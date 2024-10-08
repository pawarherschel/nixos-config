## Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModprobeConfig = "options kvm_intel nested=1";

  networking.hostName = "kats-laptop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  # time.timeZone = "America/New_York";
  time.timeZone = "Asia/Kolkata";

  #timezoned
  # services.automatic-timezoned.enable = true;

  


  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

  services.tailscale.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ksakura = {
    isNormalUser = true;
    description = "Kathryn Sakura";
    extraGroups = [ "networkmanager" "wheel" "audio" "sound" "video" "libvirtd" ];
    packages = with pkgs; [];
    shell = pkgs.nushell;
  };

  users.users.kat= {
    isNormalUser = true;
    description = "_kat";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    # shell = pkgs.nushell;
  };

  # Enable automatic login for the user.
  # services.getty.autologinUser = "ksakura";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    kitty
    pipewire
    wireplumber
    libsForQt5.polkit-kde-agent
    hyprpaper
    helix
    rustup
    cargo
    rustc
    jq
    coreutils
    firefox
    bat
    ripgrep
    ripgrep-all
    cargo-cache
    pavucontrol
    wl-clipboard
    xdg-utils
    gcc
    git
    syncthing
    nushell
    starship
    atuin
    zellij
    bottom
    ncdu
    wakeonlan
    parsec-bin
    python3
    openvpn
    networkmanager-openvpn
    gh
    nil
    nixd
    difftastic
  ];

  fonts = {
    enableDefaultPackages = true;
    packages = [
      pkgs.jetbrains-mono
    ];
  };

  programs.hyprland.enable = true;

  xdg = {
    autostart.enable = true;
    portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal
        pkgs.xdg-desktop-portal-hyprland
      ];
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  services.openssh.settings.X11Forwarding = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;
  };

  # services.localtimed.enable = true;

  security.polkit.enable = true;
  security.rtkit.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
  system.autoUpgrade = {
    enable = false;
    allowReboot = false; # Do nixos-rebuild switch --upgrade instead
    # channel = "https://channels.nixos.org/nixos-23.11";
  };
}
