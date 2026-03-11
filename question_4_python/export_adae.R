# ==============================================================================
# Script: export_adae_for_python.R
# Objective: Load ADAE from pharmaverseadam and export as CSV for GenAI task
# Required Packages: pharmaverseraw

# ==============================================================================
# Libraries
library(pharmaverseadam)

# ==============================================================================
# Read in data
adae <- pharmaverseadam::adae

# ==============================================================================
# Define File Path
output_path <- "question_4_python/adae.csv"

# ==============================================================================
# Save Deliverable
write.csv(adae, file = output_path, row.names = FALSE)

# ==============================================================================
# Completion Check
if (file.exists(output_path)) {
  print(paste("Success! ADAE exported for Python at:", output_path))
} else {
  print("Error: File was not saved.")
}
# ==============================================================================