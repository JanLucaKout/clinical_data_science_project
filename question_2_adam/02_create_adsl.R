# ==============================================================================
# Script: 02_create_adsl.R
# Objective: Create ADaM ADSL dataset using {admiral}
# Required Packages: admiral, pharmaverseraw, dplyr

# ==============================================================================
# Libraries
library(admiral)
library(pharmaversesdtm)
library(dplyr)

# ==============================================================================
# Read in Data
data("dm")
data("ds")
data("ex")
data("ae")
data("vs")

dm <- convert_blanks_to_na(dm)
ds <- convert_blanks_to_na(ds)
ex <- convert_blanks_to_na(ex)
ae <- convert_blanks_to_na(ae)
vs <- convert_blanks_to_na(vs)

# ==============================================================================
# Start ADSL from DM
adsl <- dm

# ==============================================================================
# Derive AGEGR9 and AGEGR9N
agegr9_lookup <- exprs(
  ~condition,            ~AGEGR9, ~AGEGR9N,
  is.na(AGE),          "Missing",        4,
  AGE < 18,                "<18",        1,
  between(AGE, 18, 50),  "18-50",        2,
  !is.na(AGE),             ">50",        3
)

adsl <- derive_vars_cat(
  dataset = adsl,
  definition = agegr9_lookup
)

# ==============================================================================
# Derive TRTSDTM and TRTSTMF
adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ex,
    # Filter for valid Dosage: Dose > 0 OR (Dose == 0 AND Placebo)
    # Ensure the Datepart is complete (>= length 10)
    filter_add = (EXDOSE > 0 | (EXDOSE == 0 & str_detect(EXTRT, "PLACEBO"))) & 
      nchar(EXSTDTC) >= 10,
    order = exprs(EXSTDTC),
    mode = "first",
    new_vars = exprs(
      # Convert to Datetime with specific imputation
      TRTSDTM = convert_dtc_to_dtm(
        EXSTDTC, 
        highest_imputation = "h", 
        time_imputation = "00:00:00"
      ),
      
      # Imputation Flag
      TRTSTMF = case_when(
        nchar(EXSTDTC) == 16 ~ "M",
        nchar(EXSTDTC) < 16 ~ "H",
        TRUE ~ NA_character_
      )
    ),
    by_vars = exprs(STUDYID, USUBJID)
  ) %>%
  
  mutate(
    TRTSDTM = format(TRTSDTM, "%Y-%m-%dT%H:%M:%S")
  )

# ==============================================================================
# Derive ITTFL
adsl <- adsl %>%
  mutate(
    ITTFL = if_else(!is.na(ARM) & ARM != "", "Y", "N")
  )

# ==============================================================================
# Derive STAVLDT

# Last Vital Date
vs_date <- vs %>%
  filter(!is.na(VSDTC) & nchar(VSDTC) >= 10 & (!is.na(VSSTRESN) | !is.na(VSSTRESC))) %>%
  group_by(USUBJID) %>%
  summarise(LST_VS = max(as.Date(substr(VSDTC, 1, 10)), na.rm = TRUE))

# Last AE Onset Date
ae_date <- ae %>%
  filter(!is.na(AESTDTC) & nchar(AESTDTC) >= 10) %>%
  group_by(USUBJID) %>%
  summarise(LST_AE = max(as.Date(substr(AESTDTC, 1, 10)), na.rm = TRUE))

# Last Disposition Date
ds_date <- ds %>%
  filter(!is.na(DSDTC) & nchar(DSDTC) >= 10) %>%
  group_by(USUBJID) %>%
  summarise(LST_DS = max(as.Date(substr(DSDTC, 1, 10)), na.rm = TRUE))

# Last Treatment Date
ex_date <- ex %>%
  filter(!is.na(EXENDTC) & nchar(EXENDTC) >= 10) %>%
  group_by(USUBJID) %>%
  summarise(LST_EX = max(as.Date(substr(EXENDTC, 1, 10)), na.rm = TRUE))

# Combine all and calculate MAX
adsl <- adsl %>%
  left_join(vs_date, by = "USUBJID") %>%
  left_join(ae_date, by = "USUBJID") %>%
  left_join(ds_date, by = "USUBJID") %>%
  left_join(ex_date, by = "USUBJID") %>%
  rowwise() %>%
  mutate(
    STAVLDT = max(c(LST_VS, LST_AE, LST_DS, LST_EX), na.rm = TRUE)
  ) %>%
  ungroup() 

# ==============================================================================
# STAVLDT Formatting and Selecting
adsl <- adsl %>%
  mutate(
    STAVLDT = as.Date(STAVLDT)
  ) %>%
  select(STUDYID, USUBJID, AGEGR9, AGEGR9N, TRTSDTM, TRTSTMF, ITTFL, STAVLDT)

# ==============================================================================
# Save Deliverable
if(!dir.exists("question_2_adam")) dir.create("question_2_adam")
write.csv(adsl, "question_2_adam/adsl.csv", row.names = FALSE)

# ==============================================================================
# Completion and Logging
sink("question_2_adam/02_execution_log.txt")
cat("Execution Log for Question 2 - Create ADaM ADSL dataset using {admiral}\n")
print(head(adsl))
sink()

print("Question 2 Advanced ADSL Completed.")
# ==============================================================================