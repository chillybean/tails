"""
This module implements wiki/src/contribute/design/greeter_storage.mdwn
"""

from pathlib import Path
from subprocess import run


class CleartextStorage:
    def __init__(self):
        self.mountpoint = Path("/usr/lib/live/mount/medium/")
        self.basedir = self.mountpoint / "storage"

    def load_all(self):
        pass

    def load(self, key: str, text=True):
        mode = "rt" if text else "rb"
        with (self.basedir / key).open(mode) as buf:
            return buf.read()

    def save(self, key: str, value, text=True):
        run(["/usr/bin/mount", "-o", "remount,rw", str(self.mountpoint)], check=True)
        try:
            self.basedir.mkdir(exist_ok=True)
            mode = "w" if text else "wb"
            with (self.basedir / key).open(mode) as buf:
                buf.write(value)
        finally:
            run(
                ["/usr/bin/mount", "-o", "remount,ro", str(self.mountpoint)], check=True
            )
