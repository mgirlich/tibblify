# errors on invalid names

    Names can't be empty.
    x Empty name found at location 1.

---

    Names can't be empty.
    x Empty name found at location 2.

---

    Names must be unique.
    x These names are duplicated:
      * "x" at locations 1 and 2.

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

