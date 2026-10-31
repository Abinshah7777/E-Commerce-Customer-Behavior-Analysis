# ==============================================================================
# MASTER ORCHESTRATION PIPELINE: main.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# Authors: Muhammed Shijil MK, Navin Krishna IN, Abinshah PM, Liju Shirvan, Hishal MT
# ==============================================================================

# Start Timer
start_time <- Sys.time()

cat("\n")
cat("================================================================================\n")
cat("   E-COMMERCE CUSTOMER BEHAVIOR ANALYSIS: END-TO-END ANALYTICS PIPELINE        \n")
cat("   Mentor Engineering College | B.Tech Academic Year 2026–2027                 \n")
cat("================================================================================\n\n")

# ------------------------------------------------------------------------------
# STAGE 1: LOAD CONFIGURATION & DEPENDENCIES
# ------------------------------------------------------------------------------
cat("[STAGE 1/11] Initializing Configuration & Core Libraries...\n")
if (!file.exists("config.R")) {
  stop("[CRITICAL ERROR] 'config.R' not found in working directory. Please run from project root.")
}
source("config.R")
config <- get_config()

# Load Required Libraries with informative warnings if missing
required_libs <- c("dplyr", "tidyr", "readr", "ggplot2", "scales", "cluster", "randomForest")
for (lib in required_libs) {
  if (!suppressPackageStartupMessages(require(lib, character.only = TRUE, quietly = TRUE))) {
    stop(sprintf("[CRITICAL ERROR] Package '%s' is not installed. Please run 'Rscript setup.R'.", lib))
  }
}
cat("  ✓ All required libraries verified and loaded successfully.\n")

# Source Pipeline Modules
source(file.path("R", "data_loading.R"))
source(file.path("R", "data_preprocessing.R"))
source(file.path("R", "exploratory_analysis.R"))
source(file.path("R", "statistical_analysis.R"))
source(file.path("R", "customer_segmentation.R"))
source(file.path("R", "purchase_prediction.R"))
source(file.path("R", "visualization.R"))
source(file.path("R", "business_insights.R"))
source(file.path("R", "generate_report.R"))
cat("  ✓ All 9 analysis modules sourced successfully.\n")

# ------------------------------------------------------------------------------
# STAGE 2: DATA LOADING & ACQUISITION
# ------------------------------------------------------------------------------
cat("\n[STAGE 2/11] Data Ingestion & Synthesis Verification...\n")
raw_data_path <- config$paths$data_raw

if (!file.exists(raw_data_path)) {
  cat(sprintf("[INFO] Raw data file '%s' not found. Generating reproducible dataset...\n", raw_data_path))
  raw_df <- generate_synthetic_dataset(
    n = config$dataset$n_customers,
    seed = config$seed,
    missing_rate = config$dataset$missing_rate,
    n_duplicates = config$dataset$n_duplicates,
    output_path = raw_data_path
  )
} else {
  cat(sprintf("[INFO] Raw dataset found at '%s'. Loading...\n", raw_data_path))
  raw_df <- load_raw_data(raw_data_path)
}
cat(sprintf("  ✓ Ingested %d records across %d columns.\n", nrow(raw_df), ncol(raw_df)))

# ------------------------------------------------------------------------------
# STAGE 3: DATA PREPROCESSING & CLEANSING
# ------------------------------------------------------------------------------
cat("\n[STAGE 3/11] Executing Data Preprocessing & Quality Engineering...\n")
prep_results <- preprocess_customer_data(raw_df, config)
cleaned_df <- prep_results$cleaned_data
scaled_data <- prep_results$scaled_clustering_data
train_data <- prep_results$train_data
test_data <- prep_results$test_data
prep_summary <- prep_results$preprocessing_summary
cat(sprintf("  ✓ Cleaned dataset prepared: %d observations ready for modeling.\n", nrow(cleaned_df)))

# ------------------------------------------------------------------------------
# STAGE 4: EXPLORATORY DATA ANALYSIS
# ------------------------------------------------------------------------------
cat("\n[STAGE 4/11] Computing Exploratory Data Analysis & Descriptive Metrics...\n")
eda_results <- perform_exploratory_analysis(cleaned_df, config)
cat("  ✓ Descriptive statistics and correlation matrices saved to outputs/tables/.\n")

# ------------------------------------------------------------------------------
# STAGE 5: INFERENTIAL STATISTICAL ANALYSIS
# ------------------------------------------------------------------------------
cat("\n[STAGE 5/11] Conducting Rigorous Statistical Hypothesis Testing...\n")
stat_results <- perform_statistical_analysis(cleaned_df, config)
cat(sprintf("  ✓ Completed %d hypothesis tests; documented in outputs/tables/.\n", nrow(stat_results)))

# ------------------------------------------------------------------------------
# STAGE 6: CUSTOMER SEGMENTATION (K-MEANS)
# ------------------------------------------------------------------------------
cat("\n[STAGE 6/11] Unsupervised Customer Segmentation via K-Means...\n")
seg_results <- perform_customer_segmentation(cleaned_df, scaled_data, config)
cat(sprintf("  ✓ Fitted optimal K-Means model with k = %d personas.\n", config$clustering$k_optimal))

# ------------------------------------------------------------------------------
# STAGE 7: PURCHASE PREDICTION MODELING (ML)
# ------------------------------------------------------------------------------
cat("\n[STAGE 7/11] Supervised Machine Learning & Purchase Prediction...\n")
pred_results <- train_and_evaluate_models(train_data, test_data, config)
cat(sprintf("  ✓ Logistic Regression (Baseline AUC: %.3f) | Random Forest (Advanced AUC: %.3f)\n",
            pred_results$glm_metrics$auc, pred_results$rf_metrics$auc))

# ------------------------------------------------------------------------------
# STAGE 8: CENTRALIZED VISUALIZATION EXPORT
# ------------------------------------------------------------------------------
cat("\n[STAGE 8/11] Exporting High-Resolution Publication Visualizations...\n")
generate_all_visualizations(cleaned_df, raw_df, seg_results, pred_results, config)
cat("  ✓ 15 publication figures exported to outputs/plots/.\n")

# ------------------------------------------------------------------------------
# STAGE 9: BUSINESS INSIGHTS & STRATEGIC RECOMMENDATIONS
# ------------------------------------------------------------------------------
cat("\n[STAGE 9/11] Formulating Strategic Commercial Recommendations...\n")
rec_results <- generate_business_recommendations(seg_results, pred_results, config)
cat(sprintf("  ✓ Formulated %d strategic business initiatives.\n", nrow(rec_results)))

# ------------------------------------------------------------------------------
# STAGE 10: AUTOMATED ANALYTICAL REPORT COMPILATION
# ------------------------------------------------------------------------------
cat("\n[STAGE 10/11] Compiling Comprehensive Analytical Report...\n")
report_file <- generate_analytical_report(eda_results, stat_results, seg_results, pred_results, rec_results, prep_summary, config)
cat(sprintf("  ✓ Analytical report compiled at: %s\n", report_file))

# ------------------------------------------------------------------------------
# STAGE 11: FINAL EXECUTION SUMMARY
# ------------------------------------------------------------------------------
end_time <- Sys.time()
elapsed_sec <- round(as.numeric(difftime(end_time, start_time, units = "secs")), 2)

cat("\n")
cat("================================================================================\n")
cat("   PIPELINE EXECUTION COMPLETED SUCCESSFULLY IN " %+% sprintf("%.2f seconds\n", elapsed_sec))
cat("================================================================================\n")
cat(sprintf("  • Processed Customers:     %d\n", nrow(cleaned_df)))
cat(sprintf("  • Optimal Clusters:        k = %d (%s)\n",
            config$clustering$k_optimal, paste(unique(seg_results$cluster_summary$Cluster_Name), collapse = ", ")))
cat(sprintf("  • Best Classification AUC: %.4f (Random Forest)\n", pred_results$rf_metrics$auc))
cat(sprintf("  • Generated Plots:         15 high-resolution figures in %s\n", config$paths$plots_dir))
cat(sprintf("  • Generated Data Tables:   8 CSV summaries in %s\n", config$paths$tables_dir))
cat(sprintf("  • Persisted Models:        K-Means, Logistic Regression, Random Forest in %s\n", config$paths$models_dir))
cat(sprintf("  • Comprehensive Report:    %s\n", report_file))
cat("================================================================================\n")
cat("   Mentor Engineering College | Big Data Analytics Mini Project (2026–2027)    \n")
cat("================================================================================\n\n")
