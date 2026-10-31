# ==============================================================================
# DATA LOADING & SYNTHESIS MODULE: R/data_loading.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# ==============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

#' Generate Reproducible Synthetic E-Commerce Customer Dataset
#'
#' @param n Integer: Number of unique customer records to generate (default 5000)
#' @param seed Integer: Random seed for reproducible generation
#' @param missing_rate Numeric: Fraction of missing values to inject into optional fields
#' @param n_duplicates Integer: Number of duplicate records to inject
#' @param output_path Character: Path where the raw CSV will be saved
#' @return A data.frame containing the simulated customer records
generate_synthetic_dataset <- function(n = 5000,
                                       seed = 2026,
                                       missing_rate = 0.02,
                                       n_duplicates = 15,
                                       output_path = file.path("data", "raw", "customer_data.csv")) {
  set.seed(seed)
  cat(sprintf("[DATA LOADING] Generating %d synthetic e-commerce customer profiles...\n", n))

  # 1. Customer Demographics
  customer_ids <- sprintf("CUST_%04d", 1:n)
  
  # Age: Bimodal mix reflecting young adults (20-35) and established shoppers (36-65)
  age_mix <- c(rnorm(n * 0.6, mean = 29, sd = 6), rnorm(n * 0.4, mean = 48, sd = 10))
  age <- pmax(18, pmin(72, round(sample(age_mix, n))))
  
  gender <- sample(
    c("Female", "Male", "Other"),
    size = n,
    replace = TRUE,
    prob = c(0.49, 0.47, 0.04)
  )
  
  city_tier <- sample(
    c("Tier 1", "Tier 2", "Tier 3"),
    size = n,
    replace = TRUE,
    prob = c(0.45, 0.35, 0.20)
  )
  
  # Annual Income: Log-normal distribution scaled by city tier
  base_income <- rlnorm(n, meanlog = 10.8, sdlog = 0.45) # Approx $30k - $120k
  tier_multiplier <- ifelse(city_tier == "Tier 1", 1.25, ifelse(city_tier == "Tier 2", 1.0, 0.85))
  annual_income <- round(pmax(18000, pmin(185000, base_income * tier_multiplier)), 2)
  
  customer_tenure_months <- sample(1:72, size = n, replace = TRUE)
  
  # 2. Purchasing Behavior & Engagement
  # Total Purchases: Negative binomial distribution (right-skewed frequency)
  total_purchases <- rnbinom(n, size = 4, prob = 0.35) + 1
  total_purchases <- pmin(65, total_purchases)
  
  # Average Order Value (AOV): Gamma distribution influenced by income
  aov_base <- rgamma(n, shape = 3.5, scale = 25) # Approx $40 - $250
  aov_multiplier <- 0.7 + (annual_income / 100000) * 0.5
  avg_order_value <- round(pmax(15.00, pmin(450.00, aov_base * aov_multiplier)), 2)
  
  total_spend <- round(total_purchases * avg_order_value, 2)
  
  # Recency: Exponentially distributed days since last purchase (1 to 365)
  recency_days <- round(pmax(1, pmin(365, rexp(n, rate = 1 / 45) + 1)))
  
  # App Session Minutes: Mobile engagement
  app_session_mins <- round(pmax(2.0, pmin(180.0, rgamma(n, shape = 2.5, scale = 16))), 1)
  
  # Website Visits: Web portal visits per month
  web_visits <- round(pmax(1, pmin(45, rpois(n, lambda = 8) + (total_purchases / 5))))
  
  # Discount Usage Ratio: Proportion of orders placed with promotions
  discount_usage <- round(pmax(0.00, pmin(0.95, rbeta(n, shape1 = 2, shape2 = 5))), 3)
  
  # Preferred Product Category
  categories <- c("Electronics", "Fashion", "Home & Living", "Beauty & Health", "Books & Media")
  preferred_category <- sample(
    categories,
    size = n,
    replace = TRUE,
    prob = c(0.30, 0.28, 0.18, 0.14, 0.10)
  )
  
  # Loyalty Program Membership (correlated with spend and frequency)
  loyalty_prob <- 1 / (1 + exp(-( -2.2 + 0.0006 * total_spend + 0.05 * total_purchases + 0.02 * customer_tenure_months )))
  loyalty_member <- ifelse(runif(n) < loyalty_prob, 1, 0)
  
  # Customer Satisfaction Score (1-5)
  csat_base <- 3 + (loyalty_member * 0.6) - (recency_days / 150) + rnorm(n, mean = 0, sd = 0.7)
  csat <- pmax(1, pmin(5, round(csat_base)))
  
  # 3. Supervised Classification Target: Repeat_Purchase (Future 30-day window)
  # Data Generating Process (Logistic regression formula with realistic noise)
  logit_p <- -1.30 - 
    (0.015 * recency_days) + 
    (0.065 * total_purchases) + 
    (0.00030 * total_spend) + 
    (0.45 * loyalty_member) + 
    (0.012 * app_session_mins) + 
    (0.040 * web_visits) + 
    (0.20 * (csat - 3)) - 
    (0.85 * discount_usage)
  
  repeat_purchase_prob <- 1 / (1 + exp(-logit_p))
  repeat_purchase <- ifelse(runif(n) < repeat_purchase_prob, 1, 0)
  
  # Build DataFrame
  df <- data.frame(
    CustomerID = customer_ids,
    Age = as.integer(age),
    Gender = as.character(gender),
    City_Tier = as.character(city_tier),
    Annual_Income_USD = annual_income,
    Customer_Tenure_Months = as.integer(customer_tenure_months),
    Total_Purchases = as.integer(total_purchases),
    Total_Spend_USD = total_spend,
    Avg_Order_Value_USD = avg_order_value,
    Recency_Days = as.integer(recency_days),
    App_Session_Minutes = app_session_mins,
    Website_Visits_Per_Month = as.integer(web_visits),
    Discount_Usage_Ratio = discount_usage,
    Preferred_Category = as.character(preferred_category),
    Loyalty_Program_Member = as.integer(loyalty_member),
    Customer_Satisfaction_Score = as.integer(csat),
    Repeat_Purchase = as.integer(repeat_purchase),
    stringsAsFactors = FALSE
  )
  
  # 4. Inject Realistic Data Quality Artifacts
  # Injected Missing Values (NA) in optional demographic and behavioral attributes
  n_na <- round(n * missing_rate)
  df$Annual_Income_USD[sample(1:n, n_na)] <- NA
  df$App_Session_Minutes[sample(1:n, n_na)] <- NA
  df$Customer_Tenure_Months[sample(1:n, n_na)] <- NA
  
  # Injected Duplicate Records
  if (n_duplicates > 0) {
    dup_indices <- sample(1:n, n_duplicates)
    duplicates <- df[dup_indices, ]
    df <- rbind(df, duplicates)
  }
  
  # 5. Persist Raw Dataset
  dir_path <- dirname(output_path)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  }
  
  write_csv(df, output_path)
  cat(sprintf("[DATA LOADING] Successfully wrote raw dataset to '%s' (%d total rows including %d duplicates).\n",
              output_path, nrow(df), n_duplicates))
  
  return(df)
}

#' Load Raw Dataset from CSV
#'
#' @param file_path Character: Path to CSV file
#' @return A data.frame
load_raw_data <- function(file_path = file.path("data", "raw", "customer_data.csv")) {
  if (!file.exists(file_path)) {
    stop(sprintf("[ERROR] Dataset file not found at path: %s", file_path))
  }
  
  df <- read_csv(file_path, show_col_types = FALSE)
  cat(sprintf("[DATA LOADING] Loaded %d rows and %d columns from '%s'.\n",
              nrow(df), ncol(df), file_path))
  return(as.data.frame(df))
}
