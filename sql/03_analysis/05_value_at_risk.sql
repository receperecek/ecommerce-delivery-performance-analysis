-- Purpose: quantify gross order value exposure among late eligible delivered orders.
-- Output grain: one row for all eligible orders and one row for late eligible orders; this is exposure, not proven loss.
DROP TABLE IF EXISTS analytics.rpt_value_at_risk_summary;
CREATE TABLE analytics.rpt_value_at_risk_summary AS
WITH populations AS (
    SELECT 'Eligible delivered orders'::text AS population, COUNT(*)::integer AS order_count, SUM(gross_order_value) AS gross_order_value FROM analytics.fact_order_delivery WHERE eligible
    UNION ALL SELECT 'Late eligible delivered orders', COUNT(*)::integer, SUM(gross_order_value) FROM analytics.fact_order_delivery WHERE eligible AND delivery_class = 'Late'
)
SELECT population, order_count, gross_order_value, 100.0 * gross_order_value / NULLIF((SELECT gross_order_value FROM populations WHERE population = 'Eligible delivered orders'), 0) AS share_of_eligible_value FROM populations;
SELECT population, order_count, gross_order_value, share_of_eligible_value FROM analytics.rpt_value_at_risk_summary ORDER BY CASE population WHEN 'Eligible delivered orders' THEN 1 ELSE 2 END;
