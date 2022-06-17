# cannot combine different types of spec

    Code
      (expect_error(spec_combine(df_spec, row_spec)))
    Output
      <error/rlang_error>
      Error in `spec_combine()`:
      ! Can't combine specs `..1` <df> and `..2` <row>
    Code
      (expect_error(spec_combine(df_spec, obj_spec)))
    Output
      <error/rlang_error>
      Error in `spec_combine()`:
      ! Can't combine specs `..1` <df> and `..2` <object>
    Code
      (expect_error(spec_combine(row_spec, obj_spec)))
    Output
      <error/rlang_error>
      Error in `spec_combine()`:
      ! Can't combine specs `..1` <row> and `..2` <object>

# can combine type

    Code
      (expect_error(spec_combine(spec_row, spec_scalar)))
    Output
      <error/rlang_error>
      Error in `spec_combine()`:
      ! Can't combine tibs `..1` <row> and `..2` <scalar>
    Code
      (expect_error(spec_combine(spec_row, spec_vec)))
    Output
      <error/rlang_error>
      Error in `spec_combine()`:
      ! Can't combine tibs `..1` <row> and `..2` <vector>
    Code
      (expect_error(spec_combine(spec_row, spec_df)))
    Output
      <error/rlang_error>
      Error in `spec_combine()`:
      ! Can't combine tibs `..1` <row> and `..2` <df>
    Code
      (expect_error(spec_combine(spec_df, spec_scalar)))
    Output
      <error/rlang_error>
      Error in `spec_combine()`:
      ! Can't combine tibs `..1` <df> and `..2` <scalar>
    Code
      (expect_error(spec_combine(spec_df, spec_vec)))
    Output
      <error/rlang_error>
      Error in `spec_combine()`:
      ! Can't combine tibs `..1` <df> and `..2` <vector>

# can combine ptype

    Code
      (expect_error(spec_combine(spec_int, spec_chr)))
    Output
      <error/rlang_error>
      Error in `spec_combine()`:
      ! Can't combine tibs with ptype ..1 <integer> and ..2 <character>.

# can't combine different defaults

    Code
      (expect_error(spec_combine(spec_no_default, spec_default1)))
    Output
      <error/rlang_error>
      Error in `spec_combine()`:
      ! Can't combine default values `..1` <NA_integer_> and `..2` <1L>
    Code
      (expect_error(spec_combine(spec_default1, spec_default2)))
    Output
      <error/rlang_error>
      Error in `spec_combine()`:
      ! Can't combine default values `..1` <1L> and `..2` <2L>

# can't combine different transforms

    Code
      (expect_error(spec_combine(spec_no_f, spec_f1)))
    Output
      <error/rlang_error>
      Error in `spec_combine()`:
      ! Cannot combine different transforms
    Code
      (expect_error(spec_combine(spec_f1, spec_f2)))
    Output
      <error/rlang_error>
      Error in `spec_combine()`:
      ! Cannot combine different transforms

