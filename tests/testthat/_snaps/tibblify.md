# spec argument is checked

    Code
      (expect_error(tibblify(list(), "x")))
    Output
      <error/rlang_error>
      Error in `tibblify()`:
      ! `spec` must be a tibblify spec, not a string.
    Code
      (expect_error(tibblify(list(), tib_int("x"))))
    Output
      <error/rlang_error>
      Error in `tibblify()`:
      ! `spec` must be a tibblify spec, not a <tib_scalar_integer/tib_scalar/tib_collector> object.

# names are checked

    Code
      (expect_error(tibblify(list(1, 2), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! An object must be named.
      x `x` is not named.
    Code
      (expect_error(tibblify(list(x = 1, 2), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object can't be empty.
      x `x` has an empty name at location 2.
    Code
      (expect_error(tibblify(list(1, x = 2), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object can't be empty.
      x `x` has an empty name at location 1.
    Code
      (expect_error(tibblify(list(z = 1, y = 2, 3, a = 4), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object can't be empty.
      x `x` has an empty name at location 3.
    Code
      (expect_error(tibblify(set_names(list(1, 2), c("x", NA)), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object can't be empty.
      x `x` has an empty name at location 2.
    Code
      (expect_error(tibblify(list(x = 1, x = 2), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object must be unique.
      x `x` has the duplicated name "x".

---

    Code
      (expect_error(tibblify(list(row = list(1, 2)), spec2)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! An object must be named.
      x `x$row` is not named.
    Code
      (expect_error(tibblify(list(row = list(x = 1, 2)), spec2)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object can't be empty.
      x `x$row` has an empty name at location 2.
    Code
      (expect_error(tibblify(list(row = list(1, x = 2)), spec2)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object can't be empty.
      x `x$row` has an empty name at location 1.
    Code
      (expect_error(tibblify(list(row = list(z = 1, y = 2, 3, a = 4)), spec2)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object can't be empty.
      x `x$row` has an empty name at location 3.
    Code
      (expect_error(tibblify(list(row = set_names(list(1, 2), c("x", NA))), spec2)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object can't be empty.
      x `x$row` has an empty name at location 2.
    Code
      (expect_error(tibblify(list(row = list(x = 1, x = 2)), spec2)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object must be unique.
      x `x$row` has the duplicated name "x".

# scalar column works

    Code
      (expect_error(tib(list(), tib_lgl("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field x is required but does not exist in `x[[1]]`.
      i Use `required = FALSE` if the field is optional.
    Code
      (expect_error(tib(list(), tib_scalar("x", dtt))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field x is required but does not exist in `x[[1]]`.
      i Use `required = FALSE` if the field is optional.

---

    Code
      (expect_error(tib(list(x = c(TRUE, TRUE)), tib_lgl("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x[[1]]$x` must have size "1", not size 2.
      i You specified that the field is a scalar.
      i Use `tib_vector()` if the field is a vector instead.
    Code
      (expect_error(tib(list(x = logical()), tib_lgl("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x[[1]]$x` must have size "1", not size 0.
      i You specified that the field is a scalar.
      i Use `tib_vector()` if the field is a vector instead.
    Code
      (expect_error(tib(list(x = c(dtt, dtt)), tib_scalar("x", dtt))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x[[1]]$x` must have size "1", not size 2.
      i You specified that the field is a scalar.
      i Use `tib_vector()` if the field is a vector instead.

---

    Code
      (expect_error(tib(list(x = "a"), tib_lgl("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x[[1]]$x`
      Caused by error:
      ! Can't convert <character> to <logical>.
    Code
      (expect_error(tib(list(x = 1), tib_scalar("x", dtt))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x[[1]]$x`
      Caused by error:
      ! Can't convert <double> to <datetime<local>>.

# vector column works

    Code
      (expect_error(tib(list(), tib_lgl_vec("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field x is required but does not exist in `x[[1]]`.
      i Use `required = FALSE` if the field is optional.
    Code
      (expect_error(tib(list(), tib_vector("x", dtt))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field x is required but does not exist in `x[[1]]`.
      i Use `required = FALSE` if the field is optional.

---

    Code
      (expect_error(tib(list(x = "a"), tib_lgl_vec("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x[[1]]$x`
      Caused by error:
      ! Can't convert <character> to <logical>.

# vector column respects vector_allows_empty_list

    Code
      (expect_error(tibblify(x, tspec_df(tib_int_vec("x")))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x[[2]]$x`
      Caused by error:
      ! Can't convert <list> to <integer>.

# vector column can parse scalar list

    Code
      (expect_error(tib(list(x = 1), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x[[1]]$x` must be a list, not a number.
      x `input_form = "scalar_list"` can only parse lists.
      i Use `input_form = "vector"` (the default) if the field is already a vector.
    Code
      (expect_error(tib(list(x = 1), tspec_object)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x[[1]]$x` must be a list, not a number.
      x `input_form = "object"` can only parse lists.
      i Use `input_form = "vector"` (the default) if the field is already a vector.

---

    Code
      (expect_error(tib(list(x = list(1, 1:2)), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x[[1]]$x` is not a list of scalars.
      x Element 2 must have size 1, not size 2.
    Code
      (expect_error(tib(list(x = list(integer())), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x[[1]]$x` is not a list of scalars.
      x Element 1 must have size 1, not size 0.

---

    Code
      (expect_error(tib(list(x = list(1, "a")), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x[[1]]$x`
      Caused by error:
      ! Can't convert <character> to <integer>.

# vector column can parse object

    Code
      (expect_error(tib(list(x = list(1, 2)), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! A vector must be a named list for `input_form = "object."`
      x `x[[1]]$x` is not named.

# list column works

    Code
      (expect_error(tibblify(list(list(x = TRUE), list(zzz = 1)), tspec_df(x = tib_variant(
        "x")))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field x is required but does not exist in `x[[2]]`.
      i Use `required = FALSE` if the field is optional.

# df column works

    Code
      (expect_error(tibblify(list(list(x = list(a = TRUE)), list()), tspec_df(x = tib_row(
        "x", a = tib_lgl("a"))))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field x is required but does not exist in `x[[2]]`.
      i Use `required = FALSE` if the field is optional.

# list of df column works

    Code
      (expect_error(tibblify(list(list(x = list(list(a = TRUE), list(a = FALSE))),
      list()), tspec_df(x = tib_df("x", a = tib_lgl("a"))))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field x is required but does not exist in `x[[2]]`.
      i Use `required = FALSE` if the field is optional.
    Code
      (expect_error(tibblify(list(list(x = list(list(a = TRUE), list()))), tspec_df(
        x = tib_df("x", a = tib_lgl("a"))))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field a is required but does not exist in `x[[1]]$x[[2]]`.
      i Use `required = FALSE` if the field is optional.

# colmajor: names are checked

    Code
      (expect_error(tibblify(list(1, 2), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! An object must be named.
      x `x` is not named.
    Code
      (expect_error(tibblify(list(x = 1, 2), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object can't be empty.
      x `x` has an empty name at location 2.
    Code
      (expect_error(tibblify(list(1, x = 2), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object can't be empty.
      x `x` has an empty name at location 1.
    Code
      (expect_error(tibblify(list(z = 1, y = 2, 3, a = 4), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object can't be empty.
      x `x` has an empty name at location 3.
    Code
      (expect_error(tibblify(set_names(list(1, 2), c("x", NA)), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object can't be empty.
      x `x` has an empty name at location 2.
    Code
      (expect_error(tibblify(list(x = 1, x = 2), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! The names of an object must be unique.
      x `x` has the duplicated name "x".

# colmajor: scalar column works

    Code
      (expect_error(tib_cm(x = "a", tib_lgl("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x$x`
      Caused by error:
      ! Can't convert <character> to <logical>.
    Code
      (expect_error(tib_cm(x = 1, tib_scalar("x", dtt))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x$x`
      Caused by error:
      ! Can't convert <double> to <datetime<local>>.

# colmajor: vector column works

    Code
      (expect_error(tib_cm(tib_lgl_vec("x"), x = "a")))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x$x` must be a list, not a string.
    Code
      (expect_error(tib_cm(tib_lgl_vec("x"), x = list("a"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x$x`
      Caused by error:
      ! Can't convert <character> to <logical>.

# errors if n_rows cannot be calculated

    Code
      (expect_error(tib_cm(tib_int("y"), x = list(b = 1:3))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x`
      Caused by error:
      ! Could not determine number of rows.
    Code
      (expect_error(tib_cm(tib_int("a"), x = list(b = 1:3))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x`
      Caused by error:
      ! Could not determine number of rows.

# colmajor can calculate size

    Code
      expect_error(tibblify(list(row = "a"), tspec_df(tib_row("row", tib_int("x")),
      .input_form = "colmajor")))

# colmajor checks size

    Code
      (expect_error(tib_cm(tib_int("x"), tib_int("y"), x = 1:2, y = 1:3)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Not all fields of `x` have the same size.
      x Field y has size 3.
      x Other fields have size 2.
    Code
      (expect_error(tib_cm(tib_int("x"), tib_row("y", tib_int("x")), x = 1:2, y = list(
        x = 1:3))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Not all fields of `x$y` have the same size.
      x Field x has size 3.
      x Other fields have size 2.
    Code
      (expect_error(tib_cm(tib_int("x"), tib_int_vec("y"), x = 1:2, y = list(1))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Not all fields of `x` have the same size.
      x Field y has size 1.
      x Other fields have size 2.

