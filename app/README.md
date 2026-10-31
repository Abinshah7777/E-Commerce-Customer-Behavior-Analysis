# Interactive R Shiny Dashboard: E-Commerce Customer Analytics

This directory contains the interactive R Shiny Dashboard for:
**E-Commerce Customer Behavior Analysis: Customer Segmentation and Purchase Prediction**
Mentor Engineering College (2026–2027)

---

## 1. How to Launch the Dashboard

From the project root directory, execute the following command in PowerShell, Terminal, or Command Prompt:

```bash
Rscript -e "shiny::runApp('app', launch.browser = TRUE, port = 3838)"
```

Alternatively, from within R or RStudio:

```R
shiny::runApp("app", port = 3838)
```

The application will start and automatically open in your default web browser at:
`http://127.0.0.1:3838`

---

## 2. Dashboard Features & Tabs

1. **Overview & KPIs:** Executive summary cards showing total customers, average lifetime spend, loyalty penetration, and repeat purchase propensity, alongside project attribution metadata.
2. **Exploratory Analysis:** Dynamic histogram and density explorer with metric selectors (Spend, Frequency, AOV, Recency, Session duration, Age) and preferred category filters.
3. **Customer Segmentation (K-Means):** Interactive 2D scatter plot mapping Recency vs Total Spend colored by customer personas with an interactive **Customer Segment Filter** dropdown to isolate and view only specific customer dots (or all 4 segments) along with dynamic cohort metrics and summary badges, accompanied by detailed cluster profile tables.
4. **Purchase Prediction & Real-Time Scoring Calculator:** Holdout test set comparison metrics (Accuracy, Precision, Recall, F1, ROC-AUC), Random Forest Gini feature importance rankings, and an **interactive simulator** where you can adjust customer attributes and view live predicted repeat purchase probabilities and customer tier classifications.
5. **Business Recommendations:** Actionable commercial recommendations mapping discovered personas to targeted marketing campaigns, loyalty incentives, and margin governance.
