# Quarto Page Layout – Extended Reference

Source: https://quarto.org/docs/output-formats/page-layout.html

Page layout controls apply mainly to **HTML output** (articles and websites); PDF/Word largely ignore column classes and use standard page margins instead.

## Column Width Classes

Apply as a div wrapper (`::: {.class-name} ... :::`) around any content — text, figures, tables, or code cells.

| Class | Effect |
|-------|--------|
| `column-body` | Default body width (no wrapper needed) |
| `column-body-outset` | Slightly wider than body text |
| `column-page-inset` | Wider still, inset from the full page |
| `column-page` | Full page width (ignores margin/sidebar) |
| `column-page-inset-left` / `-right` | Full width, but stops before one margin |
| `column-screen` | Edge-to-edge, full browser width |
| `column-screen-inset` | Edge-to-edge with small gutter |
| `column-margin` | Placed in the margin/sidebar, alongside body text |

```markdown
::: {.column-page}
![A wide figure spanning the page.](wide-plot.png)
:::

::: {.column-margin}
A margin note or small supplementary figure.
:::
```

## Applying Layout to Code Cells

Use the `column` chunk option instead of a div wrapper:

```yaml
#| column: page
```

```yaml
#| column: margin
```

## Margin Content Shortcuts

- `{.aside}` — sends a paragraph to the margin, similar to a footnote but always visible (no numbering).
- Margin figures/tables: add `#| column: margin` to the chunk, or wrap markdown output in `::: {.column-margin}`.

```markdown
Body text continues here.^[This becomes a margin note automatically when `reference-location: margin` is set.]
```

## Footnote & Citation Placement

```yaml
reference-location: margin    # margin, document (default), block, section
citation-location: margin
```

With `reference-location: margin`, footnotes render beside the paragraph that cites them instead of at the document's end.

## Website/Project Grid Options

Set in `_quarto.yml` to change the overall page grid (affects every document in the project):

```yaml
format:
  html:
    grid:
      body-width: 900px
      sidebar-width: 250px
      margin-width: 250px
      gutter-width: 1.5rem
```

## Page Layout for Websites

```yaml
page-layout: article   # default single-column reading layout
page-layout: full      # edge-to-edge, e.g. for dashboards/landing pages
page-layout: custom     # opt out of Quarto's layout for a fully custom page
```

## Combining with Sidebars/TOC

When a document has `toc: true`, the TOC occupies the right margin column; `column-margin` content shares that space and stacks below/above the TOC entries depending on source order.

## Practical Guidance

- Use `column-margin` for asides, small supplementary figures, or reviewer-style notes — this is the most common ask in scientific writing.
- Use `column-page` / `column-screen` sparingly, typically for one "hero" figure, wide table, or interactive widget (map, plotly chart) per document.
- Test HTML layout classes by rendering — some classes have no visible effect unless the document also sets `toc: true` or the theme has a wide enough viewport.
