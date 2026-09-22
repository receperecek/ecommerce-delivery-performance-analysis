-- Purpose: compare high-volume customer states using late rate, shipping-time evidence, reviews, and exposure.
-- Output grain: one row per customer state with at least the configured minimum eligible orders.
DROP TABLE IF EXISTS analytics.rpt_regional_performance;
CREATE TABLE analytics.rpt_regional_performance AS
SELECT customer_state, COUNT(DISTINCT order_id)::integer AS eligible_orders,
       100.0 * COUNT(*) FILTER (WHERE delivery_class = 'Late') / NULLIF(COUNT(*), 0) AS late_delivery_rate,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY shipping_days) AS median_shipping_days,
       SUM(gross_order_value) FILTER (WHERE delivery_class = 'Late') AS at_risk_order_value, AVG(review_score) AS average_review_score
FROM analytics.fact_order_delivery f CROSS JOIN analytics.pipeline_config c
WHERE f.eligible GROUP BY customer_state, c.min_region_orders HAVING COUNT(DISTINCT order_id) >= c.min_region_orders;
SELECT customer_state, eligible_orders, late_delivery_rate, median_shipping_days, at_risk_order_value, average_review_score FROM analytics.rpt_regional_performance ORDER BY at_risk_order_value DESC;
