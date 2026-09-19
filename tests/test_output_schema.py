from pathlib import Path
import pandas as pd

EXPECTED=['executive_kpis.csv','monthly_delivery_performance.csv','process_stage_metrics.csv','delay_review_impact.csv','value_at_risk_summary.csv','seller_priority.csv','category_priority.csv','regional_performance.csv','value_reconciliation_summary.csv','management_priority_summary.csv','data_quality_summary.csv']
def test_required_outputs_and_figures():
    for name in EXPECTED: assert Path('outputs/tables',name).exists()
    for i in range(1,7): assert Path('outputs/figures',f'{i:02d}_'+['monthly_delivery_performance','process_stage_duration','review_score_by_delay_severity','seller_priority_matrix','category_priority_matrix','regional_delivery_performance'][i-1]+'.png').exists()

def test_kpi_schema():
    d=pd.read_csv('outputs/tables/executive_kpis.csv')
    assert {'metric','value'} <= set(d.columns)
