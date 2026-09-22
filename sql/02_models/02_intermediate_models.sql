-- Purpose: aggregate one-to-many inputs before any order-level join.
-- Output grain: one row per order for each intermediate summary.
DROP TABLE IF EXISTS analytics.int_order_item_summary;
CREATE TABLE analytics.int_order_item_summary AS SELECT order_id, SUM(price)::numeric(14,2) AS gross_product_value, SUM(freight_value)::numeric(14,2) AS total_freight_value, SUM(price + freight_value)::numeric(14,2) AS gross_order_value, COUNT(*)::integer AS item_row_count, COUNT(DISTINCT order_item_id)::integer AS item_count, COUNT(DISTINCT seller_id)::integer AS seller_count FROM staging.order_items GROUP BY order_id;
DROP TABLE IF EXISTS analytics.int_order_payment_summary;
CREATE TABLE analytics.int_order_payment_summary AS SELECT order_id, SUM(payment_value)::numeric(14,2) AS total_payment_value, COUNT(*)::integer AS payment_row_count, COUNT(DISTINCT payment_sequential)::integer AS payment_count FROM staging.order_payments GROUP BY order_id;
DROP TABLE IF EXISTS analytics.int_order_review_resolved;
CREATE TABLE analytics.int_order_review_resolved AS
WITH ranked_reviews AS (
    SELECT review_id, order_id, review_score, review_creation_date, review_answer_timestamp, COUNT(*) OVER (PARTITION BY order_id)::integer AS review_record_count,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC NULLS LAST, review_creation_date DESC NULLS LAST, review_id DESC) AS review_rank
    FROM staging.order_reviews
)
SELECT order_id, review_id, review_score, review_creation_date, review_answer_timestamp, review_record_count FROM ranked_reviews WHERE review_rank = 1;
