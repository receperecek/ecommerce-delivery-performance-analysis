-- Purpose: reset only the project-owned schemas for an idempotent run.
-- Output grain: one configuration row; schemas are containers for later models.
DROP SCHEMA IF EXISTS analytics CASCADE;
DROP SCHEMA IF EXISTS staging CASCADE;
DROP SCHEMA IF EXISTS raw CASCADE;
CREATE SCHEMA raw;
CREATE SCHEMA staging;
CREATE SCHEMA analytics;
CREATE TABLE analytics.pipeline_config (
    config_id integer PRIMARY KEY,
    min_seller_orders integer NOT NULL,
    min_category_orders integer NOT NULL,
    min_region_orders integer NOT NULL
);
INSERT INTO analytics.pipeline_config (config_id, min_seller_orders, min_category_orders, min_region_orders)
VALUES (1, 30, 100, 100);
