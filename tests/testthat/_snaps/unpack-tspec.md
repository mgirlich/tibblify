# only unpack field in `fields`

    Code
      (expect_error(unpack_tspec(spec, fields = "not-there")))
    Output
      <error/rlang_error>
      Error in `check_unpack_cols()`:
      ! Can't unpack fields that don't exist.
      Field not-there doesn't exist.
    Code
      (expect_error(unpack_tspec(spec, fields = c("not-there", "also-not-there"))))
    Output
      <error/rlang_error>
      Error in `check_unpack_cols()`:
      ! Can't unpack fields that don't exist.
      Fields not-there and also-not-there don't exist.

# names are repaired

    Code
      (expect_error(unpack_tspec(spec, names_repair = "minimal")))
    Output
      <error/rlang_error>
      Error in `unpack_tspec()`:
      ! `names_repair` must be one of "unique", "universal", "check_unique", "unique_quiet", or "universal_quiet", not "minimal".
    Code
      (expect_error(unpack_tspec(spec, names_repair = "check_unique")))
    Output
      <error/rlang_error>
      Error in `unpack_tspec()`:
      ! In field y.
      Caused by error:
      ! Names must be unique.
      x These names are duplicated:
        * "b" at locations 1 and 2.

