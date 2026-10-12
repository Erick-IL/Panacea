#!/usr/bin/env bash
# Panacea dotfiles installer — Fork for Nix / NixOS.
# Original design by EnsixD (https://github.com/EnsixD/Panacea)
#
# Installs everything: the Quickshell pill, the Hyprland Lua config, the
# terminals, the shell, fastfetch — the whole rice. Nothing is optional here;
# for a pick-and-choose install the pieces are gated inside the shell itself.
#
#   ./install.sh              install everything
#   ./install.sh --no-deps    skip the package step (configs only)
#   ./install.sh --no-backup  replace configs in place, don't keep *.bak copies
#   ./install.sh --no-sddm    don't touch the SDDM login theme
#   ./install.sh --no-grub    don't touch the GRUB boot theme
#   ./install.sh --yes        answer yes to every prompt
#   ./install.sh --print-missing   only name the packages that are absent
#   ./install.sh --print-obsolete  only name the ones no longer used
#
# Whatever already sits at a destination is moved to <name>.bak-<timestamp>
# beside it — nothing is deleted.

set -uo pipefail

SRC="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"

# sudo, which never wastes password attempts.
#
# The installer can be launched in two ways: manually from the terminal and by updating
# from the panel. In the second case there is no terminal at all, and sudo, trying to ask
# password, reads the void, considers it an incorrect password and replies “Sorry,
# try again." Three of these in a row - and sudo blocks the user for several
# minutes throughout the system, although the person did not enter anything.
#
# Therefore: there is a terminal - we ask as usual; no - we only work
# where there are rights (-n), otherwise we quietly retreat. Missed step
# more honest than blocked sudo: it can be completed by running the installer
# hands, but you have to wait to unlock it.

if [ -t 0 ]; then SUDO="sudo"; else SUDO="sudo -n"; fi


DO_DEPS=1
# Just name what is missing and get out - without installing or copying anything.
# update.sh uses this: the list of dependencies should live in one place,
# and not diverge in two copies.

PRINT_MISSING=0
PRINT_OBSOLETE=0
DO_SDDM=1
DO_GRUB=1
# Updates and checks do not need this: the services are already turned on, the wallpaper is already downloaded,
# and restarting the shell in the sandbox would kill the worker.

DO_SERVICES=1
DO_WALLS=1
DO_RESTART=1
# Whether to save what is being replaced in <name>.bak-<time>. On the first, manual installation -
# yes: this is the only insurance if someone else’s was under the config. At
# update - no: its own has already been taken aside via KEEP, and everything else is
# exactly the same repository files, and each update would produce duplicate directories in
# ~/.config. update.sh calls the installer with --no-backup.

DO_BACKUP=1
ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        --no-deps) DO_DEPS=0 ;;
        --no-backup) DO_BACKUP=0 ;;
        --no-sddm) DO_SDDM=0 ;;
        --no-grub) DO_GRUB=0 ;;
        --no-services) DO_SERVICES=0 ;;
        --no-wallpapers) DO_WALLS=0 ;;
        --no-restart) DO_RESTART=0 ;;
        --yes|-y)  ASSUME_YES=1 ;;
        --print-missing) PRINT_MISSING=1 ;;
        --print-obsolete) PRINT_OBSOLETE=1 ;;
        --help|-h) sed -n '2,13p' "$0"; exit 0 ;;
        *) echo "unknown flag: $arg" >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------- presentation
if [ -t 1 ]; then
    B=$'\e[1m'; DIM=$'\e[2m'; OK=$'\e[32m'; WARN=$'\e[33m'; ERR=$'\e[31m'; N=$'\e[0m'
else
    B=""; DIM=""; OK=""; WARN=""; ERR=""; N=""
fi
step() { printf '\n%s▍ %s%s\n' "$B" "$*" "$N"; }
ok()   { printf '  %s✓%s %s\n' "$OK" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$WARN" "$N" "$*"; }
die()  { printf '\n%sError:%s %s\n' "$ERR" "$N" "$*" >&2; exit 1; }

ask() {  # ask "question" -> 0 for yes
    [ "$ASSUME_YES" = "1" ] && return 0
    printf '%s%s [y/N]%s ' "$B" "$1" "$N"
    read -r a; case "${a,,}" in y|yes) return 0 ;; *) return 1 ;; esac
}

if [ "$PRINT_MISSING" = "0" ] && [ "$PRINT_OBSOLETE" = "0" ]; then
    printf '\n%s=================================================================%s\n' "$B" "$N"
    printf '%s  Panacea Shell — Fork para Nix / NixOS%s\n' "$B" "$N"
    printf '%s  Projeto original por EnsixD (https://github.com/EnsixD/Panacea)%s\n' "$DIM" "$N"
    printf '%s=================================================================%s\n\n' "$B" "$N"
fi

# ----------------------------------------------------------- distro detection
IS_NIXOS=0
IS_ARCH=0
if [ -f /etc/NIXOS ] || grep -qiE 'ID=nixos|ID_LIKE=.*nixos' /etc/os-release 2>/dev/null; then
    IS_NIXOS=1
elif [ -f /etc/arch-release ] || grep -qiE 'ID=arch|ID_LIKE=.*arch' /etc/os-release 2>/dev/null; then
    IS_ARCH=1
fi

# ------------------------------------------------------------------ dependencies
# binary|arch_package|nix_package|what it is for
DEPS=(
    "Hyprland|hyprland|hyprland|the compositor"
    "qs|quickshell|quickshell|the pill (dynamic island shell)"
    "fish|fish|fish|the shell"
    "foot|foot|foot|terminal"
    "hyprpaper|hyprpaper|hyprpaper|wallpaper"
    "hyprsunset|hyprsunset|hyprsunset|night colour temperature"
    "swaylock|swaylock|swaylock|the PAM profile the lock screen and the vault use"
    "jq|jq|jq|JSON in the scripts"
    "wl-copy|wl-clipboard|wl-clipboard|clipboard access"
    "cliphist|cliphist|cliphist|clipboard history"
    "grim|grim|grim|screenshots"
    "slurp|slurp|slurp|region select"
    "ffmpeg|ffmpeg|ffmpeg|media player, trimming, thumbnails"
    "wf-recorder|wf-recorder|wf-recorder|screen recording"
    "voxtype|voxtype-bin|voxtype|voice-to-text (push-to-talk, offline)"
    "wtype|wtype|wtype|typing recognised voice into the focused field"
    "brightnessctl|brightnessctl|brightnessctl|brightness keys"
    "ddcutil|ddcutil|ddcutil|monitor brightness on a desktop"
    "playerctl|playerctl|playerctl|media keys"
    "wpctl|wireplumber|wireplumber|audio control"
    "eza|eza|eza|ls replacement"
    "zoxide|zoxide|zoxide|smarter cd"
    "bat|bat|bat|cat with syntax highlighting"
    "fastfetch|fastfetch|fastfetch|system summary, its config ships with the shell"
    "yazi|yazi|yazi|files in the terminal"
    "python3|python|python3|helper scripts"
    "rfkill|util-linux|util-linux|Bluetooth soft-unblock"
    "openssl|openssl|openssl|encrypting the password vault"
    "xdg-open|xdg-utils|xdg-utils|opening files and links from the pill"
    "gio|glib2|glib|trash and launching desktop entries"
    "upower|upower|upower|battery state and the battery page"
    "lsblk|util-linux|util-linux|disks and removable media in the file manager"
    "cava|cava|cava|the audio spectrum in the pill"
    "mpvpaper|mpvpaper|mpvpaper|live video wallpapers"
    "curl|curl|curl|downloading the wallpaper pack"
    "file|file|file|sanity-checking downloaded wallpapers"
    "git|git|git|updating the shell from the repository"
    "lspci|pciutils|pciutils|naming the graphics card on the System page"
    "timedatectl|systemd|systemd|time zone and clock on the Clock & Date page"
)
FILE_DEPS=(
    "/usr/lib/qt6/qml/QtMultimedia/qmldir|qt6-multimedia|video playback"
    "/usr/lib/qt6/qml/QtQuick/Controls/qmldir|qt6-declarative|UI controls"
    "/usr/lib/qt6/qml/QtQuick/Effects/qmldir|qt6-declarative|rounded image masks"
    "/usr/lib/qt6/qml/QtQuick/Shapes/qmldir|qt6-declarative|island notch corners"
)
EXTRA_PKGS_ARCH=(power-profiles-daemon bluez bluez-utils iwd cava pipewire-audio
                 ttf-jetbrains-mono-nerd papirus-icon-theme
                 noto-fonts noto-fonts-emoji noto-fonts-cjk noto-fonts-extra
                 bibata-cursor-theme-bin udisks2 udiskie gvfs gvfs-mtp
                 python-secretstorage python-cryptography os-prober)
EXTRA_PKGS_NIX=(power-profiles-daemon bluez iwd cava pipewire
                nerd-fonts.jetbrains-mono papirus-icon-theme
                noto-fonts noto-fonts-color-emoji noto-fonts-cjk-sans noto-fonts-extra
                bibata-cursors udisks2 udiskie gvfs
                python3Packages.secretstorage python3Packages.cryptography os-prober
                qt6.qtdeclarative qt6.qtmultimedia qt6.qtsvg)
FONT_PKG_ARCH="ttf-jetbrains-mono-nerd"
FONT_PKG_NIX="nerd-fonts.jetbrains-mono"

OBSOLETE_PKGS=(
    "waybar|1.0.7"
    "wob|1.0.7"
    "tofi|1.0.7"
    "hyprlock|1.0.7"
)

# ------------------------------------------------------------------- distro detection
detect_distro() {
    DISTRO="unknown"
    PKG_MGR="unknown"

    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO="${ID:-unknown}"
        DISTRO_LIKE="${ID_LIKE:-}"
    fi

    if command -v pacman >/dev/null 2>&1; then
        PKG_MGR="pacman"
        [ "$DISTRO" = "unknown" ] && DISTRO="arch"
    elif command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
        PKG_MGR="apt"
        [ "$DISTRO" = "unknown" ] && DISTRO="debian"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MGR="dnf"
        [ "$DISTRO" = "unknown" ] && DISTRO="fedora"
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MGR="zypper"
        [ "$DISTRO" = "unknown" ] && DISTRO="opensuse"
    elif command -v apk >/dev/null 2>&1; then
        PKG_MGR="apk"
        [ "$DISTRO" = "unknown" ] && DISTRO="alpine"
    elif command -v xbps-install >/dev/null 2>&1; then
        PKG_MGR="xbps"
        [ "$DISTRO" = "unknown" ] && DISTRO="void"
    fi
}

# ------------------------------------------------------------------- drivers
detect_drivers() {
    DRIVERS_ARCH=()
    DRIVERS_NIX=()
    DRIVER_NOTES=()

    local cpu; cpu=$(grep -m1 '^vendor_id' /proc/cpuinfo | cut -d: -f2 | tr -d ' ')
    case "$cpu" in
        AuthenticAMD)
            DRIVERS_ARCH+=(amd-ucode)
            DRIVERS_NIX+=("hardware.cpu.amd.updateMicrocode = true;")
            DRIVER_NOTES+=("amd-ucode — AMD CPU microcode")
            ;;
        GenuineIntel)
            DRIVERS_ARCH+=(intel-ucode)
            DRIVERS_NIX+=("hardware.cpu.intel.updateMicrocode = true;")
            DRIVER_NOTES+=("intel-ucode — Intel CPU microcode")
            ;;
    esac

    local gpus; gpus=$(lspci -nn 2>/dev/null | grep -iE 'vga|3d controller|display controller')

    if printf '%s' "$gpus" | grep -q '\[1002:'; then
        DRIVERS_ARCH+=(mesa vulkan-radeon libva-mesa-driver)
        DRIVERS_NIX+=("hardware.graphics.enable = true;" "hardware.graphics.extraPackages = [ pkgs.libva-mesa-driver ];")
        DRIVER_NOTES+=("mesa, vulkan-radeon, libva-mesa-driver — AMD graphics")
    fi
    if printf '%s' "$gpus" | grep -q '\[8086:'; then
        DRIVERS_ARCH+=(mesa vulkan-intel intel-media-driver)
        DRIVERS_NIX+=("hardware.graphics.enable = true;" "hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];")
        DRIVER_NOTES+=("mesa, vulkan-intel, intel-media-driver — Intel graphics")
    fi
    if printf '%s' "$gpus" | grep -q '\[10de:'; then
<<<<<<< HEAD
        if printf '%s' "$gpus" | grep -qiE 'rtx|gtx 16'; then
            DRIVERS_ARCH+=(nvidia-open-dkms nvidia-utils egl-wayland)
            DRIVERS_NIX+=("hardware.graphics.enable = true;" 'services.xserver.videoDrivers = [ "nvidia" ];' 'hardware.nvidia.open = true;')
            DRIVER_NOTES+=("nvidia-open-dkms, nvidia-utils, egl-wayland — Nvidia graphics (Turing and newer)")
        else
            DRIVERS_ARCH+=(nvidia-dkms nvidia-utils egl-wayland)
            DRIVERS_NIX+=("hardware.graphics.enable = true;" 'services.xserver.videoDrivers = [ "nvidia" ];' 'hardware.nvidia.open = false;')
            DRIVER_NOTES+=("nvidia-dkms, nvidia-utils, egl-wayland — Nvidia graphics (pre-Turing)")
=======
        if [ "$PKG_MGR" = "pacman" ]; then
            local k
            for k in linux linux-lts linux-zen linux-hardened; do
                pacman -Qq "$k" >/dev/null 2>&1 && DRIVERS+=("$k-headers")
            done
            DRIVER_NOTES+=("kernel headers — needed to build the driver module")

            if printf '%s' "$gpus" | grep -qiE 'rtx|gtx 16'; then
                DRIVERS+=(nvidia-open-dkms nvidia-utils egl-wayland)
                DRIVER_NOTES+=("nvidia-open-dkms, nvidia-utils, egl-wayland — Nvidia graphics (Turing and newer)")
            else
                DRIVERS+=(nvidia-dkms nvidia-utils egl-wayland)
                DRIVER_NOTES+=("nvidia-dkms, nvidia-utils, egl-wayland — Nvidia graphics (pre-Turing)")
            fi
        else
            DRIVER_NOTES+=("Nvidia graphics drivers")
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
        fi
        if [ "$IS_ARCH" = "1" ]; then
            local k
            for k in linux linux-lts linux-zen linux-hardened; do
                pacman -Qq "$k" >/dev/null 2>&1 && DRIVERS_ARCH+=("$k-headers")
            done
            DRIVER_NOTES+=("kernel headers — needed to build the driver module")
        fi
    fi
}

install_drivers() {
    detect_distro
    detect_drivers
<<<<<<< HEAD
    if [ "${#DRIVER_NOTES[@]}" -eq 0 ]; then
=======
    if [ "${#DRIVERS[@]}" -eq 0 ] && [ "${#DRIVER_NOTES[@]}" -eq 0 ]; then
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
        warn "could not tell what hardware this is — skipping drivers"
        return
    fi
    printf '  found:\n'
    printf '    %s\n' "${DRIVER_NOTES[@]}"
<<<<<<< HEAD

    if [ "$IS_NIXOS" = "1" ]; then
        printf '\n%s  NixOS hardware configuration (/etc/nixos/configuration.nix):%s\n' "$B" "$N"
        for line in "${DRIVERS_NIX[@]}"; do
            printf '    %s\n' "$line"
        done
        printf '\n'
        ok "hardware recommendations shown"
        return 0
    fi

    ask "Install these?" || { ok "drivers skipped"; return; }

    local uniq; mapfile -t uniq < <(printf '%s\n' "${DRIVERS_ARCH[@]}" | sort -u)
    $SUDO pacman -S --needed "${uniq[@]}" || { warn "driver install failed"; return; }
    ok "drivers in place"

    if printf '%s' "${uniq[*]}" | grep -q nvidia; then
        printf 'options nvidia_drm modeset=1\n' | $SUDO tee /etc/modprobe.d/nvidia-panacea.conf >/dev/null
        $SUDO dkms autoinstall >/dev/null 2>&1
        $SUDO mkinitcpio -P >/dev/null 2>&1
        if lsmod | grep -q '^nvidia' || modinfo nvidia >/dev/null 2>&1; then
            ok "Nvidia module built — reboot to load it"
        else
            warn "Nvidia module still missing — check 'dkms status' after reboot"
        fi
=======
    ask "Install graphics & microcode drivers?" || { ok "drivers skipped"; return; }

    local gpus; gpus=$(lspci -nn 2>/dev/null | grep -iE 'vga|3d controller|display controller')

    case "$PKG_MGR" in
        pacman)
            local uniq; mapfile -t uniq < <(printf '%s\n' "${DRIVERS[@]}" | sort -u)
            $SUDO pacman -S --needed "${uniq[@]}" || { warn "driver install failed"; return; }
            ;;
        apt)
            if printf '%s' "$gpus" | grep -q '\[10de:'; then
                $SUDO ubuntu-drivers install 2>/dev/null || $SUDO apt-get install -y nvidia-driver-550 2>/dev/null || true
            elif printf '%s' "$gpus" | grep -q '\[1002:'; then
                $SUDO apt-get install -y mesa-vulkan-drivers libgl1-mesa-dri 2>/dev/null || true
            elif printf '%s' "$gpus" | grep -q '\[8086:'; then
                $SUDO apt-get install -y mesa-vulkan-drivers intel-media-va-driver 2>/dev/null || true
            fi
            $SUDO apt-get install -y intel-microcode amd64-microcode 2>/dev/null || true
            ;;
        dnf)
            if printf '%s' "$gpus" | grep -q '\[10de:'; then
                $SUDO dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda 2>/dev/null || true
            elif printf '%s' "$gpus" | grep -q '\[1002:'; then
                $SUDO dnf install -y mesa-dri-drivers mesa-vulkan-drivers 2>/dev/null || true
            elif printf '%s' "$gpus" | grep -q '\[8086:'; then
                $SUDO dnf install -y mesa-dri-drivers mesa-vulkan-drivers intel-media-driver 2>/dev/null || true
            fi
            $SUDO dnf install -y microcode_ctl 2>/dev/null || true
            ;;
        *)
            ok "drivers skipped for $DISTRO"
            return
            ;;
    esac
    ok "drivers in place"

    # Nvidia Wayland setup
    if printf '%s' "$gpus" | grep -q '\[10de:'; then
        printf 'options nvidia_drm modeset=1\n' | $SUDO tee /etc/modprobe.d/nvidia-panacea.conf >/dev/null
        if command -v dkms >/dev/null 2>&1; then $SUDO dkms autoinstall >/dev/null 2>&1 || true; fi
        if command -v mkinitcpio >/dev/null 2>&1; then $SUDO mkinitcpio -P >/dev/null 2>&1 || true; fi
        if command -v update-initramfs >/dev/null 2>&1; then $SUDO update-initramfs -u >/dev/null 2>&1 || true; fi
        if command -v dracut >/dev/null 2>&1; then $SUDO dracut --force >/dev/null 2>&1 || true; fi
        ok "Nvidia DRM modeset configured"
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
    fi
}

MISSING_ARCH=()
MISSING_NIX=()
check_deps() {
    detect_distro
    for row in "${DEPS[@]}"; do
        IFS='|' read -r bin arch_pkg nix_pkg why <<<"$row"
        if command -v "$bin" >/dev/null 2>&1; then ok "$bin"
        else
            warn "missing $bin — $why"
            MISSING_ARCH+=("$arch_pkg")
            MISSING_NIX+=("$nix_pkg")
        fi
    done
<<<<<<< HEAD
    if [ "$IS_NIXOS" = "0" ]; then
        for row in "${FILE_DEPS[@]}"; do
            IFS='|' read -r path pkg why <<<"$row"
            if [ -e "$path" ]; then ok "$pkg"
            else warn "missing $pkg — $why"; MISSING_ARCH+=("$pkg"); fi
        done
    fi
    if fc-list 2>/dev/null | grep -iE "JetBrainsMono.*Nerd|JetBrains Mono Nerd" >/dev/null; then
        ok "JetBrainsMono Nerd Font"
    else
        warn "missing the Nerd Font — every icon is a glyph"
        MISSING_ARCH+=("$FONT_PKG_ARCH")
        MISSING_NIX+=("$FONT_PKG_NIX")
=======
    for row in "${FILE_DEPS[@]}"; do
        IFS='|' read -r path pkg why <<<"$row"
        if [ -e "$path" ]; then ok "$pkg"
        else warn "missing $pkg — $why"; MISSING+=("$pkg"); fi
    done
    if fc-list 2>/dev/null | grep -i "JetBrainsMono.*Nerd" >/dev/null; then ok "JetBrainsMono Nerd Font"
    else warn "missing the Nerd Font — every icon is a glyph"; MISSING+=("$FONT_PKG"); fi
    if [ "$PKG_MGR" = "pacman" ]; then
        MISSING+=("${EXTRA_PKGS[@]}")
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
    fi
}

aur_helper() {
    for h in yay paru pikaur; do command -v "$h" >/dev/null 2>&1 && { echo "$h"; return; }; done
}

install_aur_helper() {
    ask "quickshell and a couple other packages are in AUR, but no helper is installed. Build yay?" || return 1

    $SUDO pacman -S --needed --noconfirm base-devel git >/dev/null 2>&1 || {
        warn "could not install base-devel and git — yay needs both"; return 1; }

    local tmp; tmp="$(mktemp -d)" || return 1
    (
        cd "$tmp" || exit 1
        git clone -q --depth 1 https://aur.archlinux.org/yay-bin.git || exit 1
        cd yay-bin || exit 1
        makepkg -si --noconfirm
    ) >/dev/null 2>&1
    local rc=$?
    rm -rf "$tmp"

    if [ $rc -eq 0 ] && command -v yay >/dev/null 2>&1; then
        ok "yay built and installed"; return 0
    fi
    warn "could not build yay — install it by hand, then rerun"
    return 1
}

check_aur_helper() {
    if [ "$IS_NIXOS" = "1" ]; then
        return 0
    fi
    local h; h=$(aur_helper)
    if [ -n "$h" ]; then
        ok "AUR helper: $h — skipping"
        return 0
    fi
    install_aur_helper || warn "no AUR helper — packages from the AUR will be skipped"
}

<<<<<<< HEAD
install_deps() {
    if [ "$IS_NIXOS" = "1" ]; then
        local uniq_nix=()
        if [ ${#MISSING_NIX[@]} -gt 0 ]; then
            mapfile -t uniq_nix < <(printf '%s\n' "${MISSING_NIX[@]}" | sort -u)
        fi
        if [ ${#uniq_nix[@]} -eq 0 ]; then
            ok "all dependencies in place on NixOS"
            return 0
        fi
        warn "NixOS detected: missing ${#uniq_nix[@]} packages/dependencies."
        if [ -f /etc/nixos/configuration.nix ]; then
            if ask "Automatically inject missing dependencies into /etc/nixos/configuration.nix and run 'nixos-rebuild switch'?"; then
                step "Injecting Panacea dependencies into NixOS configuration"
                if [ -x "$SRC/nix/inject-config.sh" ]; then
                    $SUDO "$SRC/nix/inject-config.sh" "/etc/nixos/configuration.nix" "$USER" 1 || warn "nixos-rebuild switch finished with warnings"
                    ok "NixOS configuration updated"
                    return 0
                fi
            fi
        fi

        printf '\n%s  To install missing packages manually, add them to your /etc/nixos/configuration.nix:%s\n' "$B" "$N"
        printf '%s  environment.systemPackages = with pkgs; [\n' "$DIM"
        for p in "${uniq_nix[@]}"; do
            printf '    %s\n' "$p"
        done
        printf '  ];%s\n\n' "$DIM"
        printf '  Or run directly: sudo ./nix/inject-config.sh\n\n'
        if [ "$ASSUME_YES" != "1" ]; then
            ask "Continue with dotfiles configuration?" || return 1
        fi
        return 0
    fi

    command -v pacman >/dev/null 2>&1 || {
        warn "not an Arch system — install these yourself, then rerun with --no-deps:"
        printf '    %s\n' "${MISSING_ARCH[@]}"; return 1
    }
    local uniq; mapfile -t uniq < <(printf '%s\n' "${MISSING_ARCH[@]}" "${EXTRA_PKGS_ARCH[@]}" | sort -u)
=======
# ------------------------------------------------------------------- standalone helpers
ensure_nerd_font() {
    if fc-list 2>/dev/null | grep -i "JetBrainsMono.*Nerd" >/dev/null; then
        ok "JetBrainsMono Nerd Font present"
        return 0
    fi
    step "Installing JetBrains Mono Nerd Font..."
    local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
    mkdir -p "$font_dir"
    if command -v curl >/dev/null 2>&1; then
        local tmp_font; tmp_font="$(mktemp -d)"
        if curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" -o "$tmp_font/jb.tar.xz"; then
            tar -xf "$tmp_font/jb.tar.xz" -C "$font_dir" 2>/dev/null
            fc-cache -f "$font_dir" >/dev/null 2>&1 || true
            rm -rf "$tmp_font"
            ok "JetBrains Mono Nerd Font installed to ~/.local/share/fonts"
            return 0
        fi
        rm -rf "$tmp_font"
    fi
    warn "could not download JetBrains Mono Nerd Font"
    return 1
}

ensure_yazi() {
    command -v yazi >/dev/null 2>&1 && return 0
    step "Installing Yazi (file manager for terminal)..."
    mkdir -p "$HOME/.local/bin"
    local tmp_yazi; tmp_yazi="$(mktemp -d)"
    if curl -sL "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-musl.zip" -o "$tmp_yazi/yazi.zip" 2>/dev/null; then
        if command -v unzip >/dev/null 2>&1; then
            unzip -q "$tmp_yazi/yazi.zip" -d "$tmp_yazi"
            cp "$tmp_yazi"/yazi-*/yazi "$HOME/.local/bin/" 2>/dev/null || cp "$tmp_yazi"/yazi "$HOME/.local/bin/" 2>/dev/null
            chmod +x "$HOME/.local/bin/yazi"
            ok "Yazi installed to ~/.local/bin/yazi"
        fi
    fi
    rm -rf "$tmp_yazi"
}

ensure_bat_symlink() {
    if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        ok "bat alias linked to batcat"
    fi
}

ensure_bibata_cursor() {
    local icon_dir="$HOME/.local/share/icons/Bibata-Modern-Classic"
    [ -d "$icon_dir" ] || [ -d "/usr/share/icons/Bibata-Modern-Classic" ] && return 0
    mkdir -p "$HOME/.local/share/icons"
    local tmp_cur; tmp_cur="$(mktemp -d)"
    if curl -sL "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz" -o "$tmp_cur/bibata.tar.xz" 2>/dev/null; then
        tar -xf "$tmp_cur/bibata.tar.xz" -C "$HOME/.local/share/icons/" 2>/dev/null
        ok "Bibata Modern Classic cursor installed"
    fi
    rm -rf "$tmp_cur"
}

ensure_quickshell() {
    command -v qs >/dev/null 2>&1 || command -v quickshell >/dev/null 2>&1 && return 0
    step "Installing Quickshell..."
    if [ "$PKG_MGR" = "apt" ]; then
        local qt_dir="$HOME/Qt/6.7.3/gcc_64"
        if [ ! -d "$qt_dir" ]; then
            step "Installing Qt 6.7.3 via aqtinstall for Quickshell..."
            pip3 install --quiet --break-system-packages aqtinstall 2>/dev/null || pip install --quiet aqtinstall 2>/dev/null || true
            python3 -m aqt install-qt linux desktop 6.7.3 linux_gcc_64 -O "$HOME/Qt" -m qtshadertools qtmultimedia >/dev/null 2>&1 || true
        fi
        if [ -d "$qt_dir" ]; then
            local build_tmp; build_tmp="$(mktemp -d)"
            (
                cd "$build_tmp" || exit 1
                git clone --depth 1 -q https://github.com/quickshell-mirror/quickshell.git || exit 1
                cd quickshell || exit 1
                cmake -GNinja -B build -DCMAKE_BUILD_TYPE=Release \
                  -DCMAKE_PREFIX_PATH="$qt_dir" \
                  -DCMAKE_CXX_COMPILER=clang++ \
                  -DCRASH_HANDLER=OFF -DX11=OFF -DI3=OFF -DI3_IPC=OFF \
                  -DSERVICE_PAM=ON -DSERVICE_POLKIT=ON -DSCREENCOPY=ON \
                  -DNO_PCH=ON \
                  -DINSTALL_QMLDIR="$qt_dir/qml" >/dev/null 2>&1 || exit 1
                cmake --build build >/dev/null 2>&1 || exit 1
                $SUDO cmake --install build >/dev/null 2>&1 || exit 1
            )
            rm -rf "$build_tmp"
            if command -v qs >/dev/null 2>&1 || command -v quickshell >/dev/null 2>&1; then
                ok "Quickshell built and installed successfully"
                return 0
            fi
        fi
    fi
    warn "Quickshell not found — see docs/other-distros.md for instructions"
    return 1
}

# ------------------------------------------------------------------- distro package installers
install_deps_arch() {
    local uniq; mapfile -t uniq < <(printf '%s\n' "${MISSING[@]}" | sort -u)
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
    local repo=() aur=()
    for p in "${uniq[@]}"; do
        if pacman -Si "$p" >/dev/null 2>&1; then repo+=("$p"); else aur+=("$p"); fi
    done
    if [ ${#repo[@]} -gt 0 ]; then
        printf '  installing from the repos: %s\n' "${repo[*]}"
        $SUDO pacman -S --needed "${repo[@]}" || return 1
    fi
    if [ ${#aur[@]} -gt 0 ]; then
        local h; h=$(aur_helper)
        [ -z "$h" ] && { install_aur_helper && h=$(aur_helper); }
        [ -z "$h" ] && { warn "these are in the AUR — install yay or paru first: ${aur[*]}"; return 1; }
        printf '  installing from the AUR via %s: %s\n' "$h" "${aur[*]}"
        "$h" -S --needed "${aur[@]}" || return 1
    fi
    ok "dependencies in place"
}

install_deps_debian() {
    step "Updating package lists (apt)..."
    $SUDO apt-get update -qq || true

    local deb_pkgs=(
        hyprland fish foot swaylock jq wl-clipboard cliphist grim slurp ffmpeg wf-recorder
        wtype brightnessctl ddcutil playerctl wireplumber eza zoxide bat fastfetch python3
        openssl xdg-utils libglib2.0-bin upower util-linux cava curl file git pciutils unzip
        qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-shapes
        qml6-module-qtquick-effects qml6-module-qtmultimedia power-profiles-daemon bluez
        iwd papirus-icon-theme fonts-noto-core fonts-noto-color-emoji fonts-noto-cjk
        fonts-noto-extra udisks2 udiskie gvfs gvfs-backends python3-secretstorage
        python3-cryptography os-prober
        cmake ninja-build pkg-config clang qt6-base-dev qt6-declarative-dev qt6-shadertools-dev
        qt6-wayland-dev libqt6svg6-dev qt6-declarative-private-dev qt6-base-private-dev
        qt6-wayland-private-dev libdrm-dev libwayland-dev wayland-protocols libwayland-bin
        libxkbcommon-dev libpipewire-0.3-dev spirv-tools libcli11-dev libjemalloc-dev
        libpam0g-dev libpolkit-agent-1-dev libglib2.0-dev libgbm-dev
    )

    printf '  installing packages via apt...\n'
    $SUDO apt-get install -y --no-install-recommends "${deb_pkgs[@]}" 2>/dev/null || {
        for p in "${deb_pkgs[@]}"; do
            $SUDO apt-get install -y --no-install-recommends "$p" >/dev/null 2>&1 || true
        done
    }

    ensure_bat_symlink
    ensure_nerd_font
    ensure_yazi
    ensure_quickshell
    ensure_bibata_cursor
    ok "dependencies in place for $DISTRO"
}

install_deps_fedora() {
    step "Setting up packages (dnf)..."
    $SUDO dnf copr enable -y solopasha/hyprland 2>/dev/null || true

    local fedora_pkgs=(
        hyprland quickshell fish foot hyprpaper hyprsunset swaylock jq wl-clipboard cliphist
        grim slurp ffmpeg wf-recorder wtype brightnessctl ddcutil playerctl wireplumber
        eza zoxide bat fastfetch yazi python3 openssl xdg-utils glib2 upower util-linux
        cava curl file git pciutils unzip qt6-qtmultimedia qt6-qtdeclarative power-profiles-daemon
        bluez iwd papirus-icon-theme google-noto-fonts-common google-noto-emoji-fonts
        google-noto-cjk-fonts udisks2 udiskie gvfs gvfs-mtp python3-secretstorage
        python3-cryptography os-prober
    )

    printf '  installing packages via dnf...\n'
    $SUDO dnf install -y "${fedora_pkgs[@]}" 2>/dev/null || {
        for p in "${fedora_pkgs[@]}"; do
            $SUDO dnf install -y "$p" >/dev/null 2>&1 || true
        done
    }

    ensure_nerd_font
    ensure_yazi
    ensure_quickshell
    ensure_bibata_cursor
    ok "dependencies in place for $DISTRO"
}

install_deps_opensuse() {
    local suse_pkgs=(
        hyprland fish foot swaylock jq wl-clipboard cliphist grim slurp ffmpeg wf-recorder
        wtype brightnessctl ddcutil playerctl wireplumber eza zoxide bat fastfetch python3
        openssl xdg-utils glib2-tools upower util-linux cava curl file git pciutils unzip
        libqt6-multimedia libqt6-declarative power-profiles-daemon bluez iwd papirus-icon-theme
        noto-sans-fonts noto-coloremoji-fonts udisks2 udiskie gvfs gvfs-backend-mtp
        python3-SecretStorage python3-cryptography os-prober
    )
    $SUDO zypper --non-interactive install --no-recommends "${suse_pkgs[@]}" 2>/dev/null || {
        for p in "${suse_pkgs[@]}"; do
            $SUDO zypper --non-interactive install --no-recommends "$p" >/dev/null 2>&1 || true
        done
    }
    ensure_nerd_font
    ensure_yazi
    ensure_quickshell
    ensure_bibata_cursor
    ok "dependencies in place for $DISTRO"
}

install_deps_generic() {
    warn "generic/unsupported distribution ($DISTRO) — attempting standalone setup"
    ensure_nerd_font
    ensure_yazi
    ensure_bibata_cursor
    ensure_quickshell
}

install_deps() {
    detect_distro
    step "Installing dependencies for $DISTRO (using $PKG_MGR)..."

    case "$PKG_MGR" in
        pacman) install_deps_arch ;;
        apt)    install_deps_debian ;;
        dnf)    install_deps_fedora ;;
        zypper) install_deps_opensuse ;;
        *)      install_deps_generic ;;
    esac
}

# --------------------------------------------------------------------- copying
# How many copies of one directory to store. The purpose of the copy is to return someone else’s config,
# if you didn't like the setup, and it needs the latter, not the story.
# Without limit, copies accumulate silently: during development, the installation is chasing
# ten times a day, and together with the wallpaper catalog this amounts to hundreds of megabytes
# in ~/.config that no one asked for.

BACKUP_KEEP=3

backup() {
<<<<<<< HEAD
    [ -e "$1" ] || return 0
    # Update: mine has already been saved via KEEP, the rest are repository files.
    # We just remove the old one without leaving .bak, otherwise ~/.config will become overgrown
    # duplicate directories after each update.

=======
    [ -e "$1" ] || [ -L "$1" ] || return 0
    # Обновление: своё уже сохранено через KEEP, остальное — файлы репозитория.
    # Делаем резервную копию в *.bak-update на случай, если пользователь правил
    # файлы напрямую. Две предыдущие копии храним на случай, если правки
    # заметят потерянными только после следующего обновления.
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
    if [ "$DO_BACKUP" = "0" ]; then
        if [ -e "$1.bak-update" ] || [ -L "$1.bak-update" ]; then
            mv "$1.bak-update" "$1.bak-update-$STAMP-$$" || return 1
        fi
        cp -a "$1" "$1.bak-update" || return 1
        rm -rf -- "$1" || return 1
        local old_update
        while IFS= read -r old_update; do
            [ -n "$old_update" ] && rm -rf -- "$old_update"
        done < <(ls -d "$1".bak-update-* 2>/dev/null | sort | head -n -2)
        return 0
    fi
    mv "$1" "$1.bak-$STAMP" || return 1
    warn "existing $(basename "$1") saved as $(basename "$1").bak-$STAMP"

    # Copies are named by time, so regular sorting is also
    # chronological: fresh in the tail, everything before them is demolished.

    local old
    while IFS= read -r old; do
        [ -n "$old" ] && rm -rf -- "$old"
    done < <(ls -d "$1".bak-* 2>/dev/null | grep -v -F "$1.bak-update" | sort | head -n "-$BACKUP_KEEP")
}

# ------------------------------------------------------------- your condition
# What belongs to the person, not the repository. The installer takes away the directories
# entirely and puts in fresh ones - the settings left along with the old directory
# Super+I windows, keyboard shortcuts and wallpaper, and after each reinstallation man
# received the factory shell. We take ours aside before copying and
# we return after. The list is the same as in scripts/update.sh.

KEEP_FILES=(
    "panacea/settings.json"
    "panacea/clipboard_pins.json"
    "panacea/last_wifi_ssid"
    "hypr/lua/binds_data.lua"
<<<<<<< HEAD
    # Screen settings: resolution, frequency, scale. binds_data.lua is already here
    # is, but these brothers are not, and after the update the panel scale is silent
    # returned to 100%. monitors_data.lua is read by the linker at startup (path
    # Lua), monitors.conf - backup config for Hyprland without Lua; both
    # are derived from settings.json, but they must survive the update themselves: for now
    # The shell will roll over at the start, the monitor will have time to rise to “preferred”.

=======
    "hypr/lua/input_data.lua"
    "hypr/input_data.conf"
    # Настройки экрана: разрешение, частота, масштаб. binds_data.lua здесь уже
    # есть, а эти его собратья — нет, и после обновления масштаб панели молча
    # возвращался к 100%. monitors_data.lua читает компоновщик на старте (путь
    # Lua), monitors.conf — запасной конфиг для Hyprland без Lua; оба
    # производны от settings.json, но пережить обновление обязаны сами: пока
    # оболочка на старте накатит своё, монитор успеет подняться в "preferred".
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
    "hypr/lua/monitors_data.lua"
    "hypr/monitors.conf"
    # Terminal transparency: generated from settings.json, read
    # windowrules.lua at start. Without it - factory opacity.

    "hypr/lua/term_data.lua"
    # Digital vibrance: meaning lives here, from here
    # vibrance.sh restore rebuilds the shader.

    "panacea/.vibrance"
    # The saturation shader itself. The repository does not supply it (it is generated),
    # so the fresh hypr/ arrives without it - and the linker is before the restart
    # the shell holds the decoration:screen_shader link to this path and swears
    # banner “Failed to check screen shader path”. We save the file ourselves.

    "hypr/shaders/vibrance.frag"
    # Selected wallpaper. The repository has its own wallpaper.conf, and it went
    # on top - after each update the table returned to ember_stripes,
    # although the picture itself did not disappear: the catalog with wallpaper was saved, but
    # not a record of which one is selected.

    "hypr/wallpaper.conf"
    # Live wallpapers are from the same series: their path is also remembered in a separate file.

    "hypr/hyprpaper.conf"
    # Цвет фона терминала под текущую тему: пишет его оболочка при смене
    # темы, а в репозитории лежит пустая заготовка (она нужна только чтобы
    # include в foot.ini не падал до первого запуска). Без сохранения
    # обновление возвращало бы терминалу общий фон палитры.
    "foot/panacea-theme"
    # Пользовательские настройки терминала foot
    "foot/foot.ini"
    "foot/custom.ini"
    # Пользовательский конфиг Niri
    "niri/config.kdl"
    # Пользовательские настройки shell fish
    "fish/config.fish"
    "fish/custom.fish"
    "fish/fish_variables"
    # Пользовательские настройки fastfetch
    "fastfetch/config.jsonc"
    "fastfetch/custom.jsonc"
    # Пользовательский конфиг voxtype
    "voxtype/config.toml"
)
KEEP_DIRS=(
    "hypr/wallpaper"
    "hypr/custom"
    "niri/custom"
    "foot/custom"
    "fish/custom"
    "fish/functions"
    "fish/conf.d"
    "fastfetch/custom"
    "panacea/custom"
    "panacea/scripts/custom"
    "panacea/assets"
)
KEEP_STASH=""

# We put the stash next to the config, and not in /tmp, and we transfer directories, not
# copy.
#
# /tmp is almost everywhere tmpfs, that is, RAM. From the one who downloaded
# a set of wallpapers, there are hundreds of megabytes in hypr/wallpaper: they were leaving for memory
# entirely, and twice more - update.sh also makes its own stash. By car, where
# there is not enough memory, it went into swap, and the update got stuck on
# out of the blue for minutes.
#
# Within one section, a transfer is a renaming: it does not depend on
# volume at all. On four hundred megabytes, 164 ms versus 1 ms were measured.
#
# The files (their units are kilobytes) are still copied: the transfer would return them
# into place only if the outcome is successful, and the settings must survive failure.

keep_stash() {
    KEEP_STASH="$CONF/.panacea-stash-$$"
    rm -rf "$KEEP_STASH"
    mkdir -p "$KEEP_STASH" || { KEEP_STASH=""; return 0; }
    local f
    for f in "${KEEP_FILES[@]}"; do
        [ -e "$CONF/$f" ] || [ -L "$CONF/$f" ] || continue
        mkdir -p "$KEEP_STASH/$(dirname "$f")"
        cp -a "$CONF/$f" "$KEEP_STASH/$f"
    done
    for f in "${KEEP_DIRS[@]}"; do
        [ -d "$CONF/$f" ] || continue
        mkdir -p "$KEEP_STASH/$(dirname "$f")"
        mv "$CONF/$f" "$KEEP_STASH/$f" 2>/dev/null \
            || cp -a "$CONF/$f" "$KEEP_STASH/$f"
    done
    # If the installation breaks down, we will return what was taken away to its place: without this wallpaper
    # would remain lying in a hidden directory, and the person would decide that they
    # erased.

    trap 'keep_restore' EXIT INT TERM
}

keep_restore() {
    [ -n "$KEEP_STASH" ] && [ -d "$KEEP_STASH" ] || return 0
    local f restored=0
    for f in "${KEEP_FILES[@]}"; do
        [ -e "$KEEP_STASH/$f" ] || [ -L "$KEEP_STASH/$f" ] || continue
        mkdir -p "$CONF/$(dirname "$f")"
        if [ "$f" = "panacea/settings.json" ] && command -v jq >/dev/null 2>&1 && [ -f "$CONF/$f" ]; then
            local tmp_json
            tmp_json="$(mktemp)"
            if jq -s '.[0] * .[1]' "$CONF/$f" "$KEEP_STASH/$f" > "$tmp_json" 2>/dev/null; then
                mv "$tmp_json" "$CONF/$f"
                restored=1
            else
                rm -f "$tmp_json"
                cp -a "$KEEP_STASH/$f" "$CONF/$f" && restored=1
            fi
        else
            cp -a "$KEEP_STASH/$f" "$CONF/$f" && restored=1
        fi
    done
    # We merge the directories into the new one, and do not replace it with it: the repo version contains its own
    # files (logos, default wallpaper), and `cp -r dir dst` on existing
    # catalog would put ours inside it as an attached copy.
    #
    # We transfer the contents one at a time: within a section this is renaming,
    # and a set of wallpapers worth hundreds of megabytes is returned instantly. Matched
    # names overlap with usernames - this happened before.
    #
    # If the transfer fails (the stash is suddenly on another partition), we fall to
    # copying and talk about it: on a large set of wallpapers it takes
    # noticeable time, and the silent installer appears frozen.

    local item base moved_all
    for f in "${KEEP_DIRS[@]}"; do
        [ -d "$KEEP_STASH/$f" ] || continue
        mkdir -p "$CONF/$f"
        moved_all=1
        for item in "$KEEP_STASH/$f"/* "$KEEP_STASH/$f"/.[!.]*; do
            [ -e "$item" ] || [ -L "$item" ] || continue
            base="$(basename "$item")"
            rm -rf "$CONF/$f/$base"
            mv "$item" "$CONF/$f/$base" 2>/dev/null || moved_all=0
        done
        if [ "$moved_all" = "0" ]; then
            printf '  copying %s back (%s) — this can take a while\n' \
                "$f" "$(du -sh "$KEEP_STASH/$f" 2>/dev/null | cut -f1)"
            cp -a "$KEEP_STASH/$f/." "$CONF/$f/"
        fi
        restored=1
    done
    rm -rf "$KEEP_STASH"; KEEP_STASH=""
    trap - EXIT INT TERM
    [ "$restored" = "1" ] && ok "your settings, shortcuts and wallpapers kept"
    return 0
}

copy_into_config() {   # copy_into_config <dir-in-repo>
    local name="$1" dst="$CONF/$1"
    [ -d "$SRC/$name" ] || { warn "no $name in this checkout — skipping"; return; }
<<<<<<< HEAD
    backup "$dst"
    cp -r "$SRC/$name" "$dst"
    # The clean clone from GitHub does not contain them (*.bak in .gitignore), but the dirty one
    # The maintainer's checkout could have brought it in - and cp would have taken them to ~/.config. Not
    # dragging someone else's garbage into the config.

=======
    backup "$dst" || return 1
    if ! cp -a "$SRC/$name" "$dst"; then
        rm -rf -- "$dst"
        if [ "$DO_BACKUP" = "0" ]; then
            cp -a "$dst.bak-update" "$dst" 2>/dev/null || true
        else
            mv "$dst.bak-$STAMP" "$dst" 2>/dev/null || true
        fi
        return 1
    fi
    # Чистый клон с GitHub их не содержит (*.bak в .gitignore), но грязный
    # checkout мейнтейнера мог занести — и cp унёс бы их в ~/.config. Не
    # тащим чужой мусор в конфиг.
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
    find "$dst" -name '*.bak*' -exec rm -rf {} + 2>/dev/null
    ok "$name → $dst"
}

install_configs() {
    mkdir -p "$CONF" "$HOME/.local/bin"
    keep_stash
    for d in panacea hypr niri foot fish fastfetch nano; do
        if [ -d "$SRC/$d" ]; then
            copy_into_config "$d" || die "could not replace $d without losing its backup"
        fi
    done
    keep_restore
    # nanorc lives at ~/.nanorc, not in a directory. Не перезаписываем существующий конфиг
    if [ -f "$SRC/nano/nanorc" ]; then
        if [ ! -f "$HOME/.nanorc" ]; then
            cp "$SRC/nano/nanorc" "$HOME/.nanorc" && ok "nanorc → ~/.nanorc"
        fi
    fi
    if [ -d "$SRC/bin" ]; then
        cp "$SRC"/bin/* "$HOME/.local/bin/" 2>/dev/null
        chmod +x "$HOME"/.local/bin/* 2>/dev/null
        ok "helper scripts → ~/.local/bin"
    fi
    chmod +x "$CONF"/panacea/scripts/*.sh 2>/dev/null
    chmod +x "$CONF"/panacea/scripts/*.py 2>/dev/null
    chmod +x "$CONF"/hypr/scripts/*.sh 2>/dev/null
<<<<<<< HEAD
    # Quickshell looks for configurations in ~/.config/quickshell/<name>/shell.qml, and
    # without this link, a simple `qs` responds with “default configuration not found”
    # - this is what happened to everyone who tried to launch the shell by hand. Link
    # gives the standard `qs -c panacea`, without moving the config itself from its usual place.

=======
    chmod +x "$CONF"/niri/scripts/*.sh 2>/dev/null
    # Quickshell ищет конфигурации в ~/.config/quickshell/<имя>/shell.qml, и
    # без этой ссылки простое `qs` отвечает «не найдена конфигурация default»
    # — так и было у всех, кто пробовал запустить оболочку руками. Ссылка
    # даёт штатное `qs -c panacea`, не перенося сам конфиг с привычного места.
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
    mkdir -p "$CONF/quickshell"
    if [ ! -e "$CONF/quickshell/panacea" ]; then
        ln -sfn "$CONF/panacea" "$CONF/quickshell/panacea" \
            && ok "qs -c panacea → $CONF/panacea"
    fi

    # The terminal is launched by the server, and it reads its config once, when
    # start. Fresh foot.ini does not reach the running server - and, say,
    # transparency remains the same even in new windows because clients
    # inherit settings from it. We won’t kill the server ourselves: together with
    # it will close all open terminals, and there is work in them.

    if pgrep -x foot >/dev/null 2>&1; then
        # It is a restart, not a pkill: autostart of the linker works
        # once per session and the killed server will not rise again - terminal
        # After that it will stop opening altogether.

        printf '  note: the terminal server holds settings from login; restart it for the new ones:\n'
        printf '        pkill -x foot; setsid -f foot --server\n'
        printf '        (or press "Restart the terminal" in Settings → Appearance)\n'
    fi

    # live wallpaper directory: carousel opens it with a button and it should
    # exist before anything is put there

    mkdir -p "$CONF/hypr/wallpaper/live"

    # Hyprland only reads keyboard shortcuts from lua/binds_data.lua, and the window
    # Super+/ writes them to settings.json and rebuilds this file. If the file
    # no, but there are combinations in the settings - they don’t work silently, and the person
    # sees factory ones. We collect it from settings.json to be the source of truth
    # there was only one file left, and this one was just a derivative of it.

    if [ ! -f "$CONF/hypr/lua/binds_data.lua" ] && [ -f "$CONF/panacea/settings.json" ]; then
        if [ -x "$CONF/panacea/scripts/genbinds.sh" ]; then
            "$CONF/panacea/scripts/genbinds.sh" >/dev/null 2>&1 \
                && ok "keyboard shortcuts rebuilt from your settings"
        fi
    fi

    # The same goes for screen settings. The mode must be in the linker config, and
    # not exposed by the shell on the go: Qt binds the animation timer to
    # refresh rate at the time the first window is created, and on the monitor,
    # which went up to "preferred" (via HDMI this is often 60 Hz), animations and
    # will remain sixty frames - on a panel that has long gone to 144.

    if [ -x "$CONF/panacea/scripts/genmonitors.sh" ] && [ -f "$CONF/panacea/settings.json" ]; then
        "$CONF/panacea/scripts/genmonitors.sh" >/dev/null 2>&1
        [ -f "$CONF/hypr/lua/monitors_data.lua" ] \
            && ok "screen mode written into the compositor config"
    fi

<<<<<<< HEAD
    # Voxtype config (voice → text): add ours if you don’t have yours yet. Right
    # Alt listens to Hyprland, and not voxtype itself, so in our config the built-in
    # hotkey is turned off. We don’t touch someone else’s config.

    if [ ! -f "$CONF/voxtype/config.toml" ] \
       && [ -f "$CONF/panacea/scripts/voxtype.config.toml" ]; then
=======
    if [ -x "$CONF/panacea/scripts/geninput.sh" ] && [ -f "$CONF/panacea/settings.json" ]; then
        "$CONF/panacea/scripts/geninput.sh" >/dev/null 2>&1 \
            && ok "keyboard layouts written into the compositor config"
    fi

    # Конфиг voxtype (голос → текст): кладём наш. Правый
    # Alt слушает Hyprland, а не сам voxtype, поэтому в нашем конфиге встроенный
    # хоткей выключен.
    if [ -f "$CONF/panacea/scripts/voxtype.config.toml" ] && [ ! -f "$CONF/voxtype/config.toml" ]; then
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
        mkdir -p "$CONF/voxtype"
        cp "$CONF/panacea/scripts/voxtype.config.toml" "$CONF/voxtype/config.toml" \
            && ok "voxtype config written (voice-to-text on Right Alt, Russian, VAD, GPU)"
    fi

    stamp_version
    personalize_paths
}

# What version did you install? Based on this mark, the shell then understands that
# GitHub has something new and offers to update. Installed from a clone -
# take the hash directly from it; from the archive - we ask the end of the branch from GitHub.

stamp_version() {
    local sha="" ver=""
    if [ -f "$SRC/panacea/VERSION" ]; then
        ver="$(tr -d ' \r\n' < "$SRC/panacea/VERSION")"
    elif [ -f "$SRC/VERSION" ]; then
        ver="$(tr -d ' \r\n' < "$SRC/VERSION")"
    elif [ -f "$SRC/panacea/shell.qml" ]; then
        ver="$(grep -oP 'readonly property string version: "\K[^"]+' "$SRC/panacea/shell.qml" 2>/dev/null)"
    fi

    if [ -d "$SRC/.git" ] && command -v git >/dev/null 2>&1; then
        sha="$(git -C "$SRC" rev-parse HEAD 2>/dev/null)"
    fi
    if [ -z "$sha" ] && command -v git >/dev/null 2>&1; then
        sha="$(git ls-remote https://github.com/EnsixD/Panacea.git main 2>/dev/null | cut -f1)"
    fi

    [ -n "$ver" ] && printf '%s\n' "$ver" > "$CONF/panacea/VERSION"

    if [ -n "$sha" ]; then
        printf '%s\n' "$sha" > "$CONF/panacea/.version"
        ok "version stamp ${ver:-${sha:0:7}}"
    elif [ -n "$ver" ]; then
        printf '%s\n' "$ver" > "$CONF/panacea/.version"
        ok "version stamp $ver"
    else
        warn "could not determine version — the shell will not offer updates"
    fi
}

# In the repository, some of the paths are written as /home/ensi - that’s how the author wrote them.
# On someone else's car, it silently broke the wallpaper, themes (the theme stopped
# recover after reboot) and multimedia keys.
# After copying, we copy them to the home directory of the person installing them.

personalize_paths() {
    [ "$HOME" = "/home/ensi" ] && return 0
    local n=0
    while IFS= read -r f; do
        sed -i "s|/home/ensi|$HOME|g" "$f" && n=$((n + 1))
    done < <(grep -rl '/home/ensi' "$CONF" "$HOME/.local/bin" 2>/dev/null)
    [ "$n" -gt 0 ] && ok "paths rewritten to $HOME in $n files"
    return 0
}

## ------------------------------------------------------------------- services
enable_services() {
    if [ "$IS_NIXOS" = "1" ]; then
        local inactive=()
        for svc in bluetooth power-profiles-daemon iwd upower; do
            if systemctl is-active --quiet "$svc" 2>/dev/null || systemctl is-active --quiet "$svc.service" 2>/dev/null; then
                ok "$svc is active"
            else
                inactive+=("$svc")
            fi
        done
        if [ ${#inactive[@]} -gt 0 ]; then
            warn "Services not yet active in NixOS: ${inactive[*]}"
            printf '        enable them in /etc/nixos/configuration.nix:\n'
            printf '        networking = {\n'
            printf '          wireless.iwd.enable = true;\n'
            printf '          wireless.iwd.settings.General.EnableNetworkConfiguration = true;\n'
            printf '          wireless.enable = false;\n'
            printf '          networkmanager.enable = false;\n'
            printf '        };\n'
            printf '        services.power-profiles-daemon.enable = true;\n'
            printf '        hardware.bluetooth.enable = true;\n'
            printf '        services.upower.enable = true;\n'
        fi
        command -v rfkill >/dev/null 2>&1 && rfkill unblock all 2>/dev/null
        mask_rival_notifiers
        return 0
    fi

    command -v systemctl >/dev/null 2>&1 || return 0
    # Bluetooth and power profiles are what the pill talks to; iwd backs Wi-Fi,
    # upower feeds the charge indicator in the pill and the battery page.
    for svc in bluetooth power-profiles-daemon iwd upower; do
        if systemctl list-unit-files "$svc.service" >/dev/null 2>&1; then
            $SUDO systemctl enable --now "$svc.service" >/dev/null 2>&1 \
                && ok "$svc enabled" || warn "could not enable $svc"
        fi
    done

    # NetworkManager + iwd integration (Ubuntu, Mint, Debian, Fedora)
    if systemctl is-active NetworkManager.service >/dev/null 2>&1 || systemctl list-unit-files NetworkManager.service >/dev/null 2>&1; then
        if command -v iwd >/dev/null 2>&1; then
            $SUDO mkdir -p /etc/NetworkManager/conf.d
            printf '[device]\nwifi.backend=iwd\n' | $SUDO tee /etc/NetworkManager/conf.d/wifi_backend.conf >/dev/null 2>&1 \
                && ok "NetworkManager configured to use iwd backend" || true
            $SUDO systemctl restart NetworkManager >/dev/null 2>&1 || true
        fi
    fi

    # soft-unblock radios so Bluetooth/Wi-Fi come up without a manual rfkill
    command -v rfkill >/dev/null 2>&1 && rfkill unblock all 2>/dev/null

<<<<<<< HEAD
    # voxtype (voice → text): daemon accepts `voxtype record start/stop`,
    # which Hyprland pulls on the right Alt. You only need one model, and it's big.
    # (hundreds of MB) - download only with consent. We enable a custom service.

    if command -v voxtype >/dev/null 2>&1; then
        if ask "Download the voxtype speech model (~hundreds of MB) for voice-to-text?"; then
            voxtype setup --download --model medium >/dev/null 2>&1 \
                && ok "voxtype model downloaded" || warn "voxtype model download failed"
=======
    # voxtype (голос → текст): демон принимает `voxtype record start/stop`,
    # которые дёргает Hyprland по правому Alt. Модель нужна одна (medium ~1.5 GB),
    # плюс VAD модель (Silero VAD) для фильтрации фонового шума и тишины.
    local vox_cmd
    vox_cmd="$(command -v voxtype 2>/dev/null || true)"
    [ -z "$vox_cmd" ] && [ -x "/usr/lib/voxtype/voxtype-vulkan" ] && vox_cmd="/usr/lib/voxtype/voxtype-vulkan"
    [ -z "$vox_cmd" ] && [ -x "/usr/bin/voxtype" ] && vox_cmd="/usr/bin/voxtype"

    if [ -n "$vox_cmd" ]; then
        local models_dir="$HOME/.local/share/voxtype/models"
        mkdir -p "$models_dir" "$CONF/systemd/user/voxtype.service.d" "$HOME/.local/bin"

        # GPU acceleration (Vulkan)
        if [ -x "/usr/lib/voxtype/voxtype-vulkan" ]; then
            ln -sf /usr/lib/voxtype/voxtype-vulkan "$HOME/.local/bin/voxtype"
            cat << 'EOF' > "$CONF/systemd/user/voxtype.service.d/override.conf"
[Service]
ExecStart=
ExecStart=/usr/lib/voxtype/voxtype-vulkan -q daemon
Environment="VOXTYPE_VULKAN_DEVICE=amd"
EOF
            systemctl --user daemon-reload >/dev/null 2>&1 || true
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
        fi

        # Whisper speech model (medium ~1.5 GB)
        if [ ! -f "$models_dir/ggml-medium.bin" ]; then
            step "Downloading Whisper Medium speech model (~1.5 GB) for voxtype..."
            printf '  %sℹ%s Downloading ggml-medium.bin (this may take a few minutes depending on your internet connection)...%s\n' "$DIM" "$N" "$N"
            if command -v curl >/dev/null 2>&1; then
                curl -L --progress-bar "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin" -o "$models_dir/ggml-medium.bin" \
                    && ok "Whisper Medium model downloaded" \
                    || warn "Could not download Whisper Medium model via curl"
            else
                "$vox_cmd" setup --download --model medium >/dev/null 2>&1 \
                    && ok "Whisper Medium model downloaded" || warn "voxtype model download failed"
            fi
        else
            ok "Whisper Medium model already present"
        fi

        # Silero VAD model
        if [ ! -f "$models_dir/ggml-silero-vad.bin" ]; then
            if command -v curl >/dev/null 2>&1; then
                curl -sL "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-silero-vad.bin" -o "$models_dir/ggml-silero-vad.bin" 2>/dev/null || true
            fi
        fi

        "$vox_cmd" setup systemd >/dev/null 2>&1 || true
        systemctl --user enable --now voxtype.service >/dev/null 2>&1 \
            && ok "voxtype service enabled and active" \
            || warn "could not enable the voxtype service — enable it by hand: systemctl --user enable --now voxtype"
    fi

    mask_rival_notifiers
}

# The island itself serves as a notification daemon, and the name is org.freedesktop.Notifications on
# Only one process can occupy the bus. Losing this race doesn't look like
# breakdown: notifications arrive, they are simply drawn not by the shell, but by someone else’s daemon -
# through your window, past the island and past the palette.
#
# It's easy to lose the race. Neither dunst nor mako need to be launched: they are raised by itself
# bus on demand, and the first notification sent before the shell
# managed to register, turns on someone else's demon forever - until the end of the session.
# Therefore, it is not enough to stop the process, you need to close the path to launch: the unit mask is
# and it does, but dbus activation does not work without a unit.
#
# We do not touch the package: it could come as a dependency or remain from the previous build.
# The mask is removed with one command, and it is printed next to it.

mask_rival_notifiers() {
    local svc
    for svc in dunst mako; do
        systemctl --user list-unit-files "$svc.service" >/dev/null 2>&1 || continue
        [ "$(systemctl --user is-enabled "$svc.service" 2>/dev/null)" = "masked" ] && continue
        systemctl --user stop "$svc.service" >/dev/null 2>&1
        if systemctl --user mask "$svc.service" >/dev/null 2>&1; then
            ok "$svc masked — the island is the notification daemon"
            printf '        bring it back with: systemctl --user unmask %s\n' "$svc.service"
        else
            warn "$svc is installed and will take notifications away from the island"
        fi
    done
}

# ------------------------------------------------------------- SDDM login theme
# Экран входа обязан подняться до того, как мы отдадим ему свою тему.
#
# SDDM по умолчанию (в том числе на Arch) рисует greeter на X11: [General]
# DisplayServer=x11, и запускает /usr/bin/X. На минимальной установке под
# Wayland-оболочку иксов нет вовсе — и sddm.service молча уходит в цикл
# «запустился, не смог поднять дисплей, перезапустился». Со стороны это
# ровно то, о чём пишут: «система зависает на загрузке, тема не работает».
# Тема здесь ни при чём — до её чтения дело не доходит.
#
# Поэтому: иксы есть — не трогаем ничего, всё и так работает. Иксов нет —
# переводим greeter на Wayland и ставим ему компоновщик (weston, его же
# называет заводской CompositorCommand). Ни того, ни другого — не ставим
# тему и не включаем sddm вслепую, а говорим об этом вслух.
#
# Возвращает 0, если экран входа поднимется.
ensure_sddm_display_server() {
    if [ -x /usr/bin/X ] || [ -x /usr/bin/Xorg ]; then
        return 0
    fi

    warn "no X server here — SDDM would loop on boot with its default X11 greeter"

    if ! command -v weston >/dev/null 2>&1; then
        case "$PKG_MGR" in
            pacman) $SUDO pacman -S --needed --noconfirm weston >/dev/null 2>&1 ;;
            apt)    $SUDO apt-get install -y weston >/dev/null 2>&1 ;;
            dnf)    $SUDO dnf install -y weston >/dev/null 2>&1 ;;
            zypper) $SUDO zypper --non-interactive install weston >/dev/null 2>&1 ;;
            apk)    $SUDO apk add weston >/dev/null 2>&1 ;;
            xbps)   $SUDO xbps-install -y weston >/dev/null 2>&1 ;;
        esac
    fi

    if ! command -v weston >/dev/null 2>&1; then
        warn "could not install weston either — the login screen has nothing to draw on"
        printf '    install one of them and rerun:  weston  (Wayland greeter)  or  xorg-server\n'
        return 1
    fi

    # Своим файлом, а не правкой /etc/sddm.conf: заводской конфиг пакета
    # обновляется вместе с ним, и наши строки бы из него пропали.
    $SUDO mkdir -p /etc/sddm.conf.d
    printf '[General]\nDisplayServer=wayland\n\n[Wayland]\nCompositorCommand=weston --shell=kiosk --no-config\n' \
        | $SUDO tee /etc/sddm.conf.d/05-panacea-wayland.conf >/dev/null
    ok "login screen switched to the Wayland greeter (weston)"
    return 0
}

install_sddm() {
    [ -d "$SRC/sddm/panacea" ] || { warn "no SDDM theme here — skipping"; return; }

    # Bridge for lock screen / greeter theme assets
    $SUDO mkdir -p /var/lib/panacea 2>/dev/null || true
    if [ -d /var/lib/panacea ]; then
        $SUDO chmod 777 /var/lib/panacea 2>/dev/null || true
    fi

    if [ "$IS_NIXOS" = "1" ]; then
        mkdir -p "$HOME/.local/share/sddm/themes"
        rm -rf "$HOME/.local/share/sddm/themes/panacea"
        cp -r "$SRC/sddm/panacea" "$HOME/.local/share/sddm/themes/"
        $SUDO mkdir -p /etc/nixos/panacea/sddm 2>/dev/null || true
        $SUDO cp -r "$SRC/sddm/panacea" /etc/nixos/panacea/sddm/ 2>/dev/null || true
        if [ -d /etc/nixos ] && [ ! -f /etc/nixos/panacea.nix ] && [ -f "$SRC/panacea.nix" ]; then
            $SUDO cp "$SRC/panacea.nix" /etc/nixos/panacea.nix 2>/dev/null || true
            ok "panacea.nix copied to /etc/nixos/panacea.nix (import it in your configuration.nix)"
        fi
        ok "SDDM theme copied to ~/.local/share/sddm/themes/panacea and /etc/nixos/panacea/sddm/panacea"
        return 0
    fi

    command -v sddm >/dev/null 2>&1 || { warn "SDDM not installed — skipping login theme"; return; }
    detect_distro
    ensure_sddm_display_server || {
        warn "leaving the login screen alone until it can start at all"
        return
    }
    local themes=/usr/share/sddm/themes
    $SUDO rm -rf "$themes/panacea" && $SUDO cp -r "$SRC/sddm/panacea" "$themes/" || { warn "SDDM theme copy failed"; return; }
    $SUDO mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=panacea\n' | $SUDO tee /etc/sddm.conf.d/10-panacea.conf >/dev/null

    # The layout of the login screen is the same as that of the shell.

<<<<<<< HEAD
    if command -v localectl >/dev/null 2>&1 && [ -f "$SRC/hypr/lua/input.lua" ]; then
        local kbl kbo
        kbl="$(sed -n 's/.*kb_layout *= *"\([^"]*\)".*/\1/p' "$SRC/hypr/lua/input.lua" | head -1)"
        kbo="$(sed -n 's/.*kb_options *= *"\([^"]*\)".*/\1/p' "$SRC/hypr/lua/input.lua" | head -1)"
=======
    # Раскладки экрану входа — те же, что у оболочки.
    #
    # Hyprland задаёт свои раскладки только своему сеансу, а greeter берёт
    # системные X11. Там оставалась одна us: русской для пароля не было, и
    # Alt+Shift нечего было переключать — на экране входа мог висеть индикатор
    # раскладки, который никогда не менялся.
    #
    # The same saved settings drive the compositor and the login screen.
    if command -v localectl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 \
       && [ -f "$CONF/panacea/settings.json" ]; then
        local kbl kbv kbo
        kbl="$(jq -r '.keyboardLayouts // "us,ru"' "$CONF/panacea/settings.json")"
        kbv="$(jq -r '.keyboardVariants // ","' "$CONF/panacea/settings.json")"
        kbo="$(jq -r '.keyboardOptions // "grp:alt_shift_toggle"' "$CONF/panacea/settings.json")"
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
        if [ -n "$kbl" ]; then
            $SUDO localectl set-x11-keymap "$kbl" "" "$kbv" "$kbo" 2>/dev/null \
                && ok "login screen keyboard: $kbl${kbo:+ ($kbo)}" \
                || warn "could not set the login screen keyboard layout"
        fi
    fi

    ok "SDDM login theme installed and selected"
}



# ------------------------------------------------------------------------ grub
# The bootloader theme does not live in ~/.config, but in /boot - therefore, in a separate step and
# under sudo.

install_grub() {
    local src="$SRC/grub/panacea"
    [ -d "$src" ] || { warn "no grub theme in this checkout — skipping"; return; }

    if [ "$IS_NIXOS" = "1" ]; then
        $SUDO mkdir -p /etc/nixos/panacea/grub 2>/dev/null || true
        $SUDO cp -r "$src" /etc/nixos/panacea/grub/ 2>/dev/null || true
        if [ -d /boot/grub/themes ] && [ -w /boot/grub/themes ]; then
            cp -r "$src" /boot/grub/themes/ 2>/dev/null || true
        fi
        ok "GRUB theme copied to /etc/nixos/panacea/grub/panacea"
        return 0
    fi

    command -v grub-mkconfig >/dev/null 2>&1 || command -v grub2-mkconfig >/dev/null 2>&1 || {
        warn "grub-mkconfig not found — skipping the boot theme"; return; }

    local dst=/boot/grub/themes/panacea
    $SUDO mkdir -p /boot/grub/themes || { warn "cannot write to /boot/grub — skipping"; return; }
    $SUDO rm -rf "$dst" && $SUDO cp -r "$src" "$dst" \
        || { warn "boot theme copy failed"; return; }

    # We register the theme and menu mode in /etc/default/grub, if they are not there yet.

    local def=/etc/default/grub
    if [ -f "$def" ]; then
        $SUDO cp "$def" "$def.bak-$STAMP"
        set_grub_key "$def" GRUB_THEME "\"$dst/theme.txt\""
        set_grub_key "$def" GRUB_TIMEOUT_STYLE "menu"
        set_grub_key "$def" GRUB_GFXMODE "1920x1080,auto"
        set_grub_key "$def" GRUB_GFXPAYLOAD_LINUX "keep"

        if command -v os-prober >/dev/null 2>&1; then
            set_grub_key "$def" GRUB_DISABLE_OS_PROBER "false"
            ok "os-prober enabled — other systems will show up in the menu"
        else
            warn "os-prober not installed — other systems won't appear in the boot menu"
        fi
    fi

    local out=/boot/grub/grub.cfg
    if command -v grub-mkconfig >/dev/null 2>&1; then
        $SUDO grub-mkconfig -o "$out" >/dev/null 2>&1 && ok "boot theme installed → $dst"
    else
        $SUDO grub2-mkconfig -o "$out" >/dev/null 2>&1 && ok "boot theme installed → $dst"
    fi

    check_grub_prefix
}

# Everything higher could work in vain.
#
# The EFI image grubx64.efi has a prefix inside it - the directory where the bootloader comes from
# takes grub.cfg, modules and themes. If he points in a different direction than where we just went
# wrote that GRUB will read a completely different config, but we won’t notice it: and a copy
# themes and grub-mkconfig will work successfully, it’s just that no one will
# will open. On the outside it looks like "the theme is not applied and menu items are not
# change,” without a single mistake, and it takes a long time to find something like that.
#
# The classic case is an ESP mounted in /boot on top of a non-empty directory.
# Inside ESP, the theme is located on the /grub path, and the prefix remains from the previous one
# installations - (,gptN)/boot/grub, that is, in the directory hidden under the dot
# mounting. Hence the check: prefix with /boot/grub with ESP on /boot almost
# it probably means exactly that.

check_grub_prefix() {
    command -v strings >/dev/null 2>&1 || return 0
    mountpoint -q /boot 2>/dev/null || return 0

    local efi prefix
    for efi in /boot/EFI/*/grubx64.efi /boot/efi/EFI/*/grubx64.efi; do
        [ -f "$efi" ] || continue
        prefix="$($SUDO strings "$efi" 2>/dev/null | grep -m1 -E '^\([^)]*\)/')" || true
        [ -n "$prefix" ] || continue
        case "$prefix" in
            */boot/grub)
                warn "GRUB reads config from a different location than where we write"
                printf '        %s → prefix %s\n' "$efi" "$prefix"
                printf '        theme and menu will not apply until this is resolved:\n'
                printf '        $SUDO grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB\n'
                ;;
        esac
    done
}

# set_grub_key <file> <key> <value>

set_grub_key() {
    local f="$1" k="$2" v="$3"
    if $SUDO grep -qE "^[[:space:]]*$k=" "$f"; then
        $SUDO sed -i "s|^[[:space:]]*$k=.*|$k=$v|" "$f"
    else
        printf '%s=%s\n' "$k" "$v" | $SUDO tee -a "$f" >/dev/null
    fi
}

# ------------------------------------------------------------------ wallpapers
<<<<<<< HEAD
# The repository only carries a couple of wallpapers: the entire set is 400 MB, in dotfiles
# there is no place for this. Therefore, we suggest downloading it separately, in files, without
# history (git clone would take half a gigabyte).

=======
# Обои поставляются в репозитории в каталоге wallpapers/ (300+ обоев).
# Если каталог есть локально — копируем из него напрямую. Если нет (например,
# скрипт запущен отдельно) — загружаем как раньше через GitHub API.
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
WALLS_REPO="ilyamiro/shell-wallpapers"
install_wallpapers() {
    local dst="$CONF/hypr/wallpaper/shell"
    mkdir -p "$dst" || return

    if [ -d "$SRC/wallpapers" ]; then
        local n; n=$(find "$SRC/wallpapers" -type f 2>/dev/null | wc -l)
        if [ "$n" -gt 0 ]; then
            printf '  copying %s wallpapers from repository...\n' "$n"
            cp -n "$SRC/wallpapers"/* "$dst/" 2>/dev/null || cp -f "$SRC/wallpapers"/* "$dst/"
            ok "wallpapers → $dst ($n files installed)"
            return
        fi
    fi

    command -v curl >/dev/null 2>&1 || { warn "curl not found — skipping the wallpaper pack"; return; }
    command -v python3 >/dev/null 2>&1 || { warn "python3 not found — skipping the wallpaper pack"; return; }

    mkdir -p "$dst" || return
    local list; list=$(mktemp)
    curl -fsSL "https://api.github.com/repos/$WALLS_REPO/git/trees/master?recursive=1" \
        | python3 -c "
import json, sys, urllib.parse
try:
    tree = json.load(sys.stdin).get('tree', [])
except Exception:
    sys.exit(1)
for e in tree:
    p = e.get('path', '')
    if e.get('type') == 'blob' and p.startswith('images/') \
       and p.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
        print('https://raw.githubusercontent.com/$WALLS_REPO/master/' + urllib.parse.quote(p))
" > "$list" || { warn "could not read the wallpaper list"; rm -f "$list"; return; }

    local n; n=$(wc -l < "$list")
    [ "$n" -gt 0 ] || { warn "the wallpaper list came back empty"; rm -f "$list"; return; }
    printf '  downloading %s wallpapers (about 400 MB)\n' "$n"

    # We count progress from the outside: there are eight curls at once, and their own
    # the stripes would interrupt each other. Once a second we look at how many files there are
    # is already in the directory and how many megabytes it is, and we rewrite one line.
    #
    # Without this, 400 MB looked like a frozen installer: it was silent for minutes,
    # and it was impossible to understand whether the download was going on or stopped.
    # We rewrite the line via \r, so it cannot be poured into a file: in the log
    # installation would have turned out to be a mess of hundreds of lines. Not a terminal - we are silent.

    local mon=""
    if [ -t 1 ]; then
        local done_before; done_before=$(find "$dst" -type f 2>/dev/null | wc -l)
        (
            while :; do
                # We count not the appeared files, but the completed downloads: curl
                # creates a file in the first moment, so the file counter
                # instantly hit the maximum and then just stood there while she walked
                # real download. Live curl is what's left.

                have=$(find "$dst" -type f 2>/dev/null | wc -l)
                busy=$(pgrep -cx curl 2>/dev/null || echo 0)
                done_now=$(( have - done_before - busy ))
                [ "$done_now" -lt 0 ] && done_now=0
                mb=$(du -sm "$dst" 2>/dev/null | cut -f1)
                printf '\r  %s/%s done · %s MB · %s downloading   ' \
                       "$done_now" "$n" "${mb:-0}" "${busy:-0}"
                sleep 1
            done
        ) &
        mon=$!
        # The meter should not survive the installer if he is interrupted

        trap 'kill "$mon" 2>/dev/null' EXIT INT TERM
    fi

    # --speed-limit/--speed-time terminate the connection that is up: without them
    # one hanging download kept the installer all --max-time, and from the side
    # it looked like it was stuck on the last file.

    (cd "$dst" && xargs -P 8 -n 1 curl -sfLO --retry 2 --max-time 120 \
                        --speed-limit 2048 --speed-time 20 < "$list")

    if [ -n "$mon" ]; then
        kill "$mon" 2>/dev/null
        trap - EXIT INT TERM
        printf '\r%*s\r' 44 ''   # erase the progress bar behind you

    fi
    rm -f "$list"

    # We throw away broken and non-pictures: one of these would break the carousel

    local bad=0
    for f in "$dst"/*; do
        [ -f "$f" ] || continue
        case "$(file -b --mime-type "$f")" in
            image/*) ;;
            *) rm -f "$f"; bad=$((bad + 1)) ;;
        esac
    done
    # Names with percentages and spaces break file:// paths in Qt

    local before after
    for f in "$dst"/*; do
        [ -f "$f" ] || continue
        before=$(basename "$f")
        after=$(printf '%s' "$before" | tr ' ' '_' | tr -cd '[:alnum:]._-')
        [ -n "$after" ] && [ "$after" != "$before" ] && [ ! -e "$dst/$after" ] \
            && mv -f "$f" "$dst/$after"
    done
    ok "wallpapers → $dst$( [ "$bad" -gt 0 ] && printf ' (%s broken files dropped)' "$bad" )"
}

# ------------------------------------------------------------------------ run
# List per machine: one package name per line, unadorned and unadorned
# one question - update.sh uses this to tell what is missing
# after the update. The list of dependencies should live in one place, not
# two copies diverge, so the report is taken from here.
#
# EXTRA_PKGS do not go here: they do not have a binary that can be checked, and in
# MISSING they always hit - for the report it would be noise.
# The same for packages that are no longer needed: we name only those that
# really stand in the system.

if [ "$PRINT_OBSOLETE" = "1" ]; then
    command -v pacman >/dev/null 2>&1 || exit 0
    for row in "${OBSOLETE_PKGS[@]}"; do
        IFS='|' read -r pkg since <<<"$row"
        pacman -Qq "$pkg" >/dev/null 2>&1 && printf '%s\n' "$pkg"
    done
    exit 0
fi

if [ "$PRINT_MISSING" = "1" ]; then
    if [ "$IS_NIXOS" = "1" ]; then
        for row in "${DEPS[@]}"; do
            IFS='|' read -r bin arch_pkg nix_pkg why <<<"$row"
            command -v "$bin" >/dev/null 2>&1 || printf '%s\n' "$nix_pkg"
        done
        fc-list 2>/dev/null | grep -iE "JetBrainsMono.*Nerd|JetBrains Mono Nerd" >/dev/null || printf '%s\n' "$FONT_PKG_NIX"
    else
        for row in "${DEPS[@]}"; do
            IFS='|' read -r bin arch_pkg nix_pkg why <<<"$row"
            command -v "$bin" >/dev/null 2>&1 || printf '%s\n' "$arch_pkg"
        done
        for row in "${FILE_DEPS[@]}"; do
            IFS='|' read -r path pkg why <<<"$row"
            [ -e "$path" ] || printf '%s\n' "$pkg"
        done
        fc-list 2>/dev/null | grep -iE "JetBrainsMono.*Nerd|JetBrains Mono Nerd" >/dev/null || printf '%s\n' "$FONT_PKG_ARCH"
    fi
    exit 0
fi

printf '\n%sPanacea%s — dotfiles installer\n' "$B" "$N"
printf '%sfrom %s%s\n' "$DIM" "$SRC" "$N"
[ -d "$SRC/panacea" ] || die "run this from inside the cloned repo"

printf '\n%sThis overwrites ~/.config/hypr, the terminal configs and more.\nEverything replaced is backed up as *.bak-%s next to it.%s\n' "$WARN" "$STAMP" "$N"
ask "Continue?" || { echo "Nothing done."; exit 0; }

step "Checking dependencies"
check_deps
if [ "$DO_DEPS" = "1" ]; then
    step "AUR helper"
    check_aur_helper
    step "Installing packages"
    install_deps || warn "some packages are missing — the shell may be degraded until they are installed"
fi

if [ "$DO_DEPS" = "1" ]; then
    step "Graphics and CPU drivers"
    install_drivers
fi

step "Copying configs"
install_configs

if [ "$DO_SERVICES" = "1" ]; then
    step "Enabling services"
    enable_services
fi

if [ "$DO_WALLS" = "1" ]; then
    walls_msg="Install the wallpaper pack (300+ wallpapers)?"
    [ ! -d "$SRC/wallpapers" ] && walls_msg="Download the wallpaper pack (~400 MB, $WALLS_REPO)?"
    if ask "$walls_msg"; then
        step "Installing wallpapers"
        install_wallpapers
    fi
fi

if [ "$DO_GRUB" = "1" ] && [ -d /boot/grub ]; then
    if ask "Install the Panacea GRUB theme? (writes to /boot, needs root)"; then
        step "Installing the boot theme"; install_grub
    fi
fi

if [ "$DO_SDDM" = "1" ] && command -v sddm >/dev/null 2>&1; then
    if ask "Also install the Panacea SDDM login theme? (replaces your current login screen, needs root)"; then
        step "Installing the login theme"; install_sddm
    fi
fi

# Monitor brightness on a desktop machine. There is no internal matrix here, and
# the only way to the backlight is DDC/CI over the I2C bus: the core needs a module
# i2c-dev, and the user has access to /dev/i2c-*. Fresh ddcutil puts his
# udev-rule and gives access to the session owner itself, so in the i2c group
# we are added only as a fallback if the rule for some reason did not work.
#
# On a laptop, the step is skipped entirely: there the brightness goes through the backlight,
# and there is no need to touch the kernel modules.

setup_ddc() {
    ls /sys/class/backlight/* >/dev/null 2>&1 && { ok "internal backlight — DDC/CI not needed"; return; }
    command -v ddcutil >/dev/null 2>&1 || { warn "ddcutil missing — no brightness control for the monitor"; return; }

    if [ "$IS_NIXOS" = "1" ]; then
        $SUDO modprobe i2c-dev 2>/dev/null && ok "i2c-dev loaded" || true
        if getent group i2c >/dev/null 2>&1 && ! id -nG "$USER" | grep -qw i2c; then
            warn "Ensure your user is in the 'i2c' group on NixOS:"
            printf '        hardware.i2c.enable = true;\n        users.users.%s.extraGroups = [ "i2c" ];\n' "$USER"
        fi
        if ddcutil detect --brief 2>/dev/null | grep -q "I2C bus"; then
            ok "monitor answers over DDC/CI — the brightness slider is in Display"
        else
            warn "no monitor answered over DDC/CI — check that it is enabled in the monitor's own menu"
        fi
        return 0
    fi

    if ! lsmod 2>/dev/null | grep -q '^i2c_dev'; then
        $SUDO modprobe i2c-dev 2>/dev/null \
            && ok "i2c-dev loaded" \
            || warn "could not load i2c-dev — brightness over DDC/CI stays unavailable"
    fi
    # so that the module remains after a reboot

    if [ ! -f /etc/modules-load.d/i2c-dev.conf ]; then
        echo i2c-dev | $SUDO tee /etc/modules-load.d/i2c-dev.conf >/dev/null 2>&1 \
            && ok "i2c-dev enabled at boot"
    fi
    if getent group i2c >/dev/null 2>&1 && ! id -nG "$USER" | grep -qw i2c; then
        $SUDO usermod -aG i2c "$USER" 2>/dev/null \
            && warn "added you to the i2c group — takes effect at next login"
    fi

    # Is the monitor responding at all? The answer is important to a person right away: DDC/CI for many
    # monitors is turned off in the hardware menu, and without this line the slider just
    # wouldn't show up without an explanation.

    if ddcutil detect --brief 2>/dev/null | grep -q "I2C bus"; then
        ok "monitor answers over DDC/CI — the brightness slider is in Display"
    else
        warn "no monitor answered over DDC/CI — check that it is enabled in the monitor's own menu"
    fi
}

step "Monitor brightness"
setup_ddc

# Clock in 24 hours.

setup_time_format() {
    local loc="en_GB.UTF-8"
    if [ "$IS_NIXOS" = "1" ]; then
        ok "clocks in 24-hour format (configured in Hyprland session; in NixOS: i18n.extraLocaleSettings.LC_TIME = \"${loc}\";)"
        return 0
    fi

    if ! locale -a 2>/dev/null | grep -qiE "^en_GB\.?utf-?8$"; then
        if [ -f /etc/locale.gen ]; then
            $SUDO sed -i "s/^#\s*${loc} UTF-8/${loc} UTF-8/" /etc/locale.gen 2>/dev/null
            grep -q "^${loc} UTF-8" /etc/locale.gen 2>/dev/null \
                || echo "${loc} UTF-8" | $SUDO tee -a /etc/locale.gen >/dev/null 2>&1
            $SUDO locale-gen >/dev/null 2>&1
        fi
    fi

    if locale -a 2>/dev/null | grep -qiE "^en_GB\.?utf-?8$"; then
        if ! grep -q "^LC_TIME=" /etc/locale.conf 2>/dev/null; then
            echo "LC_TIME=${loc}" | $SUDO tee -a /etc/locale.conf >/dev/null 2>&1
        fi
        ok "clocks in 24-hour format (LC_TIME=${loc})"
    else
        warn "could not generate ${loc} — clocks stay in the 12-hour format"
    fi
}

# How the system opens files.

setup_mime() {
    command -v xdg-mime >/dev/null 2>&1 || {
        warn "xdg-mime not found — default applications left as they are"; return; }
    [ -d "$SRC/applications" ] || return

    local dst="$HOME/.local/share/applications"
    mkdir -p "$dst"
    local f name
    for f in "$SRC/applications"/*.desktop; do
        [ -f "$f" ] || continue
        name="$(basename "$f")"
        sed "s|@HOME@|$HOME|g" "$f" > "$dst/$name"
    done
    command -v update-desktop-database >/dev/null 2>&1 &&
        update-desktop-database "$dst" >/dev/null 2>&1

    # The browser is the one that is opened by the browser anyway.

    local browser="firefox.desktop"
    [ -f "/usr/share/applications/$browser" ] || browser=""
    if [ -n "$browser" ]; then
        for m in text/html application/xhtml+xml application/pdf \
                 x-scheme-handler/http x-scheme-handler/https; do
            xdg-mime default "$browser" "$m" 2>/dev/null
        done
    fi

    # Pictures and videos - to the viewer of the shell itself: it can crop and
    # cropping, but the browser can only show it.

    for m in image/png image/jpeg image/gif image/webp image/bmp image/tiff \
             image/svg+xml; do
        xdg-mime default panacea-media.desktop "$m" 2>/dev/null
    done

    # Video and sound - mpv, if available: this is his main job.

    if [ -f /usr/share/applications/mpv.desktop ]; then
        for m in video/mp4 video/webm video/x-matroska video/quicktime \
                 audio/mpeg audio/flac audio/ogg audio/x-wav; do
            xdg-mime default mpv.desktop "$m" 2>/dev/null
        done
    else
        for m in video/mp4 video/webm video/x-matroska; do
            xdg-mime default panacea-media.desktop "$m" 2>/dev/null
        done
    fi

    for m in text/plain text/markdown application/x-shellscript text/x-python \
             text/x-lua application/json text/csv; do
        xdg-mime default panacea-text.desktop "$m" 2>/dev/null
    done
    xdg-mime default panacea-files.desktop inode/directory 2>/dev/null

    ok "default applications set"
}

step "Default applications"
setup_mime

step "Clock format"
setup_time_format

# Cursor.

setup_cursor() {
    local theme="Bibata-Modern-Classic" size=24

    if [ ! -d "/usr/share/icons/$theme" ] && [ ! -d "$HOME/.icons/$theme" ] && [ ! -d "$HOME/.local/share/icons/$theme" ] && [ ! -d "/run/current-system/sw/share/icons/$theme" ]; then
        warn "cursor theme $theme is missing — the default cursor stays"
        return
    fi

    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface cursor-theme "$theme" 2>/dev/null
        gsettings set org.gnome.desktop.interface cursor-size "$size" 2>/dev/null
    fi

    mkdir -p "$HOME/.icons/default"
    printf '[Icon Theme]\nName=Default\nComment=Default cursor theme\nInherits=%s\n' \
        "$theme" > "$HOME/.icons/default/index.theme"

    # GTK3 and GTK4 also read their ini

    local g
    for g in "$CONF/gtk-3.0/settings.ini" "$CONF/gtk-4.0/settings.ini"; do
        mkdir -p "$(dirname "$g")"
        if [ -f "$g" ] && grep -q '^gtk-cursor-theme-name=' "$g"; then
            sed -i "s|^gtk-cursor-theme-name=.*|gtk-cursor-theme-name=$theme|" "$g"
        else
            grep -q '^\[Settings\]' "$g" 2>/dev/null || echo '[Settings]' >> "$g"
            echo "gtk-cursor-theme-name=$theme" >> "$g"
        fi
    done

    hyprctl setcursor "$theme" "$size" >/dev/null 2>&1
    ok "cursor → $theme"
}

step "Cursor"
setup_cursor

step "Login shell"
if [ "$(basename "$(getent passwd "$USER" | cut -d: -f7)")" = "fish" ]; then
    ok "fish is already your login shell"
elif [ "$IS_NIXOS" = "1" ]; then
    warn "fish is not your default login shell in NixOS"
    printf '        To enable fish as login shell, add to /etc/nixos/configuration.nix:\n'
    printf '        programs.fish.enable = true;\n'
    printf '        users.users.%s.shell = pkgs.fish;\n' "$USER"
elif ! command -v fish >/dev/null 2>&1; then
    warn "fish is missing — the shell config and aliases stay unused"
elif ask "Make fish your login shell? (that is where the aliases and the prompt live)"; then
    $SUDO chsh -s "$(command -v fish)" "$USER" 2>/dev/null \
        && ok "login shell → fish (takes effect at next login)" \
        || warn "could not change the login shell — run: chsh -s $(command -v fish)"
else
    warn "login shell left as is — aliases work only where fish is started by hand"
fi

# There is only one palette and it is located in hypr/palette.conf: palette.sh distributes it throughout
# terminals, waybar, btop, editors and login screen. She doesn't need a linker,
# therefore, the step is separate: when installing from TTY, the colors will still appear, but
# Previously, they waited for the first launch with their hands.

step "Applying the palette"
if [ -x "$CONF/hypr/scripts/palette.sh" ]; then
    "$CONF/hypr/scripts/palette.sh" >/dev/null 2>&1 && ok "colours → terminals, waybar, btop, editors"
else
    warn "palette.sh missing — colours stay at their defaults"
fi
# Wallpaper miniatures are in the background: the carousel shows them instantly, without warming up
# the first discovery would be reading 4K sources.

[ -x "$CONF/panacea/scripts/thumbs.sh" ] \
    && (setsid "$CONF/panacea/scripts/thumbs.sh" all >/dev/null 2>&1 &) \
    && ok "wallpaper thumbnails warming up in the background"

# Is there an update in progress? Then the restart is not ours.
#
# The installer kills qs - and update.sh was launched FROM the shell and died along with
# it right here, without having time to return the settings, write down a list of changes and
# mark version. The latest update.sh now sends us --no-restart, but
# people have old copies in their hands who don’t know about it. We decide for them:
# There is an update in progress - we don’t touch the shell, Quickshell itself re-reads the files.

if pgrep -f "update\.sh apply" >/dev/null 2>&1; then
    DO_RESTART=0
fi

step "Starting the shell"
if [ "$DO_RESTART" != "1" ]; then
    ok "restart skipped"
elif command -v hyprctl >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null 2>&1
    # The wallpaper lives separately from the palette: we put the last selected ones (on a clean
    # installation - those that are in the wallpaper.conf repository).

    [ -x "$CONF/hypr/scripts/switch_theme.sh" ] \
        && "$CONF/hypr/scripts/switch_theme.sh" --restore >/dev/null 2>&1
    pkill -x qs >/dev/null 2>&1; sleep 1
    # Same variable as in autorun (hypr/lua/programs.lua): without it
    # Qt on the NVIDIA driver takes the “basic render loop” and spins animations from
    # 16 ms timer - 60 frames on any monitor. Here it is needed separately:
    # the shell after installation is launched by this script, and not by autorun, and before
    # the next entrance, the island would move in jerks.

    (setsid env QSG_RENDER_LOOP=threaded qs -c "$CONF/panacea" >/dev/null 2>&1 &)
    ok "reloaded Hyprland and started the pill"
else
    warn "Hyprland isn't running here — everything comes up at next login"
fi

printf '\n%s✓ Done.%s\n' "$OK" "$N"
printf '%sSUPER+A launcher · SUPER+Z quick settings · SUPER+Tab workspaces · SUPER+E files%s\n' "$DIM" "$N"
printf '%sSUPER+I settings · SUPER+/ shortcuts · or hover the pill.%s\n' "$DIM" "$N"
# Aliases live in fish and appear in a new session, and not in the window from
# which the installation was going on: the shell is already running, its config is not
# rereads. After rebooting below this ceases to be an issue.

printf '%sls · ll · lt · c (clear) · upd (pacman -Syu) · ins (pacman -S) · ff — in a new terminal.%s\n' "$DIM" "$N"

# ------------------------------------------------------------------- reboot
# Half of what is installed is picked up only upon a new login: the session sees
# new groups and services, the portal re-reads the environment, Hyprland - its
# config from scratch. Returning to a half-old session and wondering why
# something is wrong - a worse first experience than one reboot.
#
# When updating it does not reach here: update.sh calls the installer with --no-restart.

if [ "$DO_RESTART" = "1" ]; then
    if [ "$ASSUME_YES" = "1" ]; then
        printf '\n%sRebooting in 10 seconds — Ctrl+C to stay.%s\n' "$B" "$N"
        sleep 10 && systemctl reboot
    elif ask $'\nReboot now? Everything comes up clean after it'; then
        systemctl reboot
    else
        printf '%sLog out and back in when convenient.%s\n' "$DIM" "$N"
    fi
fi
