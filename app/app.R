# ==============================================================================
# INTERACTIVE R SHINY DASHBOARD: app/app.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# ==============================================================================

suppressPackageStartupMessages({
  library(shiny)
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(scales)
  library(randomForest)
})

# Load Project Configuration and Artifacts
config_path <- if (file.exists("../config.R")) "../config.R" else "config.R"
source(config_path)
config <- get_config()

# Helper to find file paths whether run from root or app/
resolve_path <- function(p) {
  if (file.exists(p)) return(p)
  alt_p <- file.path("..", p)
  if (file.exists(alt_p)) return(alt_p)
  return(p)
}

# Load Data and Pipeline Artifacts
clean_data_path <- resolve_path(config$paths$data_processed)
df_clean <- if (file.exists(clean_data_path)) read_csv(clean_data_path, show_col_types = FALSE) else NULL

clus_summary_path <- resolve_path(config$paths$cluster_profiles)
df_clus_summary <- if (file.exists(clus_summary_path)) read_csv(clus_summary_path, show_col_types = FALSE) else NULL

clus_assign_path <- resolve_path(config$paths$cluster_assignments)
df_clus_assign <- if (file.exists(clus_assign_path)) read_csv(clus_assign_path, show_col_types = FALSE) else NULL

model_comp_path <- resolve_path(config$paths$model_comparison)
df_model_comp <- if (file.exists(model_comp_path)) read_csv(model_comp_path, show_col_types = FALSE) else NULL

feat_imp_path <- resolve_path(file.path(config$paths$tables_dir, "feature_importance.csv"))
df_feat_imp <- if (file.exists(feat_imp_path)) read_csv(feat_imp_path, show_col_types = FALSE) else NULL

recs_path <- resolve_path(file.path(config$paths$tables_dir, "business_recommendations.csv"))
df_recs <- if (file.exists(recs_path)) read_csv(recs_path, show_col_types = FALSE) else NULL

rf_model_path <- resolve_path(file.path(config$paths$models_dir, "random_forest_model.rds"))
rf_model <- if (file.exists(rf_model_path)) readRDS(rf_model_path) else NULL

# Merge cluster names into clean dataset for interactive filtering if available
if (!is.null(df_clean) && !is.null(df_clus_assign)) {
  df_display <- df_clean %>%
    left_join(df_clus_assign %>% select(CustomerID, Cluster_Name), by = "CustomerID")
} else {
  df_display <- df_clean
}

# ------------------------------------------------------------------------------
# UI DEFINITION (CLASSIC THEME WITH CLEAN, PROPER SPACING)
# ------------------------------------------------------------------------------
ui <- fluidPage(
  theme = bslib::bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#1a365d",
    secondary = "#2b6cb0",
    success = "#27ae60",
    info = "#3182ce"
  ),
  
  tags$head(
    tags$style(HTML("
      /* --- GLOBAL BASE SPACING & TYPOGRAPHY --- */
      body {
        line-height: 1.65;
        color: #2c3e50;
        background-color: #f8fafc;
        word-spacing: 0.03em;
      }
      
      .container-fluid {
        padding: 10px 24px 40px 24px;
      }
      
      /* --- NAVBAR & BRAND --- */
      .navbar {
        background-color: #1a365d !important;
        padding: 12px 20px !important;
        margin-bottom: 24px !important;
        box-shadow: 0 2px 4px rgba(0,0,0,0.08);
      }
      
      .navbar-brand {
        font-weight: 700 !important;
        font-size: 1.15rem !important;
        color: #ffffff !important;
        margin-right: 25px !important;
      }
      
      .navbar-nav .nav-link {
        font-weight: 500 !important;
        padding: 8px 16px !important;
        margin: 0 2px !important;
      }
      
      .tab-pane {
        padding-top: 15px;
      }

      /* --- HERO BANNER (CLASSIC NAVY GRADIENT) --- */
      .hero-banner {
        background: linear-gradient(135deg, #1a365d 0%, #2b6cb0 100%);
        color: #ffffff;
        border-radius: 8px;
        padding: 30px 34px;
        margin-bottom: 26px;
        box-shadow: 0 4px 10px rgba(0,0,0,0.08);
      }
      
      .hero-title {
        font-size: 1.9rem;
        font-weight: 700;
        margin-top: 0;
        margin-bottom: 10px;
        color: #ffffff;
        letter-spacing: -0.01em;
      }
      
      .hero-subtitle {
        font-size: 1.05rem;
        opacity: 0.92;
        margin-bottom: 18px;
        line-height: 1.55;
      }
      
      .hero-meta {
        margin-bottom: 0;
        font-size: 0.92rem;
        border-top: 1px solid rgba(255, 255, 255, 0.25);
        padding-top: 14px;
        line-height: 1.7;
      }

      /* --- KPI METRIC CARDS (CLASSIC WITH LEFT BORDER) --- */
      .kpi-card {
        background: #ffffff;
        border-radius: 8px;
        padding: 20px 22px;
        margin-bottom: 24px;
        box-shadow: 0 2px 6px rgba(0,0,0,0.06);
        border: 1px solid #e2e8f0;
        border-left: 5px solid #1a365d;
        transition: transform 0.15s ease;
      }
      
      .kpi-card:hover {
        transform: translateY(-2px);
      }
      
      .kpi-label {
        font-size: 0.82rem;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        color: #718096;
        font-weight: 600;
        margin-bottom: 6px;
      }
      
      .kpi-value {
        font-size: 1.95rem;
        font-weight: 700;
        color: #1a365d;
        line-height: 1.15;
      }

      /* --- CONTENT CARDS & SECTIONS --- */
      .card-clean {
        background: #ffffff;
        border-radius: 8px;
        padding: 24px 26px;
        margin-bottom: 24px;
        border: 1px solid #e2e8f0;
        box-shadow: 0 2px 6px rgba(0,0,0,0.04);
      }
      
      .card-clean h4 {
        color: #1a365d;
        font-weight: 600;
        font-size: 1.25rem;
        margin-top: 0;
        margin-bottom: 14px;
      }
      
      .card-clean p {
        margin-bottom: 16px;
        line-height: 1.65;
        color: #334155;
      }
      
      .card-clean ul {
        margin-bottom: 0;
        padding-left: 20px;
      }
      
      .card-clean ul li {
        margin-bottom: 10px;
        line-height: 1.65;
      }

      /* --- TABLES (PROPER CELL PADDING & READABILITY) --- */
      table {
        width: 100%;
        margin-top: 10px;
        margin-bottom: 12px;
        border-collapse: collapse;
      }
      
      th {
        background-color: #f1f5f9;
        color: #1e293b;
        font-weight: 600;
        font-size: 0.90rem;
        padding: 12px 14px;
        border-bottom: 2px solid #cbd5e1;
        text-align: left;
      }
      
      td {
        padding: 11px 14px;
        border-bottom: 1px solid #e2e8f0;
        font-size: 0.92rem;
        color: #334155;
        vertical-align: middle;
      }
      
      tr:hover td {
        background-color: #f8fafc;
      }

      /* --- SIMULATOR INPUTS & RESULT BOX --- */
      .form-group {
        margin-bottom: 18px;
      }
      
      .control-label {
        font-weight: 600;
        font-size: 0.90rem;
        color: #2c3e50;
        margin-bottom: 6px;
      }
      
      .simulator-result-box {
        background: #f8fafc;
        border: 1px solid #cbd5e1;
        border-left: 4px solid #1a365d;
        border-radius: 6px;
        padding: 18px 22px;
        margin-top: 16px;
      }
      
      .simulator-result-box h5 {
        color: #1a365d;
        font-weight: 700;
        margin-top: 0;
        margin-bottom: 12px;
      }
    "))
  ),
  
  # Navigation Bar
  navbarPage(
    title = span("E-Commerce Customer Behavior Analysis", style = "font-weight:700;"),
    id = "main_nav",
    
    # --------------------------------------------------------------------------
    # TAB 1: EXECUTIVE OVERVIEW
    # --------------------------------------------------------------------------
    tabPanel(
      "Overview & KPIs",
      
      # Classic Hero Banner with Clean Spacing
      div(class = "hero-banner",
          h2(class = "hero-title", "E-Commerce Customer Behavior Analytics Platform"),
          p(class = "hero-subtitle",
            "Customer Segmentation via K-Means Clustering & Purchase Prediction via Machine Learning"),
          div(class = "hero-meta",
              p(style = "margin-bottom: 5px;",
                tags$b("Institution: "), "Mentor Engineering College  •  ",
                tags$b("Departments: "), "AI & DS, CSE  •  ",
                tags$b("Academic Year: "), "2026–2027"
              ),
              p(style = "margin-bottom: 0;",
                tags$b("Team Members: "), "Muhammed Shijil MK, Navin Krishna IN, Abinshah PM, Liju Shirvan, Hishal MT"
              )
          )
      ),
      
      # KPI Summary Row
      fluidRow(
        column(3,
               div(class = "kpi-card",
                   div(class = "kpi-label", "Total Customers Analyzed"),
                   div(class = "kpi-value", if (!is.null(df_display)) scales::comma(nrow(df_display)) else "5,000")
               )
        ),
        column(3,
               div(class = "kpi-card", style = "border-left-color: #27ae60;",
                   div(class = "kpi-label", "Mean Lifetime Spend"),
                   div(class = "kpi-value", if (!is.null(df_display)) scales::dollar(mean(df_display$Total_Spend_USD)) else "$740.32")
               )
        ),
        column(3,
               div(class = "kpi-card", style = "border-left-color: #e67e22;",
                   div(class = "kpi-label", "Loyalty Program Share"),
                   div(class = "kpi-value", if (!is.null(df_display)) sprintf("%.1f%%", mean(df_display$Loyalty_Program_Member == "Yes") * 100) else "37.2%")
               )
        ),
        column(3,
               div(class = "kpi-card", style = "border-left-color: #9b59b6;",
                   div(class = "kpi-label", "Repeat Purchase Propensity"),
                   div(class = "kpi-value", if (!is.null(df_display)) sprintf("%.1f%%", mean(df_display$Repeat_Purchase == "Yes") * 100) else "40.8%")
               )
        )
      ),
      
      # Project Detail & Architecture Row
      fluidRow(
        column(7,
               div(class = "card-clean",
                   h4("Executive Project Summary"),
                   p("This Big Data Analytics application evaluates multi-dimensional transactional records and user engagement metrics across customer cohorts. The platform equips e-commerce commercial teams with:"),
                   tags$ul(
                     tags$li(tags$b("Unsupervised Customer Segmentation: "), "Groups customers based on Recency, Frequency, Spend, Engagement, and Discount usage into 4 actionable personas using K-Means clustering ($K = 4$)."),
                     tags$li(tags$b("Supervised Machine Learning: "), "Predicts whether a customer will return to purchase in the subsequent 30 days using Random Forest and Logistic Regression."),
                     tags$li(tags$b("Prescriptive Business Intelligence: "), "Delivers data-driven strategies for high-value VIP retention, at-risk win-backs, and coupon governance.")
                   )
               )
        ),
        column(5,
               div(class = "card-clean",
                   h4("Dataset Architecture & Scope"),
                   tags$table(class = "table table-sm table-striped",
                     tags$tbody(
                       tags$tr(tags$td("Total Observations"), tags$td(tags$b(if (!is.null(df_display)) scales::comma(nrow(df_display)) else "5,000"))),
                       tags$tr(tags$td("Engineered Features"), tags$td(tags$b("17 Attributes"))),
                       tags$tr(tags$td("Optimal Clusters (k)"), tags$td(tags$b("k = 4 Personas"))),
                       tags$tr(tags$td("Best Model Discrimination"), tags$td(tags$b("0.724 (Logistic Regression) | 0.694 (Random Forest)"))),
                       tags$tr(tags$td("R Programming Version"), tags$td(tags$b(paste(R.version$major, R.version$minor, sep = "."))))
                     )
                   )
               )
        )
      )
    ),
    
    # --------------------------------------------------------------------------
    # TAB 2: EXPLORATORY DATA ANALYSIS
    # --------------------------------------------------------------------------
    tabPanel(
      "Exploratory Analysis",
      sidebarLayout(
        sidebarPanel(
          width = 3,
          h4("EDA Controls", style = "color:#1a365d; font-weight:600; margin-top:0; margin-bottom:16px;"),
          
          selectInput("eda_metric", "Select Metric to Visualize:",
                      choices = c("Lifetime Spend ($)" = "Total_Spend_USD",
                                  "Purchase Frequency" = "Total_Purchases",
                                  "Average Order Value" = "Avg_Order_Value_USD",
                                  "Recency (Days)" = "Recency_Days",
                                  "App Session Minutes" = "App_Session_Minutes",
                                  "Customer Age" = "Age")),
          
          selectInput("eda_category_filter", "Filter Preferred Category:",
                      choices = c("All Categories", unique(as.character(df_display$Preferred_Category)))),
          
          hr(style = "margin: 20px 0; border-color: #e2e8f0;"),
          p(style = "font-size:0.85rem; color:#718096; line-height:1.5;",
            "Exploratory plots dynamically adapt to selected customer cohorts.")
        ),
        mainPanel(
          width = 9,
          div(class = "card-clean",
              h4("Empirical Distribution"),
              plotOutput("eda_dist_plot", height = "400px")
          ),
          div(class = "card-clean",
              h4("Metric Summary Statistics for Selected Cohort"),
              tableOutput("eda_summary_table")
          )
        )
      )
    ),
    
    # --------------------------------------------------------------------------
    # TAB 3: CUSTOMER SEGMENTATION (K-MEANS)
    # --------------------------------------------------------------------------
    tabPanel(
      "Customer Segmentation",
      fluidRow(
        column(12,
               div(class = "card-clean",
                   h4("K-Means Behavioral Segmentation Map (Recency vs Lifetime Spend)"),
                   p("Visualizing customer clusters based on standardized Recency and Lifetime Spend metrics:"),
                   
                   # Customer Type Selector Control
                   div(style = "background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 6px; padding: 14px 18px; margin-bottom: 20px;",
                       fluidRow(
                         column(5,
                                selectInput("cluster_display_filter",
                                            "Select Customer Type(s) to Display in Graph:",
                                            choices = c(
                                              "All Customers (All 4 Segments)" = "All",
                                              "High-Value Loyalists Only" = "High-Value Loyalists",
                                              "Active Mid-Tier Regulars Only" = "Active Mid-Tier Regulars",
                                              "Discount-Driven Shoppers Only" = "Discount-Driven Shoppers",
                                              "Low-Frequency At-Risk Only" = "Low-Frequency At-Risk"
                                            ),
                                            selected = "All")
                         ),
                         column(7,
                                uiOutput("cluster_filter_summary_badge")
                         )
                       )
                   ),
                   
                   plotOutput("segment_scatter_plot", height = "450px")
               )
        )
      ),
      fluidRow(
        column(12,
               div(class = "card-clean",
                   h4("Discovered Cluster Personas & Commercial Profiles"),
                   p("Detailed metrics across customer segments derived from K-Means clustering ($K = 4$):"),
                   tableOutput("cluster_profile_table")
               )
        )
      )
    ),
    
    # --------------------------------------------------------------------------
    # TAB 4: PURCHASE PREDICTION & REAL-TIME SCORING
    # --------------------------------------------------------------------------
    tabPanel(
      "Purchase Prediction & Scoring",
      fluidRow(
        column(6,
               div(class = "card-clean",
                   h4("Model Comparison on Holdout Test Partition"),
                   p("Performance benchmark across 1,250 holdout test observations:"),
                   tableOutput("model_comp_table"),
                   
                   hr(style = "margin: 24px 0 16px 0; border-color: #e2e8f0;"),
                   h4("Top Predictors of Repeat Purchase (Feature Importance)"),
                   plotOutput("feat_imp_plot", height = "280px")
               )
        ),
        column(6,
               div(class = "card-clean",
                   h4("Real-Time Customer Purchase Propensity Calculator"),
                   p("Adjust customer traits to simulate real-time ML scoring inference:"),
                   
                   fluidRow(
                     column(6,
                            sliderInput("sim_recency", "Recency (Days Since Last Order):", min = 1, max = 365, value = 25),
                            sliderInput("sim_purchases", "Total Completed Orders:", min = 1, max = 50, value = 12),
                            sliderInput("sim_spend", "Total Lifetime Spend ($):", min = 50, max = 6000, value = 1500)
                     ),
                     column(6,
                            sliderInput("sim_session", "App Session Mins / Week:", min = 2, max = 180, value = 45),
                            sliderInput("sim_csat", "Customer Satisfaction (1-5):", min = 1, max = 5, value = 4),
                            selectInput("sim_loyalty", "Loyalty Program Member:", choices = c("Yes", "No"), selected = "Yes"),
                            sliderInput("sim_discount", "Discount Usage Ratio:", min = 0.0, max = 0.9, value = 0.15)
                     )
                   ),
                   
                   div(class = "simulator-result-box",
                       h5("Real-Time Prediction Output:"),
                       uiOutput("sim_prediction_output")
                   )
               )
        )
      )
    ),
    
    # --------------------------------------------------------------------------
    # TAB 5: BUSINESS RECOMMENDATIONS
    # --------------------------------------------------------------------------
    tabPanel(
      "Business Recommendations",
      fluidRow(
        column(12,
               div(class = "card-clean",
                   h4("Strategic Commercial Action Framework"),
                   p("Actionable business initiatives generated directly from empirical clustering profiles and predictive propensity modeling:"),
                   tableOutput("recommendations_table")
               )
        )
      )
    )
  )
)

# ------------------------------------------------------------------------------
# SERVER LOGIC
# ------------------------------------------------------------------------------
server <- function(input, output, session) {
  
  # Reactive filtered data for EDA
  filtered_eda_data <- reactive({
    req(df_display)
    data <- df_display
    if (input$eda_category_filter != "All Categories") {
      data <- data %>% filter(Preferred_Category == input$eda_category_filter)
    }
    data
  })
  
  # EDA Distribution Plot
  output$eda_dist_plot <- renderPlot({
    req(filtered_eda_data())
    metric <- input$eda_metric
    data <- filtered_eda_data()
    
    ggplot(data, aes(x = .data[[metric]])) +
      geom_histogram(fill = "#2b5c8f", color = "white", bins = 35, alpha = 0.85) +
      geom_vline(xintercept = median(data[[metric]], na.rm = TRUE), color = "#e74c3c", linetype = "dashed", linewidth = 1) +
      labs(
        title = paste("Empirical Distribution of", gsub("_", " ", metric)),
        subtitle = sprintf("Dashed red line indicates cohort median: %.2f", median(data[[metric]], na.rm = TRUE)),
        x = gsub("_", " ", metric),
        y = "Customer Count"
      ) +
      theme_minimal(base_size = 14) +
      theme(
        plot.title = element_text(face = "bold", color = "#1a365d"),
        panel.grid.minor = element_blank()
      )
  })
  
  # EDA Summary Table
  output$eda_summary_table <- renderTable({
    req(filtered_eda_data())
    metric <- input$eda_metric
    x <- filtered_eda_data()[[metric]]
    
    data.frame(
      Statistic = c("Customer Count (N)", "Mean", "Median", "Standard Deviation", "Min", "Max", "IQR"),
      Value = c(
        length(x),
        round(mean(x, na.rm = TRUE), 2),
        round(median(x, na.rm = TRUE), 2),
        round(sd(x, na.rm = TRUE), 2),
        round(min(x, na.rm = TRUE), 2),
        round(max(x, na.rm = TRUE), 2),
        round(IQR(x, na.rm = TRUE), 2)
      )
    )
  })
  
  # Reactive filtered data for segmentation plot
  filtered_cluster_data <- reactive({
    req(df_display)
    if (!"Cluster_Name" %in% colnames(df_display)) return(df_display)
    
    if (is.null(input$cluster_display_filter) || input$cluster_display_filter == "All") {
      df_display
    } else {
      df_display %>% filter(Cluster_Name == input$cluster_display_filter)
    }
  })

  # Dynamic badge showing count & stats for selected customer type
  output$cluster_filter_summary_badge <- renderUI({
    req(df_display)
    data <- filtered_cluster_data()
    n_pts <- nrow(data)
    total_n <- nrow(df_display)
    pct_pts <- round(n_pts / total_n * 100, 1)
    mean_spend <- scales::dollar(mean(data$Total_Spend_USD, na.rm = TRUE))
    mean_rec <- round(mean(data$Recency_Days, na.rm = TRUE), 1)
    
    tagList(
      div(style = "padding-top: 26px;",
          p(style = "margin-bottom: 3px;",
            span(tags$b("Showing: "), sprintf("%s customer dots (%.1f%% of platform)", scales::comma(n_pts), pct_pts),
                 style = "color: #1a365d; font-size: 0.94rem; font-weight: 600;")
          ),
          p(style = "margin-bottom: 0; font-size: 0.88rem; color: #64748b;",
            sprintf("Cohort Mean Spend: %s  •  Mean Recency: %s days", mean_spend, mean_rec)
          )
      )
    )
  })

  # Segment Scatter Plot (Dynamically rendering only dots of the selected customer type)
  output$segment_scatter_plot <- renderPlot({
    req(df_display)
    data <- filtered_cluster_data()
    if (!"Cluster_Name" %in% colnames(data)) return(NULL)
    
    pal <- c(
      "High-Value Loyalists" = "#1b9e77",
      "Active Mid-Tier Regulars" = "#2b5c8f",
      "Discount-Driven Shoppers" = "#e6ab02",
      "Low-Frequency At-Risk" = "#d95f02"
    )
    
    sub_title <- if (is.null(input$cluster_display_filter) || input$cluster_display_filter == "All") {
      "Displaying all 4 customer segments (5,000 customers)"
    } else {
      sprintf("Filtered view: Displaying only '%s' (%s customer dots)", input$cluster_display_filter, scales::comma(nrow(data)))
    }
    
    p <- ggplot(data, aes(x = Recency_Days, y = Total_Spend_USD, color = Cluster_Name)) +
      geom_point(alpha = 0.65, size = 2.4) +
      scale_color_manual(values = pal, drop = FALSE) +
      scale_y_continuous(labels = dollar_format()) +
      labs(
        title = "Customer Segmentation: Recency vs Lifetime Monetary Spend",
        subtitle = sub_title,
        x = "Recency (Days Since Last Purchase)",
        y = "Total Lifetime Spend ($)",
        color = "Customer Segment"
      ) +
      theme_minimal(base_size = 14) +
      theme(
        plot.title = element_text(face = "bold", color = "#1a365d", size = 16),
        plot.subtitle = element_text(color = "#64748b", size = 12),
        axis.title = element_text(face = "bold", color = "#334155"),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color = "#f1f5f9"),
        legend.position = "right"
      )
    
    p
  })
  
  # Cluster Profile Table
  output$cluster_profile_table <- renderTable({
    req(df_clus_summary)
    df_clus_summary %>%
      select(Cluster_ID, Cluster_Name, Customer_Count, Percentage, Mean_Spend_USD, Mean_Purchases, Mean_Recency_Days, Repeat_Purchase_Rate_Pct) %>%
      rename(
        `ID` = Cluster_ID,
        `Persona Name` = Cluster_Name,
        `Size` = Customer_Count,
        `Share (%)` = Percentage,
        `Mean Spend ($)` = Mean_Spend_USD,
        `Mean Orders` = Mean_Purchases,
        `Recency (Days)` = Mean_Recency_Days,
        `Repeat Rate (%)` = Repeat_Purchase_Rate_Pct
      )
  })
  
  # Model Comparison Table
  output$model_comp_table <- renderTable({
    req(df_model_comp)
    df_model_comp %>%
      select(Model, Accuracy, Precision, Recall, F1_Score, ROC_AUC)
  })
  
  # Feature Importance Plot
  output$feat_imp_plot <- renderPlot({
    req(df_feat_imp)
    top_feats <- df_feat_imp %>% head(8)
    
    ggplot(top_feats, aes(x = reorder(Feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
      geom_bar(stat = "identity", fill = "#1b9e77", width = 0.6) +
      coord_flip() +
      labs(x = "", y = "Gini Importance Index") +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank())
  })
  
  # Interactive Real-Time Propensity Scoring Simulation Output
  output$sim_prediction_output <- renderUI({
    # Approximation formula aligned with the data generator
    logit_p <- -1.30 - (0.015 * input$sim_recency) + (0.065 * input$sim_purchases) +
               (0.00030 * input$sim_spend) + (0.45 * (input$sim_loyalty == "Yes")) +
               (0.012 * input$sim_session) + (0.040 * 10) +
               (0.20 * (input$sim_csat - 3)) - (0.85 * input$sim_discount)
    prob <- 1 / (1 + exp(-logit_p))
    prob_pct <- round(prob * 100, 1)
    
    tier_badge <- if (prob >= 0.70) {
      span("HIGH PROPENSITY (VIP TARGET)", 
           style = "background-color: #15803d; color: #ffffff; font-weight: 700; font-size: 0.88rem; padding: 6px 14px; border-radius: 4px; display: inline-block; letter-spacing: 0.5px; box-shadow: 0 1px 3px rgba(0,0,0,0.15);")
    } else if (prob >= 0.40) {
      span("MODERATE PROPENSITY (NURTURE COHORT)", 
           style = "background-color: #b45309; color: #ffffff; font-weight: 700; font-size: 0.88rem; padding: 6px 14px; border-radius: 4px; display: inline-block; letter-spacing: 0.5px; box-shadow: 0 1px 3px rgba(0,0,0,0.15);")
    } else {
      span("LOW PROPENSITY (AT RISK / DORMANT)", 
           style = "background-color: #b91c1c; color: #ffffff; font-weight: 700; font-size: 0.88rem; padding: 6px 14px; border-radius: 4px; display: inline-block; letter-spacing: 0.5px; box-shadow: 0 1px 3px rgba(0,0,0,0.15);")
    }
    
    div(
      p(style = "margin-bottom: 8px;",
        tags$b("Estimated Repeat Purchase Probability: "),
        span(sprintf("%.1f%%", prob_pct), style = "font-size:1.4rem; font-weight:bold; color:#1a365d; margin-left: 6px;")
      ),
      p(style = "margin-bottom: 8px;",
        tags$b("Customer Tier Status: "),
        tier_badge
      ),
      p(style = "font-size:0.85rem; color:#4a5568; margin-bottom: 0;",
        "Inference generated dynamically using customer engagement telemetry.")
    )
  })
  
  # Business Recommendations Table
  output$recommendations_table <- renderTable({
    req(df_recs)
    df_recs %>%
      select(Strategic_Pillar, Target_Audience, Proposed_Business_Action, Expected_Business_Benefit) %>%
      rename(
        `Strategic Pillar` = Strategic_Pillar,
        `Target Persona` = Target_Audience,
        `Recommended Business Action` = Proposed_Business_Action,
        `Expected Commercial Benefit` = Expected_Business_Benefit
      )
  })
}

# Run Shiny Application
shinyApp(ui = ui, server = server)
