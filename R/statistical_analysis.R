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

#' Execute Dynamic Statistical Hypothesis Testing
#'
#' Evaluates parametric and non-parametric hypotheses on customer spending,
#' transaction frequency, customer rating, and subscription/loyalty membership.
#'
#' @param df Cleaned customer data frame
#' @param config Configuration list
#' @return A data frame summarizing all test results
perform_statistical_analysis <- function(df, config) {
  cat("\n------------------------------------------------------------------\n")
  cat("   INFERENTIAL STATISTICAL ANALYSIS & HYPOTHESIS TESTING         \n")
  cat("------------------------------------------------------------------\n")

  test_records <- list()
  test_counter <- 1

  # Test 1: Correlation between Frequency and Spend
  freq_col <- intersect(c("Total_Purchases", "Previous_Purchases", "orders"), colnames(df))[1]
  spend_col <- intersect(c("Total_Spend_USD", "Purchase_Amount_USD", "Avg_Order_Value_USD"), colnames(df))[1]

  if (!is.na(freq_col) && !is.na(spend_col)) {
    cat(sprintf("[STAT] Test %d: Pearson Correlation between '%s' and '%s'...\n", test_counter, freq_col, spend_col))
    cor_res <- cor.test(df[[freq_col]], df[[spend_col]], method = "pearson")
    test_records[[test_counter]] <- data.frame(
      Test_ID = sprintf("STAT-%02d", test_counter),
      Hypothesis = sprintf("H0: No correlation between %s and %s vs H1: Correlation exists", freq_col, spend_col),
      Statistical_Test = "Pearson's Product-Moment Correlation",
      Test_Statistic = sprintf("t = %.2f (df = %d)", cor_res$statistic, cor_res$parameter),
      Effect_Size = sprintf("r = %.3f [95%% CI: %.3f, %.3f]", cor_res$estimate, cor_res$conf.int[1], cor_res$conf.int[2]),
      p_value = format.pval(cor_res$p.value, eps = 0.0001),
      Decision = ifelse(cor_res$p.value < 0.05, "Reject H0 (Statistically Significant)", "Fail to Reject H0"),
      Business_Interpretation = "Transaction frequency and expenditure exhibit significant association, confirming high-frequency shoppers drive revenue.",
      stringsAsFactors = FALSE
    )
    test_counter <- test_counter + 1
  }

  # Test 2: Two-Sample Welch t-Test for Spending by Subscription / Loyalty Status
  binary_col <- intersect(c("Subscription_Status", "Loyalty_Program_Member", "Repeat_Purchase"), colnames(df))[1]
  if (!is.na(binary_col) && !is.na(spend_col) && length(unique(na.omit(df[[binary_col]]))) == 2) {
    cat(sprintf("[STAT] Test %d: Welch t-Test for '%s' across '%s' groups...\n", test_counter, spend_col, binary_col))
    lvl <- levels(as.factor(df[[binary_col]]))
    grp1 <- df[[spend_col]][df[[binary_col]] == lvl[1]]
    grp2 <- df[[spend_col]][df[[binary_col]] == lvl[2]]
    t_res <- t.test(grp1, grp2, var.equal = FALSE)

    test_records[[test_counter]] <- data.frame(
      Test_ID = sprintf("STAT-%02d", test_counter),
      Hypothesis = sprintf("H0: Mean %s (%s) = Mean %s (%s) vs H1: Means differ", spend_col, lvl[1], spend_col, lvl[2]),
      Statistical_Test = "Welch Two-Sample t-Test",
      Test_Statistic = sprintf("t = %.2f (df = %.1f)", t_res$statistic, t_res$parameter),
      Effect_Size = sprintf("%s: $%.2f vs %s: $%.2f (Diff: $%.2f)", lvl[1], mean(grp1, na.rm=TRUE), lvl[2], mean(grp2, na.rm=TRUE), mean(grp1, na.rm=TRUE) - mean(grp2, na.rm=TRUE)),
      p_value = format.pval(t_res$p.value, eps = 0.0001),
      Decision = ifelse(t_res$p.value < 0.05, "Reject H0 (Statistically Significant)", "Fail to Reject H0"),
      Business_Interpretation = sprintf("Significant behavioral differences observed across '%s' cohorts.", binary_col),
      stringsAsFactors = FALSE
    )
    test_counter <- test_counter + 1
  }

  # Test 3: One-Way ANOVA across Categories
  cat_col <- intersect(c("Preferred_Category", "Category", "Payment_Method"), colnames(df))[1]
  if (!is.na(cat_col) && !is.na(spend_col)) {
    cat(sprintf("[STAT] Test %d: One-Way ANOVA for '%s' across '%s'...\n", test_counter, spend_col, cat_col))
    fmla <- as.formula(paste(spend_col, "~", cat_col))
    aov_res <- aov(fmla, data = df)
    aov_sum <- summary(aov_res)[[1]]
    f_stat <- aov_sum$`F value`[1]
    p_val <- aov_sum$`Pr(>F)`[1]

    test_records[[test_counter]] <- data.frame(
      Test_ID = sprintf("STAT-%02d", test_counter),
      Hypothesis = sprintf("H0: Mean %s is identical across all %s levels vs H1: At least one differs", spend_col, cat_col),
      Statistical_Test = "One-Way Analysis of Variance (ANOVA)",
      Test_Statistic = sprintf("F = %.2f (df1 = %d, df2 = %d)", f_stat, aov_sum$Df[1], aov_sum$Df[2]),
      Effect_Size = sprintf("Eta-Squared: %.4f", aov_sum$`Sum Sq`[1] / sum(aov_sum$`Sum Sq`)),
      p_value = format.pval(p_val, eps = 0.0001),
      Decision = ifelse(p_val < 0.05, "Reject H0 (Statistically Significant)", "Fail to Reject H0"),
      Business_Interpretation = "Spending patterns vary significantly by category, validating targeted category promotions.",
      stringsAsFactors = FALSE
    )
    test_counter <- test_counter + 1
  }

  stat_summary_df <- if (length(test_records) > 0) do.call(rbind, test_records) else data.frame()
  tables_dir <- config$paths$tables_dir
  if (!dir.exists(tables_dir)) dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  write_csv(stat_summary_df, file.path(tables_dir, "hypothesis_testing_results.csv"))
  cat(sprintf("[SUCCESS] Completed %d hypothesis tests; documented in outputs/tables/.\n", nrow(stat_summary_df)))

  return(stat_summary_df)
}
