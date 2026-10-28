# Test and production separation

## Current state

- `master` points to the stable `d` commit. `test` starts from that commit and now includes the wallet work from `wallet-swipe-integration`.
- The existing `SUPABASE_URL` in the local web, driver, and client environment files is the project identified by the owner as the current real-data project. Treat it as **production**.
- `MASTER_SUPABASE_URL` points to a separate backend-switcher project. It is **not** a test database. Older installed apps can still read its public backend view, so keep that view pointed at production until those apps are replaced.
- Vercel can keep serving an older deployment after Git `master` is moved. Check the production deployment SHA, not just the branch label.

## Target setup

| Resource | Production | Test |
| --- | --- | --- |
| Git branch | `master` | `test` |
| Supabase | Existing real-data project (`smkfvvblyudecimcfman`) | Separate project (`mtbqqharhxijulpaqdrm`) with synthetic users and data |
| Vercel | Existing project, Production Branch `master`, real domain | `moto-bike-test.vercel.app`, with `webapp` root and Production Branch `test` |
| Web environment | `NEXT_PUBLIC_APP_ENV=production`, production Supabase URL/anon key and service role key | `NEXT_PUBLIC_APP_ENV=test`, test Supabase URL/anon key and service role key |
| Android driver/client | `production` flavor, existing application IDs | `staging` flavor, `.test` application IDs and distinct OAuth URL schemes |
| iOS driver/client | Existing bundle IDs and App Store workflow on `master` | Separate bundle IDs, schemes, URL schemes and signing profiles still to be configured on a Mac |

The web server and browser must use the **same** Supabase URL. Only the web server gets `SUPABASE_SERVICE_ROLE_KEY`; never place it in Flutter, `NEXT_PUBLIC_*`, or Git. Set variables independently on each Vercel project. Do not copy the production Vercel variables into the test project.

## Setup order

1. Back up the current production Supabase database and record its applied schema, Auth settings, Storage policies and buckets, Edge Functions, webhooks, and secrets. Do not run `rollback_to_d_test_driver_access.sql` or the shared `121212` password reset on production. Those scripts are for the previous test-account rollback and are not safe production migrations.
2. Use the separate test Supabase project `mtbqqharhxijulpaqdrm`. Recreate the required schema through reviewed versioned migrations, then seed synthetic test accounts. This repo currently has manual `schema*.sql` files and no `supabase/migrations` baseline, so first reconcile the live production schema with those files; do not point `supabase db push` at either hosted project yet. Use test SMS, email, payment, maps, push, and monitoring credentials where available. Do not clone customer passwords or payment data into test.
3. In the Vercel project serving `moto-bike-test.vercel.app`, set root directory `webapp` and Production Branch `test`. Add only the test project's Supabase URL, anon key, and service role key. Add `NEXT_PUBLIC_APP_ENV=test`. The public backend-config endpoint was verified reporting `source=env` and the test Supabase host on 28 October 2026. Verify again after each deployment.
4. In the existing Vercel project, keep Production Branch `master` and the real domain. Set `NEXT_PUBLIC_APP_ENV=production`, and verify `NEXT_PUBLIC_SUPABASE_URL` and `SUPABASE_URL` are the real-data project. Remove `MASTER_SUPABASE_*`, `MASTER_BACKEND_CONFIG_*`, and `ADMIN_BACKEND_PASS` after the switcher removal reaches production. Redeploy `master` and verify the deployment SHA and domain.
5. Protect `master` in GitHub: require a reviewed pull request and the `require-tested-branch` check from `.github/workflows/production_promotion.yml`. The workflow rejects production PRs from other branches, but it only blocks merges once the check is required in GitHub's branch rules. Merge tested commits from `test` into `master`; do not force-push routine releases. Apply each migration to test first, verify behavior, back up production, then apply that same reviewed migration to production before deploying code that depends on it. A Git merge does not move database rows or Vercel secrets.
6. Build test Android apps with `--flavor staging --dart-define-from-file=<test-env-file>` and production apps with `--flavor production --dart-define-from-file=<production-env-file>`. The file must provide `ENVIRONMENT=test` or `production`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `API_BASE_URL` for the matching Vercel domain. The apps reject a flavor/environment mismatch and reject test endpoints that point at the known production Supabase or API host.
7. Register test OAuth redirects in **test Supabase Auth**: `motobike-client-test://login-callback/` and `motobike-driver-test://login-callback/`. Keep the original redirects only in production. Configure iOS test bundle IDs, schemes and signing before distributing test iOS apps. The current iOS production workflows are restricted to `master`; update their `CLIENT_DOTENV_BASE64` and `DRIVER_DOTENV_BASE64` secrets to remove legacy `MASTER_*` entries and set `ENVIRONMENT=production` before the isolation changes are promoted.
8. Test signup, driver login, offers, dispatch, payments (sandbox), and account deletion end to end against the test domain and test Supabase. Inspect both projects' logs to confirm no test request hit production. Only then promote the tested code to `master`.

After each Vercel deployment, run `python scripts/check_deployment_env.py https://moto-bike-test.vercel.app --expected test` (or the real domain with `--expected production`). It checks the public endpoint without printing the anon key. Do not start test logins until it passes.

## Important existing-app limit

Already installed mobile versions contain the old `MASTER_SUPABASE_URL` and may follow its public view. Git and new builds cannot change those installations. Keep that view fixed on the real-data project, revoke access to the old dashboard backend-switch route by deploying the web change, and publish new mobile versions before treating the environments as fully isolated.
