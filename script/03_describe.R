# =============================================================================
# 03_describe.R
# Purpose : Describe each group (age, sex), summarise every laboratory test by
#           disease stage, and check the quality of the enzyme results
# Input   : data/hcv_clean.csv
# Output  : data/group_summary.csv, data/median_table.csv,
#           data/median_iqr_table.csv
# =============================================================================

library(readr)
library(dplyr)
library(tidyr)

hcv <- read_csv("data/hcv_clean.csv", show_col_types = FALSE)

# CSV files do not store factor levels, so the stage order is set again
hcv <- hcv %>%
  mutate(Diagnosis = factor(Diagnosis,
                            levels = c("Blood Donor", "Hepatitis", "Fibrosis", "Cirrhosis")))

# ---- Study groups ----
group_summary <- hcv %>%
  group_by(Diagnosis) %>%
  summarise(
    n            = n(),
    mean_age     = round(mean(Age), 1),
    median_age   = median(Age),
    percent_male = round(mean(Sex == "Male") * 100, 1),
    ALP_missing  = sum(is.na(ALP))
  )
group_summary

# ---- Laboratory tests: median and interquartile range (IQR) per stage ----
# Medians are used because laboratory values are skewed, with extreme values
# in patients
hcv_long <- hcv %>%
  pivot_longer(cols = ALB:PROT, names_to = "Test", values_to = "Value")

lab_summary <- hcv_long %>%
  group_by(Test, Diagnosis) %>%
  summarise(
    n       = sum(!is.na(Value)),
    median  = median(Value, na.rm = TRUE),
    q1      = quantile(Value, 0.25, na.rm = TRUE),
    q3      = quantile(Value, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

# Medians: tests as rows, stages as columns
median_table <- lab_summary %>%
  select(Test, Diagnosis, median) %>%
  pivot_wider(names_from = Diagnosis, values_from = median)
median_table

# Same table as "median (Q1-Q3)", the usual format in clinical papers
median_iqr_table <- lab_summary %>%
  mutate(summary = sprintf("%.1f (%.1f-%.1f)", median, q1, q3)) %>%
  select(Test, Diagnosis, summary) %>%
  pivot_wider(names_from = Diagnosis, values_from = summary)
median_iqr_table

# ---- Globulin (total protein minus albumin) ----
# Tests whether a rise in globulins keeps total protein stable while albumin falls
hcv %>%
  mutate(GLOB = PROT - ALB) %>%
  group_by(Diagnosis) %>%
  summarise(median_GLOB = median(GLOB, na.rm = TRUE))

# ---- Data-quality checks on the enzymes ----
# Number of very low ALT (< 10 U/L) and low ALP (< 40 U/L) results per group
hcv %>%
  group_by(Diagnosis) %>%
  summarise(
    ALT_below_10 = sum(ALT < 10, na.rm = TRUE),
    ALP_below_40 = sum(ALP < 40, na.rm = TRUE),
    ALP_measured = sum(!is.na(ALP))
  )

# Lowest ALT values in cirrhosis
hcv %>%
  filter(Diagnosis == "Cirrhosis") %>%
  arrange(ALT) %>%
  select(ID, Age, Sex, ALT, AST) %>%
  head(10)

# Range of patient numbers (ID) in each group
hcv %>%
  group_by(Diagnosis) %>%
  summarise(first_ID = min(ID), last_ID = max(ID))

write_csv(group_summary, "data/group_summary.csv")
write_csv(median_table, "data/median_table.csv")
write_csv(median_iqr_table, "data/median_iqr_table.csv")

# ---- Notes (numbers produced by this script) ----
# Groups: hepatitis patients are the youngest (mean age 38.7 years; donors 47.1,
#   fibrosis 52.3, cirrhosis 53.5). Percent male: 59.7, 83.3, 61.9, 66.7.
# Medians, donors -> hepatitis -> fibrosis -> cirrhosis:
#   AST  24.8 -> 47.2  -> 70.0 -> 92.9  U/L
#   GGT  21.4 -> 45.55 -> 72.2 -> 96.35 U/L
#   BIL  6.9  -> 13.0  -> 13.0 -> 34.0  umol/L
#   ALB  42.2 -> 43.5  -> 41.0 -> 33.0  g/L
#   CHE  8.35 -> 9.51  -> 8.59 -> 3.43  kU/L
#   CHOL 5.41 -> 5.06  -> 4.58 -> 3.87  mmol/L
# Globulin medians: 30.0, 30.1, 36.0, 36.95 g/L (higher in fibrosis and cirrhosis).
# Data quality:
#   - 18 of 30 cirrhosis patients have ALT below 10 U/L (lowest 0.9 U/L).
#   - 16 of the 21 hepatitis patients with an ALP result have ALP below 40 U/L,
#     compared with 17 of 533 donors.
#   - Patients have IDs 541-615, after all donors (IDs 1-533).
#   These patterns are unusual biologically and may reflect differences in how
#   patient and donor samples were collected or measured (see report, Limitations).