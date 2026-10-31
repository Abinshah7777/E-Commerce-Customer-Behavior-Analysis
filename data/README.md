# Dataset Documentation: Genuine Kaggle E-Commerce Customer Behavior Dataset

## 1. Overview & Provenance
This project utilizes a genuine, publicly available Kaggle e-commerce customer behavior dataset:
- **Dataset Title:** Customer Shopping Trends Dataset
- **Kaggle Source:** [https://www.kaggle.com/datasets/iamsouravbanerjee/customer-shopping-trends-dataset](https://www.kaggle.com/datasets/iamsouravbanerjee/customer-shopping-trends-dataset)
- **Author:** Sourav Banerjee
- **Dataset Scale:** 3,900 customer observations across 18 behavioral, demographic, and transactional attributes.
- **Local Files:**
  - `data/raw/customer_data.csv` (Primary raw dataset)
  - `data/raw/shopping_trends.csv` (Original source backup)
  - `data/raw/customer_data_sample.xlsx` (Excel sample workbook for testing Excel upload)
  - `data/processed/cleaned_customer_data.csv` (Deduplicated, imputed, and standardized dataset)

> **Authenticity Note:** All former synthetic/dummy data generators have been removed. The pipeline and interactive Shiny web application operate exclusively on real customer transaction and behavior records.

---

## 2. Dataset Schema & Data Dictionary

| Original Column | Standardized Name | Type | Description |
|:---|:---|:---|:---|
| `Customer ID` | `CustomerID` | Alphanumeric | Unique customer identifier (`1` to `3900`) |
| `Age` | `Age` | Integer | Customer age in years (18 to 70) |
| `Gender` | `Gender` | Factor | Demographic gender (`Male`, `Female`) |
| `Item Purchased` | `Item_Purchased` | Character | Specific product purchased (e.g. Blouse, Jeans, Sneakers) |
| `Category` | `Category` / `Preferred_Category` | Factor | Product category (`Clothing`, `Footwear`, `Outerwear`, `Accessories`) |
| `Purchase Amount (USD)` | `Purchase_Amount_USD` / `Avg_Order_Value_USD` | Numeric | Monetary value of the individual transaction ($20 – $100) |
| `Location` | `Location` / `City_Tier` | Character | Geographic US State of the customer |
| `Size` | `Size` | Factor | Garment size (`S`, `M`, `L`, `XL`) |
| `Color` | `Color` | Character | Product color |
| `Season` | `Season` | Factor | Shopping season (`Winter`, `Spring`, `Summer`, `Fall`) |
| `Review Rating` | `Customer_Satisfaction_Score` | Numeric | Post-purchase review score (2.5 to 5.0) |
| `Subscription Status` | `Subscription_Status` / `Loyalty_Program_Member` | Binary Factor | Loyalty subscription membership status (`Yes`, `No`) |
| `Shipping Type` | `Shipping_Type` | Factor | Shipping method (`Express`, `Free Shipping`, `Standard`, etc.) |
| `Discount Applied` | `Discount_Applied` | Binary Factor | Whether promotion or discount was utilized (`Yes`, `No`) |
| `Promo Code Used` | `Promo_Code_Used` | Binary Factor | Whether promotional code was entered (`Yes`, `No`) |
| `Previous Purchases` | `Total_Purchases` | Integer | Historical order count (1 to 50 previous orders) |
| `Payment Method` | `Payment_Method` | Factor | Payment gateway (`Credit Card`, `PayPal`, `Venmo`, `Cash`, etc.) |
| `Frequency of Purchases` | `Frequency_of_Purchases` | Factor | Purchase cadence (`Weekly`, `Fortnightly`, `Monthly`, `Annually`, etc.) |

---

## 3. Dynamically Derived Features

When raw attributes are present, the preprocessing engine (`R/data_preprocessing.R`) automatically standardizes and engineers:
1. **`Total_Spend_USD`:** Calculated as `Purchase_Amount_USD * (Total_Purchases + 1)`.
2. **`Recency_Days`:** Derived from purchase frequency cadence (Weekly = 7 days, Fortnightly = 14 days, Monthly = 30 days, Quarterly = 90 days, Annually = 365 days).
3. **`Discount_Usage_Ratio`:** Calculated from discount utilization status (0.40 vs 0.05).
4. **`Repeat_Purchase`:** Binary indicator based on order frequency (`Total_Purchases >= 10`).

---

## 4. Custom Dataset Upload Feature

The platform provides a dynamic upload workflow in the R Shiny application (`app/app.R`):
- **Supported Formats:** CSV (`.csv`) and Excel (`.xlsx`, `.xls`).
- **Validation:** Audits row count ($\ge 5$), column count ($\ge 2$), and identifies available numerical features and binary targets.
- **Dynamic Analysis:** All EDA distributions, K-Means clustering ($K = 2 \dots 6$), and predictive propensity modeling adapt to whatever columns exist in the uploaded file without crashing.
