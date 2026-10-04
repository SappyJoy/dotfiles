# qtile: a tiling WM configured in Python. Windows are arranged by a layout per
# group (Columns, MonadTall, Max; Super+Tab cycles), the bar is part of qtile, and
# so are the launcher (a prompt in the bar) and the notifications (a bar widget).
# Based on qtile's default config (libqtile/resources/default_config.py), with the
# WM tour's shared keys on arrows, ten groups and FILM. Super+Shift+r reloads this
# file; `qtile check -c config.py` checks it.

import os
import subprocess

from libqtile import bar, hook, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy

mod = "mod4"
terminal = "kitty"

# FILM: one screen over the whole desk instead of one per monitor (Super+Shift+f
# switches and restarts qtile; the choice is kept for the next login)
FILM_STATE = os.path.join(
    os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")), "wm-tour", "film"
)


def film_saved():
    try:
        with open(FILM_STATE) as f:
            return "off" if f.readline().strip() == "off" else "on"
    except OSError:
        return "on"


@lazy.function
def film_toggle(qtile):
    mode = "off" if film_saved() == "on" else "on"
    os.makedirs(os.path.dirname(FILM_STATE), exist_ok=True)
    with open(FILM_STATE, "w") as f:
        f.write(mode + "\n")
    qtile.restart()


def root_size():
    """The X screen's size, e.g. (3600, 1920): all monitors together."""
    out = subprocess.run(["xdpyinfo"], capture_output=True, text=True).stdout
    for line in out.splitlines():
        if "dimensions:" in line:
            w, h = line.split()[1].split("x")
            return int(w), int(h)
    return None


keys = [
    # The tour's shared keys
    Key([mod], "t", lazy.spawn(terminal), desc="Terminal"),
    Key([mod], "d", lazy.spawncmd(), desc="Run a command (prompt in the bar)"),
    Key([mod], "Left", lazy.layout.left(), desc="Focus left"),
    Key([mod], "Right", lazy.layout.right(), desc="Focus right"),
    Key([mod], "Down", lazy.layout.down(), desc="Focus down"),
    Key([mod], "Up", lazy.layout.up(), desc="Focus up"),
    Key([mod, "shift"], "Left", lazy.layout.shuffle_left(), desc="Move window left"),
    Key([mod, "shift"], "Right", lazy.layout.shuffle_right(), desc="Move window right"),
    Key([mod, "shift"], "Down", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "Up", lazy.layout.shuffle_up(), desc="Move window up"),
    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="Fullscreen"),
    Key([mod, "shift"], "q", lazy.window.kill(), desc="Close the window"),
    Key([mod, "shift"], "f", film_toggle, desc="FILM or three monitors"),
    Key([mod, "shift"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "shift"], "u", lazy.shutdown(), desc="Log out"),
    # qtile's own
    Key([mod, "control"], "Left", lazy.layout.grow_left(), desc="Grow left"),
    Key([mod, "control"], "Right", lazy.layout.grow_right(), desc="Grow right"),
    Key([mod, "control"], "Down", lazy.layout.grow_down(), desc="Grow down"),
    Key([mod, "control"], "Up", lazy.layout.grow_up(), desc="Grow up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset window sizes"),
    Key([mod], "space", lazy.layout.next(), desc="Focus the next window"),
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(), desc="Split or stack a column"),
    Key([mod], "Tab", lazy.next_layout(), desc="Next layout"),
    Key([mod, "shift"], "space", lazy.window.toggle_floating(), desc="Floating"),
    Key([mod], "comma", lazy.prev_screen(), desc="Previous monitor"),
    Key([mod], "period", lazy.next_screen(), desc="Next monitor"),
    Key([], "XF86AudioRaiseVolume", lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%")),
    Key([], "XF86AudioLowerVolume", lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%")),
    Key([], "XF86AudioMute", lazy.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")),
]

# Groups 1-10 (Super+0 is 10); Super+Shift+N sends the window there
groups = [Group(str(i)) for i in range(1, 11)]
for g in groups:
    key = "0" if g.name == "10" else g.name
    keys += [
        Key([mod], key, lazy.group[g.name].toscreen(), desc=f"Group {g.name}"),
        Key([mod, "shift"], key, lazy.window.togroup(g.name), desc=f"Send to group {g.name}"),
    ]

layouts = [
    layout.Columns(border_focus_stack=["#d75f5f", "#8f3d3d"], border_width=4),
    layout.MonadTall(border_width=4),
    layout.Max(),
]

widget_defaults = dict(font="sans", fontsize=12, padding=3)
extension_defaults = widget_defaults.copy()


def make_bar():
    return bar.Bar(
        [
            widget.CurrentLayout(),
            widget.GroupBox(),
            widget.Prompt(),
            widget.WindowName(),
            widget.Chord(name_transform=lambda name: name.upper()),
            widget.Notify(default_timeout=5),
            widget.Systray(),
            widget.Clock(format="%Y-%m-%d %a %H:%M"),
        ],
        24,
    )


size = root_size() if film_saved() == "on" else None
if size:
    fake_screens = [Screen(bottom=make_bar(), x=0, y=0, width=size[0], height=size[1])]
else:
    fake_screens = None
# FILM off: one screen per monitor, each with its own bar
screens = [Screen(bottom=make_bar()) for _ in range(3)]

mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(title="pinentry"),
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True
wmname = "LG3D"  # some Java apps need a name they know


@hook.subscribe.startup_once
def startup_once():
    subprocess.Popen(["xset", "r", "rate", "200", "30"])
