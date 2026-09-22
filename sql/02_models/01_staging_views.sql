-- Purpose: cast raw landing fields and normalize nulls without changing source grain.
-- Output grain: one row per source row in each staging table.
DROP TABLE IF EXISTS staging.orders;
CREATE TABLE staging.orders AS SELECT order_id::text AS order_id, customer_id::text AS customer_id, NULLIF(order_status, '')::text AS order_status, order_purchase_timestamp::timestamp AS order_purchase_timestamp, order_approved_at::timestamp AS order_approved_at, order_delivered_carrier_date::timestamp AS order_delivered_carrier_date, order_delivered_customer_date::timestamp AS order_delivered_customer_date, order_estimated_delivery_date::timestamp AS order_estimated_delivery_date FROM raw.orders;
DROP TABLE IF EXISTS staging.customers;
CREATE TABLE staging.customers AS SELECT customer_id::text AS customer_id, customer_unique_id::text AS customer_unique_id, customer_zip_code_prefix::integer AS customer_zip_code_prefix, NULLIF(customer_city, '')::text AS customer_city, NULLIF(customer_state, '')::text AS customer_state FROM raw.customers;
DROP TABLE IF EXISTS staging.order_items;
CREATE TABLE staging.order_items AS SELECT order_id::text AS order_id, order_item_id::integer AS order_item_id, product_id::text AS product_id, seller_id::text AS seller_id, shipping_limit_date::timestamp AS shipping_limit_date, price::numeric(14,2) AS price, freight_value::numeric(14,2) AS freight_value FROM raw.order_items;
DROP TABLE IF EXISTS staging.order_payments;
CREATE TABLE staging.order_payments AS SELECT order_id::text AS order_id, payment_sequential::integer AS payment_sequential, NULLIF(payment_type, '')::text AS payment_type, payment_installments::integer AS payment_installments, payment_value::numeric(14,2) AS payment_value FROM raw.order_payments;
DROP TABLE IF EXISTS staging.order_reviews;
CREATE TABLE staging.order_reviews AS SELECT review_id::text AS review_id, order_id::text AS order_id, review_score::integer AS review_score, review_creation_date::timestamp AS review_creation_date, review_answer_timestamp::timestamp AS review_answer_timestamp FROM raw.order_reviews;
DROP TABLE IF EXISTS staging.products;
CREATE TABLE staging.products AS SELECT product_id::text AS product_id, product_category_name::text AS product_category_name FROM raw.products;
DROP TABLE IF EXISTS staging.category_translation;
CREATE TABLE staging.category_translation AS SELECT product_category_name::text AS product_category_name, product_category_name_english::text AS product_category_name_english FROM raw.category_translation;
