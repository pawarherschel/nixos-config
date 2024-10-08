{ config, pkgs, ... }:{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ksakura";
  home.homeDirectory = "/home/ksakura";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/ksakura/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "hx";
  };

  programs = {
    helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        theme = "dracula";
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
      languages = {
        language-server.nil = {
          command = "${pkgs.nil}/bin/nil";
        };
        language-server.nixd = {
          command = "${pkgs.nixd}/bin/nixd";
        };
        
        language = [
          {
            name = "nix";
            file-types = ["nix"];
            language-servers = [
              "nil"
              "nixd"
            ];
          }
        ];
      };
    };

    atuin = {
      enable = true;
      enableNushellIntegration = true;
    };

    nushell = 
    let
      defaults = {
        config = builtins.fetchurl {
          url = "https://raw.githubusercontent.com/nushell/nushell/0.98.0/crates/nu-utils/src/sample_config/default_config.nu";
          sha256 = "05k136qzz50dvqnsyhx8r38wyvwbjk92p2k0v8hldarc8izwykph";
        };
        env = builtins.fetchurl {
          url = "https://raw.githubusercontent.com/nushell/nushell/0.98.0/crates/nu-utils/src/sample_config/default_env.nu";
          sha256 = "1dw1b4m3w3rd21n6dc0ijwvmadf5fa4zx0kcbcmbks84mkffnaqd";
        };
      };
    in 
    {
      enable = true;
      configFile.text = (builtins.readFile defaults.config);
      # extraConfig = ''
      #   source ~/.local/share/atuin/init.nu
      #   use ~/.cache/starship/init.nu
      # '';
      envFile.text = (builtins.readFile defaults.env);
      # extraEnv = ''
      #   mkdir ~/.cache/starship
      #   starship init nu | save -f ~/.cache/starship/init.nu
      # '';
    };

    starship = {
      enable = true;
      # settings = {
      #   username.show_always = true;
      # };
    };


    kitty = {
      enable = true;
      font.package = pkgs.jetbrains-mono;

    };
  };

  
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mainMod" = "SUPER";
      
      monitor = [
        ",highres,auto,auto"
        ",preferred,auto,auto,mirror,eDP-1"
      ];

      xwayland.force_zero_scaling = true;

      "$terminal" = "kitty";

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "GDK_SCALE,1"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 20;

        border_size = 2;

        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";

        resize_on_border = false;

        allow_tearing = false;

        layout = "dwindle";
      };

      decoration = {
        rounding = 10;

        active_opacity = 1.0;
        inactive_opacity = 1.0;

        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";

        blur = {
          enabled = true;
          size = 3;
          passes = 1;

          vibrancy = 0.1696;
        };
      };

        animations = {
          enabled = true;

          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        master = {
          new_status = "master";
        };

        misc = {
          force_default_wallpaper = -1;
          disable_hyprland_logo = false;
        };

        input = {
          kb_layout = "us";

          follow_mouse = 1;

          sensitivity = 0;

          touchpad.natural_scroll = true;
        };

        gestures.workspace_swipe = false;

        bind = [
          "$mainMod, Q, exec, $terminal"
          "$mainMod, F, exec, firefox"
          "$mainMod, C, killactive,"
          "$mainMod ALT, F, fullscreen"
          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"
          "$mainMod SHIFT, 1, movetoworkspace, 1"
        ];

        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        
        windowrulev2 = ["suppressevent maximize, class:.* "];
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
