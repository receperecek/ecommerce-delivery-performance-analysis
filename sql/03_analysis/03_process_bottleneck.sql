-- Purpose: compare process-stage duration distributions while excluding negative durations from valid metrics.
-- Output grain: one row per process stage; invalid durations remain counted as a warning signal.
DROP TABLE IF EXISTS analytics.rpt_process_stage_metrics;
CREATE TABLE analytics.rpt_process_stage_metrics AS
WITH stages AS (
    SELECT 'Approval'::text AS stage, approval_days AS duration_days FROM analytics.fact_order_delivery WHERE eligible
    UNION ALL SELECT 'Processing', processing_days FROM analytics.fact_order_delivery WHERE eligible
    UNION ALL SELECT 'Shipping', shipping_days FROM analytics.fact_order_delivery WHERE eligible
    UNION ALL SELECT 'Total delivery', total_delivery_days FROM analytics.fact_order_delivery WHERE eligible
)
SELECT stage, COUNT(duration_days) FILTER (WHERE duration_days >= 0)::integer AS valid_order_count,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY duration_days) FILTER (WHERE duration_days >= 0) AS median_days,
       percentile_cont(0.75) WITHIN GROUP (ORDER BY duration_days) FILTER (WHERE duration_days >= 0) AS p75_days,
       percentile_cont(0.9) WITHIN GROUP (ORDER BY duration_days) FILTER (WHERE duration_days >= 0) AS p90_days,
       COUNT(*) FILTER (WHERE duration_days < 0)::integer AS invalid_duration_count
FROM stages GROUP BY stage;
SELECT stage, valid_order_count, median_days, p75_days, p90_days, invalid_duration_count FROM analytics.rpt_process_stage_metrics ORDER BY CASE stage WHEN 'Approval' THEN 1 WHEN 'Processing' THEN 2 WHEN 'Shipping' THEN 3 ELSE 4 END;
