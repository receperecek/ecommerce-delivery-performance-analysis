-- Purpose: produce a concise management handoff from calculated KPIs.
-- Output grain: one row per management priority area; language distinguishes association from causality.
DROP TABLE IF EXISTS analytics.rpt_management_priority_summary;
CREATE TABLE analytics.rpt_management_priority_summary AS
WITH k AS (SELECT metric, value FROM analytics.rpt_executive_kpis)
SELECT 'Delivery rate'::text AS priority_area, ROUND((SELECT value::numeric FROM k WHERE metric = 'late_delivery_rate'), 1)::text || chr(37) || ' late across ' || (SELECT value::bigint FROM k WHERE metric = 'eligible_delivered_orders')::text || ' eligible orders' AS evidence
UNION ALL SELECT 'Value exposure', 'BRL ' || to_char((SELECT value::numeric FROM k WHERE metric = 'at_risk_order_value'), 'FM999999999990.00') || ' at-risk gross order value'
UNION ALL SELECT 'Customer experience', ROUND((SELECT value::numeric FROM k WHERE metric = 'review_score_gap'), 2)::text || ' point observed review gap'
UNION ALL SELECT 'Process investigation', 'Compare processing, shipping, and dispatch SLA patterns, which are operational signals rather than causal proof';
SELECT priority_area, evidence FROM analytics.rpt_management_priority_summary ORDER BY CASE priority_area WHEN 'Delivery rate' THEN 1 WHEN 'Value exposure' THEN 2 WHEN 'Customer experience' THEN 3 ELSE 4 END;
