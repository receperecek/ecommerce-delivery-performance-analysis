from pathlib import Path
import pandas as pd
import numpy as np

ABSOLUTE_TOLERANCE = 1e-6
REQUIRED_OUTPUTS = ['executive_kpis.csv','monthly_delivery_performance.csv','process_stage_metrics.csv','delay_review_impact.csv','value_at_risk_summary.csv','seller_priority.csv','category_priority.csv','regional_performance.csv','value_reconciliation_summary.csv','management_priority_summary.csv','data_quality_summary.csv']

def assert_close(a,b,label):
    if not np.isclose(float(a), float(b), atol=ABSOLUTE_TOLERANCE, rtol=0): raise AssertionError(f'{label} mismatch: {a} vs {b}')

def validate_outputs(output_dir: Path):
    tables = output_dir / 'tables'
    missing = [x for x in REQUIRED_OUTPUTS if not (tables/x).exists()]
    if missing: raise AssertionError(f'Missing required outputs: {missing}')
    kpi = pd.read_csv(tables/'executive_kpis.csv').set_index('metric')['value']
    if float(kpi['early_orders']) + float(kpi['on_time_orders']) + float(kpi['late_orders']) != float(kpi['eligible_delivered_orders']): raise AssertionError('Delivery classification does not reconcile')
    seller = pd.read_csv(tables/'seller_priority.csv')
    category = pd.read_csv(tables/'category_priority.csv')
    region = pd.read_csv(tables/'regional_performance.csv')
    if not seller.empty and (seller['eligible_orders'] < 30).any(): raise AssertionError('Seller threshold violated')
    if not category.empty and (category['eligible_orders'] < 100).any(): raise AssertionError('Category threshold violated')
    if not region.empty and (region['eligible_orders'] < 100).any(): raise AssertionError('Region threshold violated')
    return True
