local terminal = "alacritty"
local file_manager = "thunar"
local menu = "rofi -show combi"
local main_mod = "SUPER"

-- Monitor-specific rules take precedence; the blank output is the portable fallback.
hl.monitor({ output = "DP-1", mode = "preferred", position = "0x0", scale = "auto" })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@144", position = "320x1440", scale = "auto" })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.5 })

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/waybar/launch.sh")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("mako")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && ~/.config/hypr/scripts/wallpaper-selector.sh --restore")
    hl.exec_cmd("go run -C ~/repos/github/deej ~/repos/github/deej/pkg/deej/cmd/main.go")
    hl.exec_cmd("/usr/bin/hyprland-per-window-layout")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgba(33ccffee)", "rgba(00ff99ee)" },
                angle = 45,
            },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    cursor = {
        no_warps = true,
    },
    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = false,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
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
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
    },
    debug = {
        vfr = true,
    },
    input = {
        kb_layout = "us,bg",
        kb_variant = ",phonetic",
        kb_model = "",
        kb_options = "caps:escape, grp:alt_space_toggle",
        kb_rules = "",
        repeat_rate = 35,
        repeat_delay = 200,
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 1, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
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
hl.animation({ leaf = "workspaces", enabled = false, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = false, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = false, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 1, bezier = "almostLinear", style = "slide top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 1, bezier = "almostLinear", style = "slide bottom" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

hl.bind(main_mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind("ALT + Q", hl.dsp.window.close())
hl.bind(main_mod .. " + M", hl.dsp.exit())
hl.bind(main_mod .. " + E", hl.dsp.exec_cmd(file_manager))
hl.bind("CTRL + Space", hl.dsp.exec_cmd(menu))
hl.bind(main_mod .. " + ALT + P", hl.dsp.window.pseudo())
hl.bind(main_mod .. " + I", hl.dsp.layout("togglesplit"))
hl.bind(main_mod .. " + O", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-opacity.sh"))
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("hyprlock"))

hl.bind(main_mod .. " + ALT + H", hl.dsp.focus({ direction = "left" }))
hl.bind(main_mod .. " + ALT + L", hl.dsp.focus({ direction = "right" }))
hl.bind(main_mod .. " + ALT + K", hl.dsp.focus({ direction = "up" }))
hl.bind(main_mod .. " + ALT + J", hl.dsp.focus({ direction = "down" }))

-- Activate the paired support and main workspaces, then retain monitor focus.
local function switch_workspace_pair(main)
    return function()
        local focused_monitor = hl.get_active_monitor()
        hl.dispatch(hl.dsp.focus({ workspace = "1" .. main }))
        hl.dispatch(hl.dsp.focus({ workspace = main }))

        if focused_monitor then
            hl.dispatch(hl.dsp.focus({ monitor = focused_monitor }))
        end
    end
end

for i = 1, 6 do
    hl.bind("ALT + " .. i, switch_workspace_pair(i))
end

for i = 1, 9 do
    hl.bind(main_mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = false }))
end
hl.bind(main_mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10, follow = false }))

hl.bind(main_mod .. " + K", hl.dsp.window.move({ monitor = "DP-1" }))
hl.bind(main_mod .. " + J", hl.dsp.window.move({ monitor = "HDMI-A-1" }))
hl.bind(main_mod .. " + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(main_mod .. " + L", hl.dsp.window.move({ direction = "right" }))

hl.bind(main_mod .. " + T", hl.dsp.workspace.toggle_special("telegram"))
hl.bind(main_mod .. " + P", hl.dsp.workspace.toggle_special("players"))
hl.bind(main_mod .. " + W", hl.dsp.workspace.toggle_special("whatsapp"))
hl.bind(main_mod .. " + A", hl.dsp.workspace.toggle_special("ai"))
hl.bind("ALT + A", hl.dsp.exec_cmd("gtk-launch chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default"))
hl.bind("PRINT", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | magick - -shave 1x1 PNG:- | swappy -f -]]))
hl.bind("ALT + C", hl.dsp.exec_cmd("/opt/google/chrome/chrome chrome://new-tab"))

hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(main_mod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + " .. main_mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))

local repeat_locked = { repeating = true, locked = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), repeat_locked)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), repeat_locked)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), repeat_locked)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), repeat_locked)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), repeat_locked)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), repeat_locked)

local locked = { locked = true }
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), locked)
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), locked)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), locked)
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), locked)

for i = 1, 6 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor = "DP-1",
        layout = i == 2 and "master" or nil,
    })
end

for i = 11, 16 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1" })
end

hl.workspace_rule({ workspace = "special:players", on_created_empty = "spotify" })
hl.workspace_rule({ workspace = "special:ai", on_created_empty = "gtk-launch chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default" })
hl.workspace_rule({ workspace = "special:whatsapp", on_created_empty = "gtk-launch chrome-hnpfjngllnobngcgfapefoaidbinmjnm-Default" })
hl.workspace_rule({ workspace = "special:telegram", on_created_empty = "Telegram" })

hl.window_rule({
    match = { class = "^(google-chrome|chromium|Chromium)$", initial_title = "^(DevTools)" },
    float = true,
    maximize = true,
    monitor = "HDMI-A-1",
})

hl.window_rule({
    match = { class = "org.telegram.desktop" },
    workspace = "special:telegram",
    pseudo = true,
    move = "0% 0%",
    size = "40% 100%",
})

for _, class in ipairs({ "Spotify", "com.github.th_ch.youtube_music" }) do
    hl.window_rule({ match = { class = class }, workspace = "special:players", tile = true })
end

hl.window_rule({
    match = { class = "^chrome-.*", initial_title = "WhatsApp Web" },
    workspace = "special:whatsapp",
    pseudo = true,
})

hl.window_rule({
    match = { class = "^chrome-.*", initial_title = "^(ChatGPT)" },
    workspace = "special:ai",
    tile = true,
})

hl.window_rule({ match = { class = "Slack" }, workspace = "4" })
hl.window_rule({ match = { class = "Slack", title = "- (Slack|Huddle)" }, float = true, size = "60% 60%" })
hl.window_rule({ match = { title = "^Slack$" }, float = true, move = "0 100%-h-0" })

hl.window_rule({
    match = { class = "^(google-chrome|chromium)$", initial_title = "^(Meet - ).*" },
    border_size = 0,
    no_max_size = true,
    float = true,
    size = "35% 40%",
    move = "100%-w-20 20",
    pin = true,
})

hl.window_rule({ match = { class = "^Alacritty" }, opacity = "0.90 override 0.80 override" })

hl.window_rule({
    match = {
        title = "^(Open File|Open|Save|Save As|Export|Import|Choose File|Rename)",
        class = "^(.*)$",
    },
    float = true,
    center = true,
})

for _, class in ipairs({
    "^(xdg-desktop-portal-gtk)$",
    "^(Xdg-desktop-portal-gtk)$",
    "^(xdg-desktop-portal-hyprland)$",
    "^(Xdg-desktop-portal-hyprland)$",
}) do
    hl.window_rule({ match = { class = class }, float = true, center = true })
end
hl.window_rule({ match = { class = "^(Xdg-desktop-portal-gtk)$" }, border_size = 0 })

hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})
