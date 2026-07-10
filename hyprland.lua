local terminal = "ghostty"
local pill_ipc = "/home/stivi/.config/hypr/scripts/pill-ipc.sh"

-- Autostart
hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
  hl.exec_cmd("/usr/libexec/hyprpolkitagent")
  hl.exec_cmd("gentoo-pipewire-launcher")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("/home/stivi/.config/hypr/scripts/watchdog.sh pill")
  hl.exec_cmd(
    "python3 /home/stivi/.config/hypr/scripts/wallcolors.py --hyprpaper /home/stivi/.config/hypr/hyprpaper.conf")
  hl.exec_cmd("/home/stivi/.config/hypr/scripts/cliphist-watch.sh")
  hl.exec_cmd("bash /home/stivi/.config/hypr/xdg-portal-hyprland")
  hl.exec_cmd("hypridle")
end)

-- Environment variables
hl.env("XCURSOR_THEME", "Hackneyed")
hl.env("XCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("GTK_USE_PORTAL", "1")

-- Sections
hl.config({
  xwayland = {
    enabled = false
  },
  input = {
    natural_scroll = true
  },
  general = {
    gaps_in = 6,
    gaps_out = 14,
    border_size = 3,
    resize_on_border = true,
    col = {
      active_border = {
        colors = { "rgba(ff0000ff)", "rgba(00ff00ff)" },
        angle = 45
      },
      inactive_border = "rgba(595959aa)"
    }
  },
  dwindle = {
    force_split = 2
  },
  decoration = {
    dim_inactive = true,
    dim_strength = 0.1,
    blur = {
      enabled = true,
      size = 8,
      passes = 2,
      new_optimizations = true,
    },
  }
})

-- Border Animation
hl.curve("linear", {
  type = "bezier",
  points = { { 0.0, 0.0 }, { 1.0, 1.0 } }
})

hl.animation({
  leaf = "border",
  enabled = true,
  speed = 10,
  bezier = "default"
})

hl.animation({
  leaf = "borderangle",
  enabled = true,
  speed = 100,
  bezier = "linear",
  style = "loop"
})

hl.bind("SUPER+Return", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER+Tab", hl.dsp.exec_cmd(pill_ipc .. " peek"))
hl.bind("SUPER+Space", hl.dsp.exec_cmd(pill_ipc .. " launcher"))
hl.bind("SUPER+V", hl.dsp.exec_cmd(pill_ipc .. " clipboard"))
hl.bind("SUPER+Escape", hl.dsp.exec_cmd(pill_ipc .. " power"))

hl.bind("SUPER+W", hl.dsp.window.close())
hl.bind("SUPER+SHIFT+V", hl.dsp.window.float({ action = "toggle" }))

hl.bind("SUPER+J", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER+SHIFT+J", hl.dsp.window.move({ workspace = "e-1", follow = true }))
hl.bind("SUPER+K", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER+SHIFT+K", hl.dsp.window.move({ workspace = "e+1", follow = true }))
hl.bind("SUPER+N", hl.dsp.focus({ workspace = "emptyn" }))
hl.bind("SUPER+SHIFT+N", hl.dsp.window.move({ workspace = "emptyn", follow = true }))

hl.bind("SUPER+SHIFT+3", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind("SUPER+SHIFT+4", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("SUPER+SHIFT+5", hl.dsp.exec_cmd("hyprshot -m window"))

hl.bind("CTRL+SUPER+Q", hl.dsp.exec_cmd("pidof hyprlock || loginctl lock-session"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.global("quickshell:mediaToggle"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.global("quickshell:mediaNext"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.global("quickshell:mediaPrev"), { locked = true })
