test_that("spec argument is checked", {
  expect_snapshot({
    (expect_error(tibblify(list(), "x")))
    (expect_error(tibblify(list(), tib_int("x"))))
  })
})


# rowmajor ----------------------------------------------------------------

test_that("names are checked", {
  spec <- tspec_object(x = tib_int("x", required = FALSE))

  expect_snapshot({
    # no names
    (expect_error(tibblify(list(1, 2), spec)))

    # partial names
    (expect_error(tibblify(list(x = 1, 2), spec)))
    (expect_error(tibblify(list(1, x = 2), spec)))
    (expect_error(tibblify(list(z = 1, y = 2, 3, a = 4), spec)))

    # `NA` name
    (expect_error(tibblify(set_names(list(1, 2), c("x", NA)), spec)))

    # duplicate name
    (expect_error(tibblify(list(x = 1, x = 2), spec)))
  })
})

test_that("scalar column works", {
  dtt <- vctrs::new_datetime(1)

  # can parse
  expect_equal(tib(list(x = TRUE), tib_lgl("x")), tibble(x = TRUE))
  expect_equal(tib(list(x = dtt), tib_scalar("x", dtt)), tibble(x = dtt))

  # errors if required but absent
  expect_snapshot((expect_error(tib(list(), tib_lgl("x")))))
  expect_snapshot((expect_error(tib(list(), tib_scalar("x", dtt)))))

  # errors if bad size
  expect_snapshot((expect_error(tib(list(x = c(TRUE, TRUE)), tib_lgl("x")))))
  expect_snapshot((expect_error(tib(list(x = c(dtt, dtt)), tib_scalar("x", dtt)))))

  # errors if bad type
  expect_snapshot((expect_error(tib(list(x = "a"), tib_lgl("x")))))
  expect_snapshot((expect_error(tib(list(x = 1), tib_scalar("x", dtt)))))

  # fallback default works
  expect_equal(tib(list(), tib_lgl("x", required = FALSE)), tibble(x = NA))
  expect_equal(tib(list(), tib_scalar("x", dtt, required = FALSE)), tibble(x = vctrs::new_datetime(NA_real_)))

  # use NA if NULL
  expect_equal(tib(list(x = NULL), tib_lgl("x", required = FALSE, fill = FALSE)), tibble(x = NA))
  expect_equal(
    tib(list(x = NULL), tib_scalar("x", vec_ptype(dtt), required = FALSE, fill = dtt)),
    tibble(x = vec_init(dtt))
  )

  # errors if empty element
  expect_snapshot({
    (expect_error(tib(list(x = integer()), tib_int("x", required = FALSE))))
  })

  # specified default works
  expect_equal(tib(list(), tib_lgl("x", required = FALSE, fill = FALSE)), tibble(x = FALSE))
  expect_equal(
    tib(list(), tib_scalar("x", vec_ptype(dtt), required = FALSE, fill = dtt)),
    tibble(x = dtt)
  )

  # transform works
  expect_equal(
    tib(list(x = TRUE), tib_lgl("x", transform = ~ !.x)),
    tibble(x = FALSE)
  )
  expect_equal(
    tib(list(x = dtt), tib_scalar("x", dtt, transform = ~ .x + 1)),
    tibble(x = vctrs::new_datetime(2))
  )
})

test_that("record objects work", {
  x_rcrd <- as.POSIXlt(Sys.time(), tz = "UTC")

  expect_equal(
    tibblify(
      list(
        list(x = x_rcrd),
        list(x = x_rcrd + 1)
      ),
      tspec_df(
        x = tib_scalar("x", ptype = x_rcrd)
      )
    ),
    tibble(x = c(x_rcrd, x_rcrd + 1))
  )

  now <- Sys.time()
  td1 <- now - (now - 100)
  td2 <- now - (now - 200)

  expect_equal(
    tibblify(
      list(
        list(timediff = td1),
        list(timediff = td2)
      ),
      tspec_df(
        timediff = tib_scalar("timediff", ptype = td1)
      )
    ),
    tibble(timediff = c(td1, td2))
  )
})

test_that("scalar columns respect ptype_inner", {
  f <- function(x) {
    stopifnot(is.character(x))
    as.Date(x)
  }
  spec <- tspec_df(
    tib_scalar(
      "x", Sys.Date(),
      required = FALSE,
      ptype_inner = character(),
      fill = "2000-01-01",
      transform = f,
    ),
  )

  expect_equal(
    tibblify(
      list(list(x = "2022-06-01"), list(x = "2022-06-02"), list()),
      spec
    ),
    tibble(x = as.Date(c("2022-06-01", "2022-06-02", "2000-01-01")))
  )

  spec2 <- tspec_df(
    tib_scalar(
      "x", Sys.Date(),
      required = FALSE,
      ptype_inner = Sys.time(),
      fill = as.POSIXct("2000-01-01"),
      transform = as.Date
    ),
  )
  x <- as.POSIXct("2022-06-02") + c(-60, 60)

  expect_equal(
    tibblify(
      list(list(x = x[[1]]), list(x = x[[2]]), list()),
      spec2
    ),
    tibble(x = as.Date(c("2022-06-01", "2022-06-02", "2000-01-01")))
  )
})

test_that("vector column works", {
  dtt <- vctrs::new_datetime(1)

  # can parse
  expect_equal(tib(list(x = c(TRUE, FALSE)), tib_lgl_vec("x")), tibble(x = list_of(c(TRUE, FALSE))))
  expect_equal(tib(list(x = c(dtt, dtt + 1)), tib_vector("x", dtt)), tibble(x = list_of(c(dtt, dtt + 1))))

  # errors if required but absent
  expect_snapshot((expect_error(tib(list(), tib_lgl_vec("x")))))
  expect_snapshot((expect_error(tib(list(), tib_vector("x", dtt)))))

  # errors if bad type
  expect_snapshot((expect_error(tib(list(x = "a"), tib_lgl_vec("x")))))

  # fallback default works
  expect_equal(tib(list(), tib_lgl_vec("x", required = FALSE)), tibble(x = list_of(NULL, .ptype = logical())))
  expect_equal(tib(list(), tib_vector("x", dtt, required = FALSE)), tibble(x = list_of(NULL, .ptype = vctrs::new_datetime())))

  # specified default works
  expect_equal(tib(list(), tib_lgl_vec("x", required = FALSE, fill = c(TRUE, FALSE))), tibble(x = list_of(c(TRUE, FALSE))))
  expect_equal(tib(list(), tib_vector("x", dtt, required = FALSE, fill = c(dtt, dtt + 1))), tibble(x = list_of(c(dtt, dtt + 1))))

  # uses NULL for NULL
  expect_equal(tib(list(x = NULL), tib_int_vec("x", fill = 1:2)), tibble(x = list_of(NULL, .ptype = integer())))

  # transform works
  expect_equal(
    tib(list(x = c(TRUE, FALSE)), tib_lgl_vec("x", transform = ~ !.x)),
    tibble(x = list_of(c(FALSE, TRUE)))
  )
  expect_equal(
    tib(list(x = c(dtt - 1, dtt)), tib_vector("x", dtt, transform = ~ .x + 1)),
    tibble(x = list_of(c(dtt, dtt + 1)))
  )
})

test_that("vector columns respect ptype_inner", {
  spec <- tspec_df(
    tib_vector(
      "x", Sys.Date(),
      required = FALSE,
      ptype_inner = character(),
      fill = as.Date("2000-01-01"),
      transform = as.Date
    ),
  )

  expect_equal(
    tibblify(
      list(list(x = "2022-06-01"), list(x = c("2022-06-02", "2022-06-03")), list()),
      spec
    ),
    tibble(
      x = list_of(
        as.Date("2022-06-01"),
        as.Date(c("2022-06-02", "2022-06-03")),
        as.Date("2000-01-01")
      )
    )
  )
})

test_that("explicit NULL work", {
  x <- list(
    list(x = NULL),
    list(x = 3L),
    list()
  )

  expect_equal(
    tibblify(x, tspec_df(tib_int("x", required = FALSE))),
    tibble(x = c(NA, 3L, NA))
  )
})

test_that("vector column respects vector_allows_empty_list", {
  x <- list(
    list(x = 1),
    list(x = list()),
    list(x = 1:3)
  )

  expect_snapshot({
    (expect_error(tibblify(x, tspec_df(tib_int_vec("x")))))
  })

  expect_equal(
    tibblify(x, tspec_df(tib_int_vec("x"), vector_allows_empty_list = TRUE)),
    tibble(x = list_of(1, integer(), 1:3))
  )
})

test_that("vector column creates tibble with values_to", {
  spec <- tib_int_vec("x", values_to = "val")
  expect_equal(
    tib(list(x = 1:2), spec),
    tibble(x = list_of(tibble(val = 1:2)))
  )

  # can handle NULL
  expect_equal(
    tib(list(x = NULL), spec),
    tibble(x = list_of(NULL, .ptype = tibble(val = 1:2)))
  )

  # can handle empty vector
  expect_equal(
    tib(list(x = integer()), spec),
    tibble(x = list_of(tibble(val = integer())))
  )

  spec2 <- tib_int_vec("x", required = FALSE, fill = c(1:2), values_to = "val")
  # can use default
  expect_equal(
    tib(list(), spec2),
    tibble(x = list_of(tibble(val = 1:2)))
  )
})

test_that("vector column can parse scalar list", {
  spec <- tib_int_vec("x", input_form = "scalar_list")
  expect_equal(
    tib(list(x = list(1, NULL, 3)), spec),
    tibble(x = list_of(c(1L, NA, 3L)))
  )

  # handles `NULL`
  expect_equal(
    tibblify(
      list(list(x = list(1, 2)), list(x = NULL)),
      tspec_df(x = spec)
    ),
    tibble(x = list_of(1:2, NULL))
  )

  # handles empty list
  expect_equal(
    tibblify(
      list(list(x = list(1, 2)), list(x = list())),
      tspec_df(x = spec)
    ),
    tibble(x = list_of(1:2, integer()))
  )

  tspec_object <- spec
  tspec_object$input_form <- "object"
  expect_snapshot({
    (expect_error(tib(list(x = 1), spec)))
    (expect_error(tib(list(x = 1), tspec_object)))
  })

  expect_snapshot({
    (expect_error(tib(list(x = list(1, 1:2)), spec)))
    (expect_error(tib(list(x = list(integer())), spec)))
  })

  expect_snapshot({
    (expect_error(tib(list(x = list(1, "a")), spec)))
  })
})

test_that("vector column can parse object", {
  spec <- tib_int_vec("x", input_form = "object")
  expect_equal(
    tib(list(x = list(a = 1, b = NULL, c = 3)), spec),
    tibble(x = list_of(c(1L, NA, 3L)))
  )

  expect_snapshot(
    (expect_error(tib(list(x = list(1, 2)), spec)))
  )

  # partial or duplicate names are not checked - https://github.com/mgirlich/tibblify/issues/103
  expect_equal(
    tib(list(x = list(a = 1, 2)), spec),
    tibble(x = list_of(c(1L, 2L)))
  )

  expect_equal(
    tib(list(x = list(a = 1, a = 2)), spec),
    tibble(x = list_of(c(1L, 2L)))
  )
})

test_that("vector column creates tibble with names_to", {
  spec <- tib_int_vec("x", input_form = "object", values_to = "val", names_to = "name")
  expect_equal(
    tib(list(x = list(a = 1, b = NULL)), spec),
    tibble(x = list_of(tibble(name = c("a", "b"), val = c(1L, NA))))
  )

  # names of default value are used
  spec2 <- tib_int_vec(
    "x",
    fill = c(x = 1L, y = 2L),
    required = FALSE,
    input_form = "object",
    values_to = "val",
    names_to = "name"
  )
  expect_equal(
    tib(list(a = 1), spec2),
    tibble(x = list_of(tibble(name = c("x", "y"), val = c(1L, 2L))))
  )

  spec3 <- tib_int_vec("x", values_to = "val", names_to = "name")
  expect_equal(
    tib(list(x = c(a = 1, b = NA)), spec3),
    tibble(x = list_of(tibble(name = c("a", "b"), val = c(1L, NA))))
  )
})

test_that("list column works", {
  # can parse
  expect_equal(
    tibblify(
      list(list(x = TRUE), list(x = 1)),
      tspec_df(x = tib_variant("x"))
    ),
    tibble(x = list(TRUE, 1))
  )

  expect_equal(
    tibblify(
      list(x = TRUE),
      tspec_row(x = tib_variant("x"))
    ),
    tibble(x = list(TRUE))
  )

  # errors if required but absent
  expect_snapshot(
    (expect_error(tibblify(
      list(list(x = TRUE), list(zzz = 1)),
      tspec_df(x = tib_variant("x"))
    )))
  )

  # fallback default works
  expect_equal(
    tibblify(
      list(list(), list(x = 1)),
      tspec_df(x = tib_variant("x", required = FALSE))
    ),
    tibble(x = list(NULL, 1))
  )

  # specified default works
  expect_equal(
    tibblify(
      list(list()),
      tspec_df(x = tib_variant("x", required = FALSE, fill = 1))
    ),
    tibble(x = list(1))
  )

  # can handle NULL
  expect_equal(
    tibblify(
      list(list(x = NULL)),
      tspec_df(x = tib_variant("x", fill = 1))
    ),
    tibble(x = list(NULL))
  )

  # transform works
  expect_equal(
    tibblify(
      list(list(x = c(TRUE, FALSE)), list(x = 1)),
      tspec_df(x = tib_variant("x", required = FALSE, transform = ~ length(.x)))
    ),
    tibble(x = list(2, 1))
  )
})

test_that("df column works", {
  # can parse
  expect_equal(
    tibblify(
      list(
        list(x = list(a = TRUE)),
        list(x = list(a = FALSE))
      ),
      tspec_df(x = tib_row("x", a = tib_lgl("a")))
    ),
    tibble(x = tibble(a = c(TRUE, FALSE)))
  )

  # errors if required but absent
  expect_snapshot(
    (expect_error(tibblify(
      list(
        list(x = list(a = TRUE)),
        list()
      ),
      tspec_df(x = tib_row("x", a = tib_lgl("a")))
    )))
  )

  # fallback default works
  expect_equal(
    tibblify(
      list(
        list(x = list(a = TRUE)),
        list(x = list()),
        list()
      ),
      tspec_df(x = tib_row("x", .required = FALSE, a = tib_lgl("a", required = FALSE)))
    ),
    tibble(x = tibble(a = c(TRUE, NA, NA)))
  )
})

test_that("list of df column works", {
  # can parse
  expect_equal(
    tibblify(
      list(
        list(x = list(
          list(a = TRUE),
          list(a = FALSE)
        ))
      ),
      tspec_df(x = tib_df("x", a = tib_lgl("a")))
    ),
    tibble(x = list_of(tibble(a = c(TRUE, FALSE))))
  )

  # errors if required but absent
  expect_snapshot(
    (expect_error(tibblify(
      list(
        list(x = list(
          list(a = TRUE),
          list(a = FALSE)
        )),
        list()
      ),
      tspec_df(x = tib_df("x", a = tib_lgl("a")))
    )))
  )

  # fallback default works
  expect_equal(
    tibblify(
      list(
        list(x = list(
          list(a = TRUE),
          list(a = FALSE)
        )),
        list(x = list()),
        list()
      ),
      tspec_df(x = tib_df("x", .required = FALSE, a = tib_lgl("a", required = FALSE)))
    ),
    tibble(x = list_of(tibble(a = c(TRUE, FALSE)), tibble(a = logical()), NULL))
  )
})

test_that("names_to works", {
  # can parse
  expect_equal(
    tibblify(
      list(
        a = list(x = TRUE),
        b = list(x = FALSE)
      ),
      tspec_df(x = tib_lgl("x"), .names_to = "nms")
    ),
    tibble(nms = c("a", "b"), x = c(TRUE, FALSE))
  )

  # works with partial names
  expect_equal(
    tibblify(
      list(
        a = list(x = TRUE),
        list(x = FALSE)
      ),
      tspec_df(x = tib_lgl("x"), .names_to = "nms")
    ),
    tibble(nms = c("a", ""), x = c(TRUE, FALSE))
  )

  # works for missing names
  expect_equal(
    tibblify(
      list(
        list(x = TRUE),
        list(x = FALSE)
      ),
      tspec_df(x = tib_lgl("x"), .names_to = "nms")
    ),
    tibble(nms = c("", ""), x = c(TRUE, FALSE))
  )
})

test_that("tibble input works", {
  df <- tibble(x = 1:2, y = c("a", "b"))

  expect_equal(
    tibblify(
      df,
      tspec_df(
        x = tib_int("x"),
        y = tib_chr("y")
      )
    ),
    df
  )

  df2 <- tibble(x = 1:2, y = c("a", "b"), df = tibble(z = 3:4))

  expect_equal(
    tibblify(
      df2,
      tspec_df(
        x = tib_int("x"),
        y = tib_chr("y"),
        df = tib_row(
          "df",
          z = tib_int("z"),
        )
      )
    ),
    df2
  )
})

test_that("tibble with list columns work - #43", {
  x <- tibble::tibble(x = list(1:3, NULL, 1:2))
  expect_equal(
    tibblify(x, tspec_df(x = tib_int_vec("x"))),
    tibble(x = list_of(1:3, NULL, 1:2))
  )

  y <- tibble::tibble(x = list(tibble(a = 1:2), NULL, tibble(a = 1)))
  spec <- tspec_df(x = tib_df("x", tib_dbl("a"), .required = FALSE))
  expect_equal(
    tibblify(y, tspec_df(x = tib_df("x", tib_dbl("a")))),
    tibble(x = list_of(tibble(a = 1:2), NULL, tibble(a = 1)))
  )
})

test_that("nested keys work", {
  expect_equal(
    tibblify(
      list(list(x = list(y = list(z = 1)))),
      tspec_df(xyz = tib_int(c("x", "y", "z")))
    ),
    tibble(xyz = 1)
  )
})

test_that("empty spec works", {
  expect_equal(
    tibblify(
      list(list(), list()),
      tspec_df()
    ),
    tibble(.rows = 2)
  )

  expect_equal(
    tibblify(
      list(),
      tspec_df()
    ),
    tibble()
  )

  expect_equal(
    tibblify(
      list(list(x = list()), list(x = list())),
      tspec_df(x = tib_row("x"))
    ),
    tibble(x = tibble(.rows = 2), .rows = 2)
  )

  expect_equal(
    tibblify(
      list(),
      tspec_df(x = tib_row("x", .required = FALSE))
    ),
    tibble(x = tibble())
  )
})

test_that("does not confuse key order due to case - #96", {
  skip_on_cran()
  withr::local_locale(c(LC_COLLATE = "en_US"))
  spec <- tspec_object(
    B = tib_int("B", required = FALSE),
    a = tib_int("a", required = FALSE),
  )
  expect_equal(
    tibblify::tibblify(list(B = 1), spec),
    list(B = 1, a = NA_integer_)
  )
})

test_that("discog works", {
  row1 <- tibble(
    instance_id = 354823933L,
    date_added = "2019-02-16T17:48:59-08:00",
    basic_information = tibble(
      labels = list_of(
        tibble(
          name             = "Tobi Records (2)",
          entity_type      = "1",
          catno            = "TOB-013",
          resource_url     = "https://api.discogs.com/labels/633407",
          id               = 633407L,
          entity_type_name = "Label"
        )
      ),
      year = 2015L,
      master_url = NA_character_,
      artists = list_of(
        tibble(
          join         = "",
          name         = "Mollot",
          anv          = "",
          tracks       = "",
          role         = "",
          resource_url = "https://api.discogs.com/artists/4619796",
          id           = 4619796L
        )
      ),
      id = 7496378L,
      thumb = "https://img.discogs.com/vEVegHrMNTsP6xG_K6OuFXz4h_U=/fit-in/150x150/filters:strip_icc():format(jpeg):mode_rgb():quality(40)/discogs-images/R-7496378-1442692247-1195.jpeg.jpg",
      title = "Demo",
      formats = list_of(
        tibble(
          # descriptions = list_of("Numbered"),
          text         = "Black",
          name         = "Cassette",
          qty          = "1"
        )
      ),
      cover_image = "https://img.discogs.com/EmbMh7vsElksjRgoXLFSuY1sjRQ=/fit-in/500x499/filters:strip_icc():format(jpeg):mode_rgb():quality(90)/discogs-images/R-7496378-1442692247-1195.jpeg.jpg",
      resource_url = "https://api.discogs.com/releases/7496378",
      master_id = 0L
    ),
    id = 7496378L,
    rating = 0L
  )

  # TODO think about issue with "description"
  spec_collection <- tspec_df(
    tib_int("instance_id"),
    tib_chr("date_added"),
    tib_row(
      "basic_information",
      tib_df(
        "labels",
        tib_chr("name"),
        tib_chr("entity_type"),
        tib_chr("catno"),
        tib_chr("resource_url"),
        tib_int("id"),
        tib_chr("entity_type_name"),
      ),
      tib_int("year"),
      tib_chr("master_url"),
      tib_df(
        "artists",
        tib_chr("join"),
        tib_chr("name"),
        tib_chr("anv"),
        tib_chr("tracks"),
        tib_chr("role"),
        tib_chr("resource_url"),
        tib_int("id"),
      ),
      tib_int("id"),
      tib_chr("thumb"),
      tib_chr("title"),
      tib_df(
        "formats",
        # tib_chr_vec(
        #   "descriptions",
        #   required = FALSE,
        #   input_form = "scalar_list",
        # ),
        tib_chr("text", required = FALSE),
        tib_chr("name"),
        tib_chr("qty"),
      ),
      tib_chr("cover_image"),
      tib_chr("resource_url"),
      tib_int("master_id"),
    ),
    tib_int("id"),
    tib_int("rating"),
  )

  expect_equal(tibblify(discog[1], spec_collection), row1)
  expect_equal(tibblify(row1, spec_collection), row1)

  specs_object <- tspec_row(!!!spec_collection$fields)
  expect_equal(tibblify(discog[[1]], specs_object), row1)
  expect_equal(tibblify(row1, specs_object), row1)
})

test_that("tspec_object() works", {
  x <- list(a = 1, b = 1:3)
  spec <- tspec_row(a = tib_int("a"), b = tib_int_vec("b"))

  expect_equal(
    tibblify(x, spec),
    tibble(a = 1L, b = list_of(1:3))
  )
  expect_equal(
    tibblify(x, tspec_object(spec)),
    list(a = 1L, b = 1:3)
  )

  x2 <- list(
    a = list(
      x = 1,
      y = list(a = 1),
      z = list(
        list(b = 1),
        list(b = 2)
      )
    )
  )

  spec2 <- tspec_row(
    a = tib_row(
      "a",
      x = tib_int("x"),
      y = tib_row("y", a = tib_int("a")),
      z = tib_df("z", b = tib_int("b"))
    )
  )

  expect_equal(
    tibblify(x2, spec2),
    tibble(
      a = tibble(
        x = 1L,
        y = tibble(a = 1L),
        z = list_of(tibble(b = 1:2))
      )
    )
  )
  expect_equal(
    tibblify(x2, tspec_object(spec2)),
    list(
      a = list(
        x = 1L,
        y = list(a = 1L),
        z = tibble(b = 1:2)
      )
    )
  )
})

test_that("spec_replace_unspecified works", {
  spec <- tspec_df(
    tib_int("1int"),
    tib_unspecified("1un"),
    tib_df(
      "1df",
      tib_int("2int"),
      tib_unspecified("2un"),
      tib_row(
        "2row",
        `3un` = tib_unspecified("key"),
        `3un2` = tib_unspecified("key2"),
      )
    ),
    tib_row(
      "1row",
      tib_unspecified("2un2"),
      `2un3` = tib_unspecified("key")
    )
  )

  expect_equal(
    spec_replace_unspecified(spec, unspecified = "drop"),
    tspec_df(
      tib_int("1int"),
      tib_df(
        "1df",
        tib_int("2int"),
        tib_row("2row")
      ),
      tib_row("1row")
    ),
    ignore_attr = "names"
  )
  expect_equal(
    spec_replace_unspecified(spec, unspecified = "list"),
    tspec_df(
      tib_int("1int"),
      tib_variant("1un"),
      tib_df(
        "1df",
        tib_int("2int"),
        tib_variant("2un"),
        tib_row(
          "2row",
          `3un` = tib_variant("key"),
          `3un2` = tib_variant("key2"),
        )
      ),
      tib_row(
        "1row",
        tib_variant("2un2"),
        `2un3` = tib_variant("key")
      )
    )
  )
})

# colmajor ----------------------------------------------------------------

test_that("colmajor: names are checked", {
  spec <- tspec_df(.input_form = "colmajor", x = tib_int("x", required = FALSE))

  expect_snapshot({
    # no names
    (expect_error(tibblify(list(1, 2), spec)))

    # partial names
    (expect_error(tibblify(list(x = 1, 2), spec)))
    (expect_error(tibblify(list(1, x = 2), spec)))
    (expect_error(tibblify(list(z = 1, y = 2, 3, a = 4), spec)))

    # `NA` name
    (expect_error(tibblify(set_names(list(1, 2), c("x", NA)), spec)))

    # duplicate name
    (expect_error(tibblify(list(x = 1, x = 2), spec)))
  })
})

test_that("colmajor: scalar column works", {
  dtt <- vctrs::new_datetime(1)

  # can parse
  expect_equal(tib_cm(x = TRUE, tib_lgl("x")), tibble(x = TRUE))
  expect_equal(tib_cm(x = dtt, tib_scalar("x", dtt)), tibble(x = dtt))

  # errors if required but absent
  # expect_snapshot((expect_error(tib2(x = 1:3, tib_lgl("y")))))

  # errors if bad type
  expect_snapshot((expect_error(tib_cm(x = "a", tib_lgl("x")))))
  expect_snapshot((expect_error(tib_cm(x = 1, tib_scalar("x", dtt)))))

  # transform works
  expect_equal(
    tib_cm(x = TRUE, tib_lgl("x", transform = ~ !.x)),
    tibble(x = FALSE)
  )
  expect_equal(
    tib_cm(x = dtt, tib_scalar("x", dtt, transform = ~ .x + 1)),
    tibble(x = vctrs::new_datetime(2))
  )

  skip("Unclear if required and default makes sense for colmajor")
  # fallback default works
  expect_equal(
    tib2(x = 1:2, tib_int("x"), tib_lgl("y", required = FALSE)),
    tibble(x = 1:2, y = NA)
  )
  expect_equal(
    tib2(x = 1:2, tib_int("x"), tib_scalar("y", dtt, required = FALSE)),
    tibble(x = 1:2, y = vctrs::new_datetime(NA_real_))
  )

  # use NA if NULL
  expect_equal(tib(list(x = NULL), tib_lgl("x", required = FALSE, fill = FALSE)), tibble(x = NA))
  expect_equal(
    tib(list(x = NULL), tib_scalar("x", vec_ptype(dtt), required = FALSE, fill = dtt)),
    tibble(x = vec_init(dtt))
  )

  # specified default works
  expect_equal(tib(list(), tib_lgl("x", required = FALSE, fill = FALSE)), tibble(x = FALSE))
  expect_equal(
    tib(list(), tib_scalar("x", vec_ptype(dtt), required = FALSE, fill = dtt)),
    tibble(x = dtt)
  )
})

test_that("colmajor: record objects work", {
  x_rcrd <- as.POSIXlt(Sys.time(), tz = "UTC")

  expect_equal(
    tib_cm(tib_scalar("x", ptype = x_rcrd), x = c(x_rcrd, x_rcrd + 1)),
    tibble(x = c(x_rcrd, x_rcrd + 1))
  )

  now <- Sys.time()
  td <- now - (now - c(100, 200))
  expect_equal(
    tib_cm(tib_scalar("x", ptype = td[1]), x = td),
    tibble(x = td)
  )
})

test_that("colmajor: scalar columns respect ptype_inner", {
  f <- function(x) {
    stopifnot(is.character(x))
    as.Date(x)
  }

  dates <- c("2022-06-01", "2022-06-02")
  expect_equal(
    tib_cm(
      tib_scalar("x", Sys.Date(), ptype_inner = character(), transform = f),
      x = dates
    ),
    tibble(x = as.Date(dates))
  )

  date_times <- as.POSIXct("2022-06-02") + c(-60, 60)
  expect_equal(
    tib_cm(
      tib_scalar("x", Sys.Date(), ptype_inner = Sys.time(), transform = as.Date),
      x = date_times
    ),
    tibble(x = as.Date(date_times))
  )
})

test_that("colmajor: vector column works", {
  dtt <- vctrs::new_datetime(1)

  # can parse
  expect_equal(tib_cm(tib_lgl_vec("x"), x = list(c(TRUE, FALSE))), tibble(x = list_of(c(TRUE, FALSE))))
  expect_equal(tib_cm(tib_vector("x", dtt), x = list(c(dtt, dtt + 1))), tibble(x = list_of(c(dtt, dtt + 1))))

  # errors if required but absent
  # expect_snapshot((expect_error(tib_cm(tib_lgl_vec("x"), list()))))
  # expect_snapshot((expect_error(tib_cm(tib_vector("x", dtt), list()))))

  # errors if bad type
  expect_snapshot({
    # not a list
    (expect_error(tib_cm(tib_lgl_vec("x"), x = "a")))
    # list of bad types
    (expect_error(tib_cm(tib_lgl_vec("x"), x = list("a"))))
  })

  # transform works
  expect_equal(
    tib_cm(tib_lgl_vec("x", transform = ~ !.x), x = list(c(TRUE, FALSE))),
    tibble(x = list_of(c(FALSE, TRUE)))
  )
  expect_equal(
    tib_cm(tib_vector("x", dtt, transform = ~ .x + 1), x = list(c(dtt - 1, dtt))),
    tibble(x = list_of(c(dtt, dtt + 1)))
  )

  skip("Unclear if required and default makes sense for colmajor")
  # fallback default works
  expect_equal(tib(list(), tib_lgl_vec("x", required = FALSE)), tibble(x = list_of(NULL, .ptype = logical())))
  expect_equal(tib(list(), tib_vector("x", dtt, required = FALSE)), tibble(x = list_of(NULL, .ptype = vctrs::new_datetime())))

  # specified default works
  expect_equal(tib(list(), tib_lgl_vec("x", required = FALSE, fill = c(TRUE, FALSE))), tibble(x = list_of(c(TRUE, FALSE))))
  expect_equal(tib(list(), tib_vector("x", dtt, required = FALSE, fill = c(dtt, dtt + 1))), tibble(x = list_of(c(dtt, dtt + 1))))
})

test_that("list column works", {
  # can parse
  expect_equal(
    tib_cm(tib_variant("x"), x = list(TRUE, 1)),
    tibble(x = list(TRUE, 1))
  )

  # transform works
  expect_equal(
    tib_cm(
      tib_variant("x", required = FALSE, transform = ~ length(.x)),
      x = list(c(TRUE, FALSE), 1)
    ),
    tibble(x = list(2, 1))
  )
})

test_that("row works", {
  # can parse
  expect_equal(
    tib_cm(
      tib_row("x", a = tib_lgl("a")),
      x = list(a = c(TRUE, FALSE))
    ),
    tibble(x = tibble(a = c(TRUE, FALSE)))
  )

  # nested row works
  expect_equal(
    tib_cm(
      tib_row("x", tib_row("row", tib_int("int"), tib_chr_vec("chr_vec"))),
      x = list(row = list(int = 1:2, chr_vec = list("a", c("b", "c"))))
    ),
    tibble(x = tibble(row = tibble(int = 1:2, chr_vec = list_of("a", c("b", "c")))))
  )

  skip("Unclear if required and default makes sense for colmajor")
  # errors if required but absent
  expect_snapshot(
    (expect_error(tibblify(
      list(
        list(x = list(a = TRUE)),
        list()
      ),
      tspec_df(x = tib_row("x", a = tib_lgl("a")))
    )))
  )

  # fallback default works
  expect_equal(
    tibblify(
      list(
        list(x = list(a = TRUE)),
        list(x = list()),
        list()
      ),
      tspec_df(x = tib_row("x", .required = FALSE, a = tib_lgl("a", required = FALSE)))
    ),
    tibble(x = tibble(a = c(TRUE, NA, NA)))
  )
})

test_that("list of df column works", {
  # can parse
  expect_equal(
    tib_cm(
      tib_df("x", tib_int("int")),
      x = list(
        list(int = 1:2),
        list(int = integer())
      )
    ),
    tibble(x = list_of(tibble(int = 1:2), tibble(int = integer())))
  )

  # nested df works
  expect_equal(
    tib_cm(
      tib_df(
        "x",
        tib_row("row", tib_int("int")), tib_df("df", tib_int("df_int"))
      ),
      x = list(
        list(row = list(int = 1:2), df = list(list(df_int = 1), list(df_int = 3:4))),
        list(row = list(int = 3), df = list(NULL))
        # TODO should this be able to handle an empty unnamed list?
        # list(row = list(int = 3), df = list(list()))
      )
    ),
    tibble(x = list_of(
      tibble(row = tibble(int = 1:2), df = list_of(tibble(df_int = 1), tibble(df_int = 3:4))),
      tibble(row = tibble(int = 3), df = list_of(NULL, .ptype = tibble(df_int = integer())))
    ))
  )

  skip("Unclear if required and default makes sense for colmajor")
  # errors if required but absent
  expect_snapshot(
    (expect_error(tibblify(
      list(
        list(x = list(
          list(a = TRUE),
          list(a = FALSE)
        )),
        list()
      ),
      tspec_df(x = tib_df("x", a = tib_lgl("a")))
    )))
  )

  # fallback default works
  expect_equal(
    tibblify(
      list(
        list(x = list(
          list(a = TRUE),
          list(a = FALSE)
        )),
        list(x = list()),
        list()
      ),
      tspec_df(x = tib_df("x", .required = FALSE, a = tib_lgl("a", required = FALSE)))
    ),
    tibble(x = list_of(tibble(a = c(TRUE, FALSE)), tibble(a = logical()), NULL))
  )
})

test_that("tibble with list columns work - #43", {
  x <- tibble::tibble(x = list(1:3, NULL, 1:2))
  expect_equal(
    tibblify(x, tspec_df(x = tib_int_vec("x"), .input_form = "colmajor")),
    tibble(x = list_of(1:3, NULL, 1:2))
  )

  y <- tibble::tibble(x = list(tibble(a = 1:2), NULL, tibble(a = 1)))
  spec <- tspec_df(x = tib_df("x", tib_dbl("a"), .required = FALSE), .input_form = "colmajor")
  expect_equal(
    tibblify(y, tspec_df(x = tib_df("x", tib_dbl("a")))),
    tibble(x = list_of(tibble(a = 1:2), NULL, tibble(a = 1)))
  )
})

test_that("nested keys work", {
  spec <- tspec_df(
    xyz = tib_int(c("x", "y", "z")),
    .input_form = "colmajor"
  )
  expect_equal(
    tibblify(list(x = list(y = list(z = 1))), spec),
    tibble(xyz = 1)
  )

  skip("Unclear if required and default makes sense for colmajor")
  spec2 <- spec
  spec2$fields$xya <-tib_int(c("x", "y", "a"), required = FALSE, fill = 2)
  expect_equal(
    tibblify(list(x = list(y = list(z = 1))), spec2),
    tibble(xyz = 1, xya = NA_integer_)
  )
})

test_that("empty spec works", {
  expect_equal(
    tibblify(
      set_names(list()),
      tspec_df(.input_form = "colmajor")
    ),
    tibble()
  )

  expect_equal(
    tibblify(
      list(x = set_names(list())),
      tspec_df(x = tib_row("x"), .input_form = "colmajor")
    ),
    tibble(x = tibble(.rows = 0), .rows = 0)
  )
})

test_that("errors if n_rows cannot be calculated", {
  expect_snapshot({
    # after key in alphabet
    (expect_error(tib_cm(tib_int("y"), x = list(b = 1:3))))
    # before key in alphabet
    (expect_error(tib_cm(tib_int("a"), x = list(b = 1:3))))
  })
})

test_that("colmajor checks size", {
  tib_cm <- function(col1, col2, x, y) {
    tibblify(
      list(x = x, y = y),
      tspec_df(col1, col2, .input_form = "colmajor")
    )
  }

  spec_cm <- function(...) {
    tspec_df(.input_form = "colmajor", ...)
  }

  expect_snapshot({
    (expect_error(tib_cm(tib_int("x"), tib_int("y"), x = 1:2, y = 1:3)))
    (expect_error(tib_cm(tib_int("x"), tib_row("y", tib_int("x")), x = 1:2, y = list(x = 1:3))))
    (expect_error(tib_cm(tib_int("x"), tib_int_vec("y"), x = 1:2, y = list(1))))
  })
})
