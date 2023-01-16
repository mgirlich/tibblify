# cannot combine different types of spec

    Code
      (expect_error(tspec_combine(df_spec, row_spec)))
    Output
      <error/rlang_error>
      Error in `tspec_combine()`:
      ! Can't combine specs `..1` <df> and `..2` <row>
    Code
      (expect_error(tspec_combine(df_spec, obj_spec)))
    Output
      <error/rlang_error>
      Error in `tspec_combine()`:
      ! Can't combine specs `..1` <df> and `..2` <object>
    Code
      (expect_error(tspec_combine(row_spec, obj_spec)))
    Output
      <error/rlang_error>
      Error in `tspec_combine()`:
      ! Can't combine specs `..1` <row> and `..2` <object>

# cannot combine different keys

    Code
      (expect_error(tspec_combine(tspec_df(tib_int("a")), tspec_df(a = tib_int("b"))))
      )
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Cannot combine tibs of different keys a and b

# nice error when combining non-specs

    Code
      (expect_error(tspec_combine(df_spec, tib_int("a"))))
    Output
      <error/rlang_error>
      Error in `check_tspec_combine_dots()`:
      ! Every element of `...` must be a tibblify spec.
      x Element 2 has class <tib_scalar_integer>.

# can combine type

    Code
      (expect_error(tspec_combine(tspec_row, spec_scalar)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Can't combine tibs `..1` <row> and `..2` <scalar>
    Code
      (expect_error(tspec_combine(tspec_row, spec_vec)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Can't combine tibs `..1` <row> and `..2` <vector>
    Code
      (expect_error(tspec_combine(tspec_row, tspec_df)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Can't combine tibs `..1` <row> and `..2` <df>
    Code
      (expect_error(tspec_combine(tspec_df, spec_scalar)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Can't combine tibs `..1` <df> and `..2` <scalar>
    Code
      (expect_error(tspec_combine(tspec_df, spec_vec)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Can't combine tibs `..1` <df> and `..2` <vector>

# can combine ptype

    Code
      (expect_error(tspec_combine(spec_int, spec_chr)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Can't combine tibs with ptype ..1 <integer> and ..2 <character>.

# can't combine different defaults

    Code
      (expect_error(tspec_combine(spec_no_default, spec_default1)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Can't combine fill `..1` <NA_integer_> and `..2` <1L>
    Code
      (expect_error(tspec_combine(spec_default1, spec_default2)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Can't combine fill `..1` <1L> and `..2` <2L>

---

    Code
      (expect_error(tspec_combine(spec_no_default_vec, spec_default1_vec)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Cannot combine fill NULL and 1
    Code
      (expect_error(tspec_combine(spec_default1_vec, spec_default2_vec)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Cannot combine fill 1 and 2

# can't combine different transforms

    Code
      (expect_error(tspec_combine(spec_no_f, spec_f1)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Cannot combine different transforms
    Code
      (expect_error(tspec_combine(spec_f1, spec_f2)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Cannot combine different transforms

# can't combine different input forms

    Code
      (expect_error(tspec_combine(spec_vec, spec_vec_scalar)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Cannot combine input forms `..1` <vector> and `..2` <scalar_list>
    Code
      (expect_error(tspec_combine(spec_vec, spec_vec_object)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Cannot combine input forms `..1` <vector> and `..2` <object>
    Code
      (expect_error(tspec_combine(spec_vec_scalar, spec_vec_object)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Cannot combine input forms `..1` <scalar_list> and `..2` <object>
    Code
      (expect_error(tspec_combine(spec_scalar, spec_vec_object)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Cannot combine input form "object" with `tib_scalar()`.

# can't combine different names_to

    Code
      (expect_error(tspec_combine(spec1, spec2)))
    Output
      <error/rlang_error>
      Error in `tspec_combine()`:
      ! Cannot combine different `names_col`
    Code
      (expect_error(tspec_combine(spec1_df, spec2_df)))
    Output
      <error/purrr_error_indexed>
      Error in `map2()`:
      i In index: 1.
      i With name: a.
      Caused by error in `tspec_combine()`:
      ! Cannot combine different `names_col`

