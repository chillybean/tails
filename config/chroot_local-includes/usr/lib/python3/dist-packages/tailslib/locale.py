import os


def apply_selected_locale():
    with open("/etc/locale.conf") as f:
        for line in f:
            k, v = line.strip().split("=", 1)
            os.environ[k] = v
