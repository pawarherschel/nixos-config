{ den, inputs, ... }:
{
  flake-file.inputs = {
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wrappers = {
      url = "github:nix-community/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  perSystem =
    {
      pkgs,
      inputs',
      ...
    }:
    let
      profile = "nixos-config";
      profileDir = "$HOME/.omp/profiles/${profile}/agent";
      mcpConfig = pkgs.writeText "omp-mcp.json" (
        builtins.toJSON {
          "$schema" =
            "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json";
          mcpServers = {
            mdn = {
              type = "http";
              url = "https://mcp.mdn.mozilla.net/";
            };
            jetbrains = {
              type = "sse";
              url = "http://127.0.0.1:64342/sse";
            };
            astro-docs = {
              type = "http";
              url = "https://mcp.docs.astro.build/mcp";
            };
            mcp-nixos = {
              type = "stdio";
              command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
            };
            linear = {
              type = "http";
              url = "https://mcp.linear.app/mcp";
            };
          };
        }
      );
    in
    {
      packages.omp = inputs.wrappers.lib.wrapPackage (_: {
        inherit pkgs;
        package = inputs'.llm-agents.packages.omp;
        runtimePkgs = [ pkgs.coreutils ];
        env.OMP_PROFILE = profile;
        flags = {
          "--append-system-prompt" = ./AGENTS.md;
        };
        runShell = [
          ''
            mkdir -p "${profileDir}"
            install -m 0644 '${mcpConfig}' "${profileDir}/mcp.json"
          ''
        ];
      });
    };

  den.aspects.programs.omp.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.omp
      ];
    };
}
