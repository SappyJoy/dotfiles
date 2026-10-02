#!/usr/bin/env python3
"""A SQLite database as text: each table with its row count, columns, and first rows.
Read-only (the file is opened with mode=ro). Usage: sqlite.py FILE"""

import sqlite3
import sys

ROWS = 5


def cell(v):
    if isinstance(v, bytes):
        return f"<{len(v)} bytes>"
    s = str(v).replace("\n", " ")
    return s if len(s) <= 40 else s[:39] + "…"


def grid(header, rows):
    rows = [list(map(cell, header))] + [list(map(cell, r)) for r in rows]
    widths = [max(len(r[i]) for r in rows) for i in range(len(header))]
    line = lambda r: "  ".join(c.ljust(w) for c, w in zip(r, widths)).rstrip()
    return [line(rows[0]), "  ".join("─" * w for w in widths)] + [line(r) for r in rows[1:]]


def main(path):
    db = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    tables = [r[0] for r in db.execute(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name")]
    print(f"{path.rsplit('/', 1)[-1]}   {len(tables)} tables")
    for t in tables:
        q = '"' + t.replace('"', '""') + '"'
        count = db.execute(f"SELECT count(*) FROM {q}").fetchone()[0]
        cols = db.execute(f"PRAGMA table_info({q})").fetchall()
        print(f"\n## {t}   {count} rows")
        print("   " + ", ".join(f"{c[1]} {c[2] or ''}".strip() for c in cols))
        cur = db.execute(f"SELECT * FROM {q} LIMIT {ROWS}")
        rows = cur.fetchall()
        if rows:
            print()
            print("\n".join("   " + l for l in grid([d[0] for d in cur.description], rows)))


if __name__ == "__main__":
    main(sys.argv[1])
