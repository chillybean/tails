from pathlib import Path


NOSYMFOLLOW_MOUNTPOINT = Path("/run/nosymfollow")
MIGRATIONS_DIR = (
    NOSYMFOLLOW_MOUNTPOINT / "live/persistence/TailsData_unlocked/.tails/migrations"
)


class Migration:
    def __init__(self, Id: str):
        state_dir = MIGRATIONS_DIR / Id
        state_dir.mkdir(mode=0o700, exist_ok=True)
        self.success_file = state_dir / "success"
        self.failure_file = state_dir / "failure"

    @property
    def succeeded(self):
        return self.success_file.exists()

    @succeeded.setter
    def succeeded(self, result: bool) -> None:
        if result:
            self.success_file.touch()
        else:
            self.failure_file.touch()
