# Source comparison and conflict resolution

Three groups of sources were compared function by function:

- **M**: Moraga, P. (2019) *Geospatial Health Data: Modeling and Visualization with R-INLA and Shiny*, Chapman & Hall/CRC. Online: <https://www.paulamoraga.com/book-geospatial/> (Ch. 4 "The R-INLA package"; Ch. 5-10).
- **B**: Blangiardo, M., Cameletti, M., Baio, G. & Rue, H. (2013) Spatial and spatio-temporal models with R-INLA. *Spatial and Spatio-temporal Epidemiology* 4:33-49.
- **K**: KIM's tutorials (secondary): `overall_inla.qmd` (a modernised replication of B), `inla-poisson.qmd` (NY8 leukaemia, a critical replication of a 2019 Poisson tutorial), `gambia_inla_tutorial.qmd` (a replication of M Ch. 9).

**Rule:** where they truly conflict, M and B are authoritative. Where M or B use
functions the current R-INLA has deprecated, the skill uses the current
replacement and lists the original, because the original call may no longer run.
That is not a conflict about method; the model is the same.

## Summary

There are **no substantive methodological conflicts**. K mostly follows M and
B, updated to current R-INLA. Most differences are API changes since 2013/2019,
or K adding checks that M and B do not cover. The items below are the places
where a reader could think the sources disagree.

## Function / argument comparison

| Topic | M | B | K | Resolution in this skill |
|---|---|---|---|---|
| Install | `install.packages("INLA", repos = ".../R/stable", dep = TRUE)` | r-inla.org | Same; plus `inla.binary.install(os = "CentOS Linux-7")` for old-glibc hosts such as Posit Connect Cloud (Gambia) | M's call; K's binary fix as a deployment tip |
| Main call | `inla(formula, family, data, control.*)` | same | same | Agree |
| Areal spatial effect | `besag` + `iid` with `scale.model = TRUE`, and `bym2` with PC priors | `bym` (one term) with default loggamma priors | `bym2` + PC priors (London, Georgia, NY8 final model); `bym` only when replicating | **bym2 recommended** (M; Riebler et al. 2016). `bym` documented for reading older work. Not a conflict: same model family, newer parameterisation |
| BYM2 PC prior values | `prec c(0.5/0.31, 0.01)`, `phi c(0.5, 2/3)` | (n/a) | `prec c(1, 0.01)`, `phi c(0.5, 0.5)` | Different values, same syntax. **Default to M**; K's values as sensitivity analysis |
| Default hyperprior | Gamma(1, 5e-05) on precision; recommends PC priors | loggamma(1, 0.0005), example of changing via `hyper` | Shows default can be badly behaved (NY8 iid precision) | Use PC priors; state them |
| Graph | `poly2nb` -> `nb2INLA` -> `inla.read.graph` | from shapefile via maptools/spdep | Same, or pass `nb2mat(..., style = "B")` as a sparse `Matrix` to `graph =`; checks islands and components | Both forms valid; add K's structural checks |
| Spatial fraction | `Phi` (bym2) | Empirical: `var(u)/(var(u) + 1/tau_v)` for bym | `Phi` | Phi for bym2; B's formula for bym |
| Space-time areal | Ch. 7: linear trend, rw1/rw2, Knorr-Held types | Bernardinelli `f(ID.area1, year, model = "iid")`, rw1 + iid, + iid interaction | Same three models as B, with bym2 instead of bym | Agree |
| Exceedance probability | `1 - inla.pmarginal(c, marginals.fitted.values[[i]])` on total RR | `inla.pmarginal` on `exp(xi)` (residual RR) | London: `1 - inla.pmarginal(0, marginals.random$ID[1:n])` (residual) ; NY8: on fitted values (total) | Both valid but **different quantities**: total risk vs covariate-adjusted residual risk. Skill documents both and says to label which one |
| Transform marginals | `inla.tmarginal` | `inla.marginal.transform` | notes rename | `inla.tmarginal` (current name) |
| Predictor marginals | `return.marginals.predictor = TRUE` | Returned by default in 2013 | Required now; shows empty list without it | Always request it |
| Prediction rows link | `control.predictor = list(compute = TRUE, link = 1)` | `compute = TRUE`; linear predictor used directly | `link = 1` | Use `link = 1` |
| Mesh | `inla.mesh.2d(loc, max.edge, cutoff)` in lon/lat (Gambia) | `inla.mesh.create.helper(points, points.domain, offset, max.edge, min.angle)` in km | `fmesher::fm_mesh_2d_inla()` (Swiss, Piemonte, km); `inla.mesh.2d` in lon/lat (Gambia, following M) | `fm_mesh_2d_inla()` (same interface, current package); old names listed. **Units:** M uses degrees, B uses km. Skill prefers km (B) and explains how to read a range in degrees (M) |
| SPDE model | `inla.spde2.matern(mesh, alpha = 2, constr = TRUE)` | `inla.spde2.matern(mesh)` | `inla.spde2.pcmatern(prior.range, prior.sigma)` (overall); `inla.spde2.matern(alpha = 2)` (Gambia) | Both valid. pcmatern recommended for interpretable priors (Fuglstad et al. 2019); matern kept for M/B reproduction |
| Range / variance | (Ch. 8: `inla.spde2.result`) | `inla.spde2.result(mod, "field", spde)` + `inla.emarginal` | pcmatern: read `Range for field`, `Stdev for field` from `summary.hyperpar`; Gambia: `inla.spde2.result(..., do.transform = TRUE)` | Agree; depends on which SPDE constructor was used |
| Gambia range in km | — | — | `range_degrees * 111` | Approximate: a degree of longitude is 111 km x cos(lat) (about 108 km at 13.5°N); prefer refitting in km |
| Projector matrix | `inla.spde.make.A(mesh, loc)` | same, with `group`, `n.group` for time | same | Agree; `fmesher::fm_basis()` is the newer equivalent |
| Stack order | `A = list(1, A)`, `effects = list(data.frame(b0 = 1, ...), s = idx)` | `A = list(A, 1)`, `effects = list(c(idx, list(Intercept = 1)), list(Elevation = ...))` | follows M (Gambia) and B (Swiss) | Both valid; **pairing by position** is what matters |
| Intercept with stack | `y ~ 0 + b0 + ...` | `rain ~ -1 + Intercept + ...` | both; explains it is still an intercept | Agree |
| Grid projection | (rasterize predictions at points) | `inla.mesh.projector` / `inla.mesh.project` | `fm_evaluator` / `fm_evaluate` | fmesher names; old names listed |
| Two-step fit for big grids | — | `control.mode = list(theta = mod.mode$mode$theta, restart = FALSE)` | same | Agree |
| Model comparison | DIC (Ch. 4) | DIC | DIC + WAIC; PIT histogram and LCPO (Gambia); warns marginal likelihood not comparable under improper priors; DIC differences < ~2 are noise | Skill includes all of these; K's warnings are additions, not conflicts |
| Poisson with non-integer counts | — | — | `family = "xpoisson"` because `"poisson"` stops on non-integer y in current INLA | Added as K's guidance (M and B do not cover it); confirmed on INLA 26.06.08 (error text: "The inla program call crashed.") |
| Leroux / SLM | — | — | `generic1` with `C = I - ICAR`; `slm` model | Added as optional models from K |
| Confounding / effect size | — | — | Spatial confounding (SD inflation); report per-IQR RR | Added as interpretation guidance from K |

## Items checked and found consistent

- `f()` index must be unique per term (M, B, K agree; duplicate `ID2 <- ID`).
- `E =` for Poisson expected counts (M, B, K agree). Fitted values are RR, not counts.
- `Ntrials =` for binomial (M, K agree).
- `control.family = list(link = "logit")` for binomial (M, K agree).
- Exceedance threshold on a transformed scale (B: log PM10; K: `log(50)`).

## Tested

All templates were run on 2026-10-27 with R 4.6.0 (Windows 11), INLA 26.06.08
(compact mode), fmesher 0.8.0, sf 1.1.3, spdep 1.4.2, terra 1.9.50, geoR 1.9.6,
inlabru 2.15.0 and SpatialEpi 1.2.8, on `SpatialEpi::scotland` (areal Poisson,
binomial, Gaussian, Leroux, space-time) and `geoR::gambia` (SPDE binomial,
Gaussian, Poisson, space-time). Failures found in that run were corrected.
Reference results: Scotland BYM2 AFF beta 4.62 (95% CrI 1.96-7.23), Phi 0.75,
DIC 450.6 / 313.1 / 301.0 (fixed / iid / bym2); Gambia SPDE range 23.0 km
(10.9-43.4), Stdev 0.98 on a 459-node mesh. Re-run after a major INLA upgrade.
