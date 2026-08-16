# iOS App Store Build from Windows

You cannot create an App Store `.ipa` directly on Windows. Apple requires the iOS build and signing step to run with Xcode on macOS. This repo now includes a GitHub Actions workflow that uses a macOS runner to build and optionally upload both Flutter apps:

- Client: `client_app/client_app`, bundle ID `com.motobikedeliveryservice.client`
- Driver: `driver_app/driver_app`, bundle ID `com.motobikedeliveryservice.driver`

## Apple setup

In App Store Connect, create two app records before running the workflow:

- MotoBike, bundle ID `com.motobikedeliveryservice.client`
- MotoBike Driver, bundle ID `com.motobikedeliveryservice.driver`

If the bundle IDs do not exist yet, create them in Apple Developer Certificates, Identifiers & Profiles first. Use the same Apple team already configured in Xcode project files: `UZUY982QUZ`.

## GitHub secrets

The setup script adds these repository secrets to GitHub under `Settings > Secrets and variables > Actions`:

- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY_IDENTIFIER`
- `APP_STORE_CONNECT_PRIVATE_KEY`
- `CERTIFICATE_PRIVATE_KEY`
- `CLIENT_DOTENV_BASE64`
- `DRIVER_DOTENV_BASE64`

The App Store Connect key must be a Team API key with access to create signing files and upload builds. Keep the `.p8` private key out of git.

Run the setup script after you have the Issuer ID:

```powershell
.\scripts\setup_ios_github_secrets.ps1 -IssuerId "PASTE_ISSUER_ID_HERE"
```

On this Windows machine, use this first-time setup command so the script can install GitHub CLI and start GitHub login if needed:

```powershell
.\scripts\setup_ios_github_secrets.ps1 -IssuerId "PASTE_ISSUER_ID_HERE" -InstallGitHubCli -LoginGitHub
```

If the GitHub repository cannot be detected automatically, pass it explicitly:

```powershell
.\scripts\setup_ios_github_secrets.ps1 -IssuerId "PASTE_ISSUER_ID_HERE" -Repo "owner/repository"
```

The script checks for missing files and existing duplicate secrets. It stops before overwriting any existing secret unless you pass `-Force`.

`CERTIFICATE_PRIVATE_KEY` is a reusable private key that the signing tool uses to create or reuse an Apple Distribution certificate. If you do not already have an exported iOS Distribution certificate private key, create one locally and store the whole PEM text as the secret:

```powershell
openssl genrsa -out ios_distribution_private_key.pem 2048
Get-Content -Raw ios_distribution_private_key.pem
```

Do not commit `ios_distribution_private_key.pem`.

The script creates the base64 `.env` secrets for you. The commands below are only a manual fallback:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("client_app\client_app\.env"))
[Convert]::ToBase64String([IO.File]::ReadAllBytes("driver_app\driver_app\.env"))
```

If setting secrets manually, paste the first output into `CLIENT_DOTENV_BASE64` and the second into `DRIVER_DOTENV_BASE64`.

## Run the build

Push this repo to GitHub, open the repository, then go to:

`Actions > iOS App Store Build > Run workflow`

Choose:

- `both` to build client and driver together
- `client` for only the client app
- `driver` for only the driver app

Leave `upload_to_app_store_connect` enabled to upload the signed IPA to App Store Connect. After upload, Apple processes the build under each app's `TestFlight` tab. Submitting to App Review still happens manually in App Store Connect because screenshots, privacy answers, age rating, pricing, and release notes must be completed there.

## Free build note

GitHub Actions macOS runners are free for public repositories. Private repositories use the free monthly GitHub Actions quota first and may cost money only after that quota is used.
