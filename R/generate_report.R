# ==============================================================================
# AUTOMATED ANALYTICAL REPORT GENERATOR: R/generate_report.R
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

#' Helper for string concatenation
`%+%` <- function(a, b) paste0(a, b)

#' Generate Publication-Quality Markdown and HTML Analytical Report
generate_analytical_report <- function(eda_results, stat_results, seg_results, pred_results, rec_results, prep_summary, config) {
  cat("\n------------------------------------------------------------------\n")
  cat("   COMPILING AUTOMATED ACADEMIC ANALYTICAL REPORT                 \n")
  cat("------------------------------------------------------------------\n")

  meta <- config$project_info
  rep_dir <- config$paths$reports_dir
  if (!dir.exists(rep_dir)) dir.create(rep_dir, recursive = TRUE, showWarnings = FALSE)

  md_file <- config$paths$final_report
  html_file <- file.path(rep_dir, "analytical_report.html")

  # 1. Format Cluster Profile Table
  clus_tbl <- seg_results$cluster_summary
  clus_md <- "| Cluster ID | Segment Persona | Customers | Share (%) |\n|:---|:---|---:|---:|\n"
  if (!is.null(clus_tbl) && nrow(clus_tbl) > 0) {
    for (i in 1:nrow(clus_tbl)) {
      cid <- if ("Cluster_ID" %in% colnames(clus_tbl)) clus_tbl$Cluster_ID[i] else i
      cname <- if ("Cluster_Name" %in% colnames(clus_tbl)) clus_tbl$Cluster_Name[i] else paste("Cluster", i)
      ccnt <- if ("Customer_Count" %in% colnames(clus_tbl)) clus_tbl$Customer_Count[i] else 0
      cpct <- if ("Percentage" %in% colnames(clus_tbl)) clus_tbl$Percentage[i] else 0.0
      clus_md <- paste0(clus_md, sprintf("| %s | **%s** | %s | %.2f%% |\n", cid, cname, scales::comma(ccnt), cpct))
    }
  }

  # 2. Format Model Comparison Table
  comp_tbl <- if (isTRUE(pred_results$model_available)) pred_results$model_comparison else NULL
  comp_md <- "| Model Algorithm | Accuracy | Precision | Recall | F1-Score | ROC-AUC |\n|:---|---:|---:|---:|---:|---:|\n"
  if (!is.null(comp_tbl) && nrow(comp_tbl) > 0) {
    for (i in 1:nrow(comp_tbl)) {
      comp_md <- paste0(comp_md, sprintf(
        "| **%s** | %.4f | %.4f | %.4f | %.4f | **%.4f** |\n",
        comp_tbl$Model[i], comp_tbl$Accuracy[i], comp_tbl$Precision[i],
        comp_tbl$Recall[i], comp_tbl$F1_Score[i], comp_tbl$ROC_AUC[i]
      ))
    }
  } else {
    comp_md <- "Predictive modeling module was not applicable or disabled for this dataset.\n"
  }

  # 3. Format Statistical Tests Table
  stat_md <- "| Test ID | Statistical Test | Hypothesis Tested | Test Statistic | p-Value | Academic Decision |\n|:---|:---|:---|:---|:---|:---|\n"
  if (!is.null(stat_results) && nrow(stat_results) > 0) {
    for (i in 1:nrow(stat_results)) {
      stat_md <- paste0(stat_md, sprintf(
        "| %s | %s | %s | %s | `%s` | **%s** |\n",
        stat_results$Test_ID[i], stat_results$Statistical_Test[i],
        stat_results$Hypothesis[i], stat_results$Test_Statistic[i],
        stat_results$p_value[i], stat_results$Decision[i]
      ))
    }
  }

  # 4. Format Recommendations Table
  rec_md <- "| Pillar | Target Audience | Proposed Action | Expected Business Benefit |\n|:---|:---|:---|:---|\n"
  if (!is.null(rec_results) && nrow(rec_results) > 0) {
    for (i in 1:nrow(rec_results)) {
      rec_md <- paste0(rec_md, sprintf(
        "| **%s** | %s | %s | %s |\n",
        rec_results$Strategic_Pillar[i], rec_results$Target_Audience[i],
        rec_results$Proposed_Business_Action[i], rec_results$Expected_Business_Benefit[i]
      ))
    }
  }

  # Build Markdown Report
  report_lines <- c(
    sprintf("# %s", meta$title),
    sprintf("### %s", meta$subtitle),
    "",
    "---",
    "",
    "**Academic Subject:** " %+% meta$subject,
    "**Institution:** " %+% meta$college,
    "**Department:** " %+% paste(meta$departments, collapse = " & "),
    "**Academic Year:** " %+% meta$academic_year,
    "**Dataset:** Customer Shopping Trends Dataset (Kaggle)",
    "**Date:** " %+% meta$date,
    "",
    "---",
    "",
    "## 1. Executive Summary",
    "",
    "This academic project implements an end-to-end Big Data Analytics and Machine Learning pipeline engineered in R programming.",
    "The platform analyzes multi-dimensional customer transaction footprints to address two core commercial objectives:",
    "",
    "1. **Unsupervised Customer Segmentation:** K-Means clustering applied to behavioral vectors.",
    "2. **Supervised Machine Learning:** Propensity modeling using Logistic Regression and Random Forest classifiers.",
    "",
    "---",
    "",
    "## 2. Customer Segmentation Summary",
    "",
    clus_md,
    "",
    "---",
    "",
    "## 3. Supervised Model Benchmark",
    "",
    comp_md,
    "",
    "---",
    "",
    "## 4. Inferential Statistical Hypothesis Testing",
    "",
    stat_md,
    "",
    "---",
    "",
    "## 5. Strategic Commercial Recommendations",
    "",
    rec_md,
    "",
    "---",
    "",
    "*(Report generated automatically by the E-Commerce Customer Behavior Analytics Pipeline)*"
  )

  # Write Markdown report
  writeLines(report_lines, md_file)
  cat(sprintf("[SUCCESS] Markdown report generated at: '%s'\n", md_file))

  # Build Clean HTML Report
  html_lines <- c(
    "<!DOCTYPE html>",
    "<html lang='en'>",
    "<head>",
    "  <meta charset='UTF-8'>",
    "  <title>Analytical Report: E-Commerce Customer Analytics</title>",
    "  <style>",
    "    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #2c3e50; max-width: 1000px; margin: 40px auto; padding: 0 20px; background: #f8fafc; }",
    "    .container { background: #ffffff; padding: 40px 50px; border-radius: 8px; box-shadow: 0 4px 15px rgba(0,0,0,0.06); border: 1px solid #e2e8f0; }",
    "    h1 { color: #1a365d; border-bottom: 2px solid #2b6cb0; padding-bottom: 12px; margin-top: 0; }",
    "    h2 { color: #2b6cb0; margin-top: 35px; border-bottom: 1px solid #e2e8f0; padding-bottom: 8px; }",
    "    table { width: 100%; border-collapse: collapse; margin: 20px 0; font-size: 0.92rem; }",
    "    th { background: #1a365d; color: #ffffff; text-align: left; padding: 10px 14px; font-weight: 600; }",
    "    td { padding: 9px 14px; border-bottom: 1px solid #e2e8f0; }",
    "    tr:nth-child(even) { background: #f8fafc; }",
    "    .badge { display: inline-block; padding: 4px 10px; border-radius: 4px; font-weight: bold; font-size: 0.82rem; background: #e2e8f0; color: #1a365d; }",
    "  </style>",
    "</head>",
    "<body>",
    "<div class='container'>",
    sprintf("<h1>%s</h1>", meta$title),
    sprintf("<p style='font-size:1.1rem; color:#4a5568;'>%s</p>", meta$subtitle),
    sprintf("<p><strong>Institution:</strong> %s | <strong>Academic Year:</strong> %s</p>", meta$college, meta$academic_year),
    "<hr style='border: 0; border-top: 1px solid #e2e8f0; margin: 25px 0;'>",
    "<h2>1. Discovered Customer Personas (K-Means)</h2>",
    "<table>",
    "  <thead><tr><th>ID</th><th>Persona Name</th><th>Size</th><th>Share (%)</th></tr></thead>",
    "  <tbody>"
  )

  if (!is.null(clus_tbl) && nrow(clus_tbl) > 0) {
    for (i in 1:nrow(clus_tbl)) {
      cid <- if ("Cluster_ID" %in% colnames(clus_tbl)) clus_tbl$Cluster_ID[i] else i
      cname <- if ("Cluster_Name" %in% colnames(clus_tbl)) clus_tbl$Cluster_Name[i] else paste("Cluster", i)
      ccnt <- if ("Customer_Count" %in% colnames(clus_tbl)) scales::comma(clus_tbl$Customer_Count[i]) else "0"
      cpct <- if ("Percentage" %in% colnames(clus_tbl)) clus_tbl$Percentage[i] else 0.0
      html_lines <- c(html_lines, sprintf("    <tr><td>%s</td><td><strong>%s</strong></td><td>%s</td><td>%.2f%%</td></tr>", cid, cname, ccnt, cpct))
    }
  }

  html_lines <- c(
    html_lines,
    "  </tbody>",
    "</table>",
    "<h2>2. Predictive Modeling Benchmark</h2>",
    "<table>",
    "  <thead><tr><th>Model</th><th>Accuracy</th><th>Precision</th><th>Recall</th><th>F1-Score</th><th>ROC-AUC</th></tr></thead>",
    "  <tbody>"
  )

  if (!is.null(comp_tbl) && nrow(comp_tbl) > 0) {
    for (i in 1:nrow(comp_tbl)) {
      html_lines <- c(html_lines, sprintf(
        "    <tr><td><strong>%s</strong></td><td>%.4f</td><td>%.4f</td><td>%.4f</td><td>%.4f</td><td><strong>%.4f</strong></td></tr>",
        comp_tbl$Model[i], comp_tbl$Accuracy[i], comp_tbl$Precision[i],
        comp_tbl$Recall[i], comp_tbl$F1_Score[i], comp_tbl$ROC_AUC[i]
      ))
    }
  } else {
    html_lines <- c(html_lines, "    <tr><td colspan='6'>Predictive modeling module was disabled for this dataset.</td></tr>")
  }

  html_lines <- c(
    html_lines,
    "  </tbody>",
    "</table>",
    "<h2>3. Strategic Commercial Actions</h2>",
    "<table>",
    "  <thead><tr><th>Pillar</th><th>Target Cohort</th><th>Action</th><th>Expected Benefit</th></tr></thead>",
    "  <tbody>"
  )

  if (!is.null(rec_results) && nrow(rec_results) > 0) {
    for (i in 1:nrow(rec_results)) {
      html_lines <- c(html_lines, sprintf(
        "    <tr><td><strong>%s</strong></td><td>%s</td><td>%s</td><td>%s</td></tr>",
        rec_results$Strategic_Pillar[i], rec_results$Target_Audience[i],
        rec_results$Proposed_Business_Action[i], rec_results$Expected_Business_Benefit[i]
      ))
    }
  }

  html_lines <- c(
    html_lines,
    "  </tbody>",
    "</table>",
    "<p style='color:#718096; font-size:0.85rem; margin-top:40px;'>Report compiled automatically by the E-Commerce Customer Analytics Platform.</p>",
    "</div>",
    "</body>",
    "</html>"
  )

  writeLines(html_lines, html_file)
  cat(sprintf("[SUCCESS] HTML report compiled at: '%s'\n", html_file))

  return(html_file)
}
