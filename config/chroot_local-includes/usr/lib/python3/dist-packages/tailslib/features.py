from pathlib import Path


def kernel_flag_is_present(flag: str) -> bool:
    return flag in Path("/proc/cmdline").read_text().split()


def flatpak_is_enabled() -> bool:
    return kernel_flag_is_present("flatpak")
