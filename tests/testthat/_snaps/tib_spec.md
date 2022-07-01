# errors on invalid names

    Names must be unique.
    x These names are duplicated:
      * "x" at locations 1 and 2.

# errors if element is not a tib collector

    Every element in `...` must be a tib collector.

---

    Every element in `...` must be a tib collector.

# can infer name from key

    Can only infer name if key is a string

---

    Names must be unique.
    x These names are duplicated:
      * "y" at locations 1 and 2.

# can nest specifications

    Names must be unique.
    x These names are duplicated:
      * "a" at locations 1 and 3.
      * "b" at locations 2 and 4.

# errors on invalid `.names_to`

    Code
      (expect_error(spec_df(.names_to = NA_character_)))
    Output
      <error/rlang_error>
      Error in `spec_df()`:
      ! `.names_to` must be a single string or `NULL`, not a character `NA`.
    Code
      (expect_error(spec_df(.names_to = 1)))
    Output
      <error/rlang_error>
      Error in `spec_df()`:
      ! `.names_to` must be a single string or `NULL`, not a number.

# errors if `.names_to` column name is not unique

    The column name of `.names_to` is already specified in `...`.

# errors on invalid key

    Code
      (expect_error(tib_int(1L)))
    Output
      <error/rlang_error>
      Error in `check_key()`:
      ! `key` must be a character vector, not an integer.
    Code
      (expect_error(tib_int(c("x", NA))))
    Output
      <error/rlang_error>
      Error in `tib_int()`:
      ! Element 2 of `key` is "NA".
      i No element of `key` can be "NA".

# errors on invalid required

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

# tib_vector checks arguments

    Code
      (expect_error(tib_int_vec("x", input_form = "v")))
    Output
      <error/rlang_error>
      Error in `tib_int_vec()`:
      ! `input_form` must be one of "vector", "scalar_list", or "object", not "v".
      i Did you mean "vector"?
    Code
      (expect_error(tib_int_vec("x", values_to = 1)))
    Output
      <error/vctrs_error_incompatible_type>
      Error in `tib_int_vec()`:
      ! Can't convert `values_to` <double> to <character>.
    Code
      (expect_error(tib_int_vec("x", values_to = c("a", "b"))))
    Output
      <error/vctrs_error_assert_size>
      Error in `tib_int_vec()`:
      ! `values_to` must have size 1, not size 2.
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
      <error/vctrs_error_incompatible_type>
      Error in `tib_int_vec()`:
      ! Can't convert `names_to` <double> to <character>.
    Code
      (expect_error(tib_int_vec("x", input_form = "object", values_to = "val",
        names_to = c("a", "b"))))
    Output
      <error/vctrs_error_assert_size>
      Error in `tib_int_vec()`:
      ! `names_to` must have size 1, not size 2.

