# dotfiles-omarchy

Personal overlays for [Omarchy](https://omarchy.org/) Linux. Separate from [kogakure/dotfiles](https://github.com/kogakure/dotfiles) (macOS). GNU Stow links these files into `$HOME`.

Omarchy owns `/usr/share/omarchy`. This repo only tracks **your** files under `~/.config` and `~/.bashrc`.

## New machine

1. Install Omarchy.
2. Log into GitHub (`gh auth login`) and add an SSH key for this machine.
3. Clone and stow:

```bash
git clone git@github.com:kogakure/dotfiles-omarchy.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` backs up any conflicting regular files, then restows. Rerun it after `omarchy refresh` if a symlink was replaced with a real file.

Host overlay is selected by hostname (`omarchy` on this laptop). Override with `DOTFILES_HOST=omarchy ./install.sh`.

## Layout

| Package | Lives at | Notes |
|---|---|---|
| `hypr` | `~/.config/hypr/*.lua` | Shared Hyprland overrides. `hyprland.lua` reclaims workspaces when a display unplugs. |
| `hosts/omarchy` | `~/.config/hypr/monitors.lua` | This machine: laptop + Studio Display. |
| `git` | `~/.config/git/config` | Identity and aliases. Credential helper is `gh`, not a machine path. |
| `bash` | `~/.bashrc` | Keep sourcing Omarchy's rc; add aliases below the comment. |
| `env` | `~/.config/environment.d/ssh-agent.conf` | User ssh-agent socket. |
| `omarchy` | `~/.config/omarchy/hooks/post-update.d/` | After `omarchy update`, print git drift if any. |

Package lists in `packages/` are for extras you add later (`omarchy pkg add`, AUR). They are not applied automatically.

## Daily use

Edit the live files (`Super + Space` → Setup, or `$EDITOR ~/.config/hypr/...`). They are symlinks, so `git -C ~/dotfiles status` sees the change. Commit from `~/dotfiles`.

`omarchy refresh` / some updates **write through or replace** those symlinks. After an update, check `git -C ~/dotfiles status`. Keep, merge, or restore; rerun `./install.sh` if a link became a regular file. The post-update hook only reports this; it does not reset configs.

## Do not track

- `/usr/share/omarchy`
- `~/.local/state/omarchy/current` (generated theme copies)
- SSH private keys, `~/.config/gh/hosts.yml`
- Browser profiles
- Hook `*.sample` files Omarchy ships

Grow this tree when a setting actually diverges. Do not snapshot all of `~/.config`.
