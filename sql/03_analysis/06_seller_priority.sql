-- Purpose: rank sufficiently large sellers using volume, platform-relative late rate, dispatch SLA, and exposure.
-- Output grain: one row per seller with at least the configured minimum eligible orders; association is not seller causality.
DROP TABLE IF EXISTS analytics.rpt_seller_priority;
CREATE TABLE analytics.rpt_seller_priority AS
WITH seller_metrics AS (
    SELECT seller_id, COUNT(DISTINCT order_id)::integer AS eligible_orders, COUNT(DISTINCT order_id) FILTER (WHERE delivery_class = 'Late')::integer AS late_orders,
           100.0 * COUNT(DISTINCT order_id) FILTER (WHERE delivery_class = 'Late') / NULLIF(COUNT(DISTINCT order_id), 0) AS late_delivery_rate,
           100.0 * COUNT(*) FILTER (WHERE dispatch_sla_breach) / NULLIF(COUNT(*), 0) AS dispatch_sla_breach_rate,
           COUNT(*)::numeric AS median_processing_days, SUM(gross_order_value) FILTER (WHERE delivery_class = 'Late') AS at_risk_order_value
    FROM analytics.fact_order_seller_delivery WHERE eligible GROUP BY seller_id
), reference AS (
    SELECT 100.0 * COUNT(*) FILTER (WHERE delivery_class = 'Late') / NULLIF(COUNT(*), 0) AS platform_late_delivery_rate FROM analytics.fact_order_delivery WHERE eligible
), benchmarks AS (
    SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY dispatch_sla_breach_rate) AS median_dispatch_rate, percentile_cont(0.5) WITHIN GROUP (ORDER BY at_risk_order_value) AS median_at_risk_value FROM seller_metrics
), filtered AS (
    SELECT s.seller_id, s.eligible_orders, s.late_orders, s.late_delivery_rate, s.dispatch_sla_breach_rate, s.median_processing_days, s.at_risk_order_value,
           r.platform_late_delivery_rate, b.median_dispatch_rate, b.median_at_risk_value
    FROM seller_metrics s CROSS JOIN reference r CROSS JOIN benchmarks b CROSS JOIN analytics.pipeline_config c WHERE s.eligible_orders >= c.min_seller_orders
)
SELECT seller_id, eligible_orders, late_orders, late_delivery_rate, dispatch_sla_breach_rate, median_processing_days, at_risk_order_value, platform_late_delivery_rate,
       CASE WHEN late_delivery_rate > platform_late_delivery_rate AND dispatch_sla_breach_rate > median_dispatch_rate AND at_risk_order_value > median_at_risk_value THEN 'Investigate Now'
            WHEN late_delivery_rate > platform_late_delivery_rate OR dispatch_sla_breach_rate > median_dispatch_rate THEN 'Process Watch'
            WHEN late_delivery_rate <= platform_late_delivery_rate THEN 'Stable' ELSE 'Monitor' END AS priority_group
FROM filtered;
SELECT seller_id, eligible_orders, late_orders, late_delivery_rate, dispatch_sla_breach_rate, median_processing_days, at_risk_order_value, platform_late_delivery_rate, priority_group FROM analytics.rpt_seller_priority ORDER BY priority_group, at_risk_order_value DESC;
