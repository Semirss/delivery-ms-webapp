-- Remove only the demo menu records previously shipped by schema v6.
-- User/admin-created marketplace records are left untouched.

DELETE FROM public.food_marketplace_items
WHERE
    (title = 'Simple burger combo' AND seller_phone = '+251 900 000 001')
    OR (title = 'Amrogn crispy chicken' AND seller_phone = '+251 900 000 002')
    OR (title = 'Fresh lunch bowl' AND seller_phone = '+251 900 000 004');

DELETE FROM public.food_restaurants
WHERE slug IN ('simple-pistro', 'amrogn-chiken')
  AND phone IN ('+251 900 000 001', '+251 900 000 002');

DELETE FROM public.food_categories AS category
WHERE category.slug IN (
    'breakfast',
    'chicken',
    'ethiopian',
    'fast-food',
    'home-kitchen'
)
AND NOT EXISTS (
    SELECT 1
    FROM public.food_marketplace_items AS item
    WHERE item.category_id = category.id
);
