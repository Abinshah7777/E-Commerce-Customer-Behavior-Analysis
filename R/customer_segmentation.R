# ==============================================================================
# CUSTOMER SEGMENTATION MODULE: R/customer_segmentation.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(cluster)
})

#' Execute Dynamic K-Means Customer Segmentation Workflow
#'
#' Evaluates optimal k using Elbow (WCSS) and Silhouette analysis, fits
#' K-Means algorithm, assigns interpretable business labels, and profiles clusters.
#'
#' @param cleaned_df Data frame: Cleaned customer dataset
#' @param scaled_data Data frame: Standardized clustering features
#' @param config List: Project configuration
#' @return A list containing fitted model, cluster assignments, metrics, and profiles
perform_customer_segmentation <- function(cleaned_df, scaled_data, config) {
  cat("\n------------------------------------------------------------------\n")
  cat("   CUSTOMER SEGMENTATION USING K-MEANS CLUSTERING                 \n")
  cat("------------------------------------------------------------------\n")

  set.seed(config$seed)

  # Validate scaled data input
  has_valid_scaled <- !is.null(scaled_data) && (is.data.frame(scaled_data) || is.matrix(scaled_data)) && !is.null(ncol(scaled_data)) && ncol(scaled_data) >= 2
  if (!has_valid_scaled) {
    num_cols <- names(cleaned_df)[sapply(cleaned_df, is.numeric)]
    num_cols <- setdiff(num_cols, c("CustomerID", "Customer_ID", "Cluster_ID"))
    if (length(num_cols) >= 2) {
      scaled_data <- as.data.frame(scale(cleaned_df[, num_cols]))
    } else {
      stop("[ERROR] Clustering requires at least 2 numerical features.")
    }
  }

  n_obs <- nrow(scaled_data)
  k_range <- config$clustering$k_range
  k_range <- k_range[k_range < n_obs] # Ensure k < N
  if (length(k_range) == 0) k_range <- 2:min(4, n_obs - 1)

  k_optimal <- min(config$clustering$k_optimal, max(k_range))
  nstart <- min(config$clustering$nstart, 25)
  max_iter <- config$clustering$max_iter

  cat(sprintf("[CLUSTERING] Evaluating cluster candidates for k in [%d, %d] across %d features...\n",
              min(k_range), max(k_range), ncol(scaled_data)))

  # 1. Elbow Method (WCSS) & Silhouette Width
  wcss_values <- numeric(length(k_range))
  silhouette_values <- numeric(length(k_range))

  dist_sample_size <- min(1500, n_obs)
  sample_idx <- sample(1:n_obs, dist_sample_size)
  sample_dist <- dist(scaled_data[sample_idx, ])

  for (i in seq_along(k_range)) {
    k_curr <- k_range[i]
    set.seed(config$seed)
    km_tmp <- stats::kmeans(scaled_data, centers = k_curr, nstart = nstart, iter.max = max_iter)
    wcss_values[i] <- km_tmp$tot.withinss

    sil_obj <- tryCatch({
      silhouette(km_tmp$cluster[sample_idx], sample_dist)
    }, error = function(e) NULL)

    silhouette_values[i] <- if (!is.null(sil_obj)) mean(sil_obj[, 3]) else 0.0
    cat(sprintf("  - k = %d | WCSS: %10.2f | Avg Silhouette Width: %.4f\n",
                k_curr, wcss_values[i], silhouette_values[i]))
  }

  k_eval_df <- data.frame(
    k = k_range,
    WCSS = round(wcss_values, 2),
    Silhouette_Width = round(silhouette_values, 4)
  )

  tables_dir <- config$paths$tables_dir
  if (!dir.exists(tables_dir)) dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  write_csv(k_eval_df, file.path(tables_dir, "clustering_metrics_k_evaluation.csv"))

  # 2. Fit Final Optimal K-Means Model
  cat(sprintf("\n[CLUSTERING] Fitting final K-Means model with k = %d...\n", k_optimal))
  set.seed(config$seed)
  final_km <- stats::kmeans(scaled_data, centers = k_optimal, nstart = nstart, iter.max = max_iter)

  # 3. Dynamic Business Persona Mapping based on Observed Cluster Centroids
  df_with_clusters <- cleaned_df
  df_with_clusters$Cluster_ID <- final_km$cluster

  # Rank clusters by primary spend / value metric
  spend_col <- intersect(c("Total_Spend_USD", "Purchase_Amount_USD", "Avg_Order_Value_USD"), colnames(df_with_clusters))[1]
  if (is.na(spend_col)) {
    spend_col <- colnames(scaled_data)[1]
  }

  cluster_ranks <- df_with_clusters %>%
    group_by(Cluster_ID) %>%
    summarise(Mean_Val = mean(.data[[spend_col]], na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(Mean_Val))

  default_persona_names <- c(
    "High-Value Loyalists",
    "Active Mid-Tier Regulars",
    "Discount-Driven Shoppers",
    "Low-Frequency At-Risk",
    "Occasional Browsers",
    "New Cohort"
  )

  persona_map <- setNames(
    default_persona_names[1:k_optimal],
    as.character(cluster_ranks$Cluster_ID)
  )

  df_with_clusters$Cluster_Name <- factor(
    persona_map[as.character(df_with_clusters$Cluster_ID)],
    levels = default_persona_names[1:k_optimal]
  )

  # 4. Generate Cluster Profile Summary Table
  cat("[CLUSTERING] Generating cluster profile summaries...\n")
  cluster_summary_list <- list()

  for (cid in unique(df_with_clusters$Cluster_ID)) {
    sub <- df_with_clusters[df_with_clusters$Cluster_ID == cid, ]
    p_name <- as.character(persona_map[as.character(cid)])
    cnt <- nrow(sub)
    pct <- round((cnt / nrow(df_with_clusters)) * 100, 2)

    row_data <- data.frame(
      Cluster_ID = cid,
      Cluster_Name = p_name,
      Customer_Count = cnt,
      Percentage = pct,
      stringsAsFactors = FALSE
    )

    # Add means for clustering features
    for (feat in colnames(scaled_data)) {
      if (feat %in% colnames(sub) && is.numeric(sub[[feat]])) {
        row_data[[paste0("Mean_", feat)]] <- round(mean(sub[[feat]], na.rm = TRUE), 2)
      }
    }

    if ("Repeat_Purchase" %in% colnames(sub)) {
      row_data$Repeat_Rate_Pct <- round(mean(sub$Repeat_Purchase == "Yes") * 100, 2)
    }

    cluster_summary_list[[as.character(cid)]] <- row_data
  }

  cluster_summary <- do.call(rbind, cluster_summary_list)
  cluster_summary <- cluster_summary %>% arrange(desc(Customer_Count))

  # Save Cluster Profiles
  profile_path <- file.path(tables_dir, "cluster_profile_summary.csv")
  write_csv(cluster_summary, profile_path)
  cat(sprintf("[SUCCESS] Saved cluster profiles to '%s'.\n", profile_path))

  # 5. Save Customer-Level Cluster Assignments
  assign_cols <- intersect(c("CustomerID", "Cluster_ID", "Cluster_Name", colnames(scaled_data), "Repeat_Purchase"), colnames(df_with_clusters))
  assign_df <- df_with_clusters[, assign_cols]
  assign_path <- file.path(tables_dir, "customer_cluster_assignments.csv")
  write_csv(assign_df, assign_path)
  cat(sprintf("[SUCCESS] Saved customer cluster assignments to '%s'.\n", assign_path))

  # 6. Save Fitted Model Object
  models_dir <- config$paths$models_dir
  if (!dir.exists(models_dir)) dir.create(models_dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(final_km, file = file.path(models_dir, "kmeans_model.rds"))
  cat(sprintf("[SUCCESS] Saved K-Means model to '%s'.\n", file.path(models_dir, "kmeans_model.rds")))

  return(list(
    kmeans_model = final_km,
    cluster_assignments = assign_df,
    cluster_summary = cluster_summary,
    k_evaluation = k_eval_df,
    df_with_clusters = df_with_clusters,
    scaled_data = scaled_data
  ))
}
