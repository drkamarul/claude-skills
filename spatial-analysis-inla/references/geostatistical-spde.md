# Geostatistical (point-referenced) models with INLA-SPDE

Use when observations are tied to coordinates and the target is a continuous
surface or predictions at unsampled sites. The SPDE approach (Lindgren, Rue
& Lindström 2011) represents a Matérn Gaussian field as a GMRF on a triangulated
mesh, so cost is about O(n^{3/2}) instead of O(n^3). Sources: Moraga Ch. 8-10;
Blangiardo et al. (2013) Sec. 4; KIM's `overall_inla.qmd` (Swiss rainfall,
Piemonte PM10) and `gambia_inla_tutorial.qmd` (malaria prevalence).

Model: `y_i ~ likelihood(eta_i)`, `eta_i = b0 + x_i' beta + (A xi)_i`,
`xi ~ Matérn(range, sigma)`, with `A` the projector from mesh nodes to
observation locations.

## Step 1. Coordinates

```r
library(INLA); library(fmesher); library(sf); library(terra)

pts <- st_as_sf(d, coords = c("lon", "lat"), crs = 4326) |>
  st_transform(32628)                               # a metric CRS for the study area (here UTM 28N)
coo <- st_coordinates(pts) / 1000                   # km: ranges and max.edge then read in km
```

Prefer a projected CRS in km (as Blangiardo et al. and KIM's Swiss/Piemonte
examples do). Moraga's Gambia chapter meshes in lon/lat degrees; that works for a
small region but the range is then in degrees (1 degree of longitude is
111 km x cos(latitude)), so convert with care.

## Step 2. Mesh

```r
bnd  <- fm_nonconvex_hull(coo, convex = -0.05)       # or the study polygon
mesh <- fm_mesh_2d_inla(loc = coo, boundary = bnd,
                        max.edge = c(10, 50),        # inner, outer triangle edge (km)
                        cutoff   = 2,                # merge points closer than this
                        offset   = c(5, 30))         # inner and outer extension
mesh$n
plot(mesh); points(coo, col = "red", pch = 19)
```

Same call with the older INLA names (Moraga, Gambia tutorial):
`inla.mesh.2d(loc = coo, max.edge = c(0.1, 5), cutoff = 0.01)`; with the 2013
paper: `inla.mesh.create.helper(points = , points.domain = , offset = , max.edge = , min.angle = )`.

Mesh rules of thumb:
- Inner `max.edge` about range/5 to range/10 (guess the range first, refine after the first fit).
- Outer extension at least about one range beyond the data to avoid boundary effects
  (variance inflation near edges).
- `cutoff` > 0 avoids tiny triangles around near-duplicate locations.
- Check that the results (range, sigma, predictions) are stable across 2-3 meshes.

## Step 3. SPDE model

```r
# Recommended: PC priors on interpretable scales (Fuglstad et al. 2019; KIM overall_inla)
spde <- inla.spde2.pcmatern(mesh,
                            prior.range = c(50, 0.5),   # P(range < 50 km) = 0.5
                            prior.sigma = c(1, 0.01))   # P(sigma > 1) = 0.01

# As in Moraga / Blangiardo / Gambia tutorial (log-normal priors on internal theta)
spde_old <- inla.spde2.matern(mesh, alpha = 2, constr = TRUE)
```

`alpha = 2` gives Matérn smoothness nu = 1 in 2-D. Choose `prior.sigma` on
the linear-predictor scale (logit for binomial, log for Poisson, data units for
Gaussian).

## Step 4. Index, projector, stack

```r
s_idx <- inla.spde.make.index("s", n.spde = spde$n.spde)
A     <- inla.spde.make.A(mesh, loc = coo)           # or fmesher::fm_basis(mesh, loc = coo)

stk_e <- inla.stack(tag = "est",
  data    = list(y = d$y, ntrials = d$n),            # drop ntrials for gaussian/poisson
  A       = list(1, A),
  effects = list(data.frame(b0 = 1, elev = d$elev), s = s_idx))

coop  <- pred_grid_km                                # matrix of prediction coordinates
Ap    <- inla.spde.make.A(mesh, loc = coop)
stk_p <- inla.stack(tag = "pred",
  data    = list(y = NA, ntrials = NA),
  A       = list(1, Ap),
  effects = list(data.frame(b0 = 1, elev = grid_elev), s = s_idx))

stk <- inla.stack(stk_e, stk_p)
```

- `A` and `effects` are paired by position: `1` (identity) goes with the data
  frame of covariates, `A` with the spatial index. Blangiardo et al. order them
  `A = list(A, 1)` with `effects = list(c(s_idx, list(Intercept = 1)), list(elev = ...))`;
  both orderings are valid as long as the pairing is consistent.
- Every covariate must be available at every prediction location. If not,
  hold it at a reference value and say so (KIM's Gambia tutorial does this for
  `green` and `phc`), or omit it from the prediction stack and add `beta * x` back
  afterwards (Blangiardo et al. Swiss example).
- `y ~ 0 + b0 + ...` removes the automatic intercept and puts it back as `b0`;
  the model still has an intercept.

## Step 5. Fit

```r
form <- y ~ 0 + b0 + elev + f(s, model = spde)

ctrl_p <- list(compute = TRUE, link = 1, A = inla.stack.A(stk))
ctrl_c <- list(dic = TRUE, waic = TRUE, cpo = TRUE, config = TRUE,
               return.marginals.predictor = TRUE)

# Gaussian (e.g. sqrt rainfall, log PM10)
res <- inla(form, family = "gaussian", data = inla.stack.data(stk, spde = spde),
            control.predictor = ctrl_p, control.compute = ctrl_c)

# Binomial (positives out of tested at each site; Moraga & KIM Gambia)
res <- inla(form, family = "binomial", Ntrials = ntrials,
            data = inla.stack.data(stk, spde = spde),
            control.family = list(link = "logit"),
            control.predictor = ctrl_p, control.compute = ctrl_c)

# Poisson (counts at sites with exposure/expected e)
stk_e <- inla.stack(tag = "est", data = list(y = d$y, e = d$e), A = list(1, A),
                    effects = list(data.frame(b0 = 1, elev = d$elev), s = s_idx))
res <- inla(form, family = "poisson", E = e, data = inla.stack.data(stk, spde = spde),
            control.predictor = ctrl_p, control.compute = ctrl_c)
```

For an individual 0/1 outcome, keep one row per person (`Ntrials = 1`) and let
`A` map each person to their household/village coordinates. This avoids the
information loss of aggregating to sites (KIM's Gambia tutorial notes this).

Large prediction grids (Blangiardo et al. Sec. 4.2, KIM Piemonte): fit once on
the estimation stack, then reuse the mode:

```r
res0 <- inla(form, family = "gaussian", data = inla.stack.data(stk_e, spde = spde),
             control.predictor = list(A = inla.stack.A(stk_e), compute = FALSE))
res  <- inla(form, family = "gaussian", data = inla.stack.data(stk, spde = spde),
             control.predictor = list(A = inla.stack.A(stk), compute = TRUE, link = 1),
             control.compute = ctrl_c,
             control.mode = list(theta = res0$mode$theta, restart = FALSE))
```

## Step 6. Spatial hyperparameters

```r
# pcmatern: reported directly
res$summary.hyperpar[c("Range for s", "Stdev for s"), ]

# matern: transform the internal theta (Blangiardo et al.; Gambia tutorial)
sr <- inla.spde2.result(res, "s", spde, do.transform = TRUE)
inla.emarginal(function(x) x, sr$marginals.range.nominal[[1]])     # practical range
inla.emarginal(function(x) x, sr$marginals.variance.nominal[[1]])  # marginal variance
inla.zmarginal(sr$marginals.range.nominal[[1]])
```

Practical range = distance at which correlation drops to about 0.1
(`sqrt(8 nu) / kappa`).

Gaussian likelihood only: `Precision for the Gaussian observations` is the
nugget (measurement-error) precision; compare `1/precision` with `Stdev^2`
to describe how much variation is spatial vs pure noise.

## Step 7. Prediction maps

```r
ip <- inla.stack.index(stk, tag = "pred")$data
pred <- data.frame(coop,
  mean = res$summary.fitted.values[ip, "mean"],
  lo   = res$summary.fitted.values[ip, "0.025quant"],
  hi   = res$summary.fitted.values[ip, "0.975quant"])
pred$exc <- sapply(res$marginals.fitted.values[ip], \(m) 1 - inla.pmarginal(0.2, m))  # P(prev > 0.2)

# Back to a raster (Moraga Ch. 9)
sv <- terra::vect(as.matrix(pred[, 1:2]), atts = pred[, -(1:2)], crs = "EPSG:32628")
r_mean <- terra::rasterize(sv, template_raster_km, field = "mean", fun = mean)
```

If the prediction stack used mesh nodes instead of grid points
(`A = inla.spde.make.A(mesh)`), project node values to a lattice:

```r
proj <- fm_evaluator(mesh, xlim = range(gx), ylim = range(gy), dims = c(nx, ny))  # was inla.mesh.projector
lp   <- fm_evaluate(proj, res$summary.linear.predictor[ip, "mean"])                # was inla.mesh.project
```

Map the posterior mean, the CrI width or SD, and an exceedance probability.
Mask areas far from any data (e.g. mountains with no stations in KIM's
Piemonte example) rather than reporting extrapolations.

## Spatio-temporal extension

```r
s_idx <- inla.spde.make.index("s", n.spde = spde$n.spde, n.group = n_t)
A     <- inla.spde.make.A(mesh, loc = coo, group = d$time, n.group = n_t)
form  <- y ~ 0 + b0 + x + f(s, model = spde, group = s.group,
                            control.group = list(model = "ar1"))
```

The field is replicated per time point with AR(1) correlation across time
(Blangiardo et al. Sec. 4.2, Moraga Ch. 10). `Rho for s` is the temporal
autocorrelation.
