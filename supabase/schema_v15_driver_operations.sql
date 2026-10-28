-- Driver operations migration. Deploy with the matching API and driver app.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE TABLE IF NOT EXISTS public.driver_operations_settings (
  id boolean PRIMARY KEY DEFAULT true CHECK (id),
  commission_percent numeric(5,2) NOT NULL DEFAULT 12 CHECK (commission_percent BETWEEN 0 AND 100),
  rate_note text NOT NULL DEFAULT 'Provisional 12%; current RIDE rate is not verified',
  updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO public.driver_operations_settings(id) VALUES (true) ON CONFLICT DO NOTHING;

ALTER TABLE public.drivers
  ADD COLUMN IF NOT EXISTS working_radius_km numeric(5,1) NOT NULL DEFAULT 5 CHECK (working_radius_km BETWEEN 1 AND 50),
  ADD COLUMN IF NOT EXISTS notifications_enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS location_accuracy_m double precision,
  ADD COLUMN IF NOT EXISTS location_heading double precision,
  ADD COLUMN IF NOT EXISTS location_speed_mps double precision,
  ADD COLUMN IF NOT EXISTS location_received_at timestamptz,
  ADD COLUMN IF NOT EXISTS auth_version integer NOT NULL DEFAULT 1;

-- Keep password hashes out of the public driver records.
CREATE TABLE IF NOT EXISTS public.driver_credentials (
  driver_id uuid PRIMARY KEY REFERENCES public.drivers(id) ON DELETE CASCADE,
  password_hash text NOT NULL
);
INSERT INTO public.driver_credentials(driver_id, password_hash)
SELECT id, CASE WHEN password LIKE '$2%' THEN password
  ELSE extensions.crypt(password, extensions.gen_salt('bf', 12)) END
FROM public.drivers WHERE password IS NOT NULL AND password <> ''
ON CONFLICT DO NOTHING;
ALTER TABLE public.drivers ALTER COLUMN password DROP NOT NULL;
UPDATE public.drivers SET password = NULL WHERE password IS NOT NULL;
CREATE OR REPLACE FUNCTION public.capture_driver_password() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions, pg_temp AS $$
BEGIN
  IF NEW.password IS NOT NULL AND NEW.password <> '' THEN
    INSERT INTO public.driver_credentials(driver_id, password_hash)
    VALUES (NEW.id, extensions.crypt(NEW.password, extensions.gen_salt('bf', 12)))
    ON CONFLICT (driver_id) DO UPDATE SET password_hash = EXCLUDED.password_hash;
    UPDATE public.drivers SET password = NULL, auth_version = auth_version + 1 WHERE id = NEW.id;
  END IF;
  RETURN NULL;
END $$;
DROP TRIGGER IF EXISTS capture_driver_password ON public.drivers;
CREATE TRIGGER capture_driver_password AFTER INSERT OR UPDATE OF password ON public.drivers
FOR EACH ROW EXECUTE FUNCTION public.capture_driver_password();

ALTER TABLE public.deliveries
  ADD COLUMN IF NOT EXISTS accepted_at timestamptz,
  ADD COLUMN IF NOT EXISTS offer_expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS commission_percent numeric(5,2),
  ADD COLUMN IF NOT EXISTS owner_commission numeric(12,2),
  ADD COLUMN IF NOT EXISTS driver_earnings numeric(12,2),
  ADD COLUMN IF NOT EXISTS fee_collection_method text NOT NULL DEFAULT 'cash' CHECK (fee_collection_method IN ('cash', 'platform')),
  ADD COLUMN IF NOT EXISTS platform_payment_reference text,
  ADD COLUMN IF NOT EXISTS payment_confirmed_at timestamptz,
  ADD COLUMN IF NOT EXISTS completed_at timestamptz,
  ADD COLUMN IF NOT EXISTS settled_at timestamptz;

CREATE TABLE IF NOT EXISTS public.driver_wallets (
  driver_id uuid PRIMARY KEY REFERENCES public.drivers(id) ON DELETE RESTRICT,
  commission_credit numeric(12,2) NOT NULL DEFAULT 0 CHECK (commission_credit >= 0),
  earnings_balance numeric(12,2) NOT NULL DEFAULT 0 CHECK (earnings_balance >= 0),
  reserved_credit numeric(12,2) NOT NULL DEFAULT 0 CHECK (reserved_credit BETWEEN 0 AND commission_credit),
  reserved_cashout numeric(12,2) NOT NULL DEFAULT 0 CHECK (reserved_cashout BETWEEN 0 AND earnings_balance),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.driver_wallet_ledger (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL REFERENCES public.driver_wallets(driver_id) ON DELETE RESTRICT,
  delivery_id uuid REFERENCES public.deliveries(id) ON DELETE RESTRICT,
  kind text NOT NULL,
  credit_delta numeric(12,2) NOT NULL DEFAULT 0,
  earnings_delta numeric(12,2) NOT NULL DEFAULT 0,
  owner_commission numeric(12,2) NOT NULL DEFAULT 0,
  reference text UNIQUE NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS driver_ledger_history ON public.driver_wallet_ledger(driver_id, created_at DESC);
CREATE TABLE IF NOT EXISTS public.driver_wallet_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL REFERENCES public.driver_wallets(driver_id) ON DELETE RESTRICT,
  kind text NOT NULL CHECK (kind IN ('topup', 'cashout', 'convert')),
  amount numeric(12,2) NOT NULL CHECK (amount > 0 AND amount <= 1000000),
  method text NOT NULL CHECK (method IN ('telebirr', 'bank', 'earnings')),
  account_name text,
  account_number text,
  bank_name text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'rejected')),
  idempotency_key uuid NOT NULL,
  external_reference text UNIQUE,
  review_note text,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(driver_id, idempotency_key)
);
CREATE INDEX IF NOT EXISTS wallet_request_review ON public.driver_wallet_requests(status, created_at);

-- Financial tables are accessible only through the authenticated server API.
ALTER TABLE public.driver_operations_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_wallet_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_wallet_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.driver_operations_settings, public.driver_credentials, public.driver_wallets,
  public.driver_wallet_ledger, public.driver_wallet_requests FROM anon, authenticated;
GRANT ALL ON public.driver_operations_settings, public.driver_credentials, public.driver_wallets,
  public.driver_wallet_ledger, public.driver_wallet_requests TO service_role;

CREATE OR REPLACE FUNCTION public.verify_driver_password(p_driver_id uuid, p_password text)
RETURNS boolean LANGUAGE sql SECURITY DEFINER SET search_path = public, extensions, pg_temp AS $$
  SELECT EXISTS (SELECT 1 FROM public.driver_credentials WHERE driver_id = p_driver_id
    AND password_hash = extensions.crypt(p_password, password_hash));
$$;

-- Direct legacy writes could forge GPS or mint earnings. Use server routes.
DROP POLICY IF EXISTS "Allow public all on drivers" ON public.drivers;
DROP POLICY IF EXISTS "Allow public all on deliveries" ON public.deliveries;
REVOKE INSERT, UPDATE, DELETE ON public.drivers FROM anon, authenticated;
REVOKE UPDATE, DELETE ON public.deliveries FROM anon, authenticated;
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.admins FROM anon, authenticated;
DROP POLICY IF EXISTS driver_public_read ON public.drivers;
CREATE POLICY driver_public_read ON public.drivers FOR SELECT USING (true);
DROP POLICY IF EXISTS delivery_public_read ON public.deliveries;
CREATE POLICY delivery_public_read ON public.deliveries FOR SELECT USING (true);
DROP POLICY IF EXISTS delivery_pending_insert ON public.deliveries;
CREATE POLICY delivery_pending_insert ON public.deliveries FOR INSERT
WITH CHECK (status = 'Pending' AND driver_id IS NULL AND commission_percent IS NULL
  AND owner_commission IS NULL AND driver_earnings IS NULL AND settled_at IS NULL
  AND accepted_at IS NULL AND payment_confirmed_at IS NULL AND platform_payment_reference IS NULL);

-- Compatibility for existing customer apps: only an unaccepted, unpaid order
-- can be cancelled directly. These grants cannot change fares or create earnings.
GRANT UPDATE(status,driver_id,assigned_at,cancelled_by,cancellation_reason) ON public.deliveries TO anon, authenticated;
DROP POLICY IF EXISTS delivery_customer_cancel ON public.deliveries;
CREATE POLICY delivery_customer_cancel ON public.deliveries FOR UPDATE
USING (status IN ('Pending','Assigned') AND accepted_at IS NULL AND payment_confirmed_at IS NULL AND settled_at IS NULL)
WITH CHECK (status = 'Cancelled' AND driver_id IS NULL AND assigned_at IS NULL AND cancelled_by = 'customer'
  AND accepted_at IS NULL AND payment_confirmed_at IS NULL AND settled_at IS NULL);

CREATE OR REPLACE FUNCTION public.assign_delivery_offer(p_delivery_id uuid, p_driver_id uuid)
RETURNS public.deliveries LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE d public.deliveries; r public.drivers; rate numeric;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(p_driver_id::text, 15));
  SELECT * INTO r FROM public.drivers WHERE id = p_driver_id FOR UPDATE;
  IF NOT FOUND OR r.approval_status <> 'Approved' OR r.is_active IS FALSE OR r.status <> 'Online'
    THEN RAISE EXCEPTION 'Choose an approved, active, online driver'; END IF;
  IF r.last_location_update IS NULL OR r.last_location_update < now() - interval '90 seconds'
    OR r.location_accuracy_m IS NULL OR r.location_accuracy_m > 100
    THEN RAISE EXCEPTION 'Driver needs a fresh GPS fix with accuracy within 100 m'; END IF;
  SELECT * INTO d FROM public.deliveries WHERE id = p_delivery_id FOR UPDATE;
  IF NOT FOUND OR d.status <> 'Pending' THEN RAISE EXCEPTION 'Delivery is no longer pending'; END IF;
  IF d.delivery_fee IS NULL OR d.delivery_fee <= 0 THEN RAISE EXCEPTION 'Set a positive delivery fee first'; END IF;
  IF EXISTS (SELECT 1 FROM public.deliveries WHERE driver_id = p_driver_id AND status IN ('Assigned','Accepted','Picked Up'))
    THEN RAISE EXCEPTION 'Driver already has an active offer or delivery'; END IF;
  SELECT commission_percent INTO rate FROM public.driver_operations_settings WHERE id;
  UPDATE public.deliveries SET driver_id = p_driver_id, status = 'Assigned', assigned_at = now(),
    offer_expires_at = now() + interval '2 minutes', accepted_at = NULL,
    commission_percent = rate, owner_commission = round(delivery_fee * rate / 100, 2),
    driver_earnings = delivery_fee - round(delivery_fee * rate / 100, 2),
    cancelled_by = NULL, cancellation_reason = NULL WHERE id = p_delivery_id RETURNING * INTO d;
  RETURN d;
END $$;

CREATE OR REPLACE FUNCTION public.driver_delivery_action(p_delivery_id uuid, p_driver_id uuid, p_action text)
RETURNS public.deliveries LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE d public.deliveries; w public.driver_wallets;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(p_driver_id::text, 15));
  SELECT * INTO d FROM public.deliveries WHERE id = p_delivery_id FOR UPDATE;
  IF NOT FOUND OR d.driver_id IS DISTINCT FROM p_driver_id THEN RAISE EXCEPTION 'This offer is no longer assigned to you'; END IF;
  IF p_action = 'accept' AND d.status IN ('Accepted','Picked Up','Delivered') THEN RETURN d; END IF;
  IF p_action = 'pickup' AND d.status IN ('Picked Up','Delivered') THEN RETURN d; END IF;
  IF p_action = 'complete' AND d.status = 'Delivered' AND d.settled_at IS NOT NULL THEN RETURN d; END IF;
  INSERT INTO public.driver_wallets(driver_id) VALUES (p_driver_id) ON CONFLICT DO NOTHING;
  SELECT * INTO w FROM public.driver_wallets WHERE driver_id = p_driver_id FOR UPDATE;
  IF p_action IN ('reject','expire') THEN
    IF d.status <> 'Assigned' THEN RAISE EXCEPTION 'Only an unaccepted offer can be returned'; END IF;
    IF p_action = 'expire' AND coalesce(d.offer_expires_at, d.assigned_at + interval '2 minutes') > now()
      THEN RAISE EXCEPTION 'Offer has not expired'; END IF;
    UPDATE public.deliveries SET status = 'Pending', driver_id = NULL, assigned_at = NULL,
      offer_expires_at = NULL, commission_percent = NULL, owner_commission = NULL, driver_earnings = NULL,
      cancelled_by = CASE WHEN p_action = 'expire' THEN 'timeout' ELSE 'driver_reject' END,
      cancellation_reason = CASE WHEN p_action = 'expire' THEN 'Offer expired without acceptance' ELSE 'Driver declined offer' END
      WHERE id = d.id RETURNING * INTO d;
  ELSIF p_action = 'accept' THEN
    IF d.status <> 'Assigned' OR coalesce(d.offer_expires_at, d.assigned_at + interval '2 minutes') <= now()
      THEN RAISE EXCEPTION 'Offer expired. Refresh your assignments'; END IF;
    IF d.commission_percent IS NULL OR d.owner_commission IS NULL THEN RAISE EXCEPTION 'Dispatch must reassign this legacy offer'; END IF;
    IF NOT EXISTS (SELECT 1 FROM public.drivers WHERE id = p_driver_id AND status = 'Online'
      AND approval_status = 'Approved' AND is_active IS NOT FALSE
      AND last_location_update >= now() - interval '90 seconds' AND location_accuracy_m <= 100)
      THEN RAISE EXCEPTION 'Go online with a fresh, accurate GPS fix before accepting'; END IF;
    IF EXISTS (SELECT 1 FROM public.deliveries WHERE driver_id = p_driver_id AND id <> d.id AND status IN ('Accepted','Picked Up'))
      THEN RAISE EXCEPTION 'Finish your current delivery first'; END IF;
    IF d.fee_collection_method = 'cash' THEN
      IF w.commission_credit - w.reserved_credit < d.owner_commission THEN RAISE EXCEPTION 'Top up commission credit before accepting this cash delivery'; END IF;
      UPDATE public.driver_wallets SET reserved_credit = reserved_credit + d.owner_commission, updated_at = now() WHERE driver_id = p_driver_id;
    END IF;
    UPDATE public.deliveries SET status = 'Accepted', accepted_at = now(), cancelled_by = NULL, cancellation_reason = NULL
      WHERE id = d.id RETURNING * INTO d;
  ELSIF p_action = 'pickup' THEN
    IF d.status <> 'Accepted' THEN RAISE EXCEPTION 'Slide to accept before confirming pickup'; END IF;
    UPDATE public.deliveries SET status = 'Picked Up' WHERE id = d.id RETURNING * INTO d;
  ELSIF p_action = 'complete' THEN
    IF d.status <> 'Picked Up' THEN RAISE EXCEPTION 'Confirm pickup before completing delivery'; END IF;
    IF d.owner_commission IS NULL THEN RAISE EXCEPTION 'Dispatch must review this legacy delivery before settlement'; END IF;
    IF d.fee_collection_method = 'platform' AND d.payment_confirmed_at IS NULL
      THEN RAISE EXCEPTION 'Dispatch must verify the platform payment before completion'; END IF;
    IF d.fee_collection_method = 'cash' THEN
      UPDATE public.driver_wallets SET commission_credit = commission_credit - d.owner_commission,
        reserved_credit = reserved_credit - d.owner_commission, updated_at = now() WHERE driver_id = p_driver_id;
    ELSE
      UPDATE public.driver_wallets SET earnings_balance = earnings_balance + d.driver_earnings, updated_at = now() WHERE driver_id = p_driver_id;
    END IF;
    INSERT INTO public.driver_wallet_ledger(driver_id, delivery_id, kind, credit_delta, earnings_delta, owner_commission, reference)
    VALUES (p_driver_id, d.id, CASE WHEN d.fee_collection_method = 'cash' THEN 'cash_trip_commission' ELSE 'trip_earnings' END,
      CASE WHEN d.fee_collection_method = 'cash' THEN -d.owner_commission ELSE 0 END,
      CASE WHEN d.fee_collection_method = 'platform' THEN d.driver_earnings ELSE 0 END,
      d.owner_commission, 'delivery:' || d.id);
    UPDATE public.deliveries SET status = 'Delivered', completed_at = now(), settled_at = now()
      WHERE id = d.id RETURNING * INTO d;
    UPDATE public.drivers SET total_deliveries = coalesce(total_deliveries,0) + 1 WHERE id = p_driver_id;
  ELSE RAISE EXCEPTION 'Unknown delivery action';
  END IF;
  RETURN d;
END $$;

CREATE OR REPLACE FUNCTION public.cancel_delivery_offer(p_delivery_id uuid, p_reason text, p_timeout boolean DEFAULT false)
RETURNS public.deliveries LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE d public.deliveries; driver uuid;
BEGIN
  SELECT driver_id INTO driver FROM public.deliveries WHERE id = p_delivery_id;
  IF driver IS NOT NULL THEN PERFORM pg_advisory_xact_lock(hashtextextended(driver::text, 15)); END IF;
  SELECT * INTO d FROM public.deliveries WHERE id = p_delivery_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Delivery not found'; END IF;
  IF p_timeout THEN
    IF d.status <> 'Assigned' OR coalesce(d.offer_expires_at,d.assigned_at + interval '2 minutes') > now() THEN RETURN d; END IF;
  ELSE
    IF d.status IN ('Delivered','Cancelled') THEN RETURN d; END IF;
    IF length(trim(coalesce(p_reason,''))) < 3 THEN RAISE EXCEPTION 'Cancellation reason is required'; END IF;
    IF d.payment_confirmed_at IS NOT NULL THEN RAISE EXCEPTION 'Resolve the verified payment with support before cancellation'; END IF;
  END IF;
  IF d.status IN ('Accepted','Picked Up') AND d.fee_collection_method = 'cash' THEN
    UPDATE public.driver_wallets SET reserved_credit = reserved_credit - d.owner_commission, updated_at = now() WHERE driver_id = d.driver_id;
  END IF;
  UPDATE public.deliveries SET status = CASE WHEN p_timeout THEN 'Pending' ELSE 'Cancelled' END,
    driver_id = CASE WHEN p_timeout THEN NULL ELSE driver_id END,
    assigned_at = CASE WHEN p_timeout THEN NULL ELSE assigned_at END, offer_expires_at = NULL,
    cancelled_by = CASE WHEN p_timeout THEN 'timeout' ELSE 'admin' END, cancellation_reason = p_reason
    WHERE id = d.id RETURNING * INTO d;
  RETURN d;
END $$;

CREATE OR REPLACE FUNCTION public.expire_driver_offers(p_driver_id uuid DEFAULT NULL)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE r record; expired_count integer := 0;
BEGIN
  FOR r IN SELECT id FROM public.deliveries WHERE status='Assigned'
    AND coalesce(offer_expires_at,assigned_at + interval '2 minutes') <= now()
    AND (p_driver_id IS NULL OR driver_id=p_driver_id) ORDER BY driver_id,id LIMIT 100
  LOOP
    PERFORM public.cancel_delivery_offer(r.id,'Offer expired without acceptance',true);
    expired_count := expired_count + 1;
  END LOOP;
  RETURN expired_count;
END $$;

-- A legacy job is reviewed individually in admin. Never rewrite all active jobs.
CREATE OR REPLACE FUNCTION public.review_legacy_driver_delivery(p_delivery_id uuid, p_action text)
RETURNS public.deliveries LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE d public.deliveries; driver uuid;
BEGIN
  SELECT driver_id INTO driver FROM public.deliveries WHERE id=p_delivery_id;
  IF driver IS NOT NULL THEN PERFORM pg_advisory_xact_lock(hashtextextended(driver::text,15)); END IF;
  SELECT * INTO d FROM public.deliveries WHERE id=p_delivery_id FOR UPDATE;
  IF NOT FOUND OR d.commission_percent IS NOT NULL OR d.settled_at IS NOT NULL OR d.payment_confirmed_at IS NOT NULL
    THEN RAISE EXCEPTION 'This delivery does not require legacy review'; END IF;
  IF p_action='reoffer' AND d.status='Assigned' THEN
    UPDATE public.deliveries SET status='Pending',driver_id=NULL,assigned_at=NULL,offer_expires_at=NULL,
      cancelled_by='admin',cancellation_reason='Legacy offer returned for a fresh quote after admin review'
      WHERE id=d.id RETURNING * INTO d;
  ELSIF p_action='preserve_cash_earnings' AND d.status='Picked Up' AND d.driver_id IS NOT NULL THEN
    IF d.delivery_fee IS NULL OR d.delivery_fee < 0 THEN RAISE EXCEPTION 'Review the original delivery fee with support first'; END IF;
    UPDATE public.deliveries SET commission_percent=0,owner_commission=0,driver_earnings=delivery_fee,
      fee_collection_method='cash' WHERE id=d.id RETURNING * INTO d;
  ELSE RAISE EXCEPTION 'Invalid legacy review action'; END IF;
  RETURN d;
END $$;

CREATE OR REPLACE FUNCTION public.request_driver_wallet(p_driver_id uuid, p_kind text, p_amount numeric,
  p_method text, p_account_name text, p_account_number text, p_bank_name text, p_key uuid)
RETURNS public.driver_wallet_requests LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE w public.driver_wallets; r public.driver_wallet_requests;
BEGIN
  INSERT INTO public.driver_wallets(driver_id) VALUES(p_driver_id) ON CONFLICT DO NOTHING;
  SELECT * INTO w FROM public.driver_wallets WHERE driver_id = p_driver_id FOR UPDATE;
  SELECT * INTO r FROM public.driver_wallet_requests WHERE driver_id = p_driver_id AND idempotency_key = p_key;
  IF FOUND THEN
    IF r.kind <> p_kind OR r.amount <> p_amount OR r.method <> p_method
      OR coalesce(r.account_name,'') <> coalesce(p_account_name,'')
      OR coalesce(r.account_number,'') <> coalesce(p_account_number,'')
      OR coalesce(r.bank_name,'') <> coalesce(p_bank_name,'') THEN RAISE EXCEPTION 'Request key already used for different details'; END IF;
    RETURN r;
  END IF;
  IF p_amount <= 0 OR p_amount > 1000000 OR p_amount <> round(p_amount,2) THEN RAISE EXCEPTION 'Use a positive amount with at most two decimal places'; END IF;
  IF p_kind NOT IN ('topup','cashout','convert') THEN RAISE EXCEPTION 'Invalid request type'; END IF;
  IF p_kind = 'convert' AND p_method <> 'earnings' THEN RAISE EXCEPTION 'Conversion must use earnings'; END IF;
  IF p_kind IN ('cashout','topup') AND p_method NOT IN ('telebirr','bank') THEN RAISE EXCEPTION 'Choose Telebirr or bank'; END IF;
  IF p_kind = 'cashout' AND (length(trim(coalesce(p_account_name,''))) < 2 OR length(trim(coalesce(p_account_number,''))) < 7
    OR (p_method = 'bank' AND length(trim(coalesce(p_bank_name,''))) < 2)) THEN RAISE EXCEPTION 'Enter valid recipient account details'; END IF;
  IF p_kind = 'cashout' AND p_method='telebirr'
    AND coalesce(public.normalize_phone_number(p_account_number),'') !~ '^09[0-9]{8}$'
    THEN RAISE EXCEPTION 'Enter a valid Ethiopian Telebirr phone number'; END IF;
  IF p_kind = 'cashout' AND p_method='bank' AND trim(p_account_number) !~ '^[0-9]{7,34}$'
    THEN RAISE EXCEPTION 'Enter a valid bank account number'; END IF;
  IF p_kind IN ('cashout','convert') AND w.earnings_balance - w.reserved_cashout < p_amount THEN RAISE EXCEPTION 'Insufficient available earnings'; END IF;
  IF p_kind = 'cashout' THEN
    UPDATE public.driver_wallets SET reserved_cashout = reserved_cashout + p_amount, updated_at = now() WHERE driver_id = p_driver_id;
  ELSIF p_kind = 'convert' THEN
    UPDATE public.driver_wallets SET earnings_balance = earnings_balance - p_amount,
      commission_credit = commission_credit + p_amount, updated_at = now() WHERE driver_id = p_driver_id;
    INSERT INTO public.driver_wallet_ledger(driver_id,kind,credit_delta,earnings_delta,reference)
      VALUES(p_driver_id,'earnings_to_credit',p_amount,-p_amount,'convert:' || p_key);
  END IF;
  INSERT INTO public.driver_wallet_requests(driver_id,kind,amount,method,account_name,account_number,bank_name,idempotency_key,status)
    VALUES(p_driver_id,p_kind,p_amount,p_method,p_account_name,p_account_number,p_bank_name,p_key,
      CASE WHEN p_kind = 'convert' THEN 'completed' ELSE 'pending' END) RETURNING * INTO r;
  RETURN r;
END $$;

CREATE OR REPLACE FUNCTION public.review_driver_wallet_request(p_request_id uuid, p_approve boolean, p_reference text, p_note text)
RETURNS public.driver_wallet_requests LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE r public.driver_wallet_requests;
BEGIN
  SELECT * INTO r FROM public.driver_wallet_requests WHERE id = p_request_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Request not found'; END IF;
  IF r.status <> 'pending' THEN
    IF (r.status='completed' AND p_approve AND r.external_reference=trim(p_reference))
      OR (r.status='rejected' AND NOT p_approve) THEN RETURN r; END IF;
    RAISE EXCEPTION 'Request was already reviewed with a different decision or reference';
  END IF;
  IF p_approve AND length(trim(coalesce(p_reference,''))) < 5 THEN RAISE EXCEPTION 'An independently verified payment reference is required'; END IF;
  IF length(trim(coalesce(p_note,''))) < 3 THEN RAISE EXCEPTION 'Add a reconciliation or rejection note'; END IF;
  PERFORM 1 FROM public.driver_wallets WHERE driver_id = r.driver_id FOR UPDATE;
  IF p_approve THEN
    PERFORM pg_advisory_xact_lock(hashtextextended(trim(p_reference), 16));
    IF EXISTS (SELECT 1 FROM public.deliveries WHERE platform_payment_reference = trim(p_reference))
      THEN RAISE EXCEPTION 'Payment reference already reconciled'; END IF;
    IF r.kind = 'topup' THEN
      UPDATE public.driver_wallets SET commission_credit = commission_credit + r.amount, updated_at = now() WHERE driver_id = r.driver_id;
    ELSIF r.kind = 'cashout' THEN
      UPDATE public.driver_wallets SET earnings_balance = earnings_balance - r.amount,
        reserved_cashout = reserved_cashout - r.amount, updated_at = now() WHERE driver_id = r.driver_id;
    ELSE RAISE EXCEPTION 'This request does not need reconciliation'; END IF;
    INSERT INTO public.driver_wallet_ledger(driver_id,kind,credit_delta,earnings_delta,reference)
      VALUES(r.driver_id,r.kind,CASE WHEN r.kind = 'topup' THEN r.amount ELSE 0 END,
        CASE WHEN r.kind = 'cashout' THEN -r.amount ELSE 0 END,'payment:' || trim(p_reference));
  ELSIF r.kind = 'cashout' THEN
    UPDATE public.driver_wallets SET reserved_cashout = reserved_cashout - r.amount, updated_at = now() WHERE driver_id = r.driver_id;
  END IF;
  UPDATE public.driver_wallet_requests SET status = CASE WHEN p_approve THEN 'completed' ELSE 'rejected' END,
    external_reference = CASE WHEN p_approve THEN trim(p_reference) ELSE NULL END,
    review_note = trim(p_note), reviewed_at = now() WHERE id = r.id RETURNING * INTO r;
  RETURN r;
END $$;

CREATE OR REPLACE FUNCTION public.driver_finance_totals()
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path = public, pg_temp AS $$
  SELECT jsonb_build_object('owner_commission', coalesce((SELECT sum(owner_commission) FROM public.driver_wallet_ledger),0),
    'driver_earnings_balance',coalesce((SELECT sum(earnings_balance) FROM public.driver_wallets),0),
    'commission_credit',coalesce((SELECT sum(commission_credit) FROM public.driver_wallets),0),
    'reserved_cashout',coalesce((SELECT sum(reserved_cashout) FROM public.driver_wallets),0));
$$;
CREATE OR REPLACE FUNCTION public.close_driver_account(p_driver_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(p_driver_id::text, 15));
  PERFORM 1 FROM public.drivers WHERE id=p_driver_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Driver account not found'; END IF;
  IF EXISTS (SELECT 1 FROM public.deliveries WHERE driver_id=p_driver_id AND status IN ('Assigned','Accepted','Picked Up'))
    THEN RAISE EXCEPTION 'Finish or cancel active deliveries before closing this account'; END IF;
  PERFORM 1 FROM public.driver_wallets WHERE driver_id=p_driver_id FOR UPDATE;
  IF EXISTS (SELECT 1 FROM public.driver_wallets WHERE driver_id=p_driver_id
    AND (commission_credit<>0 OR earnings_balance<>0 OR reserved_cashout<>0 OR reserved_credit<>0))
    OR EXISTS (SELECT 1 FROM public.driver_wallet_requests WHERE driver_id=p_driver_id AND status='pending')
    THEN RAISE EXCEPTION 'Settle wallet balances and pending requests with support before closing this account'; END IF;
  DELETE FROM public.driver_credentials WHERE driver_id=p_driver_id;
  UPDATE public.drivers SET name='Closed driver account',email=NULL,phone='closed:' || id::text,
    telegram_id=NULL,telegram_username=NULL,plate_number=NULL,personal_id_url=NULL,
    current_lat=NULL,current_lng=NULL,last_location_update=NULL,location_accuracy_m=NULL,
    location_heading=NULL,location_speed_mps=NULL,location_received_at=NULL,
    password=NULL,status='Offline',is_active=false,approval_status='Closed',auth_version=auth_version+1
    WHERE id=p_driver_id;
END $$;
CREATE OR REPLACE FUNCTION public.driver_set_offline(p_driver_id uuid)
RETURNS public.drivers LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE r public.drivers;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(p_driver_id::text, 15));
  IF EXISTS (SELECT 1 FROM public.deliveries WHERE driver_id = p_driver_id AND status IN ('Assigned','Accepted','Picked Up'))
    THEN RAISE EXCEPTION 'Finish or decline your active delivery before going offline'; END IF;
  UPDATE public.drivers SET status = 'Offline' WHERE id = p_driver_id RETURNING * INTO r;
  RETURN r;
END $$;
CREATE OR REPLACE FUNCTION public.confirm_delivery_payment(p_delivery_id uuid, p_reference text)
RETURNS public.deliveries LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE d public.deliveries;
BEGIN
  SELECT * INTO d FROM public.deliveries WHERE id = p_delivery_id FOR UPDATE;
  IF NOT FOUND OR d.fee_collection_method <> 'platform' OR d.status NOT IN ('Assigned','Accepted','Picked Up')
    THEN RAISE EXCEPTION 'Payment verification requires an active platform-collected delivery'; END IF;
  IF d.payment_confirmed_at IS NOT NULL THEN
    IF d.platform_payment_reference <> trim(p_reference) THEN RAISE EXCEPTION 'Payment already reconciled with another reference'; END IF;
    RETURN d;
  END IF;
  IF length(trim(coalesce(p_reference,''))) < 5 THEN RAISE EXCEPTION 'Verified payment reference required'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(trim(p_reference), 16));
  IF EXISTS (SELECT 1 FROM public.deliveries WHERE platform_payment_reference = trim(p_reference))
    OR EXISTS (SELECT 1 FROM public.driver_wallet_requests WHERE external_reference = trim(p_reference))
    THEN RAISE EXCEPTION 'Payment reference already reconciled'; END IF;
  UPDATE public.deliveries SET platform_payment_reference = trim(p_reference), payment_confirmed_at = now()
    WHERE id = d.id RETURNING * INTO d;
  RETURN d;
END $$;
CREATE UNIQUE INDEX IF NOT EXISTS delivery_payment_reference_unique ON public.deliveries(platform_payment_reference)
WHERE platform_payment_reference IS NOT NULL;

-- Supabase grants PUBLIC EXECUTE by default. Do not expose these RPCs.
REVOKE ALL ON FUNCTION public.verify_driver_password(uuid,text), public.assign_delivery_offer(uuid,uuid),
  public.driver_delivery_action(uuid,uuid,text), public.cancel_delivery_offer(uuid,text,boolean),
  public.request_driver_wallet(uuid,text,numeric,text,text,text,text,uuid),
  public.review_driver_wallet_request(uuid,boolean,text,text), public.capture_driver_password(),
  public.driver_finance_totals(), public.expire_driver_offers(uuid), public.review_legacy_driver_delivery(uuid,text),
  public.driver_set_offline(uuid), public.close_driver_account(uuid), public.confirm_delivery_payment(uuid,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_driver_password(uuid,text), public.assign_delivery_offer(uuid,uuid),
  public.driver_delivery_action(uuid,uuid,text), public.cancel_delivery_offer(uuid,text,boolean),
  public.request_driver_wallet(uuid,text,numeric,text,text,text,text,uuid),
  public.review_driver_wallet_request(uuid,boolean,text,text), public.driver_finance_totals(),
  public.confirm_delivery_payment(uuid,text), public.expire_driver_offers(uuid), public.review_legacy_driver_delivery(uuid,text),
  public.driver_set_offline(uuid), public.close_driver_account(uuid) TO service_role;
COMMIT;
NOTIFY pgrst, 'reload schema';
