## Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nix.settings.system-features = [
    "nixos-test"
    "benchmark"
    "big-parallel"
    "kvm"
    "gccarch-skylake"
  ];

  nix.settings.cores = 4;
  nix.settings.max-jobs = 4;

  # nixpkgs.hostPlatform = {
  #   gcc.arch = "skylake";
  #   gcc.tune = "skylake";
  #   system = "x86_64-linux";
  # };

  boot.kernelPackages = pkgs.linuxPackages_zen.extend (
    final: prev: {
      kernel = prev.kernel.overrideAttrs (old: {
        makeFlags = (old.makeFlags or [ ]) ++ [
          "KCFLAGS=-march=skylake -mtune=skylake -O2 -pipe"
          "KCPPFLAGS=-march=skylake -mtune=skylake -O2 -pipe"
        ];

        modDirVersion = "${old.version}-zen-skylake";
      });
    }
  );

  # services.dnsmasq = {
  #   enable = true;
  #   settings = {
  #     dhcp-option=[
  #       "3,0.0.0.0"
  #       "6,0.0.0.0"
  #     ];
  #     interface = "enp0s31f6";
  #     dhcp-range = [
  #       "192.168.100.2,192.168.100.254"
  #     ];
  #     server = [
  #       "1.1.1.1"
  #       "8.8.8.8"
  #     ];
  #   };
  # };

  # systemd.services.dnsmasq = {
  #   requires = ["network-online.target"];
  #   after = ["network-online.target"];
  # };

  # Bootloader.
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModprobeConfig = "options kvm_intel nested=1";
  boot.plymouth = {
    enable = true;
    themePackages = [ pkgs.plymouth-blahaj-theme ];
    theme = lib.mkForce "blahaj";
  };

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
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --greeting 'meow' --remember --remember-session";
        user = "greeter";
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ksakura = {
    isNormalUser = true;
    description = "Kathryn Sakura";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "sound"
      "video"
      "libvirtd"
    ];
    shell = pkgs.nushell;
  };

  users.users.kat = {
    isNormalUser = true;
    description = "_kat";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  # Enable automatic login for the user.
  # services.getty.autologinUser = "ksakura";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages =
    with pkgs;
    [
      atuin
      bottom
      cargo
      cargo-cache
      coreutils
      difftastic
      discord
      helium
      gcc
      gh
      git
      helix
      jq
      kdePackages.polkit-kde-agent-1
      ncdu
      networkmanager-openvpn
      nh
      nix-output-monitor
      nushell
      openvpn
      pipewire
      python3
      ripgrep
      ripgrep-all
      rustc
      rustup
      starship
      wakeonlan
      waypipe
      wireplumber
      wl-clipboard
      xdg-utils
      yazi
      zellij
    ]
    ++ (with pkgs.gnomeExtensions; [
      app-name-indicator
      appindicator
      clipboard-indicator
      edit-desktop-files
      emoji-copy
      gsconnect
      paperwm
      xwayland-indicator
    ]);

  fonts = {
    enableDefaultPackages = true;
    packages = [
      pkgs.jetbrains-mono
    ];
  };

  # programs.kdeconnect.enable = true;

  services.desktopManager.gnome.enable = true;
  services.gnome.core-apps.enable = false;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-user-docs
  ];

  # programs.hyprland.enable = true;
  # Enable the login manager
  # services.displayManager.cosmic-greeter.enable = true;
  # Enable the COSMIC DE itself
  # services.desktopManager.cosmic.enable = true;
  # Enable XWayland support in COSMIC
  # services.desktopManager.cosmic.xwayland.enable = true;
  xdg = {
    autostart.enable = true;
    terminal-exec = {
      enable = true;
      settings.default = [ "kitty.desktop" ];
    };
    portal = {
      enable = true;
      # xdg-desktop-portal-gtk is a reliable fallback for minimal setups
      extraPortals = with pkgs; [
        xdg-desktop-portal-termfilechooser
        xdg-desktop-portal-gnome
        xdg-desktop-portal-phosh
      ];
    };
  };

  programs.steam.enable = true;
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
