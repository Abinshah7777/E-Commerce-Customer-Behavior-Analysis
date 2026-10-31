# ==============================================================================
# CONFIGURATION MODULE: config.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# ==============================================================================

# Global Project Configuration
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
    version = "2.0.0"
  ),

  # Default Genuine Kaggle Dataset Metadata
  kaggle_dataset = list(
    name = "Customer Shopping Trends Dataset",
    author = "Sourav Banerjee",
    source_url = "https://www.kaggle.com/datasets/iamsouravbanerjee/customer-shopping-trends-dataset",
    raw_file = "shopping_trends.csv",
    n_observations = 3900,
    n_features = 18
  ),

  # Reproducibility Seed
  seed = 2026,

  # File Paths
  paths = list(
    data_raw = file.path("data", "raw", "customer_data.csv"),
    data_kaggle_backup = file.path("data", "raw", "shopping_trends.csv"),
    data_sample_excel = file.path("data", "raw", "customer_data_sample.xlsx"),
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

  # Clustering Configuration (K-Means)
  clustering = list(
    features = c(
      "Total_Spend_USD",
      "Avg_Order_Value_USD",
      "Total_Purchases",
      "Recency_Days",
      "Customer_Satisfaction_Score",
      "Age"
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
    ),
    palette = c(
      "High-Value Loyalists"     = "#1b9e77",
      "Active Mid-Tier Regulars"  = "#2b5c8f",
      "Discount-Driven Shoppers"  = "#e6ab02",
      "Low-Frequency At-Risk"    = "#d95f02",
      "Occasional Browsers"      = "#8e44ad",
      "New Cohort"               = "#16a085"
    )
  ),

  # Predictive Modeling Configuration
  modeling = list(
    target_var = "Subscription_Status", # Authentic binary target from Kaggle dataset (Yes/No)
    fallback_target_var = "Repeat_Purchase",
    predictor_vars = c(
      "Age",
      "Gender",
      "Category",
      "Total_Spend_USD",
      "Avg_Order_Value_USD",
      "Total_Purchases",
      "Recency_Days",
      "Customer_Satisfaction_Score",
      "Discount_Applied",
      "Payment_Method",
      "Shipping_Type"
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

# Standard Cluster Persona Color Palette (accessible globally across scripts)
PALETTE_CLUSTERS <- c(
  "High-Value Loyalists"     = "#1b9e77",
  "Active Mid-Tier Regulars"  = "#2b5c8f",
  "Discount-Driven Shoppers"  = "#e6ab02",
  "Low-Frequency At-Risk"    = "#d95f02",
  "Occasional Browsers"      = "#8e44ad",
  "New Cohort"               = "#16a085",
  "Cluster 1"                = "#1b9e77",
  "Cluster 2"                = "#2b5c8f",
  "Cluster 3"                = "#e6ab02",
  "Cluster 4"                = "#d95f02",
  "Cluster 5"                = "#8e44ad",
  "Cluster 6"                = "#16a085"
)

