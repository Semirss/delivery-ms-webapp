# Addis Ababa location catalog

The client app and web booking flow now read one location catalog from Supabase.

## Deploy

Run these migrations in order in the active Supabase project:

1. `supabase/schema_v13_addis_locations.sql`
2. `supabase/schema_v14_remove_food_demo_data.sql`

Deploy the web app after setting the existing Supabase server variables. Optionally set `GOOGLE_MAPS_API_KEY` for the admin sync's Google Place ID validation.

## Populate and maintain

1. Sign in to the web admin.
2. Open **Locations**.
3. Click **Sync OSM** to import mapped neighborhoods, suburbs, quarters, localities, villages, and low-level administrative areas inside the Addis bounding box.
4. Optionally click **Sync + Google IDs**. This stores Google Place IDs only.
5. Add or disable individual neighborhoods from the same screen.

The client restores its last successful Supabase catalog from device storage when offline. If no cache exists, it uses the bundled emergency Addis list. Search then tries Supabase, the web API, and bounded OpenStreetMap search in that order.

Google Places names and coordinates are not scraped or persisted because Google Maps Platform restricts long-term caching of that content. Place IDs are the documented storage exception.

Location records imported from OpenStreetMap retain ODbL attribution in `source_license` and the admin/web API responses.
