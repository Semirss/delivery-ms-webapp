# Driver offers, tracking and owner commission

Implemented locally for the Flutter driver app and the Next.js admin/API. Production migration, deployment and real payments have not been performed.

## Release setup

1. Back up the active Supabase database. Apply `supabase/schema_v15_driver_operations.sql` after v14, then `supabase/schema_v16_driver_topup_proofs.sql`, then `supabase/schema_v17_browser_gps_accuracy.sql`. Each database selected through the admin backend switcher needs all three migrations. V16 uses Supabase Storage and the app notifications table from v4. V17 records explicit Offline pauses and raises the server dispatch accuracy limit to 200 m.
2. Set a random server-only `DRIVER_SESSION_SECRET` or `JWT_SECRET` of at least 32 characters in Vercel. Admin login uses `JWT_SECRET` when present, otherwise the driver secret. Keep service-role keys on the server. Fallback admin/default-secret logins are disabled. Replace the seeded admin password before using finance.
3. Deploy the matching web API/admin and release the Flutter app together. The driver's existing `API_BASE_URL` must point to that API. Existing drivers must sign out and sign in again: old locally invented tokens cannot access operations.

If the driver app receives a successful response without a signed `access_token`, it shows a plain temporary-unavailability message. For diagnosis, confirm `API_BASE_URL` points at the matching deployment, apply migration v15, configure the session secret, and deploy the web API before retrying. Do not restore the old locally generated driver token.

Driver-facing sign-in errors must not mention secrets, JWTs, migrations, Supabase, or deployment steps. The API logs the missing signing-key configuration for operators and returns a plain temporary-unavailability message to drivers. If that message appears after release, check the server logs and set `DRIVER_SESSION_SECRET` or `JWT_SECRET` in the deployed web app environment.
4. In **Admin → Wallet & Commission**, review the provisional percentage, price pending deliveries and choose who collects the delivery fee. Driver-collected cash is the default. Price a delivery before sending its offer.
5. Reconcile an actual credit top-up before a driver accepts a cash job. For business-collected jobs, reconcile receipt of the fee before completion.

The migration hashes existing passwords into a restricted credentials table and removes passwords from publicly queried driver records. It does not rewrite active delivery assignments or retroactively charge completed trips. Review old active jobs individually in the finance panel: return a legacy unaccepted offer for a fresh quote, or confirm a specific already-picked-up cash job can finish with its original earnings and zero retroactive commission. Legacy business-collected jobs require support review.

## Offers and settings

`Pending → Assigned (offer) → Accepted → Picked Up → Delivered`

An offer expires after two minutes. The driver must slide fully to accept before confirming pickup. Server transactions reject expired/reassigned offers, skipped steps and duplicate settlements. Accepted jobs survive the offer timeout. Admin reads and driver operations reads clean up expired offers; acceptance always checks database expiry even without an open admin dashboard.

Offers show pickup/drop-off, package/customer details, gross fee, owner percentage/fee, driver net earnings and distances. Distances are explicitly **straight-line estimates computed on-device**. No new external road-distance request was added. Existing navigation routing remains in place. A 1–50 km working radius warns about out-of-area pickups, measured from current GPS; dispatch can deliberately offer those jobs. Missing coordinates or stale GPS show unavailable distance.

Radius and notification preferences are saved per driver on the server. Theme retains the existing light/dark/system preference. Notifications require device permission. Existing realtime/local alerts remain in use; this change does not add FCM/APNs delivery for a force-closed app.

## Location

After a successful driver sign-in, Home marks the driver online automatically. Older Offline records left by GPS failures also come online when Home opens. A manual Go Offline action stores an explicit pause that survives refresh; a new sign-in starts online again. Drivers can pause or resume availability from the Home status pill or the Settings switch. Online availability does not by itself make the driver eligible for dispatch: a fresh, accurate GPS fix is still required.

In a browser preview, the app skips `getLastKnownPosition`, which the web geolocator does not support. The driver can explore the app while online even when the browser provides no accurate fix. Chrome location readings up to 200 m are accepted for dispatch, including the browser's usual 150 m simulated accuracy. Grant location access and tap Check location in Home. Use a physical device to test real GPS behavior.

Navigation-accuracy updates include the sensor timestamp, reported accuracy, heading, speed and server receipt time. Cached fixes are never re-labelled as newly observed. Invalid fixes and fixes older than 90 seconds are rejected. The phone app requires accuracy within 100 m; Chrome and the server accept up to 200 m. Conditional writes prevent delayed fixes from replacing newer ones. Deploy `schema_v17_browser_gps_accuracy.sql` after v16 so offer assignment and acceptance use the same 200 m limit.

Android uses a location foreground service with a persistent online notification. iOS declares background location and shows its background indicator. Going offline/signing out stops tracking. The app refreshes on resume and periodically while online. Operating-system restrictions and force-stopping can interrupt tracking, so admin shows stale/unknown status rather than promising perfect, uninterrupted GPS.

Both admin maps show fix time and accuracy circles. The tracking modal uses current driver state rather than the snapshot taken when opened. Dispatch requires an approved, active, online driver with fresh GPS.

Before release, test physical Android/iOS devices: denied precise location, GPS disabled, screen locked, background/resume, stationary/moving drivers, network loss/recovery and going offline. Compare markers with the device position and confirm timestamps become stale when updates stop.

## Money model

The initial **12% is provisional**, based on older reporting, not a verified current RIDE tariff. Admin can change it. Offers freeze the quoted rate. Commission applies to the delivery fee, not the value of food or goods.

At a 200 ETB fee and 12%, owner commission is 24 ETB and driver net is 176 ETB:

| Collection | Acceptance | Completion |
| --- | --- | --- |
| Driver collects cash | Reserve 24 ETB of prepaid commission credit | Driver keeps cash; deduct 24 ETB credit; no withdrawable earnings are created |
| Business collects payment | No cash-commission reservation | Require reconciled payment; credit 176 ETB driver earnings and record 24 ETB owner commission |

Commission credit, earnings and reservations are separate. Unused top-ups are not owner revenue. Cancellation releases reserved commission. Cancelling an already reconciled business payment is blocked pending support/refund handling.

No payment provider is connected. Drivers pay top-ups by Telebirr to **+251 931 323 328**, the confirmed business number, and attach a payment screenshot. Supabase stores the screenshot in a private bucket. Admin opens it from the Finance review panel, checks the completed payment in the business account, and approves or rejects with a note. Approval adds credit and creates a driver app notification; rejection also creates a notification. The wallet shows the request status and refreshes pending requests while open. A screenshot or submitted request alone never proves payment. Cash-outs remain manual: admin sends the payout, verifies it, and records the unique transaction reference. Pending cash-outs reserve earnings; rejection releases them. Earnings can be converted into non-withdrawable commission credit. Notifications appear in the app's existing realtime/local alert flow while it is running and remain in its notifications list; force-closed push delivery is not configured.

Balance changes run in PostgreSQL transactions behind verified driver/admin sessions. Idempotency keys, reference uniqueness and locks prevent duplicate credit/settlement. Clients cannot read credentials or edit financial tables directly. Account closure requires settled balances and no active jobs/pending requests; active identity and login details are removed while transaction history is retained.

Before automated payments, connect the business merchant account and implement its verified checkout/webhook/transfer adapter. Verify amount, currency, business reference, recipient and final provider status on the server, then use the idempotent ledger operations. A redirect or submitted transfer request is not proof of success.

## Validation

- `cd webapp; npm run test:driver-operations`: real migration/functions in isolated PostgreSQL with pgcrypto; no production data. Covers cash/platform settlement, rounding, snapshots, expiry, wrong drivers, insufficient balances, idempotency, reservations, reference reuse, credential hashing, database permissions and account closure.
- `flutter test test/slide_to_accept_test.dart test/driver_earnings_test.dart`: partial/full slides, duplicate submission prevention, disabled offers, net earnings and completion-date accounting.
- `dart analyze lib` and `npm run build` are release checks. Generate ignored Freezed output when needed: `dart run build_runner build --build-filter=lib/core/databases/api/network_exceptions.freezed.dart`.

Research: [RIDE driver services](https://ride8294.com/ride-for-driver/), [RIDE release notes](https://apps.apple.com/us/app/ride-driver-et/id1375519435), [older 12% reporting](https://addisinsight.net/2022/07/14/ride-vs-feres-whos-becoming-a-winner/), [Uber upfront fare breakdown](https://help.uber.com/en/driving-and-delivering/article/understand-the-calculation-of-prices?nodeId=470cd474-831c-4e01-8e5a-3032ca39bab1), [Android location permissions](https://developer.android.com/develop/sensors-and-location/location/permissions), [Chapa verification guidance](https://docs.chapa.global/docs/v2/getting-started).
