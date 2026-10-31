-- Apply after schema_v21_focused_delivery_notifications.sql.
-- Wallet payment destinations are edited by admins through the server API.
BEGIN;

ALTER TABLE public.driver_operations_settings
  DROP CONSTRAINT IF EXISTS driver_settings_telebirr_phone_valid,
  DROP CONSTRAINT IF EXISTS driver_settings_bank_details_valid;

ALTER TABLE public.driver_operations_settings
  ADD COLUMN IF NOT EXISTS telebirr_phone text NOT NULL DEFAULT '+251 931 323 328',
  ADD COLUMN IF NOT EXISTS bank_enabled boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS bank_name text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS bank_account_name text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS bank_account_number text NOT NULL DEFAULT '';

ALTER TABLE public.driver_operations_settings
  ADD CONSTRAINT driver_settings_telebirr_phone_valid
    CHECK (regexp_replace(telebirr_phone, '[ ()-]', '', 'g') ~ '^([+]251|251|0)9[0-9]{8}$'),
  ADD CONSTRAINT driver_settings_bank_details_valid
    CHECK (NOT bank_enabled OR (
      length(trim(bank_name)) BETWEEN 2 AND 100 AND
      length(trim(bank_account_name)) BETWEEN 2 AND 100 AND
      bank_account_number ~ '^[0-9]{7,34}$'
    ));

COMMIT;
NOTIFY pgrst, 'reload schema';
