# errors on invalid names

    Code
      (expect_error(tspec_df(x = tib_int("x"), x = tib_int("y"))))
    Output
      <error/vctrs_error_names_must_be_unique>
      Error in `tspec_df()`:
      ! Names must be unique.
      x These names are duplicated:
        * "x" at locations 1 and 2.

# errors if element is not a tib collector

    Code
      (expect_error(tspec_df(1)))
    Output
      <error/rlang_error>
      Error in `tspec_df()`:
      ! ..1 must be a tib collector, not a number.
    Code
      (expect_error(tspec_df(x = tib_int("x"), y = "a")))
    Output
      <error/rlang_error>
      Error in `tspec_df()`:
      ! y must be a tib collector, not a string.

# can infer name from key

    Code
      (expect_error(tspec_df(tib_int(c("a", "b")))))
    Output
      <error/rlang_error>
      Error in `tspec_df()`:
      ! `key` must be a single string to infer name.
      x `key` of ..1 has length 2.
    Code
      (expect_error(tspec_df(y = tib_int("x"), tib_int("y"))))
    Output
      <error/vctrs_error_names_must_be_unique>
      Error in `tspec_df()`:
      ! Names must be unique.
      x These names are duplicated:
        * "y" at locations 1 and 2.

# can nest specifications

    Code
      (expect_error(tspec_df(spec1, spec1)))
    Output
      <error/vctrs_error_names_must_be_unique>
      Error in `tspec_df()`:
      ! Names must be unique.
      x These names are duplicated:
        * "a" at locations 1 and 3.
        * "b" at locations 2 and 4.

# errors on invalid `.names_to`

    Code
      (expect_error(tspec_df(.names_to = NA_character_)))
    Output
      <error/rlang_error>
      Error in `tspec_df()`:
      ! `.names_to` must be a single string or `NULL`, not a character `NA`.
    Code
      (expect_error(tspec_df(.names_to = 1)))
    Output
      <error/rlang_error>
      Error in `tspec_df()`:
      ! `.names_to` must be a single string or `NULL`, not a number.

# errors if `.names_to` column name is not unique

    Code
      (expect_error(tspec_df(x = tib_int("x"), .names_to = "x")))
    Output
      <error/rlang_error>
      Error in `tspec_df()`:
      ! The column name of `.names_to` is already specified in `...`.

# errors if `.names_to` is used with colmajor

    Code
      (expect_error(tspec_df(.names_to = "x", .input_form = "colmajor")))
    Output
      <error/rlang_error>
      Error in `tspec_df()`:
      ! Can't use `.names_to` with `.input_form = "colmajor"`.

# errors if `vector_allows_empty_list` is invalid

    Code
      (expect_error(tspec_df(vector_allows_empty_list = NA)))
    Output
      <error/rlang_error>
      Error in `tspec_df()`:
      ! `vector_allows_empty_list` must be `TRUE` or `FALSE`, not `NA`.
    Code
      (expect_error(tspec_df(vector_allows_empty_list = "a")))
    Output
      <error/rlang_error>
      Error in `tspec_df()`:
      ! `vector_allows_empty_list` must be `TRUE` or `FALSE`, not a string.

# errors on invalid `key`

    Code
      (expect_error(tib_int(character())))
    Output
      <error/rlang_error>
      Error in `tib_int()`:
      ! `key` must not be empty.
    Code
      (expect_error(tib_int(NA_character_)))
    Output
      <error/rlang_error>
      Error in `tib_int()`:
      ! `key` must not be "NA".
    Code
      (expect_error(tib_int("")))
    Output
      <error/rlang_error>
      Error in `tib_int()`:
      ! `key` must not be an empty string.
    Code
      (expect_error(tib_int(1L)))
    Output
      <error/rlang_error>
      Error in `tib_int()`:
      ! `key` must be a character vector, not an integer.
    Code
      (expect_error(tib_int(c("x", NA))))
    Output
      <error/rlang_error>
      Error in `tib_int()`:
      ! `key[2] must not be NA.
    Code
      (expect_error(tib_int(c("x", ""))))
    Output
      <error/rlang_error>
      Error in `tib_int()`:
      ! `key[2] must not be an empty string.

# errors on invalid `required`

    Code
      (expect_error(tib_int("x", required = logical())))
    Output
      <error/rlang_error>
      Error in `tib_int()`:
      ! `required` must be `TRUE` or `FALSE`, not an empty logical vector.
    Code
      (expect_error(tib_int("x", required = NA)))
    Output
      <error/rlang_error>
      Error in `tib_int()`:
      ! `required` must be `TRUE` or `FALSE`, not `NA`.
    Code
      (expect_error(tib_int("x", required = 1L)))
    Output
      <error/rlang_error>
      Error in `tib_int()`:
      ! `required` must be `TRUE` or `FALSE`, not an integer.
    Code
      (expect_error(tib_int("x", required = c(TRUE, FALSE))))
    Output
      <error/rlang_error>
      Error in `tib_int()`:
      ! `required` must be `TRUE` or `FALSE`, not a logical vector.

# errors if dots are not empty

    Code
      (expect_error(tib_int("x", TRUE)))
    Output
      <error/rlib_error_dots_nonempty>
      Error in `tib_int()`:
      ! `...` must be empty.
      x Problematic argument:
      * ..1 = TRUE
      i Did you forget to name an argument?

# tib_scalar checks arguments

    Code
      (expect_error(tib_scalar("x", model)))
    Output
      <error/vctrs_error_scalar_type>
      Error in `tib_scalar()`:
      ! `ptype` must be a vector, not a <lm> object.

---

    Code
      (expect_error(tib_chr("x", ptype_inner = model)))
    Output
      <error/vctrs_error_scalar_type>
      Error in `tib_chr()`:
      ! `ptype_inner` must be a vector, not a <lm> object.

---

    Code
      (expect_error(tib_int("x", fill = integer())))
    Output
      <error/vctrs_error_assert_size>
      Error in `tib_int()`:
      ! `fill` must have size 1, not size 0.
    Code
      (expect_error(tib_int("x", fill = 1:2)))
    Output
      <error/vctrs_error_assert_size>
      Error in `tib_int()`:
      ! `fill` must have size 1, not size 2.
    Code
      (expect_error(tib_int("x", fill = "a")))
    Output
      <error/vctrs_error_incompatible_type>
      Error in `tib_int()`:
      ! Can't convert `fill` <character> to match type of `ptype_inner` <integer>.

---

    Code
      (expect_error(tib_chr("x", fill = 0L, ptype_inner = character())))
    Output
      <error/vctrs_error_incompatible_type>
      Error in `tib_chr()`:
      ! Can't convert `fill` <integer> to match type of `ptype_inner` <character>.

---

    Code
      (expect_error(tib_int("x", transform = integer())))
    Output
      <error/rlang_error>
      Error in `tib_int()`:
      ! Can't convert `transform`, an empty integer vector, to a function.

# tib_vector checks arguments

    Code
      (expect_error(tib_int_vec("x", input_form = "v")))
    Output
      <error/rlang_error>
      Error in `tib_int_vec()`:
      ! `input_form` must be one of "vector", "scalar_list", or "object", not "v".
      i Did you mean "vector"?

---

    Code
      (expect_error(tib_vector("x", ptype = model)))
    Output
      <error/vctrs_error_scalar_type>
      Error in `tib_vector()`:
      ! `ptype` must be a vector, not a <lm> object.

---

    Code
      (expect_error(tib_chr_vec("x", ptype_inner = model)))
    Output
      <error/vctrs_error_scalar_type>
      Error in `tib_chr_vec()`:
      ! `ptype_inner` must be a vector, not a <lm> object.

---

    Code
      (expect_error(tib_int_vec("x", values_to = NA)))
    Output
      <error/rlang_error>
      Error in `tib_int_vec()`:
      ! `values_to` must be a single string, not `NA`.
    Code
      (expect_error(tib_int_vec("x", values_to = 1)))
    Output
      <error/rlang_error>
      Error in `tib_int_vec()`:
      ! `values_to` must be a single string, not a number.
    Code
      (expect_error(tib_int_vec("x", values_to = c("a", "b"))))
    Output
      <error/rlang_error>
      Error in `tib_int_vec()`:
      ! `values_to` must be a single string, not a character vector.

---

    Code
      (expect_error(tib_int_vec("x", input_form = "scalar_list", values_to = "val",
        names_to = "name")))
    Output
      <error/rlang_error>
      Error in `tib_int_vec()`:
      ! `names_to` can't be used for `input_form = "scalar_list"`.
    Code
      (expect_error(tib_int_vec("x", input_form = "object", names_to = "name")))
    Output
      <error/rlang_error>
      Error in `tib_int_vec()`:
      ! `names_to` can only be used if `values_to` is not `NULL`.
    Code
      (expect_error(tib_int_vec("x", input_form = "object", values_to = "val",
        names_to = "val")))
    Output
      <error/rlang_error>
      Error in `tib_int_vec()`:
      ! `names_to` must be different from `values_to`.
    Code
      (expect_error(tib_int_vec("x", input_form = "object", values_to = "val",
        names_to = 1)))
    Output
      <error/rlang_error>
      Error in `tib_int_vec()`:
      ! `names_to` must be a single string, not a number.
    Code
      (expect_error(tib_int_vec("x", input_form = "object", values_to = "val",
        names_to = c("a", "b"))))
    Output
      <error/rlang_error>
      Error in `tib_int_vec()`:
      ! `names_to` must be a single string, not a character vector.

# tib_df() checks arguments

    Code
      (expect_error(tib_df("x", .names_to = 1)))
    Output
      <error/rlang_error>
      Error in `tib_df()`:
      ! `.names_to` must be a single string, not a number.

