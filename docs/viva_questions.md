# Comprehensive Viva Voce Questions & Answers

**Project Title:** E-Commerce Customer Behavior Analysis  
**Subtitle:** Customer Segmentation and Purchase Prediction  
**Subject:** Big Data Analytics – R Programming Mini Project  
**Institution:** Mentor Engineering College  
**Academic Year:** 2026–2027  
**Students:** Muhammed Shijil MK, Navin Krishna IN, Abinshah PM, Liju Shirvan, Hishal MT  

---

## Section 1: Big Data Analytics & Project Context

### Q1. What is the business problem addressed by this mini project?
**Answer:** Modern e-commerce platforms struggle with customer churn, uniform blanket discounting, and inefficient marketing spend. This project uses Big Data Analytics and R programming to solve two core challenges:
1. **Customer Segmentation:** Grouping customers by behavioral and transactional patterns (RFM + engagement) into distinct personas using K-Means.
2. **Purchase Prediction:** Estimating the likelihood of future purchases over a 30-day window using machine learning (Logistic Regression and Random Forest) to guide targeted marketing.

### Q2. How does this project reflect the characteristics of "Big Data"?
**Answer:** The project simulates large-scale commercial clickstream and transactional behavior characterized by:
- **Volume:** Aggregating thousands of customer profiles and lifetime order records.
- **Velocity:** Simulating real-time propensity inference for incoming customers.
- **Variety:** Integrating continuous financial metrics, discrete transaction counts, categorical demographics, and web/app session telemetry.
- **Veracity:** Auditing and resolving missing values, duplicate entries, and extreme outliers.
- **Value:** Converting raw transactional logs into high-ROI marketing strategies.

### Q3. Why is customer segmentation critical for an e-commerce enterprise?
**Answer:** Customers have heterogeneous preferences, spending capacities, and churn risks. Segmentation allows businesses to transition from generic mass-marketing to personalized strategies—such as dedicated concierge services for high-value VIPs, automated win-back workflows for at-risk churners, and margin-protected minimum basket promotions for discount seekers.

---

## Section 2: R Programming Foundations

### Q4. Why was R chosen over Python for this Big Data Analytics mini project?
**Answer:** 
1. R is purpose-built for statistical computing, probability modeling, and data science.
2. The `tidyverse` ecosystem (`dplyr`, `readr`, `tidyr`, `ggplot2`) provides expressive and readable syntax for end-to-end data pipelines.
3. R provides built-in statistical functions (`t.test`, `aov`, `chisq.test`, `cor.test`) with complete parametric diagnostics.
4. R Shiny enables direct deployment of interactive dashboards without external frontend frameworks.

### Q5. What is the difference between a `data.frame` and a `tibble` in R?
**Answer:** A `tibble` is a modernized data frame provided by the `tibble` / `dplyr` packages. Unlike base R `data.frame`, tibbles:
- Never automatically convert string characters into factors.
- Never alter column names with periods or abbreviations.
- Provide cleaner console printing (showing dimensions and column types without flooding the terminal).

### Q6. How does vectorization work in R, and why is it important for big data?
**Answer:** Vectorization allows operations to be applied to entire vectors or arrays simultaneously via optimized underlying C/Fortran routines rather than interpreted R `for` loops. This yields orders-of-magnitude faster execution on large datasets.

### Q7. What is the role of `set.seed()` in R?
**Answer:** `set.seed()` initializes R's pseudo-random number generator (e.g., Mersenne-Twister). Setting a fixed seed (e.g. `2026`) guarantees 100% reproducibility across data synthesis, train/test splitting, K-Means centroid initialization, and Random Forest bootstrap sampling.

---

## Section 3: Data Preprocessing & Quality Engineering

### Q8. What data quality defects were audited in the pipeline, and how were they handled?
**Answer:**
1. **Duplicates:** Identified 15 duplicate customer records using `duplicated()`; removed them to preserve uniqueness.
2. **Missing Values:** Identified ~2% missing entries in `Annual_Income_USD`, `Customer_Tenure_Months`, and `App_Session_Minutes`. Handled using median imputation to prevent distortion from right-skewed distributions.
3. **Outliers:** Audited using Interquartile Range (IQR = Q75 - Q25). Real-world VIP spenders were preserved rather than dropped to reflect genuine high-value customer dynamics.
4. **Data Types:** Converted nominal variables (`Gender`, `City_Tier`, `Preferred_Category`) into factors.

### Q9. Why did you choose Median Imputation instead of Mean Imputation?
**Answer:** Financial variables (such as income and spend) and engagement metrics are heavily right-skewed. The arithmetic mean is sensitive to extreme outliers, whereas the median is a robust non-parametric measure of central tendency that preserves natural distributions.

### Q10. What is Target Leakage, and how did your pipeline prevent it?
**Answer:** Target leakage occurs when predictor variables include information that is only generated *after* or *as a consequence* of the target event. In our project:
- Predictors represent historical observations (past spend, lifetime order counts, recency, CSAT).
- The target `Repeat_Purchase` represents a separate forward-looking 30-day evaluation window.
- No future post-period actions were included in training features.

---

## Section 4: Exploratory Data Analysis & Inferential Statistics

### Q11. What were the primary findings from your Exploratory Data Analysis?
**Answer:**
- Total spend is right-skewed (Mean: ~$740 vs Median: ~$574), confirming Pareto-like commercial behavior.
- Total orders correlate strongly with lifetime spend ($r \approx 0.60, p < 0.001$).
- High app session minutes and web visits directly associate with higher repeat purchase probability.
- Preferred product categories exhibit significant differences in mean order values (e.g. Electronics and Home & Living vs Books).

### Q12. Explain the purpose of Welch's Two-Sample t-Test in your statistical analysis.
**Answer:** Welch's t-test tests the null hypothesis that two independent populations have equal means ($H_0: \mu_1 = \mu_2$) without assuming equal population variances. We used it to prove that Loyalty Program members generate statistically significantly higher lifetime spend than non-members ($p < 0.0001$).

### Q13. Why use ANOVA instead of multiple pairwise t-tests across product categories?
**Answer:** Running multiple pairwise t-tests across 5 categories would require 10 individual tests, inflating the Family-Wise Type I Error rate ($\alpha_{\text{inflated}} = 1 - (1 - 0.05)^{10} \approx 40\%$). One-Way ANOVA tests whether any category mean differs in a single omnibus test while holding Type I error at 5%.

### Q14. What does a Chi-Square Test of Independence evaluate?
**Answer:** It assesses whether an association exists between two categorical variables ($H_0$: variables are independent vs $H_1$: variables are dependent) by comparing observed frequencies ($O_{ij}$) against expected frequencies ($E_{ij}$). We proved a statistically significant association between loyalty membership and repeat purchase propensity ($\chi^2, p < 0.001$).

---

## Section 5: Unsupervised Customer Segmentation (K-Means)

### Q15. How does the K-Means clustering algorithm work?
**Answer:**
1. Randomly initialize $K$ centroids (using `nstart = 25` to find the global minimum).
2. **Assignment Step:** Assign each customer to the nearest centroid using Euclidean distance.
3. **Update Step:** Recalculate centroids as the mean of all points assigned to that cluster.
4. Repeat until centroid movement drops below tolerance (`iter.max = 300`) or convergence.

### Q16. Why is feature scaling mandatory before running K-Means?
**Answer:** K-Means relies on Euclidean distance: $d(x, y) = \sqrt{\sum (x_j - y_j)^2}$. If features are unscaled, variables with large absolute ranges (e.g., `Total_Spend_USD` from $50 to $8,000) will dominate distances, rendering features with small ranges (such as `Total_Purchases` from 1 to 65 or `Discount_Usage` from 0 to 1) negligible. Z-score scaling puts all features on equal footing ($\mu = 0, \sigma = 1$).

### Q17. How did you determine that $K = 4$ was the optimal number of clusters?
**Answer:** We evaluated $K \in [2, 8]$ using two complementary criteria:
1. **Elbow Method:** Evaluated Within-Cluster Sum of Squares (WCSS). A distinct bend/elbow appeared at $K = 4$, beyond which marginal variance explanation diminished.
2. **Silhouette Analysis:** Calculated average silhouette widths to confirm cluster cohesion and separation.
3. **Business Interpretability:** $K = 4$ mapped cleanly to four actionable personas (High-Value Loyalists, Active Regulars, Discount Shoppers, and At-Risk Churners).

### Q18. Describe the four customer personas discovered by your model.
**Answer:**
1. **High-Value Loyalists (~20%):** Highest mean spend (~$1,685), high order frequency (12.6 orders), low recency (39 days), highest repeat rate (~59%).
2. **Active Mid-Tier Regulars (~42%):** Consistent moderate spend (~$468), stable order cadence, steady repeat rate (~42%).
3. **Discount-Driven Shoppers (~26%):** High promotional coupon usage (~52%), moderate basket size, price-sensitive.
4. **Low-Frequency At-Risk (~12%):** Lapsed customers with high recency (~139 days elapsed), lowest repeat rate (~15%).

---

## Section 6: Supervised Learning & Purchase Prediction

### Q19. How did you formulate the purchase prediction task?
**Answer:** As a supervised binary classification problem. The target variable is `Repeat_Purchase` (1 = Customer placed an order in the subsequent 30-day window, 0 = Did not purchase). Models were trained on 75% of the data (3,750 records) and validated out-of-sample on holdout test data (1,250 records).

### Q20. What is Logistic Regression and why is it used as the baseline?
**Answer:** Logistic Regression is a Generalized Linear Model (GLM) with a binomial family and logit link function. It is the gold-standard baseline because it is computationally efficient, convex (guaranteed convergence), and produces directly interpretable odds ratios for each predictor.

### Q21. How does Random Forest work, and what advantages does it offer over Logistic Regression?
**Answer:** Random Forest is an ensemble of decorrelated decision trees built via:
- **Bootstrap Aggregating (Bagging):** Training each tree on a random sample drawn with replacement.
- **Random Subspace Method:** Selecting a random subset of predictors ($m = \lfloor\sqrt{p}\rfloor$) at each split.
- **Advantages:** Captures complex non-linear relationships and high-order feature interactions (such as the interaction between high satisfaction and recent visits) without requiring manual interaction terms.

### Q22. Explain the components of a Confusion Matrix.
**Answer:**
- **True Positive (TP):** Customer predicted to repeat purchase and actually did.
- **True Negative (TN):** Customer predicted not to repeat purchase and did not.
- **False Positive (FP / Type I Error):** Customer predicted to repeat purchase who did not (wastes marketing budget).
- **False Negative (FN / Type II Error):** Customer predicted not to purchase who actually would have (missed revenue opportunity).

### Q23. Why is Accuracy alone insufficient for evaluating customer purchase prediction?
**Answer:** If the dataset has class imbalance (e.g. 90% non-purchasers and 10% purchasers), a trivial model predicting "No" for everyone achieves 90% accuracy but has 0% recall and fails completely at identifying buyers. Precision, Recall, F1-Score, and ROC-AUC provide a complete, robust assessment.

### Q24. What is the difference between Precision and Recall?
**Answer:**
- **Precision:** $\frac{\text{TP}}{\text{TP} + \text{FP}}$ answers: "Of all customers predicted to buy, what fraction actually bought?"
- **Recall:** $\frac{\text{TP}}{\text{TP} + \text{FN}}$ answers: "Of all customers who actually bought, what fraction did the model catch?"

### Q25. What does the ROC-AUC metric represent?
**Answer:** The Area Under the Receiver Operating Characteristic Curve (ROC-AUC) plots True Positive Rate (Sensitivity) vs False Positive Rate ($1 - \text{Specificity}$) across all possible classification thresholds from 0.0 to 1.0. An AUC of 0.5 represents random guessing; an AUC of 1.0 represents perfect discrimination. Our models achieve strong AUC scores (~0.70–0.72), demonstrating strong ranking capability.

### Q26. Which features were identified as the strongest predictors of repeat purchase?
**Answer:** Based on Random Forest Mean Decrease in Gini Impurity and Logistic Regression z-statistics:
1. `Recency_Days` (negative relationship: lower recency = higher purchase probability)
2. `Total_Purchases` (positive frequency indicator)
3. `Total_Spend_USD` (monetary commitment)
4. `Loyalty_Program_Member` (strong positive coefficient)
5. `App_Session_Minutes` & `Customer_Satisfaction_Score`

---

## Section 7: Business Intelligence & Commercial Translation

### Q27. What strategic recommendations did you formulate for "High-Value Loyalists"?
**Answer:** Since this cohort represents ~20% of users but generates the highest spend (~$1,685), we recommend:
- Dedicated VIP concierge support and early access to new product releases.
- Tiered loyalty perks rather than cash discounts.
- Cross-category curated recommendations to maximize Customer Lifetime Value (CLV).

### Q28. How should the business re-engage the "Low-Frequency At-Risk" segment?
**Answer:** This segment has an average recency of ~139 days. We propose:
- Automated multi-channel win-back campaigns at days 45 and 75 post-purchase.
- "We Miss You" personalized incentives with a limited redemption window.
- Post-churn feedback surveys to uncover product or delivery dissatisfaction.

### Q29. How should discounts be governed for "Discount-Driven Shoppers"?
**Answer:** These customers show high coupon dependency (~52% discount usage). Blanket price discounts erode profit margins. We recommend:
- Minimum order thresholds (e.g., "Spend $100 to save $15") to protect margins.
- Bundling slow-moving or high-margin accessories with promotional discounts.

### Q30. How can the predictive ML model be used to optimize Return on Ad Spend (ROAS)?
**Answer:** By scoring all customers daily:
- Customers with predicted probability $> 0.75$ are organic "sure buyers" and do not need paid retargeting ads.
- Customers with probability $< 0.30$ are unlikely to convert regardless of ads.
- Outbound paid advertising should be targeted at the **0.40–0.70 propensity zone**, where advertising creates genuine incremental conversions.
