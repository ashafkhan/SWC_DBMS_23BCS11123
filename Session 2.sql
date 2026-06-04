--Q1. Finding User Purchases
SELECT DISTINCT user_id
FROM (
    SELECT
        user_id,
        created_at,
        LEAD(created_at) OVER (
            PARTITION BY user_id
            ORDER BY created_at
        ) AS next_purchase
    FROM amazon_transactions
) t
WHERE next_purchase > created_at
  AND next_purchase <= created_at + INTERVAL '7 day';