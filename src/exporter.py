from pathlib import Path
import pandas as pd

def export_table(df: pd.DataFrame, output_dir: Path, name: str):
    target = output_dir/'tables'/name
    target.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(target, index=False)
    return target
