"""film-snap: keep i3 and tmux column edges on the physical monitor borders.

  film-snap i3                 snap the visible i3 workspaces once
  film-snap i3-watch           snap now and after every window change (i3 exec_always)
  film-snap tmux [WINDOW]      snap a tmux window's pane columns (tmux hooks)
  film-snap plan TOTAL BORDERS CUTS [MIN]
                               print the snapped cuts, e.g. `plan 3600 1200,2400 1800`
"""
from __future__ import annotations

import subprocess
import sys

from . import core, i3, tmux


def numbers(text: str) -> list:
    return [float(v) for v in text.split(",") if v]


def main(argv: list) -> int:
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__.strip())
        return 0 if argv else 2
    command, args = argv[0], argv[1:]
    if command == "plan":
        total, borders, cuts = int(args[0]), args[1], args[2]
        goal = core.targets(numbers(cuts), numbers(borders), total,
                            float(args[3]) if len(args) > 3 else 1)
        print(",".join(map(str, goal)) if goal is not None else "none")
        return 0
    try:
        if command == "i3":
            i3.snap()
        elif command == "i3-watch":
            i3.watch()
        elif command == "tmux":
            tmux.snap(args[0] if args else "")
        else:
            print(__doc__.strip(), file=sys.stderr)
            return 2
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        # No X, no i3 or no tmux server (e.g. over SSH): nothing to snap.
        print(f"film-snap {command}: {error}", file=sys.stderr)
        return 1
    return 0


sys.exit(main(sys.argv[1:]))
