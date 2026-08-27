{
  config,
  pkgs,
  inputs,
  ...
}:

let
  # nix wrapper around hiddify appimage
  hiddify-wrapped = pkgs.callPackage ./hiddify.nix { };

  # slightly modified default starship theme
  default-starship = ./starship-default.toml;
in
{
  imports = [
    ./modules/gnome.nix
    inputs.agenix.homeManagerModules.default
  ];

  desktopEnvironmentOptions.gnome.enable = true;

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

  home.packages = with pkgs; [
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

    hiddify-wrapped

    nerd-fonts.sauce-code-pro
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.fira-mono

    qbittorrent
  ];

  age = {
    identityPaths = [ "${config.home.homeDirectory}/.ssh/agenix_identity" ];
    secrets = {
      id_ed25519 = {
        file = ./ssh-key.age;
        path = "${config.home.homeDirectory}/.ssh/rudlorenz";
        mode = "0600";
      };
    };
  };

  programs = {
    home-manager.enable = true;

    mpv = {
      enable = true;
      config = {
        vo = "gpu-next";
        gpu-api = "vulkan";
        target-colorspace-hint = "yes";
        target-peak = 203;
        hdr-compute-peak = "yes";
        tone-mapping = "bt.2390";
        hdr-peak-percentile = 99.95;
        allow-delayed-peak-detect = "yes";
      };
      profiles.projector = {
        target-colorspace-hint = "yes";
        target-peak = 1200;
      };
    };

    git = {
      enable = true;
      settings = {
        user.name = "Rudolph Lorenz";
        user.email = "rudlorenz@gmail.com";
        core.editor = "nvim";

        push.autoSetupRemote = true;
        # makes git a bit faster in really large repos
        core.fsmonitor = true;
        core.untrackedCache = true;
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*" = {
        AddKeysToAgent = "yes";
        HashKnownHosts = true;
        IdentityFile = "${config.home.homeDirectory}/.ssh/rudlorenz_ed25519";
        IdentitiesOnly = "yes";
      };
    };

    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
      };
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
      # HM screams warnings about that, so let's appease it
      withRuby = false;
      withPython3 = false;
    };

    firefox = {
      enable = true;
      configPath = "${config.xdg.configHome}/mozilla/firefox";
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
        display = {
          compact = true;
        };
        style = {
          description.foreground = "white";
          example_text.foreground = "white";
          example_code.foreground = "blue";
          command_name.foreground = "blue";
          example_variable.foreground = "blue";
        };
      };
    };

    opencode = {
      enable = true;
      tui = {
        theme = "one-dark";
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

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 5d --keep 5";
      flake = "${config.home.homeDirectory}/.dotfiles";
    };

    kitty = {
      enable = true;
      shellIntegration.enableZshIntegration = true;
      enableGitIntegration = true;
      themeFile = "OneDark-Pro";
      font = {
        name = "JetBrainsMono Nerd Font Mono";
      };
      settings = {
        "map" = "ctrl+shift+n new_os_window_with_cwd";
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
        btt = "bat --style=-numbers --no-pager";

        glg = "git --no-pager log -n 20 --oneline";
        gitlg = "git --no-pager log develop.. --oneline";
      };

      initContent = ''
        setopt histreduceblanks

        # case insensitive autocomp
        # cause I'm too lazy to setup ohmyzsh
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'


        # Grep here shortcut
        function gh() {
          rg -n -- "$1"
        }

        function mkcdir() {
          mkdir -p -- "$1" && cd "$1"
        }

        # Get HEAD commit hash
        function gitcm() {
          local commit_hash
          if ! commit_hash=$(git rev-parse HEAD 2>/dev/null); then echo "Error: not a git repository or no commits found."
            return 1
          fi
          echo -n "$commit_hash"
        }

        # Helper: detect the default branch (master → main fallback)
        function _git_default_branch() {
          local default_branch
          default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
          default_branch=''${default_branch#refs/remotes/origin/}

          if [[ -z "$default_branch" ]]; then
            if git rev-parse --verify master &>/dev/null; then
              default_branch="master"
            else
              default_branch="main"
            fi
          fi

          echo "$default_branch"
        }

        # Run git log against the default branch
        function gitlgm() {
          local default_branch
          default_branch=$(_git_default_branch)
          git --no-pager log "$default_branch".. --oneline
        }

        # Rebase current branch onto the updated default branch with --autosquash
        function gitbump() {
          emulate -L zsh
          local current_branch local_commits rebase_target default_branch

          if ! git rev-parse --git-dir &>/dev/null; then
            print -u2 "Error: not inside a git repository."
            return 1
          fi

          current_branch=$(git branch --show-current)
          if [[ -z "$current_branch" ]]; then
            print -u2 "Error: detached HEAD. Checkout your feature branch first."
            return 1
          fi

          default_branch=$(_git_default_branch)

          if [[ "$current_branch" == "$default_branch" ]]; then
            print -u2 "Error: you're already on $default_branch. Switch to a feature branch."
            return 1
          fi

          if ! git diff --quiet HEAD; then
            print -u2 "Error: you have uncommitted changes. Commit or stash them first."
            return 1
          fi

          # fetch the latest default branch from origin
          echo "→ Fetching origin/$default_branch..."
          if ! git fetch origin "$default_branch"; then
            print -u2 "Error: failed to fetch from origin."
            return 1
          fi

          # update local default branch
          if git rev-parse --verify "$default_branch" &>/dev/null; then
            if git merge-base --is-ancestor "$default_branch" "origin/$default_branch" 2>/dev/null; then
              git branch -f "$default_branch" "origin/$default_branch"
              rebase_target="$default_branch"
            else
              print -u2 "Warning: local $default_branch diverged from origin. Rebasing onto origin/$default_branch."
              rebase_target="origin/$default_branch"
            fi
          else
            git branch "$default_branch" "origin/$default_branch"
            rebase_target="$default_branch"
          fi

          # check if there is anything to rebase
          local_commits=$(git rev-list --count "$rebase_target"..HEAD)

          if (( local_commits == 0 )); then
            echo "→ No local commits to rebase. Already up to date with $rebase_target."
            return 0
          fi

          echo "→ Rebasing $current_branch ($local_commits commits) onto $rebase_target with --autosquash..."
          git rebase -i --autosquash "$rebase_target"
        }

        # Delete local branches whose remote was deleted and changes are in the default branch
        # Works with squash-merged branches (uses git cherry instead of --is-ancestor)
        function gitprune() {
          local default_branch branches_to_delete branch

          # Fetch and prune stale remote-tracking refs
          echo "Fetching origin..."
          git fetch --all --prune 2>&1 || return 1

          default_branch=$(_git_default_branch)

          # Find local branches whose remote-tracking ref is gone
          # Uses git for-each-ref for reliable, machine-readable output
          branches_to_delete=()
          for branch in $(git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads/ | awk '$2 == "[gone]" {print $1}'); do
            # Skip the default branch (shouldn't happen, but just in case)
            [[ "$branch" == "$default_branch" ]] && continue

            # Check if all branch changes are already in the default branch.
            # git cherry handles squash-merged branches (which --is-ancestor misses).
            # Lines starting with '-' mean the commit is equivalent in the base;
            # lines starting with '+' mean it's unique to the branch.
            if ! git cherry "$default_branch" "$branch" 2>/dev/null | rg -q '^+'; then
              branches_to_delete+=("$branch")
            else
              echo "Skipping '$branch': remote is gone but changes may not be in '$default_branch'."
            fi
          done

          if (( ''${#branches_to_delete[@]} == 0 )); then
            echo "No branches with gone remotes found."
            return 0
          fi

          echo "Branches safe to delete (remote gone, changes in '$default_branch'):"
          printf '  %s\n' "''${branches_to_delete[@]}"
          echo ""

          # Ask for confirmation
          read -q "REPLY?Delete these branches? [y/N] "
          echo ""
          if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            for branch in "''${branches_to_delete[@]}"; do
              git branch -D "$branch"
            done
            echo "Done."
          else
            echo "Cancelled."
          fi
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

  home.sessionVariables = {
    # EDITOR = "vim";
  };
}
