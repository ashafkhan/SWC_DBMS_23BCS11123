------------Q1--------------------------------------------------------------------------------------------------------------------------------------------------------
WITH cte AS (
    SELECT 
        cc.customer_id,
        p.product_category
    FROM customer_contracts cc
    JOIN products p
        ON cc.product_id = p.product_id
)

SELECT 
    customer_id
FROM cte
GROUP BY customer_id
HAVING COUNT(DISTINCT product_category) = (
    SELECT COUNT(DISTINCT product_category)
    FROM products
);
------------Q2--------------------------------------------------------------------------------------------------------------------------------------------------------
WITH cte AS (
    SELECT 
        user_id,
        spend,
        transaction_date,
        
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY transaction_date
        ) AS rn
        
    FROM transactions
)

SELECT 
    user_id,
    spend,
    transaction_date
FROM cte
WHERE rn = 3;
