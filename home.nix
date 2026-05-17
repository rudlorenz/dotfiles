{ config, pkgs, ... }:

let
  # nix wrapper around hiddify appimage
  hiddify = pkgs.callPackage ./hiddify.nix { };

  # slightly modified default starship theme
  default-starship = ./starship-default.toml;
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "rudlorenz";
  home.homeDirectory = "/home/rudlorenz";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
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
    ripgrep
    procs
    nil
    nixfmt

    hiddify

    nerd-fonts.sauce-code-pro
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
  ];

  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      settings = {
        user.name = "Rudolph Lorenz";
        user.email = "rudlorenz@gmail.com";
        core.editor = "nvim";
      };
    };

    bat = {
      enable = true;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = "auto";
    };

    neovim = {
      enable = true;
      vimAlias = true;
      defaultEditor = true;
    };

    firefox = {
      enable = true;
    };

    fd = {
      enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    tealdeer = {
      enable = true;
      settings = {
        updates.auto_update = true;
      };
    };

    vscode = {
      enable = true;
      mutableExtensionsDir = true;

      profiles.default.extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        eamodio.gitlens
        zhuangtongfa.material-theme
        alefragnani.bookmarks
        mkhl.direnv
        tamasfe.even-better-toml
        yzhang.markdown-all-in-one
      ];

      profiles.default.userSettings = {
        "telemetry.TelemetryLevel" = "off";
        "files.autoSave" = "afterDelay";

        "editor.formatOnSave" = true;
        "editor.mouseWheelZoom" = true;
        "editor.formatOnPaste" = true;
        "editor.minimap.enabled" = false;
        "editor.fontFamily" = "'SauceCodePro Nerd font'";

        "workbench.colorTheme" = "One Dark Pro Darker";

        "terminal.integrated.defaultProfile.linux" = "zsh";
        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font Mono";
        # "terminal.integrated.fontFamily" = "FiraMono Nerd Font";

        # setting up nix-ide extension to use nil lsp
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
      };
    };

    kitty = {
      enable = true;
      shellIntegration.enableZshIntegration = true;
      enableGitIntegration = true;
      themeFile = "OneDark-Pro";
      font = {
        name = "JetBrainsMono Nerd Font Mono";
      };
    };

    starship = {
      enable = true;
      enableZshIntegration = true;

      settings = builtins.fromTOML (builtins.readFile default-starship);
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      history = {
        ignoreDups = true;
        ignoreSpace = true;
        share = true;
      };

      shellAliases = {
        bt = "bat --style=-numbers";

        glg = "git --no-pager log -n 20 --oneline";
        gitlg = "git --no-pager log develop.. --oneline";
      };

      initContent = ''
        # Grep here shortcut
        function gh() {
          rg -n -- "$1"
        }

        function mkcdir() {
          mkdir -p -- "$1" && cd "$1"
        }
      '';
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };
  };
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
  #  /etc/profiles/per-user/rudlorenz/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "vim";
  };
}
