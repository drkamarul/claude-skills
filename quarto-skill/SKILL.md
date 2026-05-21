---
name: quarto-skill
description: >
  Use this skill whenever the user wants to create, write, edit, or improve a Quarto document (.qmd file).
  Trigger on any mention of: Quarto, .qmd, quarto render, YAML front matter for documents,
  revealjs slides in Quarto, knitr chunk options, code folding, cross-references, figure captions,
  subfigures, callout blocks, Quarto tables, inline code, citations in Quarto, Quarto PDF,
  Quarto HTML, Quarto Word output, Quarto dashboard, reproducible documents in R or Python,
  execute options, fig-cap, label, echo, warning, or any authoring task that produces a .qmd file.
  Also trigger when user asks about Quarto computations, rendering options, figure layouts, or
  multi-format output. Even if the user just says "help me write a document in R" or "I need a
  report with code and output", consider using this skill.
compatibility: RStudio, VS Code, Positron, Jupyter — any environment supporting Quarto CLI
---

# Quarto Skill

A comprehensive reference for authoring, structuring, and rendering Quarto (`.qmd`) documents — especially for reproducible research, teaching, and scientific reporting in R (with knitr).

---

## 1. Document Structure

Every Quarto document starts with **YAML front matter** between `---` delimiters:

```yaml
---
title: "My Report"
author: "Prof. Dr. Kamarul Imran Musa"
date: today
format: html
---
```

Common top-level YAML keys:

| Key | Purpose |
|-----|---------|
| `title` | Document title |
| `author` | Author name(s) |
| `date` | Date (use `today` for auto date) |
| `format` | Output format(s) |
| `toc` | Table of contents (`true`/`false`) |
| `number-sections` | Numbered headings |
| `execute` | Global code execution options |
| `bibliography` | Path to `.bib` file |

---

## 2. Output Formats

Specify format at root level or with per-format options:

```yaml
format: html          # simple single format
```

```yaml
format:              # multiple formats with options
  html:
    code-fold: true
    html-math-method: katex
    toc: true
  pdf:
    geometry:
      - top=30mm
      - left=30mm
  docx:
    default
```

**Common formats:** `html`, `pdf`, `docx`, `revealjs`, `pptx`, `beamer`, `gfm`

> For PDF output, LaTeX is required. Install TinyTeX via:
> ```bash
> quarto install tinytex
> ```

**Rendering in RStudio:**
- Click **Render** button (or `Shift+Cmd+K` / `Shift+Ctrl+K`)
- Enable **Render on Save** for live preview
- Render to multiple formats from R:

```r
quarto::quarto_render("report.qmd", output_format = c("html", "pdf", "docx"))
```

---

## 3. Code Chunks (Knitr / R)

### Basic chunk

````
```{r}
#| label: my-chunk
#| echo: true
#| warning: false

library(tidyverse)
mtcars |> summarise(mean_mpg = mean(mpg))
```
````

### Key chunk options (use `#|` prefix — Quarto style)

| Option | Values | Effect |
|--------|--------|--------|
| `label` | string | Chunk identifier (required for cross-ref) |
| `echo` | `true`/`false`/`fenced` | Show/hide code |
| `warning` | `true`/`false` | Show/hide warnings |
| `message` | `true`/`false` | Show/hide messages |
| `include` | `true`/`false` | Include all output |
| `eval` | `true`/`false` | Run or skip chunk |
| `error` | `true`/`false` | Continue on error |
| `cache` | `true`/`false` | Cache results |
| `fig-width` | number | Figure width (inches) |
| `fig-height` | number | Figure height (inches) |
| `fig-cap` | string | Figure caption |
| `fig-alt` | string | Alt text for accessibility |
| `output` | `true`/`false`/`asis` | Control output display |

### Global execution options (in YAML)

```yaml
execute:
  echo: false       # hide all code globally
  warning: false
  message: false
  cache: true
```

Override globally for a specific chunk with the `#| echo: true` option in the chunk.

### Code folding (HTML)

```yaml
format:
  html:
    code-fold: true      # fold/hide code, user can expand
    code-tools: true     # global show/hide code toggle
    code-link: true      # hyperlink functions to docs (knitr only)
```

---

## 4. Figures

### Basic figure from image file

```markdown
![Caption text](path/to/image.png){width=80% fig-align="center"}
```

Attributes: `width`, `height`, `fig-align` (`left`/`center`/`right`), `fig-alt`, `.lightbox`

### Figure from R code chunk

````
```{r}
#| label: fig-boxplot
#| fig-cap: "Distribution of BMI by group"
#| fig-alt: "Boxplot showing BMI distribution across three groups"
#| fig-width: 6
#| fig-height: 4

ggplot(data, aes(x = group, y = bmi)) +
  geom_boxplot() +
  theme_minimal()
```
````

> The `label` must start with `fig-` for cross-referencing to work.

### Multiple figures / subfigures side by side

````
```{r}
#| label: fig-combined
#| fig-cap: "City and highway mileage"
#| fig-subcap:
#|   - "Coloured by cylinders"
#|   - "Coloured by displacement"
#| layout-ncol: 2
#| column: page

plot1_code
plot2_code
```
````

### Figure sizing units

```markdown
![](image.png){width=300}        # pixels (default)
![](image.png){width=80%}        # percentage
![](image.png){width=4in}        # inches
```

### Lightbox (HTML only)

```markdown
![An elephant](elephant.png){.lightbox}
```

---

## 5. Cross-References

Cross-references require labels with appropriate prefixes.

| Type | Label prefix | Reference syntax |
|------|-------------|-----------------|
| Figure | `fig-` | `@fig-label` |
| Table | `tbl-` | `@tbl-label` |
| Section | any | `@sec-label` |
| Equation | `eq-` | `@eq-label` |

Example:

```markdown
See @fig-boxplot for the distribution.

As shown in @tbl-summary, the prevalence was 23%.
```

For sections, add `{#sec-intro}` after the heading:

```markdown
## Introduction {#sec-intro}
```

---

## 6. Tables

### Simple markdown table

```markdown
| Variable | n | % |
|----------|---|---|
| Male     | 120 | 48.0 |
| Female   | 130 | 52.0 |

: Frequency distribution of sex {#tbl-sex}
```

### R-generated tables with cross-reference

````
```{r}
#| label: tbl-summary
#| tbl-cap: "Descriptive statistics"

library(gtsummary)
trial |>
  select(age, grade, response) |>
  tbl_summary()
```
````

---

## 7. Equations

Inline: `$y = \beta_0 + \beta_1 x + \epsilon$`

Display block:

```markdown
$$
\hat{y} = \beta_0 + \beta_1 x_1 + \beta_2 x_2
$$ {#eq-regression}
```

---

## 8. Callout Blocks

```markdown
::: {.callout-note}
This is a note callout.
:::

::: {.callout-warning}
Watch out for missing data.
:::

::: {.callout-tip title="Pro Tip"}
Use `gtsummary` for publication-ready tables.
:::

::: {.callout-important}
Interpret with caution.
:::
```

Types: `callout-note`, `callout-tip`, `callout-warning`, `callout-caution`, `callout-important`

---

## 9. Citations & Bibliography

Add bibliography file to YAML:

```yaml
bibliography: references.bib
csl: apa.csl   # optional citation style
```

Cite in text:

```markdown
This finding is consistent with prior studies [@Smith2020; @Jones2021].

Smith et al. [-@Smith2020] reported similar results.
```

In RStudio Visual Editor: use **Insert > Citation** to search Zotero, DOI, or `.bib` file.

---

## 10. Inline Code

```markdown
The mean age was `r round(mean(data$age), 1)` years.

The sample size was `r nrow(data)` participants.
```

For Python inline: `` `{python} expr` ``

---

## 11. Article Layout Options

Control column width of content:

```markdown
::: {.column-margin}
Margin note or figure here.
:::

::: {.column-page}
Full-page-width content.
:::

::: {.column-screen}
Full-screen-width content.
:::
```

Or per-chunk:

```yaml
#| column: page
```

---

## 12. Sections & Navigation

```yaml
toc: true
toc-depth: 3
number-sections: true
toc-location: left   # for HTML: left, right, body
```

---

## 13. RevealJS Presentations

```yaml
format: revealjs
```

Section breaks become slides. Use `---` for horizontal dividers, `##` for new slides.

```yaml
format:
  revealjs:
    theme: dark          # default, dark, moon, sky, etc.
    slide-number: true
    incremental: true    # bullets appear one at a time
    logo: logo.png
    footer: "USM – Department of Community Medicine"
    scrollable: true
```

---

## 14. Common Patterns for Epidemiology / Public Health Reports

### Reproducible analysis report template

```yaml
---
title: "Epidemiological Analysis Report"
author: "Prof. Dr. Kamarul Imran Musa"
date: today
format:
  html:
    toc: true
    toc-depth: 3
    code-fold: true
    code-tools: true
    number-sections: true
  pdf:
    geometry:
      - margin=25mm
    number-sections: true
  docx:
    default
execute:
  echo: false
  warning: false
  message: false
bibliography: references.bib
---
```

### Typical section structure

```markdown
## Methods

### Study Design
...

### Statistical Analysis
All analyses were conducted using R version `r R.version$major`.`r R.version$minor`.

## Results

### Descriptive Statistics

```{r}
#| label: tbl-descriptive
#| tbl-cap: "Baseline characteristics of study participants"

library(gtsummary)
data |> tbl_summary(by = group)
```

### Primary Outcome

```{r}
#| label: fig-kaplan-meier
#| fig-cap: "Kaplan-Meier survival curve by treatment group"
#| fig-width: 7
#| fig-height: 5
```
```

---

## 15. Quick Reference Card

| Task | Syntax |
|------|--------|
| Heading | `# H1`, `## H2`, `### H3` |
| Bold | `**text**` |
| Italic | `*text*` |
| Code inline | `` `code` `` |
| R inline | `` `r expr` `` |
| Link | `[text](url)` |
| Image | `![alt](path)` |
| Cross-ref | `@fig-label`, `@tbl-label` |
| Citation | `[@key]` |
| Callout note | `::: {.callout-note}` |
| Equation block | `$$...$$` |
| Comment | `<!-- hidden text -->` |

---

## Reference Files

For deeper topics, read:
- `references/figures.md` — Advanced figure layouts, lightbox, LaTeX figure options
- `references/computations.md` — Caching, data frames, code linking details
- `references/authoring.md` — Full authoring tutorial notes (multi-format, citations, equations)
