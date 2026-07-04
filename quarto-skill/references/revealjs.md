# Quarto RevealJS – Extended Reference

Source: https://quarto.org/docs/presentations/revealjs/

## Minimal Setup

```yaml
---
title: "My Talk"
author: "Kamarul Imran Musa"
format: revealjs
---
```

## Themes

```yaml
format:
  revealjs:
    theme: simple   # default, simple, dark, league, sky, beige,
                     # serif, solarized, blood, moon, night
```

Custom theme via Sass:

```yaml
format:
  revealjs:
    theme: [simple, custom.scss]
```

## Slide Numbering, Progress, Navigation

```yaml
format:
  revealjs:
    slide-number: true          # or c/t (current/total), h.v (h.v style)
    progress: true
    controls: true
    hash: true                  # slide URLs reflect current slide
    history: true
    center: true                 # vertically center content
```

## Transitions

```yaml
format:
  revealjs:
    transition: slide           # none, fade, slide, convex, concave, zoom
    transition-speed: default   # default, fast, slow
    background-transition: fade
```

Per-slide override:

```markdown
## My Slide {transition="zoom"}
```

## Fragments (Incremental Reveal Within a Slide)

```markdown
::: {.fragment}
This appears on the first click.
:::

::: {.fragment .fade-out}
This appears, then fades out on the next click.
:::

::: {.fragment .highlight-red}
This text turns red when revealed.
:::
```

Order fragments explicitly with `fragment-index`:

```markdown
::: {.fragment fragment-index=2}
Shown second.
:::

::: {.fragment fragment-index=1}
Shown first.
:::
```

Fragment style classes: `fade-in` (default), `fade-out`, `fade-up`, `fade-down`, `fade-left`, `fade-right`, `fade-in-then-out`, `fade-in-then-semi-out`, `grow`, `shrink`, `strike`, `highlight-red`, `highlight-green`, `highlight-blue`, `highlight-current-red`.

## Auto-Animate (Smooth Transitions Between Slides)

```markdown
## Slide 1 {auto-animate="true"}
- Item one

## Slide 1 continued {auto-animate="true"}
- Item one
- Item two (grows in smoothly, since headings/text match the prior slide)
```

## Backgrounds

```markdown
## Full-bleed image {background-image="photo.jpg"}

## Color background {background-color="#1a1a2e"}

## Video background {background-video="clip.mp4" background-video-loop="true"}

## Iframe background {background-iframe="https://example.com"}
```

Multiple images in sequence: `background-image="a.jpg,b.jpg"` with `background-size`, `background-position`, `background-repeat` also supported.

## Speaker View & Notes

```markdown
::: {.notes}
Mention the confidence interval and effect size here.
:::
```

Press **`S`** during the presentation to open Speaker View (shows notes, next slide, and a timer) in a separate window.

## Chalkboard (Live Annotation)

```yaml
format:
  revealjs:
    chalkboard: true
```

Press **`B`** for the chalkboard, **`C`** to draw directly on slides during a live talk.

## Multiplex (Audience Follows on Their Own Devices)

```yaml
format:
  revealjs:
    multiplex: true
```

## Code Highlighting on Slides

```yaml
#| code-line-numbers: "1-3|5|7-10"
```

Pipe-separated groups step through highlighted line ranges as the presenter clicks — ideal for walking through code incrementally.

## Auto-Slide (Timed Advance, e.g. for Kiosk Mode)

```yaml
format:
  revealjs:
    auto-slide: 5000     # advance every 5s
    loop: true
```

## Size, Margins, Scaling

```yaml
format:
  revealjs:
    width: 1600
    height: 900
    margin: 0.1
    min-scale: 0.2
    max-scale: 2.0
```

## Footer & Logo

```yaml
format:
  revealjs:
    logo: logo.png
    footer: "Department of Community Medicine, USM"
```

Suppress footer/logo on a specific slide:

```markdown
## Title Slide {footer="false"}
```

## Menu / Table of Contents Overlay

```yaml
format:
  revealjs:
    menu:
      side: left
      numbers: true
```

## Scrollable Slides (Long Content)

```yaml
format:
  revealjs:
    scrollable: true
```

Or per-slide: `## Long Slide {.scrollable}`

## Exporting to PDF

Open the rendered HTML deck in Chrome/Chromium with `?print-pdf` appended to the URL, then use the browser's print dialog to save as PDF:

```
my-slides.html?print-pdf
```

## Full-Screen Reveal of Embedded Content

```yaml
format:
  revealjs:
    preview-links: auto   # open external links in an overlay iframe
```

## Common Presenter Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `F` | Full screen |
| `S` | Speaker view |
| `B` | Chalkboard |
| `O` | Slide overview grid |
| `Esc` | Exit overview/full screen |
| `Alt`/`Cmd` + click | Zoom into clicked element |
