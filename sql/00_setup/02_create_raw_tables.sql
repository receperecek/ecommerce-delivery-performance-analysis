-- Purpose: define typed raw landing tables. CSV loading appends into these tables.
-- Output grain: source grain is preserved; no joins or business calculations occur here.
CREATE TABLE raw.orders (
    order_id text NOT NULL, customer_id text NOT NULL, order_status text,
    order_purchase_timestamp timestamp, order_approved_at timestamp,
    order_delivered_carrier_date timestamp, order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp
);
CREATE TABLE raw.customers (
    customer_id text NOT NULL, customer_unique_id text, customer_zip_code_prefix integer,
    customer_city text, customer_state text
);
CREATE TABLE raw.order_items (
    order_id text NOT NULL, order_item_id integer NOT NULL, product_id text, seller_id text,
    shipping_limit_date timestamp, price numeric(14,2), freight_value numeric(14,2)
);
CREATE TABLE raw.order_payments (
    order_id text NOT NULL, payment_sequential integer NOT NULL, payment_type text,
    payment_installments integer, payment_value numeric(14,2)
);
CREATE TABLE raw.order_reviews (
    review_id text, order_id text, review_score integer, review_comment_title text,
    review_comment_message text, review_creation_date timestamp, review_answer_timestamp timestamp
);
CREATE TABLE raw.products (
    product_id text NOT NULL, product_category_name text, product_name_lenght integer,
    product_description_lenght integer, product_photos_qty integer, product_weight_g numeric,
    product_length_cm numeric, product_height_cm numeric, product_width_cm numeric
);
CREATE TABLE raw.sellers (seller_id text NOT NULL, seller_zip_code_prefix integer, seller_city text, seller_state text);
CREATE TABLE raw.category_translation (product_category_name text, product_category_name_english text);
