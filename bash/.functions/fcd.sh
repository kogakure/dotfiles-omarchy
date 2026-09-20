# fcd - cd into directory

fcd() {
    local dir
    dir=$(find . -type d | sed '1d; s|^\./||' | fzf --preview 'eza --tree --color=always {} | head -50') && cd "$dir" || return
}
