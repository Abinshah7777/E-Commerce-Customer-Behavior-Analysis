# ==============================================================================
# VISUALIZATION MODULE: R/visualization.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# ==============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(scales)
  library(dplyr)
  library(tidyr)
})

#' Academic Presentation Theme for ggplot2 Visualizations
theme_academic <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = rel(1.2), color = "#1a252c", hjust = 0),
      plot.subtitle = element_text(size = rel(0.95), color = "#556068", margin = ggplot2::margin(b = 10)),
      plot.caption = element_text(size = rel(0.75), color = "#7a8793", hjust = 1, margin = ggplot2::margin(t = 10)),
      axis.title = element_text(face = "bold", size = rel(0.95), color = "#2c3e50"),
      axis.text = element_text(size = rel(0.85), color = "#34495e"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "#e9ecef", linewidth = 0.5),
      panel.border = element_rect(color = "#cfd8dc", fill = NA, linewidth = 0.6),
      legend.position = "right",
      legend.title = element_text(face = "bold", size = rel(0.9)),
      legend.background = element_rect(fill = alpha("white", 0.8), color = NA),
      strip.background = element_rect(fill = "#eef2f5", color = "#cfd8dc"),
      strip.text = element_text(face = "bold", color = "#2c3e50")
    )
}

# Curated Academic Color Palettes
PALETTE_CLUSTERS <- c(
  "High-Value Loyalists" = "#1b9e77",
  "Active Mid-Tier Regulars" = "#2b5c8f",
  "Discount-Driven Shoppers" = "#e6ab02",
  "Low-Frequency At-Risk" = "#d95f02"
)

PALETTE_MODELS <- c(
  "Logistic Regression" = "#2b5c8f",
  "Random Forest" = "#1b9e77"
)

#' Generate All Core Visualizations for the Pipeline
#'
#' @param cleaned_df Cleaned customer dataset
#' @param raw_df Raw customer dataset (for missingness/audit plot)
#' @param seg_results Output list from perform_customer_segmentation
#' @param pred_results Output list from train_and_evaluate_models
#' @param config Project configuration list
generate_all_visualizations <- function(cleaned_df, raw_df, seg_results, pred_results, config) {
  cat("\n------------------------------------------------------------------\n")
  cat("   GENERATING HIGH-RESOLUTION PUBLICATION VISUALIZATIONS          \n")
  cat("------------------------------------------------------------------\n")
  
  plots_dir <- config$paths$plots_dir
  if (!dir.exists(plots_dir)) dir.create(plots_dir, recursive = TRUE, showWarnings = FALSE)
  
  save_plot <- function(p, filename, width = 8.5, height = 5.5) {
    target_path <- file.path(plots_dir, filename)
    ggsave(target_path, plot = p, width = width, height = height, dpi = 300)
    cat(sprintf("  ✓ Saved plot: %s\n", filename))
  }
  
  # ----------------------------------------------------------------------------
  # Plot 1: Spending Distribution
  # ----------------------------------------------------------------------------
  p1 <- ggplot(cleaned_df, aes(x = Total_Spend_USD)) +
    geom_histogram(aes(y = after_stat(density)), bins = 40, fill = "#2b5c8f", color = "white", alpha = 0.8) +
    geom_density(color = "#e74c3c", linewidth = 1.1) +
    geom_vline(xintercept = median(cleaned_df$Total_Spend_USD), linetype = "dashed", color = "#27ae60", linewidth = 1) +
    annotate("text", x = median(cleaned_df$Total_Spend_USD) * 1.5, y = 0.0004,
             label = sprintf("Median: $%.2f", median(cleaned_df$Total_Spend_USD)), color = "#27ae60", fontface = "bold") +
    scale_x_continuous(labels = dollar_format()) +
    labs(
      title = "Distribution of Lifetime Customer Spending (USD)",
      subtitle = "Right-skewed monetary expenditure exhibiting heavy-tailed VIP customer dynamics",
      x = "Total Lifetime Spend ($)",
      y = "Density",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic()
  save_plot(p1, "plot_01_spending_distribution.png")
  
  # ----------------------------------------------------------------------------
  # Plot 2: Purchase Frequency Distribution
  # ----------------------------------------------------------------------------
  p2 <- ggplot(cleaned_df, aes(x = Total_Purchases)) +
    geom_histogram(binwidth = 2, fill = "#34495e", color = "white", alpha = 0.85) +
    geom_vline(xintercept = mean(cleaned_df$Total_Purchases), color = "#e67e22", linetype = "dashed", linewidth = 1) +
    annotate("text", x = mean(cleaned_df$Total_Purchases) + 6, y = 350,
             label = sprintf("Mean: %.1f Orders", mean(cleaned_df$Total_Purchases)), color = "#e67e22", fontface = "bold") +
    labs(
      title = "Customer Lifetime Purchase Frequency",
      subtitle = "Frequency distribution indicating recurring purchase cadence across user cohorts",
      x = "Total Completed Orders (Lifetime)",
      y = "Customer Count",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic()
  save_plot(p2, "plot_02_purchase_frequency.png")
  
  # ----------------------------------------------------------------------------
  # Plot 3: Customer Age Distribution Faceted by Gender
  # ----------------------------------------------------------------------------
  p3 <- ggplot(cleaned_df, aes(x = Age, fill = Gender)) +
    geom_histogram(bins = 25, color = "white", alpha = 0.85) +
    facet_wrap(~Gender, scales = "free_y") +
    scale_fill_manual(values = c("Female" = "#9b59b6", "Male" = "#3498db", "Other" = "#1abc9c")) +
    labs(
      title = "Customer Age Demographics by Gender Identity",
      subtitle = "Stratified age distributions across customer demographic segments",
      x = "Age (Years)",
      y = "Count",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic() +
    theme(legend.position = "none")
  save_plot(p3, "plot_03_customer_age_distribution.png", width = 9.5, height = 4.5)
  
  # ----------------------------------------------------------------------------
  # Plot 4: Spending by Product Category
  # ----------------------------------------------------------------------------
  p4 <- ggplot(cleaned_df, aes(x = reorder(Preferred_Category, Total_Spend_USD, FUN = median), y = Total_Spend_USD, fill = Preferred_Category)) +
    geom_boxplot(outlier.alpha = 0.25, width = 0.5, alpha = 0.85) +
    stat_summary(fun = mean, geom = "point", shape = 18, size = 3, color = "#c0392b") +
    coord_flip() +
    scale_y_continuous(labels = dollar_format()) +
    scale_fill_brewer(palette = "Set2") +
    labs(
      title = "Customer Lifetime Spend across Preferred Product Categories",
      subtitle = "Diamonds represent category means; vertical lines depict median and interquartile range",
      x = "Product Category",
      y = "Total Spend ($)",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic() +
    theme(legend.position = "none")
  save_plot(p4, "plot_04_spending_by_category.png")
  
  # ----------------------------------------------------------------------------
  # Plot 5: Correlation Heatmap
  # ----------------------------------------------------------------------------
  num_cols <- c("Age", "Annual_Income_USD", "Total_Purchases", "Total_Spend_USD",
                "Avg_Order_Value_USD", "Recency_Days", "App_Session_Minutes", "Discount_Usage_Ratio")
  c_mat <- cor(cleaned_df[, num_cols], use = "pairwise.complete.obs")
  cor_melted <- as.data.frame(as.table(c_mat))
  colnames(cor_melted) <- c("Var1", "Var2", "Correlation")
  
  p5 <- ggplot(cor_melted, aes(x = Var1, y = Var2, fill = Correlation)) +
    geom_tile(color = "white") +
    geom_text(aes(label = sprintf("%.2f", Correlation)), color = ifelse(abs(cor_melted$Correlation) > 0.45, "white", "black"), size = 3.2) +
    scale_fill_gradient2(low = "#e74c3c", mid = "#f8f9fa", high = "#2980b9", midpoint = 0, limit = c(-1, 1)) +
    labs(
      title = "Pearson Correlation Matrix of Behavioral & Financial Metrics",
      subtitle = "Inter-variable dependency heatmap demonstrating spend-frequency-recency relationships",
      x = "", y = "",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  save_plot(p5, "plot_05_correlation_heatmap.png", width = 8.5, height = 7.0)
  
  # ----------------------------------------------------------------------------
  # Plot 6: Repeat Purchase Target Distribution
  # ----------------------------------------------------------------------------
  target_summary <- cleaned_df %>%
    group_by(Repeat_Purchase) %>%
    summarise(Count = n(), .groups = "drop") %>%
    mutate(Pct = Count / sum(Count) * 100)
  
  p6 <- ggplot(target_summary, aes(x = Repeat_Purchase, y = Count, fill = Repeat_Purchase)) +
    geom_bar(stat = "identity", width = 0.5, alpha = 0.85) +
    geom_text(aes(label = sprintf("%d (%.1f%%)", Count, Pct)), vjust = -0.4, fontface = "bold", size = 4.2) +
    scale_fill_manual(values = c("No" = "#e74c3c", "Yes" = "#27ae60")) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(
      title = "Distribution of Target Variable: Repeat Purchase in 30-Day Window",
      subtitle = "Defensible, leak-free classification target derived from customer engagement and history",
      x = "Made Repeat Purchase (Next 30 Days)",
      y = "Number of Customers",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic() +
    theme(legend.position = "none")
  save_plot(p6, "plot_06_target_distribution.png", width = 7.0, height = 5.0)
  
  # ----------------------------------------------------------------------------
  # Plot 7: Missing Value Analysis (Raw Data Audit)
  # ----------------------------------------------------------------------------
  missing_df <- data.frame(
    Feature = names(raw_df),
    Missing_Count = colSums(is.na(raw_df)),
    Missing_Pct = (colSums(is.na(raw_df)) / nrow(raw_df)) * 100
  ) %>% filter(Missing_Count > 0)
  
  if (nrow(missing_df) == 0) {
    missing_df <- data.frame(Feature = "None", Missing_Count = 0, Missing_Pct = 0)
  }
  
  p7 <- ggplot(missing_df, aes(x = reorder(Feature, Missing_Pct), y = Missing_Pct)) +
    geom_bar(stat = "identity", fill = "#e67e22", width = 0.45, alpha = 0.85) +
    geom_text(aes(label = sprintf("%.2f%% (%d NAs)", Missing_Pct, Missing_Count)), hjust = -0.1, fontface = "bold") +
    coord_flip() +
    scale_y_continuous(limits = c(0, max(5, max(missing_df$Missing_Pct) * 1.5))) +
    labs(
      title = "Raw Data Missingness Audit (Prior to Imputation)",
      subtitle = "Identification of incomplete fields successfully addressed via median imputation",
      x = "Feature",
      y = "Missing Rate (%)",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic()
  save_plot(p7, "plot_07_missing_data_summary.png", width = 8.0, height = 4.5)
  
  # ----------------------------------------------------------------------------
  # Plot 8: Elbow Method (WCSS vs k)
  # ----------------------------------------------------------------------------
  k_eval <- seg_results$k_eval
  k_opt <- config$clustering$k_optimal
  p8 <- ggplot(k_eval, aes(x = k, y = WCSS)) +
    geom_line(color = "#2b5c8f", linewidth = 1.2) +
    geom_point(color = "#2b5c8f", size = 3.5) +
    geom_point(data = k_eval %>% filter(k == k_opt), aes(x = k, y = WCSS), color = "#e74c3c", size = 5.5, shape = 21, fill = "#e74c3c") +
    geom_vline(xintercept = k_opt, linetype = "dashed", color = "#e74c3c", linewidth = 0.8) +
    annotate("text", x = k_opt + 0.6, y = k_eval$WCSS[k_eval$k == k_opt] * 1.15,
             label = sprintf("Optimal Elbow\nk = %d", k_opt), color = "#e74c3c", fontface = "bold") +
    scale_x_continuous(breaks = k_eval$k) +
    labs(
      title = "K-Means Cluster Optimization: The Elbow Method",
      subtitle = "Within-Cluster Sum of Squares (WCSS) vs candidate number of clusters (k)",
      x = "Number of Clusters (k)",
      y = "Total Within-Cluster Sum of Squares (WCSS)",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic()
  save_plot(p8, "plot_08_elbow_method.png")
  
  # ----------------------------------------------------------------------------
  # Plot 9: Silhouette Analysis
  # ----------------------------------------------------------------------------
  p9 <- ggplot(k_eval, aes(x = k, y = Silhouette_Width)) +
    geom_line(color = "#16a085", linewidth = 1.2) +
    geom_point(color = "#16a085", size = 3.5) +
    geom_point(data = k_eval %>% filter(k == k_opt), aes(x = k, y = Silhouette_Width), color = "#c0392b", size = 5.5) +
    scale_x_continuous(breaks = k_eval$k) +
    labs(
      title = "Average Silhouette Width across Cluster Counts",
      subtitle = "Validation of cluster cohesion and separation across varying k specifications",
      x = "Number of Clusters (k)",
      y = "Average Silhouette Width",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic()
  save_plot(p9, "plot_09_silhouette_analysis.png")
  
  # ----------------------------------------------------------------------------
  # Plot 10: 2D Cluster Scatter Plot (Recency vs Total Spend)
  # ----------------------------------------------------------------------------
  df_clusters <- seg_results$df_with_clusters
  p10 <- ggplot(df_clusters, aes(x = Recency_Days, y = Total_Spend_USD, color = Cluster_Name)) +
    geom_point(alpha = 0.55, size = 1.8) +
    scale_y_continuous(labels = dollar_format()) +
    scale_color_manual(values = PALETTE_CLUSTERS) +
    labs(
      title = "Customer Segmentation Map: Recency vs Lifetime Monetary Spend",
      subtitle = "Four distinct behavioral personas uncovered via K-Means clustering",
      x = "Recency (Days Since Last Purchase)",
      y = "Total Lifetime Spend ($)",
      color = "Customer Segment",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic() +
    guides(color = guide_legend(override.aes = list(size = 4, alpha = 1)))
  save_plot(p10, "plot_10_cluster_scatter_rfm.png", width = 9.5, height = 6.0)
  
  # ----------------------------------------------------------------------------
  # Plot 11: Cluster Profile Bar Comparison
  # ----------------------------------------------------------------------------
  prof_summary <- seg_results$cluster_summary
  p11 <- ggplot(prof_summary, aes(x = reorder(Cluster_Name, Mean_Spend_USD), y = Mean_Spend_USD, fill = Cluster_Name)) +
    geom_bar(stat = "identity", width = 0.55, alpha = 0.9) +
    geom_text(aes(label = sprintf("$%.2f\n(%.1f%%)", Mean_Spend_USD, Percentage)), vjust = -0.3, size = 3.5, fontface = "bold") +
    scale_fill_manual(values = PALETTE_CLUSTERS) +
    scale_y_continuous(labels = dollar_format(), expand = expansion(mult = c(0, 0.2))) +
    labs(
      title = "Mean Customer Lifetime Spend by Segment Persona",
      subtitle = "Substantial commercial divergence between high-value loyalists and lapsed cohorts",
      x = "Customer Segment",
      y = "Mean Lifetime Spend ($)",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic() +
    theme(legend.position = "none")
  save_plot(p11, "plot_11_cluster_profile_radar_bars.png")
  
  # ----------------------------------------------------------------------------
  # Plot 12: ROC Curves Comparison (Logistic Regression vs Random Forest)
  # ----------------------------------------------------------------------------
  roc_glm <- pred_results$glm_metrics$roc_curve
  roc_rf <- pred_results$rf_metrics$roc_curve
  
  roc_df <- rbind(
    data.frame(FPR = roc_glm$fpr, TPR = roc_glm$tpr, Model = sprintf("Logistic Regression (AUC = %.3f)", pred_results$glm_metrics$auc)),
    data.frame(FPR = roc_rf$fpr, TPR = roc_rf$tpr, Model = sprintf("Random Forest (AUC = %.3f)", pred_results$rf_metrics$auc))
  )
  
  p12 <- ggplot(roc_df, aes(x = FPR, y = TPR, color = Model)) +
    geom_line(linewidth = 1.3) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "#7f8c8d") +
    scale_color_manual(values = c("#2b5c8f", "#1b9e77")) +
    labs(
      title = "Receiver Operating Characteristic (ROC) Curve Comparison",
      subtitle = "Out-of-sample discriminatory power on holdout test partition",
      x = "False Positive Rate (1 - Specificity)",
      y = "True Positive Rate (Sensitivity / Recall)",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic() +
    theme(legend.position = c(0.70, 0.25))
  save_plot(p12, "plot_12_model_roc_curves.png")
  
  # ----------------------------------------------------------------------------
  # Plot 13: Feature Importance (Random Forest Gini)
  # ----------------------------------------------------------------------------
  feat_imp <- pred_results$feature_importance %>% head(10)
  p13 <- ggplot(feat_imp, aes(x = reorder(Feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
    geom_bar(stat = "identity", fill = "#1b9e77", width = 0.6, alpha = 0.85) +
    coord_flip() +
    labs(
      title = "Top 10 Predictors of Customer Repeat Purchase Propensity",
      subtitle = "Random Forest Mean Decrease in Impurity (Gini Importance Index)",
      x = "Feature",
      y = "Mean Decrease in Gini",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic()
  save_plot(p13, "plot_13_feature_importance.png")
  
  # ----------------------------------------------------------------------------
  # Plot 14: Confusion Matrix Heatmaps
  # ----------------------------------------------------------------------------
  conf_df <- data.frame(
    Model = rep(c("Logistic Regression", "Random Forest"), each = 4),
    Actual = factor(rep(c("No", "No", "Yes", "Yes"), times = 2), levels = c("Yes", "No")),
    Predicted = factor(rep(c("No", "Yes", "No", "Yes"), times = 2), levels = c("No", "Yes")),
    Count = c(
      pred_results$glm_metrics$tn, pred_results$glm_metrics$fp, pred_results$glm_metrics$fn, pred_results$glm_metrics$tp,
      pred_results$rf_metrics$tn, pred_results$rf_metrics$fp, pred_results$rf_metrics$fn, pred_results$rf_metrics$tp
    )
  )
  
  p14 <- ggplot(conf_df, aes(x = Predicted, y = Actual, fill = Count)) +
    geom_tile(color = "white", linewidth = 1.5) +
    geom_text(aes(label = Count), fontface = "bold", size = 5.5, color = "white") +
    facet_wrap(~Model) +
    scale_fill_gradient(low = "#3498db", high = "#1a365d") +
    labs(
      title = "Test-Set Confusion Matrices: Classification Performance",
      subtitle = "Comparison of True/False Positives and Negatives at 0.50 decision threshold",
      x = "Model Predicted Class",
      y = "True Observed Class",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic() +
    theme(legend.position = "none")
  save_plot(p14, "plot_14_confusion_matrices.png", width = 8.5, height = 4.5)
  
  # ----------------------------------------------------------------------------
  # Plot 15: Predicted Probability Distribution by Actual Class
  # ----------------------------------------------------------------------------
  test_preds <- pred_results$test_predictions
  p15 <- ggplot(test_preds, aes(x = RF_Predicted_Prob, fill = Actual_Repeat)) +
    geom_density(alpha = 0.6) +
    geom_vline(xintercept = 0.50, linetype = "dashed", color = "#e74c3c", linewidth = 1) +
    scale_fill_manual(values = c("No" = "#e74c3c", "Yes" = "#27ae60")) +
    annotate("text", x = 0.52, y = 3.2, label = "Threshold: 0.50", color = "#e74c3c", hjust = 0, fontface = "bold") +
    labs(
      title = "Distribution of Random Forest Predicted Probabilities by True Class",
      subtitle = "Separation quality between actual repeat purchasers and non-repeat purchasers",
      x = "Predicted Probability of Repeat Purchase",
      y = "Density",
      fill = "Actual Repeat",
      caption = "Big Data Analytics | Mentor Engineering College"
    ) +
    theme_academic() +
    theme(legend.position = "top")
  save_plot(p15, "plot_15_predicted_probabilities.png")
  
  cat(sprintf("[SUCCESS] All 15 figures successfully generated and saved to '%s'.\n", plots_dir))
}
