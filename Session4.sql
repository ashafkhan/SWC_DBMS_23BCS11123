-- ----------------------------------------Q1--------------------------------------------
CREATE OR REPLACE FUNCTION premium_vs_freemium()
RETURNS TABLE (
    date DATE,
    non_paying_downloads BIGINT,
    paying_downloads BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.date,
        SUM(CASE 
                WHEN a.paying_customer = 'no' 
                THEN d.downloads 
                ELSE 0 
            END) AS non_paying_downloads,

        SUM(CASE 
                WHEN a.paying_customer = 'yes' 
                THEN d.downloads 
                ELSE 0 
            END) AS paying_downloads

    FROM ms_download_facts d
    JOIN ms_user_dimension u
        ON d.user_id = u.user_id
    JOIN ms_acc_dimension a
        ON u.acc_id = a.acc_id

    GROUP BY d.date

    HAVING
        SUM(CASE 
                WHEN a.paying_customer = 'no' 
                THEN d.downloads 
                ELSE 0 
            END)
        >
        SUM(CASE 
                WHEN a.paying_customer = 'yes' 
                THEN d.downloads 
                ELSE 0 
            END)

    ORDER BY d.date;
END;
$$;

-- -----------------Q2---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION minimum_cpus_required()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    result INTEGER;
BEGIN
    /*
      Steps:
      1. Remove duplicates using DISTINCT
      2. Ignore rows with NULL start/end times
      3. Treat:
            start_time  -> +1 CPU needed
            end_time    -> -1 CPU released
      4. If one task ends exactly when another starts,
         process END first using ordering delta ASC
    */

    WITH valid_tasks AS (
        SELECT DISTINCT
            task_id,
            task_name,
            start_time,
            end_time
        FROM task_schedule
        WHERE start_time IS NOT NULL
          AND end_time IS NOT NULL
    ),

    events AS (
        SELECT start_time AS time_point, 1 AS delta
        FROM valid_tasks

        UNION ALL

        SELECT end_time AS time_point, -1 AS delta
        FROM valid_tasks
    ),

    running_cpu AS (
        SELECT
            time_point,
            SUM(delta) OVER (
                ORDER BY time_point, delta ASC
            ) AS active_cpus
        FROM events
    )

    SELECT MAX(active_cpus)
    INTO result
    FROM running_cpu;

    RETURN COALESCE(result, 0);
END;
$$;
