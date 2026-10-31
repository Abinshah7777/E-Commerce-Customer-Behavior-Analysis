# ==============================================================================
# AUTOMATED UNIT & INTEGRATION TEST SUITE: tests/test_pipeline.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# ==============================================================================

cat("\n==================================================================\n")
cat("   RUNNING AUTOMATED UNIT & INTEGRATION TEST SUITE               \n")
cat("==================================================================\n\n")

source("config.R")
config <- get_config()

# Load all analysis modules
source(file.path("R", "data_loading.R"))
source(file.path("R", "data_preprocessing.R"))
source(file.path("R", "exploratory_analysis.R"))
source(file.path("R", "statistical_analysis.R"))
source(file.path("R", "customer_segmentation.R"))
source(file.path("R", "purchase_prediction.R"))
source(file.path("R", "visualization.R"))
source(file.path("R", "business_insights.R"))
source(file.path("R", "generate_report.R"))

test_results <- list()
passed_count <- 0
total_tests <- 10

run_test <- function(test_num, test_title, test_expression) {
  cat(sprintf("[TEST %02d/%02d] %s... ", test_num, total_tests, test_title))
  res <- tryCatch({
    outcome <- test_expression()
    if (isTRUE(outcome)) {
      cat("PASSED ✓\n")
      return(TRUE)
    } else {
      cat(sprintf("FAILED ✗ (Condition evaluated to %s)\n", as.character(outcome)))
      return(FALSE)
    }
  }, error = function(e) {
    cat(sprintf("ERROR ✗ (%s)\n", conditionMessage(e)))
    return(FALSE)
  })
  return(res)
}

# ------------------------------------------------------------------------------
# Test 1: Real Kaggle Dataset Loading & Integrity
# ------------------------------------------------------------------------------
test_results[[1]] <- run_test(1, "Kaggle Dataset Loading & Record Integrity", function() {
  raw_df <- load_raw_data(config$paths$data_raw)
  is_df <- is.data.frame(raw_df)
  has_rows <- nrow(raw_df) >= 3000
  has_cols <- ncol(raw_df) >= 15
  return(is_df && has_rows && has_cols)
})

# ------------------------------------------------------------------------------
# Test 2: Excel (.xlsx) Dataset Ingestion via readxl
# ------------------------------------------------------------------------------
test_results[[2]] <- run_test(2, "Custom Excel (.xlsx) Dataset Ingestion", function() {
  excel_path <- config$paths$data_sample_excel
  if (!file.exists(excel_path)) {
    # Generate on the fly if needed
    raw_df <- load_raw_data(config$paths$data_raw)
    writexl::write_xlsx(head(raw_df, 150), excel_path)
  }
  custom_res <- load_custom_dataset(excel_path, "sample_customers.xlsx")
  return(custom_res$success && nrow(custom_res$data) >= 100)
})

# ------------------------------------------------------------------------------
# Test 3: Dataset Schema Standardization & Column Synonyms
# ------------------------------------------------------------------------------
test_results[[3]] <- run_test(3, "Column Name Standardization & Synonym Detection", function() {
  custom_df <- data.frame(
    `Customer ID` = 1:50,
    `Age` = sample(20:60, 50, replace = TRUE),
    `Gender` = sample(c("Male", "Female"), 50, replace = TRUE),
    `Category` = sample(c("Clothing", "Footwear"), 50, replace = TRUE),
    `Purchase Amount (USD)` = runif(50, 20, 100),
    `Previous Purchases` = sample(1:20, 50, replace = TRUE),
    check.names = FALSE
  )
  std_df <- standardize_column_names(custom_df)
  
  has_customer_id <- "CustomerID" %in% colnames(std_df)
  has_spend <- "Total_Spend_USD" %in% colnames(std_df)
  has_frequency <- "Total_Purchases" %in% colnames(std_df)
  
  return(has_customer_id && has_spend && has_frequency)
})

# ------------------------------------------------------------------------------
# Test 4: Duplicate Detection & Removal
# ------------------------------------------------------------------------------
test_results[[4]] <- run_test(4, "Duplicate Record Detection & Excising", function() {
  test_df <- data.frame(
    CustomerID = c("C01", "C02", "C01", "C03"),
    Age = c(30, 40, 30, 50),
    Total_Spend_USD = c(100, 200, 100, 300),
    Total_Purchases = c(2, 4, 2, 6)
  )
  prep <- preprocess_customer_data(test_df, config)
  # Should have 3 unique rows after deduplicating C01
  return(nrow(prep$cleaned_data) == 3)
})

# ------------------------------------------------------------------------------
# Test 5: Missing Value Imputation Completeness
# ------------------------------------------------------------------------------
test_results[[5]] <- run_test(5, "Missing Value Imputation Completeness", function() {
  test_df <- data.frame(
    CustomerID = sprintf("C%02d", 1:20),
    Age = c(25:34, rep(NA, 5), 40:44),
    Total_Spend_USD = c(100:109, rep(NA, 5), 115:119),
    Total_Purchases = 1:20
  )
  prep <- preprocess_customer_data(test_df, config)
  has_no_na <- sum(is.na(prep$cleaned_data$Age)) == 0 && sum(is.na(prep$cleaned_data$Total_Spend_USD)) == 0
  return(has_no_na)
})

# ------------------------------------------------------------------------------
# Test 6: Clustering Feature Standardization & Scaling
# ------------------------------------------------------------------------------
test_results[[6]] <- run_test(6, "Dynamic Feature Scaling (Mean=0, SD=1)", function() {
  raw_df <- load_raw_data(config$paths$data_raw)
  prep <- preprocess_customer_data(raw_df, config)
  scaled <- prep$scaled_clustering_data
  
  means_near_zero <- all(abs(colMeans(scaled)) < 0.01)
  sds_near_one <- all(abs(apply(scaled, 2, sd) - 1) < 0.01)
  return(means_near_zero && sds_near_one)
})

# ------------------------------------------------------------------------------
# Test 7: Train / Test Partitioning Independence
# ------------------------------------------------------------------------------
test_results[[7]] <- run_test(7, "Train/Test Partition Independence", function() {
  raw_df <- load_raw_data(config$paths$data_raw)
  prep <- preprocess_customer_data(raw_df, config)
  
  train_ids <- prep$train_data$CustomerID
  test_ids <- prep$test_data$CustomerID
  
  overlap <- intersect(train_ids, test_ids)
  total <- nrow(prep$cleaned_data)
  train_prop <- nrow(prep$train_data) / total
  
  return(length(overlap) == 0 && abs(train_prop - 0.75) < 0.02)
})

# ------------------------------------------------------------------------------
# Test 8: K-Means Clustering & Persona Mapping
# ------------------------------------------------------------------------------
test_results[[8]] <- run_test(8, "K-Means Clustering & Cluster Summary", function() {
  raw_df <- load_raw_data(config$paths$data_raw)
  prep <- preprocess_customer_data(raw_df, config)
  seg <- perform_customer_segmentation(prep$cleaned_data, prep$scaled_clustering_data, config)
  
  has_profiles <- nrow(seg$cluster_summary) == config$clustering$k_optimal
  all_clustered <- nrow(seg$cluster_assignments) == nrow(prep$cleaned_data)
  
  return(has_profiles && all_clustered)
})

# ------------------------------------------------------------------------------
# Test 9: Supervised Predictive Modeling Validation
# ------------------------------------------------------------------------------
test_results[[9]] <- run_test(9, "Predictive Model Fitting & Evaluation", function() {
  raw_df <- load_raw_data(config$paths$data_raw)
  prep <- preprocess_customer_data(raw_df, config)
  pred <- train_and_evaluate_models(prep$train_data, prep$test_data, config)
  
  has_model <- isTRUE(pred$model_available)
  valid_auc <- pred$glm_metrics$auc >= 0.50 && pred$rf_metrics$auc >= 0.50
  valid_probs <- all(pred$test_predictions$RF_Predicted_Prob >= 0 & pred$test_predictions$RF_Predicted_Prob <= 1)
  
  return(has_model && valid_auc && valid_probs)
})

# ------------------------------------------------------------------------------
# Test 10: Dynamic Custom Dataset Pipeline Execution
# ------------------------------------------------------------------------------
test_results[[10]] <- run_test(10, "End-to-End Pipeline on Uploaded Dataset", function() {
  custom_df <- data.frame(
    User_ID = sprintf("U%03d", 1:80),
    Years_Old = sample(18:70, 80, replace = TRUE),
    Transactions = sample(1:30, 80, replace = TRUE),
    Spending = runif(80, 50, 1500),
    Rating = sample(1:5, 80, replace = TRUE),
    VIP_Status = sample(c("Yes", "No"), 80, replace = TRUE)
  )
  
  test_cfg <- config
  test_cfg$paths$models_dir <- tempdir()
  test_cfg$paths$tables_dir <- tempdir()
  test_cfg$paths$data_processed <- file.path(tempdir(), "test_cleaned_data.csv")

  prep <- preprocess_customer_data(custom_df, test_cfg)
  seg <- perform_customer_segmentation(prep$cleaned_data, prep$scaled_clustering_data, test_cfg)
  pred <- train_and_evaluate_models(prep$train_data, prep$test_data, test_cfg, target_col = "VIP_Status")
  
  return(!is.null(seg$kmeans_model) && nrow(seg$cluster_summary) > 0)
})

# Summary
cat("\n==================================================================\n")
passed_tests <- sum(unlist(test_results))
cat(sprintf("   TEST RESULTS: %d / %d TESTS PASSED (%.1f%%)\n",
            passed_tests, total_tests, (passed_tests / total_tests) * 100))
cat("==================================================================\n\n")

if (passed_tests == total_tests) {
  cat("[SUCCESS] All pipeline invariants and dataset ingestion workflows verified!\n")
} else {
  cat("[WARNING] Some tests did not pass. Inspect logs above.\n")
}
