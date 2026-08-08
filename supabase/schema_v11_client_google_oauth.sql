-- Lets the mobile client map a completed Google OAuth session to the locked
-- public.clients account table without opening direct client reads.

CREATE OR REPLACE FUNCTION public.get_client_by_email_for_oauth(p_email TEXT)
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

    IF normalized_email IS NULL OR normalized_email = '' THEN
        RAISE EXCEPTION 'Email is required';
    END IF;

    SELECT *
    INTO matched
    FROM public.clients c
    WHERE lower(c.email) = normalized_email
    LIMIT 1;

    IF matched.id IS NULL THEN
        RETURN;
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

GRANT EXECUTE ON FUNCTION public.get_client_by_email_for_oauth(TEXT) TO anon, authenticated;
