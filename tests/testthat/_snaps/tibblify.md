# names are checked

    Code
      (expect_error(tibblify(list(1, 2), spec)))
    Output
      <error/rlang_error>
      Error in `stop_names_is_null()`:
      ! Element at path <root> has `NULL` names.
    Code
      (expect_error(tibblify(list(x = 1, 2), spec)))
    Output
      <error/rlang_error>
      Error in `stop_empty_name()`:
      ! Element at path <root> has empty name at position 2.
    Code
      (expect_error(tibblify(list(1, x = 2), spec)))
    Output
      <error/rlang_error>
      Error in `stop_empty_name()`:
      ! Element at path <root> has empty name at position 1.
    Code
      (expect_error(tibblify(list(z = 1, y = 2, 3, a = 4), spec)))
    Output
      <error/rlang_error>
      Error in `stop_empty_name()`:
      ! Element at path <root> has empty name at position 3.
    Code
      (expect_error(tibblify(set_names(list(1, 2), c("x", NA)), spec)))
    Output
      <error/rlang_error>
      Error in `stop_empty_name()`:
      ! Element at path <root> has empty name at position 2.
    Code
      (expect_error(tibblify(list(x = 1, x = 2), spec)))
    Output
      <error/rlang_error>
      Error in `stop_duplicate_name()`:
      ! Element at path <root> has duplicate name "x".

# scalar column works

    Required element absent at path [[1]]$x.

---

    Required element absent at path [[1]]$x.

---

    Required element absent at path [[1]]$x.

---

    Required element absent at path [[1]]$x.

---

    Required element absent at path [[1]]$x.

---

    Element at path [[1]]$x must have size 1.

---

    Element at path [[1]]$x must have size 1.

---

    Element at path [[1]]$x must have size 1.

---

    Element at path [[1]]$x must have size 1.

---

    Element at path [[1]]$x must have size 1.

---

    Can't convert <character> to <logical>.

---

    Can't convert <character> to <integer>.

---

    Can't convert <character> to <double>.

---

    Can't convert <double> to <character>.

---

    Can't convert <double> to <datetime<local>>.

---

    Code
      (expect_error(tib(list(x = integer()), tib_int("x", required = FALSE))))
    Output
      <error/rlang_error>
      Error in `stop_scalar()`:
      ! Element at path [[1]]$x must have size 1.

# vector column works

    Required element absent at path [[1]]$x.

---

    Required element absent at path [[1]]$x.

---

    Can't convert <character> to <logical>.

# vector column respects vector_allows_empty_list

    Code
      (expect_error(tibblify(x, spec_df(tib_int_vec("x")))))
    Output
      <error/vctrs_error_incompatible_type>
      Error:
      ! Can't convert <list> to <integer>.

# vector column can parse scalar list

    Code
      (expect_error(tib(list(x = 1), spec)))
    Output
      <error/rlang_error>
      Error in `stop_vector_non_list_element()`:
      ! Element at path [[1]]$x must be a list for `input_form = "scalar_list"`
    Code
      (expect_error(tib(list(x = 1), spec_object)))
    Output
      <error/rlang_error>
      Error in `stop_vector_non_list_element()`:
      ! Element at path [[1]]$x must be a list for `input_form = "object"`

---

    Code
      (expect_error(tib(list(x = list(1, 1:2)), spec)))
    Output
      <error/rlang_error>
      Error in `stop_vector_wrong_size_element()`:
      ! Each element in list at path [[1]]$x must have size 1.
    Code
      (expect_error(tib(list(x = list(integer())), spec)))
    Output
      <error/rlang_error>
      Error in `stop_vector_wrong_size_element()`:
      ! Each element in list at path [[1]]$x must have size 1.

# vector column can parse object

    Code
      (expect_error(tib(list(x = list(1, 2)), spec)))
    Output
      <error/rlang_error>
      Error in `stop_object_vector_names_is_null()`:
      ! Element at path [[1]]$x has `NULL` names.
      i Element must be named for `tib_vector(input_form = "object")`.

# list column works

    Required element absent at path [[2]]$x.

# df column works

    Required element absent at path [[2]]$x.

# list of df column works

    Required element absent at path [[2]]$x.

