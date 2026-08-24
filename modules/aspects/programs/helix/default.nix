# helix — editor wrapped via nix-wrapper-modules.
{
  inputs,
  config,
  den,
  lib,
  ...
}:
let
  helixSettings = {
    keys.normal.esc = [
      "collapse_selection"
      "keep_primary_selection"
    ];
    editor = {
      line-number = "relative";
      cursor-shape = {
        insert = "bar";
        normal = "block";
        select = "underline";
      };
      lsp.display-inlay-hints = true;
      whitespace.render = {
        space = "all";
        nbsp = "all";
        tab = "all";
        newline = "none";
        tabpad = "all";
      };
      indent-guides = {
        render = true;
        character = "╎";
        skip-levels = 1;
      };
    };
  };

  # Collected slices are modules providing `languages`; merge with
  # concat semantics for `language`, attrwise for everything else.
  helixLanguages =
    (lib.evalModules {
      modules = config.flake.helixWrapperModules ++ [
        {
          options.languages = lib.mkOption {
            type = lib.types.submodule {
              freeformType = lib.types.attrsOf lib.types.raw;
              options.language = lib.mkOption {
                type = lib.types.listOf lib.types.raw;
                default = [ ];
              };
              options.language-server = lib.mkOption {
                type = lib.types.attrsOf lib.types.raw;
                default = { };
              };
            };
            default = { };
          };
        }
      ];
    }).config.languages;

  # Interim: IFD while base16-helix isn't vendored for a pure mapping.
  stylixColors = inputs.self.nixosConfigurations.kats-laptop.config.lib.stylix.colors;
in
{
  flake-file.inputs = {
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    base16-helix = {
      url = "github:tinted-theming/base16-helix";
      flake = false;
    };
  };

  den = {
    classes.helixWrapper = { };

    policies.collect-helix-wrapper = _: [
      (den.lib.policy.instantiate {
        name = "helix-wrapper";
        class = "helixWrapper";
        instantiate = { modules, ... }: modules;
        intoAttr = [ "helixWrapperModules" ];
      })
    ];

    schema.user.includes = [ den.policies.collect-helix-wrapper ];

    aspects.programs.helix = {
      includes = [
        den.aspects.programs.helix.json
        den.aspects.programs.helix.javascript
        # den.aspects.programs.helix.markdown
        den.aspects.programs.helix.nix
        den.aspects.programs.helix.toml
        den.aspects.programs.helix.typst
      ];

      # settings live in the file-level `helixSettings` let — single consumer
      nixos =
        { pkgs, ... }:
        {
          environment = {
            systemPackages = [ inputs.self.packages.${pkgs.system}.helix ];
            variables.EDITOR = "hx";
            sessionVariables.EDITOR = "hx";
          };
        };
    };
  };

  perSystem =
    { pkgs, ... }:
    {
      packages.helix = inputs.wrappers.wrappers.helix.wrap {
        inherit pkgs;
        languages = helixLanguages;
        settings = helixSettings;
        extraSettings = ''
          theme = "stylix"
        '';
        runtimePkgs = with pkgs; [
          biome
          nil
          nixd
          nixfmt
          vscode-json-languageserver
          taplo
          tinymist
          tombi
          typescript-language-server
          typstyle
        ];
        themes.stylix = builtins.readFile (
          toString (stylixColors {
            templateRepo = inputs.base16-helix;
            target = "base16";
          })
        );
      };
    };
}
