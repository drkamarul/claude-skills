---
name: quarto-skill
description: >
  Use this skill whenever the user wants to create, write, edit, or improve a Quarto
  document (.qmd) or build a slide deck / presentation with Quarto or revealjs. Trigger
  on any mention of: Quarto, .qmd, quarto render, revealjs, Quarto slides or presentations,
  YAML front matter, knitr chunk options, code folding, cross-references, figures, subfigures,
  tables (kable/gt/gtsummary/DT), callout blocks, citations, page layout (column-margin,
  column-page), Quarto PDF/HTML/Word/dashboard output, or reproducible documents in R,
  Python, Julia, or Observable JS. Also trigger on requests like "make a slide deck",
  "turn this into a presentation", "write a reproducible report in R", or "help me write
  a document with code and output" even if the word Quarto is never used.
compatibility: RStudio, VS Code, Positron, Jupyter — any environment supporting the Quarto CLI
---

# Quarto Skill

Author, structure, and render Quarto (`.qmd`) content — reports, articles, and slide decks
(revealjs, PowerPoint, Beamer) — for reproducible research, teaching, and scientific
communication in R or Python.

## When to Use This Skill

- Writing or editing a `.qmd` document: reports, articles, websites, or books.
- Building a slide deck or presentation, especially with **revealjs**.
- Answering questions about Quarto YAML front matter, chunk options, or rendering.
- Adding figures, tables, cross-references, callouts, or citations to a Quarto file.
- Converting an existing R/R Markdown report into a modern Quarto document.

## Authoritative Sources

Quarto's own documentation is the source of truth and changes over time. If you have
live web access, check the relevant page below first; otherwise use the bundled
snapshot in `references/` (each file cites the page it was derived from).

| Topic | Live doc | Bundled reference |
|-------|----------|--------------------|
| General authoring (RStudio) | quarto.org/docs/get-started/authoring/rstudio.html | `references/authoring.md` |
| Code execution / computations | quarto.org/docs/get-started/computations/rstudio.html | `references/computations.md` |
| Figures | quarto.org/docs/authoring/figures.html | `references/figures.md` |
| Tables | quarto.org/docs/authoring/tables.html | `references/tables.md` |
| Front matter (YAML) | quarto.org/docs/authoring/front-matter.html | `references/front-matter.md` |
| Page layout (columns/margins) | quarto.org/docs/output-formats/page-layout.html | `references/page-layout.md` |
| Presentations (general) | quarto.org/docs/presentations/ | `references/presentations.md` |
| RevealJS slides | quarto.org/docs/presentations/revealjs/ | `references/revealjs.md` |

Reach for a reference file whenever a task goes beyond the quick patterns below —
e.g. subfigures and layout grids (`references/figures.md`), gt/gtsummary tables
(`references/tables.md`), or fragments/chalkboard/auto-animate in revealjs
(`references/revealjs.md`).

## Quick Start: Document

```yaml
---
title: "My Report"
author: "Prof. Dr. Kamarul Imran Musa"
date: today
format: html
execute:
  echo: false
  warning: false
---
```

```{r}
#| label: fig-boxplot
#| fig-cap: "Distribution of BMI by group"
ggplot(data, aes(x = group, y = bmi)) +
  geom_boxplot() +
  theme_minimal()
```

See @fig-boxplot for the distribution.

## Quick Start: Slide Deck (RevealJS)

```yaml
---
title: "Statistical Modelling in R"
author: "Kamarul Imran Musa"
format:
  revealjs:
    theme: simple
    slide-number: true
    incremental: true
---
```

```markdown
## Study Design

- Retrospective cohort
- n = 1,245 participants

## Results

::: {.fragment}
The primary outcome was significant (p < 0.05).
:::
```

A level-2 heading (`##`) starts a new slide. Full revealjs feature set — themes,
transitions, fragments, backgrounds, speaker notes, chalkboard — is in
`references/revealjs.md`.

## Document Essentials

### Output Formats

```yaml
format: html          # single format
```

```yaml
format:              # multiple formats, per-format options
  html:
    code-fold: true
    toc: true
  pdf:
    geometry: margin=25mm
  docx:
    default
```

Common formats: `html`, `pdf` (requires `quarto install tinytex`), `docx`, `revealjs`,
`pptx`, `beamer`, `gfm`. Render from R with:

```r
quarto::quarto_render("report.qmd", output_format = c("html", "pdf", "docx"))
```

### Code Chunks

````
```{r}
#| label: my-chunk
#| echo: true
#| warning: false
library(tidyverse)
mtcars |> summarise(mean_mpg = mean(mpg))
```
````

Key options: `label`, `echo`, `eval`, `warning`, `message`, `include`, `error`, `cache`,
`fig-width`/`fig-height`/`fig-cap`/`fig-alt`, `output`. Set defaults globally with an
`execute:` block in the YAML; override per-chunk. Details, caching, and Python/Observable
JS chunks: `references/computations.md`.

### Figures

```markdown
![Caption text](path/to/image.png){width=80% fig-align="center"}
```

````
```{r}
#| label: fig-boxplot
#| fig-cap: "Distribution of BMI by group"
#| fig-alt: "Boxplot showing BMI distribution across three groups"
```
````

The `label` must start with `fig-` for `@fig-boxplot` cross-references to work.
Subfigures, layout grids, lightbox, and LaTeX figure options: `references/figures.md`.

### Tables

```markdown
| Variable | n   | %    |
|----------|----:|-----:|
| Male     | 120 | 48.0 |

: Frequency distribution of sex {#tbl-sex}
```

````
```{r}
#| label: tbl-summary
#| tbl-cap: "Baseline characteristics"
library(gtsummary)
trial |> tbl_summary(by = group)
```
````

gt/gtsummary/DT patterns, column widths, and grid tables: `references/tables.md`.

### Cross-References

| Type | Label prefix | Reference |
|------|-------------|-----------|
| Figure | `fig-` | `@fig-label` |
| Table | `tbl-` | `@tbl-label` |
| Section | any (`{#sec-label}`) | `@sec-label` |
| Equation | `eq-` | `@eq-label` |

### Callouts

```markdown
::: {.callout-note}
This is a note callout.
:::

::: {.callout-tip title="Pro Tip"}
Use `gtsummary` for publication-ready tables.
:::
```

Types: `callout-note`, `callout-tip`, `callout-warning`, `callout-caution`, `callout-important`.

### Citations

```yaml
bibliography: references.bib
csl: apa.csl
```

```markdown
This finding is consistent with prior studies [@Smith2020; @Jones2021].
```

### Page Layout (Margins, Wide Content)

```markdown
::: {.column-margin}
Margin note or small figure.
:::
```

Full set of column classes (`column-page`, `column-screen`, etc.) and website grid
options: `references/page-layout.md`.

### Front Matter (YAML)

```yaml
---
title: "Report"
author:
  - name: "Kamarul Imran Musa"
    affiliation: "Universiti Sains Malaysia"
    orcid: "0000-0000-0000-0000"
date: today
abstract: >
  Short summary of the document.
---
```

Author objects, format-specific vs shared keys, title-block styling, and `params`:
`references/front-matter.md`.

## Presentations & RevealJS

Quarto renders the same slide markdown to `revealjs` (HTML, most feature-rich),
`pptx` (editable PowerPoint), or `beamer` (LaTeX/PDF). Default to **revealjs** unless
the user specifically needs an editable PowerPoint file or a static Beamer PDF.

- Slides are created from `##` headings or `---` dividers.
- `::: {.notes}` blocks become speaker notes.
- `::: {.fragment}` reveals content incrementally within a slide.
- `{background-image="..."}` on a heading sets a full-bleed slide background.

General slide-authoring patterns (columns, incremental lists, code on slides) live in
`references/presentations.md`. RevealJS-specific features (themes, transitions,
fragments, auto-animate, backgrounds, chalkboard, speaker view, PDF export) live in
`references/revealjs.md` — read it before building anything beyond a basic deck.

## Quick Reference Card

| Task | Syntax |
|------|--------|
| Heading | `# H1`, `## H2`, `### H3` |
| New slide (revealjs/pptx/beamer) | `## Heading` or `---` |
| Bold / Italic | `**text**` / `*text*` |
| R inline code | `` `r expr` `` |
| Image | `![alt](path)` |
| Cross-ref | `@fig-label`, `@tbl-label` |
| Citation | `[@key]` |
| Callout note | `::: {.callout-note}` |
| Speaker notes | `::: {.notes}` |
| Fragment (revealjs) | `::: {.fragment}` |
| Margin content | `::: {.column-margin}` |
| Equation block | `$$...$$ {#eq-label}` |

## Reference Files

- `references/authoring.md` — general authoring tutorial (formats, rendering, citations, equations, tabsets)
- `references/computations.md` — code execution, caching, data frame printing
- `references/figures.md` — advanced figure layouts, subfigures, lightbox, LaTeX options
- `references/tables.md` — grid tables, gt/gtsummary/DT, column widths
- `references/front-matter.md` — YAML metadata, author objects, params
- `references/page-layout.md` — column/margin layout classes, website grid options
- `references/presentations.md` — general slide-authoring patterns across formats
- `references/revealjs.md` — full revealjs feature reference
