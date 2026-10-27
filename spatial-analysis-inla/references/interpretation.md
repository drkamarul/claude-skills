# Interpreting INLA spatial models

INLA output is Bayesian: every quantity is a posterior distribution. Report
the posterior mean (or median) with a 95% credible interval (CrI), and use
posterior probabilities where a decision threshold matters. Do not use the
word "significant"; say "the 95% CrI excludes 1" or "P(RR > 1 | y) = 0.97".

## 1. Scales by likelihood

| Family | `beta` scale | Report | Intercept means | Fitted values |
|---|---|---|---|---|
| Gaussian | identity | `beta` as is: change in mean of y per unit x | Mean y when all x = 0 | Mean of y (smooth surface, excludes nugget) |
| Binomial (logit) | log-odds | `OR = exp(beta)` | `plogis(b0)` = probability at x = 0 and field = 0 | Probability / prevalence |
| Poisson with `E` | log-RR | `RR = exp(beta)` | `exp(b0)` = overall RR vs the standard population | Relative risk `theta_i` |
| Poisson with `offset(log(pop))` | log-rate | Rate ratio `exp(beta)` | `exp(b0)` = baseline rate per person | Expected count |

Back-transform the **marginal**, not the summary:

```r
fx <- lapply(res$marginals.fixed, \(m) inla.zmarginal(inla.tmarginal(exp, m), silent = TRUE))
tab <- do.call(rbind, lapply(fx, \(z) unlist(z[c("mean", "quant0.025", "quant0.5", "quant0.975")])))
tab                                     # OR or RR, 95% CrI

# Posterior probability of a harmful effect
sapply(res$marginals.fixed, \(m) 1 - inla.pmarginal(0, m))   # P(beta > 0 | y)
```

Exponentiating the 2.5% and 97.5% quantiles directly is fine (quantiles are
invariant to monotone transforms); exponentiating the mean is not
(`exp(E[beta]) != E[exp(beta)]`).

### Make the contrast meaningful

A "per one-unit" effect is only interpretable if one unit is a realistic
change. For skewed or wide-ranged covariates, report per IQR or per SD
(KIM, inla-poisson.qmd):

```r
iqr <- IQR(dat$x)
b   <- res$summary.fixed["x", ]
exp(c(mean = b$mean, lo = b$`0.025quant`, hi = b$`0.975quant`) * iqr)   # RR per IQR
```

Standardise covariates before fitting when you want effects on a common scale.

## 2. Hyperparameters

Reported as **precisions** `tau = 1/sigma^2`. Convert:

```r
# Transform the internal log-precision; 1/sqrt() on the precision marginal fails
# ("NaNs produced", "missing value where TRUE/FALSE needed") when its tail is long
sd_marg <- inla.tmarginal(\(x) exp(-x / 2), res$internal.marginals.hyperpar[["Log precision for idarea"]])
# Gaussian residual SD: "Log precision for the Gaussian observations"
inla.zmarginal(sd_marg)
```

| Hyperparameter | Meaning | How to read |
|---|---|---|
| `Precision for the Gaussian observations` | Residual/nugget precision | `1/sqrt()` = residual SD in y units |
| `Precision for idarea` (iid) | Between-area heterogeneity | SD on linear-predictor scale; `exp(2*SD)` is roughly the ratio of high (≈97.5th) to median area RR |
| `Precision for idarea` (bym2) | Total precision of the combined area effect | Overall variability of residual log-RR / logit |
| `Phi for idarea` (bym2) | Proportion of that variance that is spatially structured | Near 1: smooth geographical pattern; near 0: unstructured noise; wide CrI hugging the prior = data not informative |
| `Precision for idarea (iid component)` / `(spatial component)` (bym) | Two separate precisions | Not directly comparable (conditional vs marginal); use the empirical spatial fraction below |
| `Range for s` (pcmatern) | Practical range of the Matérn field | Distance (mesh units, e.g. km) beyond which correlation < 0.1 |
| `Stdev for s` (pcmatern) | Marginal SD of the field | Size of spatial variation on linear-predictor scale |
| `Theta1 for s`, `Theta2 for s` (matern) | Internal log(tau), log(kappa) | Do not interpret; use `inla.spde2.result()` |
| `Rho for x` (ar1 `f()` term), `GroupRho for s` (`control.group = list(model = "ar1")`) | AR(1) correlation | Temporal persistence |
| `Precision for ID.year` (rw1/rw2) | Smoothness of the time trend | Larger = smoother |

### Spatial fraction with the original BYM

Blangiardo et al. (2013) compute the empirical variance of the structured
effect and compare it with the iid variance:

```r
n   <- nrow(map)
u   <- res$summary.random$idarea$mean[(n + 1):(2 * n)]   # structured component
s2u <- var(u)
s2v <- inla.emarginal(\(x) 1 / x, res$marginals.hyperpar[["Precision for idarea (iid component)"]])
s2u / (s2u + s2v)                                        # fraction spatial (0.97 in London suicides)
```

With bym2 this is simply `Phi`, with a full posterior (Moraga Ch. 5).

## 3. Area-level and surface results

| Quantity | Code | Reads as |
|---|---|---|
| Smoothed RR / prevalence / mean | `summary.fitted.values$mean` | Estimate for the area/location, shrunk toward neighbours |
| 95% CrI | `0.025quant`, `0.975quant` | Uncertainty; wide where data are sparse |
| Exceedance probability | `1 - inla.pmarginal(c, m)` over `marginals.fitted.values` | P(RR > c), P(prev > c), P(PM10 > limit) |
| Residual area RR (bym2) | `exp(summary.random$idarea$mean[1:n])` | Risk not explained by covariates |
| P(residual RR > 1) | `1 - inla.pmarginal(0, m)` over `marginals.random$idarea[1:n]` | Unexplained excess risk |

Exceedance probabilities (Richardson et al. 2004; Moraga Ch. 6):
- > 0.8: strong evidence the area exceeds the threshold.
- < 0.2: strong evidence it does not.
- 0.2-0.8: uncertain; do not label as a hotspot.

Thresholds on a transformed response must be transformed too: for log(PM10),
`P(PM10 > 50) = 1 - inla.pmarginal(log(50), m)` (Blangiardo et al.; KIM Piemonte).
For Gaussian models, `summary.fitted.values` is the smooth latent mean; to
predict a new *observation*, add the nugget variance.

## 4. What spatial effects do and do not tell you

- A spatial random effect absorbs any spatially smooth missing covariate. A
  large `phi` or short range describes residual pattern; it does not identify a
  "spatial process" unless relevant confounders are in the model (KIM,
  inla-poisson.qmd: residual spatial variation in NY8 was largely age structure).
- **Spatial confounding**: adding a spatial effect to a model with a spatially
  structured covariate can shift `beta` and inflate its SD (Reich et al. 2006;
  Hodges & Reich 2010). Report `beta` from both the non-spatial and spatial
  models and comment on the change.
- Ecological (area-level) associations are not individual-level effects.

## 5. Write-up template

> We fitted a Bayesian [Poisson/binomial/Gaussian] model with [BYM2/SPDE Matérn]
> spatial random effect using INLA (R-INLA version x). [Priors.] After adjustment
> for [covariates], each [IQR] increase in [x] was associated with a [RR/OR] of
> [est] (95% CrI [lo]-[hi]; P(RR > 1) = [p]). The spatially structured share of the
> residual variance was phi = [est] (95% CrI ...) [or: the practical range was
> [r] km (95% CrI ...)]. [k] of [n] areas had P(RR > 1) > 0.8, mainly in [region].
> The spatial model improved on the non-spatial model (WAIC [a] vs [b]); PIT
> values were approximately uniform.
