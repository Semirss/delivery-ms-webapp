-- Apply after v15. Payment screenshots stay in a private Storage bucket.
BEGIN;
ALTER TABLE public.driver_wallet_requests
  ADD COLUMN IF NOT EXISTS proof_path text,
  ADD COLUMN IF NOT EXISTS proof_mime_type text;

DO $$ BEGIN
  IF to_regclass('storage.buckets') IS NULL THEN
    RAISE EXCEPTION 'Supabase Storage is required for driver payment screenshots';
  END IF;
  INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  VALUES ('driver_topup_proofs', 'driver_topup_proofs', false, 5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp'])
  ON CONFLICT (id) DO UPDATE SET public = false, file_size_limit = 5242880,
    allowed_mime_types = EXCLUDED.allowed_mime_types;
END $$;

CREATE OR REPLACE FUNCTION public.guard_driver_topup_review() RETURNS trigger
LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
BEGIN
  IF OLD.status = 'pending' AND NEW.status = 'completed' AND NEW.kind = 'topup'
    AND (NEW.proof_path IS NULL OR NEW.proof_mime_type NOT IN ('image/jpeg','image/png','image/webp'))
    THEN RAISE EXCEPTION 'A payment screenshot is required before approving this top-up';
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS guard_driver_topup_review ON public.driver_wallet_requests;
CREATE TRIGGER guard_driver_topup_review BEFORE UPDATE OF status ON public.driver_wallet_requests
FOR EACH ROW EXECUTE FUNCTION public.guard_driver_topup_review();

CREATE OR REPLACE FUNCTION public.notify_driver_wallet_review() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF OLD.status = 'pending' AND NEW.status IN ('completed','rejected') THEN
    INSERT INTO public.app_notifications(app, recipient_id, title, body, type)
    VALUES ('driver', NEW.driver_id,
      CASE WHEN NEW.status = 'completed' THEN 'Wallet request approved' ELSE 'Wallet request rejected' END,
      CASE WHEN NEW.status = 'completed' THEN
        CASE WHEN NEW.kind = 'topup' THEN 'Your commission credit top-up was approved.'
          ELSE 'Your cash out was completed.' END
      ELSE 'Your wallet request was rejected. Open your wallet to see the reason.' END,
      'wallet_request');
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS notify_driver_wallet_review ON public.driver_wallet_requests;
CREATE TRIGGER notify_driver_wallet_review AFTER UPDATE OF status ON public.driver_wallet_requests
FOR EACH ROW EXECUTE FUNCTION public.notify_driver_wallet_review();
REVOKE ALL ON FUNCTION public.guard_driver_topup_review(), public.notify_driver_wallet_review()
  FROM PUBLIC, anon, authenticated;
COMMIT;
NOTIFY pgrst, 'reload schema';
