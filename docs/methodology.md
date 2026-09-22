# Methodology

The pipeline is SQL-first: Python loads the source tables and executes the ordered SQL files in `sql/`, while PostgreSQL owns typed staging, one-to-many aggregation, analytical facts, quality checks, and the ten analysis outputs. Reviews are resolved deterministically by latest answer timestamp, creation date, then review ID. Delivery classification uses calendar dates. Invalid durations are excluded from duration summaries but retained in data-quality outputs. Segment thresholds are loaded from `.env` into `analytics.pipeline_config` and shown beside every rate. Python independently cross-validates the SQL fact and exported KPI results.

Potentially incomplete first and last calendar months are flagged rather than treated as comparable full months. The analysis uses customer state for regional cuts and does not require geolocation.
