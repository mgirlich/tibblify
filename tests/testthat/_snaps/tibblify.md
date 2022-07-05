# names are checked

    Code
      (expect_error(tibblify(list(1, 2), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path <root> has `NULL` names.
    Code
      (expect_error(tibblify(list(x = 1, 2), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path <root> has empty name at position 2.
    Code
      (expect_error(tibblify(list(1, x = 2), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path <root> has empty name at position 1.
    Code
      (expect_error(tibblify(list(z = 1, y = 2, 3, a = 4), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path <root> has empty name at position 3.
    Code
      (expect_error(tibblify(set_names(list(1, 2), c("x", NA)), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path <root> has empty name at position 2.
    Code
      (expect_error(tibblify(list(x = 1, x = 2), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path <root> has duplicate name "x".

# scalar column works

    Code
      (expect_error(tib(list(), tib_lgl("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Required element absent at path [[1]]$x.

---

    Code
      (expect_error(tib(list(), tib_int("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Required element absent at path [[1]]$x.

---

    Code
      (expect_error(tib(list(), tib_dbl("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Required element absent at path [[1]]$x.

---

    Code
      (expect_error(tib(list(), tib_chr("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Required element absent at path [[1]]$x.

---

    Code
      (expect_error(tib(list(), tib_scalar("x", dtt))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Required element absent at path [[1]]$x.

---

    Code
      (expect_error(tib(list(x = c(TRUE, TRUE)), tib_lgl("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path [[1]]$x must have size 1.

---

    Code
      (expect_error(tib(list(x = c(1, 1)), tib_int("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path [[1]]$x must have size 1.

---

    Code
      (expect_error(tib(list(x = c(1.5, 1.5)), tib_dbl("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path [[1]]$x must have size 1.

---

    Code
      (expect_error(tib(list(x = c("a", "a")), tib_chr("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path [[1]]$x must have size 1.

---

    Code
      (expect_error(tib(list(x = c(dtt, dtt)), tib_scalar("x", dtt))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path [[1]]$x must have size 1.

---

    Code
      (expect_error(tib(list(x = "a"), tib_lgl("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Cannot `tibblify()` field [[1]]$x
      Caused by error:
      ! Can't convert <character> to <logical>.

---

    Code
      (expect_error(tib(list(x = "a"), tib_int("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Cannot `tibblify()` field [[1]]$x
      Caused by error:
      ! Can't convert <character> to <integer>.

---

    Code
      (expect_error(tib(list(x = "a"), tib_dbl("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Cannot `tibblify()` field [[1]]$x
      Caused by error:
      ! Can't convert <character> to <double>.

---

    Code
      (expect_error(tib(list(x = 1), tib_chr("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Cannot `tibblify()` field [[1]]$x
      Caused by error:
      ! Can't convert <double> to <character>.

---

    Code
      (expect_error(tib(list(x = 1), tib_scalar("x", dtt))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Cannot `tibblify()` field [[1]]$x
      Caused by error:
      ! Can't convert <double> to <datetime<local>>.

---

    Code
      (expect_error(tib(list(x = integer()), tib_int("x", required = FALSE))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path [[1]]$x must have size 1.

# vector column works

    Code
      (expect_error(tib(list(), tib_lgl_vec("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Required element absent at path [[1]]$x.

---

    Code
      (expect_error(tib(list(), tib_vector("x", dtt))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Required element absent at path [[1]]$x.

---

    Code
      (expect_error(tib(list(x = "a"), tib_lgl_vec("x"))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Cannot `tibblify()` field [[1]]$x
      Caused by error:
      ! Can't convert <character> to <logical>.

# vector column respects vector_allows_empty_list

    Code
      (expect_error(tibblify(x, spec_df(tib_int_vec("x")))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Cannot `tibblify()` field [[2]]$x
      Caused by error:
      ! Can't convert <list> to <integer>.

# vector column can parse scalar list

    Code
      (expect_error(tib(list(x = 1), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path [[1]]$x must be a list for `input_form = "scalar_list"`
    Code
      (expect_error(tib(list(x = 1), spec_object)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path [[1]]$x must be a list for `input_form = "object"`

---

    Code
      (expect_error(tib(list(x = list(1, 1:2)), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Each element in list at path [[1]]$x must have size 1.
    Code
      (expect_error(tib(list(x = list(integer())), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Each element in list at path [[1]]$x must have size 1.

---

    Code
      (expect_error(tib(list(x = list(1, "a")), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Cannot `tibblify()` field [[1]]$x
      Caused by error:
      ! Can't convert <character> to <integer>.

# vector column can parse object

    Code
      (expect_error(tib(list(x = list(1, 2)), spec)))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Element at path [[1]]$x has `NULL` names.
      i Element must be named for `tib_vector(input_form = "object")`.

# list column works

    Code
      (expect_error(tibblify(list(list(x = TRUE), list(zzz = 1)), spec_df(x = tib_variant(
        "x")))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Required element absent at path [[2]]$x.

# df column works

    Code
      (expect_error(tibblify(list(list(x = list(a = TRUE)), list()), spec_df(x = tib_row(
        "x", a = tib_lgl("a"))))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Required element absent at path [[2]]$x.

# list of df column works

    Code
      (expect_error(tibblify(list(list(x = list(list(a = TRUE), list(a = FALSE))),
      list()), spec_df(x = tib_df("x", a = tib_lgl("a"))))))
    Output
      <error/tibblify_error>
      Error in `tibblify()`:
      ! Required element absent at path [[2]]$x.

