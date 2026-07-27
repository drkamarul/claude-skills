---
name: spatial_point_pattern_analysis
description: >
  Analyze 2D point-event data (disease cases, crime, ecological observations)
  against a study-region boundary using R's spatstat/sf ecosystem: ppp
  construction, first-order intensity (kernel density, quadrat counts), CSR
  tests (Clark-Evans, quadrat chi-square), K/L/G/F-function Monte Carlo
  envelopes with edge correction, and inhomogeneous population/covariate
  offset second-order tests to separate genuine clustering from clustering
  that just tracks where people/things are. Use for point pattern analysis,
  spatial epidemiology, disease mapping, hotspot detection, spatial
  clustering tests, kernel intensity surfaces, Ripley's K, or CSR testing in
  R. Also load before setting up a fresh R spatial (sf/spatstat/terra/quarto)
  conda env: documents sandbox fixes (PROJ path binding, Quarto Deno
  runtime) that silently break spatial analysis and report rendering.
---

# Spatial point pattern analysis (spatstat / sf, R)

Point pattern analysis answers one question at a time, and the questions
build on each other — don't skip straight to K-functions. Work in this order:

1. Clean and validate coordinates → 2. build the window and the `ppp` →
3. audit duplicates → 4. first-order intensity (where is it dense?) →
5. test CSR (is it random at all?) → 6. **replace the CSR baseline with an
inhomogeneous one** (is it more clustered than the population distribution
alone would explain?) → 7. sensitivity checks → 8. hotspot localization.

Step 6 is the step people skip and shouldn't: rejecting CSR for human
case data is almost never interesting on its own, because people are never
spread uniformly over a landscape. The real question is whether clustering
exceeds what the population/covariate surface would produce, and answering
it needs an inhomogeneous offset, not a uniform one.

## Environment setup

Needs `sf`, `spatstat`, `terra`, `tidyverse`, `janitor`, `scales`,
`patchwork`. If rendering a report, add `quarto`. Create with:

```
manage_environments(mode="create", name="rspatial", channels=["conda-forge"],
  packages=["r-base","r-sf","r-spatstat","r-terra","r-tidyverse","r-janitor",
            "r-scales","r-patchwork","r-knitr","r-rmarkdown","quarto","r-sfheaders"])
```

### Two sandbox defects to check for immediately

These are packaging bugs in the conda builds, not analysis choices — they
recur in every fresh environment built this way, so check for them before
assuming a CRS or Quarto failure is your code's fault.

1. **PROJ_DATA isn't bound at load.** `st_crs(4326)` or any CRS assignment
   silently returns `NA` (no error) even though `proj.db` ships inside the
   env. Fix: `Sys.setenv(PROJ_DATA = file.path(ENV_PATH, "share/proj"))`
   before any `sf`/CRS call, where `ENV_PATH` is the conda env root (e.g.
   `~/.claude-science/conda/envs/rspatial`). Verify with a round-trip: project
   two known points and check the distance against the geodesic distance —
   don't just check `st_crs()` prints something.
2. **Quarto's Deno/DOM plugin path is wrong.** `quarto render` fails because
   the activation hook exports `QUARTO_DENO_DOM` pointing at a build-time
   path that doesn't exist on this machine. Fix: export the full var set
   before rendering:
   ```
   export QUARTO_DENO=$E/bin/deno QUARTO_DENO_DOM=$E/lib/deno_dom.so \
          QUARTO_PANDOC=$E/bin/pandoc QUARTO_SHARE_PATH=$E/share/quarto \
          PROJ_DATA=$E/share/proj
   ```
   where `$E` is the env root. Persist both fixes in a project `.Rprofile`
   so every session (including the render step) inherits them.
3. If the report must be self-contained and the network sandbox blocks the
   MathJax CDN, set `html-math-method: plain` in the YAML header and write
   any formulas with Unicode/HTML instead of LaTeX — cheaper than requesting
   network access for two inline formulas.

`kernel.R` (bundled with this skill) ships `fix_proj_env()` for point 1 —
call it first thing in any R cell that touches `sf`/CRS.

## Workflow

### 1. Clean and validate the case records

Before anything spatial: check for missing/zero/impossible coordinates,
duplicate case IDs, and — often skipped — whether the claimed date range
actually matches the data. Surveillance extracts commonly have a filename
implying one calendar period while the actual onset dates spill into the
prior or following year, or truncate mid-month. Report the *actual* coverage
period, not the nominal one, and flag (don't silently drop) isolated
out-of-range dates that look like year-entry typos.

### 2. Build the window and the ppp

If the user has a boundary shapefile, read it, `st_make_valid()`, and
transform cases to its CRS (prefer the boundary's own projected CRS over an
arbitrary UTM zone if it's already metric — one less transform to get
wrong). Check how many case points fall outside the boundary before
building `owin`/`ppp` — a handful just outside, near the edge, is usually
digitization slop and fine to drop with a note; a large or systematic
spillover means the boundary or the coordinates are wrong and needs
investigating, not dropping.

Use `kernel.R`'s `build_ppp()` to do the containment audit and construction
in one call — it reports how many points were dropped and why.

If the boundary carries population or other covariate fields (common for
administrative polygons — check `names()`), that's a gift: it lets step 6
use a real covariate offset instead of a kernel-density proxy.

### 3. Audit duplicates before trusting small-scale statistics

Geocoded case data frequently has exact-coordinate duplicates (shared
addresses, clinic/centroid snapping). Check `sum(duplicated(P))` and the
fraction of points at `nndist(P) == 0`. This matters for two things
downstream:
- **Bandwidth selection**: `bw.diggle()` can collapse to a near-zero
  bandwidth when duplicates are present, because it's optimizing against
  the very tight nearest-neighbor distances the duplicates create. Compare
  against `bw.ppl()` and prefer the latter if `bw.diggle` looks suspiciously
  small relative to the point spacing; report both.
- **Second-order tests**: keep three pattern objects — as-observed,
  de-duplicated, and (if needed) jittered — so you can check whether any
  small-scale clustering finding survives de-duplication rather than being
  an artifact of tied coordinates.

### 4. First-order intensity: map and kernel density

Kernel density (`density.ppp`, sigma from `bw.ppl`) shows where events
concentrate; quadrat counts (`quadratcount`) give a simple grid summary.
Pick a quadrat grid (`nx`, `ny`) deliberately and **keep it fixed for the
whole analysis** — `quadrat.test`'s chi-square is sensitive to the grid,
and re-choosing it later (e.g. when writing up results) can silently
produce a different statistic than what you actually looked at. Locate and
name the intensity peak (which named sub-region it falls in), and express
it as a multiple of the mean — "115x the state average" communicates more
than a raw density number.

### 5. Test complete spatial randomness — but don't stop here

`clarkevans.test()` needs a correction appropriate to the window shape:
`"Donnelly"` requires a rectangular window and will error on a polygon —
use `"cdf"` instead for irregular windows. Quadrat chi-square
(`quadrat.test`) is the complementary test. Both will reject CSR decisively
for almost any real case dataset — treat that as expected, not as the
finding. The interesting question is step 6.

### 6. The real test: inhomogeneous second-order functions

Compute `Linhom`/`Lest` (or `Kinhom`) envelopes under two baselines and
compare:
- **Uniform CSR** — informative mainly as a strawman.
- **Population- or covariate-offset** — build a `pixelimage` from the
  boundary's own population field if available (rasterize, convert to
  `im`, **verify orientation** by sampling at a known urban vs. known rural
  location before trusting it — raster row order and image row order
  disagree by convention often enough to silently flip results), scale so
  its integral equals the observed point count, and pass as the `lambda`
  argument alongside `simulate = expression(rpoispp(lam))`.

If the population offset absorbs most but not all of the excess, that's
usually the headline finding: clustering exists *beyond* what population
distribution explains, pointing to a local driver (vector breeding sites,
water infrastructure, housing density — whatever's domain-appropriate)
rather than mere population density.

**Edge correction cost is not negligible on complex windows.** Ripley's
isotropic correction against a polygon with thousands of vertices (a
detailed coastline or administrative boundary) can cost minutes *per
evaluation* — with ~200 Monte Carlo simulations that's hours. Before
committing to a correction, time one evaluation:
```r
system.time(Lest(P, correction = "Ripley", rmax = 10000))
```
If it's more than a couple of seconds, switch to the **translation**
correction on a **rasterized mask window** (`as.mask(win, eps = 250)`),
which is typically 100x faster and gives near-identical results at
epidemiologically relevant distances — translation and isotropic are both
valid edge corrections for the same estimator, so this is a performance
choice, not a methods compromise. Use Kaplan-Meier correction for G/F.

### 7. Sensitivity checks

Re-run the key inhomogeneous test on the de-duplicated pattern (rescaling
the population offset to the reduced point count). If the finding survives,
it isn't a duplicate-coordinate artifact.

### 8. Hotspot localization

Aggregate observed vs. population-expected counts per administrative
polygon, compute a standardized ratio (observed / expected) and a Poisson
upper-tail p-value per unit, and name the top few by their administrative
label — this is what a reader actually wants after "clustering is
significant," namely *where*.

## Known pitfalls (from real runs)

| Symptom | Cause | Fix |
|---|---|---|
| `st_crs()` returns NA silently | PROJ_DATA unbound in conda env | `Sys.setenv(PROJ_DATA=...)` before any CRS call; verify with a distance round-trip |
| `quarto render` fails, mentions deno/dom | `QUARTO_DENO_DOM` hook points at nonexistent build path | export full QUARTO_* var set before rendering |
| `bw.diggle` gives an implausibly tiny bandwidth | duplicate/tied coordinates | prefer `bw.ppl`, report both, note the discrepancy |
| `clarkevans.test(correction="Donnelly")` errors | window is a polygon, not a rectangle | use `correction = "cdf"` |
| Envelope simulation runway looks infinite | Ripley correction on a many-vertex polygon window | time one evaluation first; switch to translation correction on `as.mask()` if slow |
| Population-offset test result looks inverted at some locations | raster row order vs. image row order mismatch | sanity-check the built `im` at one known urban and one known rural point before running the envelope |
| Report period differs from filename-implied period | surveillance extracts often carry onset dates spilling past the nominal year | report the actual min/max date range; flag (don't drop) isolated outliers |

## Files in this skill

- `kernel.R` — `fix_proj_env()`, `build_ppp()`, `audit_duplicates()`,
  `population_offset()` helpers, auto-loaded into the R kernel whenever this
  skill is loaded.
