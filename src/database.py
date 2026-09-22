from sqlalchemy import create_engine, text

def get_engine(config):
    return create_engine(config.db_url, pool_pre_ping=True)

def check_connection(engine):
    with engine.connect() as conn:
        conn.execute(text('SELECT 1'))
