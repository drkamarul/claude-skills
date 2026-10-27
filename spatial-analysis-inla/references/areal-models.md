# Areal (lattice) models with INLA

Use when each observation belongs to a polygon (district, county, census tract)
and spatial dependence is defined by **adjacency**. Sources: Moraga Ch. 5-7;
Blangiardo et al. (2013) Sec. 3.2-3.3; KIM's `overall_inla.qmd` (London,
Georgia) and `inla-poisson.qmd` (NY8 leukaemia).

## 1. Data preparation

```r
library(INLA); library(sf); library(spdep); library(SpatialEpi); library(dplyr)

map <- st_read("areas.gpkg")             # one row per area, sorted consistently
map <- map |> arrange(area_code)         # fix the order once; graph and index follow it
map$idarea <- seq_len(nrow(map))
```

### Expected counts, SIR/SMR (Poisson disease mapping)

```r
# Indirect standardisation: population and cases sorted by area, then stratum,
# with zero-case strata present (Moraga Ch. 5)
E <- expected(population = pop_long$pop, cases = pop_long$cases, n.strata = 16)

# Without strata: overall rate x population
r   <- sum(map$Y) / sum(map$pop)
map$E   <- r * map$pop
map$SIR <- map$Y / map$E          # raw SIR/SMR: noisy where E is small
```

## 2. Neighbourhood graph

```r
nb <- poly2nb(map, queen = TRUE)      # shared boundary (queen) neighbours

# Structural checks before any CAR model (KIM, inla-poisson.qmd)
c(islands    = sum(card(nb) == 0),
  components = n.comp.nb(nb)$nc)

nb2INLA("map.adj", nb)                # write INLA graph file
g <- inla.read.graph("map.adj")       # or: g <- as(nb2mat(nb, style = "B"), "Matrix")
```

- **Islands** (0 neighbours): add links by hand (e.g. nearest neighbour via
  `spdep::knearneigh` + `knn2nb`, then union with `nb`), or model them without
  the spatial term. Do not leave them silently.
- **Several components** (e.g. mainland + islands): `scale.model = TRUE`
  (and bym2) scale each connected component; check `inla.doc("besag")` on
  `adjust.for.con.comp`.
- Graph row `i` must be the area with `idarea == i`.

## 3. Model ladder

Fit from simple to complex and keep each fit for comparison (KIM's NY8
tutorial uses exactly this ladder).

| Model | Formula fragment | What it adds |
|---|---|---|
| Fixed only | `Y ~ 1 + x` | Baseline; Poisson with no overdispersion |
| iid | `+ f(idarea, model = "iid", hyper = pc_prec)` | Unstructured heterogeneity (overdispersion) |
| ICAR | `+ f(idarea, model = "besag", graph = g, scale.model = TRUE)` | Pure spatial smoothing |
| BYM (original) | `+ f(idarea, model = "bym", graph = g)` | ICAR + iid in one term; two precisions compete (Blangiardo 2013) |
| BYM by parts | `+ f(idareau, model = "besag", graph = g, scale.model = TRUE) + f(idareav, model = "iid")` | Same as BYM, separate indices (Moraga Ch. 6) |
| **BYM2 (recommended)** | `+ f(idarea, model = "bym2", graph = g, hyper = pc_bym2)` | Total precision + mixing `phi` with PC priors (Riebler 2016; Moraga Ch. 5) |
| Leroux | `+ f(idarea, model = "generic1", Cmatrix = C)`, see below | Proper CAR mixing iid and ICAR precisions (KIM, inla-poisson.qmd, after Gómez-Rubio) |

Leroux construction (KIM, inla-poisson.qmd):

```r
W    <- as(nb2mat(nb, style = "B"), "Matrix")
ICAR <- Diagonal(nrow(W), rowSums(W)) - W     # ICAR structure matrix
C    <- Diagonal(nrow(W), 1) - ICAR           # generic1 needs max eigenvalue 1
max(eigen(C)$values)                          # check: 1
```

PC priors used in the sources:

```r
# Moraga Ch. 5: marginal SD rule of thumb 0.5, conservative phi
pc_bym2 <- list(prec = list(prior = "pc.prec", param = c(0.5 / 0.31, 0.01)),
                phi  = list(prior = "pc",      param = c(0.5, 2 / 3)))

# KIM's tutorials: P(sd > 1) = 0.01, P(phi < 0.5) = 0.5 (neutral on phi)
pc_bym2_kim <- list(prec = list(prior = "pc.prec", param = c(1, 0.01)),
                    phi  = list(prior = "pc",      param = c(0.5, 0.5)))

pc_prec <- list(prec = list(prior = "pc.prec", param = c(1, 0.01)))
```

Either is defensible; state the choice and run the other as a sensitivity
analysis (see model-assessment.md).

## 4. Fitting by likelihood

```r
ctrl <- list(dic = TRUE, waic = TRUE, cpo = TRUE, config = TRUE,
             return.marginals.predictor = TRUE)
dat  <- st_drop_geometry(map)
form <- Y ~ 1 + x1 + x2 + f(idarea, model = "bym2", graph = g, hyper = pc_bym2)
```

### Poisson (counts, disease mapping)

```r
res_p <- inla(form, family = "poisson", data = dat, E = E,
              control.predictor = list(compute = TRUE), control.compute = ctrl)
```

- `summary.fitted.values$mean` = smoothed relative risk `theta_i` (because `E`
  sits outside the predictor). Predicted counts = `theta_i * E_i`.
- Non-integer "counts" (e.g. NY8 `Cases`, which are apportioned): current INLA
  stops with `family = "poisson"`. Use `family = "xpoisson"` (Poisson that accepts
  non-integer y) or round as a sensitivity check (KIM, inla-poisson.qmd).
- Overdispersion beyond the iid/bym2 term: compare with `family = "nbinomial"`.
- Rate per population instead of SIR: drop `E`, add `+ offset(log(pop))`;
  fitted values are then expected counts.

### Binomial (k positives out of n per area)

```r
res_b <- inla(form, family = "binomial", Ntrials = n, data = dat,
              control.family = list(link = "logit"),
              control.predictor = list(compute = TRUE), control.compute = ctrl)
```

- `summary.fitted.values$mean` = area prevalence/probability.
- Individual-level 0/1 data with an area index: `Ntrials = 1`, the same
  `f(idarea, ...)`, and many rows per area.

### Gaussian (area-level continuous outcome)

```r
res_g <- inla(form, family = "gaussian", data = dat,
              control.family = list(hyper = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))),
              control.predictor = list(compute = TRUE), control.compute = ctrl)
```

- `Precision for the Gaussian observations` is the residual (nugget) precision.
- If area means are based on different sample sizes, pass `scale = n_i` so the
  residual precision is `tau * n_i`.

## 5. Spatio-temporal areal models

Blangiardo et al. Sec. 3.3 and KIM's Georgia example; data in long format,
one row per area-time.

```r
lbw <- lbw |>
  mutate(ID.area  = as.integer(factor(area)),  ID.area1 = ID.area,
         ID.year  = year - min(year) + 1,      ID.year1 = ID.year,
         ID.area.year = row_number())

# (1) Bernardinelli: area-specific linear trends
f1 <- y ~ 1 + f(ID.area, model = "bym2", graph = g, hyper = pc_bym2) +
          f(ID.area1, ID.year, model = "iid") + ID.year
# (2) Knorr-Held, no interaction: structured + unstructured time
f2 <- y ~ 1 + f(ID.area, model = "bym2", graph = g, hyper = pc_bym2) +
          f(ID.year, model = "rw1") + f(ID.year1, model = "iid")
# (3) + type I interaction (iid x iid)
f3 <- update(f2, . ~ . + f(ID.area.year, model = "iid"))
```

Other Knorr-Held interactions (types II-IV) use `group` with
`control.group = list(model = "rw1")` or `"besag"`, plus constraints; see
Moraga Ch. 7. Compare (1)-(3) with DIC/WAIC/LCPO; differences of a few units
are not decisive.

## 6. Extracting area-level results

```r
n <- nrow(map)

# Total smoothed RR / prevalence / mean (from fitted values)
map$est <- res_p$summary.fitted.values$mean
map$lo  <- res_p$summary.fitted.values$`0.025quant`
map$hi  <- res_p$summary.fitted.values$`0.975quant`
map$exc <- sapply(res_p$marginals.fitted.values, \(m) 1 - inla.pmarginal(1, m))   # P(RR > 1)

# Residual (covariate-adjusted) area effect from bym2: rows 1:n = total effect b_i
map$zeta  <- exp(res_p$summary.random$idarea$mean[1:n])
map$p_res <- sapply(res_p$marginals.random$idarea[1:n], \(m) 1 - inla.pmarginal(0, m))  # P(zeta > 1)
```

`exc` answers "is overall risk elevated here?"; `p_res` answers "is risk
elevated after accounting for the covariates?" Report which one a map shows.

## 7. Mapping

```r
library(ggplot2)
ggplot(map) + geom_sf(aes(fill = est), colour = "white", linewidth = 0.1) +
  scale_fill_viridis_c(name = "RR") + theme_void()
ggplot(map) + geom_sf(aes(fill = cut(exc, c(0, 0.2, 0.8, 1), include.lowest = TRUE))) +
  scale_fill_brewer(name = "P(RR > 1)", palette = "RdBu", direction = -1) + theme_void()
```

Always show the raw SIR/prevalence beside the smoothed estimate and add an
uncertainty map (CrI width or exceedance probability).
