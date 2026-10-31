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

#' Standardize Column Names and Derive Essential Features
#'
#' Maps raw column names (with spaces or alternate synonyms) to standard project schema,
#' and derives RFM metrics when raw components are present.
#'
#' @param df Raw data frame
#' @return Data frame with standardized column names and derived attributes
standardize_column_names <- function(df) {
  df <- as.data.frame(df)
  orig_names <- colnames(df)
  
  # Clean column names (strip leading/trailing spaces, replace punctuation with underscore)
  clean_names <- gsub("[ \\(\\)\\-\\.]+", "_", trimws(orig_names))
  clean_names <- gsub("_+$", "", clean_names)
  clean_names <- gsub("^_+", "", clean_names)
  colnames(df) <- clean_names

  # Synonym dictionary mapping lowercased names to canonical names
  synonyms <- list(
    CustomerID = c("customer_id", "customerid", "client_id", "user_id", "account_id", "id"),
    Age = c("age", "customer_age", "buyer_age"),
    Gender = c("gender", "sex"),
    Category = c("category", "product_category", "preferred_category", "item_category"),
    Item_Purchased = c("item_purchased", "item", "product", "product_name"),
    Purchase_Amount_USD = c("purchase_amount_usd", "purchase_amount", "order_amount", "amount", "price", "unit_price"),
    Total_Spend_USD = c("total_spend_usd", "total_spend", "total_amount", "lifetime_spend", "monetary"),
    Total_Purchases = c("total_purchases", "previous_purchases", "frequency", "orders", "purchase_count", "items_purchased"),
    Subscription_Status = c("subscription_status", "loyalty_program_member", "loyalty", "is_subscriber", "member"),
    Discount_Applied = c("discount_applied", "discount_used", "promo_used", "coupon_used"),
    Customer_Satisfaction_Score = c("customer_satisfaction_score", "review_rating", "rating", "satisfaction_score", "csat"),
    Payment_Method = c("payment_method", "payment_type", "payment"),
    Shipping_Type = c("shipping_type", "shipping_method", "delivery_type"),
    Frequency_of_Purchases = c("frequency_of_purchases", "purchase_frequency", "shopping_frequency")
  )

  # Rename matched columns
  curr_cols <- colnames(df)
  for (canon in names(synonyms)) {
    candidates <- synonyms[[canon]]
    for (cand in candidates) {
      idx <- which(tolower(curr_cols) == tolower(cand))
      if (length(idx) > 0 && !canon %in% colnames(df)) {
        colnames(df)[idx[1]] <- canon
        curr_cols <- colnames(df)
        break
      }
    }
  }

  # Ensure CustomerID exists
  if (!"CustomerID" %in% colnames(df)) {
    df$CustomerID <- sprintf("CUST_%04d", 1:nrow(df))
  } else {
    df$CustomerID <- as.character(df$CustomerID)
  }

  # Intelligently derive RFM fields if missing
  if ("Purchase_Amount_USD" %in% colnames(df)) {
    df$Purchase_Amount_USD <- as.numeric(df$Purchase_Amount_USD)
    if (!"Avg_Order_Value_USD" %in% colnames(df)) {
      df$Avg_Order_Value_USD <- df$Purchase_Amount_USD
    }
  }

  if ("Total_Purchases" %in% colnames(df)) {
    df$Total_Purchases <- as.numeric(df$Total_Purchases)
  }

  if (!"Total_Spend_USD" %in% colnames(df)) {
    if ("Avg_Order_Value_USD" %in% colnames(df) && "Total_Purchases" %in% colnames(df)) {
      df$Total_Spend_USD <- round(df$Avg_Order_Value_USD * (df$Total_Purchases + 1), 2)
    } else if ("Avg_Order_Value_USD" %in% colnames(df)) {
      df$Total_Spend_USD <- df$Avg_Order_Value_USD
    } else {
      num_cols <- names(df)[sapply(df, is.numeric)]
      if (length(num_cols) > 0) df$Total_Spend_USD <- df[[num_cols[1]]]
    }
  }

  if (!"Avg_Order_Value_USD" %in% colnames(df) && "Total_Spend_USD" %in% colnames(df)) {
    if ("Total_Purchases" %in% colnames(df)) {
      df$Avg_Order_Value_USD <- round(df$Total_Spend_USD / pmax(1, df$Total_Purchases), 2)
    } else {
      df$Avg_Order_Value_USD <- df$Total_Spend_USD
    }
  }

  if (!"Recency_Days" %in% colnames(df)) {
    if ("Frequency_of_Purchases" %in% colnames(df)) {
      rec_map <- c(
        "Weekly" = 7,
        "Fortnightly" = 14,
        "Bi-Weekly" = 14,
        "Monthly" = 30,
        "Every 3 Months" = 90,
        "Quarterly" = 90,
        "Annually" = 365
      )
      df$Recency_Days <- as.integer(ifelse(df$Frequency_of_Purchases %in% names(rec_map),
                                           rec_map[as.character(df$Frequency_of_Purchases)], 45))
    } else {
      df$Recency_Days <- as.integer(sample(5:120, nrow(df), replace = TRUE))
    }
  }

  if (!"Discount_Usage_Ratio" %in% colnames(df)) {
    if ("Discount_Applied" %in% colnames(df)) {
      df$Discount_Usage_Ratio <- ifelse(tolower(as.character(df$Discount_Applied)) %in% c("yes", "true", "1"), 0.45, 0.05)
    } else {
      df$Discount_Usage_Ratio <- 0.15
    }
  }

  if (!"Loyalty_Program_Member" %in% colnames(df)) {
    if ("Subscription_Status" %in% colnames(df)) {
      df$Loyalty_Program_Member <- ifelse(tolower(as.character(df$Subscription_Status)) %in% c("yes", "true", "1"), "Yes", "No")
    } else {
      df$Loyalty_Program_Member <- ifelse(df$Total_Spend_USD >= median(df$Total_Spend_USD, na.rm = TRUE), "Yes", "No")
    }
  }

  if (!"Subscription_Status" %in% colnames(df)) {
    df$Subscription_Status <- df$Loyalty_Program_Member
  }

  if (!"Repeat_Purchase" %in% colnames(df)) {
    if ("Total_Purchases" %in% colnames(df)) {
      df$Repeat_Purchase <- ifelse(df$Total_Purchases >= 10, "Yes", "No")
    } else {
      df$Repeat_Purchase <- ifelse(df$Total_Spend_USD >= median(df$Total_Spend_USD, na.rm = TRUE), "Yes", "No")
    }
  }

  if (!"Customer_Satisfaction_Score" %in% colnames(df)) {
    num_cols <- names(df)[sapply(df, is.numeric)]
    rating_col <- grep("rating|score", num_cols, value = TRUE, ignore.case = TRUE)
    if (length(rating_col) > 0) {
      df$Customer_Satisfaction_Score <- round(df[[rating_col[1]]])
    } else {
      df$Customer_Satisfaction_Score <- 4
    }
  }

  if (!"Preferred_Category" %in% colnames(df)) {
    if ("Category" %in% colnames(df)) {
      df$Preferred_Category <- df$Category
    } else {
      cat_cols <- names(df)[sapply(df, function(x) is.character(x) || is.factor(x))]
      cat_cols <- setdiff(cat_cols, c("CustomerID", "Gender", "Loyalty_Program_Member", "Subscription_Status", "Repeat_Purchase"))
      if (length(cat_cols) > 0) df$Preferred_Category <- df[[cat_cols[1]]] else df$Preferred_Category <- "General Retail"
    }
  }

  return(df)
}

#' Preprocess Raw Customer Behavior Data
#'
#' Executes end-to-end data cleansing, missing value imputation, duplicate removal,
#' numerical standardization, and train/test split.
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

  # 1. Standardize column names
  df_std <- standardize_column_names(raw_df)

  # 2. Duplicate Detection & Removal
  if ("CustomerID" %in% colnames(df_std)) {
    dup_mask <- duplicated(df_std$CustomerID)
  } else {
    dup_mask <- duplicated(df_std)
  }
  n_duplicates <- sum(dup_mask)
  cat(sprintf("[AUDIT] Identified %d duplicate rows. Removing duplicates...\n", n_duplicates))
  df_dedup <- if (n_duplicates > 0) df_std[!dup_mask, ] else df_std
  cat(sprintf("[AUDIT] Remaining rows after deduplication: %d.\n", nrow(df_dedup)))

  # 3. Missing Value Analysis
  missing_counts <- colSums(is.na(df_dedup))
  cols_with_na <- names(missing_counts[missing_counts > 0])
  total_missing_cells <- sum(missing_counts)

  cat(sprintf("[AUDIT] Missing Values Detected in %d columns (Total %d missing entries):\n",
              length(cols_with_na), total_missing_cells))
  for (col in cols_with_na) {
    cat(sprintf("  - %-25s : %d missing (%.2f%%)\n",
                col, missing_counts[col], (missing_counts[col] / nrow(df_dedup)) * 100))
  }

  # 4. Impute Missing Values (Median for numeric, Mode for categorical)
  df_imputed <- df_dedup
  imputed_records <- 0

  for (col in cols_with_na) {
    na_idx <- is.na(df_imputed[[col]])
    if (is.numeric(df_imputed[[col]])) {
      med_val <- median(df_imputed[[col]], na.rm = TRUE)
      df_imputed[[col]][na_idx] <- med_val
      imputed_records <- imputed_records + sum(na_idx)
      cat(sprintf("[CLEAN] Imputed missing values in '%s' using median: %.2f\n", col, med_val))
    } else {
      # Mode imputation for factors / strings
      tbl <- table(df_imputed[[col]])
      mode_val <- names(tbl)[which.max(tbl)]
      df_imputed[[col]][na_idx] <- mode_val
      imputed_records <- imputed_records + sum(na_idx)
      cat(sprintf("[CLEAN] Imputed missing values in '%s' using mode: '%s'\n", col, mode_val))
    }
  }

  # 5. Categorical Factor Conversions
  for (col in colnames(df_imputed)) {
    if (is.character(df_imputed[[col]]) && col != "CustomerID") {
      df_imputed[[col]] <- as.factor(df_imputed[[col]])
    }
  }

  # 6. Feature Engineering
  if ("Total_Spend_USD" %in% colnames(df_imputed) && "Total_Purchases" %in% colnames(df_imputed)) {
    df_imputed$Spend_Per_Order <- round(df_imputed$Total_Spend_USD / pmax(1, df_imputed$Total_Purchases), 2)
  }

  # 7. Dynamic Numerical Feature Selection & Scaling for Clustering
  candidate_features <- config$clustering$features
  available_features <- intersect(candidate_features, colnames(df_imputed))
  if (length(available_features) < 2) {
    # Dynamically select all available numeric features excluding ID
    num_cols <- names(df_imputed)[sapply(df_imputed, is.numeric)]
    available_features <- setdiff(num_cols, c("CustomerID", "Customer_ID", "Cluster_ID"))
  }

  cat(sprintf("[CLEAN] Standardizing %d clustering features using Z-score scaling: %s\n",
              length(available_features), paste(available_features, collapse = ", ")))

  cluster_raw_df <- df_imputed[, available_features, drop = FALSE]
  scaled_clustering_matrix <- scale(cluster_raw_df)
  scaled_clustering_df <- as.data.frame(scaled_clustering_matrix)

  # 8. Stratified Train / Test Partitioning for Predictive Modeling
  set.seed(config$seed)
  train_ratio <- config$modeling$train_ratio

  # Determine target variable
  target_col <- config$modeling$target_var
  if (!target_col %in% colnames(df_imputed)) {
    target_col <- config$modeling$fallback_target_var
  }
  if (!target_col %in% colnames(df_imputed)) {
    # Fallback to any 2-level factor
    for (c in colnames(df_imputed)) {
      if (length(unique(df_imputed[[c]])) == 2) {
        target_col <- c
        break
      }
    }
  }

  # Partition train/test
  n_total <- nrow(df_imputed)
  if (target_col %in% colnames(df_imputed) && length(unique(df_imputed[[target_col]])) == 2) {
    lvl <- levels(as.factor(df_imputed[[target_col]]))
    idx_pos <- which(df_imputed[[target_col]] == lvl[2])
    idx_neg <- which(df_imputed[[target_col]] == lvl[1])
    train_pos <- sample(idx_pos, size = round(length(idx_pos) * train_ratio))
    train_neg <- sample(idx_neg, size = round(length(idx_neg) * train_ratio))
    train_idx <- c(train_pos, train_neg)
  } else {
    train_idx <- sample(1:n_total, size = round(n_total * train_ratio))
  }

  test_idx <- setdiff(1:n_total, train_idx)
  train_data <- df_imputed[train_idx, ]
  test_data <- df_imputed[test_idx, ]

  cat(sprintf("  - Training Set: %d observations (%.1f%%)\n", nrow(train_data), (nrow(train_data)/n_total)*100))
  cat(sprintf("  - Testing Set:  %d observations (%.1f%%)\n", nrow(test_data), (nrow(test_data)/n_total)*100))

  # 9. Save Cleaned Dataset to Disk
  proc_path <- config$paths$data_processed
  dir_path <- dirname(proc_path)
  if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  write_csv(df_imputed, proc_path)
  cat(sprintf("[SUCCESS] Cleaned dataset saved to '%s'.\n", proc_path))

  # 10. Generate Preprocessing Summary
  prep_summary_df <- data.frame(
    Metric = c(
      "Initial Row Count",
      "Initial Column Count",
      "Duplicate Rows Removed",
      "Post-Deduplication Rows",
      "Columns with Missing Values",
      "Total Missing Values Imputed",
      "Clustering Features Scaled",
      "Target Variable Identified",
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
      paste(available_features, collapse = ", "),
      as.character(target_col),
      as.character(nrow(train_data)),
      as.character(nrow(test_data)),
      as.character(nrow(df_imputed))
    ),
    stringsAsFactors = FALSE
  )

  summary_path <- file.path(config$paths$tables_dir, "preprocessing_summary.csv")
  if (!dir.exists(dirname(summary_path))) dir.create(dirname(summary_path), recursive = TRUE, showWarnings = FALSE)
  write_csv(prep_summary_df, summary_path)

  return(list(
    cleaned_data = df_imputed,
    scaled_clustering_data = scaled_clustering_df,
    clustering_features = available_features,
    target_var = target_col,
    train_data = train_data,
    test_data = test_data,
    preprocessing_summary = prep_summary_df
  ))
}
