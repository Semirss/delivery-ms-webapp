-- V3 Schema Updates

-- 1. Delivery assignment timeout tracking
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMPTZ;

-- 2. Cancellation record-keeping
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS cancelled_by TEXT; -- 'driver_reject', 'timeout', 'admin'

-- 3. Driver active/inactive permanent state (separate from Online/Offline)
ALTER TABLE public.drivers ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
UPDATE public.drivers SET is_active = true WHERE is_active IS NULL;
