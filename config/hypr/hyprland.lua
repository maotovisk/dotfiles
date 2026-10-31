-- Hyprland Lua config for 0.55+ / latest -git wiki.
-- Keep hyprland.conf around until the installed Hyprland build is upgraded.

local home = os.getenv("HOME") or ""
local path = os.getenv("PATH") or ""

local terminal = "kitty"
local file_manager = "dolphin"
local menu = "vicinae open"
local browser = "zen-browser"
local main_mod = "SUPER"

local function bind_exec(keys, cmd, flags)
  hl.bind(keys, hl.dsp.exec_cmd(cmd), flags)
end

hl.monitor({
  output = "DP-2",
  mode = "1920x1080@180",
  position = "0x0",
  scale = 1,
  vrr = 0,
  transform = 0,
})

hl.monitor({
  output = "DP-1",
  mode = "1920x1080@144",
  position = "1920x0",
  scale = 1,
  vrr = 0,
})

hl.workspace_rule({ workspace = "1", monitor = "DP-2" })
hl.workspace_rule({ workspace = "2", monitor = "DP-1" })

hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_MENU_PREFIX", "plasma-")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("PROTON_FSR4_UPGRADE", "1")
hl.env("XCURSOR_THEME", "breeze_cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("PATH", path .. ":" .. home .. "/.dotnet/tools/")

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 1,
    ["col.active_border"] = "rgba(9a9b9ca8)",
    ["col.inactive_border"] = "rgba(585858a8)",
    resize_on_border = true,
    allow_tearing = true,
    layout = "scrolling",
  },

  scrolling = {
    column_width = 0.67
  },

  decoration = {
    rounding = 12,
    active_opacity = 0.92,
    inactive_opacity = 0.86,
    fullscreen_opacity = 1.0,

    blur = {
      enabled = true,
      variant = "haze",
      size = 6,
      passes = 2,
      new_optimizations = true,
      ignore_opacity = true,
      noise = 0.0,
      contrast = 0.95,
      brightness = 1.05,
      vibrancy = 0.3,
      vibrancy_darkness = 0.1,
      popups = true,
      popups_ignorealpha = 0.6,

      -- Liquid glass: clear centre, refractive lens rim, faint colour fringing
      acrylic = {
        refraction = 18,
        bulb = 36,
        clarity = 0.92,
        aberration = 0.012,
        tint = "rgba(ffffff0d)",
      },
    },

    shadow = {
      enabled = true,
      range = 10,
      render_power = 3,
      color = "rgba(00000066)",
    },
  },

  animations = {
    enabled = true,
  },

  dwindle = {
    preserve_split = true,
  },

  master = {
    new_status = "master",
  },

  misc = {
    force_default_wallpaper = 0,
    enable_anr_dialog = false,
    disable_hyprland_logo = false,
    middle_click_paste = false,
    vrr = 1,
  },

  render = {
    direct_scanout = 1,
  },

  debug = {
    overlay = false,
  },

  input = {
    kb_layout = "us,br",
    kb_variant = "alt-intl,abnt2",
    kb_options = "grp:rctrl_toggle",
    follow_mouse = 1,
    accel_profile = "flat",
    sensitivity = 0,

    touchpad = {
      natural_scroll = false,
    },
  },

  cursor = {
      no_hardware_cursors = 0,
  },
})

hl.device({
  name = "opentabletdriver-virtual-artist-tablet",
  output = "DP-2",
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("eioc", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

hl.on("hyprland.start", function()
  hl.exec_cmd("fcitx5 -d --replace")
  hl.exec_cmd("xrandr --output DP-2 --primary")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("vicinae server")
  hl.exec_cmd("nm-applet")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
  hl.exec_cmd([[gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"]])
  hl.exec_cmd([[gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"]])
  hl.exec_cmd("qs")
end)

-- Apps asking to be maximized: ignore the request. In the scrolling layout a
-- lone column already fills the screen, and un-maximizing afterwards (the old
-- window.update_rules hook) left Hyprland 0.57 with the Top-layer fade stuck
-- at 0 — the bar vanished until the next workspace switch.
hl.window_rule({
  name = "suppress-maximize",
  match = { class = ".*" },
  suppress_event = "maximize",
})

bind_exec(main_mod .. " + SHIFT + C", home .. "/.local/bin/toggle-warp")
bind_exec(main_mod .. " + C", "qs ipc call shell toggleCalendar")
bind_exec(main_mod .. " + SHIFT + Z", "pkill -x qs; sleep 0.3; qs")
bind_exec(main_mod .. " + SHIFT + S", home .. "/.local/bin/sul-uploader")
bind_exec(main_mod .. " + SHIFT + G", home .. "/.local/bin/osu-gamma")

bind_exec(main_mod .. " + RETURN", terminal)
hl.bind(main_mod .. " + SHIFT + Q", hl.dsp.window.close())
bind_exec(main_mod .. " + M", [[sh -c 'zenity --question --title "Exit Hyprland" --text "You pressed the exit shortcut. Do you really want to exit Hyprland? This will end your Wayland session." --ok-label "Yes, exit Hyprland" && hyprshutdown']])
bind_exec(main_mod .. " + E", file_manager)
bind_exec(main_mod .. " + B", browser)
hl.bind(main_mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
bind_exec(main_mod .. " + R", menu)
bind_exec(main_mod .. " + N", "qs ipc call notifications toggleCenter")
bind_exec(main_mod .. " + D", "vopono exec discord -p mullvad -c wireguard -s canada")
hl.bind(main_mod .. " + SHIFT + bracketleft", hl.dsp.dpms(false))
hl.bind(main_mod .. " + SHIFT + bracketright", hl.dsp.dpms(true))
bind_exec(main_mod .. " + SHIFT + N", "qs ipc call notifications toggleDnd")
hl.bind(main_mod .. " + P", hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind(main_mod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(main_mod .. " + SHIFT + V", hl.dsp.layout("fit active"))
hl.bind(main_mod .. " + period", hl.dsp.layout("move +col"))
hl.bind(main_mod .. " + comma", hl.dsp.layout("swapcol l"))

hl.bind(main_mod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(main_mod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(main_mod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(main_mod .. " + down", hl.dsp.focus({ direction = "d" }))

hl.bind(main_mod .. " + 1", hl.dsp.focus({ workspace = "1" }))
hl.bind(main_mod .. " + 2", hl.dsp.focus({ workspace = "2" }))
hl.bind(main_mod .. " + 3", hl.dsp.focus({ workspace = "3" }))
hl.bind(main_mod .. " + 4", hl.dsp.focus({ workspace = "4" }))
hl.bind(main_mod .. " + 5", hl.dsp.focus({ workspace = "5" }))
hl.bind(main_mod .. " + 6", hl.dsp.focus({ workspace = "6" }))
hl.bind(main_mod .. " + 7", hl.dsp.focus({ workspace = "7" }))
hl.bind(main_mod .. " + 8", hl.dsp.focus({ workspace = "8" }))
hl.bind(main_mod .. " + 9", hl.dsp.focus({ workspace = "9" }))
hl.bind(main_mod .. " + 0", hl.dsp.focus({ workspace = "10" }))

hl.bind(main_mod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = "1" }))
hl.bind(main_mod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = "2" }))
hl.bind(main_mod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = "3" }))
hl.bind(main_mod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = "4" }))
hl.bind(main_mod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = "5" }))
hl.bind(main_mod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = "6" }))
hl.bind(main_mod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = "7" }))
hl.bind(main_mod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = "8" }))
hl.bind(main_mod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = "9" }))
hl.bind(main_mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))

hl.bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("ALT + Tab", function()
  hl.dispatch(hl.dsp.window.cycle_next({}))
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

hl.bind("XF86AudioPlay", hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "M", window = "class:^(discord)$" }))
hl.bind("XF86AudioPause", hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "M", window = "class:^(discord)$" }))

hl.bind("Alt + SHIFT + Return", hl.dsp.global("afogados:overlay_chat"))
hl.bind("CTRL + ALT + R", hl.dsp.global("com.a2tools.dps-meter:reset"))
hl.bind("CTRL + ALT + Up", hl.dsp.global("com.a2tools.dps-meter:toggle"))
hl.bind("CTRL + ALT + L", hl.dsp.global("com.a2tools.dps-meter:lock"))

hl.window_rule({
  match = { fullscreen_state_client = 2 },
  immediate = true,
})

-- Afogados / HTML5 stream fullscreen: keep this window out of the tearing path.
-- With Aquamarine 0.15.1, immediate presentation + a swapchain reconfigure makes
-- Hyprland submit ATOMIC_ALLOW_MODESET | PAGE_FLIP_ASYNC, which amdgpu rejects
-- with EINVAL and retries every frame (visible flicker). Must come after the
-- generic rule above so the last matching rule wins. Games keep tearing.
hl.window_rule({
  name = "no-tearing-afogados",
  match = {
    class = "^(afogados)$",
    fullscreen_state_client = 2,
  },
  immediate = false,
})

hl.window_rule({
  name = "jetbrains-toolbox",
  match = {
    class = "jetbrains-toolbox",
    float = true,
  },
  no_initial_focus = true,
})

hl.window_rule({
  name = "jetbrains-popups",
  match = {
    class = "(jetbrains-)(.*)",
    title = "^win(.*)",
  },
  no_initial_focus = true,
})

hl.window_rule({
  name = "jetbrains-splash",
  match = {
    class = "(jetbrains-)(.*)",
    title = "^$",
    float = true,
  },
  size = "672 700",
})

hl.window_rule({
  name = "picture-in-picture",
  match = {
    title = "(.*)(Picture-in-Picture)",
  },
  float = true,
})

hl.window_rule({
  name = "satty-rules",
  match = {
    class = "(com.gabm.satty)(.*)",
  },
  immediate = false,
  no_anim = true,
})

hl.window_rule({
  name = "osu-editor-l-popups-stable",
  match = {
    class = "(osu!.exe)",
    float = true,
    title = "(.*)((Rotate by)|(Scale by)|(Polygonal Circle Creation)|(Timing and Control Points))",
  },
  stay_focused = true,
})

hl.window_rule({
  name = "osu-editor-l-tooltips-stable",
  match = {
    class = "^(osu!.exe)$",
    title = "^$",
    initial_title = "^$",
    float = true,
  },
  no_initial_focus = true,
})

hl.window_rule({
  name = "osu-editor-popups-stable",
  match = {
    class = "(osu_stable)",
    float = true,
    title = "(.*)((Rotate by)|(Scale by)|(Polygonal Circle Creation)|(Timing and Control Points))",
  },
  stay_focused = true,
})

hl.window_rule({
  name = "osu-editor-tooltips-stable",
  match = {
    class = "^(osu_stable)$",
    title = "^$",
    initial_title = "^$",
    float = true,
  },
  no_initial_focus = true,
})

hl.window_rule({
  name = "osu-editor-tooltips",
  match = {
    class = "^(osu-unstable-exe)$",
    title = "^$",
    initial_title = "^$",
    float = true,
  },
  no_initial_focus = true,
})

hl.window_rule({
  name = "osu-editor-popups",
  match = {
    class = "(osu-unstable-exe)",
    float = true,
    title = "(.*)((Rotate by)|(Scale by)|(Polygonal Circle Creation)|(Timing and Control Points))",
  },
  stay_focused = true,
})

hl.window_rule({
  name = "gsr-ui",
  match = {
    title = "(gsr ui)",
  },
  no_blur = false,
  stay_focused = true,
})

hl.window_rule({
  name = "kde-portal",
  match = {
    class = "(org.freedesktop.impl.portal.desktop.kde)",
  },
  float = true,
})

hl.window_rule({
  name = "gtk-portal",
  match = {
    class = "(xdg-desktop-portal-gtk)",
  },
  float = true,
})

hl.window_rule({
    name = "aion-dps-meter",
    match = {
        class = "^(a2tools\\-dps\\-meter)$",
    },
    float = true,
    pin = true,
    no_blur = true,
    no_shadow = true,
    border_size = 0,
})

hl.layer_rule({
  name = "wofi-style",
  match = { namespace = "wofi" },
  animation = "slidevert",
  blur = true,
})

hl.layer_rule({
  name = "hyprlauncher-style",
  match = { namespace = "(hyprlauncher|launcher|vicinae)" },
  animation = "slidevert",
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.35,
})

hl.layer_rule({
  name = "screenshare-picker",
  match = { namespace = "(ch.wysbd.hyprland-preview-share-picker)" },
  animation = "slidevert",
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.35,
})

-- Quickshell "Vesper Islands": translucent dark glass, blurred by the compositor.
-- ignore_alpha 0.5 → only the glass body (α ≈ .7+) is blurred, never the
-- anti-aliased edge pixels or the outer ring (that was the white halo).
hl.layer_rule({
  name = "quickshell-bar",
  match = { namespace = "quickshell-bar" },
  animation = "slide top",
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.5,
})

-- popups animate their own card in QML; compositor animation would double it
hl.layer_rule({
  name = "quickshell-popups",
  match = { namespace = "^quickshell-(volume|network|notifications|sysmon|calendar|weather|player|toasts|share)$" },
  no_anim = true,
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.5,
})

-- dock: slides itself in QML; blur only the glass (icons are opaque anyway)
hl.layer_rule({
  name = "quickshell-dock",
  match = { namespace = "^quickshell-dock$" },
  no_anim = true,
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.5,
})

-- overview: a full-height black→clear gradient; blur would cut a hard edge
-- where the gradient crosses ignore_alpha
hl.layer_rule({
  name = "quickshell-overview",
  match = { namespace = "^quickshell-overview$" },
  no_anim = true,
})

-- snip (screenshot overlay): must appear instantly — a fade would show the
-- live screen behind the frozen frame. Overlay layer keeps it above fullscreen.
hl.layer_rule({
  name = "snip-overlay",
  match = { namespace = "^snip$" },
  no_anim = true,
})

hl.layer_rule({
  name = "swaync-style",
  match = { namespace = "swaync-control-center" },
  animation = "slide top",
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.5,
})

hl.layer_rule({
  name = "swaync-notifications-style",
  match = { namespace = "swaync-notification-window" },
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.3,
})
