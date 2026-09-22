from pathlib import Path
import pandas as pd
import numpy as np
from sqlalchemy import text

ABSOLUTE_TOLERANCE = 1e-6
REQUIRED_OUTPUTS = ['executive_kpis.csv','monthly_delivery_performance.csv','process_stage_metrics.csv','delay_review_impact.csv','value_at_risk_summary.csv','seller_priority.csv','category_priority.csv','regional_performance.csv','value_reconciliation_summary.csv','management_priority_summary.csv','data_quality_summary.csv']

def assert_close(a,b,label):
    if not np.isclose(float(a), float(b), atol=ABSOLUTE_TOLERANCE, rtol=0): raise AssertionError(f'{label} mismatch: {a} vs {b}')

def validate_outputs(output_dir: Path, config=None):
    tables = output_dir / 'tables'
    missing = [x for x in REQUIRED_OUTPUTS if not (tables/x).exists()]
    if missing: raise AssertionError(f'Missing required outputs: {missing}')
    kpi = pd.read_csv(tables/'executive_kpis.csv').set_index('metric')['value']
    if float(kpi['early_orders']) + float(kpi['on_time_orders']) + float(kpi['late_orders']) != float(kpi['eligible_delivered_orders']): raise AssertionError('Delivery classification does not reconcile')
    seller = pd.read_csv(tables/'seller_priority.csv')
    category = pd.read_csv(tables/'category_priority.csv')
    region = pd.read_csv(tables/'regional_performance.csv')
    seller_min = config.min_seller_orders if config else 30
    category_min = config.min_category_orders if config else 100
    region_min = config.min_region_orders if config else 100
    if not seller.empty and (seller['eligible_orders'] < seller_min).any(): raise AssertionError('Seller threshold violated')
    if not category.empty and (category['eligible_orders'] < category_min).any(): raise AssertionError('Category threshold violated')
    if not region.empty and (region['eligible_orders'] < region_min).any(): raise AssertionError('Region threshold violated')
    return True

def validate_sql_results(engine, output_dir: Path):
    """Recompute material controls from the SQL fact, independently of report tables."""
    fact = pd.read_sql_query(text('SELECT order_id, eligible, delivery_class, gross_order_value, review_score FROM analytics.fact_order_delivery'), engine)
    eligible = fact[fact['eligible']]
    late = eligible[eligible['delivery_class'].eq('Late')]
    kpi = pd.read_csv(output_dir / 'tables' / 'executive_kpis.csv').set_index('metric')['value']
    if fact['order_id'].duplicated().any(): raise AssertionError('SQL order fact grain violated')
    if len(eligible) != int(kpi['eligible_delivered_orders']): raise AssertionError('SQL eligible order count mismatch')
    if not np.isclose(100 * len(late) / len(eligible), float(kpi['late_delivery_rate']), atol=ABSOLUTE_TOLERANCE, rtol=0): raise AssertionError('SQL late delivery rate mismatch')
    if not np.isclose(late['gross_order_value'].sum(), float(kpi['at_risk_order_value']), atol=ABSOLUTE_TOLERANCE, rtol=0): raise AssertionError('SQL at-risk value mismatch')
    if float(kpi['at_risk_order_value']) > float(kpi['eligible_gross_order_value']): raise AssertionError('At-risk value exceeds eligible gross value')
    seller_reconciliation = pd.read_sql_query(text('SELECT order_id, gross_order_value, seller_attributable_gross_order_value, reconciliation_gap FROM analytics.seller_value_reconciliation WHERE gross_order_value IS NOT NULL'), engine)
    if seller_reconciliation['order_id'].duplicated().any(): raise AssertionError('Seller reconciliation is not one row per order')
    if not np.allclose(seller_reconciliation['reconciliation_gap'], 0, atol=ABSOLUTE_TOLERANCE, rtol=0): raise AssertionError('Seller-attributable item-plus-freight value does not reconcile to order gross value')
