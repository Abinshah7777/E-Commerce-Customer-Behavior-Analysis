# ==============================================================================
# PURCHASE PREDICTION MODULE: R/purchase_prediction.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(randomForest)
})

#' Calculate ROC Curve Coordinates and Area Under the Curve (AUC)
#'
#' @param actual Integer vector (1 for positive, 0 for negative)
#' @param predicted_prob Numeric vector of predicted probabilities
#' @return A list with auc, fpr, and tpr vectors
calculate_roc_auc <- function(actual, predicted_prob) {
  # Sort by descending predicted probabilities
  ord <- order(predicted_prob, decreasing = TRUE)
  actual_sorted <- actual[ord]
  
  n_pos <- sum(actual_sorted == 1)
  n_neg <- sum(actual_sorted == 0)
  
  if (n_pos == 0 || n_neg == 0) return(list(auc = 0.5, fpr = c(0, 1), tpr = c(0, 1)))
  
  tpr <- c(0, cumsum(actual_sorted == 1) / n_pos)
  fpr <- c(0, cumsum(actual_sorted == 0) / n_neg)
  
  # Trapezoidal integration for AUC
  auc <- sum(diff(fpr) * (tpr[-1] + tpr[-length(tpr)]) / 2)
  return(list(auc = auc, fpr = fpr, tpr = tpr))
}

#' Calculate Comprehensive Classification Metrics
#'
#' @param actual Factor/Vector of true class labels ("No", "Yes")
#' @param predicted_prob Numeric vector of probabilities for "Yes"
#' @param threshold Numeric classification decision threshold (default 0.50)
#' @return A list with metrics and confusion matrix values
evaluate_classifier <- function(actual, predicted_prob, threshold = 0.50) {
  actual_binary <- ifelse(actual == "Yes", 1, 0)
  pred_binary <- ifelse(predicted_prob >= threshold, 1, 0)
  
  tp <- sum(actual_binary == 1 & pred_binary == 1)
  tn <- sum(actual_binary == 0 & pred_binary == 0)
  fp <- sum(actual_binary == 0 & pred_binary == 1)
  fn <- sum(actual_binary == 1 & pred_binary == 0)
  
  accuracy <- (tp + tn) / (tp + tn + fp + fn)
  precision <- ifelse((tp + fp) > 0, tp / (tp + fp), 0)
  recall <- ifelse((tp + fn) > 0, tp / (tp + fn), 0) # Sensitivity
  specificity <- ifelse((tn + fp) > 0, tn / (tn + fp), 0)
  f1_score <- ifelse((precision + recall) > 0, 2 * (precision * recall) / (precision + recall), 0)
  
  roc_res <- calculate_roc_auc(actual_binary, predicted_prob)
  
  return(list(
    accuracy = accuracy,
    precision = precision,
    recall = recall,
    specificity = specificity,
    f1_score = f1_score,
    auc = roc_res$auc,
    roc_curve = roc_res,
    tp = tp,
    tn = tn,
    fp = fp,
    fn = fn
  ))
}

#' Train and Evaluate Predictive Models for Purchase Prediction
#'
#' Trains baseline Logistic Regression and advanced Random Forest classifiers,
#' evaluates out-of-sample performance on the test set, and exports diagnostics.
#'
#' @param train_data Cleaned training data frame
#' @param test_data Cleaned testing data frame
#' @param config Project configuration list
#' @return A list containing models, metrics, comparisons, and test predictions
train_and_evaluate_models <- function(train_data, test_data, config) {
  cat("\n------------------------------------------------------------------\n")
  cat("   PURCHASE PREDICTION: MACHINE LEARNING MODELING                 \n")
  cat("------------------------------------------------------------------\n")
  
  target_col <- config$modeling$target_var
  threshold <- config$modeling$prob_threshold
  
  # Specify Model Formula
  predictors <- c(
    "Age",
    "Gender",
    "City_Tier",
    "Annual_Income_USD",
    "Customer_Tenure_Months",
    "Total_Purchases",
    "Total_Spend_USD",
    "Avg_Order_Value_USD",
    "Recency_Days",
    "App_Session_Minutes",
    "Website_Visits_Per_Month",
    "Discount_Usage_Ratio",
    "Preferred_Category",
    "Loyalty_Program_Member",
    "Customer_Satisfaction_Score"
  )
  
  formula_str <- paste(target_col, "~", paste(predictors, collapse = " + "))
  model_formula <- as.formula(formula_str)
  
  cat(sprintf("[MODELING] Target: '%s' | %d Predictors selected.\n", target_col, length(predictors)))
  cat(sprintf("[MODELING] Training on %d samples | Evaluating on %d test samples.\n",
              nrow(train_data), nrow(test_data)))
  
  # ----------------------------------------------------------------------------
  # 1. Baseline Model: Logistic Regression (GLM)
  # ----------------------------------------------------------------------------
  cat("[MODELING] Training Baseline Logistic Regression (GLM Binomial)...\n")
  glm_fit <- glm(model_formula, data = train_data, family = binomial(link = "logit"))
  
  # Predict Probabilities on Test Data
  glm_test_prob <- predict(glm_fit, newdata = test_data, type = "response")
  glm_metrics <- evaluate_classifier(test_data[[target_col]], glm_test_prob, threshold = threshold)
  
  cat(sprintf("  ✓ Logistic Regression -> Acc: %.3f | Prec: %.3f | Rec: %.3f | F1: %.3f | AUC: %.3f\n",
              glm_metrics$accuracy, glm_metrics$precision, glm_metrics$recall, glm_metrics$f1_score, glm_metrics$auc))
  
  # ----------------------------------------------------------------------------
  # 2. Advanced Model: Random Forest
  # ----------------------------------------------------------------------------
  cat(sprintf("[MODELING] Training Random Forest (ntree = %d, mtry = %d)...\n",
              config$modeling$rf_ntree, config$modeling$rf_mtry))
  set.seed(config$seed)
  rf_fit <- randomForest(
    model_formula,
    data = train_data,
    ntree = config$modeling$rf_ntree,
    mtry = config$modeling$rf_mtry,
    importance = TRUE
  )
  
  # Predict Probabilities on Test Data (Column 'Yes')
  rf_test_prob_matrix <- predict(rf_fit, newdata = test_data, type = "prob")
  rf_test_prob <- rf_test_prob_matrix[, "Yes"]
  rf_metrics <- evaluate_classifier(test_data[[target_col]], rf_test_prob, threshold = threshold)
  
  cat(sprintf("  ✓ Random Forest       -> Acc: %.3f | Prec: %.3f | Rec: %.3f | F1: %.3f | AUC: %.3f\n",
              rf_metrics$accuracy, rf_metrics$precision, rf_metrics$recall, rf_metrics$f1_score, rf_metrics$auc))
  
  # ----------------------------------------------------------------------------
  # 3. Model Comparison Table
  # ----------------------------------------------------------------------------
  comparison_df <- data.frame(
    Model = c("Logistic Regression (Baseline)", "Random Forest (Advanced)"),
    Accuracy = round(c(glm_metrics$accuracy, rf_metrics$accuracy), 4),
    Precision = round(c(glm_metrics$precision, rf_metrics$precision), 4),
    Recall = round(c(glm_metrics$recall, rf_metrics$recall), 4),
    Specificity = round(c(glm_metrics$specificity, rf_metrics$specificity), 4),
    F1_Score = round(c(glm_metrics$f1_score, rf_metrics$f1_score), 4),
    ROC_AUC = round(c(glm_metrics$auc, rf_metrics$auc), 4),
    TP = c(glm_metrics$tp, rf_metrics$tp),
    TN = c(glm_metrics$tn, rf_metrics$tn),
    FP = c(glm_metrics$fp, rf_metrics$fp),
    FN = c(glm_metrics$fn, rf_metrics$fn),
    stringsAsFactors = FALSE
  )
  
  tables_dir <- config$paths$tables_dir
  if (!dir.exists(tables_dir)) dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  write_csv(comparison_df, file.path(tables_dir, "model_comparison_metrics.csv"))
  cat(sprintf("[SUCCESS] Saved model comparison metrics to '%s'.\n",
              file.path(tables_dir, "model_comparison_metrics.csv")))
  
  # ----------------------------------------------------------------------------
  # 4. Confusion Matrices Table
  # ----------------------------------------------------------------------------
  conf_df <- data.frame(
    Model = rep(c("Logistic Regression", "Random Forest"), each = 4),
    Actual = rep(c("No", "No", "Yes", "Yes"), times = 2),
    Predicted = rep(c("No", "Yes", "No", "Yes"), times = 2),
    Count = c(
      glm_metrics$tn, glm_metrics$fp, glm_metrics$fn, glm_metrics$tp,
      rf_metrics$tn, rf_metrics$fp, rf_metrics$fn, rf_metrics$tp
    ),
    stringsAsFactors = FALSE
  )
  write_csv(conf_df, file.path(tables_dir, "confusion_matrices.csv"))
  
  # ----------------------------------------------------------------------------
  # 5. Feature Importance Extraction
  # ----------------------------------------------------------------------------
  rf_imp <- as.data.frame(importance(rf_fit))
  rf_imp$Feature <- rownames(rf_imp)
  rf_imp <- rf_imp %>%
    select(Feature, MeanDecreaseAccuracy, MeanDecreaseGini) %>%
    arrange(desc(MeanDecreaseGini))
  
  write_csv(rf_imp, file.path(tables_dir, "feature_importance.csv"))
  cat(sprintf("[SUCCESS] Saved feature importance rankings to '%s'.\n",
              file.path(tables_dir, "feature_importance.csv")))
  
  # ----------------------------------------------------------------------------
  # 6. Test Set Predictions Export
  # ----------------------------------------------------------------------------
  test_preds <- test_data %>%
    select(CustomerID, Total_Spend_USD, Total_Purchases, Recency_Days, Loyalty_Program_Member, Repeat_Purchase) %>%
    mutate(
      Actual_Repeat = Repeat_Purchase,
      GLM_Predicted_Prob = round(glm_test_prob, 4),
      GLM_Predicted_Class = ifelse(glm_test_prob >= threshold, "Yes", "No"),
      RF_Predicted_Prob = round(rf_test_prob, 4),
      RF_Predicted_Class = ifelse(rf_test_prob >= threshold, "Yes", "No")
    )
  
  write_csv(test_preds, file.path(tables_dir, "test_set_predictions.csv"))
  cat(sprintf("[SUCCESS] Saved test set predictions to '%s'.\n",
              file.path(tables_dir, "test_set_predictions.csv")))
  
  # ----------------------------------------------------------------------------
  # 7. Persist Fitted Model Objects
  # ----------------------------------------------------------------------------
  models_dir <- config$paths$models_dir
  if (!dir.exists(models_dir)) dir.create(models_dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(glm_fit, file = file.path(models_dir, "logistic_regression_model.rds"))
  saveRDS(rf_fit, file = file.path(models_dir, "random_forest_model.rds"))
  cat(sprintf("[SUCCESS] Saved model objects to '%s'.\n", models_dir))
  
  return(list(
    glm_model = glm_fit,
    rf_model = rf_fit,
    glm_metrics = glm_metrics,
    rf_metrics = rf_metrics,
    comparison = comparison_df,
    feature_importance = rf_imp,
    test_predictions = test_preds
  ))
}

#' Real-Time Single Customer Purchase Propensity Inference
#'
#' @param new_customer_data A 1-row data frame with customer features
#' @param model Trained model object (glm or randomForest)
#' @return A list with predicted probability, class label, and risk tier
predict_customer_purchase <- function(new_customer_data, model) {
  if (inherits(model, "glm")) {
    prob <- predict(model, newdata = new_customer_data, type = "response")
  } else if (inherits(model, "randomForest")) {
    prob <- predict(model, newdata = new_customer_data, type = "prob")[, "Yes"]
  } else {
    stop("Unsupported model class for prediction.")
  }
  
  prob_val <- as.numeric(prob)
  class_val <- ifelse(prob_val >= 0.50, "Repeat Buyer", "Non-Repeat Buyer")
  propensity_tier <- ifelse(prob_val >= 0.70, "High Propensity",
                     ifelse(prob_val >= 0.40, "Moderate Propensity", "Low Propensity / At Risk"))
  
  return(list(
    predicted_probability = round(prob_val, 4),
    predicted_class = class_val,
    propensity_tier = propensity_tier
  ))
}
