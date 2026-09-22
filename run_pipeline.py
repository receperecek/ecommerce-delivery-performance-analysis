from pathlib import Path
import argparse
import pandas as pd
from sqlalchemy import text

from src.config import Config
from src.database import get_engine, check_connection
from src.data_loader import load_csvs, upload_raw
from src.exporter import export_table
from src.logging_config import configure_logging
from src.sql_runner import run_sql_file, query_sql_file
from src.validation import validate_outputs, validate_sql_results
from src.visualization import make_figures
from src.summary_builder import build_summary

SETUP_FILES = [Path('sql/00_setup/01_create_schemas.sql'), Path('sql/00_setup/02_create_raw_tables.sql')]
MODEL_FILES = [Path('sql/02_models/01_staging_views.sql'), Path('sql/02_models/02_intermediate_models.sql'), Path('sql/02_models/03_analytics_facts.sql')]
ANALYSIS_FILES = [
    (Path('sql/03_analysis/01_executive_kpis.sql'), 'analytics.rpt_executive_kpis', 'executive_kpis.csv'),
    (Path('sql/03_analysis/02_monthly_delivery_trend.sql'), 'analytics.rpt_monthly_delivery_performance', 'monthly_delivery_performance.csv'),
    (Path('sql/03_analysis/03_process_bottleneck.sql'), 'analytics.rpt_process_stage_metrics', 'process_stage_metrics.csv'),
    (Path('sql/03_analysis/04_delay_customer_impact.sql'), 'analytics.rpt_delay_review_impact', 'delay_review_impact.csv'),
    (Path('sql/03_analysis/05_value_at_risk.sql'), 'analytics.rpt_value_at_risk_summary', 'value_at_risk_summary.csv'),
    (Path('sql/03_analysis/06_seller_priority.sql'), 'analytics.rpt_seller_priority', 'seller_priority.csv'),
    (Path('sql/03_analysis/07_category_priority.sql'), 'analytics.rpt_category_priority', 'category_priority.csv'),
    (Path('sql/03_analysis/08_regional_performance.sql'), 'analytics.rpt_regional_performance', 'regional_performance.csv'),
    (Path('sql/03_analysis/09_value_reconciliation.sql'), 'analytics.rpt_value_reconciliation_summary', 'value_reconciliation_summary.csv'),
    (Path('sql/03_analysis/10_management_priority_summary.sql'), 'analytics.rpt_management_priority_summary', 'management_priority_summary.csv'),
]
OUTPUT_COLUMNS = {
    'executive_kpis.csv': ['metric', 'value'],
    'monthly_delivery_performance.csv': ['month', 'eligible_orders', 'late_orders', 'late_delivery_rate', 'median_total_delivery_days', 'at_risk_order_value', 'average_review_score', 'review_coverage'],
    'process_stage_metrics.csv': ['stage', 'valid_order_count', 'median_days', 'p75_days', 'p90_days', 'invalid_duration_count'],
    'delay_review_impact.csv': ['severity_bucket', 'order_count', 'reviewed_order_count', 'average_review_score', 'low_review_rate'],
    'value_at_risk_summary.csv': ['population', 'order_count', 'gross_order_value', 'share_of_eligible_value'],
    'seller_priority.csv': ['seller_id', 'eligible_orders', 'late_orders', 'late_delivery_rate', 'dispatch_sla_breach_rate', 'median_processing_days', 'at_risk_order_value', 'platform_late_delivery_rate', 'priority_group'],
    'category_priority.csv': ['category', 'eligible_orders', 'item_count', 'late_delivery_rate', 'at_risk_item_value', 'average_review_score'],
    'regional_performance.csv': ['customer_state', 'eligible_orders', 'late_delivery_rate', 'median_shipping_days', 'at_risk_order_value', 'average_review_score'],
    'value_reconciliation_summary.csv': ['metric', 'value'],
    'management_priority_summary.csv': ['priority_area', 'evidence'],
}

def validate_required_sql(config: Config):
    required_paths = SETUP_FILES + [Path('sql/01_quality/01_data_quality_profile.sql')] + MODEL_FILES + [x[0] for x in ANALYSIS_FILES]
    for relative_path in required_paths:
        if not (config.root / relative_path).exists():
            raise FileNotFoundError(f'Missing required SQL model: {relative_path}')

def setup_and_load(config: Config):
    engine = get_engine(config)
    check_connection(engine)
    source_data, row_counts = load_csvs(config.raw_dir)
    with engine.begin() as connection:
        for path in SETUP_FILES:
            run_sql_file(connection, config.root / path)
        connection.execute(text('UPDATE analytics.pipeline_config SET min_seller_orders = :seller, min_category_orders = :category, min_region_orders = :region WHERE config_id = 1'), {'seller': config.min_seller_orders, 'category': config.min_category_orders, 'region': config.min_region_orders})
    upload_raw(source_data, engine)
    return engine, row_counts

def run_models(config: Config, engine):
    with engine.begin() as connection:
        for path in MODEL_FILES:
            run_sql_file(connection, config.root / path)

def run_quality(config: Config, engine):
    with engine.begin() as connection:
        quality_result = run_sql_file(connection, config.root / Path('sql/01_quality/01_data_quality_profile.sql'))
        quality_rows = quality_result.mappings().all()
    export_table(pd.DataFrame(quality_rows, columns=['check_name', 'severity', 'value', 'detail']), config.output_dir, 'data_quality_summary.csv')

def run_analysis(config: Config, engine):
    with engine.begin() as connection:
        for path, result_table, output_name in ANALYSIS_FILES:
            rows = query_sql_file(connection, config.root / path, result_table)
            export_table(pd.DataFrame(rows, columns=OUTPUT_COLUMNS[output_name]), config.output_dir, output_name)

def run_pipeline(config: Config, logger, stage: str = 'summary'):
    validate_required_sql(config)
    stage_order = ['load', 'models', 'quality', 'analysis', 'validate', 'visualize', 'summary']
    target_index = stage_order.index(stage)
    engine, row_counts = setup_and_load(config)
    if target_index >= stage_order.index('models'):
        run_models(config, engine)
    if target_index >= stage_order.index('quality'):
        run_quality(config, engine)
    if target_index >= stage_order.index('analysis'):
        run_analysis(config, engine)
    if target_index >= stage_order.index('validate'):
        validate_outputs(config.output_dir, config)
        validate_sql_results(engine, config.output_dir)
    if target_index >= stage_order.index('visualize'):
        make_figures(config.output_dir / 'tables', config.output_dir / 'figures')
    if target_index >= stage_order.index('summary'):
        build_summary(config.output_dir)
    logger.info('SQL-first stage completed successfully: stage=%s source rows=%s', stage, sum(row_counts.values()))

def main():
    parser = argparse.ArgumentParser(description='Run the SQL-first Olist delivery analysis pipeline.')
    parser.add_argument('--stage', choices=['load', 'quality', 'models', 'analysis', 'validate', 'visualize', 'summary'], help='Accepted for reproducible stage-oriented invocation; dependencies are run in deterministic order.')
    args = parser.parse_args()
    config = Config.from_env()
    logger = configure_logging(config.output_dir)
    (config.output_dir / 'tables').mkdir(parents=True, exist_ok=True)
    (config.output_dir / 'figures').mkdir(parents=True, exist_ok=True)
    run_pipeline(config, logger, args.stage or 'summary')

if __name__ == '__main__':
    main()
