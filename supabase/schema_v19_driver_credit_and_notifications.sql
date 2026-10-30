-- Apply after schema_v18_driver_offer_fare.sql.
BEGIN;

ALTER TABLE public.app_notifications
  DROP CONSTRAINT IF EXISTS app_notifications_has_recipient;
ALTER TABLE public.app_notifications
  ADD CONSTRAINT app_notifications_has_recipient CHECK (
    recipient_id IS NOT NULL OR recipient_phone IS NOT NULL
    OR app = 'admin' OR type = 'admin_message'
  );

-- Retire the two wallet actions and the driver fare mutation at the database boundary.
CREATE OR REPLACE FUNCTION public.prevent_retired_driver_wallet_actions()
RETURNS trigger LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
BEGIN
  IF NEW.kind <> 'topup' THEN
    RAISE EXCEPTION 'Only commission credit top-ups are available';
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS prevent_retired_driver_wallet_actions ON public.driver_wallet_requests;
CREATE TRIGGER prevent_retired_driver_wallet_actions
BEFORE INSERT ON public.driver_wallet_requests
FOR EACH ROW EXECUTE FUNCTION public.prevent_retired_driver_wallet_actions();
REVOKE ALL ON FUNCTION public.driver_set_offer_fare(uuid, uuid, numeric)
  FROM PUBLIC, anon, authenticated, service_role;

-- A unique ledger reference makes the registration award safe across retries and
-- later approval status changes. Existing approved accounts are not backfilled.
CREATE OR REPLACE FUNCTION public.award_driver_approval_credit()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE award_id uuid;
BEGIN
  IF NEW.approval_status = 'Approved' AND OLD.approval_status IS DISTINCT FROM 'Approved' THEN
    INSERT INTO public.driver_wallets(driver_id) VALUES (NEW.id) ON CONFLICT DO NOTHING;
    INSERT INTO public.driver_wallet_ledger(driver_id, kind, credit_delta, reference)
      VALUES (NEW.id, 'approval_bonus', 2000, 'approval_bonus:' || NEW.id)
      ON CONFLICT (reference) DO NOTHING RETURNING id INTO award_id;
    IF award_id IS NOT NULL THEN
      UPDATE public.driver_wallets SET commission_credit = commission_credit + 2000,
        updated_at = now() WHERE driver_id = NEW.id;
      INSERT INTO public.app_notifications(app, recipient_id, title, body, type)
        VALUES ('driver', NEW.id, 'Welcome credit added',
          '2,000 ETB commission credit has been added to your wallet.', 'credit_added');
    END IF;
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS award_driver_approval_credit ON public.drivers;
CREATE TRIGGER award_driver_approval_credit
AFTER UPDATE OF approval_status ON public.drivers
FOR EACH ROW EXECUTE FUNCTION public.award_driver_approval_credit();

-- Admin credit grants are one atomic batch. A repeated batch key cannot mint twice.
CREATE OR REPLACE FUNCTION public.admin_grant_driver_credit(
  p_driver_ids uuid[], p_amount numeric, p_note text, p_key uuid
)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE target_id uuid; grant_id uuid; credited integer := 0;
BEGIN
  IF p_key IS NULL OR p_driver_ids IS NULL OR cardinality(p_driver_ids) = 0
    OR cardinality(p_driver_ids) > 2000 THEN
    RAISE EXCEPTION 'Select between 1 and 2000 drivers';
  END IF;
  IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 1000000
    OR p_amount <> round(p_amount, 2) THEN
    RAISE EXCEPTION 'Enter a positive credit amount with at most two decimal places';
  END IF;
  IF length(trim(coalesce(p_note, ''))) < 3 OR length(p_note) > 300 THEN
    RAISE EXCEPTION 'Add a credit reason between 3 and 300 characters';
  END IF;
  FOR target_id IN SELECT DISTINCT unnest(p_driver_ids) LOOP
    IF NOT EXISTS (SELECT 1 FROM public.drivers WHERE id = target_id
      AND approval_status = 'Approved' AND is_active IS NOT FALSE) THEN
      RAISE EXCEPTION 'Credit can only be granted to approved, active drivers';
    END IF;
    INSERT INTO public.driver_wallets(driver_id) VALUES (target_id) ON CONFLICT DO NOTHING;
    INSERT INTO public.driver_wallet_ledger(driver_id, kind, credit_delta, reference)
      VALUES (target_id, 'admin_credit', p_amount,
        'admin_credit:' || p_key || ':' || target_id)
      ON CONFLICT (reference) DO NOTHING RETURNING id INTO grant_id;
    IF grant_id IS NOT NULL THEN
      UPDATE public.driver_wallets SET commission_credit = commission_credit + p_amount,
        updated_at = now() WHERE driver_id = target_id;
      INSERT INTO public.app_notifications(app, recipient_id, title, body, type)
        VALUES ('driver', target_id, 'Commission credit added',
          to_char(p_amount, 'FM999999990.00') || ' ETB was added by dispatch. ' || trim(p_note),
          'credit_added');
      credited := credited + 1;
    END IF;
    grant_id := NULL;
  END LOOP;
  RETURN credited;
END $$;
REVOKE ALL ON FUNCTION public.admin_grant_driver_credit(uuid[], numeric, text, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_grant_driver_credit(uuid[], numeric, text, uuid)
  TO service_role;

-- Wallet requests create an admin inbox item once. Proof uploads may follow the request.
CREATE OR REPLACE FUNCTION public.notify_admin_driver_credit_request()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE driver_name text;
BEGIN
  IF NEW.kind = 'topup' AND NEW.status = 'pending' THEN
    SELECT name INTO driver_name FROM public.drivers WHERE id = NEW.driver_id;
    INSERT INTO public.app_notifications(app, recipient_id, title, body, type)
      VALUES ('admin', NEW.driver_id, 'Credit request',
        coalesce(driver_name, 'A driver') || ' requested ' ||
        to_char(NEW.amount, 'FM999999990.00') || ' ETB commission credit.',
        'wallet_credit_request');
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS notify_admin_driver_credit_request ON public.driver_wallet_requests;
CREATE TRIGGER notify_admin_driver_credit_request
AFTER INSERT ON public.driver_wallet_requests
FOR EACH ROW EXECUTE FUNCTION public.notify_admin_driver_credit_request();

COMMIT;
NOTIFY pgrst, 'reload schema';
