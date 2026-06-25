--Q1-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION avg_review_ratings()
RETURNS TABLE (
    mth NUMERIC,
    product INTEGER,
    avg_stars NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        EXTRACT(MONTH FROM submit_date) AS mth,
        product_id AS product,
        ROUND(AVG(stars), 2) AS avg_stars
    FROM reviews
    GROUP BY EXTRACT(MONTH FROM submit_date), product_id
    ORDER BY mth, product;
END;
$$;

--Q2-----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION yoy_growth_rate()
RETURNS TABLE (
    year NUMERIC,
    product_id INTEGER,
    curr_year_spend NUMERIC,
    prev_year_spend NUMERIC,
    yoy_rate NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH yearly_spend AS (
        SELECT
            EXTRACT(YEAR FROM transaction_date) AS year,
            product_id,
            SUM(spend) AS curr_year_spend
        FROM user_transactions
        GROUP BY EXTRACT(YEAR FROM transaction_date), product_id
    ),
    cte AS (
        SELECT
            ys.year,
            ys.product_id,
            ys.curr_year_spend,
            LAG(ys.curr_year_spend) OVER (
                PARTITION BY ys.product_id
                ORDER BY ys.year
            ) AS prev_year_spend
        FROM yearly_spend ys
    )
    SELECT
        c.year,
        c.product_id,
        c.curr_year_spend,
        c.prev_year_spend,
        ROUND(
            ((c.curr_year_spend - c.prev_year_spend) * 100.0 / c.prev_year_spend),
            2
        ) AS yoy_rate
    FROM cte c
    ORDER BY c.year, c.product_id;
END;
$$;
--Q3-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION median_search_frequency()
RETURNS TABLE (
    median NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH cte AS (
        SELECT
            searches,
            num_users,
            SUM(num_users) OVER (ORDER BY searches) AS running_total,
            SUM(num_users) OVER () AS total_users
        FROM search_frequency
    )
    SELECT ROUND(AVG(searches), 1) AS median
    FROM cte
    WHERE running_total >= total_users / 2.0
      AND running_total - num_users < total_users / 2.0 + 1;
END;
$$;
