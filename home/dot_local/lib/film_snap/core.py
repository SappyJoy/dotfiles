"""Pure math: where column edges should go so that they sit on monitor borders.

Positions run from 0 to `total`, in the caller's unit (i3: pixels, tmux: cells).
A *cut* is the edge between two neighbouring columns; a *border* is where one
physical monitor ends and the next begins.
"""
from __future__ import annotations

from itertools import combinations, combinations_with_replacement
from typing import List, Optional, Sequence, Tuple


def targets(cuts: Sequence[float], borders: Sequence[float], total: float,
            min_size: float) -> Optional[List[int]]:
    """Target positions for the sorted `cuts`, or None if nothing fits.

    - No more cuts than borders: every cut lands on a border, in order.
    - More cuts than borders: every border gets a cut, and the extra cuts split
      monitors evenly.
    Among the candidates that keep every column at least `min_size` wide, the one
    that moves the cuts least wins; on a tie the later (further right) one, so a
    new window opened on the right gets the smaller share. Without borders inside
    (0, total) the cuts stay where they are.
    """
    borders = sorted(b for b in borders if 0 < b < total)
    if not cuts or not borders:
        return [round(c) for c in cuts]
    best, best_cost = None, None
    for candidate in _candidates(len(cuts), borders, total):
        edges = [0, *candidate, total]
        if any(b - a < min_size for a, b in zip(edges, edges[1:])):
            continue
        cost = sum(abs(c - p) for c, p in zip(cuts, candidate))
        if best_cost is None or cost <= best_cost:
            best, best_cost = candidate, cost
    return None if best is None else [round(p) for p in best]


def _candidates(n: int, borders: List[float], total: float):
    if n <= len(borders):
        yield from (list(c) for c in combinations(borders, n))
        return
    # Every border is used; the extra cuts go into the monitors (segments).
    segments = list(zip([0, *borders], [*borders, total]))
    for picks in combinations_with_replacement(range(len(segments)), n - len(borders)):
        positions = list(borders)
        for s, (start, end) in enumerate(segments):
            k = picks.count(s)
            positions += [start + (end - start) * t / (k + 1) for t in range(1, k + 1)]
        yield sorted(positions)


def moves(cuts: Sequence[int], goal: Sequence[int], total: int,
          tolerance: int = 0) -> List[Tuple[int, int]]:
    """Order single-cut moves `(index, delta)` from `cuts` to `goal`.

    Moving one cut only resizes its two neighbouring columns (i3's directional
    resize, tmux's resize-pane), so a cut may move only while it stays strictly
    between its neighbours. Moves within `tolerance` are skipped.
    """
    current = list(cuts)
    todo = [i for i, (c, g) in enumerate(zip(cuts, goal)) if abs(g - c) > tolerance]
    out: List[Tuple[int, int]] = []
    while todo:
        for i in todo:
            left = current[i - 1] if i > 0 else 0
            right = current[i + 1] if i + 1 < len(current) else total
            if left < goal[i] < right:
                out.append((i, goal[i] - current[i]))
                current[i] = goal[i]
                todo.remove(i)
                break
        else:
            break  # blocked (cannot happen for sorted goals); apply what we have
    return out
