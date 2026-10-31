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
  library(readxl)
  library(scales)
  library(cluster)
  library(randomForest)
  library(bslib)
})

# Load Project Configuration and Core Modules
resolve_file <- function(filename) {
  if (file.exists(filename)) return(filename)
  parent_fn <- file.path("..", filename)
  if (file.exists(parent_fn)) return(parent_fn)
  return(filename)
}

source(resolve_file("config.R"))
config <- get_config()

source(resolve_file(file.path("R", "data_loading.R")))
source(resolve_file(file.path("R", "data_preprocessing.R")))
source(resolve_file(file.path("R", "exploratory_analysis.R")))
source(resolve_file(file.path("R", "customer_segmentation.R")))
source(resolve_file(file.path("R", "purchase_prediction.R")))
source(resolve_file(file.path("R", "statistical_analysis.R")))
source(resolve_file(file.path("R", "visualization.R")))
source(resolve_file(file.path("R", "business_insights.R")))

# Standard Cluster Persona Color Palette (Global Fallback)
if (!exists("PALETTE_CLUSTERS")) {
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
}

# ------------------------------------------------------------------------------
# UI DEFINITION (MODERN USER-FRIENDLY INTERFACE)
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
      /* --- GLOBAL TYPOGRAPHY & LAYOUT --- */
      body {
        line-height: 1.65;
        color: #2c3e50;
        background-color: #f8fafc;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Inter', sans-serif;
      }
      .container-fluid {
        padding: 10px 24px 40px 24px;
        max-width: 1440px;
        margin: 0 auto;
      }

      /* --- MODERN NAVBAR --- */
      .navbar {
        background: linear-gradient(90deg, #1a365d 0%, #2b6cb0 100%) !important;
        padding: 12px 24px !important;
        margin-bottom: 24px !important;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(26, 54, 93, 0.15);
      }
      .navbar-brand {
        font-weight: 700 !important;
        font-size: 1.22rem !important;
        color: #ffffff !important;
        letter-spacing: -0.01em;
      }
      .navbar-nav .nav-link {
        font-weight: 500 !important;
        padding: 8px 16px !important;
        color: rgba(255, 255, 255, 0.90) !important;
        border-radius: 6px;
        margin: 0 2px;
        transition: all 0.2s ease;
      }
      .navbar-nav .nav-link:hover, .navbar-nav .nav-link.active {
        background-color: rgba(255, 255, 255, 0.18) !important;
        color: #ffffff !important;
      }

      /* --- HERO BANNER (LANDING PAGE) --- */
      .hero-banner {
        background: linear-gradient(135deg, #1a365d 0%, #234e79 50%, #2b6cb0 100%);
        color: #ffffff;
        border-radius: 12px;
        padding: 32px 36px;
        margin-bottom: 24px;
        box-shadow: 0 8px 20px rgba(26, 54, 93, 0.12);
        position: relative;
        overflow: hidden;
      }
      .hero-title {
        font-size: 2.1rem;
        font-weight: 800;
        margin: 0 0 10px 0;
        color: #ffffff;
        letter-spacing: -0.02em;
      }
      .hero-subtitle {
        font-size: 1.10rem;
        opacity: 0.94;
        margin-bottom: 18px;
        max-width: 850px;
        line-height: 1.6;
      }
      .hero-meta {
        font-size: 0.92rem;
        border-top: 1px solid rgba(255, 255, 255, 0.25);
        padding-top: 16px;
        margin-bottom: 0;
      }

      .dataset-pill {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 7px 16px;
        border-radius: 20px;
        font-weight: 600;
        font-size: 0.88rem;
        background: rgba(255, 255, 255, 0.22);
        color: #ffffff;
        border: 1px solid rgba(255, 255, 255, 0.38);
        box-shadow: 0 2px 5px rgba(0,0,0,0.06);
      }

      /* --- QUICK JUMP ACTION BAR --- */
      .quick-actions-bar {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        padding: 14px 20px;
        margin-bottom: 24px;
        box-shadow: 0 2px 6px rgba(0,0,0,0.03);
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
      }

      /* --- USER-FRIENDLY KPI METRIC CARDS --- */
      .kpi-card {
        background: #ffffff;
        border-radius: 10px;
        padding: 22px 24px;
        margin-bottom: 24px;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
        border: 1px solid #e2e8f0;
        border-left: 5px solid #1a365d;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
        position: relative;
      }
      .kpi-card:hover {
        transform: translateY(-3px);
        box-shadow: 0 8px 15px -3px rgba(0, 0, 0, 0.08);
      }
      .kpi-label {
        font-size: 0.82rem;
        text-transform: uppercase;
        letter-spacing: 0.6px;
        color: #64748b;
        font-weight: 700;
        margin-bottom: 6px;
      }
      .kpi-value {
        font-size: 2.10rem;
        font-weight: 800;
        color: #1a365d;
        line-height: 1.15;
        margin-bottom: 6px;
      }
      .kpi-subtext {
        font-size: 0.82rem;
        color: #94a3b8;
        font-weight: 500;
      }

      /* --- CLEAN CONTENT CARDS --- */
      .card-clean {
        background: #ffffff;
        border-radius: 10px;
        padding: 24px 28px;
        margin-bottom: 24px;
        border: 1px solid #e2e8f0;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.04);
      }
      .card-clean h4 {
        color: #1a365d;
        font-weight: 700;
        font-size: 1.25rem;
        margin-top: 0;
        margin-bottom: 14px;
        display: flex;
        align-items: center;
        gap: 8px;
      }
      .card-clean p {
        color: #475569;
        font-size: 0.95rem;
      }

      /* --- WORKFLOW GUIDE CARDS --- */
      .workflow-step-card {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        padding: 16px 18px;
        height: 100%;
        transition: all 0.2s ease;
      }
      .workflow-step-card:hover {
        background: #ffffff;
        border-color: #2b6cb0;
        box-shadow: 0 4px 10px rgba(0,0,0,0.05);
      }
      .step-num {
        display: inline-block;
        width: 28px;
        height: 28px;
        line-height: 28px;
        text-align: center;
        background: #1a365d;
        color: #ffffff;
        border-radius: 50%;
        font-weight: 700;
        font-size: 0.85rem;
        margin-bottom: 10px;
      }

      /* --- RESPONSIVE TABLE CONTAINERS & STYLING --- */
      .table-responsive {
        width: 100%;
        overflow-x: auto;
        -webkit-overflow-scrolling: touch;
        border-radius: 8px;
        border: 1px solid #e2e8f0;
        background: #ffffff;
        margin-top: 8px;
        margin-bottom: 12px;
      }
      table {
        width: 100%;
        margin-top: 0;
        margin-bottom: 0;
        border-collapse: collapse;
      }
      th {
        background-color: #f1f5f9;
        color: #1e293b;
        font-weight: 700;
        font-size: 0.84rem;
        padding: 10px 12px;
        border-bottom: 2px solid #cbd5e1;
        text-align: left;
        white-space: nowrap;
      }
      td {
        padding: 9px 12px;
        border-bottom: 1px solid #e2e8f0;
        font-size: 0.86rem;
        color: #334155;
        white-space: nowrap;
      }
      tr:hover td {
        background-color: #f8fafc;
      }
      .cluster-profile-table-wrap th {
        background: #1a365d;
        color: #ffffff;
        border-bottom: 2px solid #0f172a;
        font-size: 0.80rem;
        letter-spacing: 0.3px;
        text-transform: uppercase;
      }

      /* --- SIMULATOR RESULT BOX --- */
      .simulator-result-box {
        background: #f8fafc;
        border: 1px solid #cbd5e1;
        border-left: 5px solid #1a365d;
        border-radius: 8px;
        padding: 18px 22px;
        margin-top: 16px;
      }

      /* --- BUTTONS --- */
      .btn-primary {
        background-color: #1a365d !important;
        border-color: #1a365d !important;
        font-weight: 600;
        padding: 8px 18px;
        border-radius: 6px;
      }
      .btn-primary:hover {
        background-color: #2b6cb0 !important;
        border-color: #2b6cb0 !important;
      }
    "))
  ),

  navbarPage(
    title = span("E-Commerce Customer Analytics", style = "font-weight:700;"),
    id = "main_nav",
    selected = "Overview & KPIs",

    # ==========================================================================
    # TAB 1: EXECUTIVE OVERVIEW & KPIS (LANDING PAGE)
    # ==========================================================================
    tabPanel(
      title = "Overview & KPIs",
      icon = icon("chart-line"),

      # Hero Banner
      div(class = "hero-banner",
          h1(class = "hero-title", "E-Commerce Customer Behavior Analytics Platform"),
          p(class = "hero-subtitle",
            "End-to-End Big Data Analytics, Unsupervised K-Means Customer Segmentation, and Supervised Machine Learning Purchase Prediction in R Programming."),
          div(class = "hero-meta",
              fluidRow(
                column(8,
                       p(style = "margin-bottom: 4px;",
                         tags$b("Institution: "), "Mentor Engineering College  •  ",
                         tags$b("Departments: "), "AI & DS, CSE  •  ",
                         tags$b("Academic Year: "), "2026–2027"
                       ),
                       p(style = "margin-bottom: 0;",
                         tags$b("Submitted By: "), "Muhammed Shijil MK, Navin Krishna IN, Abinshah PM, Liju Shirvan, Hishal MT"
                       )
                ),
                column(4, style = "text-align: right;",
                       uiOutput("hero_active_dataset_pill")
                )
              )
          )
      ),

      # Quick Actions Bar
      div(class = "quick-actions-bar",
          div(style = "display: flex; align-items: center; gap: 10px;",
              tags$span(tags$b("Active Data Source: "), style = "color: #1a365d; font-size: 0.95rem;"),
              uiOutput("quick_status_badge")
          ),
          div(style = "display: flex; gap: 8px; flex-wrap: wrap;",
              actionButton("btn_nav_upload", "Upload / Switch Dataset", class = "btn btn-outline-primary btn-sm", icon = icon("upload")),
              actionButton("btn_nav_eda", "Explore Distributions", class = "btn btn-outline-secondary btn-sm", icon = icon("chart-bar")),
              actionButton("btn_nav_cluster", "Customer Segmentation", class = "btn btn-outline-secondary btn-sm", icon = icon("users")),
              actionButton("btn_nav_ml", "Purchase Prediction", class = "btn btn-outline-secondary btn-sm", icon = icon("robot")),
              actionButton("btn_nav_recs", "Recommendations", class = "btn btn-outline-secondary btn-sm", icon = icon("lightbulb"))
          )
      ),

      # KPI Summary Row
      fluidRow(
        column(3,
               div(class = "kpi-card",
                   div(class = "kpi-label", "Total Customers Analyzed"),
                   div(class = "kpi-value", textOutput("kpi_customers")),
                   div(class = "kpi-subtext", "Active dataset customer records")
               )
        ),
        column(3,
               div(class = "kpi-card", style = "border-left-color: #27ae60;",
                   div(class = "kpi-label", "Mean Lifetime Spend"),
                   div(class = "kpi-value", textOutput("kpi_spend")),
                   div(class = "kpi-subtext", "Average monetary transaction value")
               )
        ),
        column(3,
               div(class = "kpi-card", style = "border-left-color: #e67e22;",
                   div(class = "kpi-label", "Loyalty / Subscriber Share"),
                   div(class = "kpi-value", textOutput("kpi_loyalty")),
                   div(class = "kpi-subtext", "Active subscription program members")
               )
        ),
        column(3,
               div(class = "kpi-card", style = "border-left-color: #9b59b6;",
                   div(class = "kpi-label", "Repeat Purchase Propensity"),
                   div(class = "kpi-value", textOutput("kpi_repeat")),
                   div(class = "kpi-subtext", "Cohort repeat buying rate")
               )
        )
      ),

      # Project Summary & Scope
      fluidRow(
        column(7,
               div(class = "card-clean",
                   h4(icon("layer-group"), "Executive Platform Architecture"),
                   p("This academic Big Data Analytics suite bridges raw transactional footprints with actionable business intelligence:"),
                   tags$ul(
                     tags$li(tags$b("Dynamic Ingestion & Upload: "), "Seamlessly operates with genuine Kaggle benchmarks or user-uploaded CSV and Excel datasets."),
                     tags$li(tags$b("Exploratory Data Analysis: "), "Dynamic histogram distributions, summary metrics, and Pearson correlation matrices adapt to active attributes."),
                     tags$li(tags$b("Unsupervised Segmentation (K-Means): "), "Uncovers latent behavioral personas based on user-chosen features with optimal k evaluation."),
                     tags$li(tags$b("Supervised Machine Learning: "), "Ensemble Random Forest (200 trees) and Logistic Regression classifiers predict repeat purchase and subscription conversions."),
                     tags$li(tags$b("Real-Time ML Simulator: "), "Calculates live customer propensity inference with automated tier classification badges.")
                   )
               )
        ),
        column(5,
               div(class = "card-clean",
                   h4(icon("database"), "Active Dataset Scope"),
                   tableOutput("scope_summary_table"),
                   div(style = "margin-top: 15px; text-align: right;",
                       actionButton("btn_view_dataset_tab", "Manage or Upload New Data →", class = "btn btn-primary btn-sm")
                   )
               )
        )
      ),

      # Step-by-Step Workflow Guide
      div(class = "card-clean",
          h4(icon("compass"), "Step-by-Step Platform Workflow Guide"),
          fluidRow(
            column(3,
                   div(class = "workflow-step-card",
                       div(class = "step-num", "1"),
                       tags$h6(tags$b("Dataset & Upload"), style = "color: #1a365d; margin-bottom: 6px;"),
                       p("Switch to your own CSV/Excel file or use the built-in Kaggle benchmark of 3,900 customers.", style = "font-size:0.85rem; color:#64748b; margin-bottom:0;")
                   )
            ),
            column(3,
                   div(class = "workflow-step-card",
                       div(class = "step-num", "2"),
                       tags$h6(tags$b("Exploratory Analysis"), style = "color: #1a365d; margin-bottom: 6px;"),
                       p("Filter distributions, compute IQR and standard deviation, and audit data missingness in real time.", style = "font-size:0.85rem; color:#64748b; margin-bottom:0;")
                   )
            ),
            column(3,
                   div(class = "workflow-step-card",
                       div(class = "step-num", "3"),
                       tags$h6(tags$b("K-Means Personas"), style = "color: #1a365d; margin-bottom: 6px;"),
                       p("Select features, adjust cluster count k, and explore interactive 2D segmentation scatter plots.", style = "font-size:0.85rem; color:#64748b; margin-bottom:0;")
                   )
            ),
            column(3,
                   div(class = "workflow-step-card",
                       div(class = "step-num", "4"),
                       tags$h6(tags$b("ML Prediction & Scoring"), style = "color: #1a365d; margin-bottom: 6px;"),
                       p("Compare Random Forest & Logistic models, view Gini importance, and score new customers live.", style = "font-size:0.85rem; color:#64748b; margin-bottom:0;")
                   )
            )
          )
      )
    ),

    # ==========================================================================
    # TAB 2: DATASET MANAGEMENT & UPLOAD (PHASE 3 & 5)
    # ==========================================================================
    tabPanel(
      title = "Dataset & Upload",
      icon = icon("upload"),

      fluidRow(
        column(5,
               div(class = "card-clean",
                   h4(icon("sliders-h"), "1. Select Active Dataset Source"),
                   p("Choose between the default genuine Kaggle dataset and your custom uploaded file:"),

                   radioButtons(
                     "dataset_choice",
                     label = NULL,
                     choices = c(
                       "Default: Genuine Kaggle Dataset (3,900 Shoppers)" = "kaggle",
                       "Custom: User-Uploaded Dataset (.csv, .xlsx, .xls)" = "custom"
                     ),
                     selected = "kaggle"
                   ),

                   hr(style = "margin: 18px 0; border-color: #e2e8f0;"),

                   h4(icon("file-upload"), "2. Upload Custom Dataset"),
                   p("Select any CSV or Excel file containing customer purchasing or behavioral attributes:"),
                   fileInput(
                     "user_file",
                     label = NULL,
                     accept = c(".csv", ".xlsx", ".xls"),
                     buttonLabel = "Choose File...",
                     placeholder = "No file chosen yet"
                   ),

                   uiOutput("upload_status_message"),

                   div(style = "margin-top: 16px; display: flex; gap: 8px; flex-wrap: wrap;",
                       actionButton("btn_activate_custom", "Analyze Uploaded File", class = "btn btn-primary", icon = icon("play")),
                       actionButton("btn_load_sample_excel", "Load Sample Excel (.xlsx)", class = "btn btn-outline-info", icon = icon("file-excel")),
                       actionButton("btn_reset_kaggle", "Reset to Kaggle Data", class = "btn btn-outline-secondary", icon = icon("undo"))
                   )
               ),

               div(class = "card-clean",
                   h4(icon("info-circle"), "Dataset Ingestion Integrity"),
                   tags$ul(
                     tags$li(tags$b("CSV (.csv): "), "UTF-8 and ISO-8859-1 encodings supported."),
                     tags$li(tags$b("Excel (.xlsx, .xls): "), "Multi-column sheets ingested directly via ", tags$code("readxl::read_excel()"), "."),
                     tags$li(tags$b("Automatic Column Mapping: "), "Common headers like 'Customer ID', 'Purchase Amount', 'Review Rating', 'Category' are auto-standardized without breaking downstream logic.")
                   )
               )
        ),

        column(7,
               div(class = "card-clean",
                   h4(icon("table"), "Active Dataset Attributes & Metadata"),
                   uiOutput("active_dataset_badge"),
                   tableOutput("active_dataset_meta_table")
               ),
               div(class = "card-clean",
                   h4(icon("eye"), "Dataset Preview (First 10 Observations)"),
                   div(style = "overflow-x: auto; max-height: 380px;",
                       tableOutput("dataset_preview_table")
                   )
               )
        )
      )
    ),

    # ==========================================================================
    # TAB 3: EXPLORATORY DATA ANALYSIS (EDA)
    # ==========================================================================
    tabPanel(
      title = "Exploratory Analysis",
      icon = icon("chart-bar"),

      sidebarLayout(
        sidebarPanel(
          width = 3,
          h4("EDA Controls", style = "color:#1a365d; font-weight:700; margin-top:0; margin-bottom:16px;"),
          selectInput("eda_num_metric", "Select Numerical Feature to Plot:", choices = NULL),
          selectInput("eda_cat_filter_col", "Filter by Categorical Dimension:", choices = NULL),
          selectInput("eda_cat_filter_val", "Filter Value:", choices = c("All Cohorts")),
          checkboxInput("eda_density_toggle", "Overlay Density Curve", value = TRUE),
          hr(style = "margin: 18px 0; border-color: #e2e8f0;"),
          p(style = "font-size:0.85rem; color:#64748b;",
            "All distribution histograms, quantiles, and missingness metrics recompute live for the active cohort.")
        ),
        mainPanel(
          width = 9,
          div(class = "card-clean",
              h4(icon("chart-area"), "Empirical Feature Distribution"),
              plotOutput("eda_dist_plot", height = "380px")
          ),
          fluidRow(
            column(6,
                   div(class = "card-clean",
                       h4(icon("calculator"), "Descriptive Summary Statistics"),
                       div(class = "table-responsive",
                           tableOutput("eda_stats_table")
                       )
                   )
            ),
            column(6,
                   div(class = "card-clean",
                       h4(icon("clipboard-check"), "Missing Values Quality Audit"),
                       div(class = "table-responsive",
                           tableOutput("eda_missing_table")
                       )
                   )
            )
          )
        )
      )
    ),

    # ==========================================================================
    # TAB 4: CUSTOMER SEGMENTATION (K-MEANS)
    # ==========================================================================
    tabPanel(
      title = "Customer Segmentation",
      icon = icon("users"),

      fluidRow(
        column(12,
               div(class = "card-clean",
                   h4(icon("project-diagram"), "K-Means Behavioral Segmentation Engine"),
                   p("Discover customer personas by tailoring numerical clustering attributes, cluster count, and scatter plot axes:"),

                   div(style = "background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 18px 22px; margin-bottom: 20px;",
                       fluidRow(
                         column(4,
                                selectizeInput("cluster_features_sel", "Clustering Features (Min 2):", choices = NULL, multiple = TRUE)
                         ),
                         column(3,
                                sliderInput("cluster_k_slider", "Number of Clusters (k):", min = 2, max = 6, value = 4, step = 1)
                         ),
                         column(3,
                                selectInput("cluster_view_filter", "Display Cohort in Scatter:", choices = c("All Customers" = "All"))
                         ),
                         column(2,
                                div(style = "padding-top: 28px;",
                                    actionButton("btn_run_cluster", "Run Clustering", class = "btn btn-primary w-100", icon = icon("sync"))
                                )
                         )
                       ),
                       fluidRow(
                         column(4,
                                selectInput("scatter_x_axis", "Scatter Plot X-Axis:", choices = NULL)
                         ),
                         column(4,
                                selectInput("scatter_y_axis", "Scatter Plot Y-Axis:", choices = NULL)
                         ),
                         column(4,
                                uiOutput("cluster_scatter_badge")
                         )
                       )
                   ),
                   plotOutput("segment_scatter_plot", height = "450px")
               ),
               div(class = "card-clean",
                   h4(icon("id-card"), "Discovered Customer Personas & Metric Profiles"),
                   p("Empirical metric benchmarks for each discovered cluster persona (table scrolls horizontally on compact screens):",
                     style = "color:#64748b; font-size:0.87rem; margin-bottom:12px;"),
                   div(class = "table-responsive cluster-profile-table-wrap",
                       tableOutput("cluster_profile_table")
                   )
               )
        )
      )
    ),

    # ==========================================================================
    # TAB 5: PURCHASE PREDICTION & SCORING
    # ==========================================================================
    tabPanel(
      title = "Purchase Prediction",
      icon = icon("brain"),

      fluidRow(
        column(12,
               uiOutput("prediction_availability_alert")
        )
      ),
      conditionalPanel(
        condition = "output.prediction_model_available == true",
        fluidRow(
          column(6,
                 div(class = "card-clean",
                     h4(icon("trophy"), "Predictive Model Benchmark on Holdout Partition"),
                     p("Evaluation metrics across out-of-sample holdout test partition (75% Train / 25% Test):"),
                     div(class = "table-responsive",
                         tableOutput("dyn_model_comp_table")
                     ),
                     hr(style = "margin: 20px 0; border-color: #e2e8f0;"),
                     h4(icon("chart-pie"), "Top Predictive Features (Gini Importance Index)"),
                     plotOutput("dyn_feat_imp_plot", height = "320px")
                 )
          ),
          column(6,
                 div(class = "card-clean",
                     h4(icon("calculator"), "Real-Time Customer Propensity Scoring Calculator"),
                     p("Adjust customer behavioral parameters to calculate real-time ML model inference:"),
                     uiOutput("dyn_simulator_controls"),
                     div(class = "simulator-result-box",
                         h5("Real-Time Prediction Inference:"),
                         uiOutput("dyn_simulator_result")
                     )
                 )
          )
        )
      )
    ),

    # ==========================================================================
    # TAB 6: STRATEGIC BUSINESS RECOMMENDATIONS
    # ==========================================================================
    tabPanel(
      title = "Business Recommendations",
      icon = icon("lightbulb"),

      fluidRow(
        column(12,
               div(class = "card-clean",
                   h4(icon("bullseye"), "Strategic Commercial Action Framework"),
                   p("Prescriptive initiatives derived directly from empirical clustering profiles and predictive propensity drivers:"),
                   div(class = "table-responsive",
                       tableOutput("recommendations_table")
                   )
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

  # Reactive container for user uploaded data
  uploaded_dataset_holder <- reactiveVal(NULL)
  upload_message_holder <- reactiveVal(NULL)

  # Load raw default Kaggle dataset on start
  default_raw_data <- reactive({
    p <- resolve_file(config$paths$data_raw)
    load_raw_data(p)
  })

  # File upload handler
  observeEvent(input$user_file, {
    req(input$user_file)
    res <- load_custom_dataset(input$user_file$datapath, input$user_file$name)
    if (isTRUE(res$success)) {
      uploaded_dataset_holder(res$data)
      upload_message_holder(list(
        type = "success",
        text = sprintf("File '%s' successfully loaded (%d rows, %d columns). Click 'Analyze Uploaded File' to proceed.",
                       input$user_file$name, nrow(res$data), ncol(res$data))
      ))
    } else {
      uploaded_dataset_holder(NULL)
      upload_message_holder(list(
        type = "error",
        text = sprintf("Upload Error: %s", res$message)
      ))
    }
  })

  # One-click sample Excel loader button
  observeEvent(input$btn_load_sample_excel, {
    sample_p <- resolve_file(config$paths$data_sample_excel)
    if (file.exists(sample_p)) {
      res <- load_custom_dataset(sample_p, "customer_data_sample.xlsx")
      if (isTRUE(res$success)) {
        uploaded_dataset_holder(res$data)
        updateRadioButtons(session, "dataset_choice", selected = "custom")
        upload_message_holder(list(
          type = "success",
          text = sprintf("Sample Excel workbook loaded successfully (%d rows, %d columns). Active dataset switched to Custom!",
                         nrow(res$data), ncol(res$data))
        ))
        showNotification("Loaded 'customer_data_sample.xlsx' into active analysis!", type = "message")
      }
    } else {
      showNotification("Sample Excel file not found on disk.", type = "warning")
    }
  })

  # Activate upload button
  observeEvent(input$btn_activate_custom, {
    if (is.null(uploaded_dataset_holder())) {
      showNotification("Please select and upload a valid CSV or Excel file first.", type = "warning")
    } else {
      updateRadioButtons(session, "dataset_choice", selected = "custom")
      showNotification("Active dataset updated to custom uploaded data!", type = "message")
    }
  })

  # Reset button
  observeEvent(input$btn_reset_kaggle, {
    updateRadioButtons(session, "dataset_choice", selected = "kaggle")
    showNotification("Reset active dataset to default Kaggle dataset.", type = "message")
  })

  # Quick Navigation Observers (from Landing Page)
  observeEvent(input$btn_nav_upload, updateNavbarPage(session, "main_nav", selected = "Dataset & Upload"))
  observeEvent(input$btn_view_dataset_tab, updateNavbarPage(session, "main_nav", selected = "Dataset & Upload"))
  observeEvent(input$btn_nav_eda, updateNavbarPage(session, "main_nav", selected = "Exploratory Analysis"))
  observeEvent(input$btn_nav_cluster, updateNavbarPage(session, "main_nav", selected = "Customer Segmentation"))
  observeEvent(input$btn_nav_ml, updateNavbarPage(session, "main_nav", selected = "Purchase Prediction"))
  observeEvent(input$btn_nav_recs, updateNavbarPage(session, "main_nav", selected = "Business Recommendations"))

  # Upload status alert box
  output$upload_status_message <- renderUI({
    msg <- upload_message_holder()
    if (is.null(msg)) return(NULL)

    alert_class <- if (msg$type == "success") "alert alert-success" else "alert alert-danger"
    div(class = alert_class, style = "margin-top: 15px; padding: 11px 16px; font-size: 0.90rem; border-radius: 6px;",
        tags$b(if (msg$type == "success") "Ready: " else "Notice: "),
        msg$text
    )
  })

  # Active raw dataset (switches between Kaggle and custom upload)
  active_raw_dataset <- reactive({
    if (input$dataset_choice == "custom" && !is.null(uploaded_dataset_holder())) {
      uploaded_dataset_holder()
    } else {
      default_raw_data()
    }
  })

  # Active preprocessed dataset
  active_preprocessed <- reactive({
    raw <- active_raw_dataset()
    preprocess_customer_data(raw, config)
  })

  # Current active cleaned dataframe
  active_df <- reactive({
    active_preprocessed()$cleaned_data
  })

  # Active Dataset Status Badges
  output$quick_status_badge <- renderUI({
    is_custom <- (input$dataset_choice == "custom" && !is.null(uploaded_dataset_holder()))
    label <- if (is_custom) {
      if (!is.null(input$user_file$name)) input$user_file$name else "Custom Upload"
    } else {
      "Kaggle Shopping Trends"
    }
    badge_color <- if (is_custom) "#27ae60" else "#2b6cb0"
    span(label, style = sprintf("background:%s; color:#ffffff; padding:4px 12px; border-radius:15px; font-size:0.85rem; font-weight:600;", badge_color))
  })

  output$active_dataset_badge <- renderUI({
    is_custom <- (input$dataset_choice == "custom" && !is.null(uploaded_dataset_holder()))
    ds_name <- if (is_custom) {
      if (!is.null(input$user_file$name)) input$user_file$name else "Custom Upload"
    } else {
      "Default: Customer Shopping Trends Dataset (Kaggle)"
    }
    badge_bg <- if (is_custom) "#27ae60" else "#1a365d"

    div(style = "margin-bottom: 16px;",
        span(tags$b("CURRENT ACTIVE DATASET: "), ds_name,
             style = sprintf("background:%s; color:#ffffff; padding:7px 16px; border-radius:6px; font-size:0.92rem; font-weight:700;", badge_bg))
    )
  })

  output$hero_active_dataset_pill <- renderUI({
    is_custom <- (input$dataset_choice == "custom" && !is.null(uploaded_dataset_holder()))
    ds_label <- if (is_custom) {
      if (!is.null(input$user_file$name)) input$user_file$name else "Custom Upload"
    } else {
      "Kaggle Benchmark (3,900 Records)"
    }
    div(class = "dataset-pill", icon("database"), " Active: ", ds_label)
  })

  # Metadata Table
  output$active_dataset_meta_table <- renderTable({
    df <- active_df()
    num_cols <- names(df)[sapply(df, is.numeric)]
    cat_cols <- names(df)[sapply(df, function(x) is.character(x) || is.factor(x))]

    data.frame(
      Property = c("Total Observations", "Total Attributes", "Numerical Features", "Categorical Features", "Missing Values Resolved"),
      Value = c(
        scales::comma(nrow(df)),
        as.character(ncol(df)),
        paste(num_cols[1:min(5, length(num_cols))], collapse = ", "),
        paste(cat_cols[1:min(5, length(cat_cols))], collapse = ", "),
        as.character(sum(is.na(active_raw_dataset())))
      )
    )
  })

  # Dataset Preview Table
  output$dataset_preview_table <- renderTable({
    head(active_df(), 10)
  })

  # KPI Text Outputs
  output$kpi_customers <- renderText({
    scales::comma(nrow(active_df()))
  })

  output$kpi_spend <- renderText({
    df <- active_df()
    spend_col <- intersect(c("Total_Spend_USD", "Purchase_Amount_USD", "Avg_Order_Value_USD"), colnames(df))[1]
    if (!is.na(spend_col) && is.numeric(df[[spend_col]])) {
      scales::dollar(mean(df[[spend_col]], na.rm = TRUE))
    } else {
      "N/A"
    }
  })

  output$kpi_loyalty <- renderText({
    df <- active_df()
    loy_col <- intersect(c("Loyalty_Program_Member", "Subscription_Status"), colnames(df))[1]
    if (!is.na(loy_col)) {
      pct <- mean(tolower(as.character(df[[loy_col]])) %in% c("yes", "true", "1")) * 100
      sprintf("%.1f%%", pct)
    } else {
      "N/A"
    }
  })

  output$kpi_repeat <- renderText({
    df <- active_df()
    rep_col <- intersect(c("Repeat_Purchase", "Subscription_Status"), colnames(df))[1]
    if (!is.na(rep_col)) {
      pct <- mean(tolower(as.character(df[[rep_col]])) %in% c("yes", "true", "1")) * 100
      sprintf("%.1f%%", pct)
    } else {
      "N/A"
    }
  })

  output$scope_summary_table <- renderTable({
    df <- active_df()
    prep <- active_preprocessed()
    data.frame(
      Dimension = c("Observations", "Attributes", "Clustering Features", "Target Variable"),
      Specification = c(
        scales::comma(nrow(df)),
        as.character(ncol(df)),
        paste(prep$clustering_features, collapse = ", "),
        as.character(prep$target_var)
      )
    )
  })

  # ----------------------------------------------------------------------------
  # DYNAMIC EDA OBSERVERS & OUTPUTS
  # ----------------------------------------------------------------------------
  observe({
    df <- active_df()
    num_cols <- names(df)[sapply(df, is.numeric)]
    num_cols <- setdiff(num_cols, c("CustomerID", "Customer_ID", "Cluster_ID"))
    cat_cols <- names(df)[sapply(df, function(x) is.character(x) || is.factor(x))]
    cat_cols <- setdiff(cat_cols, c("CustomerID", "Customer_ID"))

    updateSelectInput(session, "eda_num_metric", choices = num_cols, selected = num_cols[1])
    updateSelectInput(session, "eda_cat_filter_col", choices = c("None", cat_cols), selected = "None")
  })

  observeEvent(input$eda_cat_filter_col, {
    df <- active_df()
    col <- input$eda_cat_filter_col
    if (col != "None" && col %in% colnames(df)) {
      vals <- c("All Cohorts", unique(as.character(df[[col]])))
      updateSelectInput(session, "eda_cat_filter_val", choices = vals, selected = "All Cohorts")
    } else {
      updateSelectInput(session, "eda_cat_filter_val", choices = c("All Cohorts"), selected = "All Cohorts")
    }
  })

  filtered_eda_data <- reactive({
    df <- active_df()
    cat_col <- input$eda_cat_filter_col
    cat_val <- input$eda_cat_filter_val
    if (cat_col != "None" && cat_val != "All Cohorts" && cat_col %in% colnames(df)) {
      df <- df[as.character(df[[cat_col]]) == cat_val, ]
    }
    df
  })

  output$eda_dist_plot <- renderPlot({
    req(input$eda_num_metric)
    data <- filtered_eda_data()
    metric <- input$eda_num_metric
    req(metric %in% colnames(data))

    x <- na.omit(data[[metric]])
    req(length(x) > 0)
    med_val <- median(x)

    p <- ggplot(data, aes(x = .data[[metric]])) +
      geom_histogram(fill = "#2b6cb0", color = "white", bins = 30, alpha = 0.85) +
      geom_vline(xintercept = med_val, color = "#e74c3c", linetype = "dashed", linewidth = 1.1) +
      labs(
        title = paste("Empirical Distribution of", gsub("_", " ", metric)),
        subtitle = sprintf("Cohort median: %.2f (Dashed red line)", med_val),
        x = gsub("_", " ", metric),
        y = "Frequency Count"
      ) +
      theme_minimal(base_size = 14) +
      theme(
        plot.title = element_text(face = "bold", color = "#1a365d"),
        panel.grid.minor = element_blank()
      )

    p
  })

  output$eda_stats_table <- renderTable({
    req(input$eda_num_metric)
    data <- filtered_eda_data()
    metric <- input$eda_num_metric
    req(metric %in% colnames(data))
    x <- na.omit(data[[metric]])

    data.frame(
      Statistic = c("Cohort Size (N)", "Mean", "Median", "Standard Deviation", "Min", "Max", "IQR"),
      Value = c(
        scales::comma(length(x)),
        round(mean(x), 2),
        round(median(x), 2),
        round(sd(x), 2),
        round(min(x), 2),
        round(max(x), 2),
        round(IQR(x), 2)
      )
    )
  })

  output$eda_missing_table <- renderTable({
    raw <- active_raw_dataset()
    mis <- colSums(is.na(raw))
    mis_cols <- names(mis[mis > 0])
    if (length(mis_cols) == 0) {
      data.frame(Feature = "Zero Missing Entries Detected", Missing_Count = 0, Missing_Rate = "0.0%")
    } else {
      data.frame(
        Feature = mis_cols,
        Missing_Count = as.integer(mis[mis_cols]),
        Missing_Rate = sprintf("%.1f%%", (mis[mis_cols] / nrow(raw)) * 100)
      )
    }
  })

  # ----------------------------------------------------------------------------
  # DYNAMIC CUSTOMER SEGMENTATION OBSERVERS & OUTPUTS
  # ----------------------------------------------------------------------------
  observe({
    df <- active_df()
    num_cols <- names(df)[sapply(df, is.numeric)]
    num_cols <- setdiff(num_cols, c("CustomerID", "Customer_ID", "Cluster_ID"))

    updateSelectizeInput(session, "cluster_features_sel", choices = num_cols,
                         selected = num_cols[1:min(5, length(num_cols))])

    # Intelligent default axis selection prioritizing key RFM drivers (Frequency vs Monetary Spend)
    cand_x <- c("Total_Purchases", "Previous_Purchases", "Recency_Days", "orders", "Frequency")
    cand_y <- c("Total_Spend_USD", "Purchase_Amount_USD", "Avg_Order_Value_USD", "Spending", "Monetary")

    sel_x <- intersect(cand_x, num_cols)[1]
    if (is.na(sel_x)) sel_x <- num_cols[1]

    sel_y <- intersect(cand_y, num_cols)[1]
    if (is.na(sel_y)) sel_y <- if (length(num_cols) > 1) num_cols[2] else num_cols[1]

    updateSelectInput(session, "scatter_x_axis", choices = num_cols, selected = sel_x)
    updateSelectInput(session, "scatter_y_axis", choices = num_cols, selected = sel_y)
  })

  segmentation_reactive <- reactive({
    input$btn_run_cluster
    df <- isolate(active_df())
    req(nrow(df) >= 5)

    sel_feats <- isolate(input$cluster_features_sel)
    num_cols <- names(df)[sapply(df, is.numeric)]
    num_cols <- setdiff(num_cols, c("CustomerID", "Customer_ID", "Cluster_ID"))

    feats_to_use <- intersect(sel_feats, num_cols)
    if (length(feats_to_use) < 2) {
      feats_to_use <- num_cols[1:min(4, length(num_cols))]
    }

    scaled_matrix <- scale(df[, feats_to_use, drop = FALSE])
    scaled_df <- as.data.frame(scaled_matrix)

    k_val <- isolate(input$cluster_k_slider)
    if (is.null(k_val) || k_val < 2) k_val <- 4
    k_val <- min(k_val, nrow(df) - 1)

    cfg <- config
    cfg$clustering$k_optimal <- k_val
    cfg$clustering$k_range <- 2:min(6, nrow(df) - 1)

    perform_customer_segmentation(df, scaled_df, cfg)
  })

  observe({
    seg <- segmentation_reactive()
    req(seg)
    cnames <- levels(seg$df_with_clusters$Cluster_Name)
    updateSelectInput(session, "cluster_view_filter", choices = c("All Customers" = "All", cnames), selected = "All")
  })

  output$segment_scatter_plot <- renderPlot({
    seg <- segmentation_reactive()
    req(seg)
    data <- seg$df_with_clusters
    req("Cluster_Name" %in% colnames(data))

    filter_val <- input$cluster_view_filter
    if (!is.null(filter_val) && filter_val != "All") {
      data <- data %>% filter(Cluster_Name == filter_val)
    }

    x_col <- input$scatter_x_axis
    y_col <- input$scatter_y_axis
    req(x_col %in% colnames(data) && y_col %in% colnames(data))

    # Dynamically match colors to active cluster levels
    cluster_levels <- unique(as.character(data$Cluster_Name))
    fallback_palette <- c("#1b9e77", "#2b5c8f", "#e6ab02", "#d95f02", "#8e44ad", "#16a085", "#e7298a", "#66a61e", "#e41a1c", "#377eb8")
    cluster_colors <- setNames(rep(fallback_palette, length.out = length(cluster_levels)), cluster_levels)
    for (lvl in cluster_levels) {
      if (exists("PALETTE_CLUSTERS") && lvl %in% names(PALETTE_CLUSTERS)) {
        cluster_colors[lvl] <- PALETTE_CLUSTERS[lvl]
      }
    }

    # Detect whether X or Y are discrete/integer to prevent barcode striping
    x_vals <- na.omit(data[[x_col]])
    y_vals <- na.omit(data[[y_col]])
    x_is_discrete <- length(unique(x_vals)) <= 60 || all(x_vals %% 1 == 0)
    y_is_discrete <- length(unique(y_vals)) <= 25 || all(y_vals %% 1 == 0)

    # Compute cluster centroid coordinates for visual anchoring
    centroids <- tryCatch({
      data %>%
        group_by(Cluster_Name) %>%
        summarise(
          cx = mean(.data[[x_col]], na.rm = TRUE),
          cy = mean(.data[[y_col]], na.rm = TRUE),
          .groups = "drop"
        )
    }, error = function(e) NULL)

    p <- ggplot(data, aes(x = .data[[x_col]], y = .data[[y_col]], color = Cluster_Name))

    # Apply intelligent jittering if an axis is discrete (e.g. Age, Integer Counts)
    if (x_is_discrete || y_is_discrete) {
      j_w <- if (x_is_discrete) 0.35 else 0
      j_h <- if (y_is_discrete) 0.35 else 0
      p <- p + geom_jitter(width = j_w, height = j_h, alpha = 0.55, size = 2.2)
    } else {
      p <- p + geom_point(alpha = 0.60, size = 2.3)
    }

    # Add soft cluster confidence ellipses where clusters have sufficient sample size
    p <- tryCatch({
      p + stat_ellipse(aes(group = Cluster_Name), level = 0.80, linetype = 2, linewidth = 0.7, alpha = 0.65)
    }, error = function(e) p)

    if (!is.null(centroids) && nrow(centroids) > 0) {
      p <- p +
        geom_point(data = centroids, aes(x = cx, y = cy, fill = Cluster_Name),
                   color = "#111827", shape = 23, size = 5.5, stroke = 1.6, inherit.aes = FALSE) +
        scale_fill_manual(values = cluster_colors, drop = FALSE, guide = "none")
    }

    p <- p +
      scale_color_manual(values = cluster_colors, drop = FALSE) +
      labs(
        title = sprintf("K-Means Customer Segmentation Map (%s vs %s)", gsub("_", " ", x_col), gsub("_", " ", y_col)),
        subtitle = sprintf("Displaying %s customer records colored by segment (◆ = Segment Centroid Center)", scales::comma(nrow(data))),
        x = gsub("_", " ", x_col),
        y = gsub("_", " ", y_col),
        color = "Customer Segment"
      ) +
      theme_minimal(base_size = 14) +
      theme(
        plot.title = element_text(face = "bold", color = "#1a365d", size = 16),
        axis.title = element_text(face = "bold", color = "#334155"),
        panel.grid.minor = element_blank(),
        legend.position = "right"
      )

    if (grepl("spend|amount|price", tolower(y_col))) {
      p <- p + scale_y_continuous(labels = dollar_format())
    }
    if (grepl("spend|amount|price", tolower(x_col))) {
      p <- p + scale_x_continuous(labels = dollar_format())
    }

    p
  })

  output$cluster_scatter_badge <- renderUI({
    seg <- segmentation_reactive()
    req(seg)
    n_pts <- nrow(seg$df_with_clusters)
    k_opt <- length(unique(seg$df_with_clusters$Cluster_ID))
    div(style = "padding-top: 26px;",
        span(tags$b("Discovered: "), sprintf("%d Personas across %s shoppers", k_opt, scales::comma(n_pts)),
             style = "color:#1a365d; font-size:0.92rem; font-weight:600;")
    )
  })

  output$cluster_profile_table <- renderTable({
    seg <- segmentation_reactive()
    req(seg)
    df <- seg$cluster_summary
    req(nrow(df) > 0)

    # 1. Clean and abbreviate header labels
    colnames(df) <- gsub("^Mean_", "Avg ", colnames(df))
    colnames(df) <- gsub("_USD", " ($)", colnames(df))
    colnames(df) <- gsub("_", " ", colnames(df))

    rename_map <- c(
      "Cluster ID" = "ID",
      "Cluster Name" = "Customer Persona",
      "Customer Count" = "Shoppers",
      "Percentage" = "Share (%)",
      "Avg Total Spend ($)" = "Avg Spend ($)",
      "Avg Avg Order Value ($)" = "Avg Basket ($)",
      "Avg Total Purchases" = "Avg Orders",
      "Avg Recency Days" = "Avg Recency (d)",
      "Avg Customer Satisfaction Score" = "Rating ★",
      "Avg Age" = "Avg Age (y)",
      "Repeat Rate Pct" = "Repeat Rate (%)"
    )
    for (old_n in names(rename_map)) {
      if (old_n %in% colnames(df)) {
        names(df)[names(df) == old_n] <- rename_map[old_n]
      }
    }

    # 2. Format numerical columns cleanly
    if ("Shoppers" %in% colnames(df)) df[["Shoppers"]] <- scales::comma(df[["Shoppers"]])
    if ("Share (%)" %in% colnames(df)) df[["Share (%)"]] <- sprintf("%.1f%%", df[["Share (%)"]])
    if ("Avg Spend ($)" %in% colnames(df)) df[["Avg Spend ($)"]] <- sprintf("$%.2f", df[["Avg Spend ($)"]])
    if ("Avg Basket ($)" %in% colnames(df)) df[["Avg Basket ($)"]] <- sprintf("$%.2f", df[["Avg Basket ($)"]])
    if ("Rating ★" %in% colnames(df)) df[["Rating ★"]] <- sprintf("%.2f", df[["Rating ★"]])
    if ("Repeat Rate (%)" %in% colnames(df)) df[["Repeat Rate (%)"]] <- sprintf("%.1f%%", df[["Repeat Rate (%)"]])
    if ("Avg Orders" %in% colnames(df)) df[["Avg Orders"]] <- sprintf("%.1f", df[["Avg Orders"]])
    if ("Avg Recency (d)" %in% colnames(df)) df[["Avg Recency (d)"]] <- sprintf("%.0f", df[["Avg Recency (d)"]])
    if ("Avg Age (y)" %in% colnames(df)) df[["Avg Age (y)"]] <- sprintf("%.0f", df[["Avg Age (y)"]])

    df
  }, striped = TRUE, hover = TRUE, bordered = TRUE, spacing = "s", align = "c")

  # ----------------------------------------------------------------------------
  # DYNAMIC PURCHASE PREDICTION & SCORING OBSERVERS & OUTPUTS
  # ----------------------------------------------------------------------------
  active_prediction_model <- reactive({
    prep <- active_preprocessed()
    req(prep)
    is_custom <- (input$dataset_choice == "custom" && !is.null(uploaded_dataset_holder()))

    # If using default dataset and pre-trained models exist, load instantly from disk
    rf_file <- resolve_file(file.path(config$paths$models_dir, "random_forest_model.rds"))
    glm_file <- resolve_file(file.path(config$paths$models_dir, "logistic_regression_model.rds"))
    comp_file <- resolve_file(file.path(config$paths$tables_dir, "model_comparison_metrics.csv"))
    imp_file <- resolve_file(file.path(config$paths$tables_dir, "feature_importance.csv"))

    if (!is_custom && file.exists(rf_file) && file.exists(glm_file) && file.exists(comp_file) && file.exists(imp_file)) {
      rf_mod <- readRDS(rf_file)
      glm_mod <- readRDS(glm_file)
      comp_df <- readr::read_csv(comp_file, show_col_types = FALSE)
      imp_df <- readr::read_csv(imp_file, show_col_types = FALSE)

      return(list(
        model_available = TRUE,
        target_col = prep$target_var,
        predictors = imp_df$Feature,
        glm_model = glm_mod,
        rf_model = rf_mod,
        model_comparison = comp_df,
        feature_importance = imp_df,
        train_data = prep$train_data
      ))
    }

    # Otherwise (e.g. for user-uploaded custom dataset), train dynamically
    train_data <- prep$train_data
    test_data <- prep$test_data
    cfg <- config
    cfg$modeling$rf_ntree <- 100 # Responsive fast training for dynamic uploads

    res <- train_and_evaluate_models(train_data, test_data, cfg, target_col = prep$target_var)
    res$train_data <- train_data
    return(res)
  })

  output$prediction_model_available <- reactive({
    pred <- active_prediction_model()
    isTRUE(pred$model_available)
  })
  outputOptions(output, "prediction_model_available", suspendWhenHidden = FALSE)

  output$prediction_availability_alert <- renderUI({
    pred <- active_prediction_model()
    if (!isTRUE(pred$model_available)) {
      div(class = "alert alert-warning", style = "margin-bottom: 20px; border-radius: 8px;",
          h4(icon("exclamation-triangle"), "Predictive Modeling Module Disabled"),
          p(pred$message),
          p("To enable purchase prediction, ensure your uploaded dataset contains a binary (2-class) attribute such as 'Subscription_Status' (Yes/No), 'Repeat_Purchase', or 'VIP_Status'.")
      )
    } else {
      div(class = "alert alert-success", style = "margin-bottom: 20px; border-radius: 8px;",
          span(tags$b("Target Attribute Selected: "), sprintf("'%s' | Evaluating discriminatory propensity using Logistic Regression & Random Forest ensembles.", pred$target_col))
      )
    }
  })

  output$dyn_model_comp_table <- renderTable({
    pred <- active_prediction_model()
    req(pred$model_available)
    df <- as.data.frame(pred$model_comparison)
    req(nrow(df) > 0)

    # Format percentage metrics
    for (col in c("Accuracy", "Precision", "Recall", "Specificity")) {
      if (col %in% colnames(df)) df[[col]] <- sprintf("%.1f%%", as.numeric(df[[col]]) * 100)
    }
    for (col in c("F1_Score", "ROC_AUC")) {
      if (col %in% colnames(df)) df[[col]] <- sprintf("%.3f", as.numeric(df[[col]]))
    }
    colnames(df) <- gsub("_", " ", colnames(df))
    df
  }, striped = TRUE, hover = TRUE, bordered = TRUE, spacing = "s", align = "c")

  output$dyn_feat_imp_plot <- renderPlot({
    pred <- active_prediction_model()
    req(pred$model_available)
    imp_df <- pred$feature_importance %>% head(8)

    ggplot(imp_df, aes(x = reorder(Feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
      geom_bar(stat = "identity", fill = "#1b9e77", width = 0.6) +
      coord_flip() +
      labs(x = "", y = "Random Forest Mean Decrease Gini") +
      theme_minimal(base_size = 13) +
      theme(panel.grid.minor = element_blank())
  })

  output$dyn_simulator_controls <- renderUI({
    pred <- active_prediction_model()
    req(pred$model_available)
    df <- if (!is.null(pred$train_data)) pred$train_data else active_df()
    top_preds <- pred$feature_importance$Feature[1:min(4, nrow(pred$feature_importance))]

    ctrl_list <- lapply(top_preds, function(col) {
      if (col %in% colnames(df) && is.numeric(df[[col]])) {
        val_min <- min(df[[col]], na.rm = TRUE)
        val_max <- max(df[[col]], na.rm = TRUE)
        val_med <- median(df[[col]], na.rm = TRUE)
        step_val <- if (val_max - val_min <= 2) 0.05 else 1
        sliderInput(paste0("sim_ctrl_", col), label = paste(gsub("_", " ", col), ":"),
                    min = round(val_min, 2), max = round(val_max, 2),
                    value = round(val_med, 2), step = step_val)
      } else if (col %in% colnames(df)) {
        levels_choice <- if (is.factor(df[[col]])) levels(df[[col]]) else unique(as.character(df[[col]]))
        selectInput(paste0("sim_ctrl_", col), label = paste(gsub("_", " ", col), ":"),
                    choices = levels_choice, selected = levels_choice[1])
      }
    })

    do.call(tagList, ctrl_list)
  })

  output$dyn_simulator_result <- renderUI({
    pred <- active_prediction_model()
    req(pred$model_available)
    rf_mod <- pred$rf_model
    req(rf_mod)
    prep <- active_preprocessed()
    req(prep)
    train_df <- if (!is.null(pred$train_data)) pred$train_data else prep$train_data

    # Use first row of training partition as base observation (ensures perfect schema & factors)
    new_obs <- train_df[1, , drop = FALSE]

    # 1. Properly initialize all predictor variables with correct factor levels & numeric types
    if (!is.null(rf_mod$forest$xlevels)) {
      for (col in names(rf_mod$forest$xlevels)) {
        levs <- rf_mod$forest$xlevels[[col]]
        if (is.character(levs) && length(levs) > 1 && col %in% colnames(new_obs)) {
          new_obs[[col]] <- factor(as.character(new_obs[[col]]), levels = levs)
        } else if (col %in% colnames(new_obs)) {
          new_obs[[col]] <- as.numeric(new_obs[[col]])
        }
      }
    }

    # 2. Apply user's interactive adjustments from simulator controls
    top_preds <- pred$feature_importance$Feature[1:min(4, nrow(pred$feature_importance))]
    for (col in top_preds) {
      input_val <- input[[paste0("sim_ctrl_", col)]]
      if (!is.null(input_val) && col %in% colnames(new_obs)) {
        levs <- if (!is.null(rf_mod$forest$xlevels[[col]])) rf_mod$forest$xlevels[[col]] else NULL
        if (is.character(levs) && length(levs) > 1) {
          new_obs[[col]] <- factor(as.character(input_val), levels = levs)
        } else {
          new_obs[[col]] <- as.numeric(input_val)
        }
      }
    }

    prob <- tryCatch({
      p_matrix <- predict(rf_mod, newdata = new_obs, type = "prob")
      val <- if ("1" %in% colnames(p_matrix)) as.numeric(p_matrix[1, "1"]) else as.numeric(p_matrix[1, 2])
      if (is.null(val) || is.na(val) || !is.finite(val)) 0.50 else val
    }, error = function(e) {
      cat("[SIMULATOR PREDICT ERROR]:", e$message, "\n")
      0.50
    })

    if (is.null(prob) || length(prob) == 0 || is.na(prob) || !is.finite(prob)) {
      prob <- 0.50
    }

    prob_pct <- round(prob * 100, 1)

    tier_badge <- if (prob >= 0.65) {
      span("HIGH PROPENSITY (VIP / PRIORITY CONVERSION)", style = "background-color:#15803d; color:#ffffff; font-weight:700; font-size:0.85rem; padding:6px 12px; border-radius:4px;")
    } else if (prob >= 0.40) {
      span("MODERATE PROPENSITY (NURTURE COHORT)", style = "background-color:#b45309; color:#ffffff; font-weight:700; font-size:0.85rem; padding:6px 12px; border-radius:4px;")
    } else {
      span("LOW PROPENSITY (DORMANT / AT RISK)", style = "background-color:#b91c1c; color:#ffffff; font-weight:700; font-size:0.85rem; padding:6px 12px; border-radius:4px;")
    }

    div(
      p(style = "margin-bottom: 8px;",
        tags$b("Estimated Propensity Probability: "),
        span(sprintf("%.1f%%", prob_pct), style = "font-size:1.45rem; font-weight:bold; color:#1a365d; margin-left: 6px;")
      ),
      p(style = "margin-bottom: 8px;",
        tags$b("Customer Propensity Status: "),
        tier_badge
      ),
      p(style = "font-size:0.85rem; color:#64748b; margin-bottom: 0;",
        sprintf("Live machine learning scoring powered dynamically by Random Forest (%s trees).",
                if (!is.null(rf_mod$ntree)) rf_mod$ntree else config$modeling$rf_ntree))
    )
  })

  output$recommendations_table <- renderTable({
    seg <- segmentation_reactive()
    pred <- active_prediction_model()
    recs <- generate_business_recommendations(seg, pred, config)
    recs %>% select(Strategic_Pillar, Target_Audience, Proposed_Business_Action, Expected_Business_Benefit)
  })
}

# Run Application
shinyApp(ui = ui, server = server)
