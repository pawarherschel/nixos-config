# gui.theme — stylix + Catppuccin Mocha via tinted-theming.
{ inputs, den, ... }:
{
  flake-file.inputs = {
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tt-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };
    base16.url = "github:SenchoPens/base16.nix";
  };

  den.aspects.gui.theme = {
    includes = [
      den.aspects.gui.theme.wallpaper
    ];

    nixos =
      { pkgs, lib, ... }:
      {
        imports = [
          inputs.base16.nixosModule
          inputs.stylix.nixosModules.stylix
        ];

        fonts = {
          enableDefaultPackages = true;
          packages = [ (pkgs.nerd-fonts.jetbrains-mono) ];
        };

        stylix = {
          enable = true;
          polarity = "dark";
          autoEnable = true;
          base16Scheme = "${inputs.tt-schemes}/base24/catppuccin-mocha.yaml";
          targets.qt.platform = lib.mkForce "qtct";
          targets.kmscon.enable = false;
        };

        qt.platformTheme = lib.mkForce "gnome";

        services.displayManager.generic.environment = lib.mkDefault { };
      };
  };
}
