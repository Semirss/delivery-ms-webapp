-- Apply after v16. Accept Chrome's standard 150 m location uncertainty for offers.
-- Mobile clients continue to request fixes within 100 m.
BEGIN;
ALTER TABLE public.drivers
  ADD COLUMN IF NOT EXISTS availability_paused boolean NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION public.assign_delivery_offer(p_delivery_id uuid, p_driver_id uuid)
RETURNS public.deliveries LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE d public.deliveries; r public.drivers; rate numeric;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(p_driver_id::text, 15));
  SELECT * INTO r FROM public.drivers WHERE id = p_driver_id FOR UPDATE;
  IF NOT FOUND OR r.approval_status <> 'Approved' OR r.is_active IS FALSE OR r.status <> 'Online'
    THEN RAISE EXCEPTION 'Choose an approved, active, online driver'; END IF;
  IF r.last_location_update IS NULL OR r.last_location_update < now() - interval '90 seconds'
    OR r.location_accuracy_m IS NULL OR r.location_accuracy_m > 200
    THEN RAISE EXCEPTION 'Driver needs a fresh GPS fix with accuracy within 200 m'; END IF;
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
      AND last_location_update >= now() - interval '90 seconds' AND location_accuracy_m <= 200)
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

CREATE OR REPLACE FUNCTION public.driver_set_offline(p_driver_id uuid)
RETURNS public.drivers LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE r public.drivers;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(p_driver_id::text, 15));
  IF EXISTS (SELECT 1 FROM public.deliveries WHERE driver_id = p_driver_id AND status IN ('Assigned','Accepted','Picked Up'))
    THEN RAISE EXCEPTION 'Finish or decline your active delivery before going offline'; END IF;
  UPDATE public.drivers SET status = 'Offline', availability_paused = true
    WHERE id = p_driver_id RETURNING * INTO r;
  RETURN r;
END $$;

-- Preserve the server-only RPC boundary after replacing these functions.
REVOKE ALL ON FUNCTION public.assign_delivery_offer(uuid,uuid),
  public.driver_delivery_action(uuid,uuid,text), public.driver_set_offline(uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.assign_delivery_offer(uuid,uuid),
  public.driver_delivery_action(uuid,uuid,text), public.driver_set_offline(uuid)
  TO service_role;
COMMIT;
NOTIFY pgrst, 'reload schema';
