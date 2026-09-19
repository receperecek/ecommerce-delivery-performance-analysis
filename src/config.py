from dataclasses import dataclass
from pathlib import Path
import os
from dotenv import load_dotenv

@dataclass(frozen=True)
class Config:
    root: Path
    raw_dir: Path
    output_dir: Path
    db_url: str
    min_seller_orders: int
    min_category_orders: int
    min_region_orders: int

    @classmethod
    def from_env(cls, root: Path | None = None):
        root = root or Path.cwd()
        load_dotenv(root / '.env')
        required = ['DB_HOST','DB_PORT','DB_NAME','DB_USER','DB_PASSWORD']
        missing = [k for k in required if not os.getenv(k)]
        if missing:
            raise RuntimeError(f'Missing required environment variables: {", ".join(missing)}')
        raw = Path(os.getenv('RAW_DATA_DIR','data/raw'))
        out = Path(os.getenv('OUTPUT_DIR','outputs'))
        if not raw.is_absolute(): raw = root / raw
        if not out.is_absolute(): out = root / out
        password = os.getenv('DB_PASSWORD')
        from urllib.parse import quote_plus
        url = f"postgresql+psycopg2://{quote_plus(os.getenv('DB_USER'))}:{quote_plus(password)}@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
        return cls(root, raw, out, url, int(os.getenv('MIN_SELLER_ORDERS','30')), int(os.getenv('MIN_CATEGORY_ORDERS','100')), int(os.getenv('MIN_REGION_ORDERS','100')))
