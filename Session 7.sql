-- Q. 1
WITH latest_status AS (
    SELECT
        page_id,
        status,
        ROW_NUMBER() OVER (
            PARTITION BY page_id
            ORDER BY changed_at DESC
        ) AS rn
    FROM page_status_log
)

SELECT COUNT(*) AS active_pages
FROM latest_status
WHERE rn = 1
  AND status = 'active';

-- Q. 2

WITH qualified_channels AS (
    SELECT advertising_channel
    FROM uber_advertising
    GROUP BY advertising_channel
    HAVING MIN(customers_acquired) > 1500
)

SELECT advertising_channel
FROM (
    SELECT
        ua.advertising_channel,
        MAX(ua.money_spent) AS max_yearly_spending
    FROM uber_advertising ua
    JOIN qualified_channels qc
        ON ua.advertising_channel = qc.advertising_channel
    GROUP BY ua.advertising_channel
) t
ORDER BY max_yearly_spending
LIMIT 1;
