# Quarto Presentations – General Reference

Source: https://quarto.org/docs/presentations/

Quarto can produce slide decks in several formats from the **same authoring syntax**:

| Format | YAML `format:` value | Notes |
|--------|----------------------|-------|
| reveal.js (HTML) | `revealjs` | Most flexible; see `references/revealjs.md` |
| PowerPoint | `pptx` | Good for editing/collaborating outside Quarto afterwards |
| Beamer (PDF, LaTeX) | `beamer` | Requires a LaTeX installation (TinyTeX) |

```yaml
---
title: "Statistical Modelling in R"
author: "Kamarul Imran Musa"
format: revealjs
---
```

## How Slides Are Created

- A **level-1 heading (`#`)** starts a new section/title slide.
- A **level-2 heading (`##`)** starts a new slide.
- A horizontal rule (`---`) also starts a new slide without a heading.
- Content under a heading becomes that slide's body.

```markdown
## Study Design

- Retrospective cohort
- n = 1,245 participants
- Follow-up: 5 years
```

## Incremental Lists

Reveal bullets one at a time (also works in pptx/beamer):

```yaml
format:
  revealjs:
    incremental: true
```

Override per-list:

```markdown
::: {.incremental}
- First point
- Second point
:::

::: {.nonincremental}
- Shown all at once
:::
```

## Speaker Notes

```markdown
::: {.notes}
Remember to mention the confidence interval here.
:::
```

Notes are hidden from the main view and shown in the presenter/speaker view (reveal.js) or the notes pane (PowerPoint).

## Multiple Columns

```markdown
:::: {.columns}

::: {.column width="40%"}
Left column content, e.g. a bullet list.
:::

::: {.column width="60%"}
Right column content, e.g. a figure or table.
:::

::::
```

## Smaller Text / Fit-to-Slide

```markdown
::: {.smaller}
This content renders at a reduced font size.
:::
```

## Code on Slides

Standard executable chunks work on slides exactly as in documents — output (plots, tables, printed values) is inserted directly into the slide:

````
```{r}
#| echo: true
#| fig-width: 5
#| fig-height: 3.5
plot(pressure)
```
````

Use `code-line-numbers` to highlight specific lines progressively (reveal.js only — see `references/revealjs.md`).

## Common Front Matter for All Slide Formats

```yaml
---
title: "Presentation Title"
subtitle: "Optional subtitle"
author: "Presenter Name"
date: today
format:
  revealjs:
    theme: simple
  pptx:
    default
  beamer:
    default
---
```

Rendering multiple slide formats from one source lets you keep a single `.qmd` for both a live talk (`revealjs`) and a handout (`pptx`/`beamer`/PDF).

## Choosing a Format

- **revealjs** — best for live presenting in a browser, richest feature set (fragments, backgrounds, chalkboard, embedding web content).
- **pptx** — best when the audience needs an editable file or your organization mandates PowerPoint.
- **beamer** — best for LaTeX-heavy academic talks with lots of math, or when a static PDF is required.

For anything involving live delivery, animation, or interactivity, default to **revealjs** unless the user asks for PowerPoint or Beamer specifically. See `references/revealjs.md` for the full feature set.
