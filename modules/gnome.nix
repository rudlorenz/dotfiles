{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.desktopEnvironmentOptions.gnome;

  extensions = with pkgs.gnomeExtensions; [
    appindicator
    space-bar
    blur-my-shell
    quick-settings-audio-panel
    clipboard-indicator
    launch-new-instance
  ];
in
{
  options.desktopEnvironmentOptions.gnome = {
    enable = mkEnableOption "GNOME desktop, extensions, and related packages";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        gnome-tweaks
        gnome-extension-manager
      ]
      ++ extensions;

    dconf.settings = {
      "org/gnome/desktop/input-sources" = {
        xkb-options = [
          "grp:win_space_toggle"
          "ctrl:nocaps"
        ];
      };

      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = map (ext: ext.extensionUuid) extensions;
      };
    };
  };
}
