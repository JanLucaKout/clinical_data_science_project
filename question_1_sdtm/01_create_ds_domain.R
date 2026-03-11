# ==============================================================================
# Script: 01_create_ds_domain.R
# Objective: Create SDTM DS domain by deriving USUBJID and mapping raw data
# Required Packages: sdtm.oak, dplyr, pharmaverseraw

# ==============================================================================
# Libraries
library(sdtm.oak)
library(dplyr)
library(pharmaverseraw)

# ==============================================================================
# Read in data
ds_raw <- pharmaverseraw::ds_raw

# ==============================================================================
# Create oak_id_vars
ds_raw <- ds_raw %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "ds_raw"
  )

# ==============================================================================
# Read in CT
study_ct <- read.csv("question_1_sdtm/sdtm_ct.csv")

# ==============================================================================
# Map Topic Variable DSTERM
ds <-
  assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "IT.DSTERM",
    tgt_var = "DSTERM",
    id_vars = oak_id_vars()
  )

# ==============================================================================
# Step-by-Step Mapping with sdtm.oak
ds <- ds %>%
  
  # Map DSDECOD from IT.DSDECOD using assign_ct
  assign_ct(
    raw_dat = ds_raw, 
    raw_var = "IT.DSDECOD", 
    tgt_var = "DSDECOD",
    ct_spec = study_ct,
    ct_clst = "C66727",
    id_vars = oak_id_vars()
  ) %>%
  
  # Map VISITNUM from INSTANCE using assign_ct
  assign_ct(
    raw_dat = ds_raw, 
    raw_var = "INSTANCE", 
    tgt_var = "VISITNUM",
    ct_spec = study_ct,
    ct_clst = "VISITNUM",
    id_vars = oak_id_vars()
  ) %>%
  
  # Map VISIT from INSTANCE using assign_ct
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISIT",
    ct_spec = study_ct,
    ct_clst = "VISIT",
    id_vars = oak_id_vars()
  ) %>%
  
  # Map DSDTC using assign_datetime algorithm
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = "DSDTCOL",
    tgt_var = "DSDTC",
    raw_fmt = "m-d-y",
    id_vars = oak_id_vars()
  ) %>%
  
  # Map DSSTDTC using assign_datetime algorithm
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = "IT.DSSTDAT",
    tgt_var = "DSSTDTC",
    raw_fmt = "m-d-y",
    id_vars = oak_id_vars()
  )

# ==============================================================================
# Create SDTM derived variables
ds <- ds %>%
  dplyr::mutate(
    STUDYID = ds_raw$STUDY,
    DOMAIN  = "DS",
    USUBJID = paste0("01-", patient_number),
    DSCAT   = "DISPOSITION EVENT",
    DSTERM = toupper(DSTERM),
    VISIT = toupper(VISIT),
    # Remove all non-numeric values in VISITNUM
    VISITNUM = suppressWarnings(as.numeric(VISITNUM))
  ) %>%
  
  arrange(USUBJID, DSSTDTC) %>%
  
  derive_seq(
    tgt_var = "DSSEQ",
    rec_vars = c("USUBJID", "DSTERM")
  ) %>%
  
  derive_study_day(
    sdtm_in = .,
    dm_domain = dm,
    tgdt = "DSSTDTC", 
    refdt = "RFSTDTC", 
    study_day_var = "DSSTDY"
    ) %>%
  
  # Filter out empty DSTERM
  filter(!is.na(DSTERM)) %>%

  select(STUDYID, DOMAIN, USUBJID, DSSEQ, DSTERM, DSDECOD, DSCAT, VISITNUM, 
         VISIT, DSDTC, DSSTDTC, DSSTDY)

# ==============================================================================
# Save Deliverable
if(!dir.exists("question_1_sdtm")) dir.create("question_1_sdtm")
write.csv(ds, "question_1_sdtm/ds_domain.csv", row.names = FALSE)

# ==============================================================================
# Completion and Logging
sink("question_1_sdtm/01_execution_log.txt")
cat("Execution Log for Question 1 - SDTM DS Creation\n")
print(head(ds))
sink()

print("Question 1 completed: Dataset and log saved in 'question_1_sdtm/'")
# ==============================================================================