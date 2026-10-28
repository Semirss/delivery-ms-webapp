"""Fail a mobile release build if its public endpoints cross environments."""

import argparse
from pathlib import Path
from urllib.parse import urlparse

PRODUCTION_SUPABASE_HOST = "smkfvvblyudecimcfman.supabase.co"
PRODUCTION_API_HOSTS = {"motobikedeliveryservice.com", "www.motobikedeliveryservice.com"}


def values(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, separator, value = line.partition("=")
        if separator:
            result[key.strip()] = value.strip().strip('"\'')
    return result


def host(value: str) -> str:
    parsed = urlparse(value)
    if parsed.scheme != "https" or not parsed.hostname:
        raise ValueError("Mobile release URLs must use HTTPS.")
    return parsed.hostname.lower()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("file", type=Path)
    parser.add_argument("--expected", choices=("production", "test"), required=True)
    args = parser.parse_args()
    config = values(args.file)

    if config.get("ENVIRONMENT") != args.expected:
        raise ValueError("ENVIRONMENT does not match this release build.")
    if any(key.startswith("MASTER_") for key in config):
        raise ValueError("Remove legacy MASTER_* backend switcher variables.")
    if any("SERVICE_ROLE" in key or "SECRET_KEY" in key for key in config):
        raise ValueError("Do not embed server-only credentials in a mobile app.")
    if len(config.get("SUPABASE_ANON_KEY", "")) <= 20:
        raise ValueError("Missing SUPABASE_ANON_KEY.")

    supabase_host = host(config.get("SUPABASE_URL", ""))
    api_host = host(config.get("API_BASE_URL", ""))
    if args.expected == "production":
        if supabase_host != PRODUCTION_SUPABASE_HOST or api_host not in PRODUCTION_API_HOSTS:
            raise ValueError("Production build has non-production endpoints.")
    elif supabase_host == PRODUCTION_SUPABASE_HOST or api_host in PRODUCTION_API_HOSTS:
        raise ValueError("Test build points at production.")

    print(f"Verified {args.expected} mobile build endpoints.")


if __name__ == "__main__":
    main()
