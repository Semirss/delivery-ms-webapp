-- Optional mutual ratings between clients and drivers after a completed delivery.

CREATE TABLE IF NOT EXISTS public.delivery_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_id UUID NOT NULL REFERENCES public.deliveries(id) ON DELETE CASCADE,
    rater_type TEXT NOT NULL CHECK (rater_type IN ('client', 'driver')),
    rater_id TEXT NOT NULL,
    ratee_type TEXT NOT NULL CHECK (ratee_type IN ('client', 'driver')),
    ratee_id TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT delivery_ratings_unique_side UNIQUE (
        delivery_id,
        rater_type,
        rater_id,
        ratee_type,
        ratee_id
    )
);

CREATE INDEX IF NOT EXISTS idx_delivery_ratings_delivery
    ON public.delivery_ratings(delivery_id);

CREATE INDEX IF NOT EXISTS idx_delivery_ratings_ratee
    ON public.delivery_ratings(ratee_type, ratee_id);

CREATE OR REPLACE FUNCTION public.touch_delivery_ratings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS touch_delivery_ratings_updated_at
    ON public.delivery_ratings;

CREATE TRIGGER touch_delivery_ratings_updated_at
    BEFORE UPDATE ON public.delivery_ratings
    FOR EACH ROW
    EXECUTE FUNCTION public.touch_delivery_ratings_updated_at();

ALTER TABLE public.delivery_ratings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public all on delivery_ratings"
    ON public.delivery_ratings;

CREATE POLICY "Allow public all on delivery_ratings"
    ON public.delivery_ratings
    FOR ALL
    USING (true)
    WITH CHECK (true);
