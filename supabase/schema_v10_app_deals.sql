-- Admin-controlled home deals for the client app.

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS public.app_deals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    subtitle TEXT,
    body TEXT,
    image_url TEXT,
    card_type TEXT NOT NULL DEFAULT 'grid'
        CHECK (card_type IN ('hero', 'grid')),
    accent_color TEXT NOT NULL DEFAULT '#f2644d',
    text_color TEXT NOT NULL DEFAULT '#ffffff',
    overlay_opacity NUMERIC(3, 2) NOT NULL DEFAULT 0.55
        CHECK (overlay_opacity >= 0 AND overlay_opacity <= 0.95),
    badge_text TEXT,
    cta_label TEXT,
    cta_url TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS app_deals_active_sort_idx
    ON public.app_deals(is_active, card_type, sort_order, created_at DESC);

CREATE INDEX IF NOT EXISTS app_deals_schedule_idx
    ON public.app_deals(starts_at, ends_at);

DROP TRIGGER IF EXISTS set_app_deals_updated_at
    ON public.app_deals;
CREATE TRIGGER set_app_deals_updated_at
    BEFORE UPDATE ON public.app_deals
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.app_deals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read on app_deals"
    ON public.app_deals;
CREATE POLICY "Allow public read on app_deals"
    ON public.app_deals
    FOR SELECT
    USING (true);

INSERT INTO public.app_deals (
    title,
    subtitle,
    body,
    card_type,
    accent_color,
    text_color,
    overlay_opacity,
    sort_order,
    is_active
)
VALUES
    (
        'Deals are coming',
        'MotoBike is launching soon with exciting deals and offers for our first users. Stay tuned!',
        'Upcoming offers for delivery customers.',
        'hero',
        '#f2644d',
        '#ffffff',
        0.56,
        10,
        true
    ),
    (
        'Launch deals',
        'Save on first deliveries',
        'Introductory delivery offers.',
        'grid',
        '#f2644d',
        '#ffffff',
        0.46,
        20,
        true
    ),
    (
        'Partner perks',
        'Offers from local shops',
        'Local partner discounts and perks.',
        'grid',
        '#0ea5a4',
        '#ffffff',
        0.46,
        30,
        true
    )
ON CONFLICT DO NOTHING;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.app_deals;
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
END $$;
