---
name: datamanagement
description: >
  Use this skill for ANY data management, data wrangling, cleaning, or
  transformation task in R. Trigger on: dplyr, tidyr, purrr, readr,
  stringr, forcats, lubridate, janitor, pivoting, joining, merging,
  filtering, mutating, summarising, grouping, nesting, mapping over
  lists, reading CSV/Excel/SPSS/Stata files, recoding variables,
  missing data, derived variables, data validation, or epidemiological
  data preparation. Also trigger for Shiny apps with data processing,
  or preparing data for modelling, gtsummary tables, or ggplot2. Even
  if the user just says "clean this data", "wrangle this", "recode
  these", "reshape this", or "merge these files", use this skill.
  Complements shinyskill and quarto-skill.
---

# Data Management & Wrangling Skill for R

Comprehensive guide for data management, wrangling, and transformation using the tidyverse ecosystem in R. This skill covers the full pipeline from raw data import to analysis-ready datasets, with patterns commonly used in epidemiology, public health, and biostatistics.

## Core Philosophy

1. **Tidy data principles**: Each variable is a column, each observation is a row, each value is a cell.
2. **Pipe-first**: Use the native pipe `|>` (R 4.1+). Fall back to `%>%` only when lambda shorthand `~` is needed.
3. **Tidyverse-first**: Prefer `dplyr`, `tidyr`, `purrr`, `readr`, `stringr`, `forcats`, `lubridate` over base R equivalents.
4. **Readable code**: Favour explicit, self-documenting code over clever one-liners.
5. **Reproducibility**: Scripts should run top-to-bottom without manual intervention.

## Package Loading Convention

```r
library(tidyverse)   # loads dplyr, tidyr, ggplot2, purrr, readr, stringr, forcats, tibble
library(janitor)     # clean_names(), tabyl()
library(lubridate)   # date/time handling
library(readxl)      # Excel files
library(haven)       # SPSS, Stata, SAS files
library(gtsummary)   # summary tables
library(labelled)    # variable labels
```

## Data Import

### Reading Files

```r
# CSV (readr — faster, consistent types, UTF-8 default)
df <- read_csv("data.csv", show_col_types = FALSE)

# Excel
df <- read_excel("data.xlsx", sheet = "Sheet1", skip = 1)

# SPSS / Stata / SAS
df <- read_sav("data.sav")    # SPSS
df <- read_dta("data.dta")    # Stata
df <- read_sas("data.sas7bdat") # SAS

# Multiple files (purrr pattern)
paths <- list.files("data/", pattern = "\\.csv$", full.names = TRUE)
df <- paths |>
  map(read_csv, show_col_types = FALSE) |>
  list_rbind()

# Multiple sheets from one Excel file
sheets <- excel_sheets("data.xlsx")
df <- sheets |>
  set_names() |>
  map(read_excel, path = "data.xlsx") |>
  list_rbind(names_to = "sheet")
```

### Initial Inspection

```r
glimpse(df)
skim(df)             # from skimr
df |> count(variable)
df |> tabyl(variable) # from janitor — includes %, valid %, cumulative %
```

## Data Cleaning

### Column Names

```r
df <- df |> clean_names()   # janitor: snake_case, removes special chars
df <- df |> rename(new_name = old_name)
df <- df |> rename_with(str_to_lower)
df <- df |> rename_with(\(x) str_replace_all(x, "\\.", "_"))
```

### Data Types

```r
df <- df |>
  mutate(
    id = as.character(id),
    age = as.numeric(age),
    sex = factor(sex, levels = c("Male", "Female")),
    date_onset = ymd(date_onset),          # lubridate
    date_admit = dmy(date_admit),
    datetime = ymd_hms(datetime),
    bp_sys = parse_number(bp_sys_raw)      # extracts number from text
  )
```

### Missing Data

```r
# Count missing
df |> summarise(across(everything(), \(x) sum(is.na(x))))

# Visualise missing (naniar)
# naniar::vis_miss(df)

# Drop rows with any NA in key variables
df <- df |> drop_na(outcome, age, sex)

# Replace NA with a value
df <- df |> mutate(
  smoking = replace_na(smoking, "Unknown"),
  bp_sys = coalesce(bp_sys, bp_sys_alt, median(bp_sys, na.rm = TRUE))
)

# Replace specific values with NA
df <- df |> mutate(
  income = na_if(income, 999),
  status = na_if(status, "")
)
```

### Recoding & Creating Variables

```r
# if_else for binary
df <- df |> mutate(
  hypertension = if_else(bp_sys >= 140 | bp_dia >= 90, "Yes", "No")
)

# case_when for multiple conditions
df <- df |> mutate(
  bmi_cat = case_when(
    bmi < 18.5             ~ "Underweight",
    bmi >= 18.5 & bmi < 25 ~ "Normal",
    bmi >= 25 & bmi < 30   ~ "Overweight",
    bmi >= 30              ~ "Obese",
    .default = NA_character_
  )
)

# case_match for direct value mapping
df <- df |> mutate(
  sex_label = case_match(
    sex_code,
    1 ~ "Male",
    2 ~ "Female",
    .default = NA_character_
  )
)

# Factor with ordered levels
df <- df |> mutate(
  bmi_cat = factor(bmi_cat,
    levels = c("Underweight", "Normal", "Overweight", "Obese"),
    ordered = TRUE
  )
)

# forcats for factor manipulation
df <- df |> mutate(
  education = fct_relevel(education, "None", "Primary", "Secondary", "Tertiary"),
  region = fct_lump_n(region, n = 5, other_level = "Other"),
  diagnosis = fct_infreq(diagnosis)    # order by frequency
)

# Age groups (common in epi)
df <- df |> mutate(
  age_group = cut(age,
    breaks = c(0, 18, 30, 45, 60, Inf),
    labels = c("<18", "18-29", "30-44", "45-59", "60+"),
    right = FALSE
  )
)
```

### String Operations

```r
df <- df |> mutate(
  name = str_to_title(str_trim(name)),
  ic_clean = str_remove_all(ic_number, "-"),
  has_diabetes = str_detect(diagnosis, regex("diabet", ignore_case = TRUE)),
  icd_chapter = str_sub(icd_code, 1, 3)
)
```

### Date Operations

```r
df <- df |> mutate(
  year = year(date_onset),
  month = month(date_onset, label = TRUE),
  epiweek = isoweek(date_onset),
  los = as.numeric(date_discharge - date_admit),    # length of stay
  age_at_event = interval(dob, date_onset) / years(1),
  follow_up_end = date_onset + days(30)
)
```

## Data Transformation (dplyr)

### Row Operations — Extract Cases

```r
df |> filter(age > 18, sex == "Female")
df |> filter(bp_sys >= 140 | bp_dia >= 90)
df |> filter(between(age, 30, 50))
df |> filter(state %in% c("Kelantan", "Terengganu", "Pahang"))
df |> distinct(patient_id, .keep_all = TRUE)
df |> slice_sample(n = 100)
df |> slice_max(bp_sys, n = 10)
df |> arrange(desc(date_onset), patient_id)
```

### Column Operations — Extract & Create Variables

```r
df |> select(patient_id, age, sex, starts_with("bp_"))
df |> select(where(is.numeric))
df |> select(!c(notes, comments))
df |> relocate(patient_id, date_onset, .before = everything())

df |> mutate(gpm = 1 / mpg, .keep = "none")          # transmute equivalent
df |> mutate(across(where(is.numeric), round, digits = 1))
df |> mutate(across(c(bp_sys, bp_dia), \(x) x / 10))
```

### Summarise

```r
# Grouped summaries
df |>
  summarise(
    n = n(),
    mean_age = mean(age, na.rm = TRUE),
    sd_age = sd(age, na.rm = TRUE),
    median_bp = median(bp_sys, na.rm = TRUE),
    prop_hyp = mean(hypertension == "Yes", na.rm = TRUE),
    .by = c(sex, age_group)
  )

# Count shorthand
df |> count(sex, age_group, name = "n")

# across() for multiple summaries
df |>
  summarise(
    across(c(bp_sys, bp_dia, bmi), list(
      mean = \(x) mean(x, na.rm = TRUE),
      sd = \(x) sd(x, na.rm = TRUE),
      median = \(x) median(x, na.rm = TRUE)
    ), .names = "{.col}_{.fn}"),
    .by = sex
  )
```

### Row-wise Operations

```r
df |>
  rowwise() |>
  mutate(total_score = sum(c_across(q1:q10))) |>
  ungroup()
```

## Reshaping (tidyr)

```r
# Long to wide
df_wide <- df |>
  pivot_wider(
    names_from = visit,
    values_from = c(bp_sys, bp_dia),
    names_glue = "{.value}_visit{visit}"
  )

# Wide to long
df_long <- df |>
  pivot_longer(
    cols = starts_with("bp_"),
    names_to = c(".value", "visit"),
    names_pattern = "(.+)_visit(\\d+)"
  )

# Separate and unite
df <- df |> separate_wider_delim(name, delim = " ", names = c("first", "last"))
df <- df |> unite("full_name", first, last, sep = " ")
```

## Joining / Merging

```r
# Mutating joins
result <- df |> left_join(lookup, by = "patient_id")
result <- df |> left_join(lookup, by = c("icd_code" = "code"))
result <- df |> inner_join(lab, by = c("patient_id", "visit_date"))

# Filtering joins
matched <- df |> semi_join(eligible, by = "patient_id")
unmatched <- df |> anti_join(eligible, by = "patient_id")

# Bind rows/columns
combined <- bind_rows(df_2023, df_2024, .id = "year")
combined <- bind_cols(demographics, clinical)   # use with caution

# Set operations
intersect(df1, df2)
setdiff(df1, df2)
union(df1, df2)
```

## Functional Programming (purrr)

See `references/purrr-patterns.md` for detailed patterns and examples.

### Core Map Functions

```r
# map() returns a list
models <- df |>
  split(df$state) |>
  map(\(d) lm(bp_sys ~ age + sex, data = d))

# Type-specific variants
map_dbl(models, \(m) summary(m)$r.squared)
map_chr(models, \(m) paste(round(coef(m), 2), collapse = ", "))
map_int(list(a = 1:3, b = 4:9), length)

# map with data frames
map(models, broom::tidy) |> list_rbind(names_to = "state")

# map2 — iterate over two inputs
map2(models, split(df, df$state), predict)

# pmap — iterate over multiple inputs
params <- tibble(n = c(10, 20, 30), mean = c(0, 5, 10), sd = c(1, 2, 3))
pmap(params, rnorm)

# walk — side effects (saving files, printing)
iwalk(models, \(mod, name) saveRDS(mod, paste0("models/", name, ".rds")))
```

### Safe Iteration

```r
# safely() captures errors
safe_log <- safely(log, otherwise = NA_real_)
results <- list("a", 10, 100) |> map(safe_log)
results |> map("result") |> list_c()
results |> map("error") |> compact()

# possibly() returns default on error
list("a", 10, 100) |> map_dbl(possibly(log, NA_real_))

# insistently() retries on error
rate <- rate_backoff(pause_base = 0.1, max_times = 3)
insistent_fetch <- insistently(fetch_api_data, rate = rate)
```

### List Manipulation

```r
# Combine list elements
list_c(list(1:3, 4:6))                    # → c(1,2,3,4,5,6)
list_rbind(list(df1, df2), names_to = "source")
list_flatten(nested_list)

# Keep / discard
keep(results, \(x) !is.null(x))
discard(results, is.na)
compact(results)                           # remove NULL / length-0

# Detect
detect(results, \(x) x > 100)

# Reduce
reduce(list(df1, df2, df3), left_join, by = "id")
accumulate(1:5, `+`)
```

## Nesting & List-Columns

```r
# Nest by group
nested <- df |>
  nest(.by = state)

# Map models inside nested data
nested <- nested |>
  mutate(
    model = map(data, \(d) lm(bp_sys ~ age + sex, data = d)),
    tidy = map(model, broom::tidy),
    glance = map(model, broom::glance)
  )

# Unnest results
nested |> unnest(tidy)
nested |> unnest(glance)
```

## Epidemiological Data Patterns

### WHO NCD STEPS Data Preparation

```r
steps_clean <- steps_raw |>
  clean_names() |>
  mutate(
    age_group = cut(age, breaks = c(18, 30, 45, 60, 70, Inf),
                    labels = c("18-29", "30-44", "45-59", "60-69", "70+"),
                    right = FALSE),
    bmi = weight / (height / 100)^2,
    bmi_cat = case_when(
      bmi < 18.5 ~ "Underweight",
      bmi < 25   ~ "Normal",
      bmi < 30   ~ "Overweight",
      .default   = "Obese"
    ),
    hypertension = if_else(bp_sys >= 140 | bp_dia >= 90 | on_bp_meds == 1, 1, 0),
    diabetes = if_else(fasting_glucose >= 7.0 | on_dm_meds == 1, 1, 0),
    current_smoker = if_else(tobacco_use %in% c(1, 2), 1, 0),
    physical_inactive = if_else(total_met_minutes < 600, 1, 0)
  )
```

### Surveillance / Line-List Cleaning

```r
linelist <- linelist_raw |>
  clean_names() |>
  mutate(
    date_onset = parse_date_time(date_onset, orders = c("dmy", "ymd", "mdy")),
    epiweek = isoweek(date_onset),
    epiyear = isoyear(date_onset),
    delay_report = as.numeric(date_report - date_onset)
  ) |>
  filter(date_onset >= ymd("2024-01-01")) |>
  distinct(case_id, .keep_all = TRUE)

# Epicurve data
epicurve_data <- linelist |>
  count(epiweek, district, name = "cases")
```

### Cross-tabulation for Epi Tables

```r
# gtsummary approach
df |>
  select(age_group, sex, hypertension, diabetes, bmi_cat) |>
  tbl_summary(
    by = sex,
    statistic = list(
      all_continuous() ~ "{mean} ({sd})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    missing = "no"
  ) |>
  add_p() |>
  add_overall()

# janitor::tabyl for quick cross-tabs
df |>
  tabyl(age_group, hypertension) |>
  adorn_totals("row") |>
  adorn_percentages("row") |>
  adorn_pct_formatting() |>
  adorn_ns()
```

## Data Validation

```r
# Assertion checks (stopifnot or assertr)
stopifnot(
  "Duplicate IDs found" = n_distinct(df$patient_id) == nrow(df),
  "Age out of range" = all(df$age >= 0 & df$age <= 120, na.rm = TRUE),
  "Missing outcome" = sum(is.na(df$outcome)) == 0
)

# Summary validation
df |>
  summarise(
    n_rows = n(),
    n_unique_id = n_distinct(patient_id),
    pct_missing_age = mean(is.na(age)) * 100,
    min_date = min(date_onset, na.rm = TRUE),
    max_date = max(date_onset, na.rm = TRUE)
  )
```

## Integration with Shiny

When building Shiny apps that involve data processing, combine this skill with the `shinyskill`:

```r
# Reactive data pipeline inside server
server <- function(input, output, session) {
  filtered_data <- reactive({
    df |>
      filter(
        state %in% input$state,
        between(age, input$age_range[1], input$age_range[2]),
        date_onset >= input$date_range[1],
        date_onset <= input$date_range[2]
      ) |>
      mutate(
        age_group = cut(age, breaks = c(0, 18, 40, 60, Inf),
                        labels = c("<18", "18-39", "40-59", "60+"))
      )
  })

  summary_data <- reactive({
    filtered_data() |>
      summarise(
        n = n(),
        mean_bp = mean(bp_sys, na.rm = TRUE),
        prop_hyp = mean(hypertension == 1, na.rm = TRUE),
        .by = age_group
      )
  })

  output$summary_table <- DT::renderDT({
    summary_data()
  })
}
```

## Key Principles

1. **Always `clean_names()` first** — consistent snake_case column names prevent downstream errors.
2. **Inspect before transforming** — use `glimpse()`, `count()`, `tabyl()` to understand the data.
3. **Use `.by` argument** — prefer `summarise(..., .by = group)` over `group_by() |> summarise() |> ungroup()` for cleaner one-off groupings.
4. **Prefer `case_when()` over nested `if_else()`** — more readable for 3+ conditions.
5. **Use `across()` for multi-column operations** — avoid copy-paste mutations.
6. **Use `purrr::map()` over loops** — clearer intent, easier to parallelise.
7. **Use list-columns and `nest()`** — for group-wise modelling and complex workflows.
8. **Validate early** — check data quality before analysis, not after.
9. **Label variables** — use `labelled::set_variable_labels()` for self-documenting datasets.
10. **Use `janitor::tabyl()`** — for quick cross-tabulations in epidemiological analyses.

## References

For detailed purrr patterns and advanced functional programming, see `references/purrr-patterns.md`.
