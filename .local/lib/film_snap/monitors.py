"""The x positions where one physical monitor ends and the next begins.

Reads the `monitors` command (~/.local/bin/monitors), the single place that parses
xrandr for physical monitors.
"""
from __future__ import annotations

import os
import subprocess
from typing import List

MONITORS = os.path.expanduser("~/.local/bin/monitors")


def borders() -> List[int]:
    """Inner vertical monitor edges in root-window pixels, sorted; [] on failure."""
    try:
        out = subprocess.run([MONITORS], capture_output=True, text=True,
                             timeout=5).stdout
    except (OSError, subprocess.SubprocessError):
        return []
    return borders_from(out)


def borders_from(monitors_output: str) -> List[int]:
    """Parse `monitors` lines ("name x y w h mm_w mm_h") into inner edges."""
    edges = set()
    for line in monitors_output.splitlines():
        fields = line.split()
        if len(fields) >= 5:
            x, w = int(fields[1]), int(fields[3])
            edges.update((x, x + w))
    if len(edges) < 3:
        return []
    return sorted(edges)[1:-1]
