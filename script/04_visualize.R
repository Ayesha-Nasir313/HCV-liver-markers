# =============================================================================
# 04_visualize.R
# Purpose : Figures of the laboratory tests and the AST/ALT ratio across
#           disease stages
# Input   : data/hcv_clean.csv
# Output  : figures/fig1_all_tests.png, figures/fig2_key_markers.png,
#           figures/fig3_ast_alt_ratio.png
# =============================================================================

library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)

hcv <- read_csv("data/hcv_clean.csv", show_col_types = FALSE)
hcv <- hcv %>%
  mutate(Diagnosis = factor(Diagnosis,
                            levels = c("Blood Donor", "Hepatitis", "Fibrosis", "Cirrhosis")))

dir.create("figures", showWarnings = FALSE)
set.seed(2026)   # keeps the jittered dot positions the same on every run

# Units are not stated in the dataset; standard SI units are assumed
test_units <- c(ALB = "g/L", ALP = "U/L", ALT = "U/L", AST = "U/L", BIL = "umol/L",
                CHE = "kU/L", CHOL = "mmol/L", CREA = "umol/L", GGT = "U/L", PROT = "g/L")

hcv_long <- hcv %>%
  pivot_longer(cols = ALB:PROT, names_to = "Test", values_to = "Value") %>%
  mutate(Test_label = paste0(Test, " (", test_units[Test], ")"))

# Shared styling: light yellow (healthy) to dark red (cirrhosis), an ordered
# palette that stays readable for colour-blind readers
stage_fill <- scale_fill_brewer(palette = "YlOrRd")
facet_theme <- theme_bw() +
  theme(legend.position = "bottom",
        axis.text.x  = element_blank(),
        axis.ticks.x = element_blank())

# ---- Figure 1: all 10 tests ----
fig1 <- ggplot(hcv_long, aes(x = Diagnosis, y = Value, fill = Diagnosis)) +
  geom_boxplot(outlier.size = 0.8, na.rm = TRUE) +
  facet_wrap(~ Test_label, scales = "free_y", ncol = 5) +
  stage_fill +
  labs(title = "Liver Function Tests Across Stages of Hepatitis C",
       x = NULL, y = NULL, fill = "Disease stage",
       caption = paste("Boxes show the median and interquartile range; dots are outliers.",
                       "The CREA panel is compressed by three very high values in cirrhosis (486-1079 umol/L).")) +
  facet_theme
fig1
ggsave("figures/fig1_all_tests.png", plot = fig1, width = 12, height = 6, dpi = 300)

# ---- Figure 2: four key markers, every person shown ----
# Top row: markers of liver cell damage; bottom row: markers of synthetic function
fig2_data <- hcv_long %>%
  filter(Test %in% c("AST", "GGT", "ALB", "CHE")) %>%
  mutate(Test_label = factor(Test_label,
                             levels = c("AST (U/L)", "GGT (U/L)", "ALB (g/L)", "CHE (kU/L)")))

fig2 <- ggplot(fig2_data, aes(x = Diagnosis, y = Value, fill = Diagnosis)) +
  geom_boxplot(outlier.shape = NA, na.rm = TRUE) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 0.8, na.rm = TRUE) +
  facet_wrap(~ Test_label, scales = "free_y", ncol = 2) +
  stage_fill +
  labs(title = "Key Liver Markers Across Stages of Hepatitis C",
       x = NULL, y = NULL, fill = "Disease stage",
       caption = "Each dot is one person. Top: liver cell damage. Bottom: synthetic function.") +
  facet_theme
fig2
ggsave("figures/fig2_key_markers.png", plot = fig2, width = 8, height = 7, dpi = 300)

# ---- Figure 3: AST/ALT ratio, calculated for each person ----
hcv <- hcv %>% mutate(AST_ALT_ratio = AST / ALT)

# Median ratio per stage
hcv %>%
  group_by(Diagnosis) %>%
  summarise(median_ratio = round(median(AST_ALT_ratio, na.rm = TRUE), 2))

fig3 <- ggplot(hcv, aes(x = Diagnosis, y = AST_ALT_ratio, fill = Diagnosis)) +
  geom_boxplot(outlier.shape = NA, na.rm = TRUE) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 0.8, na.rm = TRUE) +
  geom_hline(yintercept = 1, linetype = "dashed") +
  scale_y_log10() +
  stage_fill +
  labs(title = "AST/ALT Ratio Across Stages of Hepatitis C",
       x = "Disease stage", y = "AST/ALT ratio (log scale)",
       caption = "Each dot is one person. Dashed line: AST = ALT. One patient with missing ALT not shown.") +
  theme_bw() +
  theme(legend.position = "none")
fig3
ggsave("figures/fig3_ast_alt_ratio.png", plot = fig3, width = 7, height = 5, dpi = 300)

list.files("figures")