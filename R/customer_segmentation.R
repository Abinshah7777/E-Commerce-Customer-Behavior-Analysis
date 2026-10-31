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

#' Execute K-Means Customer Segmentation Workflow
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
  k_range <- config$clustering$k_range
  k_optimal <- config$clustering$k_optimal
  nstart <- config$clustering$nstart
  max_iter <- config$clustering$max_iter
  
  cat(sprintf("[CLUSTERING] Evaluating cluster candidates for k in [%d, %d]...\n",
              min(k_range), max(k_range)))
  
  # 1. Elbow Method & Silhouette Width Evaluation across k
  wcss_values <- numeric(length(k_range))
  silhouette_values <- numeric(length(k_range))
  
  # Sample for silhouette computation if dataset is large to maintain fast performance
  dist_sample_size <- min(2000, nrow(scaled_data))
  sample_idx <- sample(1:nrow(scaled_data), dist_sample_size)
  sample_dist <- dist(scaled_data[sample_idx, ])
  
  for (i in seq_along(k_range)) {
    k_curr <- k_range[i]
    set.seed(config$seed)
    km_tmp <- stats::kmeans(scaled_data, centers = k_curr, nstart = nstart, iter.max = max_iter)
    wcss_values[i] <- km_tmp$tot.withinss
    
    # Compute average silhouette width
    sil_obj <- silhouette(km_tmp$cluster[sample_idx], sample_dist)
    silhouette_values[i] <- mean(sil_obj[, 3])
    
    cat(sprintf("  - k = %d | WCSS: %10.2f | Avg Silhouette Width: %.4f\n",
                k_curr, wcss_values[i], silhouette_values[i]))
  }
  
  k_eval_df <- data.frame(
    k = k_range,
    WCSS = round(wcss_values, 2),
    Silhouette_Width = round(silhouette_values, 4)
  )
  
  # Save k evaluation metrics
  tables_dir <- config$paths$tables_dir
  if (!dir.exists(tables_dir)) dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  write_csv(k_eval_df, file.path(tables_dir, "clustering_metrics_k_evaluation.csv"))
  
  # 2. Fit Final Optimal K-Means Model
  cat(sprintf("\n[CLUSTERING] Fitting final K-Means model with k = %d (nstart = %d)...\n",
              k_optimal, nstart))
  set.seed(config$seed)
  final_km <- stats::kmeans(scaled_data, centers = k_optimal, nstart = nstart, iter.max = max_iter)
  
  # 3. Dynamic Business Persona Mapping based on Observed Cluster Centroids
  # Inspect centroid characteristics to assign meaningful labels
  cluster_centers_df <- as.data.frame(final_km$centers)
  cluster_centers_df$Cluster_ID <- 1:k_optimal
  
  # Calculate raw unscaled cluster means to interpret personas accurately
  df_with_clusters <- cleaned_df
  df_with_clusters$Cluster_ID <- final_km$cluster
  
  cluster_means <- df_with_clusters %>%
    group_by(Cluster_ID) %>%
    summarise(
      Mean_Spend = mean(Total_Spend_USD),
      Mean_Recency = mean(Recency_Days),
      Mean_Frequency = mean(Total_Purchases),
      Mean_Discount = mean(Discount_Usage_Ratio),
      Count = n(),
      .groups = "drop"
    )
  
  # Identify Personas:
  # - High-Value: Highest Mean_Spend
  # - At-Risk / Lapsed: Highest Mean_Recency
  # - Discount Seekers: Highest Mean_Discount (among remaining)
  # - Active Regulars: Remaining cluster
  high_spend_id <- cluster_means$Cluster_ID[which.max(cluster_means$Mean_Spend)]
  high_recency_id <- cluster_means$Cluster_ID[which.max(cluster_means$Mean_Recency)]
  
  rem_ids <- setdiff(cluster_means$Cluster_ID, c(high_spend_id, high_recency_id))
  discount_sub <- cluster_means %>% filter(Cluster_ID %in% rem_ids)
  discount_id <- discount_sub$Cluster_ID[which.max(discount_sub$Mean_Discount)]
  regular_id <- setdiff(rem_ids, discount_id)
  
  persona_map <- c()
  persona_map[high_spend_id] <- "High-Value Loyalists"
  persona_map[high_recency_id] <- "Low-Frequency At-Risk"
  persona_map[discount_id] <- "Discount-Driven Shoppers"
  persona_map[regular_id] <- "Active Mid-Tier Regulars"
  
  df_with_clusters$Cluster_Name <- factor(persona_map[df_with_clusters$Cluster_ID],
                                          levels = c("High-Value Loyalists",
                                                     "Active Mid-Tier Regulars",
                                                     "Discount-Driven Shoppers",
                                                     "Low-Frequency At-Risk"))
  
  # 4. Generate Comprehensive Cluster Profile Summary Table
  cat("[CLUSTERING] Generating cluster profile summaries...\n")
  cluster_summary <- df_with_clusters %>%
    group_by(Cluster_ID, Cluster_Name) %>%
    summarise(
      Customer_Count = n(),
      Percentage = round((n() / nrow(df_with_clusters)) * 100, 2),
      Mean_Spend_USD = round(mean(Total_Spend_USD), 2),
      Median_Spend_USD = round(median(Total_Spend_USD), 2),
      Mean_Purchases = round(mean(Total_Purchases), 2),
      Mean_AOV_USD = round(mean(Avg_Order_Value_USD), 2),
      Mean_Recency_Days = round(mean(Recency_Days), 2),
      Mean_App_Mins = round(mean(App_Session_Minutes), 2),
      Mean_Web_Visits = round(mean(Website_Visits_Per_Month), 2),
      Mean_Discount_Ratio = round(mean(Discount_Usage_Ratio), 3),
      Loyalty_Member_Pct = round(mean(Loyalty_Program_Member == "Yes") * 100, 2),
      Repeat_Purchase_Rate_Pct = round(mean(Repeat_Purchase == "Yes") * 100, 2),
      .groups = "drop"
    ) %>%
    arrange(desc(Mean_Spend_USD))
  
  # Save Cluster Profiles
  profile_path <- file.path(tables_dir, "cluster_profile_summary.csv")
  write_csv(cluster_summary, profile_path)
  cat(sprintf("[SUCCESS] Saved cluster profiles to '%s'.\n", profile_path))
  
  # 5. Save Customer-Level Cluster Assignments
  assign_df <- df_with_clusters %>%
    select(CustomerID, Cluster_ID, Cluster_Name, Total_Spend_USD, Total_Purchases, Recency_Days, Repeat_Purchase)
  assign_path <- file.path(tables_dir, "customer_cluster_assignments.csv")
  write_csv(assign_df, assign_path)
  cat(sprintf("[SUCCESS] Saved customer cluster assignments to '%s'.\n", assign_path))
  
  # 6. Save Fitted Model Object
  models_dir <- config$paths$models_dir
  if (!dir.exists(models_dir)) dir.create(models_dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(final_km, file = file.path(models_dir, "kmeans_model.rds"))
  cat(sprintf("[SUCCESS] Saved K-Means model object to '%s'.\n", file.path(models_dir, "kmeans_model.rds")))
  
  # Print Console Summary
  cat("\n[CLUSTER PROFILE HIGHLIGHTS]\n")
  for (i in 1:nrow(cluster_summary)) {
    cat(sprintf("  ▶ [%s] %d customers (%.1f%%) | Spend: $%.2f | Orders: %.1f | Recency: %.1fd | Repeat: %.1f%%\n",
                cluster_summary$Cluster_Name[i],
                cluster_summary$Customer_Count[i],
                cluster_summary$Percentage[i],
                cluster_summary$Mean_Spend_USD[i],
                cluster_summary$Mean_Purchases[i],
                cluster_summary$Mean_Recency_Days[i],
                cluster_summary$Repeat_Purchase_Rate_Pct[i]))
  }
  
  return(list(
    model = final_km,
    k_eval = k_eval_df,
    df_with_clusters = df_with_clusters,
    cluster_summary = cluster_summary,
    persona_map = persona_map
  ))
}
