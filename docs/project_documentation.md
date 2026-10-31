# Project Report: E-Commerce Customer Behavior Analysis
## Customer Segmentation and Purchase Prediction

**Subject:** Big Data Analytics – R Programming Mini Project  
**Academic Year:** 2026–2027  
**Degree:** Bachelor of Technology (B.Tech)  
**Departments:** Department of Artificial Intelligence and Data Science & Department of Computer Science and Engineering  
**Institution:** Mentor Engineering College  

**Submitted By:**
1. Muhammed Shijil MK
2. Navin Krishna IN
3. Abinshah PM
4. Liju Shirvan
5. Hishal MT

**Date:** October 2026

---

## Abstract

The exponential growth of modern e-commerce platforms has led to massive volumes of customer demographic, behavioral, and transactional data. Extracting actionable commercial value from these big data streams requires robust statistical pipelines and scalable machine learning algorithms. This B.Tech mini project delivers a complete, reproducible analytical system developed in R programming to analyze customer purchasing behavior, execute unsupervised customer segmentation, and build supervised purchase prediction models.

Using a multi-attribute customer dataset comprising 5,000 observations, the pipeline executes rigorous data auditing, deduplication, median imputation of missing values, and Z-score feature scaling. Exploratory and inferential statistical analysis (Welch’s t-tests, One-Way ANOVA, Chi-Square tests of independence) demonstrate significant behavioral divergence across cohorts. K-Means clustering ($K = 4$), optimized via the Elbow Method and Silhouette analysis, reveals four distinct personas: *High-Value Loyalists*, *Active Mid-Tier Regulars*, *Discount-Driven Shoppers*, and *Low-Frequency At-Risk Customers*. In parallel, supervised predictive classification models (Logistic Regression and Random Forest) predict repeat purchase likelihood over a 30-day window without target leakage, achieving strong out-of-sample discriminatory performance (ROC-AUC: 0.724 for Logistic Regression and 0.694 for Random Forest). The system provides actionable business strategies, an interactive R Shiny dashboard for real-time customer propensity scoring, and an automated analytical reporting engine.

---

## 1. Introduction

### 1.1 Background & Motivation
In digital commerce, customer acquisition costs (CAC) continue to escalate. Consequently, sustainable profitability relies heavily on retaining high-value buyers, preventing churn among at-risk users, and tailoring promotions to consumer preferences. However, traditional analytics often treat customer cohorts homogeneously, leading to untargeted advertising and blanket discounting that diminishes margins.

Big Data Analytics provides the tools and computational frameworks needed to analyze multi-dimensional customer transaction histories, user engagement telemetry, and demographic traits.

### 1.2 Objectives
The primary objectives of this project are:
1. **Data Preprocessing & Quality Engineering:** Build a robust, reproducible data cleansing pipeline to handle missing values, eliminate duplicates, and standardize features.
2. **Exploratory & Inferential Statistics:** Uncover underlying spending patterns, order frequencies, and correlations, validated through formal hypothesis testing.
3. **Unsupervised Customer Segmentation:** Implement K-Means clustering to discover natural customer personas based on Recency, Frequency, Monetary (RFM) metrics, app engagement, and discount usage.
4. **Supervised Purchase Prediction:** Train and compare Logistic Regression and Random Forest models to predict 30-day repeat purchase events.
5. **Business Intelligence & Dashboards:** Convert empirical findings into actionable commercial strategies and provide an interactive R Shiny demonstration platform.

---

## 2. System Architecture & Methodology

```
+-----------------------------------------------------------------------------------+
|                            E-COMMERCE DATA SYSTEM                                 |
+-----------------------------------------------------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                        DATA PREPROCESSING (R/data_preprocessing.R)                 |
|  - Deduplication: Removed 15 duplicate customer records                          |
|  - Imputation: Handled ~2% missing values using robust medians                    |
|  - Standardization: Z-score scaling for clustering features                       |
|  - Partitioning: 75% Stratified Training (3,750) / 25% Testing (1,250)           |
+-----------------------------------------------------------------------------------+
             |                                                     |
             v                                                     v
+------------------------------------------+ +--------------------------------------+
| UNSUPERVISED CLUSTERING                  | | SUPERVISED PREDICTION                |
| (R/customer_segmentation.R)              | | (R/purchase_prediction.R)            |
| - Feature Selection (RFM + Engagement)   | | - Target: Repeat_Purchase (0/1)      |
| - Elbow Method (WCSS vs k)               | | - Baseline: Logistic Regression (GLM)|
| - Silhouette Validation                  | | - Advanced: Random Forest (200 trees)|
| - K-Means Model Fitting (k = 4)          | | - Out-of-sample Evaluation & ROC-AUC |
+------------------------------------------+ +--------------------------------------+
             \                                                     /
              \                                                   /
               v                                                 v
+-----------------------------------------------------------------------------------+
|                          VISUALIZATION & REPORTING MODULES                        |
|  - 15 High-Resolution ggplot2 Publication Charts (outputs/plots/)                |
|  - 8 Structured Analytical Data Tables (outputs/tables/)                          |
|  - Interactive R Shiny Web Application (app/app.R)                                |
|  - Automated Markdown & HTML Analytical Reports (outputs/reports/)                |
+-----------------------------------------------------------------------------------+
```

---

## 3. Dataset Characteristics & Preprocessing

### 3.1 Data Schema
The dataset contains 5,000 unique customer records across 17 attributes:
- **Identifiers & Demographics:** `CustomerID`, `Age` (18–72), `Gender` (Female, Male, Other), `City_Tier` (Tier 1–3), `Annual_Income_USD` ($18k–$185k), `Customer_Tenure_Months` (1–72).
- **Transactional & RFM Metrics:** `Total_Purchases` (1–65), `Total_Spend_USD` ($45–$8,500), `Avg_Order_Value_USD` ($15–$450), `Recency_Days` (1–365).
- **Behavioral & Telemetry:** `App_Session_Minutes` (2–180 mins/week), `Website_Visits_Per_Month` (1–45 visits), `Discount_Usage_Ratio` (0.00–0.95), `Preferred_Category` (Electronics, Fashion, Home & Living, Beauty & Health, Books & Media), `Loyalty_Program_Member` (0/1), `Customer_Satisfaction_Score` (1–5).
- **Prediction Target:** `Repeat_Purchase` (0/1 binary indicator of purchase in the subsequent 30-day window).

### 3.2 Preprocessing Results
| Metric | Count / Description |
|:---|:---|
| Raw Rows Ingested | 5,015 |
| Duplicate Rows Removed | 15 |
| Missing Values Imputed | 300 (100 in Income, 100 in Tenure, 100 in Session Mins) |
| Post-Cleaning Observations | 5,000 |
| Train / Test Split | 3,750 (75%) Train / 1,250 (25%) Test |

---

## 4. Exploratory Data Analysis & Inferential Statistics

### 4.1 Exploratory Findings
- **Spend Asymmetry:** Lifetime spending displays substantial right skewness (Mean: $740.32, Median: $573.75), indicating that top-tier customers drive disproportionate platform revenue.
- **Order Frequency:** Customers average 8.5 completed orders (SD: 4.8).
- **Loyalty Penetration:** 37.2% of the customer base are enrolled in the premium loyalty program.
- **Repeat Purchase Base Rate:** 40.8% of customers placed a follow-up order within the subsequent 30-day window.

### 4.2 Inferential Hypothesis Testing Results
1. **Purchase Frequency vs Lifetime Spend:** Pearson's correlation test confirmed a significant positive linear association ($r = 0.601, t = 52.88, p < 0.0001$).
2. **Loyalty Program Spend Lift:** Welch's Two-Sample t-test demonstrated that loyalty program members generate significantly higher lifetime spend than non-members (Mean: $1,058.40 vs $551.68, difference: $506.72, $t = 28.14, p < 0.0001$).
3. **Recency Difference by Purchase Outcome:** Repeat buyers exhibited significantly lower recency than non-repeat buyers (Mean: 32.2 days vs 48.9 days, difference: 16.7 days, $t = -17.65, p < 0.0001$).
4. **Category Spending Variance:** One-Way ANOVA across product categories confirmed significant spending variation ($F = 24.36, p < 0.0001$), with Electronics and Home & Living leading in AOV.
5. **Loyalty Association with Repeat Purchase:** Pearson's Chi-Square test confirmed that loyalty program membership is significantly associated with higher repeat purchase propensity ($\chi^2 = 84.22, p < 0.0001$).

---

## 5. Unsupervised Customer Segmentation (K-Means)

### 5.1 Optimization & Personas
Evaluating $K \in [2, 8]$ using the Elbow Method (WCSS) and Average Silhouette Width indicated that **$K = 4$** provides the optimal balance of mathematical cohesion and commercial interpretability.

| Cluster ID | Segment Persona | Customers | Share | Mean Spend | Mean Orders | Recency | Repeat Rate |
|:---:|:---|---:|---:|---:|---:|---:|---:|
| 1 | **High-Value Loyalists** | 995 | 19.9% | $1,685.72 | 12.6 | 39.3 days | 59.2% |
| 2 | **Low-Frequency At-Risk** | 615 | 12.3% | $599.05 | 7.7 | 138.9 days | 15.3% |
| 3 | **Discount-Driven Shoppers** | 1,281 | 25.6% | $521.60 | 7.4 | 33.6 days | 37.2% |
| 4 | **Active Mid-Tier Regulars** | 2,109 | 42.2% | $468.34 | 7.3 | 31.6 days | 41.9% |

---

## 6. Supervised Purchase Prediction (Machine Learning)

### 6.1 Performance Benchmarking
Models were evaluated on the holdout test set (1,250 observations, 40.8% positive class rate):

| Model Algorithm | Accuracy | Precision | Recall (Sensitivity) | Specificity | F1-Score | ROC-AUC |
|:---|---:|---:|---:|---:|---:|---:|
| **Logistic Regression (Baseline)** | 0.6720 | 0.6263 | 0.4863 | 0.8000 | 0.5473 | **0.7244** |
| **Random Forest (200 Trees)** | 0.6568 | 0.6053 | 0.4569 | 0.7946 | 0.5208 | **0.6942** |

### 6.2 Key Predictors of Purchase Propensity
The top predictors identified by Random Forest Gini Impurity and Logistic Regression coefficients:
1. `Recency_Days` (negative relationship: recent interactions indicate high repeat propensity)
2. `Total_Purchases` (positive frequency signal)
3. `Total_Spend_USD` (monetary commitment)
4. `Loyalty_Program_Member` (strong positive categorical driver)
5. `App_Session_Minutes` & `Customer_Satisfaction_Score`

---

## 7. Business Recommendations

1. **High-Value Loyalists:** Deploy VIP concierge support, tiered non-cash perks, and exclusive previews rather than price cuts.
2. **Low-Frequency At-Risk:** Trigger automated win-back emails at day 45 and 75 post-purchase with personalized incentives.
3. **Discount-Driven Shoppers:** Implement minimum purchase thresholds (e.g., "$15 off orders over $100") and product bundling to protect operating margins.
4. **Predictive Campaign Prioritization:** Allocate outbound marketing spend to customers in the 0.40–0.70 predicted probability bracket to maximize incremental return on ad spend (ROAS).

---

## 8. Interactive Demonstration Dashboard

An interactive R Shiny dashboard (`app/app.R`) provides:
- Executive KPI summary cards and metadata.
- Dynamic Exploratory Data Analysis with feature and cohort selectors.
- 2D interactive K-Means segmentation maps.
- Test set model performance diagnostics and an interactive **real-time customer scoring simulator**.
- Commercial recommendations framework.

Launch command:
```bash
Rscript -e "shiny::runApp('app', port=3838)"
```

---

## 9. Conclusion
This project successfully integrates big data preprocessing, statistical inference, unsupervised clustering, and predictive machine learning within a unified, reproducible R programming framework. The system demonstrates how data-driven analytics can directly support modern e-commerce commercial strategy.
