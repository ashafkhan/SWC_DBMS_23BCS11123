--Q1. Finding User Purchases
WITH first_purchase AS (
    SELECT 
        user_id,
        MIN(created_at) AS first_purchase_date
    FROM amazon_transactions
    GROUP BY user_id
)

SELECT DISTINCT a.user_id
FROM amazon_transactions a
JOIN first_purchase f
    ON a.user_id = f.user_id
WHERE 
    a.created_at > f.first_purchase_date
    AND a.created_at <= f.first_purchase_date + INTERVAL '7 days'
ORDER BY a.user_id;


--Q2. Product Engagement Momentum Shifts
WITH engagement_data AS (
    SELECT
        product_id,
        product_name,
        month_start,
        monthly_active_users,

        LAG(monthly_active_users, 1) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS prev1,

        LAG(monthly_active_users, 2) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS prev2,

        LAG(monthly_active_users, 3) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS prev3,

        LEAD(monthly_active_users, 1) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS next1,

        LEAD(monthly_active_users, 2) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS next2,

        LEAD(monthly_active_users, 3) OVER (
            PARTITION BY product_id
            ORDER BY month_start
        ) AS next3
    FROM product_engagement
),

turnaround AS (
    SELECT
        product_id,
        product_name,
        month_start AS lowest_month,
        monthly_active_users AS lowest_users,
        next3 AS peak_users
    FROM engagement_data
    WHERE
        -- 3 consecutive declining months before current month
        prev3 > prev2
        AND prev2 > prev1
        AND prev1 > monthly_active_users

        -- followed by 3 consecutive growth months
        AND monthly_active_users < next1
        AND next1 < next2
        AND next2 < next3
)

SELECT
    product_name,
    (lowest_month - INTERVAL '3 months')::date AS decline_started,
    (lowest_month + INTERVAL '1 month')::date AS growth_resumed,
    
    ROUND(
        ((peak_users - lowest_users)::numeric / lowest_users),
        2
    ) AS growth_ratio

FROM turnaround
ORDER BY product_name;