# Dataset Documentation: E-Commerce Customer Behavior Dataset

## 1. Overview & Provenance
This dataset was created for the academic project:
- **Project Title:** E-Commerce Customer Behavior Analysis: Customer Segmentation and Purchase Prediction
- **Subject:** Big Data Analytics – R Programming Mini Project
- **Institution:** Mentor Engineering College (Department of AI & DS / Department of CSE)
- **Academic Year:** 2026–2027

To ensure strict academic reproducibility without external API or internet access constraints, the raw dataset is generated as a **reproducible synthetic e-commerce transaction and behavior dataset** using the R statistical computing language (`R/data_loading.R`).

> **Note on Data Fidelity:** The synthetic dataset is simulated using realistic statistical distributions (log-normal spending patterns, right-skewed session durations, gamma-distributed transaction counts, and demographic stratification) mirroring enterprise e-commerce platforms (such as Amazon, Flipkart, and Shopify). Synthetic customer records are explicitly labeled as simulated data and are not represented as real-world private customer observations.

---

## 2. Dataset Schema & Data Dictionary

| Column Name | Data Type | Units / Range | Description |
|:---|:---|:---|:---|
| `CustomerID` | String | `CUST_0001` - `CUST_5000` | Unique alphanumeric identifier for each customer |
| `Age` | Integer | 18 – 72 years | Customer age in years |
| `Gender` | Factor | Female, Male, Other | Customer self-reported gender |
| `City_Tier` | Factor | Tier 1, Tier 2, Tier 3 | Geographic classification of customer residence |
| `Annual_Income_USD` | Numeric | $18,000 – $185,000 | Estimated annual household income in USD |
| `Customer_Tenure_Months` | Integer | 1 – 72 months | Number of months since customer registration |
| `Total_Purchases` | Integer | 1 – 65 orders | Lifetime completed orders placed on the platform |
| `Total_Spend_USD` | Numeric | $45.00 – $8,500.00 | Lifetime gross expenditure in USD |
| `Avg_Order_Value_USD` | Numeric | $15.00 – $450.00 | Average spend per completed order |
| `Recency_Days` | Integer | 1 – 365 days | Number of days elapsed since the most recent purchase |
| `App_Session_Minutes` | Numeric | 2.0 – 180.0 minutes | Average weekly engagement time on the mobile app |
| `Website_Visits_Per_Month` | Integer | 1 – 45 visits | Number of web portal visits recorded in the past 30 days |
| `Discount_Usage_Ratio` | Numeric | 0.00 – 0.95 | Proportion of historical orders placed using coupon codes |
| `Preferred_Category` | Factor | Electronics, Fashion, Home & Living, Beauty & Health, Books & Media | Most frequently purchased product category |
| `Loyalty_Program_Member` | Factor / Int | 0 (No), 1 (Yes) | Status in the premium loyalty membership program |
| `Customer_Satisfaction_Score` | Integer | 1 – 5 | Average post-purchase satisfaction rating (CSAT) |
| `Repeat_Purchase` | Binary Int | 0 (No), 1 (Yes) | **Prediction Target:** Whether the customer completed an order in the subsequent 30-day target observation window |

---

## 3. Data Generating Process & Prevention of Target Leakage

### Target Definition:
- The target variable `Repeat_Purchase` represents a future purchase event in a distinct 30-day post-observation window.
- The probability of repeat purchase is governed by a logistic link function based on observed historical features:
  $$\text{logit}(p) = \beta_0 + \beta_1 \cdot \text{Recency} + \beta_2 \cdot \text{Frequency} + \beta_3 \cdot \text{Spend} + \beta_4 \cdot \text{Loyalty} + \beta_5 \cdot \text{Engagement} + \beta_6 \cdot \text{Satisfaction} - \beta_7 \cdot \text{DiscountUsage} + \epsilon$$
- Because the target reflects subsequent-period purchase behavior derived from pre-period features with stochastic variance ($\epsilon$), there is **zero target leakage** (no future information is leaked into predictor columns).

### Injected Data Quality Artifacts:
To emulate real-world data engineering challenges:
1. **Missing Values (`NA`):** Approximately 2% missing values are randomly injected into `Annual_Income_USD`, `App_Session_Minutes`, and `Customer_Tenure_Months`.
2. **Duplicate Records:** 15 exact duplicate rows are deliberately introduced to validate the pipeline's deduplication mechanism.
3. **Outliers:** Natural log-normal heavy tails are included in `Total_Spend_USD` and `Annual_Income_USD` to mirror real e-commerce VIP segments.

---

## 4. Usage License & Ethics
- Created solely for academic demonstration and research.
- Fully synthetic; contains no Personally Identifiable Information (PII) or proprietary commercial data.
