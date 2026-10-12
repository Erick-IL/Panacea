<div align="center">

<img src="assets/logo-256.png" alt="Panacea Shell" width="160">

# Panacea Shell (Nix / NixOS Fork)

**Uma cápsula dinâmica para tudo.** Um ambiente desktop completo sobre o Hyprland onde toda a interface do sistema vive em uma ilha dinâmica (Dynamic Island) fluida e adaptativa.

<<<<<<< HEAD
<a href="https://nixos.org"><img alt="NixOS" src="https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white"></a>
=======
<a href="https://archlinux.org"><img alt="Arch Linux" src="https://img.shields.io/badge/Arch%20Linux-1793D1?style=for-the-badge&logo=archlinux&logoColor=white"></a>
<a href="https://ubuntu.com"><img alt="Ubuntu" src="https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white"></a>
<a href="https://debian.org"><img alt="Debian" src="https://img.shields.io/badge/Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white"></a>
<a href="https://fedoraproject.org"><img alt="Fedora" src="https://img.shields.io/badge/Fedora-51A2DA?style=for-the-badge&logo=fedora&logoColor=white"></a>
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255
<a href="https://hyprland.org"><img alt="Hyprland" src="https://img.shields.io/badge/Hyprland-00AAAE?style=for-the-badge&logo=hyprland&logoColor=white"></a>
<a href="https://github.com/YaLTeR/niri"><img alt="Niri" src="https://img.shields.io/badge/Niri-Beta-8B5CF6?style=for-the-badge"></a>
<a href="https://quickshell.org"><img alt="Quickshell" src="https://img.shields.io/badge/Quickshell-7F7F7F?style=for-the-badge&logo=qt&logoColor=white"></a>
<a href="https://fishshell.com"><img alt="Fish" src="https://img.shields.io/badge/Fish-111111?style=for-the-badge&logo=gnubash&logoColor=white"></a>
<a href="https://archlinux.org"><img alt="Arch Linux" src="https://img.shields.io/badge/Arch%20Linux-1793D1?style=for-the-badge&logo=archlinux&logoColor=white"></a>
<a href="#licença"><img alt="MIT" src="https://img.shields.io/badge/Licen%C3%A7a-MIT-3b82f6?style=for-the-badge"></a>

> [!IMPORTANT]
> **Sobre este Fork**: Este repositório é um **fork adaptado para Nix e NixOS** do projeto original **[Panacea](https://github.com/EnsixD/Panacea)** criado por **[EnsixD](https://github.com/EnsixD)**.  
> Todo o mérito pelo design original, conceito da cápsula dinâmica e arquitetura visual pertence ao autor original [EnsixD](https://github.com/EnsixD).  
> Este fork introduz suporte de primeira classe ao ecossistema Nix (Flakes, módulos declarativos para NixOS e Home Manager), instalador adaptado para NixOS, refinamentos de interface, gerenciador Docker integrado e correções para GPUs híbridas (Intel + NVIDIA PRIME).

</div>

---

Sem barras espalhadas, sem bandejas poluídas e sem popups desconexos. Wi‑Fi, Bluetooth, perfis de energia, launcher de aplicativos, central de notificações, tocador de mídia com equalizador, gerenciador de arquivos, cofre de senhas (com TOTP), menu de energia, monitor de containers Docker e configurações do sistema vivem todos dentro de uma **única cápsula dinâmica** que se expande de forma orgânica e recolhe quando você termina.

A ilha pode se fixar em qualquer borda da tela — superior, inferior, esquerda ou direita — sempre expandindo em direção ao centro do monitor.

---

# # 🚀 Novidades e Otimizações deste Fork para Nix / NixOS


- ❄️ **Suporte Nativo a Nix & Flakes**:
  - `flake.nix` configurado com pacotes (`panacea`, `panacea-sddm-theme`, `panacea-grub-theme`).
  - Módulo NixOS (`nixosModules.default` / `panacea.nix`) para habilitar tema SDDM e serviços declarativamente.
  - Módulo Home Manager (`homeManagerModules.default`) para gerenciamento das dotfiles.
- 🛠️ **Instalador `install.sh` Inteligente**:
  - Detecção automática de NixOS vs Arch Linux.
  - Verificação de dependências do sistema com sugestão formatada para o `configuration.nix`.
  - Configuração automática do tema SDDM e diretório compartilhado `/var/lib/panacea`.
  - Preservação estrita das configurações do usuário (`settings.json`, monitores e wallpapers).
- 🎮 **Testado em Hardware Híbrido Real (Intel + NVIDIA RTX com PRIME Sync)**:
  - Ajustes de renderização com aceleração por hardware estável para SDDM e Hyprland (`QSG_RENDER_LOOP=threaded`).
- 👤 **Interface e Dashboards Aprimorados**:
  - **Aba System (`SetSystem.qml`)**: Exibe o usuário ativo do sistema alinhado à esquerda no topo, com status em tempo real de hardware, memória, swap, temperaturas de CPU/GPU e processos.
  - **Aba GitHub Profile (`ProfileView.qml`)**: Dashboard com avatar, repositórios, estrelas, forks, heatmap de contribuições anual e troca dinâmica de login (sem notificações de updates fictícias).
  - **Dashboard Docker (`DockerView.qml`)**: Criação, inicialização, parada e logs de containers Docker diretamente da interface da ilha.

---

# # 📸 Demonstração em Video


A demonstração do ecossistema Panacea gravada pelo gravador integrado da ilha está disponível no repositório como `demo.mp4`.

---

## ⌨️ Atalhos Principais (Keybindings)

| Atalho | Ação | Descrição |
|---|---|---|
<<<<<<< HEAD
| `Super + A` | **Launcher** | Busca rápida de aplicativos, calculadora e ações rápidas |
| `Super + Z` | **Quick Settings** | Controles de Wi‑Fi, Bluetooth, volume, player de mídia, bateria |
| `Super + I` | **Configurações** | Painel completo de preferências (ilha, monitores, atalhos, sistema) |
| `Super + E` | **Arquivos** | Navegador de arquivos integrado (Yazi no terminal ou GUI) |
| `Super + V` | **Área de Transferência** | Histórico visual do `cliphist` com busca |
| `Super + D` | **Docker** | Painel de controle de containers e imagens Docker |
| `Super + P` | **Gravador de Tela** | Gravação de tela com áudio (`wf-recorder`) |
| `Super + Shift + P` | **Cofre de Senhas** | Vault seguro criptografado com suporte a TOTP |
| `Super + Shift + W` | **Wi-Fi** | Busca e conexão rápida de redes sem fio (`iwd`) |
| `Super + Shift + B` | **Bluetooth** | Pareamento e gerenciamento de dispositivos Bluetooth |
| `Super + Shift + N` | **Notificações** | Histórico e controle de Não Perturbe |
| `Super + Tab` | **Workspaces** | Visão geral dos espaços de trabalho ativos |
| `Super + /` | **Atalhos** | Tabela interativa com todos os atalhos configurados |
| `Ctrl + Alt + Del` | **Menu de Energia** | Bloquear, suspender, reiniciar ou desligar |
=======
| Quick settings | `Super + Z` | Wi‑Fi, Bluetooth, sound, now playing with transport and seeking straight on the equaliser, recorder, battery, passwords, tray |
| Networks / Bluetooth | `Super + Shift + W` / `+ B` | Scan, connect, pair |
| Notifications | `Super + Shift + N` | Live cards that open what they are about, one history list, do‑not‑disturb |
| Wallpapers | `Super + Shift + T` | Full‑screen carousel with parallax previews, stills and live video |
| Workspaces | `Super + Tab` | Live previews of every workspace, switch from the grid |
| Launcher | `Super + A` | App search + calculator, recents first; also the agent panel and the other systems on the disk |
| Clipboard | `Super + V` | Smart clipboard: automatic detection of HEX colors (swatch preview & RGB/HSL copy), URLs (open in browser), files/images (thumbnails), and pinned snippets |
| Files | `Super + E` | Bookmarks, disks, sorting, trash, context menu, drag between windows |
| Media | opens a file | Images, GIFs, video — trim and crop |
| Recorder | `Super + P` | FPS, folder, system audio, microphone |
| Passwords | `Super + Shift + P` | Encrypted vault, browser import, save prompts |
| Battery | from quick settings | Power profiles, charge state, capacity and wear |
| Lock screen | `Super + L` | Lock current session (or `Mod + Alt + L` on Niri) |
| Power | `Ctrl + Alt + Del` | Sleep, lock, log out, restart, shut down |
| Settings | `Super + I` | Pill, system, displays, keys — with live mock‑ups |
| Shortcuts | `Super + /` | Every binding in one place, rebindable |
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255

*(Você também pode simplesmente passar o cursor sobre a ilha para expandi-la).*

<<<<<<< HEAD
---
=======
### Nothing OS Desktop Widgets

Minimalist desktop cards that live directly on your wallpaper (`Super + I` → *Appearance* → *Desktop widgets*):
- **Nothing Analog Clock**: Signature 12-dot dial with cardinal points, double dot at 12 o'clock, clean white hands, and an orbiting red accent second hand (`colCrit`). Click to toggle between Analog and Digital Dot Clock.
- **Concentric System Monitor**: Dual concentric minimalist arcs (outer ring for RAM %, inner ring for root SSD %) with dot-matrix percentage in the center. Click the card or icon to toggle between Weather details and the System monitor.
- **Life Bar / Day & Year Progress**: A 24-segment dot bar representing the hours of the day (elapsed hours in solid white, current hour pulsing red, future hours dimmed) and time remaining. Click to switch between 24-hour Day Progress and 365-day Year Progress.

**Settings** has twelve sections, searchable from the top of the panel: *Bar &
Island* (a mock‑up of your desktop with the real island on it, its screen edge
and geometry), *Media*, *Clock & Date*, *Appearance* (palette, fonts, interface
language), *Motion*, *Launcher*, *Notifications*, *Control Center* (the quick
settings tiles, rearranged by dragging), *Lock Screen*, *Display* (resolution,
refresh rate, scale, orientation, VRR, multi‑monitor arrangement, brightness and
digital vibrance), *Mouse* and *System*.
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255

# # 📦 Como Instalar no NixOS

Existem duas formas de instalar este fork no NixOS:

# ## Method 1: Instalação Automática via `./install.sh` (Recomendado para quem já tem o sistema instalado)

<<<<<<< HEAD
=======
**Other systems are made to show up.** Arch disables `os-prober` by default,
which is why a fresh GRUB config often lists only Linux and quietly loses the
Windows that is still sitting on the disk. The installer sets
`GRUB_DISABLE_OS_PROBER=false` when `os-prober` is installed, and says so if it
is missing.

**You can restart into another system from the launcher.** Open it, type
`windows` — or whatever the system is called — and press Enter. There is no
fixed list of two: `panacea/scripts/bootos.sh` finds what is actually there, so
three systems give three entries and one system gives none at all. Names are
tidied for reading, so `Windows Boot Manager (on /dev/nvme0n1p1)` becomes
`Windows`, while distributions keep their versions.

The choice is **one‑shot**: it sets the next boot only, through `grub-reboot`
(or `BootNext` in EFI variables when GRUB is not the bootloader). Your default
system does not change, and the boot after that comes back here. Touching the
bootloader needs root, so `pkexec` asks for a password — that prompt is also the
confirmation, which is why there is no separate "are you sure". These entries
never appear in an empty launcher and are never remembered as recent: a line
that reboots the machine should not sit one careless Enter away from the browser.

> [!NOTE]
> A theme that copies successfully and a config that regenerates without error
> can still both be ignored. The `grubx64.efi` image carries a **prefix** inside
> it — the directory it reads the config, modules and themes from — and if that
> points somewhere else, everything above lands in a folder the bootloader never
> opens. Nothing reports an error; the menu simply never changes. The classic
> case is an ESP mounted at `/boot` over a non‑empty directory, leaving the
> prefix pointing at the old `/boot/grub` now hidden under the mount point. The
> installer checks for exactly this after regenerating and prints the fix:
> `sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB`.

## Colours and wallpapers

There is **one palette** for the whole system, in `hypr/palette.conf`.
`hypr/scripts/palette.sh` spreads it across the terminal, btop, fish,
neovim and the login screen. Changing the wallpaper never touches the colours —
and never touches a file that Hyprland sources, so your windows are left alone.

## What's inside

| | |
|---|---|
| **Compositor** | [Hyprland](https://hyprland.org) (primary, Lua config) · [Niri](https://github.com/YaLTeR/niri) (scrollable-tiling, beta) |
| **Shell** | [Quickshell](https://quickshell.org) — the pill, in QML |
| **CLI** | Fish + eza + zoxide |
| **Terminal** | [foot](https://codeberg.org/dnkl/foot), as a server — `foot --server` starts with the session and `footclient` opens windows instantly |
| **Lock / wallpaper** | the pill's own lock screen, hyprpaper, hyprsunset |
| **Boot / login** | GRUB theme, SDDM theme — both matching the palette |

The pill is also the notification daemon and the polkit agent, so don't run
`mako`, `dunst` or `hyprpolkitagent` alongside it. Only one process can own
`org.freedesktop.Notifications`, and the rival never has to be launched to win —
D‑Bus starts it on the first notification, and from then on it draws them in its
own window instead of the island. The installer masks `dunst` and `mako` for that
reason; `systemctl --user unmask dunst.service` puts one back.

## Install these dotfiles

> [!TIP]
> **Cross-Distribution Support (Ubuntu, Debian, Linux Mint, Fedora, openSUSE, Arch)**
> The installer automatically detects your distribution and package manager (`pacman`, `apt`, `dnf`, `zypper`).
> Running on Ubuntu, Debian or Linux Mint? See [**docs/other-distros.md**](docs/other-distros.md) for build instructions, dependencies, and compatibility notes.

> [!NOTE]
> **Experimental Niri Support**
> Panacea features dual-compositor support: while **Hyprland** is the default, fully supported compositor, preliminary integration for the **[Niri](https://github.com/YaLTeR/niri)** scrollable-tiling compositor is now available in `niri/`. The shell automatically detects Niri at launch via `$NIRI_SOCKET` and switches its IPC hooks accordingly.
> *Notice:* Niri support is experimental and actively being refined. Certain features (such as layer blur, screen shaders, and specific gesture transitions) are Hyprland-specific, and you may encounter minor edge cases or glitches under Niri. If you use Niri, your personal overrides belong in `~/.config/niri/custom/custom.kdl` so they are preserved across updates.

> [!WARNING]
> **The installer is young.** It has been run on a handful of machines, mostly
> the author's. It backs up everything it replaces as `*.bak-<timestamp>`, but
> mistakes are still possible — back up your own `~/.config` first, and read the
> flags below before running it on a setup you care about.
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255

1. Clone o repositório na sua pasta pessoal:
```bash
git clone https://github.com/EnsixD/Panacea.git ~/Panacea
cd ~/Panacea
```

2. Execute o instalador:
```bash
./install.sh
```

<<<<<<< HEAD
O script cuidará de:
- Detectar o NixOS e verificar os pacotes necessários.
- Instalar as configurações em `~/.config/{panacea,hypr,foot,fish,fastfetch,nano}`.
- Copiar o tema SDDM para `/etc/nixos/panacea/sddm/panacea` e registrar em `/var/lib/panacea`.
- Configurar o cursor Bibata, tema de ícones Papirus e atalhos de desktop.
- Recarregar o Hyprland e iniciar o Quickshell.
=======
The script checks the dependencies, then checks for an AUR helper — `yay`, `paru`
or `pikaur`. If you have one it says which and moves on; if you have none it
offers to build `yay-bin` there and then, since `quickshell` itself lives in the
AUR. Declining is fine: everything from the repos still installs. It then backs
up anything it would overwrite, copies the configs, enables Bluetooth /
power‑profiles / iwd, spreads the palette across the applications, restores the
wallpaper and warms up its thumbnails. It then offers, one prompt at a time: the
wallpaper pack (300+ wallpapers bundled in `wallpapers/`), the GRUB boot theme and
the SDDM login theme.
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255

---

# ## Método 2: Instalação Declarativa no `/etc/nixos/configuration.nix`


Para uma experiência 100% reproduzível no NixOS, utilize a configuração do módulo:

# ### 1. Módulo do Panacea (`/etc/nixos/panacea.nix`)


Crie o arquivo `/etc/nixos/panacea.nix` (ou copie de `~/Panacea/panacea.nix`):

```nix
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
  services.displayManager = {
    defaultSession = "hyprland";
    sddm = {
      enable = true;
      wayland.enable = false; # Modo X11 no greeter garante estabilidade com drivers NVIDIA
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

  # Diretório de estado compartilhado para o SDDM sincronizar papéis de parede

  systemd.tmpfiles.rules = [
    "d /var/lib/panacea 0777 root root -"
  ];

  # Desbloqueio do GNOME Keyring no login
  security.pam.services.sddm.enableGnomeKeyring = lib.mkDefault true;
}
```

#### 2. Importe no seu `/etc/nixos/configuration.nix`

Adicione os pacotes e configurações essenciais:

```nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./panacea.nix
  ];

  # Hyprland & Portais Wayland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Network with iwd (used natively by the island)
  networking = {
    networkmanager.enable = false;
    wireless.enable = false;
    wireless.iwd.enable = true;
  };

  # Audio Pipewire

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Serviços de Energia e Hardware

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  hardware.bluetooth.enable = true;
  hardware.i2c.enable = true; # Para controle de brilho via DDC/CI
  programs.fish.enable = true;
  virtualisation.docker.enable = true;

  # PAM para o cofre de senhas e bloqueio de tela
  security.pam.services.swaylock = {};

  # Pacotes do Panacea
  environment.systemPackages = with pkgs; [
    hyprland
    quickshell
    hyprpaper
    hyprsunset
    foot
    fish
    eza
    zoxide
    bat
    fastfetch
    yazi
    swaylock
    jq
    wl-clipboard
    cliphist
    grim
    slurp
    ffmpeg
    wf-recorder
    wtype
    brightnessctl
    ddcutil
    playerctl
    wireplumber
    python3
    openssl
    xdg-utils
    glib
    upower
    cava
    mpvpaper
    bibata-cursors
    papirus-icon-theme
    udisks2
    udiskie
    gvfs
    qt6.qtmultimedia
    qt6.qtdeclarative
    qt6.qtsvg
    python3Packages.secretstorage
    python3Packages.cryptography
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
  ];

  environment.sessionVariables = {
    QML2_IMPORT_PATH = "/run/current-system/sw/lib/qt-6/qml";
  };
}
```

Aplique as mudanças:
```bash
sudo nixos-rebuild switch
```

---

# # 🎨 Personalização de Temas e Cores


<<<<<<< HEAD
O Panacea trabalha com uma **paleta única unificada** em `hypr/palette.conf`.
O script `hypr/scripts/palette.sh` distribui essa paleta automaticamente para:
- O terminal (`foot`)
- O monitor do sistema (`btop`)
- A linha de comando (`fish`)
- O editor de texto (`nano` / `neovim`)
- A tela de login SDDM

Você pode alternar entre temas pré-configurados ou escolher qualquer papel de parede pelo carrossel (`Super + Shift + T` ou pelo painel de configurações em `Super + I`).

---
=======
Networking supports both **NetworkManager** (`nmcli`, standard on Fedora / Ubuntu) and **iwd** (`iwctl`, common on minimal Arch). Panacea detects the active daemon automatically — no manual configuration required. Power profiles go through `power-profiles-daemon` over D‑Bus.
Everything resolves `$HOME` at runtime — no hardcoded paths.

### Language

Choose a system locale in **Settings → Appearance**. Panacea's interface has
built-in Russian, English and Turkish translations. For any other system
locale, the Panacea interface uses English while applications use the selected
locale after the next login. There is no online translation service or API key.
If you would like another interface language, please open a GitHub issue with
the language and locale code so it can be added to the built-in translations.

### Customising and keeping changes across updates

Panacea is designed so your personal tweaks — shell aliases, terminal fonts, window rules, keybindings — survive all updates without conflicts or overwrites:

| Component | Where your custom settings live | Kept on update? |
|---|---|:---:|
| **Hyprland** | `~/.config/hypr/custom/` (`custom.conf`, `keybinds.conf`, `rules.conf` or `custom.lua`) | ✅ Yes |
| **Terminal (foot)** | `~/.config/foot/custom.ini` (or edits in `foot.ini`) | ✅ Yes |
| **Shell (fish)** | `~/.config/fish/custom.fish`, `custom/*.fish`, and `fish_variables` | ✅ Yes |
| **Niri** | `~/.config/niri/custom/custom.kdl` (and `config.kdl`) | ✅ Yes |
| **Fastfetch** | `~/.config/fastfetch/config.jsonc` or `custom.jsonc` | ✅ Yes |
| **Nano** | `~/.nanorc` (existing file is never overwritten) | ✅ Yes |
| **Panacea** | `~/.config/panacea/settings.json` (merged with defaults via `jq`) | ✅ Yes |
| **Clipboard pins and Wi-Fi history** | `clipboard_pins.json` and `last_wifi_ssid` in `~/.config/panacea/` | ✅ Yes |
| **Post-update hook** | `~/.config/panacea/custom/post-update.sh` (executed after update) | ✅ Yes |

As an extra safety net, the updater backs up modified configurations to `~/.config/<name>.bak-update` before applying changes and retains two earlier update snapshots.
Files owned by the shell, such as `panacea/shell.qml` and
`hypr/lua/keybindings.lua`, are replaced to deliver code updates. Put durable
overrides in `settings.json` or the `custom/` directories above; a direct edit
to an owned file remains in the `.bak-update` copy for manual recovery.


### Voice to text

Hold **Right Alt**, speak, let go — the recognised text lands in the focused
field. It runs offline through [voxtype](https://voxtype.io);
the installer sets it up, but the speech model is a separate ~1.5 GB download.
If dictation does nothing, the model is what's missing — the one used here is
Whisper **medium**:

```bash
mkdir -p ~/.local/share/voxtype/models
curl -L --progress-bar \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin \
  -o ~/.local/share/voxtype/models/ggml-medium.bin
curl -sL \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-silero-vad.bin \
  -o ~/.local/share/voxtype/models/ggml-silero-vad.bin
systemctl --user restart voxtype
```

The second file is the Silero VAD model — it drops silence and background
noise, and transcription stalls without it because the config enables VAD.
A smaller model is fine too (`ggml-small.bin`, `ggml-base.bin`); set the name
in `model = ` under `[whisper]` in `~/.config/voxtype/config.toml`.

## Layout

```
panacea/   the pill: QML, scripts, settings.json
hypr/      Hyprland (Lua config, palette, wallpapers, scripts)
wallpapers/ bundled collection of 300+ wallpapers
niri/      Niri (config.kdl, custom overrides, scripts)
grub/      boot theme + the script that generates its assets
sddm/      login theme
bin/       standalone helper scripts
fish/      shell config and prompt
foot/      terminal
applications/  desktop entries that make the shell the default handler
fastfetch/ nano/
```
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255

# # 👥 Créditos & Agradecimentos

<<<<<<< HEAD
=======
Shortcuts live in `panacea/settings.json` and compile into
`hypr/lua/binds_data.lua` from the settings panel; that generated file is
gitignored, and without it the defaults in `keybindings.lua` apply. Every
ordinary Hyprland shortcut, including workspace switching and window movement
for desks 1–10, can be changed in **Super+/**. Mouse, media, and lid bindings
accept a typed Hyprland combination in the same editor. Keyboard layouts and
switching options live in **Settings → Devices → Input** and are generated from
`settings.json`; on Niri, edit the preserved `~/.config/niri/config.kdl`.
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255

- **[EnsixD](https://github.com/EnsixD)** — Criador original do projeto [Panacea](https://github.com/EnsixD/Panacea), autor de todo o conceito visual, animações da cápsula e design do desktop.
- **[Matteo Gini](https://github.com/matteogini/dotfiles)** — Base dos dotfiles originais.
- **[HyDE Project](https://github.com/HyDE-Project/HyDE)** — Inspiração para paletas e temas.
- **[Quickshell](https://quickshell.org)** — Framework incrível em C++/Qt/QML que possibilita toda a renderização da ilha.
- **[Hyprland](https://hyprland.org)** — Compositor Wayland dinâmico e de alta performance.

---

<<<<<<< HEAD
# # 📄 License
=======
- [matteogini/dotfiles](https://github.com/matteogini/dotfiles) — `ember_stripes.jpg`
  and `misty_peaks.jpg`; the rice this setup grew out of.
- [HyDE](https://github.com/HyDE-Project/HyDE) — `spring_bloom.jpg`, from its
  Graphite Mono theme; `hypr/palette.conf` is derived from it.
- [ilyamiro/shell-wallpapers](https://github.com/ilyamiro/shell-wallpapers) — the
  wallpaper collection bundled in `wallpapers/`.
>>>>>>> dcf9bbff6d02ce4446b0fb7a7b26ddbe1ba50255


Distribuído sob a licença MIT. Consulte o arquivo [LICENSE](LICENSE) para obter mais informações.
