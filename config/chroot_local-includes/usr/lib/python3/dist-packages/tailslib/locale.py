import ast
import contextlib
import os
import re
import sys
import typing


# According to locale.conf(5) it uses the same format as described in
# os-release(5), so we base the code below on its "Example 5. Reading
# os-release in python(1) (any version)" but fix several issues with
# it (see discussion on tails!2459).
#
# This function is only thread-safe when the GIL is enabled.
def read_locale_conf() -> typing.Generator[tuple[str, str]]:
    filename = "/etc/locale.conf"
    with open(filename) as f:
        for line_number, line in enumerate(f, start=1):
            line = line.rstrip()  # noqa: PLW2901
            if not line or line.startswith("#"):
                continue
            name = None
            val = None
            m = re.match(r"([a-zA-Z_][a-zA-Z_0-9]*)=(.*)", line)
            if m:
                name, val = m.groups()
                if val and val[0] in ['"', "'"]:
                    try:
                        val = ast.literal_eval(val)
                    except ValueError:
                        val = None
            if name is not None and val is not None:
                yield name, val
            else:
                print(f"{filename}:{line_number}: bad line {line!r}", file=sys.stderr)


# Sets environment variables according to /etc/locale.conf
def apply_selected_locale():
    with contextlib.suppress(FileNotFoundError):
        os.environ.update(read_locale_conf())
