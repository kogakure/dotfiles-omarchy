#!/usr/bin/env bash
# Stow user overlays into $HOME. Safe to rerun.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="${DOTFILES_HOST:-$(hostname -s)}"
TARGET="${HOME}"
# nvim is stowed separately, and only after omarchy-nvim-setup has seeded
# ~/.config/nvim. Creating that directory first would make setup skip the seed.
PACKAGES=(hypr xkb git bash env omarchy mise ghostty atuin herdr harper bat ripgrep gh gh-dash yazi lazygit jj opencode pi tools gnupg espanso)

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

  local bak
  bak="${dest}.bak.$(date +%s)"
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

# Secret keys stay in the vault. --batch so a locked key does not open a
# pinentry during install. Import is idempotent. The archive/ copy is an old
# key and is not imported. A missing backup skips.
import_gpg_keys() {
  local dir="$ROOT/private/gpg"
  local log
  log="$(mktemp)"

  if [[ ! -s "$dir/private_keys.asc" || ! -s "$dir/public_keys.asc" || ! -s "$dir/ownertrust.txt" ]]; then
    echo "private/gpg key backup is missing; skipped GPG key import" >&2
    rm -f "$log"
    return 0
  fi
  if ! command -v gpg >/dev/null; then
    echo "gpg is not on PATH; skipped GPG key import" >&2
    rm -f "$log"
    return 0
  fi

  if ! gpg --batch --quiet --import "$dir/public_keys.asc" >>"$log" 2>&1 ||
    ! gpg --batch --quiet --import "$dir/private_keys.asc" >>"$log" 2>&1 ||
    ! gpg --batch --quiet --import-ownertrust "$dir/ownertrust.txt" >>"$log" 2>&1; then
    echo "GPG key import failed. Log: $log" >&2
    return 1
  fi
  rm -f "$log"
  gpgconf --reload gpg-agent >/dev/null 2>&1 || true
  gpgconf --reload dirmngr >/dev/null 2>&1 || true
  echo "Imported GPG keys from private/gpg"
}

for pkg in "${PACKAGES[@]}"; do
  stow_package "$ROOT" "$pkg"
done

import_gpg_keys

# theme.lua is not in this package. It stays the relative symlink that
# omarchy-nvim-setup writes into the current theme. plugins/ already exists
# on a seeded config, so stow links our files beside it instead of replacing
# the directory. omarchy-nvim-refresh recopies the seed; rerun this script.
if [[ ! -f "$TARGET/.config/nvim/init.lua" ]]; then
  echo "omarchy-nvim is not set up; skipped the nvim overlay. Run omarchy-nvim-setup, then ./install.sh again." >&2
else
  stow_package "$ROOT" nvim
fi

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
  done <"$list"
}

install_gh_extensions() {
  local list="$ROOT/packages/gh-extensions"
  [[ -f "$list" ]] || return 0
  if ! command -v gh >/dev/null; then
    echo "gh is not on PATH; skipped extension install. Run mise install, then ./install.sh again." >&2
    return 0
  fi

  local installed line spec
  installed="$(gh extension list 2>/dev/null || true)"
  while IFS= read -r line || [[ -n "$line" ]]; do
    spec="${line%%#*}"
    spec="${spec#"${spec%%[![:space:]]*}"}"
    spec="${spec%"${spec##*[![:space:]]}"}"
    [[ -z "$spec" ]] && continue
    if [[ "$installed" == *"$spec"* ]]; then
      continue
    fi
    gh extension install "$spec"
  done <"$list"
}

# This checkout lives outside the includeIf directories, so without a local
# include, commits here have no identity. config-personal turns signing on.
# No symlink into ~/.config/git: stow treats a link that points back into
# this repo as one of its own and folds the directory on the next restow.
# The local commit.gpgsign false from before SI-152 beats that include, so
# drop it once a secret key is present. Keep it when the vault backup is not.

# Pre-commit runs bin/dotfiles-lint on staged shell. core.hooksPath replaces
# .git/hooks; this repo has no other hooks. Skip once with --no-verify.
if [[ -e "$ROOT/.git" && -f "$ROOT/.githooks/pre-commit" ]]; then
  git -C "$ROOT" config --local core.hooksPath .githooks
fi

if [[ -e "$ROOT/.git" && -f "$ROOT/private/git/config-personal" ]]; then
  # Quoted on purpose: git expands ~ in include.path. Leave it for git.
  # shellcheck disable=SC2088
  git -C "$ROOT" config --local include.path '~/dotfiles/private/git/config-personal'
  if gpg --batch --list-secret-keys --with-colons 2>/dev/null | grep -q '^sec:'; then
    git -C "$ROOT" config --local --unset commit.gpgsign || true
  else
    git -C "$ROOT" config --local commit.gpgsign false
  fi
fi

# Same constraint for jj. The public file is stowed as ~/.jjconfig.toml.
# The vault file is only the name, email and signing key, so it is a direct
# symlink. Stow would fold ~/.config/jj if that link pointed back here.
link_jj_identity() {
  local src="$ROOT/private/jj/config.toml"
  local dest="$TARGET/.config/jj/config.toml"

  if [[ ! -f "$src" ]]; then
    echo "private/jj/config.toml is missing; skipped the jj identity link" >&2
    return 0
  fi

  mkdir -p "$TARGET/.config/jj"
  backup_if_conflict "$dest" "$src"
  ln -sfn "$src" "$dest"
}

link_jj_identity

if [[ -d "$ROOT/hosts/$HOST" ]]; then
  stow_package "$ROOT/hosts" "$HOST"
else
  echo "No host overlay for '$HOST' (expected $ROOT/hosts/$HOST)" >&2
fi

chmod +x "$ROOT/omarchy/.config/omarchy/hooks/post-update.d/dotfiles-status" 2>/dev/null || true
chmod +x "$ROOT/packages/snapshot" 2>/dev/null || true
chmod +x "$ROOT/bin/node-install" 2>/dev/null || true

install_herdr_plugins
install_gh_extensions

# espanso-wayland is an AUR package, not a mise pin. Register the user
# service when the binary is already installed; skip cleanly otherwise.
# `espanso status` exits 0 only when the worker is running. "not running"
# still contains the word running, so match the exit code, not the text.
start_espanso() {
  if ! command -v espanso >/dev/null; then
    echo "espanso is not on PATH; skipped service register. Install espanso-wayland, then ./install.sh again." >&2
    return 0
  fi
  espanso service register
  if ! espanso status >/dev/null 2>&1; then
    # The first start can sit on the welcome window and time out even
    # though the worker is up. Do not fail the rest of install for that.
    if ! espanso start; then
      echo "espanso start did not report ready. Check 'espanso status'." >&2
    fi
  fi
}

start_espanso

echo "Stowed packages into $TARGET"
