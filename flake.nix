{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium-browser = {
      url = "github:ominit/helium-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tt-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };
    base16.url = "github:SenchoPens/base16.nix";

  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      stylix,
      helium-browser,
      tt-schemes,
      base16,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      helium-browser-overlay = (
        { ... }:
        {
          nixpkgs.overlays = [
            (prev: next: {
              helium = helium-browser.packages."${prev.system}".helium;
            })
          ];
        }
      );

      wallpaper = ./wallpaper.png;

      theme = {
        # taken from https://archseer.github.io/colibri.vim/swatch.html
        # Base16
        base00 = "281733"; # revolver (bg3)
        base01 = "3B224C"; # midnight (bg2)
        base02 = "452859"; # bossanova (bg1)
        base03 = "697C81"; # sirocco (comments)
        base04 = "5A5977"; # comet (lineNr)
        base05 = "FFFFFF"; # white (fg1)
        base06 = "A4A0E8"; # lavender (fg2)
        base07 = "EBEAFA"; # white lilac (fg???)
        base08 = "F47868"; # apricot (error)
        base09 = "EFBA5D"; # honey (special)
        base0A = "E8DCA0"; # chamois (numbers)
        base0B = "9FF28F"; # mint (keywords)
        base0C = "7FB998"; # sinbad (complement 1)
        base0D = "6F44F0"; # delta (change/info)
        base0E = "DBBFEF"; # lilac (constants)
        base0F = "802F00"; # cedar (highlight)

        # Base24
        base10 = "281733"; # Darker BG (fallback to base00)
        base11 = "1A0F22"; # Darkest BG (simulated or fallback)
        base12 = "F22C86"; # minus (remove) - Bright Red
        base13 = "FFCD1C"; # lightning (warning) - Bright Yellow
        base14 = "35BF86"; # plus (add) - Bright Green
        base15 = "5FE7B7"; # turqoise - Bright Cyan
        base16 = "69A0F3"; # delta (unused CSS variant) - Bright Blue
        base17 = "3B0FBF"; # diff4 - Bright Purple

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
      # NOTE: 'nixos' is the default hostname set by the installer
      nixosConfigurations.kats-laptop = nixpkgs.lib.nixosSystem {
        # NOTE: Change this to aarch64-linux if you are on ARM
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          helium-browser-overlay

          base16.nixosModule
          stylix.nixosModules.stylix
          {
            stylix.enable = true;
            stylix.polarity = "dark";
            stylix.autoEnable = true;
            stylix.fonts.monospace.package = pkgs.jetbrains-mono;
            stylix.fonts.monospace.name = "JetBrainsMono NF Regular";
            stylix.fonts.sizes.applications = 14;
            stylix.fonts.sizes.desktop = 14;
            stylix.opacity.terminal = 0.8;
            stylix.icons.enable = true;
            stylix.icons.package = pkgs.adwaita-icon-theme;
            stylix.icons.light = "Adwaita";
            stylix.icons.dark = "Adwaita";
            stylix.base16Scheme = {
              base00 = theme.base00;
              base01 = theme.base01;
              base02 = theme.base02;
              base03 = theme.base03;
              base04 = theme.base04;
              base05 = theme.base05;
              base06 = theme.base06;
              base07 = theme.base07;
              base08 = theme.base08;
              base09 = theme.base09;
              base0A = theme.base0A;
              base0B = theme.base0B;
              base0C = theme.base0C;
              base0D = theme.base0D;
              base0E = theme.base0E;
              base0F = theme.base0F;
            };
          }
          (
            {
              config,
              pkgs,
              lib,
              ...
            }:
            let
              # --- 1. CONFIGURATION TOGGLES ---
              useLutgen = true; # Set to false to skip recoloring
              useDidder = !true; # Set to false to skip dithering

              # --- 2. PREPARATION ---
              paletteList = builtins.attrValues theme;
              lutgenArgs = lib.escapeShellArgs paletteList;
              didderPalette = lib.concatStringsSep " " paletteList;

              # --- 3. SHADOWING LOGIC ---

              # Logic: If Lutgen is on, run it. If off, just copy input -> output.
              lutgenCmd =
                if useLutgen then
                  ''
                    lutgen apply "${wallpaper}"\
                           -o smoothed.png \
                           -n 16 -l 16 \
                           -L 1.0 -P \
                           -- ${lutgenArgs}''
                else
                  ''cp "${wallpaper}" smoothed.png'';

              # Logic: If Didder is on, run it. If off, just copy input -> output.
              didderCmd =
                if useDidder then
                  ''
                    didder --in smoothed.png --out "$out" \
                           --palette "${didderPalette}" \
                           --width 1920 --height 1080 \
                           --strength 0.8 \
                           edm --serpentine Stucki
                  ''
                else
                  ''cp smoothed.png "$out"'';

            in
            {
              stylix.image =
                pkgs.runCommand "robust-wallpaper.png"
                  {
                    # Only include the tools if we actually plan to use them
                    nativeBuildInputs = (lib.optional useLutgen pkgs.lutgen) ++ (lib.optional useDidder pkgs.didder);
                  }
                  ''
                    # Step 1: Run the shadowed Lutgen command (Recolor or Copy)
                    ${lutgenCmd}

                    # Step 2: Run the shadowed Didder command (Dither or Copy)
                    ${didderCmd}
                  '';
            }
          )
          ./configuration.nix

          {
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
          }

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            # home-manager.useUserPkgs = true;
            home-manager.users.ksakura.imports = [
              ./home.nix
              # cosmic-manager.homeManagerModules.cosmic-manager
            ];
            home-manager.backupFileExtension = "bak";
          }
        ];
      };

      formatter.${system} = pkgs.alejandra;
      devShells.${system}.default =
        with pkgs;
        mkShell {
          buildInputs = [
            nil
            self.formatter.${system}
          ];
        };
    };
}
