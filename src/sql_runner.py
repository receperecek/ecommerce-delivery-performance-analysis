from pathlib import Path
from sqlalchemy import text

def run_sql_file(engine, path: Path):
    sql = path.read_text(encoding='utf-8')
    with engine.begin() as conn: conn.execute(text(sql))
