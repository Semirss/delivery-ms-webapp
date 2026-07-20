-- Adds email-based driver login support.
ALTER TABLE public.drivers
    ADD COLUMN IF NOT EXISTS email TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS drivers_email_lower_unique
    ON public.drivers (lower(email))
    WHERE email IS NOT NULL AND btrim(email) <> '';

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

DROP INDEX IF EXISTS public.drivers_phone_unique;
CREATE UNIQUE INDEX IF NOT EXISTS drivers_phone_unique
    ON public.drivers (public.normalize_phone_number(phone))
    WHERE public.normalize_phone_number(phone) IS NOT NULL;
