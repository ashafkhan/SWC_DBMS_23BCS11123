--Q1. Acceptance Rate By Date

WITH sent_requests AS (
    SELECT
        date AS sent_date,
        user_id_sender,
        user_id_receiver
    FROM fb_friend_requests
    WHERE action = 'sent'
),

accepted_requests AS (
    SELECT DISTINCT
        user_id_sender,
        user_id_receiver
    FROM fb_friend_requests
    WHERE action = 'accepted'
)

SELECT
    s.sent_date AS date,
    ROUND(
        COUNT(a.user_id_sender)::NUMERIC
        / COUNT(*)::NUMERIC,
        2
    ) AS acceptance_rate
FROM sent_requests s
LEFT JOIN accepted_requests a
    ON s.user_id_sender = a.user_id_sender
   AND s.user_id_receiver = a.user_id_receiver
GROUP BY s.sent_date
HAVING COUNT(a.user_id_sender) > 0
ORDER BY s.sent_date;




--Q2. Daily Revenue

WITH RECURSIVE dates AS (
    SELECT DATE '2025-04-15' AS transaction_date
    UNION ALL
    SELECT transaction_date + INTERVAL '1 day'
    FROM dates
    WHERE transaction_date < DATE '2025-04-28'
),

valid_purchases AS (
    SELECT
        transaction_id,
        transaction_date,
        amount
    FROM product_sales
    WHERE product_id = 'PROD-2891'
      AND country = 'US'
      AND status = 'completed'
      AND type = 'purchase'
      AND transaction_date BETWEEN '2025-04-15' AND '2025-04-28'
),

purchase_revenue AS (
    SELECT
        transaction_date,
        SUM(amount) AS revenue
    FROM valid_purchases
    GROUP BY transaction_date
),

refund_revenue AS (
    SELECT
        r.transaction_date,
        SUM(-r.amount) AS revenue
    FROM product_sales r
    JOIN valid_purchases vp
        ON r.original_transaction_id = vp.transaction_id
    WHERE r.type = 'refund'
      AND r.status = 'completed'
    GROUP BY r.transaction_date
),

combined AS (
    SELECT * FROM purchase_revenue
    UNION ALL
    SELECT * FROM refund_revenue
),

daily_net AS (
    SELECT
        transaction_date,
        SUM(revenue) AS daily_net_revenue
    FROM combined
    GROUP BY transaction_date
)

SELECT
    d.transaction_date,
    COALESCE(n.daily_net_revenue, 0) AS daily_net_revenue
FROM dates d
LEFT JOIN daily_net n
    ON d.transaction_date = n.transaction_date
ORDER BY d.transaction_date;