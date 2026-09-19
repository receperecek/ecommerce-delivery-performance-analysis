from sqlalchemy import create_engine, text

def get_engine(config):
    return create_engine(config.db_url, pool_pre_ping=True)

def check_connection(engine):
    with engine.connect() as conn:
        conn.execute(text('SELECT 1'))

def reset_schemas(engine):
    with engine.begin() as conn:
        conn.execute(text('DROP SCHEMA IF EXISTS analytics CASCADE'))
        conn.execute(text('DROP SCHEMA IF EXISTS staging CASCADE'))
        conn.execute(text('DROP SCHEMA IF EXISTS raw CASCADE'))
        for schema in ('raw','staging','analytics'):
            conn.execute(text(f'CREATE SCHEMA {schema}'))
