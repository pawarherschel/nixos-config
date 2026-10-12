{ inputs, ... }:
let
  rev = "6da6910fdba7a87dd409fcd34611503c1e7ab632";
  overlay = final: prev:
    let
      bun2nix = (inputs.llm-agents.inputs.bun2nix.overlays.default final prev).bun2nix;
    in
    {
      connectome-host = final.callPackage ./package.nix {
        src = inputs.connectome-host;
        inherit bun2nix rev;
      };
    };
in
{
  flake-file.outputs = ''
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; }
      ((inputs.import-tree.filter (path:
        !(builtins.elem (builtins.baseNameOf path) [ "package.nix" "bun.nix" ])
        || !(inputs.nixpkgs.lib.hasInfix "/overlays/connectome-host/" (toString path))
      )) ./modules)
  '';
  flake-file.inputs.connectome-host = {
    url = "github:anima-research/connectome-host/${rev}";
    flake = false;
  };

  den.aspects.overlays.connectome-host.darwin.nixpkgs.overlays = [ overlay ];
}
