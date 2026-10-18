# Liver Function Markers Across Stages of Hepatitis C Infection

How do routine liver function tests change as Hepatitis C progresses from hepatitis to
fibrosis to cirrhosis? This project analyses laboratory data from 608 people
(533 healthy blood donors and 75 Hepatitis C patients) using R.

**Full report:** `Report.html` (tables, figures, statistics and discussion)

## Background

Pakistan has the highest number of people living with hepatitis C of any country
(WHO Global Hepatitis Report 2024). I work in a hospital laboratory in Pakistan and am moving
from wet-lab to computational work. This project combines my clinical laboratory knowledge with
data analysis in R, using a public dataset.

## Data

HCV data from the UCI Machine Learning Repository (Lichtinghagen, Klawonn & Hoffmann, 2020;
https://doi.org/10.24432/C5D612), licensed CC BY 4.0. It contains age, sex and 10 laboratory
tests: ALB, ALP, ALT, AST, BIL, CHE, CHOL, CREA, GGT and PROT.

## What I did

1. **Explore** (`01_explore.R`): checked the structure, groups and missing values
2. **Clean** (`02_clean.R`): split the diagnosis column, removed 7 "suspect blood donors",
   put the disease stages in order
3. **Describe** (`03_describe.R`): median (IQR) of each test per group, globulin,
   data-quality checks
4. **Visualize** (`04_visualize.R`): boxplots of all tests and the AST/ALT ratio
5. **Test** (`05_statistics.R`): Wilcoxon, Kruskal-Wallis and Spearman tests with
   Benjamini-Hochberg correction, pairwise tests, and age and sex as confounders
6. **Report** (`Report.Rmd`, `Report.html`): the full write-up

## Key findings

- **Liver cell damage markers (AST, GGT)** were higher in every patient stage than in healthy
  donors, but did not differ significantly between hepatitis, fibrosis and cirrhosis.
- **Synthetic function markers (albumin, cholinesterase)** fell sharply only in cirrhosis and
  showed the strongest trend with disease stage (Spearman rho -0.74 and -0.72). The fall in
  albumin remained after adjusting for age and sex.
- **Bilirubin** rose sharply in cirrhosis.
- **Data quality:** unusually low ALT and ALP values in patients suggest that patient and donor
  samples may have been measured differently, so donor-patient comparisons need caution.

![Key liver markers across stages of Hepatitis C](figures/fig2_key_markers.png)

## How to run it

1. Open `hcv_project.Rproj` in RStudio
2. Install the packages: `install.packages(c("readr", "dplyr", "tidyr", "ggplot2", "knitr", "rmarkdown"))`
3. Run the scripts in order (`01` to `05`), then knit `Report.Rmd`

## Folders

```
hcv_project/
├── data/      raw data (never changed), clean data, results tables
├── script/   01_explore.R to 05_statistics.R
├── figures/   the 3 figures
├── Report.Rmd and Report.html
└── README.md
```

## Author

Ayesha Nasir
