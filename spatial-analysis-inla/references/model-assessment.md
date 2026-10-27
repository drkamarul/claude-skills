# Assessing INLA models

Assessment has four parts: (1) did the approximation run cleanly,
(2) which model is better, (3) does the chosen model fit the data,
(4) do conclusions survive reasonable changes to priors and (for SPDE) the
mesh. Request everything up front:

```r
control.compute = list(dic = TRUE, waic = TRUE, cpo = TRUE, config = TRUE,
                       return.marginals.predictor = TRUE)
```

## 1. Numerical health checks

```r
res$mode$mode.status           # 0 = optimiser converged; otherwise res <- inla.rerun(res)
res$summary.fixed[, "kld"]     # Kullback-Leibler distance of Gaussian vs (simplified) Laplace; near 0 is good
res$cpu.used
sum(res$cpo$failure > 0, na.rm = TRUE)   # unreliable CPO values
```

- Large `kld` or concern about accuracy (common with sparse binomial/Poisson
  data): refit with `control.inla = list(strategy = "laplace")` and compare.
- Hyperparameter marginals look rough: refit with
  `control.inla = list(int.strategy = "grid")`. (`inla.hyperpar()` is skipped in
  the default compact mode and deprecated in classic mode; do not use it.)
- CPO failures: flags are common in the default compact mode (33 of 56 on a
  Scotland BYM2 test) and recomputing them with `res <- inla.cpo(res)` changed
  values only in the 3rd-4th significant digit but took about 12 minutes. Read
  LCPO together with the failure count. Many failures signal a mis-specified
  likelihood (e.g. non-integer counts in a Poisson model; KIM, inla-poisson.qmd).
  Report the number rather than hiding it.

## 2. Model comparison

Fit a ladder (non-spatial -> iid -> spatial; or with/without a covariate) on
the **same observed data** and tabulate:

```r
cmp <- function(m, name) data.frame(
  model = name,
  DIC   = m$dic$dic,   pD   = m$dic$p.eff,
  WAIC  = m$waic$waic, pW   = m$waic$p.eff,
  LCPO  = -mean(log(m$cpo$cpo), na.rm = TRUE),
  mlik  = m$mlik[1, 1])
rbind(cmp(m0, "fixed"), cmp(m1, "iid"), cmp(m2, "bym2"))
```

| Criterion | Lower is better? | Notes |
|---|---|---|
| DIC (Spiegelhalter 2002) | yes | Used by Blangiardo et al. and KIM; `pD` = effective parameters |
| WAIC | yes | More stable than DIC for hierarchical models; used in KIM's tutorials |
| LCPO = -mean(log CPO) | yes | Leave-one-out log score; some authors use the sum (KIM Gambia: `-sum(log(cpo))`); be consistent |
| Marginal log-likelihood `mlik` | higher is better | **Not comparable** when a model has an improper prior (ICAR/besag, bym, rw1/rw2): its normalising constant is arbitrary (KIM, inla-poisson.qmd) |

Rules:
- Differences of a few units (< ~2-5) in DIC/WAIC are not evidence; choose on
  interpretability and purpose.
- Always include the non-spatial baseline so the gain from the spatial term is visible.
- DIC/WAIC/CPO ignore rows with `y = NA`, so prediction rows do not affect them.

### Out-of-sample validation

- Hold-out sites (Blangiardo et al. Swiss example): fit on estimation sites with
  validation sites as `y = NA` in a `"val"` stack, then
  ```r
  iv  <- inla.stack.index(stk, "val")$data
  pr  <- res$summary.fitted.values[iv, "mean"]
  c(RMSE = sqrt(mean((obs_val - pr)^2)), r = cor(obs_val, pr),
    coverage95 = mean(obs_val >= res$summary.fitted.values[iv, "0.025quant"] &
                      obs_val <= res$summary.fitted.values[iv, "0.975quant"]))
  ```
  (For Gaussian models the coverage of new observations needs the nugget; use
  posterior samples.)
- Leave-group-out CV, better than LOO when neighbours are correlated:
  ```r
  lgo <- inla.group.cv(res, num.level.sets = 3)
  -mean(log(lgo$cv))
  ```
  Requires `config = TRUE`. Compare LGOCV across models like LCPO.

## 3. Goodness of fit

### PIT histogram (calibration)

```r
hist(res$cpo$pit, breaks = 20, main = "PIT", xlab = "PIT")   # roughly uniform = well calibrated
```

U-shape: under-dispersed predictions (model too confident; consider iid or
nbinomial). Hump: over-dispersed. For discrete data the PIT is not exactly
uniform even for the true model; use it qualitatively.

### Observed vs fitted

```r
plot(dat$Y, res$summary.fitted.values$mean * dat$E,   # Poisson with E: counts
     xlab = "Observed", ylab = "Fitted"); abline(0, 1)
```

### Posterior predictive check

```r
set.seed(1)
s   <- inla.posterior.sample(500, res)                 # needs config = TRUE
eta <- sapply(s, \(x) x$latent[grep("^Predictor", rownames(x$latent))])  # with a stack, take "^APredictor" rows and subset them with inla.stack.index(stk, "est")$data
yrep <- apply(eta, 2, \(e) rpois(length(e), dat$E * exp(e)))   # Poisson; use rbinom / rnorm as needed
c(obs_var = var(dat$Y), rep_var_mean = mean(apply(yrep, 2, var)))
mean(apply(yrep, 2, \(y) mean(y == 0)) >= mean(dat$Y == 0))     # zeros check
```

### Residual spatial autocorrelation (optional)

```r
r <- (dat$Y - res$summary.fitted.values$mean * dat$E) / sqrt(res$summary.fitted.values$mean * dat$E)
spdep::moran.test(r, spdep::nb2listw(nb, style = "W", zero.policy = TRUE))
```

A non-spatial model with significant residual Moran's I justifies a spatial
term; the spatial model's residuals should show little remaining
autocorrelation. This is a frequentist diagnostic used alongside, not instead
of, the Bayesian checks.

## 4. Sensitivity analyses

### Priors

Refit with at least one alternative prior on each key hyperparameter and
compare fixed effects, phi/range, and maps:

```r
pc_a <- list(prec = list(prior = "pc.prec", param = c(0.5 / 0.31, 0.01)),
             phi  = list(prior = "pc", param = c(0.5, 2 / 3)))     # Moraga
pc_b <- list(prec = list(prior = "pc.prec", param = c(1, 0.01)),
             phi  = list(prior = "pc", param = c(0.5, 0.5)))       # KIM
fit_prior <- function(pr) inla(
  Y ~ 1 + x1 + x2 + f(idarea, model = "bym2", graph = g, hyper = pr),
  family = "poisson", E = E, data = dat,
  control.predictor = list(compute = TRUE), control.compute = list(waic = TRUE))
ma <- fit_prior(pc_a); mb <- fit_prior(pc_b)
rbind(Moraga = ma$summary.fixed[, "mean"], KIM = mb$summary.fixed[, "mean"])
rbind(Moraga = ma$summary.hyperpar["Phi for idarea", ], KIM = mb$summary.hyperpar["Phi for idarea", ])
```

Signs of prior dominance: posterior close to the prior (plot both), very wide
posterior for a precision (KIM's NY8 example: default loggamma gave a
precision posterior mean 3712 with SD 11264).

Use `inla.priors.used(res)` to print the priors actually applied (the output is long).

### Mesh (SPDE only)

Refit on 2-3 meshes (e.g. inner `max.edge` halved and doubled) and check that
range, sigma, fixed effects and predicted maps barely change. Large changes mean
the mesh is too coarse relative to the range.

### Data choices

Repeat with alternative covariate scales (e.g. log-transformed exposure),
alternative handling of non-integer counts (`xpoisson` vs rounded), or
alternative neighbour definitions (queen vs rook, k-nearest). KIM's NY8
tutorial shows the pattern: report whether the key effect and phi remain stable.

## 5. Assessment table for a report

| Model | DIC | pD | WAIC | LCPO | CPO failures | Key effect (95% CrI) | phi / range |
|---|---|---|---|---|---|---|---|
| Fixed effects | | | | | | | — |
| + iid | | | | | | | — |
| + BYM2 / SPDE | | | | | | | |
| Sensitivity: alt. prior | | | | | | | |
