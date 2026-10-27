---
name: spatial-analysis-inla
description: >
  Bayesian spatial analysis in R with INLA (R-INLA) for Gaussian, binomial and
  Poisson outcomes: areal disease mapping (besag, BYM, BYM2) and geostatistical
  SPDE models, interpretation (RR, OR, exceedance probabilities, phi, range)
  and model assessment (DIC, WAIC, CPO, PIT, sensitivity). Use for INLA,
  disease mapping, small-area estimation, spatial Poisson or logistic
  regression, prevalence mapping, kriging, or any Bayesian spatial model in R.
---

# Spatial analysis with INLA in R

INLA (Rue, Martino & Chopin 2009) computes posterior marginals for **latent
Gaussian models** with nested Laplace approximations instead of MCMC. Almost
every spatial model you will meet in epidemiology is a latent Gaussian model:

```
y_i | eta_i, psi  ~  likelihood (gaussian | binomial | poisson)
eta_i = alpha + sum_m beta_m x_mi + sum_l f_l(z_li)        # linear predictor
f_l   ~ GMRF(psi)                                          # iid, besag, bym2, spde, rw1 ...
```

`alpha`, `beta` and the `f()` effects are the latent field `theta`; the
precisions, mixing and range parameters are the hyperparameters `psi`.
INLA returns `p(theta_i | y)` and `p(psi_k | y)` for each component.

Primary sources for this skill: Moraga (2019) *Geospatial Health Data*,
Ch. 4-10 (<https://www.paulamoraga.com/book-geospatial/>) and Blangiardo,
Cameletti, Baio & Rue (2013) *Spatial and spatio-temporal models with R-INLA*,
Spatial and Spatio-temporal Epidemiology 4:33-49. KIM's own tutorials
(London/Georgia/Swiss/Piemonte replication, NY8 Poisson, Gambia binomial SPDE)
are secondary sources that update these to the current API. Where sources
differ, Moraga and Blangiardo et al. win on method; the current R-INLA API wins
on function names. Details in
[references/source-comparison.md](references/source-comparison.md).

## Reference files

Read the one that matches the task before writing code. If the `references/`
folder is not next to this file, read them from
<https://github.com/drkamarul/claude-skills/tree/main/spatial-analysis-inla/references>.

| File | Read when |
|---|---|
| [references/function-reference.md](references/function-reference.md) | You need the purpose and key arguments of any R-INLA / fmesher / spdep function |
| [references/areal-models.md](references/areal-models.md) | Data are counts/means/proportions per polygon (district, county, census tract) |
| [references/geostatistical-spde.md](references/geostatistical-spde.md) | Data are measured at point locations and you want a continuous surface or prediction at new places |
| [references/interpretation.md](references/interpretation.md) | Turning output into RR/OR/means, exceedance maps, spatial fraction, range, write-up |
| [references/model-assessment.md](references/model-assessment.md) | Comparing models, checking fit, sensitivity analysis, cross-validation |
| [references/source-comparison.md](references/source-comparison.md) | Old code (from papers or tutorials) uses a function or default that looks different from what is here |

## Workflow

Work in this order. Each step has a checkpoint; do not continue past a
failed one.

1. **Classify the data.** Areal (one value per polygon) or point-referenced
   (one value per coordinate)? This decides the spatial effect: `besag`/`bym2`
   on a neighbourhood graph, or `spde` on a mesh.
2. **Choose the likelihood** from the outcome (table below). Check the
   response is on the right scale (counts are integers, binomial has trials,
   Gaussian is roughly symmetric, transform if not).
3. **Prepare the spatial structure.** Areal: `poly2nb()` -> `nb2INLA()` ->
   `inla.read.graph()`; check for islands (areas with zero neighbours).
   Points: project to a metric CRS (km), build a mesh, check it visually.
4. **Fit a non-spatial baseline** (fixed effects only, or `+ f(id, model = "iid")`).
   This is the reference for whether the spatial term earns its place.
5. **Fit the spatial model** with PC priors and
   `control.compute = list(dic = TRUE, waic = TRUE, cpo = TRUE, config = TRUE, return.marginals.predictor = TRUE)`.
6. **Check the fit ran cleanly**: `summary(res)`, no warnings, `res$mode$mode.status == 0`,
   `kld` near zero in `summary.fixed`, `sum(res$cpo$failure > 0)` small.
7. **Assess** (see model-assessment.md): DIC/WAIC/LCPO vs baseline, PIT
   histogram, posterior predictive check, prior and (SPDE) mesh sensitivity.
8. **Interpret** on the natural scale (see interpretation.md): exponentiate
   for RR/OR, transform precisions to SDs, map posterior mean, 95% CrI width
   and exceedance probabilities.
9. **Report**: model equation, priors, software version (`inla.version()`),
   fixed-effect table, hyperparameter table, maps, assessment table.

## Likelihood choice

| Outcome | `family` | Extra argument | Link | `exp(beta)` means | Fitted values are |
|---|---|---|---|---|---|
| Continuous (e.g. BMI, sqrt(rainfall), log(PM10)) | `"gaussian"` | — | identity | (no exp) change in mean per unit x | mean of y |
| Successes out of n (positives / tested) | `"binomial"` | `Ntrials = n` | logit | odds ratio | probability / prevalence |
| 0/1 per individual | `"binomial"` | `Ntrials = 1` (or omit) | logit | odds ratio | probability |
| Counts with expected counts (disease mapping) | `"poisson"` | `E = E` | log | relative risk | relative risk `theta_i` (E is **not** in the predictor) |
| Counts with population at risk | `"poisson"` | `+ offset(log(pop))` in formula | log | rate ratio | expected count (offset **is** in the predictor) |
| Non-integer "counts" (apportioned cases) | `"xpoisson"` | `E = E` | log | relative risk | relative risk |
| Over-dispersed counts | `"nbinomial"` | `E = E` | log | relative risk | relative risk |
| Excess zeros | `"zeroinflatedpoisson1"`, `"zeroinflatedbinomial1"` | as above | | | |

Poisson in disease mapping almost always means `E = E` with `E` from
indirect standardisation (`SpatialEpi::expected()`); this makes
`summary.fitted.values` the smoothed SIR/SMR. Check `inla.doc("poisson")`,
`inla.doc("binomial")`, `inla.doc("gaussian")` for parameterisations.

## Minimal templates

The three families share one skeleton. Areal BYM2 (Moraga Ch. 5-6):

```r
library(INLA); library(sf); library(spdep)

nb <- poly2nb(map)                       # map is an sf polygon layer, rows = areas
nb2INLA("map.adj", nb)
g  <- inla.read.graph("map.adj")
map$idarea <- seq_len(nrow(map))

prior <- list(
  prec = list(prior = "pc.prec", param = c(0.5 / 0.31, 0.01)),  # P(sd > 0.5/0.31) = 0.01
  phi  = list(prior = "pc",      param = c(0.5, 2 / 3))          # P(phi < 0.5) = 2/3
)
formula <- Y ~ x1 + x2 + f(idarea, model = "bym2", graph = g, hyper = prior)

ctrl <- list(dic = TRUE, waic = TRUE, cpo = TRUE, config = TRUE,
             return.marginals.predictor = TRUE)

# Poisson (disease mapping)
res <- inla(formula, family = "poisson", data = st_drop_geometry(map), E = E,
            control.predictor = list(compute = TRUE), control.compute = ctrl)

# Binomial (cases out of n per area)
res <- inla(formula, family = "binomial", data = st_drop_geometry(map), Ntrials = n,
            control.predictor = list(compute = TRUE), control.compute = ctrl)

# Gaussian (area-level mean); the Gaussian precision is a likelihood hyperparameter
res <- inla(formula, family = "gaussian", data = st_drop_geometry(map),
            control.family = list(hyper = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))),
            control.predictor = list(compute = TRUE), control.compute = ctrl)
```

For point-referenced data, the template (mesh -> SPDE -> A -> stack -> fit ->
predict) is in [references/geostatistical-spde.md](references/geostatistical-spde.md).

## Reading the output

| Slot | Contains |
|---|---|
| `summary(res)` | Fixed effects, hyperparameters, DIC/WAIC, marginal log-likelihood, run time |
| `res$summary.fixed` | mean, sd, 0.025/0.5/0.975 quantiles, mode, `kld` for intercept and covariates (linear-predictor scale) |
| `res$summary.random$idarea` | Posterior of each area/node effect. For `bym2`/`bym`: rows `1:n` = total effect, rows `(n+1):2n` = structured part only |
| `res$summary.hyperpar` | Precisions (`1/variance`), `Phi` (bym2), `Range`/`Stdev` (pcmatern), `Rho` (ar1) |
| `res$summary.fitted.values` | Posterior of `g^{-1}(eta)`: RR, prevalence, or mean (needs `control.predictor = list(compute = TRUE)`) |
| `res$summary.linear.predictor` | Posterior of `eta` |
| `res$marginals.*` | Full marginal densities (two-column x, y matrices) for the functions `inla.*marginal()` |
| `res$dic$dic`, `res$waic$waic`, `res$cpo$cpo`, `res$cpo$pit` | Assessment quantities (requested in `control.compute`) |
| `res$mlik` | Log marginal likelihood (Laplace and Gaussian integration) |

Fixed effects and random effects are on the **linear-predictor scale**;
hyperparameters are reported as **precisions**. Always transform before
interpreting. Use `inla.tmarginal()` on the marginal, not a transform of the
summary mean, because `E[exp(beta)] != exp(E[beta])` and `E[1/tau] != 1/E[tau]`.

```r
# RR / OR with 95% CrI for every fixed effect
t(sapply(res$marginals.fixed, function(m)
  inla.zmarginal(inla.tmarginal(exp, m), silent = TRUE)[c("mean", "quant0.025", "quant0.975")]))

# SD of a random effect from its precision
inla.zmarginal(inla.tmarginal(function(x) 1 / sqrt(x),
                              res$marginals.hyperpar[["Precision for idarea"]]))

# Exceedance probability P(RR_i > 1 | y) for every area
map$exc <- sapply(res$marginals.fitted.values, function(m) 1 - inla.pmarginal(1, m))
```

## Hard rules

- **Install INLA from its own repository**, not CRAN:
  `install.packages("INLA", repos = c(getOption("repos"), INLA = "https://inla.r-inla-download.org/R/stable"), dep = TRUE)`.
  Report `inla.version()` with results; defaults change between releases.
  On hosts with an old glibc (e.g. Posit Connect Cloud) load fails with
  "GLIBC_2.38 not found"; run `INLA::inla.binary.install(os = "CentOS Linux-7")`.
- **One index per `f()`**: R-INLA will not allow two `f()` terms on the same
  variable. Duplicate it (`idarea2 <- idarea`) for besag + iid or space-time terms.
- **Graph order = data order**: the neighbourhood graph rows must match the
  `idarea` index (`1:n` in the same order as the polygons the graph came from).
- **Islands**: an area with no neighbours breaks `besag`/`bym2` assumptions.
  Connect it manually (`spdep::addlinks1` / edit the nb), or drop/flag it. Also
  handle disconnected sub-graphs (`scale.model = TRUE` scales each component).
- **Use `scale.model = TRUE`** for `besag`, `rw1`, `rw2` so priors on precision
  are comparable (bym2 scales internally).
- **Prefer PC priors** (`pc.prec`, `pc`, `inla.spde2.pcmatern`) over the
  old `loggamma(1, 0.0005)` defaults; state priors in the methods.
- **Project coordinates** to a metric CRS (km) before building an SPDE mesh;
  ranges and `max.edge` are in mesh units.
- **Prediction with NA**: rows with `y = NA` are predicted. Add `link = 1`
  inside `control.predictor` so their fitted values are on the response scale.
- **Stacks**: with `inla.stack`, remove the automatic intercept (`y ~ 0 + b0 + ...`)
  and supply `b0 = 1` in the effects; extract rows with `inla.stack.index(stk, tag)$data`.
- **Compare DIC/WAIC/LCPO only between models fitted to the same observed
  responses.** Prediction rows (`y = NA`) do not enter these criteria, so
  adding them is fine; dropping or adding observed rows is not.
- Do not claim "significance". Report the posterior mean, 95% credible
  interval, and where useful a posterior probability such as `P(beta > 0 | y)`.

## Common errors

| Symptom | Cause / fix |
|---|---|
| `family = "poisson"` stops on non-integer y | Use `"xpoisson"`, or round as a sensitivity check |
| `mlik` of ICAR/BYM model looks far worse | Improper prior: marginal likelihood not comparable; use DIC/WAIC/LCPO |
| `Error: f(idarea, ...) ... is used twice` | Duplicate the index variable for each `f()` |
| Fitted values for prediction rows look like logits | Missing `link = 1` in `control.predictor` |
| `marginals.fitted.values` is NULL | Add `return.marginals.predictor = TRUE` in `control.compute` |
| Many `cpo$failure > 0` | Run `res <- inla.cpo(res)` to recompute those CPOs; if many remain, model is mis-specified |
| Crash / "inla.core" error with SPDE | Mesh too fine or coordinates in metres/degrees; coarsen `max.edge`, add `cutoff`, project to km |
| Phi posterior hugging prior | Data carry little information about spatial vs unstructured split; report it, do not over-interpret |
| Range larger than the study region | Spatial field is nearly a constant trend; consider a covariate or coarser model; check mesh extension |
| Warnings about `inla.mesh.2d` / `inla.mesh.projector` deprecated | Use `fmesher::fm_mesh_2d_inla()` / `fm_evaluator()` (see source-comparison.md) |

## Output template for a report

1. Data and spatial units, CRS, number of areas/locations, neighbourhood definition or mesh summary (`mesh$n`).
2. Model equation with likelihood, link, linear predictor, priors.
3. Fixed effects table on natural scale (RR/OR/mean difference, 95% CrI, `P(>1)` or `P(>0)`).
4. Hyperparameter table (SDs, phi, range, rho) with 95% CrI.
5. Maps: posterior mean, CrI width or SD, exceedance probability.
6. Model comparison table (DIC, pD, WAIC, LCPO) and one sentence on PIT / predictive check.
7. Sensitivity statement (priors; mesh for SPDE).

Pair with `quarto-skill` for the document, `datamanagement` for data
preparation, and `spatial-point-pattern-analysis` when the data are event
locations rather than measurements.
