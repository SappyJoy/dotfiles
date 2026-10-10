"""The folder Quartz serves for a repo's notes: the notes, and the repo's docs next to them.

Usage: python3 notes-content.py REPO CONTENT

Makes CONTENT hold a link to each entry of REPO/notes/, and every tracked Markdown file
and image of REPO at its path from the repo's root, so a note links a doc as
[[docs/guide]]. Left out: .agent/, Claude's instruction files, hidden folders, and a
doc whose path a note already takes. Images are links; Markdown docs are copies whose
relative links are rewritten to paths from the root, because Quartz resolves a link with
a folder from the root, not from the page; and their frontmatter is shown as a code
block, since one that strict YAML refuses would stop Quartz's build. Run again, it brings CONTENT up to date and
touches only what changed, so a running Quartz rebuilds no more than it must.
"""

import os
import posixpath
import re
import subprocess
import sys
from pathlib import Path

IMAGES = {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp"}
NOT_DOCS = (".agent/", "notes/")
NOT_DOC_NAMES = {"CLAUDE.md", "CLAUDE.local.md", "AGENTS.md"}
# [text](path) and ![alt](path), the part up to the path, and the path
LINK = re.compile(r"(!?\[[^\]]*\]\()([^)\s]+)")
FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
FRONTMATTER = re.compile(r"\A---\n(.*?\n)---\n", re.S)


def from_root(doc: str, target: str) -> str:
    """A relative link in doc as a path from the repo's root; others as they are."""
    if re.match(r"[a-zA-Z][a-zA-Z0-9+.-]*:", target) or target.startswith(("#", "/", "<")):
        return target
    path, hash_, anchor = target.partition("#")
    resolved = posixpath.normpath(posixpath.join(posixpath.dirname(doc), path))
    return target if resolved.startswith("..") else resolved + hash_ + anchor


def rewrite(doc: str, text: str) -> str:
    text = FRONTMATTER.sub(lambda m: f"```yaml\n{m.group(1)}```\n", text, count=1)
    out, fence = [], ""
    for line in text.splitlines(keepends=True):
        match = FENCE.match(line)
        if match and (not fence or match.group(1)[0] == fence[0]):
            fence = "" if fence else match.group(1)
        elif not fence:
            line = LINK.sub(lambda m: m.group(1) + from_root(doc, m.group(2)), line)
        out.append(line)
    return "".join(out)


def wanted(repo: Path) -> dict[str, tuple[str, str | Path]]:
    """Each path in CONTENT: ("link", its target) or ("text", a doc's rewritten text)."""
    notes = repo / "notes"
    want: dict[str, tuple[str, str | Path]] = {
        entry.name: ("link", entry) for entry in notes.iterdir() if not entry.name.startswith(".")}
    files = subprocess.run(["git", "-C", repo, "ls-files", "-z"], capture_output=True,
                           text=True, check=True).stdout.split("\0")
    for path in filter(None, files):
        parts, suffix = path.split("/"), Path(path).suffix.lower()
        if (path.startswith(NOT_DOCS) or parts[-1] in NOT_DOC_NAMES or parts[0] in want
                or any(p.startswith(".") for p in parts) or not (repo / path).is_file()):
            continue
        if suffix == ".md":
            want[path] = ("text", rewrite(path, (repo / path).read_text(encoding="utf-8")))
        elif suffix in IMAGES:
            want[path] = ("link", repo / path)
    return want


def sync(repo: Path, content: Path) -> None:
    want = wanted(repo)
    content.mkdir(parents=True, exist_ok=True)
    # what's there and no longer wanted, or wanted as something else, goes
    for dirpath, dirnames, filenames in os.walk(content, topdown=False):
        for name in filenames + dirnames:
            path = Path(dirpath, name)
            rel = path.relative_to(content).as_posix()
            kind = want.get(rel, ("", ""))[0]
            if path.is_symlink() or path.is_file():
                if kind != ("link" if path.is_symlink() else "text"):
                    path.unlink()
            elif not any(w.startswith(rel + "/") for w in want):
                path.rmdir()
    for rel, (kind, value) in want.items():
        path = content / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        if kind == "link" and not (path.is_symlink() and os.readlink(path) == str(value)):
            path.unlink(missing_ok=True)
            path.symlink_to(value)
        elif kind == "text" and not (path.is_file() and path.read_text(encoding="utf-8") == value):
            path.write_text(str(value), encoding="utf-8")


if __name__ == "__main__":
    sync(Path(sys.argv[1]).resolve(), Path(sys.argv[2]))
