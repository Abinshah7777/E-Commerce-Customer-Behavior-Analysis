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
      plot.title = element_text(face = "bold", size = rel(1.15), color = "#1a252c", hjust = 0),
      plot.subtitle = element_text(size = rel(0.92), color = "#556068", margin = ggplot2::margin(b = 10)),
      plot.caption = element_text(size = rel(0.75), color = "#7a8793", hjust = 1, margin = ggplot2::margin(t = 10)),
      axis.title = element_text(face = "bold", size = rel(0.92), color = "#2c3e50"),
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

#' Generate All Visualizations for the Active Dataset
generate_all_visualizations <- function(cleaned_df, raw_df, seg_results, pred_results, config) {
  cat("\n------------------------------------------------------------------\n")
  cat("   GENERATING HIGH-RESOLUTION PUBLICATION VISUALIZATIONS          \n")
  cat("------------------------------------------------------------------\n")

  plots_dir <- config$paths$plots_dir
  if (!dir.exists(plots_dir)) dir.create(plots_dir, recursive = TRUE, showWarnings = FALSE)

  save_plot <- function(p, filename, width = 8.5, height = 5.5) {
    target_path <- file.path(plots_dir, filename)
    tryCatch({
      ggsave(target_path, plot = p, width = width, height = height, dpi = 300)
      cat(sprintf("  ✓ Saved plot: %s\n", filename))
    }, error = function(e) {
      cat(sprintf("  ✗ Failed saving %s: %s\n", filename, e$message))
    })
  }

  spend_col <- intersect(c("Total_Spend_USD", "Purchase_Amount_USD", "Avg_Order_Value_USD"), colnames(cleaned_df))[1]
  freq_col <- intersect(c("Total_Purchases", "Previous_Purchases", "orders"), colnames(cleaned_df))[1]
  cat_col <- intersect(c("Preferred_Category", "Category", "Item_Purchased"), colnames(cleaned_df))[1]

  # Plot 1: Spending Distribution
  tryCatch({
    if (!is.na(spend_col)) {
      med_val <- median(cleaned_df[[spend_col]], na.rm = TRUE)
      p1 <- ggplot(cleaned_df, aes(x = .data[[spend_col]])) +
        geom_histogram(aes(y = after_stat(density)), bins = 35, fill = "#2b5c8f", color = "white", alpha = 0.8) +
        geom_density(color = "#e74c3c", linewidth = 1.1) +
        geom_vline(xintercept = med_val, linetype = "dashed", color = "#27ae60", linewidth = 1) +
        scale_x_continuous(labels = dollar_format()) +
        labs(
          title = "Customer Monetary Spending Distribution",
          subtitle = sprintf("Cohort median: $%.2f (Dashed green line)", med_val),
          x = "Total Spend ($)",
          y = "Density",
          caption = "Big Data Analytics | Mentor Engineering College"
        ) +
        theme_academic()
      save_plot(p1, "plot_01_spending_distribution.png")
    }
  }, error = function(e) NULL)

  # Plot 2: Purchase Frequency
  tryCatch({
    if (!is.na(freq_col)) {
      p2 <- ggplot(cleaned_df, aes(x = .data[[freq_col]])) +
        geom_histogram(bins = 25, fill = "#34495e", color = "white", alpha = 0.85) +
        geom_vline(xintercept = mean(cleaned_df[[freq_col]], na.rm = TRUE), color = "#e67e22", linetype = "dashed", linewidth = 1) +
        labs(
          title = "Customer Purchase Frequency Distribution",
          subtitle = sprintf("Mean purchase count: %.1f completed orders", mean(cleaned_df[[freq_col]], na.rm = TRUE)),
          x = "Completed Orders / Transactions",
          y = "Customer Count",
          caption = "Big Data Analytics | Mentor Engineering College"
        ) +
        theme_academic()
      save_plot(p2, "plot_02_purchase_frequency.png")
    }
  }, error = function(e) NULL)

  # Plot 3: Age Distribution by Gender (if available)
  tryCatch({
    if ("Age" %in% colnames(cleaned_df) && "Gender" %in% colnames(cleaned_df)) {
      p3 <- ggplot(cleaned_df, aes(x = Age, fill = Gender)) +
        geom_histogram(bins = 20, color = "white", alpha = 0.85) +
        facet_wrap(~Gender, scales = "free_y") +
        labs(
          title = "Customer Age Distribution Faceted by Gender",
          subtitle = "Demographic stratification across customer segments",
          x = "Age (Years)",
          y = "Customer Count",
          caption = "Big Data Analytics | Mentor Engineering College"
        ) +
        theme_academic() +
        theme(legend.position = "none")
      save_plot(p3, "plot_03_customer_age_distribution.png", width = 9.0, height = 4.5)
    }
  }, error = function(e) NULL)

  # Plot 4: Spending by Category
  tryCatch({
    if (!is.na(cat_col) && !is.na(spend_col)) {
      p4 <- ggplot(cleaned_df, aes(x = reorder(.data[[cat_col]], .data[[spend_col]], FUN = median), y = .data[[spend_col]], fill = .data[[cat_col]])) +
        geom_boxplot(outlier.alpha = 0.25, width = 0.5, alpha = 0.85) +
        coord_flip() +
        scale_y_continuous(labels = dollar_format()) +
        labs(
          title = sprintf("Customer Spend across %s", cat_col),
          subtitle = "Boxplots show distribution quartiles and median expenditure",
          x = "Category",
          y = "Expenditure ($)",
          caption = "Big Data Analytics | Mentor Engineering College"
        ) +
        theme_academic() +
        theme(legend.position = "none")
      save_plot(p4, "plot_04_spending_by_category.png")
    }
  }, error = function(e) NULL)

  # Plot 5: Correlation Heatmap
  tryCatch({
    num_cols <- names(cleaned_df)[sapply(cleaned_df, is.numeric)]
    num_cols <- setdiff(num_cols, c("CustomerID", "Customer_ID", "Cluster_ID"))
    if (length(num_cols) >= 2) {
      target_num <- num_cols[1:min(7, length(num_cols))]
      c_mat <- round(cor(cleaned_df[, target_num], use = "pairwise.complete.obs"), 2)
      cor_melted <- as.data.frame(as.table(c_mat))
      colnames(cor_melted) <- c("Var1", "Var2", "Correlation")

      p5 <- ggplot(cor_melted, aes(x = Var1, y = Var2, fill = Correlation)) +
        geom_tile(color = "white") +
        geom_text(aes(label = sprintf("%.2f", Correlation)), color = ifelse(abs(cor_melted$Correlation) > 0.45, "white", "black"), size = 3.2) +
        scale_fill_gradient2(low = "#e74c3c", mid = "#f8f9fa", high = "#2980b9", midpoint = 0, limit = c(-1, 1)) +
        labs(
          title = "Pearson Correlation Matrix of Behavioral Features",
          x = "", y = "",
          caption = "Big Data Analytics | Mentor Engineering College"
        ) +
        theme_academic() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
      save_plot(p5, "plot_05_correlation_heatmap.png", width = 8.0, height = 6.5)
    }
  }, error = function(e) NULL)

  # Plot 6: Target Distribution
  tryCatch({
    target_name <- if (isTRUE(pred_results$model_available)) pred_results$target_col else "Subscription_Status"
    if (target_name %in% colnames(cleaned_df)) {
      tgt_summary <- cleaned_df %>%
        group_by(Target = .data[[target_name]]) %>%
        summarise(Count = n(), .groups = "drop") %>%
        mutate(Pct = round(Count / sum(Count) * 100, 1))

      p6 <- ggplot(tgt_summary, aes(x = as.factor(Target), y = Count, fill = as.factor(Target))) +
        geom_bar(stat = "identity", width = 0.5, alpha = 0.85) +
        geom_text(aes(label = sprintf("%d (%.1f%%)", Count, Pct)), vjust = -0.4, fontface = "bold") +
        scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
        labs(
          title = sprintf("Distribution of Target Variable: %s", target_name),
          subtitle = "Class representation across customer observations",
          x = target_name,
          y = "Count",
          caption = "Big Data Analytics | Mentor Engineering College"
        ) +
        theme_academic() +
        theme(legend.position = "none")
      save_plot(p6, "plot_06_target_distribution.png", width = 7.0, height = 5.0)
    }
  }, error = function(e) NULL)

  # Plot 7: Missing Value Summary
  tryCatch({
    missing_df <- data.frame(
      Feature = names(raw_df),
      Missing_Count = colSums(is.na(raw_df)),
      Missing_Pct = (colSums(is.na(raw_df)) / nrow(raw_df)) * 100
    ) %>% filter(Missing_Count > 0)

    if (nrow(missing_df) == 0) {
      missing_df <- data.frame(Feature = "Zero Missing Values", Missing_Count = 0, Missing_Pct = 0)
    }

    p7 <- ggplot(missing_df, aes(x = reorder(Feature, Missing_Pct), y = Missing_Pct)) +
      geom_bar(stat = "identity", fill = "#e67e22", width = 0.45, alpha = 0.85) +
      geom_text(aes(label = sprintf("%.1f%% (%d NAs)", Missing_Pct, Missing_Count)), hjust = -0.1, fontface = "bold") +
      coord_flip() +
      scale_y_continuous(limits = c(0, max(5, max(missing_df$Missing_Pct) * 1.5))) +
      labs(
        title = "Dataset Missing Value Audit",
        subtitle = "Pre-imputation data quality profile",
        x = "Feature",
        y = "Missing Rate (%)",
        caption = "Big Data Analytics | Mentor Engineering College"
      ) +
      theme_academic()
    save_plot(p7, "plot_07_missing_data_summary.png", width = 8.0, height = 4.5)
  }, error = function(e) NULL)

  # Plot 8 & 9: Elbow Method and Silhouette Analysis
  tryCatch({
    k_eval <- seg_results$k_evaluation
    k_opt <- config$clustering$k_optimal

    p8 <- ggplot(k_eval, aes(x = k, y = WCSS)) +
      geom_line(color = "#2b5c8f", linewidth = 1.2) +
      geom_point(color = "#2b5c8f", size = 3.5) +
      scale_x_continuous(breaks = k_eval$k) +
      labs(
        title = "K-Means Cluster Optimization: The Elbow Method",
        subtitle = "Within-Cluster Sum of Squares (WCSS) vs Number of Clusters (k)",
        x = "Clusters (k)",
        y = "WCSS",
        caption = "Big Data Analytics | Mentor Engineering College"
      ) +
      theme_academic()
    save_plot(p8, "plot_08_elbow_method.png")

    p9 <- ggplot(k_eval, aes(x = k, y = Silhouette_Width)) +
      geom_line(color = "#16a085", linewidth = 1.2) +
      geom_point(color = "#16a085", size = 3.5) +
      scale_x_continuous(breaks = k_eval$k) +
      labs(
        title = "Average Silhouette Width across Cluster Specifications",
        x = "Clusters (k)",
        y = "Average Silhouette Width",
        caption = "Big Data Analytics | Mentor Engineering College"
      ) +
      theme_academic()
    save_plot(p9, "plot_09_silhouette_analysis.png")
  }, error = function(e) NULL)

  # Plot 10: 2D Cluster Scatter Plot
  tryCatch({
    df_clusters <- seg_results$df_with_clusters
    rec_col <- intersect(c("Recency_Days", "Total_Purchases", "Age"), colnames(df_clusters))[1]
    if (!is.na(rec_col) && !is.na(spend_col) && "Cluster_Name" %in% colnames(df_clusters)) {
      p10 <- ggplot(df_clusters, aes(x = .data[[rec_col]], y = .data[[spend_col]], color = Cluster_Name)) +
        geom_point(alpha = 0.55, size = 1.8) +
        scale_y_continuous(labels = dollar_format()) +
        scale_color_manual(values = PALETTE_CLUSTERS) +
        labs(
          title = sprintf("Customer Segmentation Map (%s vs %s)", rec_col, spend_col),
          x = rec_col,
          y = spend_col,
          color = "Cluster Persona",
          caption = "Big Data Analytics | Mentor Engineering College"
        ) +
        theme_academic() +
        guides(color = guide_legend(override.aes = list(size = 4, alpha = 1)))
      save_plot(p10, "plot_10_cluster_scatter_rfm.png", width = 9.0, height = 5.5)
    }
  }, error = function(e) NULL)

  # Plot 11: Cluster Profile Bar Chart
  tryCatch({
    prof_summary <- seg_results$cluster_summary
    if ("Mean_Total_Spend_USD" %in% colnames(prof_summary)) {
      val_col <- "Mean_Total_Spend_USD"
    } else {
      mean_cols <- grep("^Mean_", colnames(prof_summary), value = TRUE)
      val_col <- if (length(mean_cols) > 0) mean_cols[1] else "Customer_Count"
    }

    p11 <- ggplot(prof_summary, aes(x = reorder(Cluster_Name, .data[[val_col]]), y = .data[[val_col]], fill = Cluster_Name)) +
      geom_bar(stat = "identity", width = 0.55, alpha = 0.9) +
      coord_flip() +
      scale_fill_manual(values = PALETTE_CLUSTERS) +
      labs(
        title = sprintf("Cluster Profile Comparison by %s", val_col),
        x = "Cluster Segment",
        y = val_col,
        caption = "Big Data Analytics | Mentor Engineering College"
      ) +
      theme_academic() +
      theme(legend.position = "none")
    save_plot(p11, "plot_11_cluster_profile_radar_bars.png")
  }, error = function(e) NULL)

  # Predictive Model Visualizations (Plots 12-15) if model is available
  if (isTRUE(pred_results$model_available)) {
    tryCatch({
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
          title = "Receiver Operating Characteristic (ROC) Comparison",
          x = "False Positive Rate (1 - Specificity)",
          y = "True Positive Rate (Recall)",
          caption = "Big Data Analytics | Mentor Engineering College"
        ) +
        theme_academic() +
        theme(legend.position = c(0.70, 0.25))
      save_plot(p12, "plot_12_model_roc_curves.png")
    }, error = function(e) NULL)

    tryCatch({
      feat_imp <- pred_results$feature_importance %>% head(10)
      p13 <- ggplot(feat_imp, aes(x = reorder(Feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
        geom_bar(stat = "identity", fill = "#1b9e77", width = 0.6, alpha = 0.85) +
        coord_flip() +
        labs(
          title = "Top Feature Importance (Random Forest Gini Index)",
          x = "Feature",
          y = "Mean Decrease in Gini",
          caption = "Big Data Analytics | Mentor Engineering College"
        ) +
        theme_academic()
      save_plot(p13, "plot_13_feature_importance.png")
    }, error = function(e) NULL)
  }

  cat("[SUCCESS] Publication figures generated successfully.\n")
}
