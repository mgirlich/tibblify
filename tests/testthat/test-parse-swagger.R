test_that("can parse swagger spec", {
  expect_no_error(
    parse_swagger_spec("https://dtrnk0o2zy01c.cloudfront.net/openapi/en-us/dest/SponsoredProducts_prod_3p.json")
  )
})
