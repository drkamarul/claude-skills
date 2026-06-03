---
name: lmer-mixed-effects
description: >
  Use this skill for ANY linear mixed-effects model (LMM) analysis in R.
  Trigger on: lmer, lme4, lmerTest, mixed model, multilevel model,
  hierarchical model, random intercept, random slope, random effects,
  fixed effects, REML, VarCorr, ranef, fixef, ICC, intraclass correlation,
  nested data, clustered data, repeated measures, broom.mixed, singular fit,
  model comparison with anova(), caterpillar plot, dotplot(ranef()),
  confint.merMod, Satterthwaite, 2-level model, school data, or fitting
  lmer(). Even if the user says "fit a mixed model", "account for
  clustering", "add random effects", or "hierarchical regression in R",
  use this skill. Complements datamanagement and quarto-skill.
---

# Linear Mixed-Effects Models with lme4

Comprehensive reference for fitting, interpreting, and diagnosing 2-level linear mixed-effects models in R using lme4. Based on Bates et al. (2015), JSS and Glenn Williams' R for Psych, Ch. 9.

## Core Philosophy

1. **Hierarchy requires LMM**: Observations nested in groups violate independence — LMMs partition variance across levels rather than ignoring clustering.
2. **REML for estimation, ML for comparison**: Fit with `REML = TRUE` (default); use ML when comparing models differing in fixed effects. `anova()` handles this automatically.
3. **Random effects shrink towards the mean**: Group estimates are partially pooled — a feature that reduces overfitting to small groups.
4. **No p-values by default**: lme4 omits p-values intentionally (degrees of freedom are not well-defined for mixed models). Use lmerTest for Satterthwaite approximation or likelihood ratio tests.

## Package Loading

```r
library(lme4)        # lmer(), glmer(), ranef(), VarCorr()
library(lmerTest)    # adds Satterthwaite p-values to summary()
library(tidyverse)
library(broom.mixed) # tidy(), augment() for lme4 objects
```

## Formula Syntax Quick Reference

| Formula | Meaning |
|---------|---------|
| `y ~ x + (1 \| g)` | Random intercept, fixed slope |
| `y ~ x + (x \| g)` | Correlated random intercept and slope |
| `y ~ x + (x \|\| g)` | Uncorrelated random intercept and slope |
| `y ~ x + (1 \| g1/g2)` | g2 nested within g1 — equivalent to `(1\|g1) + (1\|g1:g2)` |
| `y ~ x + (1 \| g1) + (1 \| g2)` | Crossed random effects |

**`(x|g)` vs `(x||g)`**: Use `(x|g)` (correlated, default) unless sample sizes are small or the correlation is not of interest. `||` forces independence but breaks invariance to predictor shifts (lmer.pdf §2.2).

## Standard Workflow

```r
# Step 1 — Null model (M0): baseline for ICC
m0 <- lmer(outcome ~ 1 + (1 | group), data = dat, REML = TRUE)

# Step 2 — Random intercept model (M1)
m1 <- lmer(outcome ~ var1 + var2 + var3 + (1 | group), data = dat, REML = TRUE)

# Step 3 — Random slope model (M2): allow ATTAIN effect to vary by school
m2 <- lmer(outcome ~ var1 + var2 + var3 + (var1 | group), data = dat, REML = TRUE)
```

## Reading `summary()` Output

```
Linear mixed model fit by REML ['lmerMod']
REML criterion at convergence: 1743.6     ← lower = better fit; compare via anova()

Scaled residuals:
    Min      1Q  Median      3Q     Max
-3.9536 -0.4634  0.0231  0.4634  5.1793  ← should be ~N(0,1); tails flag outliers

Random effects:
 Groups   Name        Variance Std.Dev. Corr
 Subject  (Intercept)  612.10   24.741        ← between-group variance (τ₀²)
          Days          35.07    5.922  0.07  ← random slope variance; correlation
 Residual              654.94   25.592        ← within-group variance (σ²)
Number of obs: 180, groups: Subject, 18       ← n_obs; grouping var; n_groups

Fixed effects:
             Estimate Std. Error t value    ← NO p-values in base lme4
(Intercept)   251.405      6.825  36.838
Days           10.467      1.546   6.771
```

**Key extractor functions:**

| Function | Returns |
|----------|---------|
| `fixef(m)` | Named vector of fixed-effect coefficients β̂ |
| `ranef(m)` | List of BLUPs (conditional modes) per group |
| `VarCorr(m)` | Variance components table (τ², σ², correlations) |
| `sigma(m)` | Residual SD (√σ²) |
| `coef(m)` | Fixed + random effects combined per group |
| `fitted(m)` | Fitted values conditional on random effects |
| `resid(m)` | Residuals |
| `nobs(m)` / `ngrps(m)` | Number of observations / groups |

## Variance Components and ICC

```r
# Extract variance components as a data frame
vc <- as.data.frame(VarCorr(m0))
# grp: grouping factor; var1/var2: variable names; vcov: variance; sdcor: SD/corr

# Intraclass correlation (ICC) from null model
icc <- vc$vcov[1] / sum(vc$vcov)
# ICC = τ₀² / (τ₀² + σ²)
# ICC > 0.05 justifies multilevel modelling
# ICC = proportion of total variance attributable to group membership
```

## p-values

lme4 intentionally omits p-values — degrees of freedom are ambiguous for unbalanced mixed models. Three options:

```r
# Option 1 — lmerTest: Satterthwaite df (recommended for most applied work)
library(lmerTest)
m1 <- lmer(outcome ~ var1 + var2 + var3 + (1 | group), data = dat)
summary(m1)    # now shows Df and Pr(>|t|) columns

# Option 2 — Likelihood ratio test: compare nested models
anova(m0, m1)  # auto-refits to ML; output: Chisq, Df, Pr(>Chisq)

# Option 3 — Parametric bootstrap: most rigorous, slowest
confint(m1, method = "boot", nsim = 1000)
# Absence of 0 in CI ≈ significance
```

## Model Comparison

```r
# LRT across model sequence — anova() refits to ML automatically
anova(m0, m1, m2)
# Output columns: npar, AIC, BIC, logLik, deviance, Chisq, Df, Pr(>Chisq)

# Single-model fixed-effects ANOVA table (requires lmerTest)
anova(m1)   # F statistics with Satterthwaite df

# Information criteria
AIC(m0, m1, m2)   # lower = better; penalises complexity
BIC(m0, m1, m2)   # stronger penalty for parameters than AIC
```

**Rule**: Compare models differing in **fixed effects** using ML (anova handles this). Compare models differing only in **random effects** structure using REML.

## Confidence Intervals

```r
confint(m1, method = "profile")           # profile likelihood — best, computationally intensive
confint(m1, method = "Wald")              # Wald — fast, acceptable for fixed effects (large n)
confint(m1, method = "boot", nsim = 999)  # bootstrap — slowest, most robust

# Profile CIs preferred for variance parameters (.sig01, .sigma)
# Wald acceptable for fixed-effect coefficients when data are large
```

## Diagnostics

```r
# 1 — Residuals vs fitted (check linearity and homoscedasticity)
plot(m1, type = c("p", "smooth"))

# 2 — Normal Q-Q of residuals (check normality assumption)
qqnorm(resid(m1)); qqline(resid(m1))

# 3 — Caterpillar plot: normality of random effects across groups
lattice::dotplot(ranef(m1, condVar = TRUE))
# Each group's BLUP ± CI; should fan symmetrically around 0

# 4 — Singular fit: random effects at boundary (near-zero variance)
isSingular(m1)
# If TRUE: simplify random effects structure (e.g., drop slope, use ||)

# 5 — Scale-location (heteroscedasticity)
plot(m1, sqrt(abs(resid(.))) ~ fitted(.))
```

## Tidy Output (broom.mixed)

```r
library(broom.mixed)

tidy(m1)                               # all fixed and random effect estimates
tidy(m1, effects = "fixed")            # fixed effects only (regression table)
tidy(m1, effects = "ran_pars")         # variance components
tidy(m1, effects = "fixed",
     conf.int = TRUE, conf.method = "Wald")  # with 95% CIs

augment(m1)   # observation-level: .fitted, .resid, .hat, .cooksd
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Comparing models with REML when fixed effects differ | Let `anova()` auto-refit to ML, or set `REML = FALSE` manually |
| Ignoring `isSingular()` warning | Check `isSingular(m)`; simplify RE structure or use `(x\|\|g)` |
| Omitting ICC from null model | Always fit M0 first; ICC < 0.05 may not justify MLM |
| Using `coef()` as "group-level effects" | `coef()` = β̂ + b̂ (combined); use `ranef()` for deviations only |
| Grouping variable left as numeric | Always `factor(SID)` before fitting |
| Using final model with `REML = FALSE` | Final reported model always uses `REML = TRUE` |
| Forcing `(x\|\|g)` without justification | Use `(x\|g)` (correlated) unless correlation is inestimable or near-zero |

## Key References

- Bates D, Mächler M, Bolker BM, Walker SC (2015). Fitting LMMs Using lme4. *JSS* 67(1). `docs/lmer.pdf`
- Williams G. R for Psych, Ch. 9: Mixed Effects Models. `docs/Chapter 9 Mixed Effects Models _ R for Psych.mhtml`
