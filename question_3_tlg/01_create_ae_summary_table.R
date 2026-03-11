# ==============================================================================
# Script: 01_create_ae_summary_table.R
# Objective: Create outputs for adverse events summary using the ADAE dataset
# the ADAE dataset and {gtsummary}.
# Required Packages: pharmaverseraw, gt

# ==============================================================================
# Libraries
library(pharmaverseadam)
library(gt)

# ==============================================================================
# Read in data
adsl <- pharmaverseadam::adsl
adae <- pharmaverseadam::adae

# ==============================================================================
# Ensure output directory exists
if(!dir.exists("question_3_tlg")) dir.create("question_3_tlg")

# ==============================================================================
# Pre-processing
adae <- adae |>
  filter(
    TRTEMFL == "Y"
  )

# ==============================================================================
# Create the Table
tbl <- adae |>
  tbl_hierarchical(
    variables = c(AESOC, AETERM),
    by = ACTARM,
    id = USUBJID,
    denominator = adsl,
    overall_row = TRUE,
    label = "..ard_hierarchical_overall.." ~ "Treatement Emergent AEs"
  )

# ==============================================================================
# Save Deliverable
tbl |> 
  as_gt() |> 
  gtsave(filename = "question_3_tlg/ae_summary_table.html")

# ==============================================================================
# Completion and Logging
log_file <- "question_3_tlg/01_create_ae_summary_table.txt"
sink(log_file)

cat("====================================================================\n")
cat("Execution Log: 01_create_ae_summary_table.R\n")
cat("DateTime: ", as.character(Sys.time()), "\n")
cat("====================================================================\n\n")

cat("DATA SUMMARY:\n")
cat("Number of subjects in ADSL (Denominator): ", nrow(adsl), "\n")
cat("Number of Treatment-Emergent AEs (TRTEMFL='Y'): ", nrow(adae), "\n\n")

cat("CHECKING HIERARCHY (First 5 rows of input data):\n")
print(head(adae[, c("USUBJID", "AESOC", "AETERM", "ACTARM")], 5))

cat("\n====================================================================\n")
cat("STATUS: Table generated and exported to HTML successfully.\n")
cat("====================================================================\n")

sink() # This closes the log file

print("Hierarchical AE Table successfully exported as HTML!")
# ==============================================================================