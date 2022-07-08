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

---

    Code
      (expect_error(tibblify(list(1, 2), spec)))
    Output
      <error/rlang_error>
      Error in `stop_names_is_null()`:
      ! Element at path [[]] has `NULL` names.
    Code
      (expect_error(tibblify(list(x = 1, 2), spec)))
    Output
      <error/rlang_error>
      Error in `stop_empty_name()`:
      ! Element at path [[]] has empty name at position 2.
    Code
      (expect_error(tibblify(list(1, x = 2), spec)))
    Output
      <error/rlang_error>
      Error in `stop_empty_name()`:
      ! Element at path [[]] has empty name at position 1.
    Code
      (expect_error(tibblify(list(z = 1, y = 2, 3, a = 4), spec)))
    Output
      <error/rlang_error>
      Error in `stop_empty_name()`:
      ! Element at path [[]] has empty name at position 3.
    Code
      (expect_error(tibblify(set_names(list(1, 2), c("x", NA)), spec)))
    Output
      <error/rlang_error>
      Error in `stop_empty_name()`:
      ! Element at path [[]] has empty name at position 2.
    Code
      (expect_error(tibblify(list(x = 1, x = 2), spec)))
    Output
      <error/rlang_error>
      Error in `stop_duplicate_name()`:
      ! Element at path [[]] has duplicate name "x".

# scalar column works

    Code
      (expect_error(tib(list(), tib_lgl("x"))))
    Output
      <error/rlang_error>
      Error in `stop_required()`:
      ! Required element absent at path [[1]]$x.

---

    Code
      (expect_error(tib(list(), tib_scalar("x", dtt))))
    Output
      <error/rlang_error>
      Error in `stop_required()`:
      ! Required element absent at path [[1]]$x.

---

    Code
      (expect_error(tib(list(x = c(TRUE, TRUE)), tib_lgl("x"))))
    Output
      <error/rlang_error>
      Error in `stop_scalar()`:
      ! Element at path [[1]]$x must have size 1.

---

    Code
      (expect_error(tib(list(x = c(dtt, dtt)), tib_scalar("x", dtt))))
    Output
      <error/rlang_error>
      Error in `stop_scalar()`:
      ! Element at path [[1]]$x must have size 1.

---

    Code
      (expect_error(tib(list(x = "a"), tib_lgl("x"))))
    Output
      <error/vctrs_error_incompatible_type>
      Error:
      ! Can't convert <character> to <logical>.

---

    Code
      (expect_error(tib(list(x = 1), tib_scalar("x", dtt))))
    Output
      <error/vctrs_error_incompatible_type>
      Error:
      ! Can't convert <double> to <datetime<local>>.

---

    Code
      (expect_error(tib(list(x = integer()), tib_int("x", required = FALSE))))
    Output
      <error/rlang_error>
      Error in `stop_scalar()`:
      ! Element at path [[1]]$x must have size 1.

# vector column works

    Code
      (expect_error(tib(list(), tib_lgl_vec("x"))))
    Output
      <error/rlang_error>
      Error in `stop_required()`:
      ! Required element absent at path [[1]]$x.

---

    Code
      (expect_error(tib(list(), tib_vector("x", dtt))))
    Output
      <error/rlang_error>
      Error in `stop_required()`:
      ! Required element absent at path [[1]]$x.

---

    Code
      (expect_error(tib(list(x = "a"), tib_lgl_vec("x"))))
    Output
      <error/vctrs_error_incompatible_type>
      Error:
      ! Can't convert <character> to <logical>.

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

---

    Code
      (expect_error(tib(list(x = list(1, "a")), spec)))
    Output
      <error/vctrs_error_incompatible_type>
      Error:
      ! Can't convert <character> to <integer>.

# vector column can parse object

    Code
      (expect_error(tib(list(x = list(1, 2)), spec)))
    Output
      <error/rlang_error>
      Error in `stop_object_vector_names_is_null()`:
      ! Element at path [[1]]$x has `NULL` names.
      i Element must be named for `tib_vector(input_form = "object")`.

# list column works

    Code
      (expect_error(tibblify(list(list(x = TRUE), list(zzz = 1)), spec_df(x = tib_variant(
        "x")))))
    Output
      <error/rlang_error>
      Error in `stop_required()`:
      ! Required element absent at path [[2]]$x.

# df column works

    Code
      (expect_error(tibblify(list(list(x = list(a = TRUE)), list()), spec_df(x = tib_row(
        "x", a = tib_lgl("a"))))))
    Output
      <error/rlang_error>
      Error in `stop_required()`:
      ! Required element absent at path [[2]]$x.

# list of df column works

    Code
      (expect_error(tibblify(list(list(x = list(list(a = TRUE), list(a = FALSE))),
      list()), spec_df(x = tib_df("x", a = tib_lgl("a"))))))
    Output
      <error/rlang_error>
      Error in `stop_required()`:
      ! Required element absent at path [[2]]$x.

# colmajor works

    Code
      (expect_error(tib_cm(tib_row("x"), 1:3)))
    Output
      <error/rlang_error>
      Error in `stop_colmajor_non_list_element()`:
      ! Element at path [[]] must be a list.

---

    Code
      (expect_error(tibblify(list(x = 1:3), spec_cm(tib_int("x"), tib_int("y")))))
    Output
      <error/rlang_error>
      Error in `stop_required()`:
      ! Required element absent at path [[]]$y.

# colmajor checks size

    Code
      (expect_error(tib_cm(tib_int("x"), tib_int("y"), x = 1:2, y = 1:3)))
    Output
      <error/rlang_error>
      Error in `stop_colmajor_wrong_size_element()`:
      ! Field at path [[]]$y has size 3, not size 2.
      i For `input_form = "colmajor"` each field must have the same size.
    Code
      (expect_error(tib_cm(tib_int("x"), tib_row("y", tib_int("x")), x = 1:2, y = list(
        x = 1:3))))
    Output
      <error/rlang_error>
      Error in `stop_colmajor_wrong_size_element()`:
      ! Field at path [[]]$y$x has size 3, not size 2.
      i For `input_form = "colmajor"` each field must have the same size.
    Code
      (expect_error(tib_cm(tib_int("x"), tib_int_vec("y"), x = 1:2, y = list(1))))
    Output
      <error/rlang_error>
      Error in `stop_colmajor_wrong_size_element()`:
      ! Field at path [[]]$y has size 1, not size 2.
      i For `input_form = "colmajor"` each field must have the same size.

