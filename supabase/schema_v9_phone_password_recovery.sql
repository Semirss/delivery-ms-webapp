-- Adds phone-based password recovery and phone/email uniqueness enforcement.
-- Run this after schema_v8_play_store_update_urls.sql.

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

DO $$
BEGIN
    IF EXISTS (
        SELECT lower(email)
        FROM public.drivers
        WHERE email IS NOT NULL AND btrim(email) <> ''
        GROUP BY lower(email)
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION 'Duplicate driver emails exist. Clean them before adding the unique index.';
    END IF;

    IF EXISTS (
        SELECT public.normalize_phone_number(phone)
        FROM public.drivers
        WHERE public.normalize_phone_number(phone) IS NOT NULL
        GROUP BY public.normalize_phone_number(phone)
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION 'Duplicate driver phone numbers exist. Clean them before adding the unique index.';
    END IF;

    IF EXISTS (
        SELECT public.normalize_phone_number(phone)
        FROM public.clients
        WHERE public.normalize_phone_number(phone) IS NOT NULL
        GROUP BY public.normalize_phone_number(phone)
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION 'Duplicate client phone numbers exist. Clean them before adding the unique index.';
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS drivers_email_lower_unique
    ON public.drivers (lower(email))
    WHERE email IS NOT NULL AND btrim(email) <> '';

DROP INDEX IF EXISTS public.drivers_phone_unique;
CREATE UNIQUE INDEX IF NOT EXISTS drivers_phone_unique
    ON public.drivers (public.normalize_phone_number(phone))
    WHERE public.normalize_phone_number(phone) IS NOT NULL;

DROP INDEX IF EXISTS public.clients_phone_unique;
CREATE UNIQUE INDEX IF NOT EXISTS clients_phone_unique
    ON public.clients (public.normalize_phone_number(phone))
    WHERE public.normalize_phone_number(phone) IS NOT NULL;

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

GRANT EXECUTE ON FUNCTION public.register_client(TEXT, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reset_client_password_by_phone(TEXT, TEXT) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
