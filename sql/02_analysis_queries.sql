-- 02_analysis_queries.sql
-- Run each query separately in SQLite after loading the schema and CSV data.

-- 1. Overall payment success rate (attempt-level metric).
SELECT
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) AS successful_attempts,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS payment_success_rate_pct
FROM payments;

-- 2. Daily payment success rate.
SELECT
    payment_date,
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) AS successful_attempts,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS success_rate_pct
FROM payments
GROUP BY payment_date
ORDER BY payment_date;

-- 3. Payment success rate by payment type.
SELECT
    payment_type,
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) AS successful_attempts,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS success_rate_pct
FROM payments
GROUP BY payment_type
ORDER BY success_rate_pct DESC;

-- 4. Failed payment reasons.
SELECT
    COALESCE(failure_reason, 'Not specified') AS failure_reason,
    COUNT(*) AS failed_attempts,
    ROUND(100.0 * COUNT(*) /
        NULLIF((SELECT COUNT(*) FROM payments WHERE status = 'failed'), 0), 2
    ) AS share_of_failures_pct
FROM payments
WHERE status = 'failed'
GROUP BY COALESCE(failure_reason, 'Not specified')
ORDER BY failed_attempts DESC;

-- 5. Activation by signup cohort.
-- Activation is defined as at least one first_successful_payment event
-- within 7 days (inclusive) after signup.
WITH activation AS (
    SELECT
        u.user_id,
        u.signup_date,
        MAX(CASE
            WHEN e.event_name = 'first_successful_payment'
             AND julianday(e.event_date) - julianday(u.signup_date) BETWEEN 0 AND 7
            THEN 1 ELSE 0
        END) AS activated_within_7d
    FROM users u
    LEFT JOIN events e ON e.user_id = u.user_id
    GROUP BY u.user_id, u.signup_date
)
SELECT
    signup_date,
    COUNT(*) AS signed_up_users,
    SUM(activated_within_7d) AS activated_users,
    ROUND(100.0 * SUM(activated_within_7d) / NULLIF(COUNT(*), 0), 2) AS activation_rate_pct
FROM activation
GROUP BY signup_date
ORDER BY signup_date;

-- 6. Strict D7 retention by signup cohort.
-- A retained user must have any recorded event exactly 7 calendar days after signup.
WITH user_d7 AS (
    SELECT
        u.user_id,
        u.signup_date,
        MAX(CASE
            WHEN e.event_date = date(u.signup_date, '+7 days') THEN 1 ELSE 0
        END) AS retained_d7
    FROM users u
    LEFT JOIN events e ON e.user_id = u.user_id
    GROUP BY u.user_id, u.signup_date
)
SELECT
    signup_date,
    COUNT(*) AS cohort_users,
    SUM(retained_d7) AS retained_users_d7,
    ROUND(100.0 * SUM(retained_d7) / NULLIF(COUNT(*), 0), 2) AS d7_retention_pct
FROM user_d7
GROUP BY signup_date
ORDER BY signup_date;

-- 7. Monthly active users (event-based definition).
SELECT
    strftime('%Y-%m', event_date) AS activity_month,
    COUNT(DISTINCT user_id) AS monthly_active_users
FROM events
GROUP BY strftime('%Y-%m', event_date)
ORDER BY activity_month;

-- 8. Payment volume and amount by platform.
SELECT
    u.platform,
    COUNT(p.payment_id) AS payment_attempts,
    ROUND(SUM(CASE WHEN p.status = 'success' THEN p.amount_eur ELSE 0 END), 2)
        AS successful_payment_amount_eur
FROM users u
LEFT JOIN payments p ON p.user_id = u.user_id
GROUP BY u.platform
ORDER BY successful_payment_amount_eur DESC;

-- 9. Investigate whether payment failures are concentrated by platform and type.
SELECT
    u.platform,
    p.payment_type,
    COUNT(*) AS attempts,
    SUM(CASE WHEN p.status = 'failed' THEN 1 ELSE 0 END) AS failed_attempts,
    ROUND(100.0 * SUM(CASE WHEN p.status = 'failed' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2) AS failure_rate_pct
FROM payments p
JOIN users u ON u.user_id = p.user_id
GROUP BY u.platform, p.payment_type
ORDER BY failure_rate_pct DESC, attempts DESC;

-- 10. Data quality checks: duplicate event IDs, orphan payments, missing failure reasons.
SELECT 'duplicate_event_ids' AS check_name, COUNT(*) AS issue_count
FROM (
    SELECT event_id FROM events GROUP BY event_id HAVING COUNT(*) > 1
)
UNION ALL
SELECT 'orphan_payments', COUNT(*)
FROM payments p LEFT JOIN users u ON p.user_id = u.user_id
WHERE u.user_id IS NULL
UNION ALL
SELECT 'failed_payments_without_reason', COUNT(*)
FROM payments
WHERE status = 'failed' AND (failure_reason IS NULL OR TRIM(failure_reason) = '');
