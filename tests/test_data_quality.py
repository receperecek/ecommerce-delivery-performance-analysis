from pathlib import Path
import pandas as pd

def test_quality_output_exists():
    path=Path('outputs/tables/data_quality_summary.csv')
    assert path.exists(), 'Run the pipeline before tests'
    df=pd.read_csv(path)
    assert {'check_name','severity','value','detail'} <= set(df.columns)

def test_no_critical_quality_failures():
    df=pd.read_csv('outputs/tables/data_quality_summary.csv')
    critical=df[(df.severity=='CRITICAL') & (df.value>0)]
    assert critical.empty, critical.to_string()
