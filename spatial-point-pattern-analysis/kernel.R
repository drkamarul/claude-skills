# kernel.R -- helpers for spatial-point-pattern-analysis skill

fix_proj_env <- function(env_path = NULL) {
  # Binds PROJ_DATA (and GDAL_DATA if present) for conda-packaged sf/spatstat
  # environments where the activation hook doesn't set it. Call this first
  # thing in any R cell that touches sf/CRS. Idempotent -- safe to call repeatedly.
  if (is.null(env_path)) {
    rp <- Sys.getenv("R_HOME")
    if (nzchar(rp)) env_path <- normalizePath(file.path(rp, ".."), mustWork = FALSE)
  }
  if (is.null(env_path) || !nzchar(env_path)) {
    message("fix_proj_env: could not infer env_path; pass it explicitly, e.g. ",
            "fix_proj_env('~/.claude-science/conda/envs/rspatial')")
    return(invisible(FALSE))
  }
  proj_dir <- file.path(env_path, "share", "proj")
  gdal_dir <- file.path(env_path, "share", "gdal")
  if (dir.exists(proj_dir)) Sys.setenv(PROJ_DATA = proj_dir)
  if (dir.exists(gdal_dir)) Sys.setenv(GDAL_DATA = gdal_dir)
  ok <- dir.exists(proj_dir)
  if (!ok) message("fix_proj_env: ", proj_dir, " does not exist -- check env_path")
  invisible(ok)
}

build_ppp <- function(cases_sf, window_sf, verbose = TRUE) {
  # Constructs a spatstat ppp from case points + a boundary polygon (both sf,
  # same CRS assumed already). Reports and drops points outside the window,
  # flagging whether drops look like coastline/digitization slop (<500m out)
  # or something that needs investigating (large or systematic spillover).
  stopifnot(requireNamespace("sf", quietly = TRUE),
            requireNamespace("spatstat.geom", quietly = TRUE))
  win_u <- sf::st_union(sf::st_make_valid(window_sf))
  inside <- lengths(sf::st_intersects(cases_sf, win_u)) > 0
  n_out <- sum(!inside)
  if (n_out > 0) {
    d_out <- as.numeric(sf::st_distance(cases_sf[!inside, ], win_u))
    near <- sum(d_out < 500)
    if (verbose) {
      message(sprintf(
        "build_ppp: dropping %d/%d points outside window (%d within 500m -- likely digitization slop)",
        n_out, nrow(cases_sf), near))
      if (near < n_out) {
        message("build_ppp: WARNING -- some dropped points are >500m outside the window; ",
                "verify the boundary/CRS before treating this as slop.")
      }
    }
  }
  cases_in <- cases_sf[inside, ]
  win <- spatstat.geom::as.owin(sf::as_Spatial(sf::st_sf(geometry = win_u)))
  xy <- sf::st_coordinates(cases_in)
  P <- spatstat.geom::ppp(xy[, 1], xy[, 2], window = win)
  if (verbose) {
    message(sprintf("build_ppp: ppp built, n=%d, area=%.0f km2, intensity=%.4f /km2",
                     P$n, spatstat.geom::area(win) / 1e6, P$n / (spatstat.geom::area(win) / 1e6)))
  }
  list(ppp = P, window = win, dropped = sum(!inside), n_out_far = if (n_out > 0) n_out - near else 0)
}

audit_duplicates <- function(P) {
  # Reports duplicate-coordinate burden and returns as-observed, de-duplicated,
  # and a 50m-jittered version -- use the latter two for sensitivity checks
  # on any small-scale clustering finding, and to sanity-check bandwidth choice.
  stopifnot(requireNamespace("spatstat.geom", quietly = TRUE))
  dup <- duplicated(cbind(P$x, P$y)) | duplicated(cbind(P$x, P$y), fromLast = TRUE)
  n_dup <- sum(duplicated(cbind(P$x, P$y)))
  nnd <- spatstat.geom::nndist(P)
  pct_zero <- mean(nnd == 0) * 100
  message(sprintf("audit_duplicates: %d duplicated points | %.1f%% of points at nndist=0",
                   n_dup, pct_zero))
  P_unique <- spatstat.geom::unique.ppp(P)
  P_jitter <- spatstat.geom::rjitter(P, radius = 50)
  list(P = P, P_unique = P_unique, P_jitter = P_jitter,
       n_duplicated = n_dup, pct_nndist_zero = pct_zero)
}

population_offset <- function(pop_polygons, pop_field, window, eps = 250, n_points = NULL) {
  # Rasterizes a population (or other covariate) field from polygons into a
  # spatstat im scaled so its integral equals n_points (defaults to the
  # polygon-field sum). Use as the `lambda` argument to envelope(..., 
  # simulate = expression(rpoispp(lam))) for an inhomogeneous CSR baseline.
  # ALWAYS sanity-check orientation afterward: sample the returned im at one
  # known urban and one known rural coordinate and confirm high/low match
  # expectation -- raster vs. image row-order conventions disagree often
  # enough to silently flip results.
  stopifnot(requireNamespace("terra", quietly = TRUE),
            requireNamespace("spatstat.geom", quietly = TRUE))
  r <- terra::rast(terra::vect(pop_polygons), resolution = eps)
  r <- terra::rasterize(terra::vect(pop_polygons), r, field = pop_field)
  im <- spatstat.geom::as.im(as.data.frame(r, xy = TRUE), eps = eps)
  total <- sum(spatstat.geom::as.matrix(im), na.rm = TRUE)
  if (is.null(n_points)) n_points <- total
  scale_factor <- n_points / total
  im_scaled <- spatstat.geom::eval.im(im * scale_factor)
  im_scaled[spatstat.geom::as.mask(window)]
}
