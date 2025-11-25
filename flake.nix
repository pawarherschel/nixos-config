{
  inputs = {
    # NOTE: Replace "nixos-23.11" with that which is in system.stateVersion of
    # configuration.nix. You can also use latter versions if you wish to
    # upgrade.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium-browser = {
      url = "github:ominit/helium-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # cosmic-manager = {
    #   url = "github:HeitorAugustoLN/cosmic-manager";
    #   inputs = {
    #     nixpkgs.follows = "nixpkgs";
    #     home-manager.follows = "home-manager";
    #   };
    # };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      stylix,
      # cosmic-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # NOTE: 'nixos' is the default hostname set by the installer
      nixosConfigurations.kats-laptop = nixpkgs.lib.nixosSystem {
        # NOTE: Change this to aarch64-linux if you are on ARM
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          stylix.nixosModules.stylix
          {
            stylix.enable = true;
            stylix.polarity = "dark";
            stylix.image = ./wallpaper.png;
            stylix.autoEnable = true;
            stylix.fonts.monospace.package = pkgs.jetbrains-mono;
            stylix.fonts.monospace.name = "JetBrainsMono NF Regular";
            stylix.fonts.sizes.terminal = 12;
            stylix.targets.grub.useWallpaper = true;
          }

          ./configuration.nix
          {
            environment.systemPackages = [
              inputs.helium-browser.packages."${system}".default
            ];
          }

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
