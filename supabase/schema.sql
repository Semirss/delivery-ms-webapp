-- Drivers table
CREATE TABLE public.drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT NOT NULL,
    password TEXT NOT NULL,
    telegram_id TEXT UNIQUE,
    status TEXT NOT NULL DEFAULT 'Offline', -- 'Online', 'Offline'
    total_deliveries INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE OR REPLACE FUNCTION public.normalize_phone_number(p_phone TEXT)
RETURNS TEXT AS $$
DECLARE
    digits TEXT;
BEGIN
    digits := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');

    IF digits = '' THEN
        RETURN NULL;
    END IF;

    IF length(digits) = 12
        AND left(digits, 3) = '251'
        AND substring(digits FROM 4 FOR 1) IN ('7', '9') THEN
        RETURN '0' || substring(digits FROM 4);
    END IF;

    IF length(digits) = 9 AND left(digits, 1) IN ('7', '9') THEN
        RETURN '0' || digits;
    END IF;

    IF length(digits) = 10
        AND left(digits, 1) = '0'
        AND substring(digits FROM 2 FOR 1) IN ('7', '9') THEN
        RETURN digits;
    END IF;

    RETURN digits;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE UNIQUE INDEX IF NOT EXISTS drivers_email_lower_unique
    ON public.drivers (lower(email))
    WHERE email IS NOT NULL AND btrim(email) <> '';

DROP INDEX IF EXISTS public.drivers_phone_unique;
CREATE UNIQUE INDEX IF NOT EXISTS drivers_phone_unique
    ON public.drivers (public.normalize_phone_number(phone))
    WHERE public.normalize_phone_number(phone) IS NOT NULL;

-- Deliveries table
CREATE TABLE public.deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    pickup_location TEXT NOT NULL,
    dropoff_location TEXT NOT NULL,
    package_type TEXT,
    delivery_fee DECIMAL(10,2),
    status TEXT NOT NULL DEFAULT 'Pending', -- 'Pending', 'Assigned', 'Picked Up', 'Delivered', 'Cancelled'
    driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
    time_requested TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS (Row Level Security)
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deliveries ENABLE ROW LEVEL SECURITY;

-- Allow public access for MVP validation (Since we are using service role or simple token)
CREATE POLICY "Allow public all on drivers" ON public.drivers FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all on deliveries" ON public.deliveries FOR ALL USING (true) WITH CHECK (true);
