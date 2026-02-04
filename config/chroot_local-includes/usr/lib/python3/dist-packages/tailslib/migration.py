import shutil
from pathlib import Path


NOSYMFOLLOW_MOUNTPOINT = Path("/run/nosymfollow")
MIGRATIONS_DIR = (
    NOSYMFOLLOW_MOUNTPOINT / "live/persistence/TailsData_unlocked/.tails/migrations"
)


class Migration:
    def __init__(self, Id: str):
        self.state_dir = MIGRATIONS_DIR / Id
        self.success_file = self.state_dir / "success"
        self.failure_file = self.state_dir / "failure"

    @property
    def succeeded(self):
        return self.success_file.exists()

    @succeeded.setter
    def succeeded(self, result: bool) -> None:
        self.state_dir.mkdir(mode=0o750, exist_ok=True)
        shutil.chown(self.state_dir, group="amnesia")
        if result:
            self.success_file.touch()
        else:
            self.failure_file.touch()


if __name__ == "__main__":
    import sys

    migration = Migration(sys.argv[1])
    if migration.succeeded:
        sys.exit(0)
    else:
        sys.exit(1)
