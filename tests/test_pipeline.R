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
# Test 1: Synthetic Dataset Generation & Schema Validation
# ------------------------------------------------------------------------------
test_results[[1]] <- run_test(1, "Dataset Generation & Schema Integrity", function() {
  test_raw_path <- file.path("data", "raw", "test_sample_data.csv")
  df_sample <- generate_synthetic_dataset(n = 200, seed = 42, missing_rate = 0.05, n_duplicates = 5, output_path = test_raw_path)
  
  expected_cols <- c("CustomerID", "Age", "Gender", "City_Tier", "Annual_Income_USD",
                     "Customer_Tenure_Months", "Total_Purchases", "Total_Spend_USD",
                     "Avg_Order_Value_USD", "Recency_Days", "App_Session_Minutes",
                     "Website_Visits_Per_Month", "Discount_Usage_Ratio", "Preferred_Category",
                     "Loyalty_Program_Member", "Customer_Satisfaction_Score", "Repeat_Purchase")
  
  has_all_cols <- all(expected_cols %in% colnames(df_sample))
  correct_rows <- nrow(df_sample) == 205 # 200 + 5 duplicates
  if (file.exists(test_raw_path)) unlink(test_raw_path)
  
  return(has_all_cols && correct_rows)
})

# ------------------------------------------------------------------------------
# Test 2: Duplicate Detection & Removal
# ------------------------------------------------------------------------------
test_results[[2]] <- run_test(2, "Duplicate Detection & Deduplication", function() {
  dummy_df <- data.frame(
    CustomerID = c("C1", "C2", "C1"),
    Age = c(25, 30, 25),
    Gender = c("Female", "Male", "Female"),
    City_Tier = c("Tier 1", "Tier 2", "Tier 1"),
    Annual_Income_USD = c(50000, 60000, 50000),
    Customer_Tenure_Months = c(12, 24, 12),
    Total_Purchases = c(5, 10, 5),
    Total_Spend_USD = c(500, 1000, 500),
    Avg_Order_Value_USD = c(100, 100, 100),
    Recency_Days = c(10, 20, 10),
    App_Session_Minutes = c(30, 45, 30),
    Website_Visits_Per_Month = c(5, 10, 5),
    Discount_Usage_Ratio = c(0.1, 0.2, 0.1),
    Preferred_Category = c("Electronics", "Fashion", "Electronics"),
    Loyalty_Program_Member = c(1, 0, 1),
    Customer_Satisfaction_Score = c(4, 5, 4),
    Repeat_Purchase = c(1, 0, 1)
  )
  
  res <- preprocess_customer_data(dummy_df, config)
  # Should have 2 unique rows after deduplicating C1
  return(nrow(res$cleaned_data) == 2)
})

# ------------------------------------------------------------------------------
# Test 3: Missing Value Imputation
# ------------------------------------------------------------------------------
test_results[[3]] <- run_test(3, "Missing Value Imputation Completeness", function() {
  dummy_df <- data.frame(
    CustomerID = sprintf("C%d", 1:10),
    Age = 25:34,
    Gender = rep(c("Female", "Male"), 5),
    City_Tier = rep("Tier 1", 10),
    Annual_Income_USD = c(40000, NA, 50000, 60000, NA, 70000, 80000, 90000, 100000, 110000),
    Customer_Tenure_Months = 1:10,
    Total_Purchases = 1:10,
    Total_Spend_USD = (1:10) * 100,
    Avg_Order_Value_USD = rep(100, 10),
    Recency_Days = (1:10) * 5,
    App_Session_Minutes = c(NA, 20, 30, NA, 50, 60, 70, 80, 90, 100),
    Website_Visits_Per_Month = 1:10,
    Discount_Usage_Ratio = rep(0.1, 10),
    Preferred_Category = rep("Electronics", 10),
    Loyalty_Program_Member = rep(0, 10),
    Customer_Satisfaction_Score = rep(4, 10),
    Repeat_Purchase = rep(c(0, 1), 5)
  )
  
  res <- preprocess_customer_data(dummy_df, config)
  has_no_na <- all(colSums(is.na(res$cleaned_data)) == 0)
  return(has_no_na)
})

# ------------------------------------------------------------------------------
# Test 4: Numerical Scaling & Clustering Features Non-Triviality
# ------------------------------------------------------------------------------
test_results[[4]] <- run_test(4, "Clustering Feature Standardization & Scaling", function() {
  raw_df <- generate_synthetic_dataset(n = 300, seed = 123, output_path = file.path("data", "raw", "temp_test.csv"))
  prep <- preprocess_customer_data(raw_df, config)
  scaled <- prep$scaled_clustering_data
  unlink(file.path("data", "raw", "temp_test.csv"))
  
  # Check means are ~0 and sds are ~1 for all scaled columns
  means_near_zero <- all(abs(colMeans(scaled)) < 0.001)
  sds_near_one <- all(abs(apply(scaled, 2, sd) - 1) < 0.001)
  no_nas <- all(!is.na(scaled))
  
  return(means_near_zero && sds_near_one && no_nas)
})

# ------------------------------------------------------------------------------
# Test 5: Train / Test Partitioning & Stratification
# ------------------------------------------------------------------------------
test_results[[5]] <- run_test(5, "Stratified Train/Test Split Independence", function() {
  raw_df <- generate_synthetic_dataset(n = 400, seed = 999, output_path = file.path("data", "raw", "temp_test.csv"))
  prep <- preprocess_customer_data(raw_df, config)
  unlink(file.path("data", "raw", "temp_test.csv"))
  
  train_ids <- prep$train_data$CustomerID
  test_ids <- prep$test_data$CustomerID
  
  # No overlap between train and test sets
  overlap <- intersect(train_ids, test_ids)
  no_overlap <- length(overlap) == 0
  
  # Correct proportions (75% train, 25% test)
  total <- nrow(prep$cleaned_data)
  train_prop <- nrow(prep$train_data) / total
  prop_valid <- abs(train_prop - 0.75) < 0.02
  
  return(no_overlap && prop_valid)
})

# ------------------------------------------------------------------------------
# Test 6: K-Means Clustering Execution & Profile Generation
# ------------------------------------------------------------------------------
test_results[[6]] <- run_test(6, "K-Means Clustering & Persona Mapping", function() {
  raw_df <- generate_synthetic_dataset(n = 300, seed = 555, output_path = file.path("data", "raw", "temp_test.csv"))
  prep <- preprocess_customer_data(raw_df, config)
  unlink(file.path("data", "raw", "temp_test.csv"))
  
  seg <- perform_customer_segmentation(prep$cleaned_data, prep$scaled_clustering_data, config)
  
  k_valid <- length(unique(seg$model$cluster)) == config$clustering$k_optimal
  all_assigned <- nrow(seg$df_with_clusters) == nrow(prep$cleaned_data)
  profiles_exist <- nrow(seg$cluster_summary) == config$clustering$k_optimal
  
  return(k_valid && all_assigned && profiles_exist)
})

# ------------------------------------------------------------------------------
# Test 7: Logistic Regression Model Fitting & Prediction Validity
# ------------------------------------------------------------------------------
test_results[[7]] <- run_test(7, "Logistic Regression Fitting & Probabilities in [0, 1]", function() {
  raw_df <- generate_synthetic_dataset(n = 400, seed = 777, output_path = file.path("data", "raw", "temp_test.csv"))
  prep <- preprocess_customer_data(raw_df, config)
  unlink(file.path("data", "raw", "temp_test.csv"))
  
  pred <- train_and_evaluate_models(prep$train_data, prep$test_data, config)
  
  glm_probs <- pred$test_predictions$GLM_Predicted_Prob
  valid_probs <- all(glm_probs >= 0 & glm_probs <= 1)
  auc_valid <- pred$glm_metrics$auc >= 0.50 && pred$glm_metrics$auc <= 1.00
  
  return(valid_probs && auc_valid)
})

# ------------------------------------------------------------------------------
# Test 8: Random Forest Model Fitting & Feature Importance
# ------------------------------------------------------------------------------
test_results[[8]] <- run_test(8, "Random Forest Fitting & Gini Importance Extraction", function() {
  raw_df <- generate_synthetic_dataset(n = 400, seed = 777, output_path = file.path("data", "raw", "temp_test.csv"))
  prep <- preprocess_customer_data(raw_df, config)
  unlink(file.path("data", "raw", "temp_test.csv"))
  
  pred <- train_and_evaluate_models(prep$train_data, prep$test_data, config)
  
  rf_probs <- pred$test_predictions$RF_Predicted_Prob
  valid_probs <- all(rf_probs >= 0 & rf_probs <= 1)
  feat_imp_valid <- nrow(pred$feature_importance) > 5 && all(pred$feature_importance$MeanDecreaseGini >= 0)
  
  return(valid_probs && feat_imp_valid)
})

# ------------------------------------------------------------------------------
# Test 9: Real-Time Propensity Scoring Function
# ------------------------------------------------------------------------------
test_results[[9]] <- run_test(9, "Real-Time Propensity Scoring Function", function() {
  raw_df <- generate_synthetic_dataset(n = 300, seed = 888, output_path = file.path("data", "raw", "temp_test.csv"))
  prep <- preprocess_customer_data(raw_df, config)
  unlink(file.path("data", "raw", "temp_test.csv"))
  
  pred <- train_and_evaluate_models(prep$train_data, prep$test_data, config)
  
  dummy_cust <- prep$test_data[1, ]
  score <- predict_customer_purchase(dummy_cust, pred$rf_model)
  
  score_valid <- score$predicted_probability >= 0 && score$predicted_probability <= 1
  label_valid <- score$predicted_class %in% c("Repeat Buyer", "Non-Repeat Buyer")
  tier_valid <- score$propensity_tier %in% c("High Propensity", "Moderate Propensity", "Low Propensity / At Risk")
  
  return(score_valid && label_valid && tier_valid)
})

# ------------------------------------------------------------------------------
# Test 10: Inferential Statistical Hypothesis Test Execution
# ------------------------------------------------------------------------------
test_results[[10]] <- run_test(10, "Inferential Hypothesis Testing Pipeline", function() {
  raw_df <- generate_synthetic_dataset(n = 300, seed = 333, output_path = file.path("data", "raw", "temp_test.csv"))
  prep <- preprocess_customer_data(raw_df, config)
  unlink(file.path("data", "raw", "temp_test.csv"))
  
  stat_df <- perform_statistical_analysis(prep$cleaned_data, config)
  all_tests_run <- nrow(stat_df) == 5
  has_p_values <- all(!is.na(stat_df$p_value))
  
  return(all_tests_run && has_p_values)
})

# ------------------------------------------------------------------------------
# Final Test Summary
# ------------------------------------------------------------------------------
cat("\n==================================================================\n")
total_passed <- sum(unlist(test_results))
cat(sprintf("   TEST RESULTS: %d / %d TESTS PASSED (%.1f%%)\n",
            total_passed, total_tests, (total_passed / total_tests) * 100))
cat("==================================================================\n\n")

if (total_passed == total_tests) {
  cat("[SUCCESS] ALL UNIT AND INTEGRATION TESTS PASSED WITH 100% SUCCESS!\n\n")
} else {
  stop(sprintf("[FAILURE] %d tests failed. Inspect diagnostic output.", total_tests - total_passed))
}
