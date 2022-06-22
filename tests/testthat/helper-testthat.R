test_that <- function(...) {
  gctorture2(101)
  on.exit(gctorture2(0))
  testthat::test_that(...)
}
