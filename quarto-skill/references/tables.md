# Quarto Tables – Extended Reference

Source: https://quarto.org/docs/authoring/tables.html

## Markdown (Pipe) Tables

```markdown
| Variable | n   | %    |
|----------|----:|-----:|
| Male     | 120 | 48.0 |
| Female   | 130 | 52.0 |

: Frequency distribution of sex {#tbl-sex}
```

- `:---` left-aligns, `---:` right-aligns, `:---:` centers a column.
- The caption line (`: Caption text {#tbl-label}`) must directly follow the table with **no blank line** before it if you want it attached as a caption; the label must start with `tbl-` for cross-referencing.

## Grid Tables

Useful when cells need multi-line content, lists, or embedded code:

```markdown
+---------------+---------------+
| Variable      | Description   |
+===============+===============+
| `age`         | Age in years, |
|               | continuous    |
+---------------+---------------+
| `sex`         | - Male        |
|               | - Female      |
+---------------+---------------+

: Variable dictionary {#tbl-dict}
```

## Cross-Referencing Tables

```markdown
As shown in @tbl-sex, slightly more participants were female.
```

Rules mirror figures: the label must start with `tbl-`, and the caption must be present for the reference to resolve.

## Tables from Code (R)

### knitr::kable — simple, portable

```{r}
#| label: tbl-kable
#| tbl-cap: "Summary statistics (kable)"
knitr::kable(head(mtcars), digits = 1)
```

### gt — publication-quality styling

```{r}
#| label: tbl-gt
#| tbl-cap: "Summary statistics (gt)"
library(gt)
mtcars |>
  head() |>
  gt() |>
  fmt_number(columns = everything(), decimals = 1)
```

### gtsummary — clinical/epidemiology summary tables

```{r}
#| label: tbl-summary
#| tbl-cap: "Baseline characteristics by group"
library(gtsummary)
trial |>
  select(age, grade, response, trt) |>
  tbl_summary(by = trt) |>
  add_p()
```

### DT — interactive tables (HTML only)

```{r}
#| label: tbl-dt
DT::datatable(mtcars, options = list(pageLength = 5))
```

> Interactive tables (DT, reactable) cannot be numbered/cross-referenced the same way as static tables — treat them as unlabeled output unless the format supports it.

## Tables from Code (Python)

```{python}
#| label: tbl-py
#| tbl-cap: "Summary statistics (pandas)"
import pandas as pd
from great_tables import GT
df = pd.read_csv("data.csv")
GT(df.head())
```

## Column Widths

Control relative column widths for a table produced by a code cell:

```yaml
#| tbl-colwidths: [75,25]
```

Or disable Quarto's automatic width calculation:

```yaml
#| tbl-colwidths: false
```

## Side-by-Side Tables

```markdown
::: {layout-ncol=2}

| A | B |
|---|---|
| 1 | 2 |

| C | D |
|---|---|
| 3 | 4 |

:::
```

## Table Placement (PDF/LaTeX)

```yaml
tbl-pos: "H"        # H=here, t=top, b=bottom
```

## Caption Location

```yaml
tbl-cap-location: top      # default for tables
tbl-cap-location: bottom
tbl-cap-location: margin
```
