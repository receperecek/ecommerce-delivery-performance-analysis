from pathlib import Path
import pandas as pd
import re

EXPECTED=['executive_kpis.csv','monthly_delivery_performance.csv','process_stage_metrics.csv','delay_review_impact.csv','value_at_risk_summary.csv','seller_priority.csv','category_priority.csv','regional_performance.csv','value_reconciliation_summary.csv','management_priority_summary.csv','data_quality_summary.csv']
def test_required_outputs_and_figures():
    for name in EXPECTED: assert Path('outputs/tables',name).exists()
    for i in range(1,7): assert Path('outputs/figures',f'{i:02d}_'+['monthly_delivery_performance','process_stage_duration','review_score_by_delay_severity','seller_priority_matrix','category_priority_matrix','regional_delivery_performance'][i-1]+'.png').exists()

def test_kpi_schema():
    d=pd.read_csv('outputs/tables/executive_kpis.csv')
    assert {'metric','value'} <= set(d.columns)

def test_sql_models_are_substantive():
    paths = list(Path('sql/00_setup').glob('*.sql')) + list(Path('sql/01_quality').glob('*.sql')) + list(Path('sql/02_models').glob('*.sql')) + list(Path('sql/03_analysis').glob('*.sql'))
    assert len(paths) == 16
    for path in paths:
        lines=[line.strip() for line in path.read_text(encoding='utf-8').splitlines() if line.strip() and not line.strip().startswith('--')]
        assert lines, f'{path} contains only comments or whitespace'
        assert any(token in ' '.join(lines).upper() for token in ('SELECT','CREATE','DROP','INSERT')), f'{path} has no executable SQL'
        assert not re.search(r'\bSELECT\s+\*', path.read_text(encoding='utf-8'), flags=re.IGNORECASE), f'{path} uses SELECT *'

def test_pipeline_references_sql_source_of_truth():
    code=Path('run_pipeline.py').read_text(encoding='utf-8')
    assert 'run_sql_file' in code and 'query_sql_file' in code
    assert 'sql/03_analysis/01_executive_kpis.sql' in code
    assert 'build_models' not in code and 'make_analyses' not in code
    assert "args.stage or 'summary'" in code
    assert "stage_order = ['load', 'models', 'quality', 'analysis', 'validate', 'visualize', 'summary']" in code

def test_seller_and_category_sql_metric_contracts():
    seller=Path('sql/03_analysis/06_seller_priority.sql').read_text(encoding='utf-8')
    category=Path('sql/03_analysis/07_category_priority.sql').read_text(encoding='utf-8')
    facts=Path('sql/02_models/03_analytics_facts.sql').read_text(encoding='utf-8')
    assert 'percentile_cont(0.5)' in seller and 'ORDER BY processing_days' in seller
    assert 'COUNT(*)::numeric AS median_processing_days' not in seller
    assert 'seller_item_value' in seller and 'seller_freight_value' in seller
    assert 'seller_value_reconciliation' in seller
    assert 'processing_days' in facts
    assert 'COUNT(DISTINCT order_id) FILTER (WHERE delivery_class = \'Late\')' in category
    assert 'SUM(price + freight_value)' in category
