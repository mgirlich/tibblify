# tibblify 0.2.0

* `tibblify()` gains the argument `names_to` to store the names of a recordlist
  in a column.
* Guessed spec uses `vctrs` namespace so that `vctrs` doesn't need to be loaded
  for the spec to work.
  
## Bugfixes
* The `.default` argument of `lcol_df()` and `lcol_df_lst()` is now printed.
  This bug caused some copy-pasted specs, for example after guessing, to not
  work correctly and complain about missing paths.

# tibblify 0.1.0

* First CRAN release.
