# E-Commerce Customer Behavior Analysis: Customer Segmentation and Purchase Prediction

[![R Version](https://img.shields.io/badge/R-4.6.1-blue.svg)](https://cloud.r-project.org/)
[![Subject](https://img.shields.io/badge/Subject-Big%20Data%20Analytics-green.svg)](#)
[![Academic Year](https://img.shields.io/badge/Academic%20Year-2026--2027-orange.svg)](#)
[![Institution](https://img.shields.io/badge/Institution-Mentor%20Engineering%20College-red.svg)](#)
[![Tests Status](https://img.shields.io/badge/Tests-10%2F10%20Passed%20(100%25)-brightgreen.svg)](#)

A complete end-to-end Big Data Analytics and Machine Learning academic mini project implemented from scratch in **R programming**. This project uncovers latent customer personas via **K-Means clustering** and predicts future repeat purchase likelihood via **Logistic Regression** and **Random Forest** classification algorithms.

---

## 1. Project Information & Metadata

- **Project Title:** E-Commerce Customer Behavior Analysis
- **Subtitle:** Customer Segmentation and Purchase Prediction
- **Subject:** Big Data Analytics – R Programming Mini Project
- **Institution:** Mentor Engineering College
- **Departments:**
  - Department of Artificial Intelligence and Data Science
  - Department of Computer Science and Engineering
- **Programme:** Bachelor of Technology (B.Tech)
- **Academic Year:** 2026–2027
- **Submitted By:**
  1. Muhammed Shijil MK
  2. Navin Krishna IN
  3. Abinshah PM
  4. Liju Shirvan
  5. Hishal MT
- **Date:** October 2026

---

## 2. Project Overview & Objectives

E-commerce platforms capture high-velocity, high-volume transactional footprints and user telemetry. Analyzing this data enables retailers to transition from untargeted blanket marketing to personalized customer lifecycle strategies.

### Primary Objectives:
1. **Unsupervised Customer Segmentation:** Cluster customers using RFM metrics (Recency, Frequency, Monetary value), mobile app engagement, and discount usage using **K-Means** ($K = 4$).
2. **Supervised Purchase Prediction:** Predict customer repeat purchase events within a forward-looking 30-day window using **Logistic Regression** (baseline) and **Random Forest** (ensemble classifier), preventing target leakage.
3. **Data Quality & Auditing:** Audit and resolve duplicate rows, handle missing attributes via median imputation, and standardize multi-scale numerical variables.
4. **Inferential Statistical Testing:** Validate empirical differences using Pearson correlation, Welch’s two-sample t-tests, One-Way ANOVA, and Pearson’s Chi-Square tests of independence.
5. **Interactive Demonstration & Business Intelligence:** Provide an interactive **R Shiny Dashboard** with real-time ML scoring and formulate actionable, ROI-focused commercial strategies.

---

## 3. Technology Stack & Dependencies

| Category | Technology / Package | Purpose |
|:---|:---|:---|
| **Programming Language** | R (v4.6.1) | Core statistical computing and pipeline execution |
| **Data Manipulation** | `dplyr` (v1.2.1), `tidyr` (v1.3.2), `readr` (v2.2.0) | Data wrangling, filtering, reshaping, and CSV I/O |
| **Data Visualization** | `ggplot2` (v4.0.3), `scales` (v1.4.0) | High-resolution publication-grade visualization suite |
| **Clustering & Segmentation**| `stats::kmeans()`, `cluster` (v2.1.8.2) | K-Means clustering, Elbow method, and Silhouette analysis |
| **Predictive Modeling** | `stats::glm()`, `randomForest` (v4.7-1.2) | Logistic regression, random forest ensembles, Gini importance |
| **Interactive Interface** | `shiny` (v1.14.0), `bslib` (v0.12.0) | Interactive dashboard with real-time customer scoring |
| **Package Management** | `renv.lock` | Exact dependency locking and reproducibility |

---

## 4. Complete Directory Structure

```
E-Commerce-Customer-Behavior-Analysis/
│
├── README.md                      # Primary project documentation, architecture, and instructions
├── main.R                         # Master pipeline orchestrator (Rscript main.R)
├── setup.R                        # Automated dependency verification and environment setup
├── config.R                       # Centralized project configuration, paths, and hyperparameters
├── renv.lock                      # Dependency lockfile recording exact package versions
├── .gitignore                     # Git ignore rules for R environment and caches
│
├── data/
│   ├── raw/
│   │   └── customer_data.csv      # Raw synthesized customer dataset (5,015 rows, 17 columns)
│   ├── processed/
│   │   └── cleaned_customer_data.csv # Cleansed, imputed, deduplicated dataset (5,000 rows)
│   └── README.md                  # Comprehensive dataset schema and provenance documentation
│
├── R/
│   ├── data_loading.R             # Data ingestion and reproducible synthetic simulation engine
│   ├── data_preprocessing.R       # Data auditing, median imputation, Z-score scaling, train/test split
│   ├── exploratory_analysis.R     # Descriptive statistics, category summaries, correlation matrix
│   ├── statistical_analysis.R     # Hypothesis testing (Welch t-tests, ANOVA, Chi-Square, Pearson r)
│   ├── customer_segmentation.R    # K-Means clustering, WCSS Elbow method, Silhouette, cluster profiles
│   ├── purchase_prediction.R      # Logistic Regression & Random Forest classifiers, ROC-AUC, scoring
│   ├── visualization.R            # 15 publication-grade ggplot2 visualizations (300 DPI)
│   ├── business_insights.R        # Prescriptive commercial strategies and recommendation engine
│   └── generate_report.R          # Automated Markdown and HTML academic report generator
│
├── outputs/
│   ├── plots/                     # 15 High-resolution analytical charts (.png, 300 DPI)
│   │   ├── plot_01_spending_distribution.png
│   │   ├── plot_02_purchase_frequency.png
│   │   ├── plot_03_customer_age_distribution.png
│   │   ├── plot_04_spending_by_category.png
│   │   ├── plot_05_correlation_heatmap.png
│   │   ├── plot_06_target_distribution.png
│   │   ├── plot_07_missing_data_summary.png
│   │   ├── plot_08_elbow_method.png
│   │   ├── plot_09_silhouette_analysis.png
│   │   ├── plot_10_cluster_scatter_rfm.png
│   │   ├── plot_11_cluster_profile_radar_bars.png
│   │   ├── plot_12_model_roc_curves.png
│   │   ├── plot_13_feature_importance.png
│   │   ├── plot_14_confusion_matrices.png
│   │   └── plot_15_predicted_probabilities.png
│   ├── tables/                    # 8 Structured analytical CSV data tables
│   │   ├── preprocessing_summary.csv
│   │   ├── descriptive_statistics.csv
│   │   ├── categorical_distributions.csv
│   │   ├── category_spending_summary.csv
│   │   ├── correlation_matrix.csv
│   │   ├── hypothesis_testing_results.csv
│   │   ├── clustering_metrics_k_evaluation.csv
│   │   ├── cluster_profile_summary.csv
│   │   ├── customer_cluster_assignments.csv
│   │   ├── model_comparison_metrics.csv
│   │   ├── confusion_matrices.csv
│   │   ├── feature_importance.csv
│   │   ├── test_set_predictions.csv
│   │   └── business_recommendations.csv
│   ├── models/                    # Persisted serialized model binaries (.rds)
│   │   ├── kmeans_model.rds
│   │   ├── logistic_regression_model.rds
│   │   └── random_forest_model.rds
│   └── reports/                   # Automated academic reports (.md and .html)
│       ├── analytical_report.md
│       └── analytical_report.html
│
├── tests/
│   └── test_pipeline.R            # Automated unit and integration test suite (10 test cases)
│
├── docs/
│   ├── project_documentation.md   # Full formal academic project report
│   ├── methodology.md             # In-depth theoretical and mathematical foundations
│   └── viva_questions.md          # 30+ Academic viva questions with detailed answers
│
└── app/
    ├── app.R                      # Interactive R Shiny dashboard with real-time scoring
    └── README.md                  # Dashboard execution instructions and feature overview
```

---

## 5. Prerequisites & Quick Start Guide

### Step 1: Verify R Installation
Ensure R (v4.0 or higher; v4.6.1 recommended) is installed on your operating system:
```bash
Rscript --version
```

### Step 2: Set Up Environment & Install Packages
Run the automated environment setup script:
```bash
Rscript setup.R
```
This verifies R version compatibility, creates all output directories, installs missing CRAN dependencies (`dplyr`, `tidyr`, `readr`, `ggplot2`, `scales`, `cluster`, `randomForest`, `shiny`), and verifies successful loading.

### Step 3: Execute the Complete End-to-End Analytics Pipeline
Run the master orchestration script:
```bash
Rscript main.R
```
The master script sequentially executes all 11 stages of data ingestion, preprocessing, EDA, statistical testing, K-Means clustering, predictive modeling, visualization generation, business translation, and automated report generation in under 45 seconds.

### Step 4: Run the Automated Test Suite
Verify that all mathematical and software invariants pass:
```bash
Rscript tests/test_pipeline.R
```
Expected output: `TEST RESULTS: 10 / 10 TESTS PASSED (100.0%)`.

### Step 5: Launch the Interactive R Shiny Dashboard (Optional)
Launch the interactive web platform to explore charts and test real-time customer scoring:
```bash
Rscript -e "shiny::runApp('app', launch.browser = TRUE, port = 3838)"
```
Then navigate to `http://127.0.0.1:3838` in your web browser.

---

## 6. Key Empirical Results & Personas

### 6.1 Discovered Customer Personas ($K = 4$)
| Cluster Persona | Customer Share | Mean Lifetime Spend | Mean Orders | Recency | Repeat Purchase Rate | Commercial Strategy |
|:---|---:|---:|---:|---:|---:|:---|
| **High-Value Loyalists** | 19.9% (995) | **$1,685.72** | 12.6 | 39.3 days | **59.2%** | VIP Concierge, Tiered Perks, No heavy discounts |
| **Active Mid-Tier Regulars** | 42.2% (2,109) | **$468.34** | 7.3 | 31.6 days | **41.9%** | Cross-selling, Category expansion incentives |
| **Discount-Driven Shoppers** | 25.6% (1,281) | **$521.60** | 7.4 | 33.6 days | **37.2%** | Minimum basket thresholds ($100+), margin protection |
| **Low-Frequency At-Risk** | 12.3% (615) | **$599.05** | 7.7 | 138.9 days | **15.3%** | Automated win-back workflows, feedback surveys |

### 6.2 Predictive Modeling Benchmark (Holdout Test Set)
| Model Algorithm | Accuracy | Precision | Recall (Sensitivity) | Specificity | F1-Score | ROC-AUC |
|:---|---:|---:|---:|---:|---:|---:|
| **Logistic Regression (Baseline)** | 0.6720 | 0.6263 | 0.4863 | 0.8000 | 0.5473 | **0.7244** |
| **Random Forest (200 Trees)** | 0.6568 | 0.6053 | 0.4569 | 0.7946 | 0.5208 | **0.6942** |

- **Top Propensity Predictors:** `Recency_Days` (negative relationship), `Total_Purchases` (positive frequency signal), `Total_Spend_USD` (monetary commitment), `Loyalty_Program_Member` (status driver), and `App_Session_Minutes`.

---

## 7. Documentation Directory Guide

- **[Project Documentation](docs/project_documentation.md):** Complete formal academic project report.
- **[Methodological Foundations](docs/methodology.md):** Theoretical derivations for K-Means, WCSS, Silhouette, Logistic Regression, Random Forest, and ROC-AUC.
- **[Viva Voce Questions & Answers](docs/viva_questions.md):** 30+ comprehensive questions and answers covering R, Big Data Analytics, ML, and business intelligence.
- **[Dataset Documentation](data/README.md):** Complete data schema, data generating process, and ethical considerations.
- **[Interactive Dashboard Guide](app/README.md):** Guide to launching and navigating the Shiny application.

---

## 8. Academic Deliverables Verification Checklist

- [x] R Programming as primary language (no Python substitution).
- [x] Complete directory structure created from scratch.
- [x] Reproducible dataset with complete schema and data dictionary.
- [x] Audited preprocessing pipeline (duplicates, missing imputation, scaling, stratified split).
- [x] Exploratory Data Analysis & Inferential Hypothesis Testing (t-tests, ANOVA, Chi-Square).
- [x] K-Means clustering with Elbow Method and Silhouette evaluation.
- [x] Supervised predictive classification (Logistic Regression & Random Forest).
- [x] 15 high-resolution `ggplot2` figures exported to `outputs/plots/`.
- [x] 8 structured analytical CSV tables exported to `outputs/tables/`.
- [x] Interactive R Shiny Dashboard with real-time scoring calculator (`app/app.R`).
- [x] Automated analytical Markdown & HTML report generator.
- [x] 10/10 automated tests passing with 100% success (`tests/test_pipeline.R`).
- [x] Complete academic report, methodology, and viva questions.

---

## 9. License & Attribution
Developed for the **B.Tech Mini Project (Academic Year 2026–2027)** at **Mentor Engineering College**, Department of Artificial Intelligence and Data Science & Department of Computer Science and Engineering.
#   E - C o m m e r c e - C u s t o m e r - B e h a v i o r - A n a l y s i s  
 