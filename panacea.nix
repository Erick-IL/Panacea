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
in
{
  # SDDM Display Manager with Panacea Island Theme
  services.displayManager = {
    defaultSession = "hyprland";
    sddm = {
      enable = true;
      wayland.enable = false; # X11 mode in greeter with stable NVIDIA acceleration


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

  # Shared runtime state for SDDM greeter bridge
  systemd.tmpfiles.rules = [
    "d /var/lib/panacea 0777 root root -"
  ];

  # Automatic unlocking of GNOME Keyring on login via SDDM


  security.pam.services.sddm.enableGnomeKeyring = lib.mkDefault true;
}
