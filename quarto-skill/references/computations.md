# Quarto Computations – Extended Reference

Source: https://quarto.org/docs/get-started/computations/rstudio.html

## Overview

Quarto supports executable code blocks in R, Python, Julia, and Observable JS. The code runs on render — making documents fully reproducible.

## Cell Output Control

### Hide all code globally

```yaml
execute:
  echo: false
```

### Override for specific chunk

```{r}
#| echo: true
```

### echo options

- `true` — show code
- `false` — hide code
- `fenced` — show code WITH the fenced delimiters (useful for teaching)

### Other output options

| Option | Purpose |
|--------|---------|
| `warning: false` | Suppress warnings (useful for package loads) |
| `message: false` | Suppress messages |
| `include: false` | Run code but suppress ALL output |
| `eval: false` | Skip execution, show code only |
| `error: true` | Continue rendering even if chunk errors |
| `output: false` | Suppress result/print output but keep side effects |

## Code Folding

HTML format only:

```yaml
format:
  html:
    code-fold: true      # each chunk foldable
    code-tools: true     # global "show/hide all code" button
```

## Code Linking

Hyperlinks functions to online documentation (knitr + downlit package):

```yaml
format:
  html:
    code-link: true
```

> Note: `code-link` is incompatible with `code-line-numbers` and `code-annotations` simultaneously.

## Figures from Code

```{r}
#| label: fig-scatterplot
#| fig-cap: "City and highway mileage for 38 popular models of cars."
#| fig-alt: "Scatterplot of city vs. highway mileage, colored by cylinders."
#| fig-width: 6
#| fig-height: 3.5

ggplot(mpg, aes(x = hwy, y = cty, color = cyl)) +
  geom_point(alpha = 0.5, size = 2) +
  scale_color_viridis_c() +
  theme_minimal()
```

Cross-reference: `@fig-scatterplot shows a positive relationship...`

## Multiple Figures from One Chunk

```{r}
#| label: fig-mpg
#| fig-cap: "City and highway mileage."
#| fig-subcap:
#|   - "Color by number of cylinders"
#|   - "Color by engine displacement, in liters"
#| layout-ncol: 2
#| column: page

ggplot(mpg, aes(x = hwy, y = cty, color = cyl)) +
  geom_point(alpha = 0.5, size = 2) +
  scale_color_viridis_c() +
  theme_minimal()

ggplot(mpg, aes(x = hwy, y = cty, color = displ)) +
  geom_point(alpha = 0.5, size = 2) +
  scale_color_viridis_c(option = "E") +
  theme_minimal()
```

Reference individual subfigures: `@fig-mpg-1` and `@fig-mpg-2`.

## Data Frames / Tables

By default, data frames print as plain text. Options to improve:

```yaml
df-print: kable      # knitr::kable style
df-print: tibble     # tibble print style
df-print: paged      # interactive paged table (HTML only)
```

Or use explicitly in chunk:

```{r}
knitr::kable(head(mtcars))
```

Or with gtsummary:

```{r}
#| label: tbl-summary
#| tbl-cap: "Summary statistics"
library(gtsummary)
trial |> tbl_summary()
```

## Inline Code (R)

```markdown
The dataset contains `r nrow(data)` observations with
mean age `r round(mean(data$age, na.rm=TRUE), 1)` years.
```

Inline R evaluates at render time. Perfect for dynamic text in results sections.

## Caching

Enable caching to speed up re-renders when only parts of document change:

```yaml
execute:
  cache: true
```

Or per-chunk:

```{r}
#| cache: true
```

Clear cache: delete the `_cache/` directory or use:

```r
quarto::quarto_render("doc.qmd", cache_refresh = TRUE)
```

## Python Chunks

````
```{python}
#| label: fig-py
#| fig-cap: "Python plot"

import matplotlib.pyplot as plt
plt.plot([1, 2, 3], [1, 4, 9])
plt.show()
```
````

## Observable JS

````
```{ojs}
data = FileAttachment("data.csv").csv({ typed: true })
Plot.dot(data, {x: "x", y: "y"}).plot()
```
````
