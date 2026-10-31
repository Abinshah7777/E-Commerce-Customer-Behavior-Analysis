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
calculate_roc_auc <- function(actual_binary, predicted_prob) {
  ord <- order(predicted_prob, decreasing = TRUE)
  actual_sorted <- actual_binary[ord]

  n_pos <- sum(actual_sorted == 1)
  n_neg <- sum(actual_sorted == 0)

  if (n_pos == 0 || n_neg == 0) return(list(auc = 0.5, fpr = c(0, 1), tpr = c(0, 1)))

  tpr <- c(0, cumsum(actual_sorted == 1) / n_pos)
  fpr <- c(0, cumsum(actual_sorted == 0) / n_neg)

  auc <- sum(diff(fpr) * (tpr[-1] + tpr[-length(tpr)]) / 2)
  return(list(auc = max(0.5, round(auc, 4)), fpr = fpr, tpr = tpr))
}

#' Calculate Comprehensive Classification Metrics
evaluate_classifier <- function(actual, predicted_prob, threshold = 0.50) {
  # Standardize actual to binary 0/1
  lvl <- levels(as.factor(actual))
  pos_label <- if ("Yes" %in% lvl) "Yes" else if ("1" %in% lvl) "1" else lvl[2]
  actual_binary <- ifelse(actual == pos_label, 1, 0)
  pred_binary <- ifelse(predicted_prob >= threshold, 1, 0)

  tp <- sum(actual_binary == 1 & pred_binary == 1)
  tn <- sum(actual_binary == 0 & pred_binary == 0)
  fp <- sum(actual_binary == 0 & pred_binary == 1)
  fn <- sum(actual_binary == 1 & pred_binary == 0)

  total <- tp + tn + fp + fn
  accuracy <- if (total > 0) (tp + tn) / total else 0.0
  precision <- if ((tp + fp) > 0) tp / (tp + fp) else 0.0
  recall <- if ((tp + fn) > 0) tp / (tp + fn) else 0.0
  specificity <- if ((tn + fp) > 0) tn / (tn + fp) else 0.0
  f1_score <- if ((precision + recall) > 0) 2 * (precision * recall) / (precision + recall) else 0.0

  roc_res <- calculate_roc_auc(actual_binary, predicted_prob)

  return(list(
    accuracy = round(accuracy, 4),
    precision = round(precision, 4),
    recall = round(recall, 4),
    specificity = round(specificity, 4),
    f1_score = round(f1_score, 4),
    auc = roc_res$auc,
    roc_curve = roc_res,
    tp = tp,
    tn = tn,
    fp = fp,
    fn = fn
  ))
}

#' Dynamic Supervised Classification and Propensity Modeling
train_and_evaluate_models <- function(train_data, test_data, config, target_col = NULL) {
  cat("\n------------------------------------------------------------------\n")
  cat("   PURCHASE PREDICTION: MACHINE LEARNING MODELING                 \n")
  cat("------------------------------------------------------------------\n")

  tables_dir <- config$paths$tables_dir
  models_dir <- config$paths$models_dir
  if (!dir.exists(tables_dir)) dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(models_dir)) dir.create(models_dir, recursive = TRUE, showWarnings = FALSE)

  # 1. Determine Target Variable
  if (is.null(target_col)) {
    candidates <- c(config$modeling$target_var, config$modeling$fallback_target_var, "Subscription_Status", "Repeat_Purchase", "Discount_Applied")
    for (cand in candidates) {
      if (cand %in% colnames(train_data) && length(unique(na.omit(train_data[[cand]]))) == 2) {
        target_col <- cand
        break
      }
    }
  }

  # If still null, search for any binary column
  if (is.null(target_col) || !target_col %in% colnames(train_data)) {
    for (col in colnames(train_data)) {
      if (col %in% c("CustomerID", "Customer_ID", "Cluster_ID")) next
      if (length(unique(na.omit(train_data[[col]]))) == 2) {
        target_col <- col
        break
      }
    }
  }

  if (is.null(target_col) || !target_col %in% colnames(train_data)) {
    cat("[WARNING] No suitable binary classification target identified in dataset.\n")
    cat("[INFO] Purchase prediction module disabled for this dataset.\n")
    return(list(
      model_available = FALSE,
      message = "No binary target variable was detected in this dataset. Predictive modeling requires a 2-class outcome attribute."
    ))
  }

  cat(sprintf("[MODELING] Selected Target Variable: '%s'\n", target_col))

  # Format target as binary factor (0 and 1)
  lvl <- levels(as.factor(train_data[[target_col]]))
  pos_class <- if ("Yes" %in% lvl) "Yes" else if ("1" %in% lvl) "1" else lvl[2]
  train_data$target_binary <- as.factor(ifelse(train_data[[target_col]] == pos_class, 1, 0))
  test_data$target_binary <- as.factor(ifelse(test_data[[target_col]] == pos_class, 1, 0))

  # 2. Select Suitable Predictors (Numeric and Low-Cardinality Categorical)
  # Prevent target leakage: exclude target and any direct synonyms/derivatives
  leakage_cols <- c(
    target_col,
    "Subscription_Status",
    "Loyalty_Program_Member",
    "Repeat_Purchase",
    "CustomerID",
    "Customer_ID",
    "Cluster_ID",
    "Cluster_Name",
    "target_binary"
  )
  candidate_preds <- setdiff(colnames(train_data), leakage_cols)
  valid_preds <- c()

  for (col in candidate_preds) {
    if (is.numeric(train_data[[col]])) {
      valid_preds <- c(valid_preds, col)
    } else if (is.character(train_data[[col]]) || is.factor(train_data[[col]])) {
      # Only include categorical features with 10 or fewer distinct levels
      n_lev <- length(unique(na.omit(train_data[[col]])))
      if (n_lev >= 2 && n_lev <= 10) {
        train_data[[col]] <- as.factor(train_data[[col]])
        test_data[[col]] <- as.factor(test_data[[col]])
        valid_preds <- c(valid_preds, col)
      }
    }
  }

  if (length(valid_preds) == 0) {
    cat("[WARNING] Insufficient valid predictor variables found for modeling.\n")
    return(list(model_available = FALSE, message = "No valid numerical or low-cardinality predictors found."))
  }

  cat(sprintf("[MODELING] Candidate Predictors (%d features): %s\n",
              length(valid_preds), paste(valid_preds, collapse = ", ")))

  formula_str <- paste("target_binary ~", paste(valid_preds, collapse = " + "))
  model_formula <- as.formula(formula_str)

  # 3. Model 1: Logistic Regression (Baseline)
  cat("[MODELING] Fitting Logistic Regression (GLM Binomial)...\n")
  glm_fit <- tryCatch({
    glm(model_formula, data = train_data, family = binomial(link = "logit"))
  }, error = function(e) {
    cat(sprintf("[WARN] GLM error: %s. Falling back to numeric predictors only.\n", e$message))
    num_only <- valid_preds[sapply(train_data[valid_preds], is.numeric)]
    glm(as.formula(paste("target_binary ~", paste(num_only, collapse = " + "))), data = train_data, family = binomial)
  })

  glm_test_prob <- predict(glm_fit, newdata = test_data, type = "response")
  glm_test_prob[is.na(glm_test_prob)] <- 0.5
  glm_metrics <- evaluate_classifier(test_data$target_binary, glm_test_prob, threshold = config$modeling$prob_threshold)

  # 4. Model 2: Random Forest (Ensemble)
  cat(sprintf("[MODELING] Fitting Random Forest Classifier (%d trees)...\n", config$modeling$rf_ntree))
  set.seed(config$seed)
  rf_fit <- tryCatch({
    randomForest(
      model_formula,
      data = train_data,
      ntree = config$modeling$rf_ntree,
      importance = TRUE
    )
  }, error = function(e) {
    cat(sprintf("[WARN] Random Forest error: %s. Fitting on numeric predictors.\n", e$message))
    num_only <- valid_preds[sapply(train_data[valid_preds], is.numeric)]
    randomForest(
      as.formula(paste("target_binary ~", paste(num_only, collapse = " + "))),
      data = train_data,
      ntree = 100,
      importance = TRUE
    )
  })

  rf_prob_matrix <- predict(rf_fit, newdata = test_data, type = "prob")
  rf_test_prob <- if ("1" %in% colnames(rf_prob_matrix)) rf_prob_matrix[, "1"] else rf_prob_matrix[, 2]
  rf_test_prob[is.na(rf_test_prob)] <- 0.5
  rf_metrics <- evaluate_classifier(test_data$target_binary, rf_test_prob, threshold = config$modeling$prob_threshold)

  cat(sprintf("[RESULTS] Logistic Regression -> Accuracy: %.3f | ROC-AUC: %.3f | F1: %.3f\n",
              glm_metrics$accuracy, glm_metrics$auc, glm_metrics$f1_score))
  cat(sprintf("[RESULTS] Random Forest       -> Accuracy: %.3f | ROC-AUC: %.3f | F1: %.3f\n",
              rf_metrics$accuracy, rf_metrics$auc, rf_metrics$f1_score))

  # 5. Model Comparison Metrics Table
  model_comp_df <- data.frame(
    Model = c("Logistic Regression (Baseline)", "Random Forest (200 Trees)"),
    Target = target_col,
    Accuracy = c(glm_metrics$accuracy, rf_metrics$accuracy),
    Precision = c(glm_metrics$precision, rf_metrics$precision),
    Recall = c(glm_metrics$recall, rf_metrics$recall),
    Specificity = c(glm_metrics$specificity, rf_metrics$specificity),
    F1_Score = c(glm_metrics$f1_score, rf_metrics$f1_score),
    ROC_AUC = c(glm_metrics$auc, rf_metrics$auc)
  )
  write_csv(model_comp_df, file.path(tables_dir, "model_comparison_metrics.csv"))

  # 6. Feature Importance Table
  imp_matrix <- importance(rf_fit)
  gini_col <- if ("MeanDecreaseGini" %in% colnames(imp_matrix)) "MeanDecreaseGini" else colnames(imp_matrix)[ncol(imp_matrix)]
  feat_imp_df <- data.frame(
    Feature = rownames(imp_matrix),
    MeanDecreaseGini = round(imp_matrix[, gini_col], 3),
    stringsAsFactors = FALSE
  ) %>% arrange(desc(MeanDecreaseGini))
  write_csv(feat_imp_df, file.path(tables_dir, "feature_importance.csv"))

  # 7. Persist Models
  saveRDS(glm_fit, file.path(models_dir, "logistic_regression_model.rds"))
  saveRDS(rf_fit, file.path(models_dir, "random_forest_model.rds"))

  # 8. Export Test Set Predictions
  test_preds_df <- test_data
  test_preds_df$GLM_Predicted_Prob <- round(glm_test_prob, 4)
  test_preds_df$RF_Predicted_Prob <- round(rf_test_prob, 4)
  write_csv(test_preds_df, file.path(tables_dir, "test_set_predictions.csv"))

  return(list(
    model_available = TRUE,
    target_col = target_col,
    predictors = valid_preds,
    glm_model = glm_fit,
    rf_model = rf_fit,
    glm_metrics = glm_metrics,
    rf_metrics = rf_metrics,
    model_comparison = model_comp_df,
    feature_importance = feat_imp_df,
    test_predictions = test_preds_df
  ))
}
