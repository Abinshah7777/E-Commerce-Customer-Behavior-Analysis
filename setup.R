# ==============================================================================
# SETUP MODULE: setup.R
# Project: E-Commerce Customer Behavior Analysis
# Subtitle: Customer Segmentation and Purchase Prediction
# Subject: Big Data Analytics – R Programming Mini Project
# Academic Year: 2026–2027
# Institution: Mentor Engineering College
# ==============================================================================

cat("\n==================================================================\n")
cat("   E-COMMERCE CUSTOMER BEHAVIOR ANALYSIS: SETUP & ENVIRONMENT    \n")
cat("==================================================================\n\n")

# 1. R Version Verification
r_version <- paste(R.version$major, R.version$minor, sep = ".")
cat(sprintf("[INFO] Current R Version: %s (%s)\n", r_version, R.version$platform))

# 2. Required Packages
required_packages <- c(
  "dplyr",
  "tidyr",
  "readr",
  "ggplot2",
  "scales",
  "cluster",
  "randomForest",
  "shiny"
)

cat("[INFO] Checking required R packages...\n")
installed_pkgs <- rownames(installed.packages())
missing_pkgs <- setdiff(required_packages, installed_pkgs)

if (length(missing_pkgs) > 0) {
  cat(sprintf("[INFO] Installing missing packages: %s\n", paste(missing_pkgs, collapse = ", ")))
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
} else {
  cat("[SUCCESS] All required packages are already installed.\n")
}

# 3. Verify Package Loading
cat("\n[INFO] Verifying package loading...\n")
all_loaded <- TRUE
for (pkg in required_packages) {
  loaded <- suppressPackageStartupMessages(require(pkg, character.only = TRUE, quietly = TRUE))
  if (loaded) {
    ver <- as.character(packageVersion(pkg))
    cat(sprintf("  ✓ %-15s [v%s] Loaded\n", pkg, ver))
  } else {
    cat(sprintf("  ✗ %-15s Failed to load\n", pkg))
    all_loaded <- FALSE
  }
}

if (!all_loaded) {
  stop("[ERROR] One or more required packages could not be loaded. Please inspect your R library.")
}

# 4. Project Directory Tree Verification
dirs <- c(
  file.path("data", "raw"),
  file.path("data", "processed"),
  "R",
  file.path("outputs", "plots"),
  file.path("outputs", "tables"),
  file.path("outputs", "models"),
  file.path("outputs", "reports"),
  "tests",
  "docs",
  "app"
)

cat("\n[INFO] Verifying project directories...\n")
for (d in dirs) {
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
    cat(sprintf("  + Created directory: %s\n", d))
  } else {
    cat(sprintf("  ✓ Directory exists:  %s\n", d))
  }
}

cat("\n==================================================================\n")
cat("   ENVIRONMENT SETUP COMPLETED SUCCESSFULLY!                      \n")
cat("   You can now run: Rscript main.R                                \n")
cat("==================================================================\n\n")
