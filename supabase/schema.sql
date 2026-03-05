-- Drivers table
CREATE TABLE public.drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    password TEXT NOT NULL,
    telegram_id TEXT UNIQUE,
    status TEXT NOT NULL DEFAULT 'Offline', -- 'Online', 'Offline'
    total_deliveries INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

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
