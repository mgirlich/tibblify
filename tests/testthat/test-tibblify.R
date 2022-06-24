test_that("names are checked", {
  spec <- spec_object(x = tib_int("x", required = FALSE))

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
  expect_equal(tib(list(x = 1), tib_int("x")), tibble(x = 1L))
  expect_equal(tib(list(x = 1.5), tib_dbl("x")), tibble(x = 1.5))
  expect_equal(tib(list(x = "a"), tib_chr("x")), tibble(x = "a"))
  expect_equal(tib(list(x = dtt), tib_scalar("x", dtt)), tibble(x = dtt))

  # errors if required but absent
  expect_snapshot_error(tib(list(), tib_lgl("x")))
  expect_snapshot_error(tib(list(), tib_int("x")))
  expect_snapshot_error(tib(list(), tib_dbl("x")))
  expect_snapshot_error(tib(list(), tib_chr("x")))
  expect_snapshot_error(tib(list(), tib_scalar("x", dtt)))

  # errors if bad size
  expect_snapshot_error(tib(list(x = c(TRUE, TRUE)), tib_lgl("x")))
  expect_snapshot_error(tib(list(x = c(1, 1)), tib_int("x")))
  expect_snapshot_error(tib(list(x = c(1.5, 1.5)), tib_dbl("x")))
  expect_snapshot_error(tib(list(x = c("a", "a")), tib_chr("x")))
  expect_snapshot_error(tib(list(x = c(dtt, dtt)), tib_scalar("x", dtt)))

  # errors if bad type
  expect_snapshot_error(tib(list(x = "a"), tib_lgl("x")))
  expect_snapshot_error(tib(list(x = "a"), tib_int("x")))
  expect_snapshot_error(tib(list(x = "a"), tib_dbl("x")))
  expect_snapshot_error(tib(list(x = 1), tib_chr("x")))
  expect_snapshot_error(tib(list(x = 1), tib_scalar("x", dtt)))

  # fallback default works
  expect_equal(tib(list(), tib_lgl("x", required = FALSE)), tibble(x = NA))
  expect_equal(tib(list(), tib_int("x", required = FALSE)), tibble(x = NA_integer_))
  expect_equal(tib(list(), tib_dbl("x", required = FALSE)), tibble(x = NA_real_))
  expect_equal(tib(list(), tib_chr("x", required = FALSE)), tibble(x = NA_character_))
  expect_equal(tib(list(), tib_scalar("x", dtt, required = FALSE)), tibble(x = vctrs::new_datetime(NA_real_)))

  # use default if empty element
  expect_equal(tib(list(x = NULL), tib_lgl("x", required = FALSE, default = FALSE)), tibble(x = FALSE))
  expect_equal(tib(list(x = NULL), tib_int("x", required = FALSE, default = 1)), tibble(x = 1))
  expect_equal(tib(list(x = NULL), tib_dbl("x", required = FALSE, default = 1.5)), tibble(x = 1.5))
  expect_equal(tib(list(x = NULL), tib_chr("x", required = FALSE, default = "a")), tibble(x = "a"))
  expect_equal(
    tib(list(x = NULL), tib_scalar("x", vec_ptype(dtt), required = FALSE, default = dtt)),
    tibble(x = dtt)
  )

  # specified default works
  expect_equal(tib(list(), tib_lgl("x", required = FALSE, default = FALSE)), tibble(x = FALSE))
  expect_equal(tib(list(), tib_int("x", required = FALSE, default = 1)), tibble(x = 1))
  expect_equal(tib(list(), tib_dbl("x", required = FALSE, default = 1.5)), tibble(x = 1.5))
  expect_equal(tib(list(), tib_chr("x", required = FALSE, default = "a")), tibble(x = "a"))
  expect_equal(
    tib(list(), tib_scalar("x", vec_ptype(dtt), required = FALSE, default = dtt)),
    tibble(x = dtt)
  )

  # transform works
  expect_equal(
    tib(list(x = TRUE), tib_lgl("x", transform = ~ !.x)),
    tibble(x = FALSE)
  )
  expect_equal(
    tib(list(x = 1), tib_int("x", transform = ~ .x - 1)),
    tibble(x = 0)
  )
  expect_equal(
    tib(list(x = 1.5), tib_dbl("x", transform = ~ .x - 1)),
    tibble(x = 0.5)
  )
  expect_equal(
    tib(list(x = "a"), tib_chr("x", transform = ~ paste0(.x, "b"))),
    tibble(x = "ab")
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
      spec_df(
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
      spec_df(
        timediff = tib_scalar("timediff", ptype = td1)
      )
    ),
    tibble(timediff = c(td1, td2))
  )
})

test_that("vector column works", {
  dtt <- vctrs::new_datetime(1)

  # can parse
  expect_equal(tib(list(x = c(TRUE, FALSE)), tib_lgl_vec("x")), tibble(x = list_of(c(TRUE, FALSE))))
  expect_equal(tib(list(x = c(dtt, dtt + 1)), tib_vector("x", dtt)), tibble(x = list_of(c(dtt, dtt + 1))))

  # errors if required but absent
  expect_snapshot_error(tib(list(), tib_lgl_vec("x")))
  expect_snapshot_error(tib(list(), tib_vector("x", dtt)))

  # errors if bad type
  expect_snapshot_error(tib(list(x = "a"), tib_lgl_vec("x")))

  # fallback default works
  expect_equal(tib(list(), tib_lgl_vec("x", required = FALSE)), tibble(x = list_of(NULL, .ptype = logical())))
  expect_equal(tib(list(), tib_vector("x", dtt, required = FALSE)), tibble(x = list_of(NULL, .ptype = vctrs::new_datetime())))

  # specified default works
  expect_equal(tib(list(), tib_lgl_vec("x", required = FALSE, default = c(TRUE, FALSE))), tibble(x = list_of(c(TRUE, FALSE))))
  expect_equal(tib(list(), tib_vector("x", dtt, required = FALSE, default = c(dtt, dtt + 1))), tibble(x = list_of(c(dtt, dtt + 1))))

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

  spec2 <- tib_int_vec("x", required = FALSE, default = c(1:2), values_to = "val")
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
      spec_df(x = spec)
    ),
    tibble(x = list_of(1:2, NULL))
  )

  # handles empty list
  expect_equal(
    tibblify(
      list(list(x = list(1, 2)), list(x = list())),
      spec_df(x = spec)
    ),
    tibble(x = list_of(1:2, integer()))
  )

  expect_snapshot({
    (expect_error(tib(list(x = 1), spec)))
  })
})

test_that("vector column can parse object", {
  spec <- tib_int_vec("x", input_form = "object")
  expect_equal(
    tib(list(x = list(a = 1, b = NULL, c = 3)), spec),
    tibble(x = list_of(c(1L, NA, 3L)))
  )

  skip("Unclear what tib_vector should do with missing names")
  expect_equal(
    tib(list(x = list(1, 2)), spec),
    tibble(x = list_of(c(1L, 2L)))
  )

  skip("Unclear what tib_vector should do with partial names")
  expect_equal(
    tib(list(x = list(a = 1, 2)), spec),
    tibble(x = list_of(c(1L, 2L)))
  )

  skip("Unclear what tib_vector should do with duplicate names")
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
    default = c(x = 1L, y = 2L),
    required = FALSE,
    input_form = "object",
    values_to = "val",
    names_to = "name"
  )
  expect_equal(
    tib(list(a = 1), spec2),
    tibble(x = list_of(tibble(name = c("x", "y"), val = c(1L, 2L))))
  )

  # currently not clear what to do about missing names but it should not crash
  # and if no error is thrown it should at least produce both columns
  expect_named(
    tib(list(x = list(1, NULL)), spec)$x[[1]],
    c("name", "val")
  )

  skip("Unclear what tib_vector should do with missing names")
  expect_equal(
    tib(list(x = list(1, NULL)), spec),
    tibble(x = list_of(tibble(name = c(NA, NA), val = c(1L, NA))))
  )
})

test_that("list column works", {
  # can parse
  expect_equal(
    tibblify(
      list(list(x = TRUE), list(x = 1)),
      spec_df(x = tib_variant("x"))
    ),
    tibble(x = list(TRUE, 1))
  )

  expect_equal(
    tibblify(
      list(x = TRUE),
      spec_row(x = tib_variant("x"))
    ),
    tibble(x = list(TRUE))
  )

  # errors if required but absent
  expect_snapshot_error(
    tibblify(
      list(list(x = TRUE), list(zzz = 1)),
      spec_df(x = tib_variant("x"))
    )
  )

  # fallback default works
  expect_equal(
    tibblify(
      list(list(), list(x = 1)),
      spec_df(x = tib_variant("x", required = FALSE))
    ),
    tibble(x = list(NULL, 1))
  )

  # specified default works
  expect_equal(
    tibblify(
      list(list()),
      spec_df(x = tib_variant("x", required = FALSE, default = 1))
    ),
    tibble(x = list(1))
  )

  # transform works
  expect_equal(
    tibblify(
      list(list(x = c(TRUE, FALSE)), list(x = 1)),
      spec_df(x = tib_variant("x", required = FALSE, transform = ~ length(.x)))
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
      spec_df(x = tib_row("x", a = tib_lgl("a")))
    ),
    tibble(x = tibble(a = c(TRUE, FALSE)))
  )

  # errors if required but absent
  expect_snapshot_error(
    tibblify(
      list(
        list(x = list(a = TRUE)),
        list()
      ),
      spec_df(x = tib_row("x", a = tib_lgl("a")))
    )
  )

  # fallback default works
  expect_equal(
    tibblify(
      list(
        list(x = list(a = TRUE)),
        list(x = list()),
        list()
      ),
      spec_df(x = tib_row("x", .required = FALSE, a = tib_lgl("a", required = FALSE)))
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
      spec_df(x = tib_df("x", a = tib_lgl("a")))
    ),
    tibble(x = list_of(tibble(a = c(TRUE, FALSE))))
  )

  # errors if required but absent
  expect_snapshot_error(
    tibblify(
      list(
        list(x = list(
          list(a = TRUE),
          list(a = FALSE)
        )),
        list()
      ),
      spec_df(x = tib_df("x", a = tib_lgl("a")))
    )
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
      spec_df(x = tib_df("x", .required = FALSE, a = tib_lgl("a", required = FALSE)))
    ),
    tibble(x = list_of(tibble(a = c(TRUE, FALSE)), tibble(a = logical()), NULL))
  )
})

test_that("names_to works", {
  tib2 <- function(x, y, col) {
    tibblify(
      list(x, y),
      spec_df(x = col)
    )
  }

  # can parse
  expect_equal(
    tibblify(
      list(
        a = list(x = TRUE),
        b = list(x = FALSE)
      ),
      spec_df(x = tib_lgl("x"), .names_to = "nms")
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
      spec_df(x = tib_lgl("x"), .names_to = "nms")
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
      spec_df(x = tib_lgl("x"), .names_to = "nms")
    ),
    tibble(nms = c("", ""), x = c(TRUE, FALSE))
  )
})

test_that("tibble input works", {
  df <- tibble(x = 1:2, y = c("a", "b"))

  expect_equal(
    tibblify(
      df,
      spec_df(
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
      spec_df(
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

test_that("nested keys work", {
  expect_equal(
    tibblify(
      list(list(x = list(y = list(z = 1)))),
      spec_df(xyz = tib_int(list("x", "y", "z")))
    ),
    tibble(xyz = 1)
  )
})

test_that("empty spec works", {
  expect_equal(
    tibblify(
      list(list(), list()),
      spec_df()
    ),
    tibble(.rows = 2)
  )

  expect_equal(
    tibblify(
      list(),
      spec_df()
    ),
    tibble()
  )

  tibblify(
    list(list(x = list()), list(x = list())),
    spec_df(x = tib_row("x", a = tib_int("a", required = FALSE)))
  )

  expect_equal(
    tibblify(
      list(list(x = list()), list(x = list())),
      spec_df(x = tib_row("x"))
    ),
    tibble(x = tibble(.rows = 2), .rows = 2)
  )

  expect_equal(
    tibblify(
      list(),
      spec_df(x = tib_row("x", .required = FALSE))
    ),
    tibble(x = tibble())
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
          descriptions = list_of("Numbered"),
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

  spec_collection <- spec_df(
    instance_id = tib_int("instance_id"),
    date_added = tib_chr("date_added"),
    basic_information = tib_row(
      "basic_information",
      labels = tib_df(
        "labels",
        name = tib_chr("name"),
        entity_type = tib_chr("entity_type"),
        catno = tib_chr("catno"),
        resource_url = tib_chr("resource_url"),
        id = tib_int("id"),
        entity_type_name = tib_chr("entity_type_name")
      ),
      year = tib_int("year"),
      master_url = tib_chr("master_url"),
      artists = tib_df(
        "artists",
        join = tib_chr("join"),
        name = tib_chr("name"),
        anv = tib_chr("anv"),
        tracks = tib_chr("tracks"),
        role = tib_chr("role"),
        resource_url = tib_chr("resource_url"),
        id = tib_int("id")
      ),
      id = tib_int("id"),
      thumb = tib_chr("thumb"),
      title = tib_chr("title"),
      formats = tib_df(
        "formats",
        descriptions = tib_chr_vec(
          "descriptions",
          transform = ~ vctrs::vec_c(!!!.x, .ptype = character())
        ),
        text = tib_chr("text", required = FALSE),
        name = tib_chr("name"),
        qty = tib_chr("qty")
      ),
      cover_image = tib_chr("cover_image"),
      resource_url = tib_chr("resource_url"),
      master_id = tib_int("master_id")
    ),
    id = tib_int("id"),
    rating = tib_int("rating"),
  )

  expect_equal(tibblify(discog[1], spec_collection), row1)
  expect_equal(tibblify(row1, spec_collection), row1)

  specs_object <- spec_row(!!!spec_collection$fields)
  expect_equal(tibblify(discog[[1]], specs_object), row1)
  expect_equal(tibblify(row1, specs_object), row1)
})

test_that("spec_object() works", {
  x <- list(a = 1, b = 1:3)
  spec <- spec_row(a = tib_int("a"), b = tib_int_vec("b"))

  expect_equal(
    tibblify(x, spec),
    tibble(a = 1L, b = list_of(1:3))
  )
  expect_equal(
    tibblify(x, spec_object(spec)),
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

  spec2 <- spec_row(
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
    tibblify(x2, spec_object(spec2)),
    list(
      a = list(
        x = 1L,
        y = list(a = 1L),
        z = tibble(b = 1:2)
      )
    )
  )
})

# remove_spec <- function(x) {
#   attr(x, "spec") <- NULL
#   x
# }
#
# test_that("default works", {
#   recordlist <- list(
#     list(int = 1, chr = "a"),
#     list(int = 2, chr = "b")
#   )
#
#   # no default provided
#   expect_equal(
#     tibblify(
#       recordlist,
#       spec = lcols(
#         int = lcol_int("int")
#       )
#     ),
#     tibble::tibble(int = 1:2),
#     ignore_attr = "spec"
#   )
#
#   # default: skip
#   expect_equal(
#     tibblify(
#       recordlist,
#       lcols(
#         int = lcol_int("int")
#       )
#     ),
#     tibble::tibble(int = 1:2),
#     ignore_attr = "spec"
#   )
# })
#
# test_that("df_cols work", {
#   recordlist <- list(
#     list(
#       df = list(
#         chr = "a",
#         int = 1
#       )
#     ),
#     list(
#       df = list(
#         chr = "b",
#         int = 2
#       )
#     )
#   )
#
#   col_specs <- lcols(
#     df = lcol_df(
#       "df",
#       chr = lcol_chr("chr", .default = NA_character_),
#       int = lcol_int("int")
#     )
#   )
#
#   expect_equal(
#     tibblify(recordlist, col_specs),
#     tibble::tibble(
#       df = tibble::tibble(
#         chr = c("a", "b"),
#         int = 1:2
#       )
#     ),
#     ignore_attr = "spec"
#   )
#
#   expect_equal(
#     tibblify(list(), col_specs),
#     tibble::tibble(
#       df = tibble::tibble(
#         chr = character(),
#         int = integer()
#       )
#     ),
#     ignore_attr = "spec"
#   )
# })
#
# test_that("df_lst_cols work", {
#   recordlist <- list(
#     list(
#       df = list(
#         list(
#           chr = "a",
#           int = 1
#         ),
#         list(
#           chr = "b",
#           int = 2
#         )
#       )
#     ),
#     list(
#       df = list(
#         list(
#           chr = "c"
#         )
#       )
#     )
#   )
#
#   col_specs <- lcols(
#     df = lcol_df_lst(
#       "df",
#       chr = lcol_chr("chr"),
#       int = lcol_int("int", .default = NA_integer_)
#     )
#   )
#
#   expect_equal(
#     tibblify(recordlist, col_specs),
#     tibble::tibble(
#       df = list_of(
#         tibble::tibble(
#           chr = c("a", "b"),
#           int = 1:2
#         ),
#         tibble::tibble(
#           chr = "c",
#           int = NA_integer_
#         )
#       )
#     ),
#     ignore_attr = "spec"
#   )
#
#   expect_equal(
#     tibblify(list(), col_specs),
#     tibble::tibble(
#       df = list_of(.ptype =
#         tibble::tibble(
#           chr = character(),
#           int = integer()
#         )
#       )
#     ),
#     ignore_attr = "spec"
#   )
# })
#
# test_that("old spec works", {
#   x_rcrd <- as.POSIXlt(Sys.time(), tz = "UTC")
#   recordlist <- list(
#     list(a = x_rcrd),
#     list(a = x_rcrd + 1)
#   )
#
#   spec <- lcols(
#     a = lcol_vec("a", ptype = x_rcrd)
#   )
#
#   expect_equal(
#     tibblify(recordlist, spec),
#     tibble::tibble(a = vec_c(!!!purrr::map(recordlist, "a"), .ptype = x_rcrd)),
#     ignore_attr = "spec"
#   )
#
#   now <- Sys.time()
#   past <- now - c(100, 200)
#
#   recordlist <- list(
#     list(timediff = now - past[1]),
#     list(timediff = now - past[2])
#   )
#
#   spec <- lcols(
#     timediff = lcol_vec("timediff", ptype = recordlist[[1]]$timediff)
#   )
#
#   expect_equal(
#     tibblify(recordlist, spec),
#     tibble::tibble(timediff = vec_c(!!!purrr::map(recordlist, "timediff"))),
#     ignore_attr = "spec"
#   )
# })
