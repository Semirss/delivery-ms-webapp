-- Apply after schema_v19_driver_credit_and_notifications.sql.
-- Admins may send an offer to an approved online driver while GPS is pending.
-- driver_delivery_action still requires a fresh accurate fix before acceptance.
BEGIN;

CREATE OR REPLACE FUNCTION public.assign_delivery_offer(p_delivery_id uuid, p_driver_id uuid)
RETURNS public.deliveries LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE d public.deliveries; r public.drivers; rate numeric;
  gps_live boolean; gps_unknown boolean;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(p_driver_id::text, 15));
  SELECT * INTO r FROM public.drivers WHERE id = p_driver_id FOR UPDATE;
  IF NOT FOUND OR r.approval_status <> 'Approved' OR r.is_active IS FALSE
    OR r.status <> 'Online' OR r.availability_paused = true
    THEN RAISE EXCEPTION 'Choose an approved, active, online driver'; END IF;
  gps_live := r.current_lat BETWEEN -90 AND 90
    AND r.current_lng BETWEEN -180 AND 180
    AND r.last_location_update BETWEEN now() - interval '90 seconds' AND now() + interval '10 seconds'
    AND r.location_accuracy_m BETWEEN 0 AND 200;
  gps_unknown := r.current_lat IS NULL OR r.current_lng IS NULL
    OR r.last_location_update IS NULL OR r.location_accuracy_m IS NULL;
  IF NOT coalesce(gps_live, false) AND NOT gps_unknown THEN
    RAISE EXCEPTION 'Driver GPS is stale or inaccurate. Wait for a new fix';
  END IF;
  SELECT * INTO d FROM public.deliveries WHERE id = p_delivery_id FOR UPDATE;
  IF NOT FOUND OR d.status <> 'Pending' THEN RAISE EXCEPTION 'Delivery is no longer pending'; END IF;
  IF d.delivery_fee IS NULL OR d.delivery_fee <= 0 THEN RAISE EXCEPTION 'Set a positive delivery fee first'; END IF;
  IF EXISTS (SELECT 1 FROM public.deliveries WHERE driver_id = p_driver_id
    AND status IN ('Assigned','Accepted','Picked Up')) THEN
    RAISE EXCEPTION 'Driver already has an active offer or delivery';
  END IF;
  SELECT commission_percent INTO rate FROM public.driver_operations_settings WHERE id;
  UPDATE public.deliveries SET driver_id = p_driver_id, status = 'Assigned', assigned_at = now(),
    offer_expires_at = now() + interval '2 minutes', accepted_at = NULL,
    commission_percent = rate, owner_commission = round(delivery_fee * rate / 100, 2),
    driver_earnings = delivery_fee - round(delivery_fee * rate / 100, 2),
    cancelled_by = NULL, cancellation_reason = NULL
    WHERE id = p_delivery_id RETURNING * INTO d;
  RETURN d;
END $$;

REVOKE ALL ON FUNCTION public.assign_delivery_offer(uuid, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.assign_delivery_offer(uuid, uuid) TO service_role;
COMMIT;
NOTIFY pgrst, 'reload schema';
