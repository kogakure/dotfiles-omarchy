# Modified version where you can press
#   - CTRL-O to open with xdg-open,
#   - CTRL-E or Enter key to open with the $EDITOR

fo() {
    # Use process substitution to capture fzf output
    IFS=$'\n' read -r -d '' key file <<EOF
$(fzf-tmux --query="$1" --exit-0 --expect=ctrl-o,ctrl-e)
EOF

    # Check if a file was selected
    if [ -n "$file" ]; then
        if [ "$key" = "ctrl-o" ]; then
            xdg-open "$file"
        else
            ${EDITOR:-nvim} "$file"
        fi
    fi
}
