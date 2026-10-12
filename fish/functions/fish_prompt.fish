function fish_prompt --description 'Single-line prompt in pill style'
    # What remains from the previous team - we catch before any calls
    set -l last_status $status

    # The emphasis comes from conf.d/theme_colors.fish, which writes switch_theme.sh
    set -l accent normal
    if set -q fish_color_command
        set accent (string replace -r '\s.*' '' -- $fish_color_command)
    end
    test -n "$accent"; or set accent normal

    # Catalog without a tilde: home is shown as a word, otherwise the latest
    # two parts of the path - this way the line remains short and without service marks
    set -l cwd (string replace -r '^~/?' '' -- (prompt_pwd -d 2))
    test -n "$cwd"; or set cwd home

    set_color 4a4a4a
    echo -n '▍'
    set_color $accent --bold
    echo -n $cwd
    set_color normal

    # Git branch - only the name and an asterisk if there is an uncommitted one
    set -l branch (command git symbolic-ref --short HEAD 2>/dev/null; or command git rev-parse --short HEAD 2>/dev/null)
    if test -n "$branch"
        set_color 6a6a6a
        echo -n '  '(string sub -l 24 -- $branch)
        command git diff-index --quiet HEAD -- 2>/dev/null; or echo -n '*'
        set_color normal
    end

    # Background tasks
    set -l running (count (jobs -p))
    if test $running -gt 0
        set_color 6a6a6a
        echo -n "  ⏵$running"
        set_color normal
    end

    # Separator: turns red if the previous team fell
    if test $last_status -ne 0
        set_color ff5555
        echo -n '  ⟢ '
    else
        set_color $accent
        echo -n '  ⟢ '
    end
    set_color normal
end
