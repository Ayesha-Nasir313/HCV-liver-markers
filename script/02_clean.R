# =============================================================================
# 02_clean.R
# Purpose : Clean the raw data and save an analysis-ready file
# Input   : data/hcv_data.csv   (raw file, never modified)
# Output  : data/hcv_clean.csv  (608 people)
# =============================================================================

library(readr)
library(dplyr)
library(tidyr)

# The first column (patient number) has no name in the file; readr calls it ...1
hcv <- read_csv("data/hcv_data.csv", show_col_types = FALSE)

hcv <- hcv %>%
  rename(ID = ...1) %>%
  # "1=Hepatitis" -> Code "1" and Diagnosis "Hepatitis"
  separate(Category, into = c("Code", "Diagnosis"), sep = "=") %>%
  # Remove the 7 suspect blood donors (abnormal values, no diagnosis)
  filter(Code != "0s") %>%
  mutate(
    Group = if_else(Diagnosis == "Blood Donor", "Healthy", "HCV patient"),
    Sex   = case_when(Sex %in% c("f", "Female") ~ "Female",
                      Sex %in% c("m", "Male")   ~ "Male"),
    # Stages in disease order instead of alphabetical order
    Diagnosis = factor(Diagnosis,
                       levels = c("Blood Donor", "Hepatitis", "Fibrosis", "Cirrhosis"))
  )

# ---- Checks ----
nrow(hcv)                    # expected: 608
hcv %>% count(Diagnosis)     # expected: 533 / 24 / 21 / 30
hcv %>% count(Sex)           # expected: Female and Male only, no NA
colSums(is.na(hcv))          # missing values in each column

# Highest creatinine values, checked for biological plausibility
hcv %>%
  arrange(desc(CREA)) %>%
  select(ID, Diagnosis, Age, Sex, CREA) %>%
  head()

# Missing ALP in each group
hcv %>%
  group_by(Diagnosis) %>%
  summarise(ALP_missing = sum(is.na(ALP)))

write_csv(hcv, "data/hcv_clean.csv")

# ---- Cleaning decisions ----
# - The raw file is never overwritten; the cleaned data are saved as a new file.
# - Seven suspect blood donors were removed, leaving 608 people
#   (Blood Donor 533, Hepatitis 24, Fibrosis 21, Cirrhosis 30).
# - Missing values (ALB 1, ALP 18, ALT 1, CHOL 10, PROT 1) were kept, because a
#   person missing one test still has valid results for the others. Each
#   calculation excludes missing values only for the test concerned.
# - Missing ALP occurs only in patients (Hepatitis 3 of 24, Fibrosis 9 of 21,
#   Cirrhosis 6 of 30), so ALP results for the patient stages are less reliable.
# - Extreme values were kept when biologically possible. The highest creatinine
#   values (1079.1, 519.0 and 485.9 umol/L) are all in cirrhosis patients and fit
#   severe kidney failure in advanced liver disease (e.g. hepatorenal syndrome).
# - Disease stages are stored as a factor in disease order:
#   Blood Donor -> Hepatitis -> Fibrosis -> Cirrhosis.