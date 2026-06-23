-- Q1.
WITH employee_scores AS (
    SELECT
        employee_id,
        employee_name,
        AVG(customer_satisfaction) AS avg_satisfaction_score
    FROM amazon_support_tickets
    WHERE resolution_status = 'Resolved'
    GROUP BY employee_id, employee_name
),

ranked_employees AS (
    SELECT
        employee_id,
        employee_name,
        avg_satisfaction_score,
        DENSE_RANK() OVER (
            ORDER BY avg_satisfaction_score DESC
        ) AS employee_rank
    FROM employee_scores
)

SELECT
    employee_id,
    employee_name,
    ROUND(avg_satisfaction_score, 2) AS avg_satisfaction_score,
    employee_rank
FROM ranked_employees
WHERE employee_rank <= 3
ORDER BY employee_rank, employee_id;

-- Q2.
WITH ranked_salaries AS (
    SELECT
        department,
        salary,
        DENSE_RANK() OVER (
            PARTITION BY department
            ORDER BY salary DESC
        ) AS salary_rank
    FROM (
        SELECT DISTINCT department, salary
        FROM twitter_employee
    ) t
)

SELECT
    department,
    salary
FROM ranked_salaries
WHERE salary_rank <= 3
ORDER BY department, salary DESC;
