#!/usr/bin/env bash
# Stow user overlays into $HOME. Safe to rerun.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="${DOTFILES_HOST:-$(hostname -s)}"
TARGET="${HOME}"
PACKAGES=(hypr git bash env omarchy)

need_cmd() {
  command -v "$1" >/dev/null || {
    echo "Missing $1. Install with: omarchy pkg add $1" >&2
    exit 1
  }
}

need_cmd stow

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

for pkg in "${PACKAGES[@]}"; do
  stow_package "$ROOT" "$pkg"
done

if [[ -d "$ROOT/hosts/$HOST" ]]; then
  stow_package "$ROOT/hosts" "$HOST"
else
  echo "No host overlay for '$HOST' (expected $ROOT/hosts/$HOST)" >&2
fi

chmod +x "$ROOT/omarchy/.config/omarchy/hooks/post-update.d/dotfiles-status" 2>/dev/null || true
chmod +x "$ROOT/packages/snapshot" 2>/dev/null || true

echo "Stowed packages into $TARGET"
