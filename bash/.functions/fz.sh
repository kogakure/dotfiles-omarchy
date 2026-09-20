# Search zoxide history with fzf
# rupa/z's `_z` is not on this machine; Omarchy inits zoxide.

fz() {
    if ! command -v zoxide >/dev/null 2>&1; then
        echo "Error: zoxide is not installed or not in PATH"
        return 1
    fi

    # If arguments are provided, jump to the best match
    if [ $# -gt 0 ]; then
        local dir
        dir=$(zoxide query "$@") || return
        cd "$dir" || return 1
        return
    fi

    # Use fzf to select from zoxide history
    local dir
    dir=$(zoxide query -l |
        fzf --height 40% --nth 1.. --reverse --info=inline +s --tac --query "${*##-* }" \
            --preview 'eza -l {}' \
            --preview-window right:50% \
            --bind 'ctrl-/:change-preview-window(down|hidden|)' \
            --header 'Press CTRL-/ to toggle preview window')

    # Change to the selected directory
    if [ -n "$dir" ]; then
        cd "$dir" || return 1
    fi
}
