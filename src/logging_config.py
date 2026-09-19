import logging
from pathlib import Path

def configure_logging(output_dir: Path):
    (output_dir/'logs').mkdir(parents=True, exist_ok=True)
    logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s', handlers=[logging.FileHandler(output_dir/'logs'/'pipeline.log', encoding='utf-8'), logging.StreamHandler()])
    return logging.getLogger('pipeline')
