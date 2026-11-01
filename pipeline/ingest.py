# Read csv and load into database (raw)
import logging # Show logs
from pathlib import Path # For file paths

import pandas as pd 
from sqlalchemy import text 

from database import get_engine

BASE_DIR = Path(__file__).resolve().parents[1] # Get the base directory
DATA_DIR = BASE_DIR / "data" / "raw" # Get the data directory

TABLES = {
    "olist_orders_dataset.csv": "orders",
    "olist_order_items_dataset.csv": "order_items",
    "olist_customers_dataset.csv": "customers",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "olist_order_payments_dataset.csv": "payments",
    "olist_order_reviews_dataset.csv": "reviews",
    "olist_geolocation_dataset.csv": "geolocation",
    "product_category_name_translation.csv": "category_translation",
}

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
) # Configure logging

def main():
    engine = get_engine()
    
    with engine.begin() as conn: # .begin() autocommits
        conn.execute(text("Create schema if not exists raw;"))
        
        for file_name, table_name in TABLES.items():
            file_path = DATA_DIR / file_name
            
            if not file_path.exists():
                raise FileNotFoundError(f"Missing file: {file_path}")
            
            df = pd.read_csv(file_path)
            df.to_sql(
                name=table_name,
                con=conn,
                schema="raw",
                index=False,
                if_exists="replace",
            )
            
            logging.info(f"Loaded %s into raw.%s: %s rows", file_name, table_name, len(df))
            
            
if __name__ == "__main__":
    main()
            