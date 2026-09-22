-- Purpose: calculate the executive delivery and value KPIs.
-- Output grain: one row per KPI; at-risk value is gross value exposure, not proven loss.
DROP TABLE IF EXISTS analytics.rpt_executive_kpis;
CREATE TABLE analytics.rpt_executive_kpis AS
WITH eligible AS (SELECT order_id, order_status, delivery_class, delay_days, gross_order_value, review_score FROM analytics.fact_order_delivery WHERE eligible),
late AS (SELECT order_id, order_status, delivery_class, delay_days, gross_order_value, review_score FROM eligible WHERE delivery_class = 'Late'),
stable AS (SELECT COUNT(*)::numeric AS total_orders, COUNT(*) FILTER (WHERE order_status = 'delivered')::numeric AS delivered_orders, COUNT(*) FILTER (WHERE delivery_class = 'Early')::numeric AS early_orders, COUNT(*) FILTER (WHERE delivery_class = 'On Time')::numeric AS on_time_orders, COUNT(*) FILTER (WHERE delivery_class = 'Late')::numeric AS late_orders FROM eligible)
SELECT metric, value FROM (
SELECT 'total_orders'::text AS metric, (SELECT COUNT(*)::numeric FROM analytics.fact_order_delivery) AS value UNION ALL
SELECT 'delivered_orders', (SELECT COUNT(*)::numeric FROM analytics.fact_order_delivery WHERE order_status = 'delivered') UNION ALL
SELECT 'eligible_delivered_orders', COUNT(*)::numeric FROM eligible UNION ALL
SELECT 'early_orders', COUNT(*)::numeric FROM eligible WHERE delivery_class = 'Early' UNION ALL
SELECT 'on_time_orders', COUNT(*)::numeric FROM eligible WHERE delivery_class = 'On Time' UNION ALL
SELECT 'late_orders', COUNT(*)::numeric FROM late UNION ALL
SELECT 'late_delivery_rate', 100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM eligible), 0) FROM late UNION ALL
SELECT 'average_delay_days', AVG(delay_days) FROM late UNION ALL
SELECT 'median_delay_days', percentile_cont(0.5) WITHIN GROUP (ORDER BY delay_days) FROM late UNION ALL
SELECT 'p90_delay_days', percentile_cont(0.9) WITHIN GROUP (ORDER BY delay_days) FROM late UNION ALL
SELECT 'eligible_gross_order_value', SUM(gross_order_value) FROM eligible UNION ALL
SELECT 'at_risk_order_value', SUM(gross_order_value) FROM late UNION ALL
SELECT 'at_risk_order_value_share', 100.0 * (SELECT SUM(gross_order_value) FROM late) / NULLIF((SELECT SUM(gross_order_value) FROM eligible), 0) UNION ALL
SELECT 'on_time_average_review_score', AVG(review_score) FILTER (WHERE delivery_class IN ('Early', 'On Time')) FROM eligible UNION ALL
SELECT 'late_average_review_score', AVG(review_score) FROM late UNION ALL
SELECT 'review_score_gap', (SELECT AVG(review_score) FROM eligible WHERE delivery_class IN ('Early', 'On Time')) - (SELECT AVG(review_score) FROM late) UNION ALL
SELECT 'cancellation_and_unavailable_rate', 100.0 * COUNT(*) FILTER (WHERE order_status IN ('canceled','unavailable')) / NULLIF(COUNT(*), 0) FROM analytics.fact_order_delivery UNION ALL
SELECT 'delivery_timestamp_coverage', 100.0 * COUNT(*) FILTER (WHERE order_delivered_customer_date IS NOT NULL) / NULLIF(COUNT(*), 0) FROM analytics.fact_order_delivery UNION ALL
SELECT 'review_coverage_rate', 100.0 * COUNT(*) FILTER (WHERE review_score IS NOT NULL) / NULLIF(COUNT(*), 0) FROM eligible
) kpis;
SELECT metric, value FROM analytics.rpt_executive_kpis ORDER BY CASE metric WHEN 'total_orders' THEN 1 WHEN 'delivered_orders' THEN 2 ELSE 3 END, metric;
