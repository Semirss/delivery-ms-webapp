-- Fix food image uploads for the client app.
-- The client app currently uses the Supabase anon key, so Storage sees uploads
-- as role "anon" unless a Supabase Auth session exists.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'food_images',
    'food_images',
    true,
    6291456,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Allow public read on food_images"
    ON storage.objects;
CREATE POLICY "Allow public read on food_images"
    ON storage.objects
    FOR SELECT
    USING (bucket_id = 'food_images');

DROP POLICY IF EXISTS "Allow authenticated upload on food_images"
    ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated update on food_images"
    ON storage.objects;
DROP POLICY IF EXISTS "Allow app upload on food_images"
    ON storage.objects;
CREATE POLICY "Allow app upload on food_images"
    ON storage.objects
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (bucket_id = 'food_images');
