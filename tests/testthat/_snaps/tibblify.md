# spec argument is checked

    Code
      (expect_error(tibblify(list(), "x")))
    Output
      <error/rlang_error>
      Error in `tibblify()`:
      ! `spec` must be a tibblify spec, not the string "x".
    Code
      (expect_error(tibblify(list(), tib_int("x"))))
    Output
      <error/rlang_error>
      Error in `tibblify()`:
      ! `spec` must be a tibblify spec, not a <tib_scalar_integer> object.

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

# tib_scalar works

    Code
      (expect_error(tib(list(a = 1), tib_lgl("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field x is required but does not exist in `x[[1]]`.
      i Use `required = FALSE` if the field is optional.
    Code
      (expect_error(tib(list(a = 1), tib_scalar("x", dtt))))
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
      ! `x[[1]]$x` must have size 1, not size 2.
      i You specified that the field is a scalar.
      i Use `tib_vector()` if the field is a vector instead.
    Code
      (expect_error(tib(list(x = logical()), tib_lgl("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x[[1]]$x` must have size 1, not size 0.
      i You specified that the field is a scalar.
      i Use `tib_vector()` if the field is a vector instead.
    Code
      (expect_error(tib(list(x = c(dtt, dtt)), tib_scalar("x", dtt))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x[[1]]$x` must have size 1, not size 2.
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

# tib_vector works

    Code
      (expect_error(tib(list(a = 1), tib_lgl_vec("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field x is required but does not exist in `x[[1]]`.
      i Use `required = FALSE` if the field is optional.
    Code
      (expect_error(tib(list(a = 1), tib_vector("x", dtt))))
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

# tib_vector respects vector_allows_empty_list

    Code
      (expect_error(tibblify(x, tspec_df(tib_int_vec("x")))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x[[2]]$x`
      Caused by error:
      ! Can't convert <list> to <integer>.

# tib_vector can parse scalar list

    Code
      (expect_error(tib(list(x = 1), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x[[1]]$x` must be a list, not the number 1.
      x `input_form = "scalar_list"` can only parse lists.
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
      (expect_error(tib(list(x = list(NULL, 1, 1:2)), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x[[1]]$x` is not a list of scalars.
      x Element 3 must have size 1, not size 2.

---

    Code
      (expect_error(tib(list(x = list(1, "a")), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x[[1]]$x`
      Caused by error in `vctrs::list_unchop()`:
      ! Can't convert `x[[2]]` <character> to <integer>.

# tib_vector can parse object

    Code
      (expect_error(tib(list(x = list(1, 2)), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! A vector must be a named list for `input_form = "object."`
      x `x[[1]]$x` is not named.

---

    Code
      (expect_error(tib(list(x = 1), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x[[1]]$x` must be a list, not the number 1.
      x `input_form = "object"` can only parse lists.
      i Use `input_form = "vector"` (the default) if the field is already a vector.

---

    Code
      (expect_error(tib(list(x = list(a = 1, b = 1:2)), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x[[1]]$x` is not an object.
      x Element 2 must have size 1, not size 2.

# tib_variant works

    Code
      (expect_error(tibblify(list(list(x = TRUE), list(zzz = 1)), tspec_df(x = tib_variant(
        "x")))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field x is required but does not exist in `x[[2]]`.
      i Use `required = FALSE` if the field is optional.

# tib_row works

    Code
      (expect_error(tibblify(list(list(x = list(a = TRUE)), list()), tspec_df(x = tib_row(
        "x", a = tib_lgl("a"))))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field x is required but does not exist in `x[[2]]`.
      i Use `required = FALSE` if the field is optional.

# tib_df works

    Code
      (expect_error(tibblify(list(list(x = list(list(a = TRUE), list(a = FALSE))),
      list(a = 1)), tspec_df(x = tib_df("x", a = tib_lgl("a"))))))
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
      ! Field x is required but does not exist in `x`.
      i For `.input_form = "colmajor"` every field is required.
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

# colmajor: tib_scalar works

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

# colmajor: tib_vector works

    Code
      (expect_error(tib_cm(tib_lgl_vec("x"), x = "a")))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x$x` must be a list, not the string "a".
    Code
      (expect_error(tib_cm(tib_lgl_vec("x"), x = list("a"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x$x`
      Caused by error:
      ! Can't convert <character> to <logical>.

# colmajor: tib_df works

    Code
      (expect_error(tib_cm(tib_df("x", tib_int("a"), tib_chr("b")), x = list(list(b = c(
        "a", "b"), a = 1:2), list(a = character(), b = "c")))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Not all fields of `x` have the same size.
      x Field x$x[[2]]$b has size 1.
      x Field x$x[[2]]$a has size 0.

# colmajor: errors if field is absent

    Code
      (expect_error(tib_cm(tib_int("y"), x = list(b = 1:3))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field y is required but does not exist in `x`.
      i For `.input_form = "colmajor"` every field is required.
    Code
      (expect_error(tib_cm(tib_int("x"), tib_int("y", required = FALSE), x = list(b = 1:
        3))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field y is required but does not exist in `x`.
      i For `.input_form = "colmajor"` every field is required.

# colmajor: can calculate size

    Code
      (expect_error(tibblify(list(row = "a"), tspec_df(tib_row("row", tib_int("x")),
      .input_form = "colmajor"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! `x$row` must be a list, not the string "a".

# colmajor: errors on NULL value

    Code
      (expect_error(tib_cm(tib_int("x"), x = NULL)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Field x$x must not be "NULL".

# colmajor: checks size

    Code
      (expect_error(tib_cm(tib_int("x"), tib_int("y"), x = 1:2, y = 1:3)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Not all fields of `x` have the same size.
      x Field x$y has size 3.
      x Field x$x has size 2.
    Code
      (expect_error(tib_cm(tib_int("x"), tib_row("y", tib_int("x")), x = 1:2, y = list(
        x = 1:3))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Not all fields of `x` have the same size.
      x Field x$y$x has size 3.
      x Field x$x has size 2.
    Code
      (expect_error(tib_cm(tib_int("x"), tib_int_vec("y"), x = 1:2, y = list(1))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Not all fields of `x` have the same size.
      x Field x$y has size 1.
      x Field x$x has size 2.

# recursive: works

    Code
      (expect_error(tibblify(x2, spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Problem while tibblifying `x[[1]]$children[[2]]$children[[1]]$id`
      Caused by error:
      ! Can't convert <character> to <integer>.

