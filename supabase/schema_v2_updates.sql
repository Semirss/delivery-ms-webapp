-- 1. Create Admins table
CREATE TABLE IF NOT EXISTS public.admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Note: We will insert a default admin account here or allow you to do it via API.
INSERT INTO public.admins (username, password) VALUES ('admin', 'admin123') ON CONFLICT DO NOTHING;

-- 2. Add Approval Status to Drivers
ALTER TABLE public.drivers ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'Pending';

-- Update existing drivers to be immediately approved so they aren't locked out.
UPDATE public.drivers SET approval_status = 'Approved';

-- 3. Make delivery_fee nullable since it's set later
ALTER TABLE public.deliveries ALTER COLUMN delivery_fee DROP NOT NULL;

-- 4. Driver extra info for Moto/Bike system
ALTER TABLE public.drivers ADD COLUMN IF NOT EXISTS plate_number TEXT;
ALTER TABLE public.drivers ADD COLUMN IF NOT EXISTS personal_id_url TEXT;
ALTER TABLE public.drivers ADD COLUMN IF NOT EXISTS telegram_username TEXT;
ALTER TABLE public.drivers ADD COLUMN IF NOT EXISTS vehicle_type TEXT;

-- 5. Delivery category
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS vehicle_category TEXT;

-- 6. Setup Supabase Storage for Driver IDs (Run in SQL editor if not using UI)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('driver_ids', 'driver_ids', true) ON CONFLICT (id) DO NOTHING;
-- Note: Remember to set RLS policies on the bucket via Supabase Dashboard to allow uploads (e.g. INSERT for anon/authenticated if doing public uploads, or specific roles).
