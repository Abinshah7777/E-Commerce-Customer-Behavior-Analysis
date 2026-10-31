"""
================================================================================
DATA INGESTION, DYNAMIC UPLOAD & COLUMN STANDARDIZATION PIPELINE
Project: E-Commerce Customer Behavior Analysis
Author: Big Data Analytics Mini Project Team
================================================================================

This module provides a unified data ingestion framework supporting:
1. Direct ingestion of real-world Kaggle datasets (UCI Online Retail & Brazilian Olist).
2. Dynamic file upload interfaces:
   - Standalone Python Script: CLI flags (`argparse`) + interactive fallback (`input()`).
   - Jupyter Notebook: Interactive widget (`ipywidgets.FileUpload`).
   - Google Colab: Native upload prompt (`google.colab.files.upload()`).
3. Automated column standardization immediately after loading into canonical schema:
   ['CustomerID', 'InvoiceID', 'InvoiceDate', 'Quantity', 'UnitPrice', 'TotalAmount', 'Description', 'Country']
4. Downstream RFM (Recency, Frequency, Monetary) transformation for clustering and predictive modeling.
"""

import os
import sys
import io
import argparse
from datetime import datetime
from typing import Optional, Dict, Tuple, List, Union
import pandas as pd
import numpy as np


# ==============================================================================
# 1. CANONICAL SCHEMA & DATASET PRESETS
# ==============================================================================

CANONICAL_COLUMNS: Dict[str, str] = {
    "CustomerID": "Unique identifier for customer (alphanumeric or integer)",
    "InvoiceID": "Unique identifier for transaction / invoice / order",
    "InvoiceDate": "Timestamp or calendar date of transaction",
    "Quantity": "Quantity of items purchased in transaction",
    "UnitPrice": "Individual item price / unit price (currency unit)",
    "TotalAmount": "Total transaction monetary spend (Quantity * UnitPrice)",
    "Description": "Product / item description or category (optional)",
    "Country": "Customer or store country / location (optional)"
}

DATASET_PRESETS: Dict[str, Dict[str, str]] = {
    # Kaggle: "E-Commerce Data" (UCI Machine Learning Repository / Online Retail)
    # URL: https://www.kaggle.com/datasets/carrie1/ecommerce-data
    "uci_online_retail": {
        "CustomerID": "CustomerID",
        "InvoiceNo": "InvoiceID",
        "InvoiceDate": "InvoiceDate",
        "Quantity": "Quantity",
        "UnitPrice": "UnitPrice",
        "Description": "Description",
        "Country": "Country"
    },
    # Kaggle: "Brazilian E-Commerce Public Dataset by Olist"
    # URL: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
    "brazilian_olist": {
        "customer_unique_id": "CustomerID",
        "order_id": "InvoiceID",
        "order_purchase_timestamp": "InvoiceDate",
        "order_item_id": "Quantity",
        "price": "UnitPrice",
        "product_category_name": "Description",
        "customer_state": "Country"
    },
    # Generic synonym dictionary for automatic column name detection
    "generic": {
        "customer_id": "CustomerID",
        "customerid": "CustomerID",
        "client_id": "CustomerID",
        "user_id": "CustomerID",
        "account_id": "CustomerID",
        "buyer_id": "CustomerID",
        "invoice_id": "InvoiceID",
        "invoiceno": "InvoiceID",
        "invoice_no": "InvoiceID",
        "order_id": "InvoiceID",
        "orderid": "InvoiceID",
        "transaction_id": "InvoiceID",
        "invoice_date": "InvoiceDate",
        "invoicedate": "InvoiceDate",
        "order_date": "InvoiceDate",
        "orderdate": "InvoiceDate",
        "date": "InvoiceDate",
        "timestamp": "InvoiceDate",
        "qty": "Quantity",
        "quantity": "Quantity",
        "units": "Quantity",
        "price": "UnitPrice",
        "unit_price": "UnitPrice",
        "unitprice": "UnitPrice",
        "item_price": "UnitPrice",
        "total": "TotalAmount",
        "total_amount": "TotalAmount",
        "totalamount": "TotalAmount",
        "total_spend": "TotalAmount",
        "total_spend_usd": "TotalAmount",
        "spending": "TotalAmount",
        "monetary": "TotalAmount",
        "amount": "TotalAmount",
        "item_description": "Description",
        "description": "Description",
        "product_name": "Description",
        "product": "Description",
        "country": "Country",
        "state": "Country",
        "region": "Country"
    }
}


# ==============================================================================
# 2. ROBUST FILE LOADER WITH ENCODING FALLBACKS
# ==============================================================================

def load_dataset(file_path: str, encoding: Optional[str] = None) -> pd.DataFrame:
    """
    Loads a dataset from CSV or Excel file.
    Tries multiple candidate encodings automatically (vital for Kaggle UCI data containing latin1 characters).
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"[ERROR] File not found: '{file_path}'")

    file_ext = os.path.splitext(file_path)[1].lower()
    print(f"\n[INFO] Loading dataset from: '{file_path}'")

    if file_ext in [".xlsx", ".xls"]:
        df = pd.read_excel(file_path)
        print(f"[SUCCESS] Loaded {len(df):,} rows and {len(df.columns)} columns from Excel.")
        return df

    # Candidate encodings to handle common Kaggle encoding quirks
    encodings_to_try = [encoding] if encoding else ["utf-8", "ISO-8859-1", "latin1", "cp1252"]

    for enc in encodings_to_try:
        if not enc:
            continue
        try:
            df = pd.read_csv(file_path, encoding=enc, low_memory=False)
            print(f"[SUCCESS] Loaded {len(df):,} rows and {len(df.columns)} columns using '{enc}' encoding.")
            return df
        except UnicodeDecodeError:
            continue
        except Exception as e:
            raise RuntimeError(f"Error reading '{file_path}' with encoding '{enc}': {e}")

    raise ValueError(f"Failed to decode '{file_path}' with supported encodings: {encodings_to_try}")


# ==============================================================================
# 3. DIRECT KAGGLE DATASET INGESTION HELPERS
# ==============================================================================

def load_uci_ecommerce(
    file_path: str = "data/raw/data.csv",
    clean_cancellations: bool = True,
    drop_guest_checkouts: bool = True
) -> pd.DataFrame:
    """
    Direct loader and domain preprocessor for the popular Kaggle UCI 'E-Commerce Data':
    Kaggle link: https://www.kaggle.com/datasets/carrie1/ecommerce-data
    
    Processing steps:
    1. Loads raw CSV with 'ISO-8859-1' encoding.
    2. Maps column names to canonical schema.
    3. Handles cancelled orders (InvoiceNo starting with 'C' and Quantity < 0).
    4. Drops rows with null CustomerID (guest checkouts without customer identifier).
    5. Calculates TotalAmount = Quantity * UnitPrice.
    6. Formats InvoiceDate to datetime.
    """
    print("\n" + "=" * 70)
    print(" INGESTING KAGGLE UCI 'E-COMMERCE DATA' (ONLINE RETAIL)")
    print("=" * 70)

    # Step 1: Load raw CSV
    df = load_dataset(file_path, encoding="ISO-8859-1")

    # Step 2: Column mapping
    df = standardize_columns(df, preset="uci_online_retail")

    initial_len = len(df)

    # Step 3: Handle guest checkouts (NaN CustomerIDs)
    if drop_guest_checkouts and "CustomerID" in df.columns:
        n_missing = df["CustomerID"].isna().sum()
        df = df.dropna(subset=["CustomerID"])
        # Format CustomerID as integer or clean string (avoid 17850.0)
        df["CustomerID"] = df["CustomerID"].astype(int).astype(str)
        print(f"  [CLEAN] Dropped {n_missing:,} guest checkouts missing CustomerID.")

    # Step 4: Handle cancellations
    if clean_cancellations and "InvoiceID" in df.columns:
        cancellations = df["InvoiceID"].astype(str).str.startswith("C", na=False) | (df["Quantity"] <= 0)
        n_canc = cancellations.sum()
        df = df[~cancellations].copy()
        print(f"  [CLEAN] Filtered out {n_canc:,} cancelled / return transactions.")

    # Step 5: Filter out negative or zero unit prices
    if "UnitPrice" in df.columns:
        invalid_price = df["UnitPrice"] <= 0
        df = df[~invalid_price].copy()

    # Step 6: Recalculate TotalAmount
    if "Quantity" in df.columns and "UnitPrice" in df.columns:
        df["TotalAmount"] = (df["Quantity"] * df["UnitPrice"]).round(2)

    print(f"[COMPLETED] Retained {len(df):,} valid purchase transactions ({len(df)/initial_len:.1%} of raw data).")
    return df


def load_brazilian_olist(
    orders_path: str,
    items_path: str,
    customers_path: Optional[str] = None,
    filter_delivered: bool = True
) -> pd.DataFrame:
    """
    Direct loader and relational merger for the Kaggle Brazilian E-Commerce Dataset (Olist):
    Kaggle link: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

    Merges:
    - olist_orders_dataset.csv (order_id, customer_id, order_purchase_timestamp, order_status)
    - olist_order_items_dataset.csv (order_id, price, freight_value)
    - olist_customers_dataset.csv (customer_id -> customer_unique_id)
    """
    print("\n" + "=" * 70)
    print(" INGESTING KAGGLE BRAZILIAN E-COMMERCE (OLIST) DATASET")
    print("=" * 70)

    orders = pd.read_csv(orders_path)
    items = pd.read_csv(items_path)

    if filter_delivered and "order_status" in orders.columns:
        orders = orders[orders["order_status"] == "delivered"].copy()

    # Merge orders with line items
    merged = pd.merge(items, orders, on="order_id", how="inner")

    # If customers table is provided, link to customer_unique_id
    if customers_path and os.path.exists(customers_path):
        customers = pd.read_csv(customers_path)
        merged = pd.merge(merged, customers, on="customer_id", how="inner")
        merged["CustomerID"] = merged["customer_unique_id"]
    else:
        merged["CustomerID"] = merged["customer_id"]

    # Canonical mappings
    merged["InvoiceID"] = merged["order_id"]
    merged["InvoiceDate"] = pd.to_datetime(merged["order_purchase_timestamp"], errors="coerce")
    merged["Quantity"] = 1
    merged["UnitPrice"] = merged["price"]
    merged["TotalAmount"] = (merged["price"] + merged.get("freight_value", 0.0)).round(2)

    keep_cols = ["CustomerID", "InvoiceID", "InvoiceDate", "Quantity", "UnitPrice", "TotalAmount"]
    if "customer_state" in merged.columns:
        merged["Country"] = merged["customer_state"]
        keep_cols.append("Country")

    clean_df = merged[keep_cols].copy()
    print(f"[COMPLETED] Merged and standardized {len(clean_df):,} delivered order items.")
    return clean_df


# ==============================================================================
# 4. COLUMN MAPPING & CANONICAL STANDARDIZATION STEP
# ==============================================================================

def standardize_columns(
    df: pd.DataFrame,
    preset: Optional[str] = None,
    custom_mapping: Optional[Dict[str, str]] = None,
    auto_detect: bool = True
) -> pd.DataFrame:
    """
    Standardizes dataset column names into canonical schema:
    ['CustomerID', 'InvoiceID', 'InvoiceDate', 'Quantity', 'UnitPrice', 'TotalAmount', 'Description', 'Country']

    Execution Flow:
    1. Applies preset mapping (e.g. 'uci_online_retail', 'brazilian_olist').
    2. Auto-detects synonyms for missing canonical fields.
    3. Incorporates explicit user-provided custom mappings.
    4. Automatically calculates 'TotalAmount' = Quantity * UnitPrice if not already provided.
    5. Parses 'InvoiceDate' to datetime.
    6. Validates presence of core fields required for downstream RFM and clustering.
    """
    df = df.copy()
    rename_plan: Dict[str, str] = {}

    # 1. Preset dictionary
    if preset and preset in DATASET_PRESETS:
        for raw_col, target_col in DATASET_PRESETS[preset].items():
            if raw_col in df.columns:
                rename_plan[raw_col] = target_col

    # 2. Auto-detect synonyms across all columns not already mapped
    if auto_detect:
        synonyms = DATASET_PRESETS["generic"]
        for col in df.columns:
            if col in rename_plan:
                continue
            normalized = col.strip().lower().replace(" ", "_").replace("-", "")
            if normalized in synonyms:
                rename_plan[col] = synonyms[normalized]

    # 3. User custom mapping overrides
    if custom_mapping:
        for src, target in custom_mapping.items():
            if src in df.columns:
                rename_plan[src] = target

    # Apply column renaming
    print("\n--- Column Mapping Summary ---")
    if rename_plan:
        for src, target in rename_plan.items():
            print(f"  [MAPPED] '{src}' -> '{target}'")
        df.rename(columns=rename_plan, inplace=True)
    else:
        print("  [INFO] Dataset columns already adhere to standard schema or no aliases matched.")

    # 4. Ensure TotalAmount is present (Quantity * UnitPrice)
    if "TotalAmount" not in df.columns:
        if "Quantity" in df.columns and "UnitPrice" in df.columns:
            df["Quantity"] = pd.to_numeric(df["Quantity"], errors="coerce").fillna(0)
            df["UnitPrice"] = pd.to_numeric(df["UnitPrice"], errors="coerce").fillna(0.0)
            df["TotalAmount"] = (df["Quantity"] * df["UnitPrice"]).round(2)
            print("  [CALCULATED] 'TotalAmount' computed dynamically as (Quantity * UnitPrice).")
        elif "total_spend" in df.columns:
            df["TotalAmount"] = pd.to_numeric(df["total_spend"], errors="coerce").round(2)
        else:
            print("  [WARNING] 'TotalAmount' is absent and cannot be computed without 'Quantity' and 'UnitPrice'.")
    else:
        df["TotalAmount"] = pd.to_numeric(df["TotalAmount"], errors="coerce")

    # 5. Convert InvoiceDate to datetime
    if "InvoiceDate" in df.columns:
        df["InvoiceDate"] = pd.to_datetime(df["InvoiceDate"], errors="coerce")
        print("  [FORMATTED] 'InvoiceDate' parsed into datetime objects.")

    # 6. Validate downstream requirements
    required_rfm = ["CustomerID", "InvoiceDate", "TotalAmount"]
    missing = [c for c in required_rfm if c not in df.columns]

    if missing:
        print(f"\n[ALERT] Missing essential fields for downstream RFM / Clustering: {missing}")
        print(f"Current available columns: {list(df.columns)}")
    else:
        print("\n[VERIFIED] All core RFM fields verified: 'CustomerID', 'InvoiceDate', 'TotalAmount'.")

    return df


# ==============================================================================
# 5. RFM FEATURE GENERATION FOR CLUSTERING
# ==============================================================================

def compute_rfm_features(df: pd.DataFrame, snapshot_date: Optional[Union[str, datetime]] = None) -> pd.DataFrame:
    """
    Transforms transactional purchase records into customer-level RFM features:
    - Recency: Days elapsed between the snapshot date and the customer's last purchase.
    - Frequency: Total number of distinct purchases / transactions.
    - Monetary: Total monetary spend across all transactions.
    """
    if not all(col in df.columns for col in ["CustomerID", "InvoiceDate", "TotalAmount"]):
        raise ValueError("DataFrame must contain ['CustomerID', 'InvoiceDate', 'TotalAmount'] to calculate RFM.")

    # Clean missing dates or amounts
    valid_df = df.dropna(subset=["CustomerID", "InvoiceDate", "TotalAmount"]).copy()

    if snapshot_date is None:
        snapshot_date = valid_df["InvoiceDate"].max() + pd.Timedelta(days=1)
    elif isinstance(snapshot_date, str):
        snapshot_date = pd.to_datetime(snapshot_date)

    print(f"\n[INFO] Calculating customer RFM metrics relative to snapshot date: {snapshot_date:%Y-%m-%d}...")

    # Group by customer
    rfm = valid_df.groupby("CustomerID").agg(
        Recency_Days=("InvoiceDate", lambda d: int((snapshot_date - d.max()).days)),
        Total_Purchases=("InvoiceID", "nunique") if "InvoiceID" in valid_df.columns else ("InvoiceDate", "count"),
        Total_Spend_USD=("TotalAmount", "sum"),
        Avg_Order_Value_USD=("TotalAmount", "mean")
    ).reset_index()

    rfm["Total_Spend_USD"] = rfm["Total_Spend_USD"].round(2)
    rfm["Avg_Order_Value_USD"] = rfm["Avg_Order_Value_USD"].round(2)

    print(f"[SUCCESS] Aggregated {len(rfm):,} customer profiles ready for K-Means clustering.")
    return rfm


# ==============================================================================
# 6. DYNAMIC FILE UPLOAD HANDLERS (CLI, JUPYTER & GOOGLE COLAB)
# ==============================================================================

def get_file_path_interactive() -> str:
    """
    Prompts the user via terminal input() to enter the path to their custom dataset.
    Supports quoting and verifies that the file exists on disk.
    """
    print("\n" + "=" * 60)
    print(" DYNAMIC FILE UPLOAD (STANDALONE SCRIPT MODE)")
    print("=" * 60)
    while True:
        user_input = input("Enter path to custom CSV/Excel dataset (or 'q' to quit): ").strip().strip('"\'')
        if user_input.lower() in ["q", "quit", "exit"]:
            print("Operation aborted by user.")
            sys.exit(0)
        if not user_input:
            print("[ERROR] Path cannot be empty. Please enter a valid file path.")
            continue
        if os.path.exists(user_input):
            return user_input
        else:
            print(f"[ERROR] File not found at: '{user_input}'. Please re-check the path.")


def upload_dataset_jupyter():
    """
    Dynamic file upload widget for Jupyter Notebook and VS Code Interactive Python.
    Uses `ipywidgets.FileUpload`.

    Usage in Jupyter Notebook:
        uploader = upload_dataset_jupyter()
        display(uploader)
        # After selecting a file, parse it with:
        df = parse_jupyter_upload(uploader)
    """
    try:
        import ipywidgets as widgets
        uploader = widgets.FileUpload(
            accept=".csv, .xlsx, .xls",
            multiple=False,
            description="Select Dataset",
            button_style="primary"
        )
        print("[JUPYTER] Render the upload widget with: display(uploader)")
        return uploader
    except ImportError:
        raise ImportError("The 'ipywidgets' package is required. Install via: pip install ipywidgets")


def parse_jupyter_upload(uploader, preset: str = "generic") -> pd.DataFrame:
    """Parses the uploaded binary content from an ipywidgets.FileUpload widget into a DataFrame."""
    if not uploader.value:
        raise ValueError("[ERROR] No file uploaded yet. Please click 'Select Dataset' to upload.")

    # Support ipywidgets v7 and v8 upload data structures
    if isinstance(uploader.value, (list, tuple)):
        file_obj = uploader.value[0]
        filename = file_obj["name"]
        content = file_obj["content"]
    elif isinstance(uploader.value, dict):
        filename = next(iter(uploader.value.keys()))
        val = uploader.value[filename]
        content = val["content"] if isinstance(val, dict) else val.content
    else:
        raise TypeError("Unrecognized ipywidgets.FileUpload value format.")

    print(f"\n[UPLOAD] Ingesting widget-uploaded file: '{filename}' ({len(content):,} bytes)")

    if filename.endswith(".xlsx") or filename.endswith(".xls"):
        raw_df = pd.read_excel(io.BytesIO(content))
    else:
        # Candidate encodings
        for enc in ["utf-8", "ISO-8859-1", "latin1"]:
            try:
                raw_df = pd.read_csv(io.BytesIO(content), encoding=enc, low_memory=False)
                break
            except UnicodeDecodeError:
                continue

    return standardize_columns(raw_df, preset=preset, auto_detect=True)


def upload_dataset_colab(preset: str = "generic") -> pd.DataFrame:
    """
    Dynamic file upload interface for Google Colab environments.
    Prompts user to select a file directly from their browser.

    Usage in Google Colab:
        df = upload_dataset_colab()
    """
    try:
        from google.colab import files
    except ImportError:
        raise ImportError("[ERROR] google.colab is only available when running inside Google Colab.")

    print("\n[COLAB] Please select a dataset to upload from your local machine:")
    uploaded = files.upload()

    if not uploaded:
        raise ValueError("[ERROR] No file was uploaded.")

    filename, content = next(iter(uploaded.items()))
    print(f"[COLAB] File uploaded successfully: '{filename}' ({len(content):,} bytes)")

    if filename.endswith(".xlsx") or filename.endswith(".xls"):
        raw_df = pd.read_excel(io.BytesIO(content))
    else:
        for enc in ["utf-8", "ISO-8859-1", "latin1"]:
            try:
                raw_df = pd.read_csv(io.BytesIO(content), encoding=enc, low_memory=False)
                break
            except UnicodeDecodeError:
                continue

    return standardize_columns(raw_df, preset=preset, auto_detect=True)


# ==============================================================================
# 7. STANDALONE CLI SCRIPT EXECUTION
# ==============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Ingest, dynamically upload, standardize, and prepare E-Commerce datasets for RFM and Clustering."
    )
    parser.add_argument(
        "-f", "--file",
        type=str,
        default=None,
        help="Path to CSV or Excel dataset. If omitted, prompts interactively."
    )
    parser.add_argument(
        "-p", "--preset",
        type=str,
        choices=["uci_online_retail", "brazilian_olist", "generic"],
        default="uci_online_retail",
        help="Column mapping preset matching your source dataset structure."
    )
    parser.add_argument(
        "-o", "--output",
        type=str,
        default="data/processed/cleaned_customer_data.csv",
        help="Destination path for standardized output CSV."
    )
    parser.add_argument(
        "--rfm",
        action="store_true",
        help="If set, aggregates transactions into customer-level RFM features."
    )

    args = parser.parse_args()

    # Step 1: Resolve dataset path via argparse or interactive fallback
    file_path = args.file
    if not file_path:
        sample_path = os.path.join("data", "raw", "customer_data.csv")
        if os.path.exists(sample_path):
            print(f"Found local sample dataset at '{sample_path}'.")
            choice = input("Use this dataset? [Y/n/c for custom path]: ").strip().lower()
            if choice in ["", "y", "yes"]:
                file_path = sample_path
            else:
                file_path = get_file_path_interactive()
        else:
            file_path = get_file_path_interactive()

    # Step 2: Load dataset (handling Kaggle presets if applicable)
    if args.preset == "uci_online_retail" and "data.csv" in os.path.basename(file_path).lower():
        clean_df = load_uci_ecommerce(file_path)
    else:
        raw_df = load_dataset(file_path)
        # Step 3: Column mapping and standardization immediately after load
        clean_df = standardize_columns(raw_df, preset=args.preset, auto_detect=True)

    # Optional: RFM aggregation
    if args.rfm:
        print("\n[OPTION] Performing customer RFM aggregation...")
        clean_df = compute_rfm_features(clean_df)

    # Preview standardized dataset
    print("\n--- Standardized Dataset Preview ---")
    print(clean_df.head(5))
    print(f"\nShape: {clean_df.shape[0]:,} rows x {clean_df.shape[1]} columns")

    # Save output
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    clean_df.to_csv(args.output, index=False)
    print(f"\n[SAVED] Output saved to: '{args.output}'")


if __name__ == "__main__":
    main()
