-- 03_experiment_analysis.sql
-- Descriptive experiment analysis. Synthetic example only.
-- Assumption: assignment is randomized at user level and feature_used is tracked consistently.

WITH user_outcomes AS (
    SELECT
        a.user_id,
        a.experiment_group,
        MAX(CASE WHEN e.event_name = 'feature_used'
                 AND e.event_date >= a.assigned_date
                 AND e.event_date < date(a.assigned_date, '+14 days')
                 THEN 1 ELSE 0 END) AS adopted_feature
    FROM experiment_assignments a
    LEFT JOIN events e ON e.user_id = a.user_id
    GROUP BY a.user_id, a.experiment_group
)
SELECT
    experiment_group,
    COUNT(*) AS assigned_users,
    SUM(adopted_feature) AS users_adopted,
    ROUND(100.0 * SUM(adopted_feature) / NULLIF(COUNT(*), 0), 2) AS adoption_rate_pct
FROM user_outcomes
GROUP BY experiment_group
ORDER BY experiment_group;

-- Interpretation checklist:
-- 1. Compare treatment and control adoption rates.
-- 2. Calculate absolute percentage-point difference and relative lift.
-- 3. In a real experiment, calculate uncertainty (e.g., confidence interval).
-- 4. Check sample ratio mismatch, tracking quality, guardrails, and experiment duration.
-- 5. Do not claim causality unless the experiment design supports it.
