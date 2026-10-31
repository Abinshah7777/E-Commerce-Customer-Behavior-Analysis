# ==============================================================================
# DATA PREPROCESSING MODULE: R/data_preprocessing.R
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

#' Preprocess Raw Customer Behavior Data
#'
#' Executes end-to-end data cleansing, missing value imputation, duplicate removal,
#' feature engineering, numerical standardization, and stratified train/test split.
#'
#' @param raw_df Data frame: Raw customer records
#' @param config List: Configuration settings from config.R
#' @return A list containing cleaned_data, scaled_clustering_data, train_data, test_data, and summary metrics
preprocess_customer_data <- function(raw_df, config) {
  cat("\n------------------------------------------------------------------\n")
  cat("   DATA PREPROCESSING & QUALITY AUDIT                             \n")
  cat("------------------------------------------------------------------\n")
  
  initial_rows <- nrow(raw_df)
  initial_cols <- ncol(raw_df)
  cat(sprintf("[AUDIT] Raw Dataset Dimensions: %d rows, %d columns.\n", initial_rows, initial_cols))
  
  # 1. Duplicate Detection & Removal
  duplicate_mask <- duplicated(raw_df) | duplicated(raw_df$CustomerID)
  n_duplicates <- sum(duplicate_mask)
  cat(sprintf("[AUDIT] Identified %d duplicate rows. Removing duplicates...\n", n_duplicates))
  
  df_dedup <- raw_df[!duplicate_mask, ]
  cat(sprintf("[AUDIT] Remaining rows after deduplication: %d.\n", nrow(df_dedup)))
  
  # 2. Missing Value Analysis
  missing_counts <- colSums(is.na(df_dedup))
  cols_with_na <- names(missing_counts[missing_counts > 0])
  total_missing_cells <- sum(missing_counts)
  
  cat(sprintf("[AUDIT] Missing Values Detected in %d columns (Total %d missing entries):\n",
              length(cols_with_na), total_missing_cells))
  for (col in cols_with_na) {
    cat(sprintf("  - %-25s : %d missing (%.2f%%)\n",
                col, missing_counts[col], (missing_counts[col] / nrow(df_dedup)) * 100))
  }
  
  # 3. Missing Value Imputation (Justified Strategy: Median Imputation for Skewed Numerics)
  df_imputed <- df_dedup
  imputed_records <- 0
  
  for (col in cols_with_na) {
    if (is.numeric(df_imputed[[col]])) {
      med_val <- median(df_imputed[[col]], na.rm = TRUE)
      na_idx <- is.na(df_imputed[[col]])
      df_imputed[[col]][na_idx] <- med_val
      imputed_records <- imputed_records + sum(na_idx)
      cat(sprintf("[CLEAN] Imputed missing values in '%s' using median: %.2f\n", col, med_val))
    }
  }
  
  # 4. Data Type Conversions & Categorical Standardization
  cat("[CLEAN] Standardizing data types and categorical factor levels...\n")
  df_imputed$Gender <- factor(df_imputed$Gender, levels = c("Female", "Male", "Other"))
  df_imputed$City_Tier <- factor(df_imputed$City_Tier, levels = c("Tier 1", "Tier 2", "Tier 3"))
  df_imputed$Preferred_Category <- factor(df_imputed$Preferred_Category)
  df_imputed$Loyalty_Program_Member <- factor(df_imputed$Loyalty_Program_Member, levels = c(0, 1), labels = c("No", "Yes"))
  df_imputed$Repeat_Purchase <- factor(df_imputed$Repeat_Purchase, levels = c(0, 1), labels = c("No", "Yes"))
  
  # 5. Outlier Auditing (IQR Method)
  cat("[AUDIT] Auditing extreme values using Interquartile Range (IQR)...\n")
  numeric_cols <- c("Total_Spend_USD", "Total_Purchases", "Avg_Order_Value_USD", "Recency_Days", "Annual_Income_USD")
  outlier_summary <- list()
  for (col in numeric_cols) {
    q25 <- quantile(df_imputed[[col]], 0.25)
    q75 <- quantile(df_imputed[[col]], 0.75)
    iqr_val <- q75 - q25
    lower_bound <- q25 - 1.5 * iqr_val
    upper_bound <- q75 + 1.5 * iqr_val
    n_outliers <- sum(df_imputed[[col]] < lower_bound | df_imputed[[col]] > upper_bound)
    outlier_summary[[col]] <- n_outliers
    cat(sprintf("  - %-22s: %d outliers beyond [%.1f, %.1f]\n", col, n_outliers, lower_bound, upper_bound))
  }
  # Note: Genuine high spenders are preserved as valid VIP customers rather than deleted.
  
  # 6. Feature Engineering: RFM & Engagement Indices
  cat("[CLEAN] Engineering behavioral features: Spend_Per_Visit and Engagement_Score...\n")
  df_imputed$Spend_Per_Visit <- round(df_imputed$Total_Spend_USD / pmax(1, df_imputed$Website_Visits_Per_Month), 2)
  df_imputed$Engagement_Index <- as.numeric(round(scale(df_imputed$App_Session_Minutes) + scale(df_imputed$Website_Visits_Per_Month), 3))
  
  # 7. Numerical Scaling for Clustering
  clustering_features <- config$clustering$features
  cat(sprintf("[CLEAN] Extracting and scaling %d clustering features using Z-score standardization...\n",
              length(clustering_features)))
  
  cluster_raw_df <- df_imputed[, clustering_features]
  scaled_clustering_matrix <- scale(cluster_raw_df)
  scaled_clustering_df <- as.data.frame(scaled_clustering_matrix)
  
  # 8. Stratified Train / Test Partitioning for Predictive Modeling
  set.seed(config$seed)
  train_ratio <- config$modeling$train_ratio
  cat(sprintf("[CLEAN] Performing stratified train/test split (%.0f%% Train, %.0f%% Test)...\n",
              train_ratio * 100, (1 - train_ratio) * 100))
  
  # Stratified index sampling by Repeat_Purchase
  idx_pos <- which(df_imputed$Repeat_Purchase == "Yes")
  idx_neg <- which(df_imputed$Repeat_Purchase == "No")
  
  train_pos <- sample(idx_pos, size = round(length(idx_pos) * train_ratio))
  train_neg <- sample(idx_neg, size = round(length(idx_neg) * train_ratio))
  train_idx <- c(train_pos, train_neg)
  test_idx <- setdiff(1:nrow(df_imputed), train_idx)
  
  train_data <- df_imputed[train_idx, ]
  test_data <- df_imputed[test_idx, ]
  
  cat(sprintf("  - Training Set: %d records (Repeat Purchase Rate: %.2f%%)\n",
              nrow(train_data), (sum(train_data$Repeat_Purchase == "Yes") / nrow(train_data)) * 100))
  cat(sprintf("  - Testing Set:  %d records (Repeat Purchase Rate: %.2f%%)\n",
              nrow(test_data), (sum(test_data$Repeat_Purchase == "Yes") / nrow(test_data)) * 100))
  
  # 9. Save Cleaned Dataset to Disk
  proc_path <- config$paths$data_processed
  dir_path <- dirname(proc_path)
  if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  write_csv(df_imputed, proc_path)
  cat(sprintf("[SUCCESS] Cleaned dataset saved to '%s'.\n", proc_path))
  
  # 10. Generate Preprocessing Summary Table
  prep_summary_df <- data.frame(
    Metric = c(
      "Initial Row Count",
      "Initial Column Count",
      "Duplicate Rows Identified & Removed",
      "Post-Deduplication Rows",
      "Columns with Missing Values",
      "Total Missing Values Imputed",
      "Engineered Features Added",
      "Clustering Features Scaled",
      "Training Set Size",
      "Testing Set Size",
      "Final Cleaned Dataset Rows"
    ),
    Value = c(
      as.character(initial_rows),
      as.character(initial_cols),
      as.character(n_duplicates),
      as.character(nrow(df_dedup)),
      as.character(length(cols_with_na)),
      as.character(imputed_records),
      "Spend_Per_Visit, Engagement_Index",
      paste(clustering_features, collapse = ", "),
      as.character(nrow(train_data)),
      as.character(nrow(test_data)),
      as.character(nrow(df_imputed))
    ),
    stringsAsFactors = FALSE
  )
  
  summary_path <- file.path(config$paths$tables_dir, "preprocessing_summary.csv")
  if (!dir.exists(dirname(summary_path))) dir.create(dirname(summary_path), recursive = TRUE, showWarnings = FALSE)
  write_csv(prep_summary_df, summary_path)
  cat(sprintf("[SUCCESS] Preprocessing summary saved to '%s'.\n", summary_path))
  
  return(list(
    cleaned_data = df_imputed,
    scaled_clustering_data = scaled_clustering_df,
    clustering_features = clustering_features,
    train_data = train_data,
    test_data = test_data,
    preprocessing_summary = prep_summary_df
  ))
}
