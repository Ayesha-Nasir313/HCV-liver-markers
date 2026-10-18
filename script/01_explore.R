# =============================================================================
# 01_explore.R
# Project : Liver function markers across stages of Hepatitis C infection
# Purpose : First look at the raw data: size, column types, groups, missing values
# Input   : data/hcv_data.csv  (UCI "HCV data", file hcvdat0.csv, renamed;
#           Lichtinghagen, Klawonn & Hoffmann 2020, doi:10.24432/C5D612)
# Output  : none (results are printed to the Console)
# =============================================================================

library(readr)
library(dplyr)

hcv <- read_csv("data/hcv_data.csv", show_col_types = FALSE)

# ---- Structure ----
head(hcv)
str(hcv)
summary(hcv)     # range, mean and number of missing values for each column
nrow(hcv)
ncol(hcv)

# ---- Groups ----
hcv %>% count(Category)
hcv %>% count(Sex)

# ---- Notes ----
# 1. 615 people and 14 columns: patient number, Category, Age, Sex and
#    10 laboratory tests.
# 2. Category: Blood Donor 533, suspect Blood Donor 7, Hepatitis 24,
#    Fibrosis 21, Cirrhosis 30.
# 3. Category combines a code and a diagnosis separated by "=" (e.g. "1=Hepatitis").
#    They are split into two columns in 02_clean.R.
# 4. Missing values occur in ALB, ALP, ALT, CHOL and PROT.
# 5. "Suspect blood donors" (code 0s) have abnormal laboratory values but no
#    diagnosis, so they are neither clearly healthy nor clearly ill. They are
#    removed in 02_clean.R to keep the healthy control group clean.
# 6. Group sizes are very unequal (533 donors vs 75 patients, only 21-30 per
#    disease stage). This limits the power of comparisons between patient stages.