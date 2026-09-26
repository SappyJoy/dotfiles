"""Snap the columns of the visible i3 workspaces to the monitor borders.

A workspace's columns are the children of its first horizontal split with two or
more children, reached through single-child containers. A cut is the middle of
the gap between two columns. Each cut moves with `[con_id=…] resize grow|shrink
right N px`, which only resizes the two neighbouring columns.
"""
from __future__ import annotations

import fcntl
import json
import os
import subprocess
from typing import List, Optional

from . import core, monitors

MIN_WIDTH = 150  # px; no column is snapped narrower than this
TOLERANCE = 2  # px; closer than this counts as snapped
TICK = "film-snap"  # `i3-msg -t send_tick film-snap` snaps on demand


def i3(*args: str) -> str:
    return subprocess.run(["i3-msg", *args], capture_output=True, text=True,
                          timeout=5).stdout


def columns(workspace: dict) -> Optional[dict]:
    """The horizontal split holding the workspace's columns, or None."""
    node = workspace
    while len(node.get("nodes", [])) == 1:
        node = node["nodes"][0]
    if node.get("layout") == "splith" and len(node.get("nodes", [])) >= 2:
        return node
    return None


def plan(workspace: dict, borders: List[int]) -> str:
    """i3 commands that snap one workspace, or "" when nothing needs to move."""
    split = columns(workspace)
    if split is None:
        return ""
    x0, total = split["rect"]["x"], split["rect"]["width"]
    cols = [c["rect"] for c in split["nodes"]]
    cuts = [(a["x"] + a["width"] + b["x"]) / 2 - x0 for a, b in zip(cols, cols[1:])]
    goal = core.targets(cuts, [b - x0 for b in borders], total, MIN_WIDTH)
    if goal is None:
        return ""
    current = [round(c) for c in cuts]
    commands = []
    for i, delta in core.moves(current, goal, total, TOLERANCE):
        verb = "grow" if delta > 0 else "shrink"
        commands.append(f"[con_id={split['nodes'][i]['id']}] resize {verb} right {abs(delta)} px")
    return "; ".join(commands)


def visible_workspaces(tree: dict, names: List[str]) -> List[dict]:
    found = []
    stack = [tree]
    while stack:
        node = stack.pop()
        if node.get("type") == "workspace" and node.get("name") in names:
            found.append(node)
        else:
            stack.extend(node.get("nodes", []))
    return found


def snap() -> None:
    """Snap every visible workspace; a few passes absorb i3's px/percent rounding."""
    borders = monitors.borders()
    if not borders:
        return
    for _ in range(3):
        names = [w["name"] for w in json.loads(i3("-t", "get_workspaces")) if w["visible"]]
        tree = json.loads(i3("-t", "get_tree"))
        commands = [c for c in (plan(w, borders) for w in visible_workspaces(tree, names)) if c]
        if not commands:
            return
        i3("; ".join(commands))


def safe_snap() -> None:
    """snap() for the watcher: an i3 restart or odd reply must not kill it."""
    try:
        snap()
    except (OSError, ValueError, KeyError, subprocess.SubprocessError):
        pass


def relevant(event: dict) -> bool:
    """Window opened/closed/moved/(un)floated, resize mode left, or our tick."""
    if "container" in event:
        return event.get("change") in ("new", "close", "move", "floating")
    if "pango_markup" in event:  # mode event
        return event.get("change") == "default"
    return event.get("payload") == TICK


def watch() -> None:
    """Snap now and after every relevant i3 event, as the only watcher.

    An i3 restart closes the subscription, so the old watcher exits and the one
    started by exec_always takes over (it waits for the lock meanwhile).
    """
    runtime = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    with open(os.path.join(runtime, "film-snap-i3.lock"), "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        safe_snap()
        sub = subprocess.Popen(["i3-msg", "-t", "subscribe", "-m",
                                '["window", "mode", "tick"]'],
                               stdout=subprocess.PIPE, text=True)
        assert sub.stdout is not None
        for line in sub.stdout:
            try:
                event = json.loads(line)
            except ValueError:
                continue
            if isinstance(event, dict) and relevant(event):
                safe_snap()
