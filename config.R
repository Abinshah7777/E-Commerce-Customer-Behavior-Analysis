# ==============================================================================
# CONFIGURATION MODULE: config.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# Authors: Muhammed Shijil MK, Navin Krishna IN, Abinshah PM, Liju Shirvan
# ==============================================================================

# Global Project Metadata
CONFIG <- list(
  project_info = list(
    title = "E-Commerce Customer Behavior Analysis",
    subtitle = "Customer Segmentation and Purchase Prediction",
    subject = "Big Data Analytics – R Programming Mini Project",
    academic_year = "2026–2027",
    college = "Mentor Engineering College",
    departments = c(
      "Department of Artificial Intelligence and Data Science",
      "Department of Computer Science and Engineering"
    ),
    authors = c(
      "Muhammed Shijil MK",
      "Navin Krishna IN",
      "Abinshah PM",
      "Liju Shirvan",
      "Hishal MT"
    ),
    date = "October 2026",
    version = "1.0.0"
  ),

  # Reproducibility Seed
  seed = 2026,

  # File Paths
  paths = list(
    data_raw = file.path("data", "raw", "customer_data.csv"),
    data_processed = file.path("data", "processed", "cleaned_customer_data.csv"),
    data_readme = file.path("data", "README.md"),
    plots_dir = file.path("outputs", "plots"),
    tables_dir = file.path("outputs", "tables"),
    models_dir = file.path("outputs", "models"),
    reports_dir = file.path("outputs", "reports"),
    final_report = file.path("outputs", "reports", "analytical_report.md"),
    cluster_assignments = file.path("outputs", "tables", "customer_cluster_assignments.csv"),
    cluster_profiles = file.path("outputs", "tables", "cluster_profile_summary.csv"),
    model_comparison = file.path("outputs", "tables", "model_comparison_metrics.csv"),
    predictions = file.path("outputs", "tables", "test_set_predictions.csv")
  ),

  # Dataset Parameters (Synthetic Generation)
  dataset = list(
    n_customers = 5000,
    missing_rate = 0.02, # 2% missing in optional fields to test imputation
    n_duplicates = 15    # duplicate rows to test duplicate detection
  ),

  # Clustering Configuration (K-Means)
  clustering = list(
    features = c(
      "Total_Spend_USD",
      "Avg_Order_Value_USD",
      "Total_Purchases",
      "Recency_Days",
      "App_Session_Minutes",
      "Discount_Usage_Ratio"
    ),
    k_range = 2:8,
    k_optimal = 4,
    nstart = 25,
    max_iter = 300,
    cluster_labels = c(
      "Cluster_1" = "High-Value Loyalists",
      "Cluster_2" = "Active Mid-Tier Regulars",
      "Cluster_3" = "Discount-Driven Shoppers",
      "Cluster_4" = "Low-Frequency At-Risk"
    )
  ),

  # Predictive Modeling Configuration
  modeling = list(
    target_var = "Repeat_Purchase",
    predictor_vars = c(
      "Age",
      "Annual_Income_USD",
      "Customer_Tenure_Months",
      "Total_Spend_USD",
      "Avg_Order_Value_USD",
      "Total_Purchases",
      "Recency_Days",
      "App_Session_Minutes",
      "Website_Visits_Per_Month",
      "Discount_Usage_Ratio",
      "Loyalty_Program_Member",
      "Gender",
      "City_Tier",
      "Preferred_Category"
    ),
    train_ratio = 0.75,
    prob_threshold = 0.50,
    rf_ntree = 200,
    rf_mtry = 3
  )
)

# Helper function to get config
get_config <- function() {
  return(CONFIG)
}
