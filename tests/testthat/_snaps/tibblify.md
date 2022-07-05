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

    Cannot `tibblify()` field [[1]]$x
    Caused by error:
    ! Can't convert <character> to <logical>.

---

    Cannot `tibblify()` field [[1]]$x
    Caused by error:
    ! Can't convert <character> to <integer>.

---

    Cannot `tibblify()` field [[1]]$x
    Caused by error:
    ! Can't convert <character> to <double>.

---

    Cannot `tibblify()` field [[1]]$x
    Caused by error:
    ! Can't convert <double> to <character>.

---

    Cannot `tibblify()` field [[1]]$x
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

    Required element absent at path [[1]]$x.

---

    Required element absent at path [[1]]$x.

---

    Cannot `tibblify()` field [[1]]$x
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

    Required element absent at path [[2]]$x.

# df column works

    Required element absent at path [[2]]$x.

# list of df column works

    Required element absent at path [[2]]$x.

