-- Food marketplace for client app food delivery and admin control.

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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
DROP POLICY IF EXISTS "Allow app upload on food_images"
    ON storage.objects;
CREATE POLICY "Allow app upload on food_images"
    ON storage.objects
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (bucket_id = 'food_images');

DROP POLICY IF EXISTS "Allow authenticated update on food_images"
    ON storage.objects;

CREATE TABLE IF NOT EXISTS public.food_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    parent_id UUID REFERENCES public.food_categories(id) ON DELETE SET NULL,
    icon_name TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS food_categories_parent_idx
    ON public.food_categories(parent_id);

CREATE INDEX IF NOT EXISTS food_categories_active_sort_idx
    ON public.food_categories(is_active, sort_order, name);

CREATE TABLE IF NOT EXISTS public.food_restaurants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    subtitle TEXT,
    phone TEXT,
    image_url TEXT,
    pickup_location TEXT,
    pickup_lat FLOAT8,
    pickup_lng FLOAT8,
    is_featured BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    sort_order INTEGER NOT NULL DEFAULT 0,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS food_restaurants_featured_sort_idx
    ON public.food_restaurants(is_featured, is_active, sort_order, name);

CREATE TABLE IF NOT EXISTS public.food_marketplace_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (price >= 0),
    image_url TEXT,
    seller_name TEXT NOT NULL,
    seller_phone TEXT NOT NULL,
    pickup_location TEXT,
    pickup_lat FLOAT8,
    pickup_lng FLOAT8,
    category_id UUID REFERENCES public.food_categories(id) ON DELETE SET NULL,
    restaurant_id UUID REFERENCES public.food_restaurants(id) ON DELETE SET NULL,
    restaurant_name TEXT,
    source_type TEXT NOT NULL DEFAULT 'client'
        CHECK (source_type IN ('client', 'restaurant', 'admin')),
    created_by UUID,
    is_featured BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    sort_order INTEGER NOT NULL DEFAULT 0,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.food_marketplace_items
    ADD COLUMN IF NOT EXISTS restaurant_name TEXT;

CREATE INDEX IF NOT EXISTS food_marketplace_items_category_idx
    ON public.food_marketplace_items(category_id);

CREATE INDEX IF NOT EXISTS food_marketplace_items_restaurant_idx
    ON public.food_marketplace_items(restaurant_id);

CREATE INDEX IF NOT EXISTS food_marketplace_items_active_sort_idx
    ON public.food_marketplace_items(is_active, is_featured, sort_order, created_at DESC);

DROP TRIGGER IF EXISTS set_food_categories_updated_at
    ON public.food_categories;
CREATE TRIGGER set_food_categories_updated_at
    BEFORE UPDATE ON public.food_categories
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_food_restaurants_updated_at
    ON public.food_restaurants;
CREATE TRIGGER set_food_restaurants_updated_at
    BEFORE UPDATE ON public.food_restaurants
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_food_marketplace_items_updated_at
    ON public.food_marketplace_items;
CREATE TRIGGER set_food_marketplace_items_updated_at
    BEFORE UPDATE ON public.food_marketplace_items
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.food_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_marketplace_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public all on food_categories"
    ON public.food_categories;
CREATE POLICY "Allow public all on food_categories"
    ON public.food_categories
    FOR ALL
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public all on food_restaurants"
    ON public.food_restaurants;
CREATE POLICY "Allow public all on food_restaurants"
    ON public.food_restaurants
    FOR ALL
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public all on food_marketplace_items"
    ON public.food_marketplace_items;
CREATE POLICY "Allow public all on food_marketplace_items"
    ON public.food_marketplace_items
    FOR ALL
    USING (true)
    WITH CHECK (true);

INSERT INTO public.food_categories (name, slug, description, icon_name, sort_order)
VALUES
    ('Breakfast', 'breakfast', 'Morning meals and cafe plates', 'breakfast_dining', 10),
    ('Chicken', 'chicken', 'Fried, grilled and family chicken meals', 'set_meal', 20),
    ('Ethiopian', 'ethiopian', 'Local plates, injera and stews', 'restaurant', 30),
    ('Fast food', 'fast-food', 'Burgers, fries and quick meals', 'fastfood', 40),
    ('Home kitchen', 'home-kitchen', 'Client-made meals and home food', 'home', 50)
ON CONFLICT (slug) DO UPDATE
SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon_name = EXCLUDED.icon_name,
    sort_order = EXCLUDED.sort_order,
    is_active = true;

INSERT INTO public.food_restaurants (
    name,
    slug,
    subtitle,
    phone,
    image_url,
    pickup_location,
    pickup_lat,
    pickup_lng,
    is_featured,
    is_active,
    sort_order
)
VALUES
    (
        'Simple pistro',
        'simple-pistro',
        'Burgers, pasta and cafe plates',
        '+251 900 000 001',
        'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80',
        'Simple pistro, Addis Ababa',
        9.0116,
        38.7850,
        true,
        true,
        10
    ),
    (
        'Amrogn chiken',
        'amrogn-chiken',
        'Crispy chicken and family meals',
        '+251 900 000 002',
        'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?auto=format&fit=crop&w=900&q=80',
        'Amrogn chiken, Addis Ababa',
        9.0069,
        38.7852,
        true,
        true,
        20
    )
ON CONFLICT (slug) DO UPDATE
SET
    subtitle = EXCLUDED.subtitle,
    phone = EXCLUDED.phone,
    image_url = EXCLUDED.image_url,
    pickup_location = EXCLUDED.pickup_location,
    pickup_lat = EXCLUDED.pickup_lat,
    pickup_lng = EXCLUDED.pickup_lng,
    is_featured = EXCLUDED.is_featured,
    is_active = EXCLUDED.is_active,
    sort_order = EXCLUDED.sort_order;

INSERT INTO public.food_marketplace_items (
    title,
    description,
    price,
    image_url,
    seller_name,
    seller_phone,
    pickup_location,
    pickup_lat,
    pickup_lng,
    category_id,
    restaurant_id,
    restaurant_name,
    source_type,
    is_featured,
    is_active,
    sort_order
)
SELECT
    seed.title,
    seed.description,
    seed.price,
    seed.image_url,
    seed.seller_name,
    seed.seller_phone,
    seed.pickup_location,
    seed.pickup_lat,
    seed.pickup_lng,
    category.id,
    restaurant.id,
    seed.restaurant_name,
    seed.source_type,
    seed.is_featured,
    true,
    seed.sort_order
FROM (
    VALUES
        (
            'Simple burger combo',
            'Burger and fries',
            420::numeric,
            'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80',
            'Simple pistro',
            '+251 900 000 001',
            'Simple pistro, Addis Ababa',
            9.0116::float8,
            38.7850::float8,
            'fast-food',
            'simple-pistro',
            'Simple pistro',
            'restaurant',
            true,
            10
        ),
        (
            'Amrogn crispy chicken',
            'Crispy chicken plate',
            520::numeric,
            'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?auto=format&fit=crop&w=900&q=80',
            'Amrogn chiken',
            '+251 900 000 002',
            'Amrogn chiken, Addis Ababa',
            9.0069::float8,
            38.7852::float8,
            'chicken',
            'amrogn-chiken',
            'Amrogn chiken',
            'restaurant',
            true,
            20
        ),
        (
            'Fresh lunch bowl',
            'Rice, vegetables and sauce',
            350::numeric,
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
            'Mimi kitchen',
            '+251 900 000 004',
            'Kazanchis, Addis Ababa',
            9.0133::float8,
            38.7652::float8,
            'home-kitchen',
            NULL,
            NULL,
            'client',
            false,
            30
        )
) AS seed (
    title,
    description,
    price,
    image_url,
    seller_name,
    seller_phone,
    pickup_location,
    pickup_lat,
    pickup_lng,
    category_slug,
    restaurant_slug,
    restaurant_name,
    source_type,
    is_featured,
    sort_order
)
LEFT JOIN public.food_categories category
    ON category.slug = seed.category_slug
LEFT JOIN public.food_restaurants restaurant
    ON restaurant.slug = seed.restaurant_slug
WHERE NOT EXISTS (
    SELECT 1
    FROM public.food_marketplace_items existing
    WHERE lower(existing.title) = lower(seed.title)
        AND existing.seller_phone = seed.seller_phone
);

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.food_categories;
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.food_restaurants;
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.food_marketplace_items;
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
END $$;
