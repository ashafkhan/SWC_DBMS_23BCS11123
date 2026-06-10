---------------------Q1-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
    EXTRACT(MONTH FROM curr.event_date) AS month,
    COUNT(DISTINCT curr.user_id) AS monthly_active_users
FROM user_actions curr
JOIN user_actions prev
    ON curr.user_id = prev.user_id
    AND DATE_TRUNC('month', curr.event_date) 
        = DATE_TRUNC('month', prev.event_date) + INTERVAL '1 month'
WHERE EXTRACT(MONTH FROM curr.event_date) = 7
  AND EXTRACT(YEAR FROM curr.event_date) = 2022
GROUP BY month;
---------------------Q2-----------------------------------------------------------------------------------------------------------------------------------------------
WITH cte AS (
    SELECT 
        transaction_id,
        merchant_id,
        credit_card_id,
        amount,
        transaction_timestamp,
        
        LAG(transaction_timestamp) OVER (
            PARTITION BY merchant_id, credit_card_id, amount
            ORDER BY transaction_timestamp
        ) AS prev_time

    FROM transactions
)

SELECT 
    COUNT(*) AS payment_count
FROM cte
WHERE prev_time IS NOT NULL
AND transaction_timestamp - prev_time <= INTERVAL '10 minutes';
