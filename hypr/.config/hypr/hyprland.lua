-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Hyprland workspaces are global: each monitor occupies one of 1-10.
-- Unplugging the Studio Display can leave its workspace on a dead or 0x0 MST
-- output, so Super+1..5 appears blocked. Move those back to the laptop.
local function monitor_is_usable(monitor)
  if not monitor or (monitor.width or 0) <= 0 or (monitor.height or 0) <= 0 then
    return false
  end

  for _, live in ipairs(hl.get_monitors()) do
    if live.name == monitor.name and (live.width or 0) > 0 then
      return true
    end
  end

  return false
end

local function reclaim_orphaned_workspaces()
  local laptop = hl.get_monitor("eDP-1")
  if not laptop then
    return
  end

  for _, workspace in ipairs(hl.get_workspaces()) do
    if workspace.id and workspace.id > 0 and not workspace.special then
      if not monitor_is_usable(workspace.monitor) then
        hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(workspace.id), monitor = "eDP-1" }))
      end
    end
  end
end

hl.on("monitor.removed", function()
  hl.timer(reclaim_orphaned_workspaces, { timeout = 250, type = "oneshot" })
end)

-- Load settings written by OmaSettings (omasettings:managed).
require("hypr.omasettings")
