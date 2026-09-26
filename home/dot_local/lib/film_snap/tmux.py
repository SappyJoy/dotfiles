"""Snap the top-level pane columns of a tmux window to the monitor borders.

This only matters when the terminal spans a monitor border (FILM). The terminal's
pixel rectangle comes from i3 through WINDOWID: kitty sets it, and tmux copies it
into the session environment on attach. Pixel borders become cell columns through
the terminal's cell width. A cut is the separator column between two pane columns.
It moves with `resize-pane -R/-L` on a pane of the left column, which resizes only
the two neighbouring columns.
"""
from __future__ import annotations

import json
import re
import subprocess
from typing import List, Optional

from . import core, monitors
from .i3 import i3

MIN_WIDTH = 10  # cells


def tmux(*args: str) -> str:
    return subprocess.run(["tmux", *args], capture_output=True, text=True,
                          timeout=5).stdout


def parse_layout(layout: str) -> dict:
    """Parse #{window_layout} ("csum,WxH,X,Y{…}") into nested dicts.

    Each node has w, h, x, y and either `pane` (leaf) or `split` ("{" = side by
    side, "[" = stacked) with `children`.
    """
    text = layout.split(",", 1)[1]
    pos = 0

    def node() -> dict:
        nonlocal pos
        m = re.match(r"(\d+)x(\d+),(\d+),(\d+)", text[pos:])
        if m is None:
            raise ValueError(f"bad layout at {pos}: {layout}")
        pos += m.end()
        n = dict(zip("whxy", map(int, m.groups())))
        if pos < len(text) and text[pos] in "{[":
            n["split"] = text[pos]
            pos += 1
            n["children"] = [node()]
            while text[pos] == ",":
                pos += 1
                n["children"].append(node())
            pos += 1  # the closing bracket
        else:
            m = re.match(r",(\d+)", text[pos:])
            if m is None:
                raise ValueError(f"bad layout at {pos}: {layout}")
            pos += m.end()
            n["pane"] = int(m.group(1))
        return n

    return node()


def first_pane(node: dict) -> int:
    while "pane" not in node:
        node = node["children"][0]
    return node["pane"]


def plan(layout: str, width: int, content_x: int, content_w: int,
         borders: List[int]) -> List[List[str]]:
    """resize-pane commands for one window, or [] when nothing needs to move.

    width is the window width in cells, content_x/content_w the terminal's
    text area in root-window pixels, borders the monitor borders in pixels.
    """
    root = parse_layout(layout)
    cell = content_w // width if width else 0
    if root.get("split") != "{" or cell <= 0:
        return []
    cols = root["children"]
    cuts = [c["x"] + c["w"] for c in cols[:-1]]  # the separator columns
    cells = [(b - content_x) // cell for b in borders]
    goal = core.targets(cuts, [c for c in cells if 0 < c < width - 1], width, MIN_WIDTH)
    if goal is None:
        return []
    return [["resize-pane", "-t", f"%{first_pane(cols[i])}", "-R" if d > 0 else "-L", str(abs(d))]
            for i, d in core.moves(cuts, goal, width)]


def terminal(session: str) -> Optional[dict]:
    """The i3 rect of the terminal holding this session's client, or None."""
    env = tmux("show-environment", "-t", session, "WINDOWID").strip()
    if not env.startswith("WINDOWID="):
        return None
    window = int(env.split("=", 1)[1])
    stack = [json.loads(i3("-t", "get_tree"))]
    while stack:
        node = stack.pop()
        if node.get("window") == window:
            return node
        stack.extend(node.get("nodes", []) + node.get("floating_nodes", []))
    return None


def snap(target: str = "") -> None:
    """Snap one tmux window (default: the current one)."""
    borders = monitors.borders()
    if not borders:
        return
    fmt = "#{session_name}\t#{window_width}\t#{window_layout}"
    args = ["display-message", "-p"] + (["-t", target] if target else []) + [fmt]
    session, width, layout = tmux(*args).rstrip("\n").split("\t")
    node = terminal(session)
    if node is None:
        return
    x = node["rect"]["x"] + node["window_rect"]["x"]
    commands = plan(layout, int(width), x, node["window_rect"]["width"], borders)
    joined: List[str] = []
    for command in commands:  # one tmux call: cmd1 ; cmd2 ; …
        if joined:
            joined.append(";")
        joined.extend(command)
    if joined:
        tmux(*joined)
