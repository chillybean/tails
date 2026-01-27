import apt.cache

from tailslib.locale import user_language_and_region


def thunderbird_l10n_package() -> str | None:
    (language, region) = user_language_and_region()
    apt_cache = apt.cache.Cache()

    candidates = [
        f"thunderbird-l10n-{language}-{region}",
        f"thunderbird-l10n-{language}",
    ]

    for package in candidates:
        if package in apt_cache:
            return package

    return None
