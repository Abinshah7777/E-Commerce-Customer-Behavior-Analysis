# ==============================================================================
# DATA LOADING MODULE: R/data_loading.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# ==============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(readxl)
  library(dplyr)
})

#' Load Dataset from File (CSV or Excel)
#'
#' Supports CSV (.csv) with encoding fallbacks and Excel (.xlsx, .xls) formats.
#'
#' @param file_path Character: Path to the dataset file
#' @return A data.frame containing the loaded records
load_raw_data <- function(file_path = file.path("data", "raw", "customer_data.csv")) {
  if (!file.exists(file_path)) {
    # Check alternate kaggle location
    alt_path <- file.path("data", "raw", "shopping_trends.csv")
    if (file.exists(alt_path)) {
      file_path <- alt_path
    } else {
      stop(sprintf("[ERROR] Dataset file not found at: %s", file_path))
    }
  }

  ext <- tolower(tools::file_ext(file_path))

  if (ext %in% c("xlsx", "xls")) {
    cat(sprintf("[DATA LOADING] Loading Excel workbook from '%s'...\n", file_path))
    df <- tryCatch({
      as.data.frame(readxl::read_excel(file_path))
    }, error = function(e) {
      stop(sprintf("[ERROR] Failed to read Excel file '%s': %s", file_path, e$message))
    })
  } else {
    cat(sprintf("[DATA LOADING] Loading CSV dataset from '%s'...\n", file_path))
    # Try reading with UTF-8, then fallback to ISO-8859-1 (latin1)
    df <- tryCatch({
      as.data.frame(readr::read_csv(file_path, show_col_types = FALSE))
    }, error = function(e) {
      tryCatch({
        as.data.frame(read.csv(file_path, stringsAsFactors = FALSE, fileEncoding = "ISO-8859-1"))
      }, error = function(e2) {
        stop(sprintf("[ERROR] Failed to read CSV file '%s': %s", file_path, e2$message))
      })
    })
  }

  cat(sprintf("[DATA LOADING] Successfully loaded %d observations across %d columns.\n",
              nrow(df), ncol(df)))
  return(df)
}

#' Load and Validate User-Uploaded Custom Dataset
#'
#' @param file_path Character: Temporary or persistent file path of the uploaded file
#' @param original_name Character: Original filename uploaded by user
#' @return A list containing the loaded data.frame and validation summary
load_custom_dataset <- function(file_path, original_name = basename(file_path)) {
  if (is.null(file_path) || file_path == "" || !file.exists(file_path)) {
    return(list(
      success = FALSE,
      data = NULL,
      message = "No valid file was provided or file does not exist on disk."
    ))
  }

  ext <- tolower(tools::file_ext(original_name))
  if (!ext %in% c("csv", "xlsx", "xls")) {
    return(list(
      success = FALSE,
      data = NULL,
      message = sprintf("Unsupported format '.%s'. Please upload a CSV (.csv) or Excel (.xlsx, .xls) file.", ext)
    ))
  }

  # Load file safely
  df <- tryCatch({
    if (ext %in% c("xlsx", "xls")) {
      as.data.frame(readxl::read_excel(file_path))
    } else {
      # Try readr first, then base read.csv with latin1
      tryCatch({
        as.data.frame(readr::read_csv(file_path, show_col_types = FALSE))
      }, error = function(e1) {
        as.data.frame(read.csv(file_path, stringsAsFactors = FALSE, fileEncoding = "ISO-8859-1"))
      })
    }
  }, error = function(e) {
    return(NULL)
  })

  if (is.null(df) || nrow(df) == 0) {
    return(list(
      success = FALSE,
      data = NULL,
      message = "The uploaded file could not be parsed or contains zero records."
    ))
  }

  # Validate dataset requirements
  val <- validate_dataset(df)
  if (!val$is_valid) {
    return(list(
      success = FALSE,
      data = NULL,
      message = val$message,
      validation = val
    ))
  }

  return(list(
    success = TRUE,
    data = df,
    message = sprintf("Successfully loaded '%s' (%d rows, %d columns).", original_name, nrow(df), ncol(df)),
    validation = val
  ))
}

#' Comprehensive Dataset Validation
#'
#' Assesses dataset suitability for exploratory data analysis, clustering, and predictive modeling.
#'
#' @param df Data frame to inspect
#' @return A list with validation findings
validate_dataset <- function(df) {
  if (is.null(df) || !is.data.frame(df)) {
    return(list(is_valid = FALSE, message = "Provided object is not a valid tabular data frame."))
  }

  n_rows <- nrow(df)
  n_cols <- ncol(df)

  if (n_rows < 5) {
    return(list(is_valid = FALSE, message = sprintf("Dataset has only %d row(s). Minimum 5 observations required for analysis.", n_rows)))
  }

  if (n_cols < 2) {
    return(list(is_valid = FALSE, message = sprintf("Dataset has only %d column. Minimum 2 columns required for multi-dimensional analysis.", n_cols)))
  }

  # Identify column types
  numeric_cols <- names(df)[sapply(df, is.numeric)]
  char_cols <- names(df)[sapply(df, function(x) is.character(x) || is.factor(x))]
  date_cols <- names(df)[sapply(df, function(x) inherits(x, "Date") || inherits(x, "POSIXt"))]

  # Identify potential binary target columns (for predictive modeling)
  potential_targets <- c()
  for (col in names(df)) {
    vals <- na.omit(unique(df[[col]]))
    if (length(vals) == 2) {
      potential_targets <- c(potential_targets, col)
    }
  }

  # Identify missing values
  missing_counts <- colSums(is.na(df))
  total_missing <- sum(missing_counts)

  has_numeric <- length(numeric_cols) >= 1
  can_cluster <- length(numeric_cols) >= 2
  can_predict <- length(potential_targets) >= 1 && length(numeric_cols) >= 1

  return(list(
    is_valid = TRUE,
    n_rows = n_rows,
    n_cols = n_cols,
    column_names = names(df),
    numeric_cols = numeric_cols,
    categorical_cols = char_cols,
    date_cols = date_cols,
    potential_targets = potential_targets,
    total_missing = total_missing,
    can_cluster = can_cluster,
    can_predict = can_predict,
    message = "Dataset passed all validation integrity checks."
  ))
}
