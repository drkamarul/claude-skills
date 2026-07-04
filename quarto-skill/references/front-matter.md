# Quarto Front Matter (YAML) – Extended Reference

Source: https://quarto.org/docs/authoring/front-matter.html

## Where Front Matter Lives

- Inline, at the top of a `.qmd` file, between `---` delimiters.
- Project-wide, in `_quarto.yml` (applies to every document in the project).
- In a shared metadata file included via `metadata-files`.

Document-level YAML overrides project-level YAML for the same key.

```yaml
# _quarto.yml (project-wide defaults)
project:
  type: default
format:
  html:
    theme: flatly
```

```yaml
# report.qmd (overrides theme just for this document)
---
title: "Report"
format:
  html:
    theme: cosmo
---
```

## Core Document Metadata

```yaml
---
title: "Determinants of Hospital Readmission"
subtitle: "A Retrospective Cohort Study"
author:
  - name: "Kamarul Imran Musa"
    affiliation: "Universiti Sains Malaysia"
    email: "kamarul@usm.my"
    orcid: "0000-0000-0000-0000"
    corresponding: true
date: today
date-modified: last-modified
abstract: >
  This study examines risk factors associated with 30-day hospital
  readmission among patients with type 2 diabetes.
keywords: ["readmission", "diabetes", "cohort study"]
description: "Retrospective cohort analysis of readmission risk factors."
lang: en
---
```

### Author Field Options

`author` accepts a single string, or a list of objects with:

| Field | Purpose |
|-------|---------|
| `name` | Full name |
| `affiliation` | Institution (string or object with `name`, `department`, `city`) |
| `email` | Contact email |
| `url` | Personal/lab URL |
| `orcid` | ORCID identifier |
| `role` / `roles` | Contribution role (e.g. `writing`, `analysis`) |
| `corresponding` | `true` to mark as corresponding author |
| `note` | Footnote-style annotation (e.g. equal contribution) |

## Date Handling

```yaml
date: today                 # renders current date at build time
date: "2024-03-15"           # fixed date
date-modified: last-modified # updates to file's last-modified date
date-format: "MMMM D, YYYY"  # custom display format
```

## Format-Specific vs Shared Options

Root-level keys apply to **every** output format; keys nested under `format` apply only to that format.

```yaml
---
title: "Report"
toc: true                 # shared — applies to html, pdf, docx
number-sections: true     # shared
format:
  html:
    code-fold: true        # html only
    theme: flatly
  pdf:
    documentclass: article # pdf only
    geometry: margin=1in
  docx:
    default
---
```

## Title Block Customization (HTML)

```yaml
title-block-banner: true              # or a color/image path
title-block-banner-color: white
title-block-style: default            # default, plain, or none
```

## Citation Metadata (for Reference Managers)

```yaml
citation:
  type: article-journal
  container-title: "Journal of Epidemiology"
  doi: "10.1000/xyz123"
  url: "https://doi.org/10.1000/xyz123"
```

## Reusing Metadata Across Documents

```yaml
# _quarto.yml
metadata-files:
  - _authors.yml
```

```yaml
# _authors.yml
author:
  - name: "Kamarul Imran Musa"
    affiliation: "USM"
```

## Params (Parameterized Documents)

```yaml
params:
  state: "Kelantan"
  year: 2023
```

Referenced in code as `params$state` (R) or `params["state"]` (Python), and overridden at render time:

```r
quarto::quarto_render("report.qmd", execute_params = list(state = "Selangor"))
```

## Common Pitfalls

- YAML is indentation-sensitive — use 2 spaces, never tabs.
- Quote strings containing `:` (e.g. `title: "Ratio: 2:1"`), or YAML parsing breaks.
- `format: html` (scalar) and `format: {html: {...}}` (mapping) are both valid — don't mix a scalar value with nested keys for the same format.
