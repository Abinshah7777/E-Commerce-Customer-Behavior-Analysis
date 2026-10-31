# ==============================================================================
# EXPLORATORY DATA ANALYSIS MODULE: R/exploratory_analysis.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
})

#' Perform Comprehensive Exploratory Data Analysis
#'
#' Dynamically computes descriptive statistics, categorical breakdowns,
#' and correlation matrices for any customer behavioral dataset.
#'
#' @param df Cleaned customer data frame
#' @param config Configuration list
#' @return A list containing statistical tables and summaries
perform_exploratory_analysis <- function(df, config) {
  cat("\n------------------------------------------------------------------\n")
  cat("   EXPLORATORY DATA ANALYSIS (EDA)                                \n")
  cat("------------------------------------------------------------------\n")

  tables_dir <- config$paths$tables_dir
  if (!dir.exists(tables_dir)) dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

  # 1. Dynamic Numerical Feature Summary Statistics
  num_cols <- names(df)[sapply(df, is.numeric)]
  num_cols <- setdiff(num_cols, c("CustomerID", "Customer_ID", "Cluster_ID"))

  cat(sprintf("[EDA] Computing descriptive statistics for %d numerical variables...\n", length(num_cols)))

  if (length(num_cols) > 0) {
    desc_stats <- lapply(num_cols, function(col) {
      x <- na.omit(df[[col]])
      if (length(x) == 0) return(NULL)
      q <- quantile(x, probs = c(0.25, 0.50, 0.75), na.rm = TRUE)
      std_val <- sd(x, na.rm = TRUE)
      skew_val <- if (!is.na(std_val) && std_val > 0) round((mean(x) - median(x)) / std_val, 3) else 0.0

      data.frame(
        Variable = col,
        N = length(x),
        Mean = round(mean(x), 2),
        SD = round(std_val, 2),
        Median = round(median(x), 2),
        IQR = round(q[3] - q[1], 2),
        Min = round(min(x), 2),
        Q25 = round(q[1], 2),
        Q75 = round(q[3], 2),
        Max = round(max(x), 2),
        Skewness = skew_val,
        stringsAsFactors = FALSE
      )
    })
    desc_stats_df <- do.call(rbind, desc_stats[!sapply(desc_stats, is.null)])
  } else {
    desc_stats_df <- data.frame(Variable = character(), Mean = numeric())
  }

  desc_path <- file.path(tables_dir, "descriptive_statistics.csv")
  write_csv(desc_stats_df, desc_path)
  cat(sprintf("[EDA] Saved descriptive statistics to '%s'.\n", desc_path))

  # 2. Dynamic Categorical Frequency Analysis
  cat_cols <- names(df)[sapply(df, function(x) is.character(x) || is.factor(x))]
  cat_cols <- setdiff(cat_cols, c("CustomerID", "Customer_ID"))

  cat(sprintf("[EDA] Computing frequency tables for %d categorical variables...\n", length(cat_cols)))
  cat_list <- list()

  for (col in cat_cols) {
    tbl <- table(df[[col]])
    prop_tbl <- prop.table(tbl) * 100
    tmp_df <- data.frame(
      Variable = col,
      Category_Level = names(tbl),
      Frequency = as.integer(tbl),
      Proportion_Pct = round(as.numeric(prop_tbl), 2),
      stringsAsFactors = FALSE
    )
    cat_list[[col]] <- tmp_df
  }

  cat_dist_df <- if (length(cat_list) > 0) do.call(rbind, cat_list) else data.frame()
  cat_path <- file.path(tables_dir, "categorical_distributions.csv")
  write_csv(cat_dist_df, cat_path)
  cat(sprintf("[EDA] Saved categorical distributions to '%s'.\n", cat_path))

  # 3. Correlation Matrix across Numerical Features
  if (length(num_cols) >= 2) {
    cat("[EDA] Computing Pearson correlation matrix across numerical attributes...\n")
    cor_matrix <- round(cor(df[, num_cols], use = "pairwise.complete.obs"), 3)
    cor_df <- as.data.frame(cor_matrix)
    cor_df <- cbind(Feature = rownames(cor_matrix), cor_df)
    cor_path <- file.path(tables_dir, "correlation_matrix.csv")
    write_csv(cor_df, cor_path)
    cat(sprintf("[EDA] Saved correlation matrix to '%s'.\n", cor_path))
  } else {
    cor_matrix <- matrix()
  }

  # 4. Category Spending Breakdown (if applicable)
  cat_col_target <- intersect(c("Preferred_Category", "Category", "Item_Purchased"), colnames(df))[1]
  spend_col_target <- intersect(c("Total_Spend_USD", "Purchase_Amount_USD", "Avg_Order_Value_USD"), colnames(df))[1]

  if (!is.na(cat_col_target) && !is.na(spend_col_target)) {
    cat(sprintf("[EDA] Summarizing expenditure by '%s'...\n", cat_col_target))
    cat_summary <- df %>%
      group_by(Category = .data[[cat_col_target]]) %>%
      summarise(
        Customer_Count = n(),
        Mean_Spend_USD = round(mean(.data[[spend_col_target]], na.rm = TRUE), 2),
        Median_Spend_USD = round(median(.data[[spend_col_target]], na.rm = TRUE), 2),
        Total_Revenue_USD = round(sum(.data[[spend_col_target]], na.rm = TRUE), 2),
        Share_of_Spend_Pct = round((sum(.data[[spend_col_target]], na.rm = TRUE) / sum(df[[spend_col_target]], na.rm = TRUE)) * 100, 2),
        .groups = "drop"
      ) %>%
      arrange(desc(Total_Revenue_USD))

    cat_spend_path <- file.path(tables_dir, "category_spending_summary.csv")
    write_csv(cat_summary, cat_spend_path)
  } else {
    cat_summary <- data.frame()
  }

  return(list(
    descriptive_stats = desc_stats_df,
    categorical_distributions = cat_dist_df,
    correlation_matrix = cor_matrix,
    category_summary = cat_summary
  ))
}
