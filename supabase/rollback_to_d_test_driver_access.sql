-- Manual database compatibility rollback for the primary branch at c8e14d8 ("d").
-- Only for the owner's test database: all driver accounts are test accounts.
-- Apply in Supabase SQL Editor AFTER taking a database backup/snapshot.
-- Git checkout does not undo applied SQL migrations.
-- This restores the legacy app's direct driver/delivery access and sets the
-- requested shared test password, 121212, for every driver row.
-- It does not erase wallet/payment history or remove v15-v18 columns/tables.

BEGIN;

DO $$
BEGIN
  IF to_regclass('public.driver_credentials') IS NULL THEN
    RAISE EXCEPTION 'schema v15 is not present; inspect this database before running the rollback';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgrelid = 'public.drivers'::regclass
      AND tgname = 'capture_driver_password'
      AND NOT tgisinternal
  ) THEN
    RAISE EXCEPTION 'Expected v15 password trigger is missing; inspect this database before running the rollback';
  END IF;
END $$;

-- The v15 trigger clears plaintext on every password update. Bypass it only
-- for this transaction, while updating the current API's protected hashes too.
ALTER TABLE public.drivers DISABLE TRIGGER capture_driver_password;
UPDATE public.drivers
SET password = '121212', auth_version = auth_version + 1;
INSERT INTO public.driver_credentials (driver_id, password_hash)
SELECT id, extensions.crypt('121212', extensions.gen_salt('bf', 12))
FROM public.drivers
ON CONFLICT (driver_id) DO UPDATE SET password_hash = EXCLUDED.password_hash;
ALTER TABLE public.drivers ENABLE TRIGGER capture_driver_password;

-- Restore the direct table reads/writes used by the app at commit d.
DROP POLICY IF EXISTS driver_public_read ON public.drivers;
DROP POLICY IF EXISTS delivery_public_read ON public.deliveries;
DROP POLICY IF EXISTS delivery_pending_insert ON public.deliveries;
DROP POLICY IF EXISTS delivery_customer_cancel ON public.deliveries;
DROP POLICY IF EXISTS "Allow public all on drivers" ON public.drivers;
DROP POLICY IF EXISTS "Allow public all on deliveries" ON public.deliveries;
CREATE POLICY "Allow public all on drivers" ON public.drivers
  FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all on deliveries" ON public.deliveries
  FOR ALL USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.drivers, public.deliveries
  TO anon, authenticated;

COMMIT;
NOTIFY pgrst, 'reload schema';

-- Verification, run separately:
-- SELECT count(*) AS drivers_with_test_password FROM public.drivers WHERE password = '121212';
-- SELECT count(*) AS total_drivers FROM public.drivers;
