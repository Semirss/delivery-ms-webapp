-- Shared Addis Ababa location catalog for the client app and web app.
-- Permanent coordinates come from OSM/manual records. Google Place IDs may be
-- stored for validation, but Google names/coordinates must not be cached here.

CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;

CREATE TABLE IF NOT EXISTS public.addis_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL CHECK (length(trim(name)) > 0),
    aliases TEXT[] NOT NULL DEFAULT '{}',
    latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    location_type TEXT NOT NULL DEFAULT 'neighbourhood',
    source TEXT NOT NULL DEFAULT 'manual',
    source_license TEXT,
    external_id TEXT UNIQUE,
    google_place_id TEXT UNIQUE,
    search_priority INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    search_text TEXT NOT NULL DEFAULT '',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    source_updated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.prepare_addis_location()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.name := trim(NEW.name);
    NEW.aliases := ARRAY(
        SELECT DISTINCT trim(alias)
        FROM unnest(COALESCE(NEW.aliases, '{}'::text[])) AS alias
        WHERE trim(alias) <> '' AND lower(trim(alias)) <> lower(NEW.name)
    );
    NEW.search_text := lower(
        trim(concat_ws(' ', NEW.name, array_to_string(NEW.aliases, ' ')))
    );
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prepare_addis_location_trigger
    ON public.addis_locations;
CREATE TRIGGER prepare_addis_location_trigger
    BEFORE INSERT OR UPDATE ON public.addis_locations
    FOR EACH ROW EXECUTE FUNCTION public.prepare_addis_location();

CREATE INDEX IF NOT EXISTS addis_locations_search_trgm_idx
    ON public.addis_locations USING GIN (search_text extensions.gin_trgm_ops);
CREATE INDEX IF NOT EXISTS addis_locations_active_priority_idx
    ON public.addis_locations (is_active, search_priority DESC, name);
CREATE INDEX IF NOT EXISTS addis_locations_coordinates_idx
    ON public.addis_locations (latitude, longitude);

ALTER TABLE public.addis_locations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can read active Addis locations"
    ON public.addis_locations;
CREATE POLICY "Public can read active Addis locations"
    ON public.addis_locations
    FOR SELECT
    USING (is_active = TRUE);

GRANT SELECT ON public.addis_locations TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.search_addis_locations(
    search_query TEXT DEFAULT '',
    result_limit INTEGER DEFAULT 12
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    aliases TEXT[],
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location_type TEXT,
    source TEXT,
    google_place_id TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
    WITH input AS (
        SELECT lower(trim(COALESCE(search_query, ''))) AS query
    )
    SELECT
        location.id,
        location.name,
        location.aliases,
        location.latitude,
        location.longitude,
        location.location_type,
        location.source,
        location.google_place_id
    FROM public.addis_locations AS location
    CROSS JOIN input
    WHERE location.is_active = TRUE
      AND (
          input.query = ''
          OR location.search_text ILIKE '%' || input.query || '%'
          OR location.search_text % input.query
      )
    ORDER BY
        CASE WHEN lower(location.name) = input.query THEN 0 ELSE 1 END,
        CASE WHEN lower(location.name) LIKE input.query || '%' THEN 0 ELSE 1 END,
        similarity(location.search_text, input.query) DESC,
        location.search_priority DESC,
        location.name
    LIMIT LEAST(GREATEST(COALESCE(result_limit, 12), 1), 50);
$$;

GRANT EXECUTE ON FUNCTION public.search_addis_locations(TEXT, INTEGER)
    TO anon, authenticated;

-- Emergency starter catalog. The admin OSM sync expands this without an app
-- rebuild, and manual additions are immediately visible to both clients.
INSERT INTO public.addis_locations (
    name, aliases, latitude, longitude, source, source_license,
    external_id, search_priority
)
VALUES
    ('Bole', ARRAY['Bole Road','Edna Mall'], 8.9947, 38.7891, 'curated', 'OpenStreetMap/field review', 'curated:bole', 100),
    ('Bole Atlas', ARRAY['Atlas','Atlas Hotel'], 8.9979, 38.7815, 'curated', 'OpenStreetMap/field review', 'curated:bole-atlas', 90),
    ('Bole Medhanialem', ARRAY['Bole Medhanealem','Medhanialem','Edna'], 8.9974, 38.7866, 'curated', 'OpenStreetMap/field review', 'curated:bole-medhanialem', 95),
    ('Bole Michael', ARRAY['Bole Mikhael','Bole Mikael'], 8.9829, 38.7888, 'curated', 'OpenStreetMap/field review', 'curated:bole-michael', 70),
    ('Bole Bulbula', ARRAY['Bulbula','Bole Bulibula'], 8.9256, 38.7856, 'curated', 'OpenStreetMap/field review', 'curated:bole-bulbula', 70),
    ('Bole Arabsa', ARRAY['Arabsa','Arabssa'], 8.9184, 38.8347, 'curated', 'OpenStreetMap/field review', 'curated:bole-arabsa', 70),
    ('CMC', ARRAY['CMC Michael','CMC Square'], 9.0272, 38.8429, 'curated', 'OpenStreetMap/field review', 'curated:cmc', 100),
    ('Gurd Shola', ARRAY['Gurdi Shola','Gurdshola'], 9.0223, 38.8140, 'curated', 'OpenStreetMap/field review', 'curated:gurd-shola', 95),
    ('Piassa', ARRAY['Piazza','Arada'], 9.0369, 38.7524, 'curated', 'OpenStreetMap/field review', 'curated:piassa', 100),
    ('Kazanchis', ARRAY['Kasanchis'], 9.0133, 38.7652, 'curated', 'OpenStreetMap/field review', 'curated:kazanchis', 100),
    ('Meskel Square', ARRAY['Meskel','Stadium'], 9.0104, 38.7612, 'curated', 'OpenStreetMap/field review', 'curated:meskel-square', 100),
    ('Gotera', ARRAY['Gotera Interchange','Gotera Condominium'], 8.9964, 38.7665, 'curated', 'OpenStreetMap/field review', 'curated:gotera', 90),
    ('Summit', ARRAY['Summit Square','Summit Condominium','Summit Mazoria'], 9.0311, 38.8688, 'curated', 'OpenStreetMap/field review', 'curated:summit', 90),
    ('Hayat', ARRAY['Hayat Hospital','Yeka Hayat'], 9.0250, 38.8500, 'curated', 'OpenStreetMap/field review', 'curated:hayat', 85),
    ('Ayat', ARRAY['Ayat Real Estate'], 9.0266, 38.8580, 'curated', 'OpenStreetMap/field review', 'curated:ayat', 85),
    ('Megenagna', ARRAY['Megenagna Taxi Station','Megenagna Shola'], 9.0194, 38.8005, 'curated', 'OpenStreetMap/field review', 'curated:megenagna', 100),
    ('Haya Hulet 22', ARRAY['22','Haya Hulet','22 Mazoria'], 9.0069, 38.7852, 'curated', 'OpenStreetMap/field review', 'curated:haya-hulet', 90),
    ('Gerji', ARRAY['Gerji Mebrat Hail','Gerji Imperial'], 9.0104, 38.8068, 'curated', 'OpenStreetMap/field review', 'curated:gerji', 85),
    ('Jacros', ARRAY['Jakros','Yekatit 12 Square'], 9.0158, 38.8285, 'curated', 'OpenStreetMap/field review', 'curated:jacros', 75),
    ('Figa', ARRAY['Figa Mebrat','Yeka Figa'], 9.0368, 38.8311, 'curated', 'OpenStreetMap/field review', 'curated:figa', 65),
    ('Kotebe', ARRAY['Kotebe College'], 9.0336, 38.8175, 'curated', 'OpenStreetMap/field review', 'curated:kotebe', 70),
    ('Shola', ARRAY['Shola Market','Shola Gebeya'], 9.0262, 38.7956, 'curated', 'OpenStreetMap/field review', 'curated:shola', 80),
    ('Urael', ARRAY['Ural','Urael Church'], 9.0101, 38.7749, 'curated', 'OpenStreetMap/field review', 'curated:urael', 85),
    ('Wollo Sefer', ARRAY['Wello Sefer','Bole Wello Sefer'], 8.9989, 38.7732, 'curated', 'OpenStreetMap/field review', 'curated:wollo-sefer', 85),
    ('Olympia', ARRAY['Olympia Square'], 9.0058, 38.7637, 'curated', 'OpenStreetMap/field review', 'curated:olympia', 75),
    ('Merkato', ARRAY['Mercato','Autobus Tera'], 9.0277, 38.7388, 'curated', 'OpenStreetMap/field review', 'curated:merkato', 100),
    ('Mexico Square', ARRAY['Mexico','Mex'], 9.0097, 38.7458, 'curated', 'OpenStreetMap/field review', 'curated:mexico-square', 90),
    ('Lideta Square', ARRAY['Ledeta','Lideta'], 9.0155, 38.7344, 'curated', 'OpenStreetMap/field review', 'curated:lideta-square', 85),
    ('Torhailoch Square', ARRAY['Tor Hayloch','Tor Hailoch','Torhayloch'], 9.0125, 38.7233, 'curated', 'OpenStreetMap/field review', 'curated:torhailoch', 85),
    ('Old Airport', ARRAY['Airport Area','Bisrate Gabriel'], 8.9960, 38.7291, 'curated', 'OpenStreetMap/field review', 'curated:old-airport', 80),
    ('Weyra Sefer', ARRAY['Weira Sefer'], 8.9955, 38.7555, 'curated', 'OpenStreetMap/field review', 'curated:weyra-sefer', 75),
    ('Lancha', ARRAY['Lancia'], 8.9964, 38.7466, 'curated', 'OpenStreetMap/field review', 'curated:lancha', 65),
    ('Kera', ARRAY['Kera Roundabout'], 8.9864, 38.7477, 'curated', 'OpenStreetMap/field review', 'curated:kera', 75),
    ('Sar Bet', ARRAY['Sarbet'], 8.9913, 38.7328, 'curated', 'OpenStreetMap/field review', 'curated:sar-bet', 80),
    ('Mekanisa', ARRAY['Mekanissa','Mekanisa Abo'], 8.9771, 38.7288, 'curated', 'OpenStreetMap/field review', 'curated:mekanisa', 80),
    ('Lafto', ARRAY['Nifas Silk Lafto','Nifas Silk'], 8.9585, 38.7404, 'curated', 'OpenStreetMap/field review', 'curated:lafto', 80),
    ('Saris Abo', ARRAY['Saris','Saris Adey Abeba'], 8.9711, 38.7633, 'curated', 'OpenStreetMap/field review', 'curated:saris-abo', 80),
    ('Kality Menaharia', ARRAY['Kaliti','Kality','Kality Bus Station'], 8.8955, 38.7583, 'curated', 'OpenStreetMap/field review', 'curated:kality', 80),
    ('Lebu', ARRAY['Lebu Mebrat','Lebu Medhanialem'], 8.9645, 38.7184, 'curated', 'OpenStreetMap/field review', 'curated:lebu', 80),
    ('Jemo', ARRAY['Jemo Michael','Jemo Condominium'], 8.9588, 38.7246, 'curated', 'OpenStreetMap/field review', 'curated:jemo', 80),
    ('Ayer Tena', ARRAY['Ayertena','Ayer Tena Square'], 9.0046, 38.6925, 'curated', 'OpenStreetMap/field review', 'curated:ayer-tena', 75),
    ('Alem Bank', ARRAY['Alembank'], 9.0151, 38.6898, 'curated', 'OpenStreetMap/field review', 'curated:alem-bank', 70),
    ('Kolfe', ARRAY['Kolfe Keranio'], 9.0302, 38.7072, 'curated', 'OpenStreetMap/field review', 'curated:kolfe', 75),
    ('Asko', ARRAY['Asko Addis Sefer'], 9.0711, 38.7054, 'curated', 'OpenStreetMap/field review', 'curated:asko', 70),
    ('Wingate', ARRAY['Winget','Wingate School'], 9.0540, 38.7210, 'curated', 'OpenStreetMap/field review', 'curated:wingate', 65),
    ('Addisu Gebeya', ARRAY['Addis Gebeya','New Market'], 9.0467, 38.7330, 'curated', 'OpenStreetMap/field review', 'curated:addisu-gebeya', 75),
    ('Shiro Meda', ARRAY['Shiromeda','Shiro Meda Market'], 9.0626, 38.7617, 'curated', 'OpenStreetMap/field review', 'curated:shiro-meda', 75),
    ('Entoto', ARRAY['Entoto Maryam','Entoto Park'], 9.0836, 38.7648, 'curated', 'OpenStreetMap/field review', 'curated:entoto', 80),
    ('Arat Kilo', ARRAY['4 Kilo','Arat Kilo Square'], 9.0340, 38.7611, 'curated', 'OpenStreetMap/field review', 'curated:arat-kilo', 90),
    ('Sidist Kilo', ARRAY['6 Kilo','Six Kilo'], 9.0445, 38.7612, 'curated', 'OpenStreetMap/field review', 'curated:sidist-kilo', 85),
    ('Amist Kilo', ARRAY['5 Kilo','Five Kilo'], 9.0393, 38.7588, 'curated', 'OpenStreetMap/field review', 'curated:amist-kilo', 75),
    ('Kebena', ARRAY['Yeka Kebena'], 9.0352, 38.7778, 'curated', 'OpenStreetMap/field review', 'curated:kebena', 70),
    ('Ferensay Legasion', ARRAY['Ferensay','French Embassy'], 9.0437, 38.7834, 'curated', 'OpenStreetMap/field review', 'curated:ferensay-legasion', 70),
    ('Haya Arat 24', ARRAY['24','Haya Arat','24 Mazoria'], 9.0082, 38.7919, 'curated', 'OpenStreetMap/field review', 'curated:haya-arat', 70),
    ('Meri', ARRAY['Meri Luke'], 9.0153, 38.8641, 'curated', 'OpenStreetMap/field review', 'curated:meri', 70),
    ('Yerer', ARRAY['Yerer Ber'], 9.0234, 38.8878, 'curated', 'OpenStreetMap/field review', 'curated:yerer', 65),
    ('Zenebe Werk', ARRAY['Zenba Wer','Zenbe Werk','Zenebe Work'], 9.0300, 38.7055, 'curated', 'OpenStreetMap/field review', 'curated:zenebe-werk', 60)
ON CONFLICT (external_id) DO UPDATE
SET
    name = EXCLUDED.name,
    aliases = EXCLUDED.aliases,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    search_priority = EXCLUDED.search_priority,
    is_active = TRUE;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.addis_locations;
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
END $$;
