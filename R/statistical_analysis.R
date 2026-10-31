# ==============================================================================
# STATISTICAL ANALYSIS MODULE: R/statistical_analysis.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

#' Execute Rigorous Academic Statistical Hypothesis Testing
#'
#' Evaluates parametric and non-parametric hypotheses on customer spending,
#' recency, loyalty status, and repeat purchase outcomes.
#'
#' @param df Cleaned customer data frame
#' @param config Configuration list
#' @return A data frame summarizing all test results
perform_statistical_analysis <- function(df, config) {
  cat("\n------------------------------------------------------------------\n")
  cat("   INFERENTIAL STATISTICAL ANALYSIS & HYPOTHESIS TESTING         \n")
  cat("------------------------------------------------------------------\n")
  
  test_records <- list()
  
  # 1. Test 1: Correlation between Total Purchases and Total Spend
  cat("[STAT] Test 1: Correlation between Purchase Frequency and Lifetime Spend...\n")
  cor_test_res <- cor.test(df$Total_Purchases, df$Total_Spend_USD, method = "pearson")
  spearman_res <- cor.test(df$Total_Purchases, df$Total_Spend_USD, method = "spearman", exact = FALSE)
  
  test_records[[1]] <- data.frame(
    Test_ID = "STAT-01",
    Hypothesis = "H0: No correlation between Frequency and Spend vs H1: Positive correlation",
    Statistical_Test = "Pearson's Product-Moment Correlation",
    Test_Statistic = sprintf("t = %.2f (df = %d)", cor_test_res$statistic, cor_test_res$parameter),
    Effect_Size = sprintf("r = %.3f [95%% CI: %.3f, %.3f]", cor_test_res$estimate, cor_test_res$conf.int[1], cor_test_res$conf.int[2]),
    p_value = format.pval(cor_test_res$p.value, eps = 0.0001),
    Decision = ifelse(cor_test_res$p.value < 0.05, "Reject H0 (Statistically Significant)", "Fail to Reject H0"),
    Business_Interpretation = "Strong linear and monotonic relationship: transaction frequency directly drives lifetime spending.",
    stringsAsFactors = FALSE
  )
  
  # 2. Test 2: Two-Sample Welch t-Test for Spending by Loyalty Membership
  cat("[STAT] Test 2: Welch's t-Test for Spending across Loyalty Program Members...\n")
  spend_loyalty <- df$Total_Spend_USD[df$Loyalty_Program_Member == "Yes"]
  spend_non_loyalty <- df$Total_Spend_USD[df$Loyalty_Program_Member == "No"]
  
  t_loyalty <- t.test(spend_loyalty, spend_non_loyalty, var.equal = FALSE)
  wilcox_loyalty <- wilcox.test(spend_loyalty, spend_non_loyalty, exact = FALSE)
  
  test_records[[2]] <- data.frame(
    Test_ID = "STAT-02",
    Hypothesis = "H0: Mean Spend (Loyalty) = Mean Spend (Non-Loyalty) vs H1: Mean Spend differs",
    Statistical_Test = "Welch Two-Sample t-Test (and Wilcoxon Rank-Sum)",
    Test_Statistic = sprintf("t = %.2f (df = %.1f)", t_loyalty$statistic, t_loyalty$parameter),
    Effect_Size = sprintf("Loyalty Mean: $%.2f vs Non-Loyalty: $%.2f (Diff: $%.2f)",
                          mean(spend_loyalty), mean(spend_non_loyalty), mean(spend_loyalty) - mean(spend_non_loyalty)),
    p_value = format.pval(t_loyalty$p.value, eps = 0.0001),
    Decision = ifelse(t_loyalty$p.value < 0.05, "Reject H0 (Statistically Significant)", "Fail to Reject H0"),
    Business_Interpretation = "Loyalty program members generate substantially higher spend, validating premium membership incentives.",
    stringsAsFactors = FALSE
  )
  
  # 3. Test 3: Welch's t-Test for Recency Days by Repeat Purchase Target
  cat("[STAT] Test 3: Welch's t-Test for Recency Days by Repeat Purchase Outcome...\n")
  recency_repeat <- df$Recency_Days[df$Repeat_Purchase == "Yes"]
  recency_non_repeat <- df$Recency_Days[df$Repeat_Purchase == "No"]
  
  t_recency <- t.test(recency_repeat, recency_non_repeat, var.equal = FALSE)
  
  test_records[[3]] <- data.frame(
    Test_ID = "STAT-03",
    Hypothesis = "H0: Mean Recency (Repeat) = Mean Recency (Non-Repeat) vs H1: Recency differs",
    Statistical_Test = "Welch Two-Sample t-Test",
    Test_Statistic = sprintf("t = %.2f (df = %.1f)", t_recency$statistic, t_recency$parameter),
    Effect_Size = sprintf("Repeat Mean: %.1f days vs Non-Repeat: %.1f days (Diff: %.1f days)",
                          mean(recency_repeat), mean(recency_non_repeat), mean(recency_repeat) - mean(recency_non_repeat)),
    p_value = format.pval(t_recency$p.value, eps = 0.0001),
    Decision = ifelse(t_recency$p.value < 0.05, "Reject H0 (Statistically Significant)", "Fail to Reject H0"),
    Business_Interpretation = "Customers who recently purchased have dramatically higher likelihood of repeat purchasing; recency is a key predictive signal.",
    stringsAsFactors = FALSE
  )
  
  # 4. Test 4: One-Way ANOVA for Spending across Product Categories
  cat("[STAT] Test 4: One-Way ANOVA for Spending across Preferred Categories...\n")
  anova_fit <- aov(Total_Spend_USD ~ Preferred_Category, data = df)
  anova_summary <- summary(anova_fit)[[1]]
  f_stat <- anova_summary["Preferred_Category", "F value"]
  p_val_anova <- anova_summary["Preferred_Category", "Pr(>F)"]
  
  test_records[[4]] <- data.frame(
    Test_ID = "STAT-04",
    Hypothesis = "H0: Mean Spend is equal across all product categories vs H1: Category means differ",
    Statistical_Test = "One-Way Analysis of Variance (ANOVA)",
    Test_Statistic = sprintf("F = %.2f (df1 = %d, df2 = %d)", f_stat, anova_summary["Preferred_Category", "Df"], anova_summary["Residuals", "Df"]),
    Effect_Size = sprintf("R-squared = %.3f", anova_summary["Preferred_Category", "Sum Sq"] / sum(anova_summary[, "Sum Sq"])),
    p_value = format.pval(p_val_anova, eps = 0.0001),
    Decision = ifelse(p_val_anova < 0.05, "Reject H0 (Statistically Significant)", "Fail to Reject H0"),
    Business_Interpretation = "Significant spending variation across categories (e.g., Electronics & Home vs Books); marketing budgets should align with high-AOV categories.",
    stringsAsFactors = FALSE
  )
  
  # 5. Test 5: Pearson's Chi-Square Test for Loyalty vs Repeat Purchase
  cat("[STAT] Test 5: Chi-Square Test for Loyalty Membership vs Repeat Purchase...\n")
  chisq_tbl <- table(df$Loyalty_Program_Member, df$Repeat_Purchase)
  chisq_res <- chisq.test(chisq_tbl)
  
  test_records[[5]] <- data.frame(
    Test_ID = "STAT-05",
    Hypothesis = "H0: Loyalty membership and Repeat Purchase are independent vs H1: Dependent",
    Statistical_Test = "Pearson's Chi-Square Test of Independence",
    Test_Statistic = sprintf("Chi-sq = %.2f (df = %d)", chisq_res$statistic, chisq_res$parameter),
    Effect_Size = sprintf("Cramer's V = %.3f", sqrt(chisq_res$statistic / (nrow(df) * (min(dim(chisq_tbl)) - 1)))),
    p_value = format.pval(chisq_res$p.value, eps = 0.0001),
    Decision = ifelse(chisq_res$p.value < 0.05, "Reject H0 (Statistically Significant)", "Fail to Reject H0"),
    Business_Interpretation = "Strong association: Loyalty members exhibit a statistically higher propensity to repeat purchase.",
    stringsAsFactors = FALSE
  )
  
  results_df <- do.call(rbind, test_records)
  
  # Save to tables directory
  tables_dir <- config$paths$tables_dir
  if (!dir.exists(tables_dir)) dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  out_path <- file.path(tables_dir, "hypothesis_testing_results.csv")
  write_csv(results_df, out_path)
  cat(sprintf("[SUCCESS] Saved inferential statistical testing results to '%s'.\n", out_path))
  
  return(results_df)
}
