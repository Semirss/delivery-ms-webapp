-- Read-only check for the dedicated test Supabase project.
-- Run in the SQL Editor for mtbqqharhxijulpaqdrm before and after v15-v18.
-- Every base_* value must be true before applying v15.
SELECT
  to_regclass('public.drivers') IS NOT NULL AS base_drivers,
  to_regclass('public.deliveries') IS NOT NULL AS base_deliveries,
  to_regclass('public.admins') IS NOT NULL AS base_admins,
  to_regclass('public.app_notifications') IS NOT NULL AS base_notifications,
  to_regclass('storage.buckets') IS NOT NULL AS base_storage,
  to_regprocedure('public.normalize_phone_number(text)') IS NOT NULL AS base_phone_function,
  to_regclass('public.driver_wallets') IS NOT NULL
    AND to_regclass('public.driver_credentials') IS NOT NULL AS v15_ready,
  to_regclass('public.driver_wallet_requests') IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'driver_wallet_requests'
        AND column_name = 'proof_path'
    ) AS v16_ready,
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'drivers'
      AND column_name = 'availability_paused'
  ) AS v17_ready,
  to_regprocedure('public.driver_set_offer_fare(uuid,uuid,numeric)') IS NOT NULL AS v18_ready;
