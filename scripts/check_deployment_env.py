"""Read the public config endpoint without printing its anon key."""

import argparse
import json
from urllib.parse import urlparse
from urllib.request import urlopen

EXPECTED_SUPABASE_HOST = {
    "production": "smkfvvblyudecimcfman.supabase.co",
    "test": "mtbqqharhxijulpaqdrm.supabase.co",
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url", help="Vercel base URL")
    parser.add_argument("--expected", choices=EXPECTED_SUPABASE_HOST, required=True)
    args = parser.parse_args()

    base = urlparse(args.url)
    if base.scheme != "https" or not base.hostname:
        raise ValueError("Deployment URL must use HTTPS.")
    endpoint = f"https://{base.hostname}/api/public/backend-config"
    with urlopen(endpoint, timeout=15) as response:
        config = json.load(response)

    actual_host = urlparse(config.get("supabaseUrl", "")).hostname
    if config.get("source") != "env" or actual_host != EXPECTED_SUPABASE_HOST[args.expected]:
        raise ValueError(
            f"{args.expected} deployment is not isolated: "
            f"source={config.get('source')}, supabase_host={actual_host}"
        )
    print(f"Verified {args.expected} deployment: {base.hostname} -> {actual_host}")


if __name__ == "__main__":
    main()
