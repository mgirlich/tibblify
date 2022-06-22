#' @import rlang
#' @import vctrs
#' @keywords internal
#' @aliases tibblify-package
"_PACKAGE"

# The following block is used by usethis to automatically manage
# roxygen namespace tags. Modify with care!
## usethis namespace: start
#' @useDynLib tibblify, .registration = TRUE
## usethis namespace: end
NULL

#' @importFrom rlang zap
#' @export zap
#' @keywords internal
rlang::zap

#' @importFrom tibble tibble
#' @export tibble
#' @keywords internal
tibble::tibble
