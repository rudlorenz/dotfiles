# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  # Evaluates USB wakeup for a HID device's parent. Triggered on every HID
  # interface addition. It scans the parent for a boot-keyboard interface
  # (protocol 01) and explicitly sets `enabled` or `disabled`. Because the
  # last interface to register triggers the final evaluation, this achieves
  # eventual consistency without needing to block udev with `sleep`.
  usb-wakeup-decide = pkgs.writeShellScript "usb-wakeup-decide" ''
    dev="$1"
    for iface in /sys/bus/usb/devices/"$dev"/*/; do
      [ -f "$iface/bInterfaceClass" ] || continue
      [ "$(cat "$iface/bInterfaceClass")" = "03" ] || continue
      if [ "$(cat "$iface/bInterfaceProtocol")" = "01" ]; then
        echo enabled > /sys/bus/usb/devices/"$dev"/power/wakeup
        exit 0
      fi
    done
    echo disabled > /sys/bus/usb/devices/"$dev"/power/wakeup
  '';
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # xbox dongle driver
  hardware.xone.enable = true;

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.configurationLimit = 15;

  boot.loader.timeout = 10;

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.loader.grub.theme = (
    pkgs.sleek-grub-theme.override {
      withStyle = "bigSur";
    }
  );
  boot.loader.grub.default = "saved";
  boot.loader.grub.timeoutStyle = "menu";

  networking.hostName = "vulture-nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Novosibirsk";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Use the standard OpenSSH ssh-agent instead of GNOME's gcr-ssh-agent.
  # The two conflict (build-time assertion in services.gnome.gcr-ssh-agent);
  # only one SSH agent may be active at a time.
  services.gnome.gcr-ssh-agent.enable = false;
  programs.ssh.startAgent = true;

  # Enable autologin
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "rudlorenz";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us, ru";
    variant = "";
    options = "grp:win_space_toggle";
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "hibernate";
    HandleLidSwitchExternalPower = "hibernate";
    HandleLidSwitchDocked = "hibernate";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    extraConfig.pipewire."10-pro-audio" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [
          44100
          48000
          88200
          96000
          176400
          192000
        ];
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 2048;
      };
    };

    wireplumber.extraConfig."10-mojo2" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              "node.name" = "~alsa_output.*";
              "device.vendor.id" = "usb:245f";
            }
          ];
          actions = {
            "update-props" = {
              "audio.format" = "S32LE";
              "audio.rate" = [
                44100
                48000
                88200
                96000
                176400
                192000
                352800
                384000
                705600
                768000
              ];
              "node.pause-on-idle" = false;
              "api.alsa.period-size" = 256;
            };
          };
        }
      ];
    };
  };

  # disable usb autosuspend for chord mojo2
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="245f", ATTRS{idProduct}=="0815", ATTR{power/control}="on"

    # Disable wakeup for the Razer 2.4 GHz dongle (composite device with
    # keyboard sub-interfaces that cause the generic script to enable wakeup).
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="007d", ATTR{power/wakeup}="disabled"

    # Skip the generic wakeup script for the Razer dongle. ATTRS traverses
    # the parent chain, so from the interface event we can read the parent
    # USB device's idVendor/idProduct.
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_interface", ATTR{bInterfaceClass}=="03", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="007d", GOTO="usb_wakeup_end"

    # Evaluate USB wakeup on any HID interface addition.
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_interface", ATTR{bInterfaceClass}=="03", RUN+="${usb-wakeup-decide} $parent"

    LABEL="usb_wakeup_end"
  '';

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rudlorenz = {
    isNormalUser = true;
    description = "Rudolph";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      #  thunderbird
    ];
  };

  users.users.root.shell = pkgs.zsh;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs.zsh.enable = true;

  programs.steam = {
    enable = true;
    # remotePlay.openFirewall = true; # Open ports for Steam Remote Play
    # localNetworkGameTransfers.openFirewall = true; # Open ports for PC-to-PC game transfers
    # dedicatedServer.openFirewall = true;
    extraPackages = [ pkgs.adwaita-icon-theme ];
  };

  # GameMode: temporarily apply optimizations (performance CPU governor, P-core
  # pinning on hybrid CPUs, GPU max performance) while a game is running.
  programs.gamemode = {
    enable = true;
    settings = {
      cpu.pin_cores = "yes"; # Intel hybrid CPUs: pin games to P-cores (auto-detected)
      gpu = {
        # Apply GPU optimisations while GameMode is active. Note: this keeps
        # the GPU at max clocks during games -> more heat, more FPS.
        apply_gpu_optimisations = "accept-responsibility";
        nv_powermizer_mode = 1; # GPUPowerMizerMode = "Prefer Maximum Performance"
      };
    };
  };

  # Gamescope: per-game micro-compositor for proper fullscreen, frame pacing and
  # lower input latency under Wayland.
  # Doesn't really need one and it doesn't give that much, but nice to have
  programs.gamescope = {
    enable = true;
    enableWsi = true; # Vulkan WSI layer for Wayland + NVIDIA
  };

  # Intel DPTF adaptive thermal management: proactively adjust cooling before
  # the kernel's generic throttle kicks in (GS66 runs hot).
  services.thermald.enable = true;

  # NVIDIA Dynamic Boost (nvidia-powerd): shift the power budget between CPU and
  # GPU on supported laptops (Ampere + Alder Lake qualifies).
  # Verify SBIOS support with: nvidia-settings -q DynamicBoostSupport
  hardware.nvidia.dynamicBoost.enable = true;

  # Allowing to run appimage files.
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    wget
    fzf
    # looks like a hack a bit, but w/e
    # agenix.packages.${pkgs.system}.default
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://mirror.yandex.ru/nixos/"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.optimise = {
    automatic = true;
    dates = "weekly";
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
  # services.openssh.enable = true;

  # services.fwupd.enable = true;

  # Open ports in the firewall.
  # Warcraft III LAN: TCP+UDP 6112 for game connections & lobby discovery.
  # networking.firewall.allowedTCPPorts = [ 6112 ];
  # networking.firewall.allowedUDPPorts = [ 6112 ];

  # LocalSend: files over the LAN; module opens TCP+UDP 53317 by default.
  # programs.localsend.enable = true;
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
