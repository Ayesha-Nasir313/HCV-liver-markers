# =============================================================================
# 05_statistics.R
# Purpose : Statistical tests of laboratory values between groups and across
#           disease stages, and a check of age and sex as confounders
# Input   : data/hcv_clean.csv
# Output  : data/results_healthy_vs_hcv.csv, data/results_across_stages.csv,
#           data/results_patient_trend.csv, data/results_pairwise.csv
# Methods : Rank-based tests, because laboratory values are skewed.
#           Benjamini-Hochberg (BH) correction for multiple testing;
#           a result is called significant if the adjusted p-value is < 0.05.
# =============================================================================

library(readr)
library(dplyr)
library(tidyr)

hcv <- read_csv("data/hcv_clean.csv", show_col_types = FALSE)
hcv <- hcv %>%
  mutate(Diagnosis = factor(Diagnosis,
                            levels = c("Blood Donor", "Hepatitis", "Fibrosis", "Cirrhosis")))

hcv_long <- hcv %>%
  pivot_longer(cols = ALB:PROT, names_to = "Test", values_to = "Value")

lab_tests <- c("ALB", "ALP", "ALT", "AST", "BIL", "CHE", "CHOL", "CREA", "GGT", "PROT")

# ---- 1. Healthy donors vs all HCV patients (Wilcoxon rank-sum test) ----
results_2groups <- hcv_long %>%
  group_by(Test) %>%
  summarise(
    median_healthy = median(Value[Group == "Healthy"], na.rm = TRUE),
    median_hcv     = median(Value[Group == "HCV patient"], na.rm = TRUE),
    p_value        = wilcox.test(Value[Group == "Healthy"],
                                 Value[Group == "HCV patient"],
                                 exact = FALSE)$p.value,
    .groups = "drop"
  ) %>%
  mutate(
    p_adj       = p.adjust(p_value, method = "BH"),
    direction   = if_else(median_hcv > median_healthy, "higher in HCV", "lower in HCV"),
    significant = if_else(p_adj < 0.05, "yes", "no")
  ) %>%
  arrange(p_adj)
results_2groups

# ---- 2. Differences among all four groups (Kruskal-Wallis test) ----
# Donors are included, so a significant result can come from the healthy vs
# patient difference alone. Section 3 tests change across the disease stages.
results_stages <- hcv_long %>%
  group_by(Test) %>%
  summarise(
    p_value = kruskal.test(Value, Diagnosis)$p.value,
    .groups = "drop"
  ) %>%
  mutate(
    p_adj       = p.adjust(p_value, method = "BH"),
    significant = if_else(p_adj < 0.05, "yes", "no")
  ) %>%
  arrange(p_adj)
results_stages

# ---- 3. Trend with disease stage, patients only (Spearman correlation) ----
# Code: 1 = Hepatitis, 2 = Fibrosis, 3 = Cirrhosis. Donors are excluded.
# rho runs from -1 to +1: negative = falls with stage, positive = rises with stage.
results_trend <- hcv_long %>%
  filter(Group == "HCV patient") %>%
  group_by(Test) %>%
  summarise(
    n       = sum(!is.na(Value)),
    rho     = cor.test(Value, Code, method = "spearman", exact = FALSE)$estimate,
    p_value = cor.test(Value, Code, method = "spearman", exact = FALSE)$p.value,
    .groups = "drop"
  ) %>%
  mutate(
    rho         = round(rho, 2),
    p_adj       = p.adjust(p_value, method = "BH"),
    direction   = if_else(rho > 0, "rises with stage", "falls with stage"),
    significant = if_else(p_adj < 0.05, "yes", "no")
  ) %>%
  arrange(p_adj)
results_trend

# AST/ALT ratio, calculated for each patient
patients <- hcv %>%
  filter(Group == "HCV patient") %>%
  mutate(AST_ALT_ratio = AST / ALT)
cor.test(patients$AST_ALT_ratio, patients$Code, method = "spearman", exact = FALSE)

# ---- 4. Pairwise comparisons of all groups, all tests (Wilcoxon rank-sum) ----
# 6 pairs of groups x 10 tests = 60 comparisons, BH-corrected together.
# pairwise_one_test() returns the 6 unadjusted p-values for one test as rows.
pairwise_one_test <- function(test_name) {
  p <- pairwise.wilcox.test(hcv[[test_name]], hcv$Diagnosis,
                            p.adjust.method = "none", exact = FALSE)$p.value
  as.data.frame(as.table(p)) %>%
    filter(!is.na(Freq)) %>%
    transmute(Test    = test_name,
              Group_1 = as.character(Var2),
              Group_2 = as.character(Var1),
              p_value = Freq)
}

results_pairwise <- bind_rows(lapply(lab_tests, pairwise_one_test)) %>%
  mutate(
    p_adj       = p.adjust(p_value, method = "BH"),
    significant = if_else(p_adj < 0.05, "yes", "no")
  )
results_pairwise

# ---- 5. Age and sex as possible confounders ----
kruskal.test(Age ~ Diagnosis, data = hcv)     # does age differ between groups?
table(hcv$Diagnosis, hcv$Sex)
chisq.test(table(hcv$Diagnosis, hcv$Sex))     # does sex differ between groups?

# Albumin in cirrhosis vs donors, before and after adjusting for age and sex.
# A linear model is used for albumin because its distribution is close to symmetric.
model_1 <- lm(ALB ~ Diagnosis, data = hcv)
model_2 <- lm(ALB ~ Diagnosis + Age + Sex, data = hcv)
summary(model_1)
summary(model_2)

# ---- Save results ----
write_csv(results_2groups,  "data/results_healthy_vs_hcv.csv")
write_csv(results_stages,   "data/results_across_stages.csv")
write_csv(results_trend,    "data/results_patient_trend.csv")
write_csv(results_pairwise, "data/results_pairwise.csv")

# ---- Notes (results of this script) ----
# 1. Healthy vs patients: 9 of 10 tests differ after BH correction; only PROT
#    does not (adjusted p = 0.053). Higher in patients: AST, GGT, BIL.
#    Lower in patients: CHOL, ALP, CHE, ALB, CREA, ALT.
# 2. Four groups: all 10 tests are significant, but CREA does not change among
#    the patient stages (section 3), so its result reflects donors vs patients.
# 3. Trend within patients: strongest for ALB (rho -0.74) and CHE (-0.72),
#    then ALP (+0.52), BIL (+0.44), CHOL (-0.38), ALT (-0.30), AST (+0.27)
#    and PROT (-0.26). GGT and CREA are not significant.
#    AST/ALT ratio rises with stage (rho 0.47).
# 4. Pairwise (31 of 60 significant): ALB and CHE differ only between cirrhosis
#    and the other groups. AST and GGT differ between donors and every patient
#    stage, but not between any two patient stages.
# 5. Age differs between groups (p = 1.8e-6; hepatitis patients are youngest).
#    Sex does not differ significantly (p = 0.12), although 20 of 24 hepatitis
#    patients are male. Albumin in cirrhosis is 9.8 g/L lower than in donors,
#    and 9.5 g/L lower after adjusting for age and sex (both p < 0.001), so age
#    and sex do not explain the fall in albumin.