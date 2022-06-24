new_difftime <- function(units) {
  structure(numeric(), class = "difftime", units = units)
}

new_rational <- function(n = integer(), d = integer()) {
  n <- vec_cast(n, integer())
  d <- vec_cast(d, integer())

  size <- vec_size_common(n, d)
  n <- vec_recycle(n, size)
  d <- vec_recycle(d, size)

  new_rcrd(list(n = n, d = d), class = "vctrs_rational")
}

read_sample_json <- function(x) {
  path <- system.file("jsonexamples", x, package = "tibblify")
  jsonlite::fromJSON(path, simplifyDataFrame = FALSE)
}
