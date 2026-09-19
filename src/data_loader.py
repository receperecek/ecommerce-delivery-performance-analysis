from pathlib import Path
import pandas as pd

EXPECTED = {
 'olist_orders_dataset.csv':['order_id','customer_id','order_status','order_purchase_timestamp','order_approved_at','order_delivered_carrier_date','order_delivered_customer_date','order_estimated_delivery_date'],
 'olist_customers_dataset.csv':['customer_id','customer_unique_id','customer_zip_code_prefix','customer_city','customer_state'],
 'olist_order_items_dataset.csv':['order_id','order_item_id','product_id','seller_id','shipping_limit_date','price','freight_value'],
 'olist_order_payments_dataset.csv':['order_id','payment_sequential','payment_type','payment_installments','payment_value'],
 'olist_order_reviews_dataset.csv':['review_id','order_id','review_score','review_comment_title','review_comment_message','review_creation_date','review_answer_timestamp'],
 'olist_products_dataset.csv':['product_id','product_category_name','product_name_lenght','product_description_lenght','product_photos_qty','product_weight_g','product_length_cm','product_height_cm','product_width_cm'],
 'olist_sellers_dataset.csv':['seller_id','seller_zip_code_prefix','seller_city','seller_state'],
 'product_category_name_translation.csv':['product_category_name','product_category_name_english'],
}
DATE_COLS = {'olist_orders_dataset.csv':['order_purchase_timestamp','order_approved_at','order_delivered_carrier_date','order_delivered_customer_date','order_estimated_delivery_date'], 'olist_order_items_dataset.csv':['shipping_limit_date'], 'olist_order_reviews_dataset.csv':['review_creation_date','review_answer_timestamp']}

def load_csvs(raw_dir: Path):
    data, row_counts = {}, {}
    for name, columns in EXPECTED.items():
        path = raw_dir / name
        if not path.exists(): raise FileNotFoundError(f'Missing required source file: {name}')
        df = pd.read_csv(path)
        if list(df.columns) != columns: raise ValueError(f'Header mismatch in {name}')
        for col in DATE_COLS.get(name, []): df[col] = pd.to_datetime(df[col], errors='coerce')
        data[name] = df
        row_counts[name] = len(df)
    optional = raw_dir / 'olist_geolocation_dataset.csv'
    if optional.exists(): row_counts[optional.name] = sum(1 for _ in open(optional, encoding='utf-8')) - 1
    return data, row_counts

def upload_raw(data, engine):
    for name, df in data.items():
        table = name.replace('.csv','').replace('olist_','').replace('product_category_name_translation','category_translation')
        df.to_sql(table, engine, schema='raw', if_exists='replace', index=False, chunksize=5000, method='multi')
