-- One-time recovery for approved, active TEST drivers using pre-v15 app builds.
-- The project owner confirmed every approved, active driver is a test account
-- and authorized resetting all of them to new random plaintext passwords.
-- Run once in the Supabase SQL Editor after schema v15. Save the final result
-- securely and give each driver only their own new password.

BEGIN;

CREATE TEMP TABLE legacy_test_driver_passwords ON COMMIT PRESERVE ROWS AS
SELECT id, email, phone, encode(extensions.gen_random_bytes(16), 'hex') AS new_password
FROM public.drivers
WHERE approval_status = 'Approved' AND is_active IS DISTINCT FROM false;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM legacy_test_driver_passwords) THEN
    RAISE EXCEPTION 'No approved, active test drivers found; no passwords were changed';
  END IF;
END $$;

-- The v15 trigger normally clears drivers.password. Disable it only inside
-- this transaction, then refresh the protected hashes for the newer app/API.
ALTER TABLE public.drivers DISABLE TRIGGER capture_driver_password;

UPDATE public.drivers AS d
SET password = p.new_password, auth_version = d.auth_version + 1
FROM legacy_test_driver_passwords AS p
WHERE d.id = p.id;

INSERT INTO public.driver_credentials (driver_id, password_hash)
SELECT id, extensions.crypt(new_password, extensions.gen_salt('bf', 12))
FROM legacy_test_driver_passwords
ON CONFLICT (driver_id) DO UPDATE SET password_hash = EXCLUDED.password_hash;

ALTER TABLE public.drivers ENABLE TRIGGER capture_driver_password;

COMMIT;

-- Save this result now; this temporary result table disappears when the SQL
-- Editor's database session ends. The passwords remain in public.drivers for
-- the old app until you clear that column after all drivers update.
SELECT id, email, phone, new_password
FROM legacy_test_driver_passwords
ORDER BY email NULLS LAST, phone;
