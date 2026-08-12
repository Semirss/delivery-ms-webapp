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
    normalized_identifier TEXT;
    normalized_email TEXT;
    normalized_phone TEXT;
BEGIN
    normalized_identifier := btrim(coalesce(p_email, ''));
    normalized_email := lower(normalized_identifier);
    normalized_phone := public.normalize_phone_number(normalized_identifier);

    SELECT *
    INTO matched
    FROM public.clients c
    WHERE lower(c.email) = normalized_email
       OR (
            normalized_phone IS NOT NULL
            AND public.normalize_phone_number(c.phone) = normalized_phone
       )
    ORDER BY CASE WHEN lower(c.email) = normalized_email THEN 0 ELSE 1 END
    LIMIT 1;

    IF matched.id IS NULL OR NOT public.verify_client_password(p_password, matched.password_hash) THEN
        RAISE EXCEPTION 'Invalid email/phone or password';
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

GRANT EXECUTE ON FUNCTION public.login_client(TEXT, TEXT) TO anon, authenticated;
