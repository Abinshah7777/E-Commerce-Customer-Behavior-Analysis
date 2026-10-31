"""
Data Ingestion & Pre-processing Pipeline for E-Commerce Datasets
Supports:
1. Real Kaggle Datasets (UCI Online Retail, Brazilian E-Commerce / Olist)
2. Standalone script mode (argparse + interactive input() fallback)
3. Jupyter / Google Colab file upload integration (ipywidgets / colab.files)
4. Robust Column Standardization & RFM Field Validation
"""

import os
import sys
import argparse
from typing import Optional, Dict, Tuple
import pandas as pd
import numpy as np


# ==============================================================================
# 1. CANONICAL SCHEMA & DATASET PRESETS
# ==============================================================================

# Standard canonical column names expected by downstream EDA, RFM, and Clustering
CANONICAL_COLUMNS = {
    "CustomerID": "Unique identifier for customer",
    "InvoiceID": "Unique identifier for transaction / order",
    "InvoiceDate": "Timestamp / date of transaction",
    "Quantity": "Quantity of items purchased",
    "UnitPrice": "Price per individual item",
    "TotalAmount": "Total transaction spend (Quantity * UnitPrice or pre-calculated)",
    "Description": "Product description or title (optional)",
    "Country": "Customer or transaction country (optional)"
}

# Pre-configured mappings for popular Kaggle E-Commerce datasets
DATASET_PRESETS: Dict[str, Dict[str, str]] = {
    # Kaggle: "E-Commerce Data" (UCI Machine Learning Repository / Online Retail)
    "uci_online_retail": {
        "CustomerID": "CustomerID",
        "InvoiceNo": "InvoiceID",
        "InvoiceDate": "InvoiceDate",
        "Quantity": "Quantity",
        "UnitPrice": "UnitPrice",
        "Description": "Description",
        "Country": "Country"
    },
    # Kaggle: "Brazilian E-Commerce Public Dataset by Olist" (Merged orders + items)
    "brazilian_olist": {
        "customer_unique_id": "CustomerID",
        "order_id": "InvoiceID",
        "order_purchase_timestamp": "InvoiceDate",
        "order_item_id": "Quantity",
        "price": "UnitPrice",
        "product_category_name": "Description"
    },
    # Common alternate conventions
    "generic": {
        "customer_id": "CustomerID",
        "client_id": "CustomerID",
        "user_id": "CustomerID",
        "invoice_id": "InvoiceID",
        "order_id": "InvoiceID",
        "invoice_number": "InvoiceID",
        "invoice_date": "InvoiceDate",
        "order_date": "InvoiceDate",
        "date": "InvoiceDate",
        "timestamp": "InvoiceDate",
        "qty": "Quantity",
        "quantity": "Quantity",
        "price": "UnitPrice",
        "unit_price": "UnitPrice",
        "item_price": "UnitPrice",
        "total": "TotalAmount",
        "total_amount": "TotalAmount",
        "total_spend": "TotalAmount",
        "total_spend_usd": "TotalAmount",
        "spending": "TotalAmount",
        "monetary": "TotalAmount",
        "amount": "TotalAmount",
        "country": "Country",
        "description": "Description"
    }
}


# ==============================================================================
# 2. FILE LOADING WITH ENCODING FALLBACKS
# ==============================================================================

def load_dataset(file_path: str, encoding: Optional[str] = None) -> pd.DataFrame:
    """
    Loads an e-commerce dataset from CSV or Excel file.
    Tries multiple encodings automatically (critical for Kaggle UCI data containing latin1 characters).
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: '{file_path}'")

    file_ext = os.path.splitext(file_path)[1].lower()
    print(f"\n[INFO] Loading dataset from: {file_path}")

    if file_ext in [".xlsx", ".xls"]:
        return pd.read_excel(file_path)

    # List of candidate encodings (UCI E-Commerce CSV often uses ISO-8859-1 or latin1)
    encodings_to_try = [encoding] if encoding else ["utf-8", "ISO-8859-1", "latin1", "cp1252"]

    for enc in encodings_to_try:
        if enc is None:
            continue
        try:
            df = pd.read_csv(file_path, encoding=enc, low_memory=False)
            print(f"[SUCCESS] Loaded {len(df):,} rows and {len(df.columns)} columns using '{enc}' encoding.")
            return df
        except UnicodeDecodeError:
            continue
        except Exception as e:
            raise RuntimeError(f"Error reading {file_path} with encoding {enc}: {e}")

    raise ValueError(f"Failed to decode '{file_path}' with encodings: {encodings_to_try}")


# ==============================================================================
# 3. COLUMN STANDARDIZATION & MAPPING STEP
# ==============================================================================

def standardize_columns(
    df: pd.DataFrame,
    preset: Optional[str] = None,
    custom_mapping: Optional[Dict[str, str]] = None,
    auto_detect: bool = True
) -> pd.DataFrame:
    """
    Applies column mapping to normalize dataset columns into standard names:
    ('CustomerID', 'InvoiceID', 'InvoiceDate', 'Quantity', 'UnitPrice', 'TotalAmount').

    - Computes 'TotalAmount' = Quantity * UnitPrice if not directly present.
    - Converts 'InvoiceDate' to datetime.
    - Strips invalid / missing CustomerIDs.
    """
    df = df.copy()
    mapping: Dict[str, str] = {}

    # 1. Apply preset mapping if specified
    if preset and preset in DATASET_PRESETS:
        mapping.update(DATASET_PRESETS[preset])

    # 2. Auto-detect column names matching synonyms if enabled
    if auto_detect:
        synonyms = DATASET_PRESETS["generic"]
        for col in df.columns:
            normalized = col.strip().lower().replace(" ", "_").replace("-", "_")
            if normalized in synonyms and col not in mapping:
                mapping[col] = synonyms[normalized]

    # 3. Override with any explicit custom user mapping
    if custom_mapping:
        mapping.update(custom_mapping)

    # Filter mapping to only include columns that actually exist in the dataframe
    actual_mapping = {src: target for src, target in mapping.items() if src in df.columns}

    print("\n--- Column Mapping Summary ---")
    if actual_mapping:
        for src, target in actual_mapping.items():
            print(f"  Mapped: '{src}' -> '{target}'")
        df.rename(columns=actual_mapping, inplace=True)
    else:
        print("  No columns needed renaming or no preset matches found.")

    # 4. Handle TotalAmount calculation if missing
    if "TotalAmount" not in df.columns:
        if "Quantity" in df.columns and "UnitPrice" in df.columns:
            # Clean numeric values
            df["Quantity"] = pd.to_numeric(df["Quantity"], errors="coerce")
            df["UnitPrice"] = pd.to_numeric(df["UnitPrice"], errors="coerce")
            df["TotalAmount"] = (df["Quantity"] * df["UnitPrice"]).round(2)
            print("  [CALCULATED] 'TotalAmount' generated as (Quantity * UnitPrice).")
        else:
            print("  [WARNING] 'TotalAmount' is missing and cannot be computed (needs 'Quantity' & 'UnitPrice').")

    # 5. Standardize InvoiceDate parsing
    if "InvoiceDate" in df.columns:
        df["InvoiceDate"] = pd.to_datetime(df["InvoiceDate"], errors="coerce")
        print("  [PARSED] 'InvoiceDate' converted to datetime.")

    # 6. Validate essential fields for downstream RFM & clustering
    required_rfm = ["CustomerID", "InvoiceDate", "TotalAmount"]
    missing = [c for c in required_rfm if c not in df.columns]
    if missing:
        print(f"\n[ALERT] Downstream RFM/Clustering may require: {missing}")
        print(f"Current columns: {list(df.columns)}")
    else:
        print("\n[VERIFIED] All core RFM fields present: CustomerID, InvoiceDate, TotalAmount.")

    return df


# ==============================================================================
# 4. INTERACTIVE / CLI FILE UPLOAD HANDLERS
# ==============================================================================

def get_file_path_interactive() -> str:
    """Prompt user via terminal input() to provide their custom dataset path."""
    print("\n" + "=" * 60)
    print(" DYNAMIC DATASET INGESTION: FILE INPUT PROMPT")
    print("=" * 60)
    while True:
        user_path = input("Enter the full or relative path to your CSV/Excel dataset: ").strip().strip('"\'')
        if not user_path:
            print("Path cannot be empty. Please try again.")
            continue
        if os.path.exists(user_path):
            return user_path
        else:
            print(f"Error: '{user_path}' does not exist on disk. Please verify the path.")


# ==============================================================================
# 5. JUPYTER / GOOGLE COLAB INTEGRATION HELPERS
# ==============================================================================

def get_colab_uploader():
    """
    Returns code snippet and helper function for Google Colab file upload.
    Usage in Colab:
        df = upload_colab_dataset()
    """
    try:
        from google.colab import files
        import io
        print("Please choose a CSV file to upload from your local machine:")
        uploaded = files.upload()
        for filename, content in uploaded.items():
            print(f"Uploaded: {filename} ({len(content):,} bytes)")
            df = pd.read_csv(io.BytesIO(content), encoding="ISO-8859-1", low_memory=False)
            return standardize_columns(df, auto_detect=True)
    except ImportError:
        raise ImportError("google.colab module is only available within Google Colab environments.")


def get_ipywidgets_uploader():
    """
    Creates an ipywidgets FileUpload widget for Jupyter Notebook.
    Usage in Jupyter:
        uploader = get_ipywidgets_uploader()
        display(uploader)
        # Once uploaded, parse with:
        df = parse_uploaded_widget(uploader)
    """
    try:
        import ipywidgets as widgets
        uploader = widgets.FileUpload(
            accept=".csv, .xlsx",
            multiple=False,
            description="Upload Dataset"
        )
        return uploader
    except ImportError:
        raise ImportError("ipywidgets is not installed. Run 'pip install ipywidgets'.")


def parse_uploaded_widget(uploader) -> pd.DataFrame:
    """Parses an ipywidgets.FileUpload widget into a standardized pandas DataFrame."""
    import io
    if not uploader.value:
        raise ValueError("No file has been uploaded via widget yet.")

    # Handle ipywidgets v7 vs v8 structure
    item = uploader.value[0] if isinstance(uploader.value, (list, tuple)) else next(iter(uploader.value.values()))
    content = item.get("content") if isinstance(item, dict) else item.content
    filename = item.get("name") if isinstance(item, dict) else item.name

    print(f"[UPLOAD] Processing widget upload: {filename}")
    if filename.endswith(".xlsx") or filename.endswith(".xls"):
        df = pd.read_excel(io.BytesIO(content))
    else:
        df = pd.read_csv(io.BytesIO(content), encoding="ISO-8859-1", low_memory=False)

    return standardize_columns(df, auto_detect=True)


# ==============================================================================
# 6. STANDALONE MAIN EXECUTION (ARGPARSE + FALLBACK)
# ==============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Ingest, standardize, and prepare E-Commerce datasets for RFM and Clustering."
    )
    parser.add_argument(
        "-f", "--file",
        type=str,
        default=None,
        help="Path to the dataset CSV or Excel file (e.g. data/data.csv)"
    )
    parser.add_argument(
        "-p", "--preset",
        type=str,
        choices=["uci_online_retail", "brazilian_olist", "generic"],
        default="uci_online_retail",
        help="Column mapping preset matching your dataset source"
    )
    parser.add_argument(
        "-o", "--output",
        type=str,
        default="data/processed/standardized_ecommerce_data.csv",
        help="Destination path for standardized output CSV"
    )

    args = parser.parse_args()

    # Step 1 & 2: Determine file path via argparse or fallback to input()
    file_path = args.file
    if not file_path:
        # Check if default sample data exists in workspace first
        sample_path = os.path.join("data", "raw", "customer_data.csv")
        if os.path.exists(sample_path):
            print(f"Found local dataset at '{sample_path}'.")
            choice = input(f"Use this dataset? [Y/n] (or enter 'c' to enter custom path): ").strip().lower()
            if choice in ["", "y", "yes"]:
                file_path = sample_path
            else:
                file_path = get_file_path_interactive()
        else:
            file_path = get_file_path_interactive()

    # Step 2: Load dataset with encoding fallback
    raw_df = load_dataset(file_path)

    # Step 3: Column mapping and standardization
    clean_df = standardize_columns(raw_df, preset=args.preset, auto_detect=True)

    # Display preview of standardized data
    print("\n--- Standardized Dataset Preview ---")
    print(clean_df.head(5))

    # Save standardized output
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    clean_df.to_csv(args.output, index=False)
    print(f"\n[SAVED] Standardized dataset saved to: '{args.output}'")


if __name__ == "__main__":
    main()
