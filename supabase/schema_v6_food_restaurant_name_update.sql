-- Adds optional restaurant names on food listings for client/admin inserts.

ALTER TABLE public.food_marketplace_items
    ADD COLUMN IF NOT EXISTS restaurant_name TEXT;

UPDATE public.food_marketplace_items AS item
SET restaurant_name = restaurant.name
FROM public.food_restaurants AS restaurant
WHERE item.restaurant_id = restaurant.id
    AND (item.restaurant_name IS NULL OR btrim(item.restaurant_name) = '');
