-- Sets Android app-version update links to the final Play Store package IDs.
UPDATE public.app_versions
SET update_url = 'https://play.google.com/store/apps/details?id=com.motobikedeliveryservice.client'
WHERE app = 'client'
  AND platform = 'android'
  AND btrim(coalesce(update_url, '')) = '';

UPDATE public.app_versions
SET update_url = 'https://play.google.com/store/apps/details?id=com.motobikedeliveryservice.driver'
WHERE app = 'driver'
  AND platform = 'android'
  AND btrim(coalesce(update_url, '')) = '';
