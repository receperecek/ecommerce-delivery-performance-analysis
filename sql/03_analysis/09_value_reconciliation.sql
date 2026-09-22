-- Purpose: reconcile payment value with gross item-plus-freight value for eligible delivered orders.
-- Output grain: one row per reconciliation metric; the gap is diagnostic, not a revised KPI definition.
DROP TABLE IF EXISTS analytics.rpt_value_reconciliation_summary;
CREATE TABLE analytics.rpt_value_reconciliation_summary AS
SELECT 'eligible_gross_order_value'::text AS metric, SUM(gross_order_value)::numeric AS value FROM analytics.fact_order_delivery WHERE eligible
UNION ALL SELECT 'total_payment_value', SUM(total_payment_value)::numeric FROM analytics.fact_order_delivery WHERE eligible
UNION ALL SELECT 'value_reconciliation_gap', SUM(total_payment_value - gross_order_value)::numeric FROM analytics.fact_order_delivery WHERE eligible;
SELECT metric, value FROM analytics.rpt_value_reconciliation_summary ORDER BY CASE metric WHEN 'eligible_gross_order_value' THEN 1 WHEN 'total_payment_value' THEN 2 ELSE 3 END;
