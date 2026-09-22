-- Purpose: compare category delivery performance and item-level financial exposure without assigning a full order to every category.
-- Output grain: one row per category with at least the configured minimum distinct eligible orders.
DROP TABLE IF EXISTS analytics.rpt_category_priority;
CREATE TABLE analytics.rpt_category_priority AS
SELECT category, COUNT(DISTINCT order_id)::integer AS eligible_orders, COUNT(*)::integer AS item_count,
       100.0 * COUNT(*) FILTER (WHERE delivery_class = 'Late') / NULLIF(COUNT(*), 0) AS late_delivery_rate,
       SUM(price) FILTER (WHERE delivery_class = 'Late') AS at_risk_item_value, AVG(review_score) AS average_review_score
FROM analytics.fact_order_item_delivery f CROSS JOIN analytics.pipeline_config c
WHERE f.eligible GROUP BY category, c.min_category_orders HAVING COUNT(DISTINCT order_id) >= c.min_category_orders;
SELECT category, eligible_orders, item_count, late_delivery_rate, at_risk_item_value, average_review_score FROM analytics.rpt_category_priority ORDER BY at_risk_item_value DESC;
