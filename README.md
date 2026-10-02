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

`install.sh` inits the `private/` submodule, backs up any conflicting regular files, then restows. Rerun it after `omarchy refresh` if a symlink was replaced with a real file. The machine needs SSH access to `kogakure/vault`; if the submodule cannot be fetched, `install.sh` stops.

Then install the pinned CLI tools (Omarchy already put mise on `PATH`):

```bash
mise trust ~/.config/mise/mise.toml
mise install
```

Host overlay is selected by hostname (`omarchy` on this laptop). Override with `DOTFILES_HOST=omarchy ./install.sh`.

## Layout

| Package | Lives at | Notes |
|---|---|---|
| `hypr` | `~/.config/hypr/*.lua` | Shared Hyprland overrides. `hyprland.lua` reclaims workspaces when a display unplugs. |
| `hosts/omarchy` | `~/.config/hypr/monitors.lua` | This machine: laptop + Studio Display. |
| `git` | `~/.config/git/config`, `ignore` | No identity. Includes Omarchy's shipped git config, then personal or work identity when the repo is under `~/Code/personal` or `~/Code/work`. `gh` credentials, hunk/delta, extra aliases. Global gitignore. |
| `private` | not stowed | Submodule of `kogakure/vault` (same repo as the macOS dotfiles). Git reads the identity files from here; they are not copied into `~/.config`. |
| `bash` | `~/.bashrc`, `~/.functions/*.sh` | Keep sourcing Omarchy's rc; PATH, env and aliases in bashrc. Functions in a sourced directory (Omarchy's `fns` pattern). |
| `env` | `~/.config/environment.d/ssh-agent.conf` | User ssh-agent socket. |
| `omarchy` | `~/.config/omarchy/hooks/post-update.d/` | After `omarchy update`, print git drift if any. |
| `mise` | `~/.config/mise/mise.toml` | Pinned CLI tools. Loads after Omarchy's `config.toml`, so pins win. |
| `ghostty` | `~/.config/ghostty/config` | Personal deltas; Omarchy still owns the colour block via the generated theme include. |
| `atuin` | `~/.config/atuin/config.toml` | History search settings from the Macs. The binary is the mise pin. `atuin login` is interactive; the encryption key stays in Proton Pass. |

## Extra packages

CLI tools are pinned in `mise/.config/mise/mise.toml`. `packages/official.txt` and `packages/aur.txt` are only for extras **mise cannot supply**, plus explicitly installed packages that are **not** Omarchy defaults (ISO lists, `core`, distro meta-packages, CPU microcode). They are not applied automatically.

Refresh the lists from this machine, then commit if the diff looks right:

```bash
~/dotfiles/packages/snapshot
```

On a new machine, after `./install.sh`:

```bash
grep -vE '^#|^$' packages/official.txt | xargs -r omarchy pkg add
grep -vE '^#|^$' packages/aur.txt | xargs -r omarchy pkg aur add
```

The post-update hook reminds you when the lists have drifted. It does not rewrite them.

## Daily use

Edit the live files (`Super + Space` → Setup, or `$EDITOR ~/.config/hypr/...`). They are symlinks, so `git -C ~/dotfiles status` sees the change. Commit from `~/dotfiles`.

`omarchy refresh` / some updates **write through or replace** those symlinks. After an update, check `git -C ~/dotfiles status`. Keep, merge, or restore; rerun `./install.sh` if a link became a regular file. The post-update hook only reports this; it does not reset configs.

## Private submodule

`private/` is [kogakure/vault](https://github.com/kogakure/vault). Same role as `private/` in the macOS dotfiles: identity, agent configs, app preferences, Wakatime, and signing-key material stay out of this public tree.

`./install.sh` runs `git submodule update --init -- private`. Git then reads:

- `~/dotfiles/private/git/config-personal`
- `~/dotfiles/private/git/config-work`

Those paths are in the public git config. The files stay in the submodule. Nothing else in the vault is wired up. jj, GPG, agent configs and Espanso each get their own links when those are ported. Nested submodules inside the vault (agent skills, Claude plugins) are not initialized here.

Repos under `~/Code/personal` and `~/Code/work` pick up the matching identity file. `~/dotfiles` is outside those trees, so `install.sh` points this checkout at `config-personal` and leaves `commit.gpgsign` off. Anywhere else, run `glu` once in that repo:

```bash
git config --local include.path ~/dotfiles/private/git/config-personal
```

`config-personal` also sets `commit.gpgsign`. The public git config turns signing back off, because this machine does not have the secret key yet. `glu` writes a local include, which beats that global override, so a repo you `glu` will try to sign until you set `commit.gpgsign` false locally or import the key.

## Do not track

- `/usr/share/omarchy`
- `~/.local/state/omarchy/current` (generated theme copies)
- SSH private keys, `~/.config/gh/hosts.yml`
- Git name, email and signing key (those live in `private/git/`)
- Browser profiles
- Hook `*.sample` files Omarchy ships
- `~/.config/mise/config.toml` (Omarchy writes this via `mise use -g`)

Grow this tree when a setting actually diverges. Do not snapshot all of `~/.config`.
