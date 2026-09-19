from pathlib import Path
import json

def test_summary_outputs():
    assert Path('outputs/summary/executive_summary.md').exists()
    payload=json.loads(Path('outputs/summary/analysis_summary.json').read_text())
    assert 'kpis' in payload and 'caveats' in payload
