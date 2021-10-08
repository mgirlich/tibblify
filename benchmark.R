list(
  list(a = mtcars),
  list(a = mtcars)
) %>%
  tibblify(
    spec_df(
      a = tib_df(
        "a",
        !!!purrr::map(
          set_names(c("disp", "hp", "drat", "wt", "qsec", "vs", "am", "gear", "carb", "mpg", "cyl")),
          ~ tib_dbl(key = .x, required = TRUE, default = 1.5)
        )
      )
    )
  )


mtcars_spec <- spec_df(
  !!!purrr::map(
    # set_names(c("disp", "hp", "drat", "wt", "qsec", "vs", "am", "gear", "carb", "mpg", "cyl")),
    set_names(c("mpg", "cyl", "disp", "hp", "drat", "wt", "qsec", "vs", "am", "gear", "carb")),
    ~ tib_dbl(key = .x, required = TRUE, default = 1.5)
  )
)

# object_list <- vec_rep(purrr::map(vec_chop(mtcars), unclass), 10e3)
object_list <- vec_rep(vec_chop(mtcars), 10e3)
object_list <- vec_rep(vec_chop(mtcars %>% tibble::rownames_to_column("name")), 10e3)
object_list <- vec_rep(vec_chop(mtcars), 10e3)

# 10x as fast as `vec_rbind()`
bench::mark(
  # rbind = vctrs::vec_rbind(!!!object_list, .ptype = vec_ptype(object_list[[1]])),
  # vec_c = vctrs::vec_c(!!!object_list, .ptype = vec_ptype(object_list[[1]])),
  tibblify = tibblify(object_list, mtcars_spec),
  iterations = 5,
  check = FALSE
)


# # A tibble: 4 × 13
#   expression                                             min   median `itr/sec` mem_alloc `gc/sec`
#   <bch:expr>                                        <bch:tm> <bch:tm>     <dbl> <bch:byt>    <dbl>
# 1 parse_row_to_tibble_R(object_list)                  12.04s   12.04s    0.0831    34.2MB    2.91
# 2 parse_row_to_tibble_C(object_list)                   2.83s    2.83s    0.354     31.7MB    0.707
# 3 parse_normalise_row_C_transpose_purr(object_list) 673.25ms 673.25ms    1.49      95.2MB    1.49
# 4 parse_transpose_normalise_row_C(object_list)      642.96ms 642.96ms    1.56      92.8MB    1.56
