# R-INLA function reference

Functions used for spatial analysis with INLA, grouped by task. "Source"
records where each appears: **M** = Moraga, *Geospatial Health Data* (2019);
**B** = Blangiardo, Cameletti, Baio & Rue (2013); **F** = current
`fmesher` package (the mesh engine split out of INLA in 2023); **K** = KIM's
tutorials (secondary). Run `?name`
or `inla.doc("name")` for full documentation.

## Setup and discovery

| Function | Use | Source |
|---|---|---|
| `install.packages("INLA", repos = c(getOption("repos"), INLA = "https://inla.r-inla-download.org/R/stable"), dep = TRUE)` | INLA is not on CRAN; install from its repository | M |
| `inla.binary.install(os = "CentOS Linux-7")` | Install an INLA binary built for an older glibc (deployment hosts) | K |
| `inla.version()` | Report the installed version alongside results | — |
| `inla.upgrade(testing = FALSE)` | Update to the latest stable build | — |
| `names(inla.models()$likelihood)` | List available likelihoods (`family` values) | M, B |
| `names(inla.models()$latent)` | List available latent models for `f(model = ...)` | M, B |
| `names(inla.models()$prior)` | List available priors | M |
| `inla.doc("name")` | Open the documentation for a likelihood, latent model or prior (e.g. `"bym2"`, `"pc.prec"`, `"poisson"`) | M, B |
| `inla.setOption(num.threads = "4:1")` | Control parallelism | — |

## Model fitting

| Function / argument | Use | Source |
|---|---|---|
| `inla(formula, family, data, ...)` | Fit the model; returns an `inla` object | M, B |
| `formula = y ~ x1 + x2 + f(...)` | Linear predictor; fixed effects as in `glm()`, latent effects with `f()`; `y ~ 0 + b0 + ...` removes the automatic intercept (needed with `inla.stack`) | M, B |
| `family = "gaussian" / "binomial" / "poisson" / "nbinomial" / "zeroinflatedpoisson1"` | Likelihood | M, B |
| `family = "xpoisson"` | Poisson likelihood that accepts non-integer responses | K |
| `E = E` | Poisson/nbinomial expected counts; `log(E)` enters as a fixed offset outside the linear predictor | M, B |
| `Ntrials = n` | Binomial number of trials per row | M |
| `offset(log(pop))` in formula | Offset inside the linear predictor (fitted values become counts) | — |
| `weights`, `scale` | Observation weights; `scale` multiplies the Gaussian precision per observation | — |
| `control.predictor = list(compute = TRUE, link = 1, A = inla.stack.A(stk))` | Compute linear predictor and fitted value marginals; `link = 1` back-transforms NA (prediction) rows; `A` passes the SPDE projection matrix | M, B |
| `control.compute = list(dic, waic, cpo, config, return.marginals.predictor, mlik)` | Request DIC, WAIC, CPO/PIT, posterior sampling support, predictor marginals, marginal likelihood | M, B |
| `control.fixed = list(mean.intercept, prec.intercept, mean, prec)` | Priors on fixed effects (defaults: intercept N(0, prec 0); others N(0, prec 0.001)) | M |
| `control.family = list(link = "logit", hyper = list(prec = ...))` | Link and priors for likelihood hyperparameters (e.g. Gaussian precision, nbinomial size) | M |
| `control.inla = list(strategy = "simplified.laplace", int.strategy = "auto")` | Approximation (`gaussian`, `simplified.laplace` default, `laplace`, `adaptive`) and integration (`auto`, `grid`, `ccd`, `eb`) | M, B |
| `control.mode = list(theta = fit0$mode$theta, restart = FALSE)` | Start (or fix) the hyperparameter mode from a previous fit, e.g. fit on the estimation stack then predict on the full stack | B |
| `inla.set.control.fixed.default()` | Show default fixed-effect priors | M |
| `inla.hyperpar(res)` | Refine hyperparameter marginals; skipped in compact mode and deprecated in classic mode (INLA 26) — use `control.inla = list(int.strategy = "grid")` instead | M |
| `inla.rerun(res)` | Rerun starting from the current mode (use when `mode.status != 0`) | — |
| `inla.cpo(res)` | Recompute CPO values flagged in `res$cpo$failure` | — |

## Latent models inside `f()`

General form: `f(index, model = "...", graph = g, hyper = prior, scale.model = TRUE, constr = TRUE, group = , control.group = , replicate = )`.

| `model =` | Structure | Typical use | Key hyperparameters | Source |
|---|---|---|---|---|
| `"iid"` | Exchangeable N(0, 1/tau) | Unstructured area effect, overdispersion, hospital effect | `prec` | M, B |
| `"besag"` | Intrinsic CAR (ICAR) on a graph | Spatially structured area effect | `prec` | M, B |
| `"bym"` | besag + iid in one term (original BYM) | Disease mapping (older parameterisation) | `prec.unstruct`, `prec.spatial` | B |
| `"bym2"` | Scaled BYM, total precision + mixing `phi` | Disease mapping, recommended | `prec`, `phi` | M |
| `"besagproper"` | Proper CAR | Alternative areal prior | `prec`, `diag` | — |
| `"generic1"` with `Cmatrix = I - ICAR` | Leroux CAR | Mixes iid and ICAR precision | `prec`, `beta` | K |
| `"slm"` with `args.slm` | Spatial lag model | Econometric-style spatial dependence | `prec`, `rho` | K |
| `"rw1"`, `"rw2"` | Random walk of order 1/2 | Smooth temporal trend or non-linear covariate effect | `prec` | M, B |
| `"ar1"` | First-order autoregressive | Temporal correlation, also in `control.group` | `prec`, `rho` | M, B |
| `spde` object (`model = spde`) | Matern field via SPDE on a mesh | Geostatistical / point-referenced effect | `range`, `stdev` (pcmatern) or `theta1`, `theta2` | M, B |

Extra arguments of `f()`:

- `graph = g` — neighbourhood graph from `inla.read.graph()` or an adjacency matrix.
- `hyper = list(prec = list(prior = "pc.prec", param = c(U, alpha)))` — priors on the internal scale.
- `scale.model = TRUE` — scale ICAR/RW so the generalised variance is 1 (comparable priors).
- `constr = TRUE` — sum-to-zero constraint (default for intrinsic models).
- `group = time, control.group = list(model = "ar1")` — replicate the effect over groups with AR(1) (or `"exchangeable"`, `"rw1"`) correlation across groups; Kronecker space-time models.
- `replicate = r` — independent replicates sharing hyperparameters.
- `f(id, w, model = "iid")` — second variable `w` is a weight (e.g. area-specific linear trend `f(idarea1, year, model = "iid")`).

## Priors

| Prior | Meaning of `param` | Use |
|---|---|---|
| `"pc.prec"` | `c(U, alpha)`: P(sd > U) = alpha | Any precision |
| `"pc"` (for `phi` in bym2) | `c(U, alpha)`: P(phi < U) = alpha | Spatial mixing parameter |
| `"pc.cor1"`, `"pc.cor0"` | P(rho > U) = alpha (base rho = 1 or 0) | AR(1) correlation |
| `"loggamma"` | `c(shape, rate)` on log precision | Older default (`c(1, 5e-05)` / `c(1, 0.0005)`) |
| `"normal"`, `"gaussian"` | `c(mean, precision)` | Fixed effects, internal-scale hyperparameters |
| `inla.spde2.pcmatern(prior.range = c(r0, p), prior.sigma = c(s0, p))` | P(range < r0) = p; P(sd > s0) = p | Matern field |

## Areal-data helpers (spdep / SpatialEpi)

| Function | Use | Source |
|---|---|---|
| `spdep::poly2nb(map, queen = TRUE)` | Neighbour list from shared boundaries | M |
| `spdep::nb2INLA("map.adj", nb)` | Write neighbour list to INLA graph file | M |
| `inla.read.graph("map.adj")` | Read graph file into an `inla.graph` | M |
| `spdep::nb2mat(nb, style = "B", zero.policy = TRUE)` | Binary adjacency matrix; can be passed as `graph =` directly | — |
| `spdep::card(nb)`, `spdep::n.comp.nb(nb)` | Neighbour counts (zero = island) and number of connected components | K |
| `SpatialEpi::expected(population, cases, n.strata)` | Expected counts by indirect standardisation | M |

## SPDE / geostatistics

| INLA (as in the papers) | Current replacement | Use | Source |
|---|---|---|---|
| `inla.mesh.create.helper(points, points.domain, offset, max.edge, min.angle)` | `fmesher::fm_mesh_2d_inla(...)` | Build a triangulation (2013-era helper) | B |
| `inla.mesh.2d(loc, boundary, max.edge = c(inner, outer), cutoff, offset)` | `fmesher::fm_mesh_2d_inla(...)` / `fm_mesh_2d()` | Build a triangulation around observation locations; smaller inner `max.edge` inside, larger outside | M, F, K |
| `inla.nonconvex.hull(coo, convex = )` | `fmesher::fm_nonconvex_hull()` | Boundary around points | M, F |
| `inla.spde2.matern(mesh, alpha = 2, constr = )` | (still current) | SPDE Matern model with log-normal priors on internal `theta` | M, B |
| `inla.spde2.pcmatern(mesh, prior.range, prior.sigma)` | (still current, preferred) | SPDE Matern model with PC priors on range and sd | K |
| `inla.spde.make.index("s", n.spde = spde$n.spde, n.group = )` | (still current) | Named index list for the spatial (and group) effect | M, B |
| `inla.spde.make.A(mesh, loc, group, n.group)` | `fmesher::fm_basis(mesh, loc)` (+ `fm_row_kron` for groups) | Projection matrix from mesh nodes to locations | M, B, F |
| `inla.stack(tag, data, A, effects)` | (still current) | Bundle response, projection matrices and effects; `A` and `effects` lists are paired by position | M, B |
| `inla.stack.data(stk, spde = spde)` | | Data argument for `inla()` | M, B |
| `inla.stack.A(stk)` | | `A` argument for `control.predictor` | M, B |
| `inla.stack.index(stk, tag = "pred")$data` | | Row indices of a tagged block in `summary.fitted.values` / `summary.linear.predictor` | M, B |
| `inla.spde2.result(res, "s", spde, do.transform = TRUE)` | (still current) | Marginals of range, variance, kappa, tau of the Matern field | B |
| `inla.mesh.projector(mesh, xlim, ylim, dims)` | `fmesher::fm_evaluator(mesh, xlim, ylim, dims)` | Lattice projector for mapping a field | B, F, K |
| `inla.mesh.project(proj, field)` | `fmesher::fm_evaluate(proj, field)` | Project node values to a grid | B, F |
| `plot(mesh)` | `ggplot() + inlabru::gg(mesh)` or `fmesher::geom_fm(data = mesh)` | Inspect mesh | M, F |

## Posterior marginals

A marginal is a two-column matrix (`x`, `y`). These functions work on any
element of `res$marginals.fixed`, `marginals.random`, `marginals.hyperpar`,
`marginals.fitted.values`, `marginals.linear.predictor`.

| Function | Use | Source |
|---|---|---|
| `inla.tmarginal(fun, marg)` | Marginal of a transformation (e.g. `exp` for RR/OR, `function(x) 1/x` for variance, `function(x) exp(-x/2)` on `internal.marginals.hyperpar` for SD) | M, B |
| `inla.emarginal(fun, marg)` | Posterior expectation of `fun(x)` | M, B |
| `inla.zmarginal(marg, silent = TRUE)` | Mean, sd and quantiles of a marginal | M |
| `inla.pmarginal(q, marg)` | CDF: `1 - inla.pmarginal(c, marg)` is the exceedance probability P(x > c) | M, B |
| `inla.qmarginal(p, marg)` | Quantiles | M |
| `inla.dmarginal(x, marg)` | Density at x | M |
| `inla.hpdmarginal(p, marg)` | Highest posterior density interval | — |
| `inla.smarginal(marg)` | Spline-smoothed marginal for plotting | M |
| `inla.rmarginal(n, marg)` | Random draws from a single marginal | — |

## Joint posterior sampling and prediction checks

| Function | Use | Source |
|---|---|---|
| `inla.posterior.sample(n, res)` | Draws from the joint approximate posterior (needs `control.compute = list(config = TRUE)`) | M |
| `inla.posterior.sample.eval(fun, samples)` | Evaluate a function (e.g. `function(...) Predictor`) on each draw | — |
| `inla.hyperpar.sample(n, res)` | Draws of hyperparameters | — |
| `inla.group.cv(res, num.level.sets = 3)` | Leave-group-out cross-validation (groups of correlated observations), returns `cv` log scores | — |

## Result slots

| Slot | Content |
|---|---|
| `summary.fixed`, `marginals.fixed` | Fixed effects (incl. `kld`) |
| `summary.random[[name]]`, `marginals.random[[name]]` | Each `f()` term (for bym/bym2: 2n rows) |
| `summary.hyperpar`, `marginals.hyperpar` | Hyperparameters on user scale (precisions, phi, range, rho) |
| `internal.summary.hyperpar` | Hyperparameters on the internal (log/logit) scale |
| `summary.linear.predictor`, `summary.fitted.values` (+ `marginals.`) | `eta` and `g^-1(eta)` per row |
| `dic` (`$dic`, `$p.eff`, `$local.dic`), `waic` (`$waic`, `$p.eff`, `$local.waic`) | Information criteria |
| `cpo` (`$cpo`, `$pit`, `$failure`) | Leave-one-out predictive quantities |
| `mlik` | Log marginal likelihood |
| `mode$mode.status`, `mode$theta` | Optimiser status (0 = OK) and hyperparameter mode |
| `cpu.used` | Run time |
