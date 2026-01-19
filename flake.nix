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
    fingerprint = {
      url = "github:viktor-grunwaldt/t480-fingerprint-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
      fingerprint,
      nixos-hardware,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;

      # --- 0. HELPERS ---

      # Moved to top. Defaults MUST be false to prevent collisions.
      mkWallpaperName =
        {
          path,
          lutgen ? false,
          didder ? false,
        }:
        let
          base = lib.removeSuffix ".png" (baseNameOf path);
          suffixes = (lib.optional lutgen "lutgen") ++ (lib.optional didder "didder") ++ [ "png" ];
        in
        lib.concatStringsSep "." ([ base ] ++ suffixes);

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

      nil-overlay = (
        { config, ... }:
        {
          nixpkgs.overlays = [
            (final: prev: {
              nil = (prev.nil.override { nix = config.nix.package; }).overrideAttrs (
                finalAttrs: previousAttrs: {
                  src = prev.fetchFromGitHub {
                    owner = "oxalica";
                    repo = "nil";
                    rev = "cd7a6f6d5dc58484e62a8e85677e06e47cf2bd4d";
                    hash = "sha256-fK4INnIJQNAA8cyjcDRZSPleA+N/STI6I0oBDMZ2r+E=";
                  };

                  cargoDeps = final.rustPlatform.fetchCargoVendor {
                    inherit (finalAttrs) src;
                    hash = "sha256-wvtCLCvpxbUo7VZPExUI7J+U06jnWBMnVuXqJeL/kOI=";
                  };
                }
              );
            })
          ];
        }
      );

      mkWallpapers =
        {
          pkgs,
          lib,
          theme,
          mkName,
        }:

        let
          # --- 1. CONFIGURATION & HELPERS ---
          paletteList = builtins.attrValues theme;
          lutgenArgs = lib.escapeShellArgs paletteList;
          didderPalette = lib.concatStringsSep " " paletteList;

          mkRaw =
            name: src:
            pkgs.runCommand "${name}-raw"
              {
                nativeBuildInputs = [ pkgs.imagemagick ];
              }
              ''
                mkdir -p $out
                # Resize src to 1920x1080 and save to output
                convert "${src}" -resize 1920x1080 $out/output.png
              '';

          mkLutgen =
            name: src:
            pkgs.runCommand "${name}-lutgen"
              {
                nativeBuildInputs = [
                  pkgs.lutgen
                  pkgs.imagemagick
                ];
              }
              ''
                # 1. Resize first to intermediate file
                convert "${src}" -resize 1920x1080 resized.png

                # 2. Apply lutgen on the resized image
                lutgen apply resized.png -o temp.png \
                        -n 16 -l 16 -L 1.0 -P \
                        -- ${lutgenArgs}

                # 3. Create output
                mkdir -p $out
                mv temp.png $out/output.png
              '';

          mkDidder =
            name: src:
            pkgs.runCommand "${name}-didder"
              {
                nativeBuildInputs = [ pkgs.didder ];
              }
              ''
                didder --in "${src}" --out temp.png \
                       --palette "${didderPalette}" \
                       --width 960 --height 540 \
                       --strength 0.8 --upscale 2 \
                       edm --serpentine Stucki

                mkdir -p $out
                mv temp.png $out/output.png
              '';

          # --- 2. PIPELINE LOGIC ---
          wallpapersDir = ./wallpapers;
          files = builtins.readDir wallpapersDir;
          pngFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".png" name) files;

          processFile =
            filename: _:
            let
              baseName = lib.removeSuffix ".png" filename;
              source = "${wallpapersDir}/${filename}";

              # A. Raw (lutgen=false, didder=false)
              rawDrv = mkRaw baseName source;
              raw = {
                name = mkName { path = filename; };
                # Now this points to ...-01-raw/output.png
                path = "${rawDrv}/output.png";
              };
              # B. Lutgen (lutgen=true, didder=false)
              lutgenDrv = mkLutgen baseName source;
              lutgen = {
                name = mkName {
                  path = filename;
                  lutgen = true;
                };
                path = "${lutgenDrv}/output.png";
              };

              # C. Didder (lutgen=false, didder=true)
              didderDrv = mkDidder baseName source;
              didder = {
                name = mkName {
                  path = filename;
                  didder = true;
                };
                path = "${didderDrv}/output.png";
              };

              # D. Combined (lutgen=true, didder=true)
              combinedDrv = mkDidder "${baseName}-lutgen" "${lutgenDrv}/output.png";
              combined = {
                name = mkName {
                  path = filename;
                  lutgen = true;
                  didder = true;
                };
                path = "${combinedDrv}/output.png";
              };
            in
            [
              raw
              lutgen
              didder
              combined
            ];

          allWallpapers = lib.flatten (lib.mapAttrsToList processFile pngFiles);

        in
        pkgs.linkFarm "processed-wallpapers" (
          map (entry: {
            name = "wallpapers/" + entry.name;
            path = entry.path;
          }) allWallpapers
        );

      theme =
        let
          b16Lib = base16.lib {
            inherit pkgs;
            lib = pkgs.lib;
          };
          base = 24;
          rawScheme = b16Lib.mkSchemeAttrs "${tt-schemes}/base${builtins.toString base}/catppuccin-mocha.yaml";

          it = rawScheme.withHashtag;
        in
        if !true then
          {
            base00 = it.base00;
            base01 = it.base01;
            base02 = it.base02;
            base03 = it.base03;
            base04 = it.base04;
            base05 = it.base05;
            base06 = it.base06;
            base07 = it.base07;
            base08 = it.base08;
            base09 = it.base09;
            base0A = it.base0A;
            base0B = it.base0B;
            base0C = it.base0C;
            base0D = it.base0D;
            base0E = it.base0E;
            base0F = it.base0F;
            base10 = if base == 24 then it.base10 else null;
            base11 = if base == 24 then it.base11 else null;
            base12 = if base == 24 then it.base12 else null;
            base13 = if base == 24 then it.base13 else null;
            base14 = if base == 24 then it.base14 else null;
            base15 = if base == 24 then it.base15 else null;
            base16 = if base == 24 then it.base16 else null;
            base17 = if base == 24 then it.base17 else null;
          }
        else
          {
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
      wallpapers = mkWallpapers {
        inherit pkgs theme lib;
        mkName = mkWallpaperName;
      };

      mkWallpaperConfig =
        {
          path,
          lutgen ? false,
          didder ? false,
        }:
        {
          path = path;
          lutgen = lutgen;
          didder = didder;
        };

      wallpaperConfig = mkWallpaperConfig {
        path = ./wallpapers/062.png;
        # lutgen = true;
        # didder = true;
      };

      # Path Construction:
      # /nix/store/...-processed-wallpapers/wallpapers/04.lutgen.didder.png
      wallpaper =
        # This prints the path to stderr during evaluation
        "${builtins.trace "WALLPAPERS PATH: ${wallpapers}" wallpapers}/wallpapers/"
        + (mkWallpaperName {
          inherit (wallpaperConfig) path lutgen didder;
        });
    in
    {
      # NOTE: 'nixos' is the default hostname set by the installer
      nixosConfigurations.kats-laptop = nixpkgs.lib.nixosSystem {
        # NOTE: Change this to aarch64-linux if you are on ARM
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          nixos-hardware.nixosModules.lenovo-thinkpad-t480

          fingerprint.nixosModules."06cb-009a-fingerprint-sensor"

          helium-browser-overlay

          nil-overlay

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
            stylix.opacity.terminal = 1.0;
            stylix.icons.enable = true;
            stylix.icons.package = pkgs.adwaita-icon-theme;
            stylix.icons.light = "Adwaita";
            stylix.icons.dark = "Adwaita";
            stylix.base16Scheme = theme;
            stylix.image = wallpaper;
            # stylix.base16Scheme = {
            #   base00 = theme.base00;
            #   base01 = theme.base01;
            #   base02 = theme.base02;
            #   base03 = theme.base03;
            #   base04 = theme.base04;
            #   base05 = theme.base05;
            #   base06 = theme.base06;
            #   base07 = theme.base07;
            #   base08 = theme.base08;
            #   base09 = theme.base09;
            #   base0A = theme.base0A;
            #   base0B = theme.base0B;
            #   base0C = theme.base0C;
            #   base0D = theme.base0D;
            #   base0E = theme.base0E;
            #   base0F = theme.base0F;
            # };
          }
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

          (
            { config, pkgs, ... }:
            {
              # 1. Basic Routing & Internet Sharing
              boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

              networking.nat = {
                enable = true;
                internalInterfaces = [ "enp0s31f6" ];
                externalInterface = "wlp3s0";
                forwardPorts = [
                  # Forward ALVR Ports (Quest -> Laptop -> PC)
                  {
                    sourcePort = 9943;
                    destination = "192.168.100.246:9943";
                    proto = "tcp";
                  }
                  {
                    sourcePort = 9943;
                    destination = "192.168.100.246:9943";
                    proto = "udp";
                  }
                  {
                    sourcePort = 9944;
                    destination = "192.168.100.246:9944";
                    proto = "tcp";
                  }
                  {
                    sourcePort = 9944;
                    destination = "192.168.100.246:9944";
                    proto = "udp";
                  }
                ];
              };

              # 2. Firewall: Trust Cable & Open ALVR on WiFi
              networking.firewall = {
                enable = true;
                trustedInterfaces = [ "enp0s31f6" ];
                allowedTCPPorts = [
                  9943
                  9944
                ];
                allowedUDPPorts = [
                  9943
                  9944
                ];
              };

              # 3. Static IP for Laptop (Gateway)
              networking.interfaces.enp0s31f6.ipv4.addresses = [
                {
                  address = "192.168.100.1";
                  prefixLength = 24;
                }
              ];
              networking.networkmanager.unmanaged = [ "enp0s31f6" ];

              # 4. DHCP Server (Gives PC IP & Internet DNS)
              services.dnsmasq = {
                enable = true;
                resolveLocalQueries = false;
                settings = {
                  port = 0;
                  interface = "enp0s31f6";
                  dhcp-range = [ "192.168.100.2,192.168.100.254,24h" ];
                  dhcp-host = "50:eb:f6:76:ab:35,192.168.100.246";
                  dhcp-option = [
                    "3,0.0.0.0"
                    "6,1.1.1.1,8.8.8.8"
                  ];
                };
              };

              # 5. The "Lie" (Masquerade)
              # This makes all traffic hitting the PC look like it came from the Laptop.
              # Critical for bypassing Windows Firewall "Public Network" blocks.
              networking.firewall.extraCommands = ''
                iptables -t nat -A POSTROUTING -o enp0s31f6 -j MASQUERADE
              '';
            }
          )
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
