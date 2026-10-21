#!/usr/bin/env bash
# Stow user overlays into $HOME. Safe to rerun.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="${DOTFILES_HOST:-$(hostname -s)}"
TARGET="${HOME}"
PACKAGES=(hypr git bash env omarchy mise ghostty atuin herdr)

need_cmd() {
  command -v "$1" >/dev/null || {
    echo "Missing $1. Install with: omarchy pkg add $1" >&2
    exit 1
  }
}

need_cmd stow
need_cmd git

# Identity lives in the vault submodule, not in this public tree (SI-137).
# Nested submodules inside private/ (agent skills, Claude plugins) stay
# uninitialised; the tickets that use them can init those later.
init_private() {
  if [[ ! -e "$ROOT/.git" || ! -f "$ROOT/.gitmodules" ]]; then
    echo "Not a full checkout; skipping private submodule" >&2
    return 0
  fi

  git -C "$ROOT" submodule update --init -- private
}

backup_if_conflict() {
  local dest="$1"
  local src="$2"

  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    return
  fi

  if [[ -L "$dest" ]]; then
    local resolved
    resolved="$(readlink -f "$dest")"
    if [[ "$resolved" == "$(readlink -f "$src")" ]]; then
      return
    fi
  fi

  local bak="${dest}.bak.$(date +%s)"
  echo "Backing up $dest -> $bak"
  mv "$dest" "$bak"
}

stow_package() {
  local dir="$1"
  local pkg="$2"
  local pkg_root="$dir/$pkg"

  if [[ ! -d "$pkg_root" ]]; then
    echo "Skipping missing package: $pkg" >&2
    return
  fi

  while IFS= read -r -d '' file; do
    local rel="${file#"$pkg_root"/}"
    mkdir -p "$TARGET/$(dirname "$rel")"
    backup_if_conflict "$TARGET/$rel" "$file"
  done < <(find "$pkg_root" -type f -print0)

  stow -v -d "$dir" -t "$TARGET" -R "$pkg"
}

# herdr installs plugin checkouts under ~/.config/herdr/plugins/github.
# If that directory does not exist yet, stow would link the whole plugins
# tree into this repo and the next plugin install would write into git.
mkdir -p "$TARGET/.config/herdr/plugins/github" "$TARGET/.config/herdr/plugins/config"

init_private

for pkg in "${PACKAGES[@]}"; do
  stow_package "$ROOT" "$pkg"
done

install_herdr_plugins() {
  local list="$ROOT/packages/herdr-plugins"
  [[ -f "$list" ]] || return 0
  if ! command -v herdr >/dev/null; then
    echo "herdr is not on PATH; skipped plugin install. Run mise install, then ./install.sh again." >&2
    return 0
  fi

  local installed line spec
  installed="$(herdr plugin list 2>/dev/null || true)"
  while IFS= read -r line || [[ -n "$line" ]]; do
    spec="${line%%#*}"
    spec="${spec#"${spec%%[![:space:]]*}"}"
    spec="${spec%"${spec##*[![:space:]]}"}"
    [[ -z "$spec" ]] && continue
    if [[ "$installed" == *"$spec"* ]]; then
      continue
    fi
    herdr plugin install "$spec" --yes
  done < "$list"
}

# This checkout lives outside the includeIf directories, so without a local
# include, commits here have no identity. Signing stays off until SI-152:
# config-personal turns it on, and a local value beats the global override.
# No symlink into ~/.config/git: stow treats a link that points back into
# this repo as one of its own and folds the directory on the next restow.
if [[ -e "$ROOT/.git" && -f "$ROOT/private/git/config-personal" ]]; then
  # Quoted on purpose: git expands ~ in include.path. Leave it for git.
  # shellcheck disable=SC2088
  git -C "$ROOT" config --local include.path '~/dotfiles/private/git/config-personal'
  git -C "$ROOT" config --local commit.gpgsign false
fi

if [[ -d "$ROOT/hosts/$HOST" ]]; then
  stow_package "$ROOT/hosts" "$HOST"
else
  echo "No host overlay for '$HOST' (expected $ROOT/hosts/$HOST)" >&2
fi

chmod +x "$ROOT/omarchy/.config/omarchy/hooks/post-update.d/dotfiles-status" 2>/dev/null || true
chmod +x "$ROOT/packages/snapshot" 2>/dev/null || true
chmod +x "$ROOT/bin/node-install" 2>/dev/null || true

install_herdr_plugins

echo "Stowed packages into $TARGET"
