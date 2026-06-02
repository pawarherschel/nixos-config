# gui.theme — stylix + base16 colibri theme.
{ inputs, ... }:
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

  den.aspects.gui.theme =
    let
      # https://archseer.github.io/colibri.vim/swatch.html
      colibri = {
        # Base16
        base00 = "281733"; # revolver (bg3)
        base01 = "3B224C"; # midnight (bg2)
        base02 = "452859"; # bossanova (bg1)
        base03 = "697C81"; # sirocco (comments)
        base04 = "5A5977"; # comet (lineNr)
        base05 = "FFFFFF"; # white (fg1)
        base06 = "A4A0E8"; # lavender (fg2)
        base07 = "EBEAFA"; # white lilac
        base08 = "F47868"; # apricot (error)
        base09 = "EFBA5D"; # honey (special)
        base0A = "E8DCA0"; # chamois (numbers)
        base0B = "9FF28F"; # mint (keywords)
        base0C = "7FB998"; # sinbad (complement 1)
        base0D = "6F44F0"; # delta (change/info)
        base0E = "DBBFEF"; # lilac (constants)
        base0F = "802F00"; # cedar (highlight)
        # Base24
        base10 = "281733"; # darker bg
        base11 = "1A0F22"; # darkest bg
        base12 = "F22C86"; # bright red
        base13 = "FFCD1C"; # bright yellow
        base14 = "35BF86"; # bright green
        base15 = "5FE7B7"; # bright cyan
        base16 = "69A0F3"; # bright blue
        base17 = "3B0FBF"; # bright purple
        # Alternative
        almond = "E8AE8B";
        almond_dark = "ECCDBA";
        chamois = "D7C25B";
        comet = "716F94";
        lavender = "938FDB";
        lilac = "C590EB";
        midnight = "846897";
        midnight_alt = "311D40";
        mint = "6BC05B";
        neon = "2CF2F1";
        silver = "AAAAAA";
        silver_dark = "CCCCCC";
        sinbad = "81CECF";
        tree = "7FB998";
        white_lilac_bright = "F3F2FC";
      };
    in
    {
      nixos =
        { pkgs, lib, ... }:
        {
          imports = [
            inputs.base16.nixosModule
            inputs.stylix.nixosModules.stylix
          ];

          fonts = {
            enableDefaultPackages = true;
            packages = [ pkgs.jetbrains-mono ];
          };

          stylix = {
            enable = true;
            polarity = "dark";
            autoEnable = true;
            base16Scheme = colibri;
            # stylix GNOME module auto-sets these to outdated values; force the correct ones
            targets.qt.platform = lib.mkForce "qtct";
            targets.kmscon.enable = false;
          };

          qt.platformTheme = lib.mkForce "gnome";

          # Silence stylix upstream warning (uses renamed option internally)
          services.displayManager.generic.environment = lib.mkDefault { };
        };
    };
}
