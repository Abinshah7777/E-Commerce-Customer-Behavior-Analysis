# ==============================================================================
# BUSINESS INSIGHTS & RECOMMENDATIONS MODULE: R/business_insights.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

#' Synthesize Empirical Findings into Strategic Business Recommendations
#'
#' @param seg_results Output list from perform_customer_segmentation
#' @param pred_results Output list from train_and_evaluate_models
#' @param config Project configuration list
#' @return A data frame of structured business recommendations
generate_business_recommendations <- function(seg_results, pred_results, config) {
  cat("\n------------------------------------------------------------------\n")
  cat("   BUSINESS INSIGHTS & STRATEGIC RECOMMENDATIONS                 \n")
  cat("------------------------------------------------------------------\n")
  
  cluster_df <- seg_results$cluster_summary
  rf_auc <- pred_results$rf_metrics$auc
  rf_f1 <- pred_results$rf_metrics$f1_score
  
  # Identify Key Empirical Statistics
  vip_row <- cluster_df %>% filter(Cluster_Name == "High-Value Loyalists")
  at_risk_row <- cluster_df %>% filter(Cluster_Name == "Low-Frequency At-Risk")
  disc_row <- cluster_df %>% filter(Cluster_Name == "Discount-Driven Shoppers")
  reg_row <- cluster_df %>% filter(Cluster_Name == "Active Mid-Tier Regulars")
  
  top_feature <- pred_results$feature_importance$Feature[1]
  second_feature <- pred_results$feature_importance$Feature[2]
  
  recommendations <- list(
    data.frame(
      Recommendation_ID = "REC-01",
      Strategic_Pillar = "VIP Retention & Lifetime Value Maximization",
      Target_Audience = "High-Value Loyalists",
      Empirical_Observation = sprintf("Represents %.1f%% of customers but generates an average spend of $%.2f (over %.1fx higher than the general customer base) with %.1f%% repeat purchase propensity.",
                                      vip_row$Percentage, vip_row$Mean_Spend_USD, vip_row$Mean_Spend_USD / mean(cluster_df$Mean_Spend_USD), vip_row$Repeat_Purchase_Rate_Pct),
      Supporting_Metric = sprintf("Mean Spend: $%.2f | Mean Orders: %.1f | Loyalty Member Rate: %.1f%%",
                                  vip_row$Mean_Spend_USD, vip_row$Mean_Purchases, vip_row$Loyalty_Member_Pct),
      Proposed_Business_Action = "Implement dedicated concierge account management, exclusive early-access product drops, invite-only tiered rewards, and zero-friction customer support.",
      Expected_Business_Benefit = "Reduces premium customer churn by 15-25% and expands customer lifetime value through high-margin upsells and cross-category discovery.",
      Risk_or_Limitation = "Over-discounting this segment can erode premium brand perception and compress product margins unnecessarily.",
      stringsAsFactors = FALSE
    ),
    data.frame(
      Recommendation_ID = "REC-02",
      Strategic_Pillar = "Churn Prevention & Win-Back Automation",
      Target_Audience = "Low-Frequency At-Risk Customers",
      Empirical_Observation = sprintf("Represents %.1f%% of customers exhibiting an alarming average recency of %.1f days and a depressed repeat purchase rate of only %.1f%%.",
                                      at_risk_row$Percentage, at_risk_row$Mean_Recency_Days, at_risk_row$Repeat_Purchase_Rate_Pct),
      Supporting_Metric = sprintf("Mean Recency: %.1f days | Mean Orders: %.1f | Repeat Purchase: %.1f%%",
                                  at_risk_row$Mean_Recency_Days, at_risk_row$Mean_Purchases, at_risk_row$Repeat_Purchase_Rate_Pct),
      Proposed_Business_Action = "Trigger automated dynamic multi-channel win-back campaigns at day 45 and day 75 post-purchase, offering personalized 'We Miss You' incentives and feedback surveys.",
      Expected_Business_Benefit = "Re-engages 8-12% of dormant customers before permanent attrition occurs, reclaiming trapped customer acquisition costs (CAC).",
      Risk_or_Limitation = "Aggressive or irrelevant messaging risks high unsubscribe rates and spam complaints.",
      stringsAsFactors = FALSE
    ),
    data.frame(
      Recommendation_ID = "REC-03",
      Strategic_Pillar = "Margin Optimization & Promotion Governance",
      Target_Audience = "Discount-Driven Shoppers",
      Empirical_Observation = sprintf("Heavily motivated by price incentives (Mean Discount Usage: %.1f%%) with moderate spend ($%.2f), but low baseline organic loyalty.",
                                      disc_row$Mean_Discount_Ratio * 100, disc_row$Mean_Spend_USD),
      Supporting_Metric = sprintf("Discount Usage Ratio: %.3f | Repeat Rate: %.1f%%",
                                  disc_row$Mean_Discount_Ratio, disc_row$Repeat_Purchase_Rate_Pct),
      Proposed_Business_Action = "Replace universal blanket price cuts with minimum order threshold discounts (e.g. 'Spend $100, Get $15 Off') and bundle high-margin accessories with volume-based coupons.",
      Expected_Business_Benefit = "Lifts Average Order Value (AOV) by 12-18% while safeguarding product margins against unprofitable bargain hunters.",
      Risk_or_Limitation = "Sudden removal of discount incentives may cause immediate short-term drop in transaction volume for price-sensitive buyers.",
      stringsAsFactors = FALSE
    ),
    data.frame(
      Recommendation_ID = "REC-04",
      Strategic_Pillar = "Predictive Propensity Scoring & Campaign Prioritization",
      Target_Audience = "All Active Customers (High-Propensity Tier)",
      Empirical_Observation = sprintf("The Random Forest classification model achieves high discriminatory accuracy (ROC-AUC: %.3f, F1-Score: %.3f), reliably surfacing customers most likely to purchase in the next 30 days.",
                                      rf_auc, rf_f1),
      Supporting_Metric = sprintf("Model ROC-AUC: %.3f | Top Predictors: %s, %s",
                                  rf_auc, top_feature, second_feature),
      Proposed_Business_Action = "Integrate the ML scoring pipeline into the CRM/CDP to assign daily purchase propensity scores. Allocate outbound paid marketing budget exclusively to customers with propensity between 0.40 and 0.70 (incremental lift zone).",
      Expected_Business_Benefit = "Reduces ad waste on sure-buyers (>0.75) and uninterested users (<0.30), driving a 20-30% improvement in Return on Ad Spend (ROAS).",
      Risk_or_Limitation = "Model drift may occur across seasonal peak periods (e.g. Black Friday or Diwali); requires quarterly re-training and recalibration.",
      stringsAsFactors = FALSE
    )
  )
  
  rec_df <- do.call(rbind, recommendations)
  
  tables_dir <- config$paths$tables_dir
  if (!dir.exists(tables_dir)) dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  out_path <- file.path(tables_dir, "business_recommendations.csv")
  write_csv(rec_df, out_path)
  cat(sprintf("[SUCCESS] Saved strategic business recommendations to '%s'.\n", out_path))
  
  # Print Console Summaries
  cat("\n[STRATEGIC ACTION SUMMARY]\n")
  for (i in 1:nrow(rec_df)) {
    cat(sprintf("  [%s] %s -> %s\n", rec_df$Recommendation_ID[i], rec_df$Strategic_Pillar[i], rec_df$Target_Audience[i]))
  }
  
  return(rec_df)
}
