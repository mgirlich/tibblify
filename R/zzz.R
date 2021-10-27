# nocov start

.onLoad <- function(libname, pkgname) {
  # Load vctrs namespace for access to C callables
  requireNamespace("vctrs", quietly = TRUE)

  # Initialize slider C globals
  .Call(tibblify_initialize, ns_env("tibblify"))
}

# nocov end
