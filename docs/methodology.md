# Analytical Methodology & Algorithmic Foundations

**Project Title:** E-Commerce Customer Behavior Analysis  
**Subtitle:** Customer Segmentation and Purchase Prediction  
**Subject:** Big Data Analytics – R Programming Mini Project  
**Academic Year:** 2026–2027  
**Institution:** Mentor Engineering College  
**Authors:** Muhammed Shijil MK, Navin Krishna IN, Abinshah PM, Liju Shirvan, Hishal MT  

---

## 1. Overview of the Analytical Framework

The analytical architecture integrates unsupervised pattern discovery with supervised predictive classification. The pipeline operates in two primary analytical phases:
1. **Unsupervised Customer Segmentation:** Identifying latent customer personas without pre-existing labels using **K-Means Clustering**.
2. **Supervised Purchase Prediction:** Modeling the conditional probability of future customer transaction events over a 30-day target observation window using **Logistic Regression** and **Random Forest** algorithms.

```
+-------------------------------------------------------------------------+
|                        RAW E-COMMERCE DATASET                           |
|      (Customer Demographics, Spend, Frequency, Recency, Telemetry)      |
+-------------------------------------------------------------------------+
                                    |
                                    v
+-------------------------------------------------------------------------+
|                   DATA PREPROCESSING & CLEANSING PIPELINE               |
|  - Duplicate Removal            - Median Imputation for Missing Values  |
|  - Feature Engineering (RFM)    - Stratified Train/Test Split (75/25)   |
+-------------------------------------------------------------------------+
             |                                              |
             v                                              v
+---------------------------+                 +---------------------------+
| UNSUPERVISED LEARNING     |                 | SUPERVISED LEARNING       |
| - Z-Score Standardization |                 | - Baseline: Logistic Reg. |
| - WCSS / Elbow Method     |                 | - Advanced: Random Forest |
| - Silhouette Validation   |                 | - Confusion Matrix & F1   |
| - K-Means Clustering (k=4)|                 | - ROC-AUC Discrimination  |
+---------------------------+                 +---------------------------+
             \                                              /
              \                                            /
               v                                          v
+-------------------------------------------------------------------------+
|                  PRESCRIPTIVE BUSINESS INTELLIGENCE                     |
|  - VIP Concierge Retention      - At-Risk Dynamic Win-Back Automation   |
|  - Margin & Promotion Rules     - Propensity-Driven ROAS Optimization   |
+-------------------------------------------------------------------------+
```

---

## 2. Unsupervised Learning: K-Means Clustering

### 2.1 Mathematical Objective Function
K-Means partitions $N$ observations into $K$ mutually exclusive clusters $S = \{S_1, S_2, \dots, S_K\}$ by minimizing the total Within-Cluster Sum of Squares (WCSS):

$$\min_{S} \sum_{k=1}^{K} \sum_{x_i \in S_k} ||x_i - \mu_k||^2$$

where:
- $x_i$ represents the $p$-dimensional standardized feature vector for customer $i$.
- $\mu_k = \frac{1}{|S_k|} \sum_{x_i \in S_k} x_i$ denotes the centroid of cluster $S_k$.
- $||\cdot||$ denotes the standard Euclidean distance metric:

$$d(x_i, \mu_k) = \sqrt{\sum_{j=1}^{p} (x_{ij} - \mu_{kj})^2}$$

### 2.2 Feature Scaling
Because Euclidean distance is sensitive to variable variances, all continuous clustering features are standardized using Z-score scaling:

$$z_{ij} = \frac{x_{ij} - \bar{x}_j}{s_j}$$

where $\bar{x}_j$ is the empirical mean and $s_j$ is the sample standard deviation of feature $j$. This guarantees that high-magnitude metrics (such as lifetime spend in thousands of dollars) do not artificially dominate low-magnitude metrics (such as order frequencies or discount ratios).

### 2.3 Determining Optimal $K$

#### A. The Elbow Method (WCSS Inflection)
The total within-cluster sum of squares decreases monotonically as $K$ increases. The optimal $K$ corresponds to the "elbow" point where the marginal rate of variance explanation drops sharply:

$$\Delta \text{WCSS}(K) = \text{WCSS}(K) - \text{WCSS}(K+1)$$

#### B. Silhouette Analysis
To validate cluster cohesion and separation, the silhouette coefficient $s(i)$ is computed for each customer:

$$s(i) = \frac{b(i) - a(i)}{\max(a(i), b(i))}$$

where:
- $a(i)$ is the mean intra-cluster distance between customer $i$ and all other members in the same cluster.
- $b(i)$ is the minimum mean distance from customer $i$ to any point in the nearest neighboring cluster.
- The average silhouette score ranges from $-1$ to $+1$, where values $> 0.2$ denote cohesive clustering structure.

---

## 3. Supervised Learning: Purchase Prediction

### 3.1 Problem Formulation & Target Specification
The supervised target $Y_i \in \{0, 1\}$ represents whether customer $i$ completed a repeat purchase in the subsequent 30-day evaluation window:
- $Y_i = 1$: Customer returned and made a purchase (Repeat Buyer).
- $Y_i = 0$: Customer did not purchase during the period (Non-Repeat Buyer).

### 3.2 Baseline Model: Logistic Regression
Logistic Regression models the posterior class probability using the logistic sigmoid link function:

$$P(Y_i = 1 | X_i) = \pi(X_i) = \frac{1}{1 + e^{-(\beta_0 + \beta_1 X_{i1} + \dots + \beta_p X_{ip})}}$$

The log-odds (logit transformation) provides a linear representation:

$$\ln\left(\frac{\pi(X_i)}{1 - \pi(X_i)}\right) = \beta_0 + \sum_{j=1}^{p} \beta_j X_{ij}$$

Parameters $\boldsymbol{\beta}$ are estimated by maximizing the Bernoulli log-likelihood via Iteratively Reweighted Least Squares (IRLS):

$$\ell(\boldsymbol{\beta}) = \sum_{i=1}^{n} \left[ y_i \ln(\pi(X_i)) + (1 - y_i) \ln(1 - \pi(X_i)) \right]$$

### 3.3 Advanced Model: Random Forest Classification
Random Forest constructs an ensemble of $B$ decorrelated classification trees using Bootstrap Aggregation (Bagging) and Random Feature Subspace selection:

1. For tree $b = 1, \dots, B$:
   - Draw a bootstrap sample $\mathcal{D}_b$ of size $N$ with replacement from the training set.
   - Grow an unpruned decision tree $T_b$. At each split node, randomly select $m = \lfloor \sqrt{p} \rfloor$ features from the total $p$ predictors. Choose the best split among the $m$ candidates using Gini Impurity reduction:
   
$$I_G(t) = 1 - \sum_{c \in \{0, 1\}} p(c|t)^2$$

2. The ensemble probability estimate is the fraction of individual trees voting for class 1:

$$\hat{P}(Y = 1 | X) = \frac{1}{B} \sum_{b=1}^{B} I(T_b(X) = 1)$$

### 3.4 Feature Importance Estimation
Feature importance is quantified using the **Mean Decrease in Gini Index**, calculated as the total reduction in node impurity contributed by each predictor across all $B$ ensemble trees:

$$\text{Importance}(X_j) = \frac{1}{B} \sum_{b=1}^{B} \sum_{t \in T_b: v(t) = j} \Delta I_G(t)$$

---

## 4. Evaluation Metrics & Theoretical Rationale

| Evaluation Metric | Mathematical Formula | Contextual Interpretation in E-Commerce |
|:---|:---|:---|
| **Accuracy** | $\frac{\text{TP} + \text{TN}}{\text{TP} + \text{TN} + \text{FP} + \text{FN}}$ | Proportion of total correct classifications across both buyer and non-buyer cohorts. |
| **Precision** | $\frac{\text{TP}}{\text{TP} + \text{FP}}$ | Proportion of predicted repeat buyers who actually complete a purchase. Essential for controlling marketing ad spend waste. |
| **Recall (Sensitivity)** | $\frac{\text{TP}}{\text{TP} + \text{FN}}$ | Proportion of true repeat buyers identified by the model. Crucial for maximizing revenue capture. |
| **Specificity** | $\frac{\text{TN}}{\text{TN} + \text{FP}}$ | Proportion of non-buyers correctly screened out to prevent unnecessary outbound marketing. |
| **F1-Score** | $2 \cdot \frac{\text{Precision} \cdot \text{Recall}}{\text{Precision} + \text{Recall}}$ | Harmonic mean of Precision and Recall, balancing precision costs against recall opportunities. |
| **ROC-AUC** | $\int_{0}^{1} \text{TPR}(t) \, d(\text{FPR}(t))$ | Area under the Receiver Operating Characteristic curve. Measures discriminatory ability independent of classification threshold. |

---

## 5. Statistical Inference & Hypothesis Testing

To ensure conclusions are scientifically sound rather than anecdotal, inferential tests are conducted:
1. **Pearson's Product-Moment Correlation Test:** Evaluates linear association between numerical continuous attributes.
2. **Welch's Two-Sample t-Test:** Compares mean spending and engagement across groups without assuming equal variances:

$$t = \frac{\bar{X}_1 - \bar{X}_2}{\sqrt{\frac{s_1^2}{n_1} + \frac{s_2^2}{n_2}}}$$

3. **One-Way Analysis of Variance (ANOVA):** Evaluates between-group versus within-group variance across product category preferences:

$$F = \frac{\text{MS}_{\text{between}}}{\text{MS}_{\text{within}}}$$

4. **Pearson's Chi-Square Test of Independence:** Assesses independence between categorical attributes (e.g. Loyalty Membership and Repeat Purchase):

$$\chi^2 = \sum \frac{(O_{ij} - E_{ij})^2}{E_{ij}}$$
