-- Apply after v17. Let the assigned driver set the fare before accepting.
BEGIN;
ALTER TABLE public.deliveries
  ADD COLUMN IF NOT EXISTS driver_set_fare_at timestamptz,
  ADD COLUMN IF NOT EXISTS dispatch_fare_before_driver numeric(12,2);

CREATE OR REPLACE FUNCTION public.driver_set_offer_fare(
  p_delivery_id uuid, p_driver_id uuid, p_fare numeric
)
RETURNS public.deliveries LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp AS $$
DECLARE d public.deliveries; fee numeric(12,2);
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(p_driver_id::text, 15));
  SELECT * INTO d FROM public.deliveries WHERE id = p_delivery_id FOR UPDATE;
  IF NOT FOUND OR d.driver_id IS DISTINCT FROM p_driver_id OR d.status <> 'Assigned'
    THEN RAISE EXCEPTION 'This offer is no longer assigned to you'; END IF;
  IF coalesce(d.offer_expires_at, d.assigned_at + interval '2 minutes') <= now()
    THEN RAISE EXCEPTION 'Offer expired. Refresh your assignments'; END IF;
  IF d.payment_confirmed_at IS NOT NULL OR d.settled_at IS NOT NULL
    THEN RAISE EXCEPTION 'A paid delivery fare cannot be changed'; END IF;
  IF p_fare IS NULL OR p_fare <= 0 OR p_fare > 1000000 OR p_fare <> round(p_fare, 2)
    THEN RAISE EXCEPTION 'Enter a valid fare with up to two decimal places'; END IF;
  IF d.commission_percent IS NULL
    THEN RAISE EXCEPTION 'This offer is out of date. Ask dispatch to send a new offer'; END IF;
  fee := round(p_fare * d.commission_percent / 100, 2);
  UPDATE public.deliveries SET
    dispatch_fare_before_driver = coalesce(dispatch_fare_before_driver, delivery_fee),
    delivery_fee = p_fare,
    owner_commission = fee,
    driver_earnings = p_fare - fee,
    driver_set_fare_at = now()
    WHERE id = d.id RETURNING * INTO d;
  RETURN d;
END $$;

REVOKE ALL ON FUNCTION public.driver_set_offer_fare(uuid,uuid,numeric)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.driver_set_offer_fare(uuid,uuid,numeric)
  TO service_role;
COMMIT;
NOTIFY pgrst, 'reload schema';
