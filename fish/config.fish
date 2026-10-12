if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -gx BROWSER firefox


# opencode and local bin
fish_add_path $HOME/.opencode/bin
fish_add_path $HOME/.local/bin

set -g fish_greeting ""

# eza instead of ls: colors, icons, wood. The flags are matched to the island -
# no frames, grouping folders at the top.
#
# Hidden files are intentionally not shown by default: in the home directory
# there were four times more of them than usual, and the naked ls turned into a sheet of
# service points. They haven’t gone anywhere - they are shown ll, la and any challenge
# with -a or -la because the alias appends flags to the end of the command.
if type -q eza
    alias ls   'eza --icons --group-directories-first'
    alias ll   'eza --icons --group-directories-first -la --git'
    alias la   'eza --icons --group-directories-first -la --git'
    alias lt   'eza --icons --group-directories-first --tree --level=2'
end

# zoxide replaces cd: it remembers where you went and jumps along a piece of the path.
# init gives a function to cd, so regular cd continues to work as before.
if type -q zoxide
    zoxide init --cmd cd fish | source
end

# bat instead of cat: syntax highlighting and line numbers. --paging=never to
# in scripts and pipes it behaved like a regular cat.
if type -q bat
    alias cat 'bat --paging=never'
    set -gx BAT_THEME ansi
end

# The prompt string lives in functions/fish_prompt.fish.
# The definition here overlapped the file, and edits to it had no effect.



# Updating the system and installing packages in whole words. abbr unfolds
# to the command directly on the line - you can see what will go under sudo right now, and this
# more important than saving on clicks when it comes to -Syu.
abbr -a upd 'sudo pacman -Syu'
abbr -a ins 'sudo pacman -S'

# Pacman base
abbr -a i 'sudo pacman -S'       # Installa
abbr -a syu 'sudo pacman -Syu'     # Aggiorna sistema
abbr -a r 'sudo pacman -Rns'      # Rimuove con dipendenze inutilizzate
abbr -a pacc 'pacman -Ss'           # Cerca nei repo
abbr -a pace 'pacman -Qe'         # Elenca pacchetti installati esplicitamente

# Se usi un AUR helper (es. yay o paru)
abbr -a y 'yay'                     # Scorciatoia universale per AUR
abbr -a yi 'yay -S'
abbr -a ysyu 'yay -Syu'

# Git
abbr -a gs 'git status'
abbr -a ga 'git add'
abbr -a gc 'git commit -m'
abbr -a gp 'git push'

# Clear the screen with one letter. It is alias, not abbr: abbr is expanded
# to a line and requires Enter twice for something that should work instantly.
alias c clear

# fastfetch is deliberately not called when starting the terminal: it is needed when it is
# they ask, and not with every new window. Its settings are in
# ~/.config/fastfetch/config.jsonc and are picked up by a normal `fastfetch` call.
# Short form to avoid typing the whole name:
abbr -a ff 'fastfetch'


set -gx PATH "$HOME/.local/bin" $PATH

# ==============================================================================
# Пользовательские настройки (User Custom Overrides)
# Файлы ~/.config/fish/custom.fish и ~/.config/fish/custom/*.fish
# сохраняются при обновлениях Panacea и никогда не затираются.
# ==============================================================================
if test -f $__fish_config_dir/custom.fish
    source $__fish_config_dir/custom.fish
end
if test -d $__fish_config_dir/custom
    for f in $__fish_config_dir/custom/*.fish
        test -r $f; and source $f
    end
end
