# /etc/nixos/panacea.nix
# Panacea Desktop Shell module for NixOS
{ config, pkgs, lib, ... }:

let
  panacea-sddm-theme = pkgs.stdenvNoCC.mkDerivation {
    pname = "panacea-sddm-theme";
    version = "1.0.0";
    src = ./panacea/sddm/panacea;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes/panacea
      cp -r * $out/share/sddm/themes/panacea/
    '';
  };

  panacea-grub-theme = pkgs.stdenvNoCC.mkDerivation {
    pname = "panacea-grub-theme";
    version = "1.0.0";
    src = ./panacea/grub/panacea;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };
in
{
  # Ensure runtime directory for wallpaper sync and SDDM bridge
  systemd.tmpfiles.rules = [
    "d /var/lib/panacea 0777 root root -"
  ];

  # Disable GDM if enabled elsewhere
  services.displayManager.gdm.enable = lib.mkForce false;

  # SDDM Display Manager with Panacea Island Theme
  services.displayManager = {
    defaultSession = "hyprland";
    sddm = {
      enable = true;
      wayland.enable = false; # X11 mode in greeter with stable NVIDIA acceleration; launches Wayland (Hyprland) sessions natively


      theme = "panacea";
      extraPackages = [
        panacea-sddm-theme
        pkgs.qt6.qtdeclarative
        pkgs.qt6.qtsvg
        pkgs.qt6.qtmultimedia
        pkgs.qt6.qt5compat
      ];
    };
  };

  environment.systemPackages = [
    panacea-sddm-theme
  ];

  # Automatic unlocking of GNOME Keyring on login via SDDM


  security.pam.services.sddm.enableGnomeKeyring = lib.mkDefault true;
}
