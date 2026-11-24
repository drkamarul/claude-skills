---
name: "friendly-style-slidedeck"
description: "Build or revise a Quarto revealjs talk deck in KIM's friendly, sharing-experience style with the navy/indigo/magenta card theme, short spoken sentences and timed speaker notes."
---

# Friendly-style slide deck (Quarto revealjs)

Use this when KIM or other users ask for a talk, lecture or seminar deck, or ask to revise one, in "my style" or a friendly style. Also use the quarto-skill for Quarto syntax.

## 1. Plan before building

1. Read any existing deck, `AGENTS.md` and `implementation_plan.md` in the folder.
2. Ask questions in grill-me rounds (numbered, with a recommended answer each) until these are settled: audience, date/time/venue, talk length, **slide limit**, must-have content, what can be cut, screenshots, bio facts.
3. Present the full numbered slide outline (mark new slides with ★) and **wait for approval** before editing files.
4. Back up the old version (e.g. `backup_YYYY-MM-DD/`) before overwriting.

## 2. Language style

KIM is **sharing experience, not teaching**.

- First person: "I use…", "In my experience…", "What works for me…", "Mistakes I see".
- Short sentences KIM or user can say aloud. One idea per bullet. Aim for ≤ ~40 words of body text per slide.
- Professional but friendly, never authoritative: avoid "must", "never do", "you should". Prefer "I always…", "I try…", "Please don't take it lightly".
- Mistakes are written as **mistake → fix** (e.g. "Trusting every answer → don't trust; always verify").
- Explain each technical term in plain words the first time.
- No em-dash chains or arrow-heavy fragments in spoken text.
- Never invent references, statistics, model names or product features. Link official pages or peer-reviewed papers that were opened and checked; log them in `references.md` with the check date. Personal terms or opinions (e.g. KIM's own coinages) are framed as experience, with no fake source.
- Use they/them or KIM's name in files, never guessed pronouns.

## 3. Structure and slide-count rules

- Respect the slide limit strictly (count title and reference slides). If content doesn't fit one slide, **split** into (1/2), (2/2) rather than shrinking the font.
- Typical order: Title → About me → Today's plan → Why (motivation) → Parts A/B/C → Take-home habits → References → Thank you · Questions.
- Bio slide: title line, then KIM's chosen facts as bullets; book card and website/LinkedIn card on the right.
- Every slide (except the title) has speaker notes starting with a time stamp `[mm:ss–mm:ss]`, written in short spoken sentences. Leave a few minutes of buffer before Q&A.
- Every image has `fig-alt`. Crop screenshots so no personal data shows (sidebars with project names, account names, avatars); save cropped copies as `*_cropped.png` and keep originals.

## 4. YAML setup

```yaml
---
title: "<Title>"
subtitle: "<Subtitle>"
author:
  - name: "Prof. Dr. Kamarul Imran Musa (KIM)"
    url: "https://myanalytics.com.my/"
    affiliation: "Professor of Epidemiology and Statistics, School of Medical Sciences, Universiti Sains Malaysia"
date: YYYY-MM-DD
date-format: "dddd, D MMMM YYYY [· <time> · <venue>]"
format:
  revealjs:
    theme: [default, talk.scss]
    width: 1280
    height: 720
    slide-number: c/t
    show-slide-number: all
    progress: true
    transition: slide
    background-transition: fade
    highlight-style: github
    footer: "<Short title> · <Venue> · <Date>"
    menu: true
    controls: true
    controls-layout: bottom-right
    center: false
    auto-stretch: false
    hash: true
    title-slide-attributes:
      data-background-gradient: "linear-gradient(135deg, #14213d 0%, #3a0ca3 60%, #b5179e 100%)"
    embed-resources: true
---
```

## 5. Slide patterns

Part label at the top of each content slide:

```markdown
## Reason first {.smaller}

[PART A · WORKFLOW]{.part-tag .pa}
```

(`.pa` navy, `.pb` indigo, `.pc` teal, `.px` coral.)

Cards in columns (solid: `card-navy|blue|indigo|teal|magenta|coral|light`; soft with left border: `card-blue-soft|teal-soft|amber-soft|red-soft|pink-soft`):

```markdown
::::: columns
::: {.column width="50%"}
::: {.card .card-teal style="min-height: 260px;"}
**⏱ To save time**

I spend much less time writing code
:::
:::
::: {.column width="50%"}
::: {.card .card-red-soft}
**Trusting every answer** → don't trust

Always verify and validate
:::
:::
:::::
```

Other helpers: `::: {.big-quote}` one-line message; `::: {.callout-tip}` / `{.callout-important}`; `::: aside` for source links with "(checked <date>)"; `[1]{.step-number}` numbered steps; `::: {.tiles}` + `::: {.tile .t1}` … `.t8` letter tiles; `::: {.shot}` around a screenshot (border + shadow; set `height="…px"` so it fits); `::: {.refs}` numbered reference list; `::: {.contact-card .center}` on the thank-you slide; `.small`, `.xsmall`, `.muted`, `.center`. Drop `{.smaller}` on slides with little text so it reads from the back of the room.

Speaker notes:

```markdown
::: {.notes}
[02:30–04:00] Let me start with why. First, time. I code much less now.
:::
```

## 6. Theme file `talk.scss`

Save this next to the `.qmd`:

```scss
/*-- scss:defaults --*/

$c-ink:     #14213d;
$c-indigo:  #3a0ca3;
$c-blue:    #4361ee;
$c-cyan:    #0096c7;
$c-teal:    #06a77d;
$c-amber:   #f4a261;
$c-coral:   #e76f51;
$c-magenta: #b5179e;
$c-muted:   #5c677d;
$c-light:   #f3f5fb;
$c-white:   #ffffff;

$font-family-sans-serif: "Segoe UI", "Inter", system-ui, -apple-system, sans-serif;
$presentation-font-size-root: 34px;
$presentation-heading-font: "Segoe UI", "Inter", system-ui, sans-serif;
$presentation-heading-color: $c-ink;
$presentation-heading-font-weight: 700;
$body-bg: $c-white;
$body-color: #22303f;
$link-color: $c-blue;
$code-color: $c-magenta;

/*-- scss:rules --*/

.reveal {
  h2 {
    font-size: 1.3em;
    padding-bottom: 0.2em;
    margin-bottom: 0.5em;
    border-bottom: 4px solid transparent;
    border-image: linear-gradient(90deg, $c-blue, $c-magenta, $c-amber) 1;
  }
  h3 { font-size: 1em; color: $c-blue; margin-bottom: 0.3em; }
  ul, ol { line-height: 1.5; }
  li { margin-bottom: 0.25em; }
  pre code { font-size: 0.7em; border-radius: 8px; max-height: 520px; }
  .footer { font-size: 0.5em; color: $c-muted; }
  .progress span { background: linear-gradient(90deg, $c-blue, $c-magenta); }
  .slide-number { font-size: 0.5em; color: $c-muted; background: transparent; }
  .aside, aside { font-size: 0.5em; color: $c-muted; }
  .aside a, aside a { color: $c-cyan; }
  strong { color: $c-ink; }
}

.reveal section.has-dark-background {
  h1 { font-size: 1.7em; color: $c-white; }
  p  { color: rgba(255,255,255,0.88); font-size: 0.95em; }
  strong { color: $c-white; }
  a { color: #ffd6a5; }
}

.card {
  border-radius: 12px; padding: 12px 18px; margin: 6px 4px;
  font-size: 0.8em; line-height: 1.4;
  box-shadow: 0 3px 10px rgba(20, 33, 61, 0.10);
}
.card strong { color: inherit; }
.card code { color: inherit !important; background: rgba(255,255,255,0.18) !important; }
.card-light code, [class*='-soft'] code { background: rgba(20,33,61,0.07) !important; }
.card-navy    { background: $c-ink;     color: $c-white; }
.card-blue    { background: $c-blue;    color: $c-white; }
.card-indigo  { background: $c-indigo;  color: $c-white; }
.card-teal    { background: $c-teal;    color: $c-white; }
.card-magenta { background: $c-magenta; color: $c-white; }
.card-coral   { background: $c-coral;   color: $c-white; }
.card-light   { background: $c-light;   color: $c-ink; }
.card-blue-soft  { background: #e7ecfd; color: $c-ink; border-left: 5px solid $c-blue; }
.card-teal-soft  { background: #e0f5ee; color: $c-ink; border-left: 5px solid $c-teal; }
.card-amber-soft { background: #fdf0e6; color: $c-ink; border-left: 5px solid $c-amber; }
.card-red-soft   { background: #fbe7e2; color: $c-ink; border-left: 5px solid $c-coral; }
.card-pink-soft  { background: #f8e4f4; color: $c-ink; border-left: 5px solid $c-magenta; }

.tiles { display: flex; gap: 10px; justify-content: center; flex-wrap: wrap; margin: 10px 0 18px; }
.tile {
  width: 104px; padding: 10px 4px; border-radius: 12px; text-align: center;
  color: $c-white; font-size: 0.55em; line-height: 1.25;
  box-shadow: 0 3px 10px rgba(20, 33, 61, 0.15);
}
.tile strong { color: #fff !important; display: block; font-size: 2.1em; line-height: 1.1; }
.t1 { background: $c-ink; }
.t2 { background: $c-indigo; }
.t3 { background: $c-blue; }
.t4 { background: $c-cyan; }
.t5 { background: $c-teal; }
.t6 { background: #2a9d8f; }
.t7 { background: $c-coral; }
.t8 { background: $c-magenta; }

.step-number {
  display: inline-flex; align-items: center; justify-content: center;
  width: 1.5em; height: 1.5em; border-radius: 50%;
  background: $c-blue; color: $c-white; font-weight: 700; font-size: 0.85em; margin-right: 6px;
}

.reveal table { font-size: 0.8em; border-collapse: collapse; width: 100%; }
.reveal table th { background: $c-ink; color: $c-white; padding: 6px 10px; text-align: left; }
.reveal table td { padding: 5px 10px; border-bottom: 1px solid #dde2ee; vertical-align: top; }
.reveal table tr:nth-child(even) td { background: $c-light; }

.small  { font-size: 0.72em; }
.xsmall { font-size: 0.6em; }
.muted  { color: $c-muted; }
.center { text-align: center; }
.big-quote {
  font-size: 1.05em; font-weight: 600; color: $c-indigo; text-align: center;
  margin: 0.6em auto; max-width: 85%;
}
.demo-tag {
  display: inline-block; padding: 2px 12px; border-radius: 20px;
  background: $c-amber; color: $c-ink; font-size: 0.5em; font-weight: 700; letter-spacing: 0.04em;
}
.contact-card {
  background: linear-gradient(135deg, $c-ink 0%, $c-indigo 55%, $c-magenta 100%);
  color: $c-white; padding: 26px 36px; border-radius: 16px; font-size: 0.8em; line-height: 1.9;
  max-width: 640px; margin: 10px auto;
}
.contact-card a { color: #ffd6a5; }
.reveal .contact-card strong { color: #ffffff; }
.refs { font-size: 0.48em; line-height: 1.35; }
.refs li { margin-bottom: 0.15em; }

.reveal #title-slide, .reveal section.section-dark {
  h1, h2, p, .subtitle, .quarto-title-author-name, .quarto-title-affiliation, .date, a { color: $c-white !important; }
}
.reveal #title-slide h1.title { font-size: 2.1em; }
.reveal #title-slide .subtitle { color: #ffd6a5 !important; font-size: 1.1em; }
.reveal section.section-dark h1 { font-size: 1.7em; }

.part-tag {
  display: inline-block; padding: 2px 12px; border-radius: 20px; margin-bottom: 4px;
  color: $c-white; font-size: 0.45em; font-weight: 700; letter-spacing: 0.05em;
}
.pa { background: $c-ink; }
.pb { background: $c-indigo; }
.pc { background: $c-teal; }
.px { background: $c-coral; }
.shot img { border: 1px solid #dde2ee; border-radius: 8px; box-shadow: 0 3px 10px rgba(20, 33, 61, 0.12); }
```

## 7. Render and check before reporting

1. `quarto render <deck>.qmd` and fix every warning. If Quarto isn't installed, download the Linux tarball from the quarto-cli GitHub releases into a scratch folder and run its `bin/quarto`.
2. Check with Playwright at 1280 × 720 (set `Reveal.configure({transition:'none'})` before screenshots, or slides are captured mid-transition):
   - `Reveal.getTotalSlides()` ≤ the limit
   - no slide overflows (look at screenshots, not only scrollHeight)
   - every `img` has alt text; every content slide has `aside.notes`
3. Check every URL returns 200 and every DOI matches Crossref; record dates in `references.md`. Say plainly which links could not be checked.
4. Update `AGENTS.md` (slide limit, tone rule) and add a dated section to `implementation_plan.md` with decisions, time budget and outline.
5. Report to KIM or user: slide count, render status, checks, what changed, where the backup is.
