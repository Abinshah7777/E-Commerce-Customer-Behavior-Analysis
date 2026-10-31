# E-Commerce Customer Behavior Analysis
### Customer Segmentation and Purchase Prediction

---

**Academic Subject:** Big Data Analytics – R Programming Mini Project
**Institution:** Mentor Engineering College
**Department:** Department of Artificial Intelligence and Data Science & Department of Computer Science and Engineering
**Academic Year:** 2026–2027
**Dataset:** Customer Shopping Trends Dataset (Kaggle)
**Date:** October 2026

---

## 1. Executive Summary

This academic project implements an end-to-end Big Data Analytics and Machine Learning pipeline engineered in R programming.
The platform analyzes multi-dimensional customer transaction footprints to address two core commercial objectives:

1. **Unsupervised Customer Segmentation:** K-Means clustering applied to behavioral vectors.
2. **Supervised Machine Learning:** Propensity modeling using Logistic Regression and Random Forest classifiers.

---

## 2. Customer Segmentation Summary

| Cluster ID | Segment Persona | Customers | Share (%) |
|:---|:---|---:|---:|
| 2 | **Low-Frequency At-Risk** | 1,311 | 33.62% |
| 1 | **Discount-Driven Shoppers** | 1,033 | 26.49% |
| 3 | **High-Value Loyalists** | 1,014 | 26.00% |
| 4 | **Active Mid-Tier Regulars** | 542 | 13.90% |


---

## 3. Supervised Model Benchmark

| Model Algorithm | Accuracy | Precision | Recall | F1-Score | ROC-AUC |
|:---|---:|---:|---:|---:|---:|
| **Logistic Regression (Baseline)** | 0.8492 | 0.6543 | 0.9354 | 0.7700 | **0.8998** |
| **Random Forest (200 Trees)** | 0.8564 | 0.6804 | 0.8821 | 0.7682 | **0.9139** |


---

## 4. Inferential Statistical Hypothesis Testing

| Test ID | Statistical Test | Hypothesis Tested | Test Statistic | p-Value | Academic Decision |
|:---|:---|:---|:---|:---|:---|
| STAT-01 | Pearson's Product-Moment Correlation | H0: No correlation between Total_Purchases and Total_Spend_USD vs H1: Correlation exists | t = 76.87 (df = 3898) | `< 1e-04` | **Reject H0 (Statistically Significant)** |
| STAT-02 | Welch Two-Sample t-Test | H0: Mean Total_Spend_USD (No) = Mean Total_Spend_USD (Yes) vs H1: Means differ | t = -1.14 (df = 1901.9) | `0.25501` | **Fail to Reject H0** |
| STAT-03 | One-Way Analysis of Variance (ANOVA) | H0: Mean Total_Spend_USD is identical across all Preferred_Category levels vs H1: At least one differs | F = 0.83 (df1 = 3, df2 = 3896) | `0.47923` | **Fail to Reject H0** |


---

## 5. Strategic Commercial Recommendations

| Pillar | Target Audience | Proposed Action | Expected Business Benefit |
|:---|:---|:---|:---|
| **VIP Retention & Lifetime Value Maximization** | Low-Frequency At-Risk | Implement dedicated concierge account management, exclusive early-access product drops, and invite-only VIP rewards. | Reduces premium customer churn by 15-25% and expands customer lifetime value through high-margin upsells. |
| **Churn Prevention & Win-Back Automation** | Lapsed / At-Risk Cohorts | Deploy automated multi-stage email win-back workflows featuring personalized catalog recommendations and limited-time re-activation perks. | Recovers 8-12% of lapsed customers into active spending cycles. |
| **Basket Size Expansion & Cross-Selling** | Regular Mid-Tier Buyers | Introduce dynamic cart-level product bundling, minimum spend free-shipping thresholds, and personalized category cross-sells. | Increases average order value by 12-18% across high-frequency buyers. |
| **Discount Governance & Margin Protection** | Promotion-Sensitive Buyers | Replace blanket site-wide sales with personalized margin-gated coupon thresholds (e.g., minimum cart value required). | Safeguards gross product margin while preserving purchase incentive. |


---

*(Report generated automatically by the E-Commerce Customer Behavior Analytics Pipeline)*
