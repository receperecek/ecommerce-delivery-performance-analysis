import pandas as pd

def test_delivery_classes_reconcile():
    k=pd.read_csv('outputs/tables/executive_kpis.csv').set_index('metric')['value']
    assert k.early_orders+k.on_time_orders+k.late_orders == k.eligible_delivered_orders
    assert 0 <= k.at_risk_order_value <= k.eligible_gross_order_value

def test_reviews_valid():
    d=pd.read_csv('outputs/tables/data_quality_summary.csv').set_index('check_name')
    assert d.loc['review_score_invalid','value']==0

def test_value_reconciliation_exists():
    d=pd.read_csv('outputs/tables/value_reconciliation_summary.csv')
    assert 'value_reconciliation_gap' in set(d.metric)
