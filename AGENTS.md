# Project operating rules

- Never commit `.env`, credentials, raw CSV/ZIP files, or database passwords.
- Keep the three analytical grains separate: order, order-seller, and order-item.
- Aggregate one-to-many tables before joining to the order fact; never create item-payment multiplication.
- Use the documented delivery KPI contract and preserve audit counts and data-quality warnings.
- At-risk order value is gross value of late delivered orders, an exposure measure—not proven revenue or profit loss.
- Do not make causal claims about sellers, carriers, reviews, or delay.
- Run `python run_pipeline.py` and `pytest -q` before committing.
- Confirm `.env` and `data/raw/*.csv` are ignored and inspect staged diffs before Git operations.
