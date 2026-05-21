# Quarto Authoring – Extended Reference

Source: https://quarto.org/docs/get-started/authoring/rstudio.html

## Output Format Selection

### At document creation (RStudio)
File → New File → Quarto Document → choose format

### In YAML

```yaml
format: html          # single format
```

```yaml
format:
  html:
    code-fold: true
    html-math-method: katex
  pdf:
    geometry:
      - top=30mm
      - left=30mm
  docx:
    default
```

### Format-level vs. root-level options

- **Root level**: applies to ALL formats
- **Under a format**: applies only to that format

```yaml
title: "Report"
author: "KIM"
toc: true               # root — applies to all
number-sections: true   # root — applies to all
syntax-highlighting: pygments   # root
format:
  html:
    code-fold: true     # HTML only
  pdf:
    geometry:           # PDF only
      - margin=25mm
```

## PDF Requirements

LaTeX required. Install TinyTeX:

```bash
quarto install tinytex
```

Or from R:

```r
install.packages("tinytex")
tinytex::install_tinytex()
```

## Rendering

```r
# Render current document to first listed format
quarto::quarto_render()

# Render specific file to multiple formats
quarto::quarto_render("report.qmd", output_format = c("html", "pdf", "docx"))
```

In RStudio: Render button → dropdown to select format.

Keyboard shortcut: `Shift + Cmd + K` (Mac) / `Shift + Ctrl + K` (Windows)

## Table of Contents

```yaml
toc: true
toc-depth: 3
number-sections: true
toc-title: "Contents"
toc-location: left    # HTML: left, right, body
```

## Equations

Inline: `$\mu = \frac{\sum x}{n}$`

Block display:

```markdown
$$
OR = \frac{a/b}{c/d} = \frac{ad}{bc}
$$ {#eq-or}
```

Reference: `The odds ratio (@eq-or) was...`

## Citations

### Setup

```yaml
bibliography: references.bib
csl: vancouver.csl
```

### Cite syntax

```markdown
[@Smith2020]              # parenthetical: (Smith, 2020)
@Smith2020                # narrative: Smith (2020)
[-@Smith2020]             # year only: (2020)
[@Smith2020; @Jones2021]  # multiple
```

### In RStudio Visual Editor

Insert → Citation → search by DOI, Zotero, or `.bib` key

## Cross References Summary

| Element | Label format | Reference |
|---------|-------------|-----------|
| Figure (inline) | `{#fig-name}` | `@fig-name` |
| Figure (chunk) | `#\| label: fig-name` | `@fig-name` |
| Table | `{#tbl-name}` or `#\| label: tbl-name` | `@tbl-name` |
| Section | `## Title {#sec-name}` | `@sec-name` |
| Equation | `$$ ... $$ {#eq-name}` | `@eq-name` |

## Callout Blocks

```markdown
::: {.callout-note}
Note with default title "Note".
:::

::: {.callout-tip title="Practical tip"}
Use `tbl_summary()` from gtsummary for clean tables.
:::

::: {.callout-warning collapse="true"}
This section can be toggled open/closed.
:::
```

Types: `note`, `tip`, `warning`, `caution`, `important`

Add `collapse="true"` to make collapsible (HTML).

## Article Layout

Control content width per element:

```markdown
::: {.column-margin}
Sidebar annotation or small figure.
:::
```

Column classes: `column-body`, `column-body-outset`, `column-page`, `column-screen-inset`, `column-screen`, `column-margin`

Per chunk:

```yaml
#| column: page
```

## RevealJS Presentation Essentials

```yaml
format:
  revealjs:
    theme: simple          # simple, dark, moon, sky, night, serif, solarized
    slide-number: true
    incremental: true      # bullets one at a time
    logo: logo.png
    footer: "Department of Community Medicine, USM"
    transition: slide
    scrollable: true
    smaller: true          # reduce font size
    width: 1600
    height: 900
```

New slide: `##` heading or `---` divider

Speaker notes:

```markdown
::: {.notes}
Remember to mention the confidence interval here.
:::
```

## Visual Editor (RStudio)

Switch: Source ↔ Visual button in toolbar

Features:
- GUI insert for citations, cross-references, equations
- Table editor
- Spell check
- Format toolbar (bold, italic, headings)
- Insert → Callout Block, Tabset, etc.

## Tabset Panels (HTML)

```markdown
::: {.panel-tabset}

## Tab 1

Content for first tab.

## Tab 2

Content for second tab.

:::
```

## Conditional Content by Format

```markdown
::: {.content-visible when-format="html"}
This appears only in HTML output.
:::

::: {.content-hidden when-format="pdf"}
This is hidden in PDF.
:::
```

## Parameters (Parameterised Reports)

```yaml
params:
  state: "Kelantan"
  year: 2023
```

Use in document:

```{r}
cat("State:", params$state)
```

Render with different params:

```r
quarto::quarto_render(
  "report.qmd",
  execute_params = list(state = "Selangor", year = 2024)
)
```
