# shellcheck shell=bash
# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# --- User PATH and env (non-interactive too) --------------------------------
# Ported from kogakure/dotfiles shell/{path,env}.spec. @darwin / @brew dropped.

path_add() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$PATH:$1" ;;
  esac
}

# mise shims and ~/.local/bin are already in env-bootstrap; listed so the
# intended set is visible. bun/pnpm/cargo dirs appear once those toolchains
# write them (global installs, rustup).
path_add "$HOME/.local/share/mise/shims"
path_add "$HOME/.local/bin"
path_add "$HOME/.bun/bin"
path_add "$HOME/.local/share/pnpm/bin"
path_add "$HOME/.cargo/bin"
export PATH
unset -f path_add

export EDITOR=nvim
export GIT_EDITOR=nvim

export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export FD_OPTIONS="--follow --exclude .git --exclude node_modules"
export FZF_ALT_C_COMMAND="fd --type d ${FD_OPTIONS} --color=never --hidden"
# eza, not tree: tree is not installed, eza is the listing tool.
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -50'"
export FZF_CTRL_R_OPTS="--reverse"
export FZF_CTRL_T_COMMAND="git ls-files --cached --others --exclude-standard | fd --hidden --type f --type l ${FD_OPTIONS}"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers {}' --bind shift-up:preview-page-up,shift-down:preview-page-down"
export FZF_DEFAULT_COMMAND="$FZF_CTRL_T_COMMAND"
export FZF_DEFAULT_OPTS="--no-height"
export FZF_TMUX=1
export FZF_TMUX_OPTS="-p"

export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/.local/share/pnpm"

# mise owns the version; stop claude/grok rewriting the pinned binary (SI-122).
export DISABLE_AUTOUPDATER=1
export GROK_DISABLE_AUTOUPDATER=1

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
# shellcheck disable=SC1091
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Collision decisions vs Omarchy default/bash/aliases (SI-134):
#   c    Omarchy wins (opencode --auto). Ctrl+L clears; do not port c=clear.
#   cx   Omarchy wins (claude --permission-mode auto). Dangerous Claude is cc.
#   cy   User flags win: sandbox bypass instead of Omarchy's --approve-for-me.
#   n    Omarchy wins (nvim function). Spec has no n.
#   ls   Omarchy wins (eza -lh --icons=auto). Port ll for a git long listing.
#   lt   Omarchy wins (eza --tree --level=2).
#   t    Omarchy wins (tmux attach || new -s Work). Port ta as attach-only.
# Dropped: @darwin (icloud, dropbox, ia), emacs/e (not installed),
# glu (no config-personal; identity is in git/config).

if GPG_TTY="$(tty)" && [ "$GPG_TTY" != "not a tty" ]; then
  export GPG_TTY
else
  unset GPG_TTY
fi

alias reload='source ~/.bashrc'

alias cd..='cd ..'
alias mkdir='mkdir -p'
alias ll='eza -lh --git --group-directories-first --icons=auto'
alias dotfiles='cd $HOME/dotfiles'

alias lg='lazygit'
alias v='vim'
if command -v nvim >/dev/null 2>&1; then
  alias vim='nvim'
fi

alias ta='tmux attach'
alias ars='atuin run script'
alias cc='claude --dangerously-skip-permissions'
alias cy='codex --dangerously-bypass-approvals-and-sandbox'
alias youtube-dl='yt-dlp'
