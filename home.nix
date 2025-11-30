{
  config,
  pkgs,
  ...
}:
{
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
  home.packages = ([
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
  ]
    ++ ( with pkgs; [
  # The Editor
  neovim

  # Build Tools (Required for Mason to compile plugins)
  gcc
  gnumake
  unzip
  wget
  curl
  gzip
  gnutar
  ripgrep
  fd
  
  # Runtimes (Mason installs the LSPs, but uses these to run them)
  nodejs_22  # Essential for Copilot, TypeScript, JSON, HTML LSPs
  python3    # Essential for Python LSPs
  cargo      # Essential for Rust/Lua tools
  go         # Essential for Go tools
  luajit
]));

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

  xdg.desktopEntries = {
    helium = {
      name = "Helium";
      exec = "${pkgs.helium}/bin/helium %U";
      genericName = "Web Browser";
      comment = "Access the Internet";
      startupNotify = true;
      terminal = false;
      icon = "${pkgs.helium}/lib/helium-bin-0.6.7.1/product_logo_256.png";
      type = "Application";
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "application/pdf"
        "application/rdf+xml"
        "application/rss+xml"
        "application/xhtml+xml"
        "application/xhtml_xml"
        "application/xml"
        "image/gif"
        "image/jpeg"
        "image/png"
        "image/webp"
        "text/html"
        "text/xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "helium.desktop";
      "x-scheme-handler/http" = "helium.desktop";
      "x-scheme-handler/https" = "helium.desktop";
      "x-scheme-handler/about" = "helium.desktop";
      "x-scheme-handler/unknown" = "helium.desktop";
      "text/plain" = "helix.desktop";
    };
  };

  programs = {
    # cosmic-edit.enable = false;
    # cosmic-ext-calculator.enable = true;
    # cosmic-files.enable = true;
    # cosmic-player.enable = true;

    helix = {
      enable = true;
      defaultEditor = true;
      # [language-server.ltex-ls-plus]
      # command = "D:\\ltex-ls-plus-18.5.1\\bin\\ltex-ls-plus.bat"
      # [language-server.ltex-ls-plus.config]
      # ltex.language = "en-GB"
      # ltex.additionalRules.enablePickyRules = true
      # ltex.completionEnabled = true
      # ltex.diagnosticSeverity = "warning"
      # ltex.disabledRules = { "en-GB" = ["EN_QUOTES", "ELLIPSIS"] }
      # ltex.statusBarItem = true
      #
      # [language-server.marksman]
      # command = "D:\\marksman\\marksman.exe"
      #
      # [language-server.tinymist]
      # command = "tinymist"
      # [language-server.tinymist.config]
      # preview.background.enabled = true
      # preview.background.args = [
      #   "--data-plane-host=127.0.0.1:23635",
      #   "--invert-colors=never",
      #   "--open",
      # ]
      # tinymist.formatterMode = "typstyle"
      # tinymist.lint.enabled = true
      # tinymist.lint.when = "onType"
      # tinymist.exportPdf = "onSave"
      # tinymist.systemFonts = false
      # tinymist.preview.systemFonts = false
      # tinymist.formatterIndentSize = 3
      # tinymist.completion.triggerOnSnippetPlaceholders = true
      #
      #
      # [[language]]
      # name = "markdown"
      # language-servers = ["ltex-ls-plus", "marksman"]
      # formatter = { command = 'deno', args = ["fmt", "-", "--ext", "md"] }
      # auto-format = true
      #
      # [[language]]
      # name = "toml"
      # formatter = { command = "taplo", args = ["format", "-"] }
      # auto-format = true
      # roots = ["."]
      #
      # [[language]]
      # name = "typst"
      # language-servers = ["tinymist", "ltex-ls-plus"]
      # formatter.command = "typstyle"
      # auto-format = true
      settings = {
        # theme = "dracula";
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
            file-types = [ "nix" ];
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
      settings.enter_accept = true;
    };

    nushell =
      let
        tag = "0.108.0";
        defaults = {
          config = builtins.fetchurl {
            url = "https://raw.githubusercontent.com/nushell/nushell/refs/tags/${tag}/crates/nu-utils/src/default_files/default_config.nu";
            sha256 = "sha256:018lbv7idyyj9wvc3bb4rlv2avi23i6fllzqq7agwj62pa3zf6s3";
          };
          env = builtins.fetchurl {
            url = "https://raw.githubusercontent.com/nushell/nushell/refs/tags/${tag}/crates/nu-utils/src/default_files/default_env.nu";
            sha256 = "sha256:09fpv8sa4dh4gjzy0z2cyfi734f0l3ckwp0k9fafg8cl7d1vkn40";
          };
        };
      in
      {
        enable = true;
        configFile.text = builtins.readFile defaults.config;
        # extraConfig = ''
        #   source ~/.local/share/atuin/init.nu
        #   use ~/.cache/starship/init.nu
        # '';
        envFile.text = builtins.readFile defaults.env;
        # extraEnv = ''
        #   mkdir ~/.cache/starship
        #   starship init nu | save -f ~/.cache/starship/init.nu
        # '';
      };

    starship = {
      enable = true;
      settings = {
        # username.show_always = true;
        #
        custom = {
          jj = {
            ignore_timeout = true;
            description = "current jj status";
            symbol = "";
            when = true;
            command = ''
              jj root > /dev/null && jj log --revisions @ --no-graph --ignore-working-copy --color always --limit 1 --template '
                separate(" ",
                  "🥋",
                  change_id.shortest(4),
                  bookmarks,
                  "|",
                  concat(
                    if(conflict, "💥"),
                    if(divergent, "🚧"),
                    if(hidden, "👻"),
                    if(immutable, "🔒"),
                  ),
                  raw_escape_sequence("\x1b[1;32m") ++ if(empty, "(empty)"),
                  raw_escape_sequence("\x1b[1;32m") ++ if(description.first_line().len() == 0,
                    "(no description set)",
                    if(description.first_line().substr(0, 29) == description.first_line(),
                      description.first_line(),
                      description.first_line().substr(0, 29) ++ "…",
                    )
                  ) ++ raw_escape_sequence("\x1b[0m"),
                )
              '
            '';
          };
        };

        git_state.disabled = true;
        git_commit.disabled = true;
        git_metrics.disabled = true;
        git_branch.disabled = true;
        custom.git_branch = {
          when = true;
          command = "jj root >/dev/null 2>&1 || starship module git_branch";
          description = "Only show git_branch if we're not in a jj repo";
        };
      };
    };

    kitty = {
      enable = true;
      font = {
        # package = pkgs.jetbrains-mono;
        # name = "JetBrainsMono NF Regular";
        # size = 11;
      };
      settings = {
        window_padding_width = 15;
      };
    };

    bat = {
      enable = true;
    };

    bottom = {
      enable = true;
      settings.flags = { };
    };

    gh = {
      enable = true;
      settings.editor = "hx";
      settings = {
        version = 1;
        git_protocol = "https";
        prompt = "enable";
      };
    };

    jujutsu = {
      enable = true;
      settings = {
        user = {
          email = "pawarherschel@gmail.com";
          name = "Herschel Pawar";
        };
        ui = {
          editor = "hx";
        };
      };
    };
  };

  services = {
    # hyprpaper = {
    #   enable = true;
    #   settings = {
    #     splash = true;
    #     # preload = "/home/ksakura/wallpaper.png";
    #     # wallpaper = "eDP-1,/home/ksakura/wallpaper.png";
    #   };
    # };

    syncthing.enable = true;
  };
  # wayland.desktopManager.cosmic.enable = true;
  # wayland.windowManager.hyprland = {
  #   enable = true;
  #   systemd.enable = true;
  #   settings = {
  #     "$mainMod" = "SUPER";

  #     monitor = [
  #       ",highres,auto,auto"
  #       ",preferred,auto,auto,mirror,eDP-1"
  #     ];

  #     xwayland.force_zero_scaling = true;

  #     "$terminal" = "kitty";

  #     env = [
  #       "XCURSOR_SIZE,24"
  #       "HYPRCURSOR_SIZE,24"
  #       "GDK_SCALE,1"
  #     ];

  #     general = {
  #       gaps_in = 2;
  #       gaps_out = 8;

  #       border_size = 2;

  #       # "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
  #       # "col.inactive_border" = "rgba(595959aa)";

  #       resize_on_border = false;

  #       allow_tearing = false;

  #       layout = "dwindle";
  #     };

  #     decoration = {
  #       rounding = 10;

  #       active_opacity = 1.0;
  #       inactive_opacity = 1.0;

  #       # drop_shadow = true;
  #       # shadow_range = 4;
  #       # shadow_render_power = 3;
  #       # "col.shadow" = "rgba(1a1a1aee)";

  #       blur = {
  #         enabled = true;
  #         size = 3;
  #         passes = 1;

  #         vibrancy = 0.1696;
  #       };
  #     };

  #     animations = {
  #       enabled = true;

  #       bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

  #       animation = [
  #         "windows, 1, 7, myBezier"
  #         "windowsOut, 1, 7, default, popin 80%"
  #         "border, 1, 10, default"
  #         "borderangle, 1, 8, default"
  #         "fade, 1, 7, default"
  #         "workspaces, 1, 6, default"
  #       ];
  #     };

  #     dwindle = {
  #       pseudotile = true;
  #       preserve_split = true;
  #     };

  #     master = {
  #       new_status = "master";
  #     };

  #     misc = {
  #       # force_default_wallpaper = -1;
  #       # disable_hyprland_logo = false;
  #     };

  #     input = {
  #       kb_layout = "us";

  #       follow_mouse = 1;

  #       sensitivity = 0;

  #       touchpad.natural_scroll = true;
  #     };

  #     bind = [
  #       "$mainMod, Q, exec, $terminal"
  #       "$mainMod, F, exec, helium"
  #       "$mainMod, D, exec, discord"
  #       "$mainMod, C, killactive,"
  #       "$mainMod ALT, F, fullscreen"
  #       "$mainMod, S, togglespecialworkspace, magic"
  #       "$mainMod SHIFT, S, movetoworkspace, special:magic"
  #       "$mainMod SHIFT, 1, movetoworkspace, 1"
  #     ];

  #     bindm = [
  #       "$mainMod, mouse:272, movewindow"
  #       "$mainMod, mouse:273, resizewindow"
  #     ];

  #     windowrulev2 = ["suppressevent maximize, class:.* "];
  #   };
  # };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
