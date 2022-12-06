test_that("can parse open api spec", {
  skip_on_cran()
  expect_no_error(
    # supprss `incomplete final line` warning
    suppressWarnings(
      parse_openapi_spec("https://dtrnk0o2zy01c.cloudfront.net/openapi/en-us/dest/SponsoredProducts_prod_3p.json")
    )
  )
})
