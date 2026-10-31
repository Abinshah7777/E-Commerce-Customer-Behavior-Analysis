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
#' Computes descriptive statistics, categorical breakdowns, cross-tabulations,
#' and correlation matrices for all customer behavioral variables.
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
  
  # 1. Numerical Feature Summary Statistics
  cat("[EDA] Computing descriptive statistics for numerical variables...\n")
  num_cols <- c(
    "Age",
    "Annual_Income_USD",
    "Customer_Tenure_Months",
    "Total_Purchases",
    "Total_Spend_USD",
    "Avg_Order_Value_USD",
    "Recency_Days",
    "App_Session_Minutes",
    "Website_Visits_Per_Month",
    "Discount_Usage_Ratio",
    "Customer_Satisfaction_Score"
  )
  
  desc_stats <- lapply(num_cols, function(col) {
    x <- df[[col]]
    q <- quantile(x, probs = c(0.25, 0.50, 0.75), na.rm = TRUE)
    data.frame(
      Variable = col,
      N = length(x),
      Mean = round(mean(x, na.rm = TRUE), 2),
      SD = round(sd(x, na.rm = TRUE), 2),
      Median = round(median(x, na.rm = TRUE), 2),
      IQR = round(q[3] - q[1], 2),
      Min = round(min(x, na.rm = TRUE), 2),
      Q25 = round(q[1], 2),
      Q75 = round(q[3], 2),
      Max = round(max(x, na.rm = TRUE), 2),
      Skewness = round((mean(x, na.rm = TRUE) - median(x, na.rm = TRUE)) / sd(x, na.rm = TRUE), 3),
      stringsAsFactors = FALSE
    )
  })
  desc_stats_df <- do.call(rbind, desc_stats)
  
  desc_path <- file.path(tables_dir, "descriptive_statistics.csv")
  write_csv(desc_stats_df, desc_path)
  cat(sprintf("[EDA] Saved descriptive statistics to '%s'.\n", desc_path))
  
  # 2. Categorical Frequency Analysis
  cat("[EDA] Computing frequency tables for categorical variables...\n")
  cat_cols <- c("Gender", "City_Tier", "Preferred_Category", "Loyalty_Program_Member", "Repeat_Purchase")
  cat_list <- list()
  
  for (col in cat_cols) {
    tbl <- table(df[[col]])
    prop_tbl <- prop.table(tbl) * 100
    tmp_df <- data.frame(
      Variable = col,
      Category = names(tbl),
      Count = as.integer(tbl),
      Percentage = round(as.numeric(prop_tbl), 2),
      stringsAsFactors = FALSE
    )
    cat_list[[col]] <- tmp_df
  }
  cat_dist_df <- do.call(rbind, cat_list)
  
  cat_path <- file.path(tables_dir, "categorical_distributions.csv")
  write_csv(cat_dist_df, cat_path)
  cat(sprintf("[EDA] Saved categorical distributions to '%s'.\n", cat_path))
  
  # 3. Product Category Spending Breakdown
  cat("[EDA] Analyzing spending and frequency by product category...\n")
  category_summary <- df %>%
    group_by(Preferred_Category) %>%
    summarise(
      Customer_Count = n(),
      Customer_Share_Pct = round((n() / nrow(df)) * 100, 2),
      Mean_Total_Spend = round(mean(Total_Spend_USD), 2),
      Median_Total_Spend = round(median(Total_Spend_USD), 2),
      Mean_AOV = round(mean(Avg_Order_Value_USD), 2),
      Mean_Purchases = round(mean(Total_Purchases), 2),
      Repeat_Purchase_Rate_Pct = round(mean(Repeat_Purchase == "Yes") * 100, 2),
      .groups = "drop"
    ) %>%
    arrange(desc(Mean_Total_Spend))
  
  cat_summary_path <- file.path(tables_dir, "category_spending_summary.csv")
  write_csv(category_summary, cat_summary_path)
  cat(sprintf("[EDA] Saved category spending summary to '%s'.\n", cat_summary_path))
  
  # 4. Correlation Matrix of Numerical Features
  cat("[EDA] Calculating Pearson correlation matrix...\n")
  cor_df <- df[, num_cols]
  cor_matrix <- round(cor(cor_df, use = "pairwise.complete.obs"), 3)
  cor_matrix_df <- as.data.frame(cor_matrix)
  cor_matrix_df <- cbind(Variable = rownames(cor_matrix_df), cor_matrix_df)
  
  cor_path <- file.path(tables_dir, "correlation_matrix.csv")
  write_csv(cor_matrix_df, cor_path)
  cat(sprintf("[EDA] Saved correlation matrix to '%s'.\n", cor_path))
  
  # Print key console insights
  cat("\n[EDA HIGHLIGHTS]\n")
  cat(sprintf("  • Total Customers: %d\n", nrow(df)))
  cat(sprintf("  • Average Lifetime Spend: $%.2f (Median: $%.2f)\n",
              mean(df$Total_Spend_USD), median(df$Total_Spend_USD)))
  cat(sprintf("  • Average Orders Per Customer: %.1f\n", mean(df$Total_Purchases)))
  cat(sprintf("  • Loyalty Program Penetration: %.2f%%\n",
              mean(df$Loyalty_Program_Member == "Yes") * 100))
  cat(sprintf("  • Overall Repeat Purchase Rate: %.2f%%\n",
              mean(df$Repeat_Purchase == "Yes") * 100))
  
  return(list(
    descriptive_statistics = desc_stats_df,
    categorical_distributions = cat_dist_df,
    category_summary = category_summary,
    correlation_matrix = cor_matrix
  ))
}
