# ranger commands of my own; ranger's built-in ones stay in ranger. Keys: rc.conf.
import os
import shutil
import subprocess

from ranger.api.commands import Command


class zi(Command):
    """:zi

    Pick a directory from zoxide's history in fzf and go there (zoxide's `cdi`).
    """

    def execute(self):
        proc = self.fm.execute_command(
            "zoxide query -i", universal_newlines=True, stdout=subprocess.PIPE
        )
        out, _ = proc.communicate()
        if proc.returncode == 0 and out.strip():
            self.fm.cd(out.rstrip("\n"))


class fzf_select(Command):
    """:fzf_select

    Pick a file or directory below the current one in fzf: go to a directory, or
    select a file in its directory. Hidden files included, .git left out.
    """

    def execute(self):
        if shutil.which("fd"):
            find = "fd --hidden --exclude .git"
        else:
            find = "find . -mindepth 1 -name .git -prune -o -print | cut -c3-"
        proc = self.fm.execute_command(
            find + " | fzf +m", universal_newlines=True, stdout=subprocess.PIPE
        )
        out, _ = proc.communicate()
        if proc.returncode == 0 and out.strip():
            path = os.path.abspath(out.rstrip("\n"))
            if os.path.isdir(path):
                self.fm.cd(path)
            else:
                self.fm.select_file(path)
