-- Purpose: materialize auditable quality checks before business exports.
-- Output grain: one row per named quality check, with severity and observed value.
DROP TABLE IF EXISTS analytics.data_quality_profile;
CREATE TABLE analytics.data_quality_profile AS
SELECT 'source_orders_row_count'::text AS check_name, 'INFO'::text AS severity, COUNT(*)::numeric AS value, 'raw.orders row count'::text AS detail FROM raw.orders
UNION ALL SELECT 'source_customers_row_count', 'INFO', COUNT(*)::numeric, 'raw.customers row count' FROM raw.customers
UNION ALL SELECT 'source_order_items_row_count', 'INFO', COUNT(*)::numeric, 'raw.order_items row count' FROM raw.order_items
UNION ALL SELECT 'source_order_payments_row_count', 'INFO', COUNT(*)::numeric, 'raw.order_payments row count' FROM raw.order_payments
UNION ALL SELECT 'source_order_reviews_row_count', 'INFO', COUNT(*)::numeric, 'raw.order_reviews row count' FROM raw.order_reviews
UNION ALL SELECT 'source_products_row_count', 'INFO', COUNT(*)::numeric, 'raw.products row count' FROM raw.products
UNION ALL SELECT 'source_sellers_row_count', 'INFO', COUNT(*)::numeric, 'raw.sellers row count' FROM raw.sellers
UNION ALL SELECT 'order_fact_unique_order_id', CASE WHEN COUNT(*) = COUNT(DISTINCT order_id) THEN 'PASS' ELSE 'CRITICAL' END, COUNT(DISTINCT order_id)::numeric, 'one row per order' FROM analytics.fact_order_delivery
UNION ALL SELECT 'order_item_composite_duplicates', CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'CRITICAL' END, COUNT(*)::numeric, 'order_id + order_item_id duplicates' FROM (SELECT order_id, order_item_id FROM raw.order_items GROUP BY order_id, order_item_id HAVING COUNT(*) > 1) duplicate_keys
UNION ALL SELECT 'payment_composite_duplicates', CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'CRITICAL' END, COUNT(*)::numeric, 'order_id + payment_sequential duplicates' FROM (SELECT order_id, payment_sequential FROM raw.order_payments GROUP BY order_id, payment_sequential HAVING COUNT(*) > 1) duplicate_keys
UNION ALL SELECT 'review_multiplicity_orders', 'WARNING', COUNT(*)::numeric, 'orders with more than one source review record' FROM (SELECT order_id FROM raw.order_reviews GROUP BY order_id HAVING COUNT(*) > 1) review_multiplicity
UNION ALL SELECT 'negative_item_values', 'WARNING', COUNT(*)::numeric, 'negative price or freight values' FROM raw.order_items WHERE price < 0 OR freight_value < 0
UNION ALL SELECT 'delivered_missing_delivery_date', 'WARNING', COUNT(*)::numeric, 'delivered orders missing customer-delivery date' FROM raw.orders WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL
UNION ALL SELECT 'invalid_processing_duration', 'WARNING', COUNT(*)::numeric, 'negative approval-to-carrier duration' FROM analytics.fact_order_delivery WHERE processing_days < 0
UNION ALL SELECT 'review_score_invalid', CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'CRITICAL' END, COUNT(*)::numeric, 'review score outside 1 through 5' FROM raw.order_reviews WHERE review_score IS NOT NULL AND review_score NOT BETWEEN 1 AND 5
UNION ALL SELECT 'multi_item_order_rate', 'INFO', 100.0 * COUNT(*) FILTER (WHERE item_count > 1) / NULLIF(COUNT(*), 0), 'percent of orders with more than one item' FROM analytics.fact_order_delivery
UNION ALL SELECT 'multi_seller_order_rate', 'INFO', 100.0 * COUNT(*) FILTER (WHERE seller_count > 1) / NULLIF(COUNT(*), 0), 'percent of orders with more than one seller' FROM analytics.fact_order_delivery
UNION ALL SELECT 'multi_payment_order_rate', 'INFO', 100.0 * COUNT(*) FILTER (WHERE payment_count > 1) / NULLIF(COUNT(*), 0), 'percent of orders with more than one payment' FROM analytics.fact_order_delivery;
SELECT check_name, severity, value, detail FROM analytics.data_quality_profile ORDER BY check_name;
