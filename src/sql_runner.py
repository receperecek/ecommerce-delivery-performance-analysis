from pathlib import Path
from sqlalchemy import text

def split_sql_statements(sql: str) -> list[str]:
    """Split this project's PostgreSQL scripts without breaking quoted semicolons."""
    statements, current, in_quote = [], [], False
    for character in sql:
        if character == "'":
            in_quote = not in_quote
        if character == ';' and not in_quote:
            statement = ''.join(current).strip()
            if statement:
                statements.append(statement)
            current = []
        else:
            current.append(character)
    statement = ''.join(current).strip()
    if statement:
        statements.append(statement)
    return statements

def read_sql_file(path: Path) -> str:
    sql = path.read_text(encoding='utf-8').strip()
    executable = [line for line in sql.splitlines() if line.strip() and not line.lstrip().startswith('--')]
    if not executable:
        raise ValueError(f'SQL file contains no executable statement: {path}')
    return sql

def run_sql_file(connection, path: Path):
    """Execute one inspectable SQL model as supplied, preserving PostgreSQL semantics."""
    statements = []
    executable_sql = '\n'.join(line for line in read_sql_file(path).splitlines() if not line.lstrip().startswith('--'))
    for statement in split_sql_statements(executable_sql):
        candidate = statement.strip()
        executable = [line for line in candidate.splitlines() if line.strip() and not line.lstrip().startswith('--')]
        if executable:
            statements.append(candidate)
    result = None
    for statement in statements:
        result = connection.exec_driver_sql(statement)
    return result

def query_sql_file(connection, path: Path, result_table: str):
    """Execute a model file and return its explicit result-table projection."""
    result = run_sql_file(connection, path)
    return result.mappings().all()
