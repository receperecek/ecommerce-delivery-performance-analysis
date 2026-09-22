-- Purpose: materialize separate order, order-seller, and order-item analytical grains.
-- Output grains: one row per order; one row per order-seller; one row per order item.
DROP TABLE IF EXISTS analytics.fact_order_delivery;
CREATE TABLE analytics.fact_order_delivery AS
SELECT o.order_id, o.customer_id, c.customer_unique_id, c.customer_state, o.order_status, o.order_purchase_timestamp, o.order_approved_at, o.order_delivered_carrier_date, o.order_delivered_customer_date, o.order_estimated_delivery_date,
       i.gross_product_value, i.total_freight_value, i.gross_order_value, COALESCE(i.item_row_count, 0)::integer AS item_row_count, COALESCE(i.item_count, 0)::integer AS item_count, COALESCE(i.seller_count, 0)::integer AS seller_count,
       COALESCE(p.total_payment_value, 0)::numeric(14,2) AS total_payment_value, COALESCE(p.payment_row_count, 0)::integer AS payment_row_count, COALESCE(p.payment_count, 0)::integer AS payment_count, COALESCE(r.review_record_count, 0)::integer AS review_record_count,
       r.review_id, r.review_score, r.review_creation_date, r.review_answer_timestamp,
       (o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL) AS eligible,
       (o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date)::integer AS delay_days,
       CASE WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL THEN CASE WHEN o.order_delivered_customer_date::date < o.order_estimated_delivery_date::date THEN 'Early' WHEN o.order_delivered_customer_date::date = o.order_estimated_delivery_date::date THEN 'On Time' ELSE 'Late' END ELSE 'Not Eligible' END AS delivery_class,
       EXTRACT(EPOCH FROM (o.order_approved_at - o.order_purchase_timestamp)) / 86400.0 AS approval_days, EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_approved_at)) / 86400.0 AS processing_days, EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_delivered_carrier_date)) / 86400.0 AS shipping_days, EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0 AS total_delivery_days, (r.review_score <= 2) AS low_review
FROM staging.orders o LEFT JOIN staging.customers c ON c.customer_id = o.customer_id LEFT JOIN analytics.int_order_item_summary i ON i.order_id = o.order_id LEFT JOIN analytics.int_order_payment_summary p ON p.order_id = o.order_id LEFT JOIN analytics.int_order_review_resolved r ON r.order_id = o.order_id;
DROP TABLE IF EXISTS analytics.fact_order_seller_delivery;
CREATE TABLE analytics.fact_order_seller_delivery AS
SELECT oi.order_id, oi.seller_id, MIN(oi.shipping_limit_date) AS seller_shipping_limit_date, COUNT(DISTINCT oi.order_item_id)::integer AS item_count, SUM(oi.price)::numeric(14,2) AS seller_item_value, SUM(oi.freight_value)::numeric(14,2) AS seller_freight_value, f.eligible, f.delivery_class, f.delay_days, f.gross_order_value, f.review_score, f.order_delivered_carrier_date, (f.order_delivered_carrier_date > MIN(oi.shipping_limit_date)) AS dispatch_sla_breach
FROM staging.order_items oi JOIN analytics.fact_order_delivery f ON f.order_id = oi.order_id GROUP BY oi.order_id, oi.seller_id, f.eligible, f.delivery_class, f.delay_days, f.gross_order_value, f.review_score, f.order_delivered_carrier_date;
DROP TABLE IF EXISTS analytics.fact_order_item_delivery;
CREATE TABLE analytics.fact_order_item_delivery AS
SELECT oi.order_id, oi.order_item_id, oi.product_id, oi.seller_id, oi.shipping_limit_date, oi.price, oi.freight_value, p.product_category_name, COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category, f.customer_state, f.order_status, f.eligible, f.delivery_class, f.delay_days, f.gross_order_value, f.review_score
FROM staging.order_items oi LEFT JOIN staging.products p ON p.product_id = oi.product_id LEFT JOIN staging.category_translation t ON t.product_category_name = p.product_category_name LEFT JOIN analytics.fact_order_delivery f ON f.order_id = oi.order_id;
