# errors on invalid names

    Names must be unique.
    x These names are duplicated:
      * "x" at locations 1 and 2.

# can infer name from key

    Can only infer name if key is a string

---

    Can only infer name if key is a string

---

    Names must be unique.
    x These names are duplicated:
      * "y" at locations 1 and 2.

# errors if `.names_to` column name is not unique

    The column name of `.names_to` is already specified in `...`

# errors if element is not a tib collector

    Every element in `...` must be a tib collector.

---

    Every element in `...` must be a tib collector.

# errors on invalid key

    `key` must be a character, integer or a list.

---

    Every element of `key` must be a scalar character or scalar integer.

---

    Every element of `key` must be a scalar character or scalar integer.

---

    Every element of `key` must be a scalar character or scalar integer.

# can nest specifications

    Names must be unique.
    x These names are duplicated:
      * "a" at locations 1 and 3.
      * "b" at locations 2 and 4.

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
      (expect_error(tib_int_vec("x", values_to = "val", names_to = "name")))
    Output
      <error/rlang_error>
      Error in `tib_int_vec()`:
      ! `names_to` can only be used if `input_form` is "object".
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

