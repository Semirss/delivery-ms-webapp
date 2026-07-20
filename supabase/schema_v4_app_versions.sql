-- V4 Schema Updates
-- Central app release policy for mobile force updates and maintenance holds.
-- In-app notifications for live mobile delivery events.
-- Delivery app metadata used by the mobile client.
-- Client table auth for the customer mobile app. This does not use Supabase Auth.

CREATE SCHEMA IF NOT EXISTS extensions;

DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'pgcrypto extension could not be installed; client auth will use the built-in fallback hash.';
    WHEN undefined_file THEN
        RAISE NOTICE 'pgcrypto extension is unavailable; client auth will use the built-in fallback hash.';
END $$;

CREATE TABLE IF NOT EXISTS public.clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    phone TEXT,
    first_name TEXT,
    last_name TEXT,
    password_hash TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Blocked', 'Deleted')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_email_verified BOOLEAN NOT NULL DEFAULT true,
    is_phone_verified BOOLEAN NOT NULL DEFAULT false,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE OR REPLACE FUNCTION public.normalize_phone_number(p_phone TEXT)
RETURNS TEXT AS $$
DECLARE
    digits TEXT;
BEGIN
    digits := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');

    IF digits = '' THEN
        RETURN NULL;
    END IF;

    IF length(digits) = 12
        AND left(digits, 3) = '251'
        AND substring(digits FROM 4 FOR 1) IN ('7', '9') THEN
        RETURN '0' || substring(digits FROM 4);
    END IF;

    IF length(digits) = 9 AND left(digits, 1) IN ('7', '9') THEN
        RETURN '0' || digits;
    END IF;

    IF length(digits) = 10
        AND left(digits, 1) = '0'
        AND substring(digits FROM 2 FOR 1) IN ('7', '9') THEN
        RETURN digits;
    END IF;

    RETURN digits;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE UNIQUE INDEX IF NOT EXISTS clients_email_lower_unique
    ON public.clients (lower(email));

DROP INDEX IF EXISTS public.clients_phone_unique;
CREATE UNIQUE INDEX IF NOT EXISTS clients_phone_unique
    ON public.clients (public.normalize_phone_number(phone))
    WHERE public.normalize_phone_number(phone) IS NOT NULL;

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Deny direct public client reads" ON public.clients;
CREATE POLICY "Deny direct public client reads"
    ON public.clients
    FOR SELECT
    USING (false);

DROP POLICY IF EXISTS "Deny direct public client writes" ON public.clients;
CREATE POLICY "Deny direct public client writes"
    ON public.clients
    FOR ALL
    USING (false)
    WITH CHECK (false);

ALTER TABLE public.deliveries
    ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL;

ALTER TABLE public.deliveries
    ADD COLUMN IF NOT EXISTS service_type TEXT NOT NULL DEFAULT 'parcel';

ALTER TABLE public.deliveries
    ADD COLUMN IF NOT EXISTS payment_method TEXT NOT NULL DEFAULT 'Telebirr';

CREATE TABLE IF NOT EXISTS public.app_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    app TEXT NOT NULL CHECK (app IN ('client', 'driver')),
    platform TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
    minimum_build INTEGER NOT NULL DEFAULT 1 CHECK (minimum_build > 0),
    latest_build INTEGER NOT NULL DEFAULT 1 CHECK (latest_build > 0),
    latest_version TEXT NOT NULL DEFAULT '1.0.0',
    force_update BOOLEAN NOT NULL DEFAULT false,
    update_url TEXT NOT NULL DEFAULT '',
    release_notes TEXT NOT NULL DEFAULT '',
    maintenance_mode BOOLEAN NOT NULL DEFAULT false,
    maintenance_message TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT app_versions_app_platform_unique UNIQUE (app, platform),
    CONSTRAINT app_versions_latest_gte_minimum CHECK (latest_build >= minimum_build)
);

ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read on app_versions" ON public.app_versions;
CREATE POLICY "Allow public read on app_versions"
    ON public.app_versions
    FOR SELECT
    USING (true);

INSERT INTO public.app_versions (
    app,
    platform,
    minimum_build,
    latest_build,
    latest_version,
    force_update,
    update_url,
    release_notes,
    maintenance_mode,
    maintenance_message
) VALUES
    ('client', 'android', 1, 1, '1.0.0', false, 'https://play.google.com/store/apps/details?id=com.motobikedeliveryservice.client', '', false, ''),
    ('client', 'ios', 1, 1, '1.0.0', false, '', '', false, ''),
    ('driver', 'android', 1, 1, '1.0.0', false, 'https://play.google.com/store/apps/details?id=com.motobikedeliveryservice.driver', '', false, ''),
    ('driver', 'ios', 1, 1, '1.0.0', false, '', '', false, '')
ON CONFLICT (app, platform) DO NOTHING;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.hash_client_password(p_password TEXT)
RETURNS TEXT AS $$
DECLARE
    fallback_salt TEXT;
BEGIN
    BEGIN
        RETURN crypt(p_password, gen_salt('bf'));
    EXCEPTION
        WHEN undefined_function THEN
            fallback_salt := md5(random()::text || clock_timestamp()::text || p_password);
            RETURN 'md5$' || fallback_salt || '$' || md5(fallback_salt || p_password);
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

CREATE OR REPLACE FUNCTION public.verify_client_password(
    p_password TEXT,
    p_password_hash TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    fallback_parts TEXT[];
BEGIN
    IF p_password_hash IS NULL OR p_password_hash = '' THEN
        RETURN false;
    END IF;

    IF p_password_hash LIKE 'md5$%' THEN
        fallback_parts := string_to_array(p_password_hash, '$');

        IF array_length(fallback_parts, 1) = 3 THEN
            RETURN p_password_hash = 'md5$' || fallback_parts[2] || '$' || md5(fallback_parts[2] || p_password);
        END IF;

        RETURN p_password_hash = 'md5$' || md5(p_password);
    END IF;

    BEGIN
        RETURN p_password_hash = crypt(p_password, p_password_hash);
    EXCEPTION
        WHEN undefined_function THEN
            RETURN false;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

DROP TRIGGER IF EXISTS set_clients_updated_at ON public.clients;
CREATE TRIGGER set_clients_updated_at
    BEFORE UPDATE ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.register_client(
    p_email TEXT,
    p_password TEXT,
    p_first_name TEXT DEFAULT NULL,
    p_last_name TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    email TEXT,
    phone TEXT,
    first_name TEXT,
    last_name TEXT,
    is_email_verified BOOLEAN,
    is_phone_verified BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    normalized_email TEXT;
    normalized_phone TEXT;
BEGIN
    normalized_email := lower(btrim(p_email));
    normalized_phone := public.normalize_phone_number(p_phone);

    IF normalized_email IS NULL OR normalized_email = '' THEN
        RAISE EXCEPTION 'Email is required';
    END IF;

    IF p_password IS NULL OR length(p_password) < 6 THEN
        RAISE EXCEPTION 'Password must be at least 6 characters';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.clients c
        WHERE lower(c.email) = normalized_email
    ) THEN
        RAISE EXCEPTION 'A client account already exists for this email';
    END IF;

    IF normalized_phone IS NOT NULL AND EXISTS (
        SELECT 1
        FROM public.clients c
        WHERE public.normalize_phone_number(c.phone) = normalized_phone
    ) THEN
        RAISE EXCEPTION 'A client account already exists for this phone number';
    END IF;

    RETURN QUERY
    INSERT INTO public.clients (
        email,
        phone,
        first_name,
        last_name,
        password_hash,
        is_phone_verified
    ) VALUES (
        normalized_email,
        normalized_phone,
        NULLIF(btrim(p_first_name), ''),
        NULLIF(btrim(p_last_name), ''),
        public.hash_client_password(p_password),
        normalized_phone IS NOT NULL
    )
    RETURNING
        clients.id,
        clients.email,
        clients.phone,
        clients.first_name,
        clients.last_name,
        clients.is_email_verified,
        clients.is_phone_verified,
        clients.created_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

CREATE OR REPLACE FUNCTION public.reset_client_password_by_phone(
    p_phone TEXT,
    p_new_password TEXT
)
RETURNS TABLE (
    email TEXT,
    phone TEXT
) AS $$
DECLARE
    normalized_phone TEXT;
    matched public.clients%ROWTYPE;
BEGIN
    normalized_phone := public.normalize_phone_number(p_phone);

    IF normalized_phone IS NULL THEN
        RAISE EXCEPTION 'Phone number is required';
    END IF;

    IF p_new_password IS NULL OR length(p_new_password) < 6 THEN
        RAISE EXCEPTION 'Temporary password must be at least 6 characters';
    END IF;

    SELECT *
    INTO matched
    FROM public.clients c
    WHERE public.normalize_phone_number(c.phone) = normalized_phone
    LIMIT 1;

    IF matched.id IS NULL THEN
        RAISE EXCEPTION 'No client account found for this phone number';
    END IF;

    IF NOT matched.is_active OR matched.status <> 'Active' THEN
        RAISE EXCEPTION 'This client account is not active';
    END IF;

    UPDATE public.clients c
    SET password_hash = public.hash_client_password(p_new_password),
        updated_at = timezone('utc'::text, now())
    WHERE c.id = matched.id;

    RETURN QUERY
    SELECT c.email, c.phone
    FROM public.clients c
    WHERE c.id = matched.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

CREATE OR REPLACE FUNCTION public.login_client(
    p_email TEXT,
    p_password TEXT
)
RETURNS TABLE (
    id UUID,
    email TEXT,
    phone TEXT,
    first_name TEXT,
    last_name TEXT,
    is_email_verified BOOLEAN,
    is_phone_verified BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    matched public.clients%ROWTYPE;
    normalized_email TEXT;
BEGIN
    normalized_email := lower(btrim(p_email));

    SELECT *
    INTO matched
    FROM public.clients c
    WHERE lower(c.email) = normalized_email
    LIMIT 1;

    IF matched.id IS NULL OR NOT public.verify_client_password(p_password, matched.password_hash) THEN
        RAISE EXCEPTION 'Invalid email or password';
    END IF;

    IF NOT matched.is_active OR matched.status <> 'Active' THEN
        RAISE EXCEPTION 'This client account is not active';
    END IF;

    UPDATE public.clients c
    SET last_login_at = timezone('utc'::text, now())
    WHERE c.id = matched.id;

    RETURN QUERY
    SELECT
        matched.id,
        matched.email,
        matched.phone,
        matched.first_name,
        matched.last_name,
        matched.is_email_verified,
        matched.is_phone_verified,
        matched.created_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

GRANT EXECUTE ON FUNCTION public.register_client(TEXT, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.login_client(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reset_client_password_by_phone(TEXT, TEXT) TO anon, authenticated;
REVOKE ALL ON FUNCTION public.hash_client_password(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.verify_client_password(TEXT, TEXT) FROM PUBLIC;

DROP TRIGGER IF EXISTS set_app_versions_updated_at ON public.app_versions;
CREATE TRIGGER set_app_versions_updated_at
    BEFORE UPDATE ON public.app_versions
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.app_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    app TEXT NOT NULL CHECK (app IN ('client', 'driver', 'admin')),
    recipient_id UUID,
    recipient_phone TEXT,
    delivery_id UUID REFERENCES public.deliveries(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'info',
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT app_notifications_has_recipient CHECK (
        recipient_id IS NOT NULL OR recipient_phone IS NOT NULL OR app = 'admin'
    )
);

CREATE INDEX IF NOT EXISTS app_notifications_app_created_idx
    ON public.app_notifications (app, created_at DESC);

CREATE INDEX IF NOT EXISTS app_notifications_recipient_id_idx
    ON public.app_notifications (recipient_id, created_at DESC);

CREATE INDEX IF NOT EXISTS app_notifications_recipient_phone_idx
    ON public.app_notifications (recipient_phone, created_at DESC);

CREATE INDEX IF NOT EXISTS app_notifications_delivery_idx
    ON public.app_notifications (delivery_id);

ALTER TABLE public.app_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read on app_notifications" ON public.app_notifications;
CREATE POLICY "Allow public read on app_notifications"
    ON public.app_notifications
    FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Allow public read receipts on app_notifications" ON public.app_notifications;
CREATE POLICY "Allow public read receipts on app_notifications"
    ON public.app_notifications
    FOR UPDATE
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public feedback inserts on app_notifications" ON public.app_notifications;
CREATE POLICY "Allow public feedback inserts on app_notifications"
    ON public.app_notifications
    FOR INSERT
    WITH CHECK (app = 'admin' AND type = 'client_feedback');

CREATE OR REPLACE FUNCTION public.create_delivery_app_notifications()
RETURNS TRIGGER AS $$
DECLARE
    driver_name TEXT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.app_notifications (
            app,
            recipient_id,
            recipient_phone,
            delivery_id,
            title,
            body,
            type
        ) VALUES (
            'client',
            NEW.client_id,
            NEW.customer_phone,
            NEW.id,
            'Delivery requested',
            'Your delivery request was created and is waiting for dispatch.',
            'delivery_created'
        );

        INSERT INTO public.app_notifications (
            app,
            delivery_id,
            title,
            body,
            type
        ) VALUES (
            'admin',
            NEW.id,
            'New delivery request',
            COALESCE(NEW.customer_name, 'A customer') || ' requested a delivery to ' || COALESCE(NEW.dropoff_location, 'the destination') || '.',
            'delivery_created'
        );

        RETURN NEW;
    END IF;

    IF NEW.driver_id IS DISTINCT FROM OLD.driver_id AND NEW.driver_id IS NOT NULL THEN
        SELECT name INTO driver_name
        FROM public.drivers
        WHERE id = NEW.driver_id;

        INSERT INTO public.app_notifications (
            app,
            recipient_id,
            delivery_id,
            title,
            body,
            type
        ) VALUES (
            'driver',
            NEW.driver_id,
            NEW.id,
            'New delivery assigned',
            'Pickup: ' || COALESCE(NEW.pickup_location, 'Pickup location') || '. Dropoff: ' || COALESCE(NEW.dropoff_location, 'Dropoff location') || '.',
            'delivery_assigned'
        );

        INSERT INTO public.app_notifications (
            app,
            recipient_id,
            recipient_phone,
            delivery_id,
            title,
            body,
            type
        ) VALUES (
            'client',
            NEW.client_id,
            NEW.customer_phone,
            NEW.id,
            'Courier assigned',
            COALESCE(driver_name, 'A courier') || ' has been assigned to your delivery.',
            'delivery_assigned'
        );
    END IF;

    IF NEW.status IS DISTINCT FROM OLD.status AND NEW.status <> 'Assigned' THEN
        INSERT INTO public.app_notifications (
            app,
            recipient_id,
            recipient_phone,
            delivery_id,
            title,
            body,
            type
        ) VALUES (
            'client',
            NEW.client_id,
            NEW.customer_phone,
            NEW.id,
            'Delivery ' || NEW.status,
            CASE NEW.status
                WHEN 'Pending' THEN 'Your delivery is waiting for dispatch.'
                WHEN 'Picked Up' THEN 'Your package has been picked up.'
                WHEN 'Delivered' THEN 'Your delivery has been completed.'
                WHEN 'Cancelled' THEN 'Your delivery was cancelled.'
                ELSE 'Your delivery status changed to ' || NEW.status || '.'
            END,
            'delivery_status'
        );

        IF NEW.driver_id IS NOT NULL THEN
            INSERT INTO public.app_notifications (
                app,
                recipient_id,
                delivery_id,
                title,
                body,
                type
            ) VALUES (
                'driver',
                NEW.driver_id,
                NEW.id,
                'Delivery ' || NEW.status,
                CASE NEW.status
                    WHEN 'Picked Up' THEN 'Pickup confirmed. Continue to the dropoff location.'
                    WHEN 'Delivered' THEN 'Delivery completed. Earnings have been updated.'
                    WHEN 'Cancelled' THEN 'This delivery was cancelled.'
                    ELSE 'Delivery status changed to ' || NEW.status || '.'
                END,
                'delivery_status'
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS create_delivery_app_notifications ON public.deliveries;
CREATE TRIGGER create_delivery_app_notifications
    AFTER INSERT OR UPDATE OF status, driver_id ON public.deliveries
    FOR EACH ROW
    EXECUTE FUNCTION public.create_delivery_app_notifications();

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.app_notifications;
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
END $$;

NOTIFY pgrst, 'reload schema';
