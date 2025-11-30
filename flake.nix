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
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      stylix,
      helium-browser,
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
    in
    {
      # NOTE: 'nixos' is the default hostname set by the installer
      nixosConfigurations.kats-laptop = nixpkgs.lib.nixosSystem {
        # NOTE: Change this to aarch64-linux if you are on ARM
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          helium-browser-overlay

          stylix.nixosModules.stylix
          {
            stylix.enable = true;
            stylix.polarity = "dark";
            # stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
            stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/harmonic16-dark.yaml";
            stylix.autoEnable = true;
            stylix.fonts.monospace.package = pkgs.jetbrains-mono;
            stylix.fonts.monospace.name = "JetBrainsMono NF Regular";
            stylix.fonts.sizes.terminal = 12;
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
              colors = config.lib.stylix.colors.withHashtag;
              paletteList = [
                colors.base00
                colors.base01
                colors.base02
                colors.base03
                colors.base04
                colors.base05
                colors.base06
                colors.base07
                colors.base08
                colors.base09
                colors.base0A
                colors.base0B
                colors.base0C
                colors.base0D
                colors.base0E
                colors.base0F
              ];
              lutgenArgs = lib.escapeShellArgs paletteList;
              didderPalette = lib.concatStringsSep " " paletteList;

              # --- 3. SHADOWING LOGIC ---

              # Logic: If Lutgen is on, run it. If off, just copy input -> output.
              lutgenCmd =
                if useLutgen then
                  ''
                    lutgen apply "${wallpaper}"\
                           -o smoothed.png \
                           -n 32 -l 16 \
                           -L 0.001 -P \
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
