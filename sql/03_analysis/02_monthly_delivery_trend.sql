-- Purpose: show monthly eligible volume, late performance, duration, exposure, and reviews.
-- Output grain: one row per purchase month; boundary months should be interpreted cautiously.
DROP TABLE IF EXISTS analytics.rpt_monthly_delivery_performance;
CREATE TABLE analytics.rpt_monthly_delivery_performance AS
SELECT TO_CHAR(DATE_TRUNC('month', order_purchase_timestamp), 'YYYY-MM') AS month,
       COUNT(*)::integer AS eligible_orders, COUNT(*) FILTER (WHERE delivery_class = 'Late')::integer AS late_orders,
       100.0 * COUNT(*) FILTER (WHERE delivery_class = 'Late') / NULLIF(COUNT(*), 0) AS late_delivery_rate,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY total_delivery_days) AS median_total_delivery_days,
       SUM(gross_order_value) FILTER (WHERE delivery_class = 'Late') AS at_risk_order_value,
       AVG(review_score) AS average_review_score, 100.0 * COUNT(review_score) / NULLIF(COUNT(*), 0) AS review_coverage
FROM analytics.fact_order_delivery WHERE eligible GROUP BY DATE_TRUNC('month', order_purchase_timestamp);
SELECT month, eligible_orders, late_orders, late_delivery_rate, median_total_delivery_days, at_risk_order_value, average_review_score, review_coverage FROM analytics.rpt_monthly_delivery_performance ORDER BY month;
