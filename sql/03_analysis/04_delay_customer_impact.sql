-- Purpose: associate delivery-delay severity with observed review scores without claiming causality.
-- Output grain: one row per delivery-severity bucket.
DROP TABLE IF EXISTS analytics.rpt_delay_review_impact;
CREATE TABLE analytics.rpt_delay_review_impact AS
WITH bucketed AS (
    SELECT CASE WHEN delay_days < 0 THEN 'Early' WHEN delay_days = 0 THEN 'On Time' WHEN delay_days BETWEEN 1 AND 3 THEN '1-3 Days Late' WHEN delay_days BETWEEN 4 AND 7 THEN '4-7 Days Late' WHEN delay_days BETWEEN 8 AND 14 THEN '8-14 Days Late' WHEN delay_days >= 15 THEN '15+ Days Late' ELSE 'Unknown' END AS severity_bucket, order_id, review_score, low_review
    FROM analytics.fact_order_delivery WHERE eligible
)
SELECT severity_bucket, COUNT(DISTINCT order_id)::integer AS order_count, COUNT(review_score)::integer AS reviewed_order_count, AVG(review_score) AS average_review_score, 100.0 * COUNT(*) FILTER (WHERE low_review) / NULLIF(COUNT(*), 0) AS low_review_rate
FROM bucketed GROUP BY severity_bucket;
SELECT severity_bucket, order_count, reviewed_order_count, average_review_score, low_review_rate FROM analytics.rpt_delay_review_impact ORDER BY CASE severity_bucket WHEN 'Early' THEN 1 WHEN 'On Time' THEN 2 WHEN '1-3 Days Late' THEN 3 WHEN '4-7 Days Late' THEN 4 WHEN '8-14 Days Late' THEN 5 WHEN '15+ Days Late' THEN 6 ELSE 7 END;
