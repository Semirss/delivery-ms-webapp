-- Apply after schema_v20_pending_gps_dispatch.sql.
-- Keep delivery notifications for assignment and completion only.
-- Credit and admin-authored messages use separate notification paths.
BEGIN;

CREATE OR REPLACE FUNCTION public.create_delivery_app_notifications()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE driver_name text; assigned_now boolean := false; delivered_now boolean := false;
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.app_notifications(app, delivery_id, title, body, type)
    VALUES ('admin', NEW.id, 'New delivery request',
      coalesce(NEW.customer_name, 'A customer') || ' requested a delivery to ' ||
      coalesce(NEW.dropoff_location, 'the destination') || '.', 'delivery_created');
    assigned_now := NEW.status = 'Assigned' AND NEW.driver_id IS NOT NULL;
  ELSE
    assigned_now := NEW.status = 'Assigned' AND NEW.driver_id IS NOT NULL
      AND (NEW.driver_id IS DISTINCT FROM OLD.driver_id
        OR OLD.status IS DISTINCT FROM 'Assigned');
    delivered_now := NEW.status = 'Delivered' AND OLD.status IS DISTINCT FROM 'Delivered';
  END IF;

  IF assigned_now THEN
    SELECT name INTO driver_name FROM public.drivers WHERE id = NEW.driver_id;
    INSERT INTO public.app_notifications(app, recipient_id, delivery_id, title, body, type)
    VALUES ('driver', NEW.driver_id, NEW.id, 'New delivery assigned',
      'Pickup: ' || coalesce(NEW.pickup_location, 'Pickup location') ||
      '. Dropoff: ' || coalesce(NEW.dropoff_location, 'Dropoff location') || '.',
      'delivery_assigned');
    INSERT INTO public.app_notifications(
      app, recipient_id, recipient_phone, delivery_id, title, body, type)
    VALUES ('client', NEW.client_id, NEW.customer_phone, NEW.id, 'Courier assigned',
      coalesce(driver_name, 'A courier') || ' has been assigned to your delivery.',
      'delivery_assigned');
  END IF;

  IF delivered_now THEN
    INSERT INTO public.app_notifications(
      app, recipient_id, recipient_phone, delivery_id, title, body, type)
    VALUES ('client', NEW.client_id, NEW.customer_phone, NEW.id,
      'Delivery completed', 'Your delivery has been completed.', 'delivery_status');
    IF NEW.driver_id IS NOT NULL THEN
      INSERT INTO public.app_notifications(
        app, recipient_id, delivery_id, title, body, type)
      VALUES ('driver', NEW.driver_id, NEW.id, 'Delivery completed',
        'Delivery completed. Earnings have been updated.', 'delivery_status');
    END IF;
  END IF;
  RETURN NEW;
END $$;

COMMIT;
NOTIFY pgrst, 'reload schema';
