# Methodology

The pipeline loads source tables into `raw`, creates typed and normalized staging views/tables, aggregates items/payments/reviews before joining, and materializes separate order, order-seller, and order-item facts in `analytics`. Reviews are resolved deterministically by latest answer timestamp, creation date, then review ID. Delivery classification uses calendar dates. Invalid durations are excluded from duration summaries but retained in data-quality outputs. Segment thresholds are loaded from `.env` and shown beside every rate.

Potentially incomplete first and last calendar months are flagged rather than treated as comparable full months. The analysis uses customer state for regional cuts and does not require geolocation.
