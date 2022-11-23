# can format tib_unspecified()

    Code
      tib_unspecified("a") %>% print()
    Output
      tib_unspecified("a")

# format for scalars works

    Code
      tib_chr("a") %>% print()
    Output
      tib_chr("a")

---

    Code
      tib_date("a") %>% print()
    Output
      tib_date("a")

---

    Code
      tib_dbl("a") %>% print()
    Output
      tib_dbl("a")

---

    Code
      tib_int("a") %>% print()
    Output
      tib_int("a")

---

    Code
      tib_lgl("a") %>% print()
    Output
      tib_lgl("a")

---

    Code
      tib_variant("a") %>% print()
    Output
      tib_variant("a")

---

    Code
      tib_int("a", fill = NA_integer_) %>% print()
    Output
      tib_int("a")

---

    Code
      tib_int("a", fill = 1) %>% print()
    Output
      tib_int("a", fill = 1L)

---

    Code
      tib_int("a", transform = as.integer) %>% print()
    Output
      tib_int("a", transform = .Primitive("as.integer"))

---

    Code
      tib_int("a", fill = NA_integer_, transform = as.integer) %>% print()
    Output
      tib_int("a", transform = .Primitive("as.integer"))

---

    Code
      tib_scalar("a", ptype = new_difftime(units = "mins")) %>% print()
    Output
      tib_scalar("a", ptype = vctrs::new_duration())

---

    Code
      tib_row("a", x = tib_int("x"), y = tib_dbl("y", fill = NA_real_), z = tib_chr(
        "z", fill = "abc")) %>% print()
    Output
      tib_row(
        "a",
        tib_int("x"),
        tib_dbl("y"),
        tib_chr("z", fill = "abc"),
      )

---

    Code
      tib_int(key = "x", ptype_inner = character(), fill = "a")
    Output
      tib_int(
        "x",
        fill = "a",
        ptype_inner = character(0),
      )

# format breaks long lines

    Code
      tib_row("path", a_long_name = tib_dbl("a looooooooooooooooooooong name", fill = 1)) %>%
        print(width = 60)
    Output
      tib_row(
        "path",
        a_long_name = tib_dbl(
          "a looooooooooooooooooooong name",
          fill = 1,
        ),
      )

---

    Code
      tib_row("path", a_long_name = tib_dbl("a looooooooooooooooooooong name", fill = 1)) %>%
        print(width = 69)
    Output
      tib_row(
        "path",
        a_long_name = tib_dbl("a looooooooooooooooooooong name", fill = 1),
      )

# format for tib_vector works

    Code
      tib_chr_vec("a") %>% print()
    Output
      tib_chr_vec("a")

---

    Code
      tib_vector("a", ptype = vctrs::new_duration()) %>% print()
    Output
      tib_vector("a", ptype = vctrs::new_duration())

---

    Code
      tib_vector("a", ptype = vctrs::new_duration(), input_form = "object",
      values_to = "vals", names_to = "names") %>% print()
    Output
      tib_vector(
        "a",
        ptype = vctrs::new_duration(),
        input_form = "object",
        values_to = "vals",
        names_to = "names",
      )

---

    Code
      tib_int_vec("a", fill = 1:2) %>% print()
    Output
      tib_int_vec("a", fill = 1:2)

---

    Code
      tib_int_vec(key = "x", ptype_inner = character(), fill = 1:2)
    Output
      tib_int_vec(
        "x",
        fill = 1:2,
        ptype_inner = character(0),
      )

---

    Code
      tib_lgl_vec("lgl")
    Output
      tib_lgl_vec("lgl")
    Code
      tib_int_vec("int")
    Output
      tib_int_vec("int")
    Code
      tib_dbl_vec("dbl")
    Output
      tib_dbl_vec("dbl")
    Code
      tib_chr_vec("chr")
    Output
      tib_chr_vec("chr")
    Code
      tib_date_vec("date")
    Output
      tib_date_vec("date")

# format for tib_chr_date works

    Code
      tib_chr_date("a")
    Output
      tib_chr_date("a")
    Code
      tib_chr_date("a", required = FALSE, fill = "2022-01-01", format = "%Y")
    Output
      tib_chr_date(
        "a",
        required = FALSE,
        fill = "2022-01-01",
        format = "%Y",
      )

---

    Code
      tib_chr_date_vec("a")
    Output
      tib_chr_date_vec("a")
    Code
      tib_chr_date_vec("a", required = FALSE, fill = as.Date("2022-01-01"), format = "%Y")
    Output
      tib_chr_date_vec(
        "a",
        required = FALSE,
        fill = as.Date("2022-01-01"),
        format = "%Y",
      )

# format for tib_row works

    Code
      tib_row("formats", text = tib_chr("text", fill = NA_character_)) %>% print()
    Output
      tib_row(
        "formats",
        tib_chr("text"),
      )

---

    Code
      tib_row("formats", text = tib_chr("text"), .required = FALSE) %>% print()
    Output
      tib_row(
        "formats",
        .required = FALSE,
        tib_chr("text"),
      )

---

    Code
      tib_row("basic_information", labels = tib_row("labels", name = tib_chr("name"),
      entity_type = tib_chr("entity_type"), catno = tib_chr("catno"), resource_url = tib_chr(
        "resource_url"), id = tib_int("id"), entity_type_name = tib_chr(
        "entity_type_name")), year = tib_int("year"), master_url = tib_chr(
        "master_url", fill = NA), artists = tib_df("artists", join = tib_chr("join"),
      name = tib_chr("name"), anv = tib_chr("anv"), tracks = tib_chr("tracks"), role = tib_chr(
        "role"), resource_url = tib_chr("resource_url"), id = tib_int("id")), id = tib_int(
        "id"), thumb = tib_chr("thumb"), title = tib_chr("title"), formats = tib_df(
        "formats", descriptions = tib_chr_vec("descriptions", fill = NULL), text = tib_chr(
          "text", fill = NA), name = tib_chr("name"), qty = tib_chr("qty")),
      cover_image = tib_chr("cover_image"), resource_url = tib_chr("resource_url"),
      master_id = tib_int("master_id")) %>% print()
    Output
      tib_row(
        "basic_information",
        tib_row(
          "labels",
          tib_chr("name"),
          tib_chr("entity_type"),
          tib_chr("catno"),
          tib_chr("resource_url"),
          tib_int("id"),
          tib_chr("entity_type_name"),
        ),
        tib_int("year"),
        tib_chr("master_url"),
        tib_df(
          "artists",
          tib_chr("join"),
          tib_chr("name"),
          tib_chr("anv"),
          tib_chr("tracks"),
          tib_chr("role"),
          tib_chr("resource_url"),
          tib_int("id"),
        ),
        tib_int("id"),
        tib_chr("thumb"),
        tib_chr("title"),
        tib_df(
          "formats",
          tib_chr_vec("descriptions"),
          tib_chr("text"),
          tib_chr("name"),
          tib_chr("qty"),
        ),
        tib_chr("cover_image"),
        tib_chr("resource_url"),
        tib_int("master_id"),
      )

# format for tib_variant works

    Code
      tib_variant("a")
    Output
      tib_variant("a")

---

    Code
      tib_variant("a", fill = tibble(a = 1:2))
    Output
      tib_variant(
        "a",
        fill = c("structure(list(a = 1:2), class = c(\"tbl_df\", \"tbl\", \"data.frame\"", "), row.names = c(NA, -2L))"),
      )

---

    Code
      tib_variant("a", elt_transform = as.character)
    Output
      tib_variant("a", elt_transform = .Primitive("as.character"))

# format for tib_df works

    Code
      tib_df("formats", text = tib_chr("text", fill = NA_character_)) %>% print()
    Output
      tib_df(
        "formats",
        tib_chr("text"),
      )

---

    Code
      tib_df("formats", text = tib_chr("text"), .required = FALSE) %>% print()
    Output
      tib_df(
        "formats",
        .required = FALSE,
        tib_chr("text"),
      )

---

    Code
      tib_df("formats", .names_to = "nms", text = tib_chr("text")) %>% print()
    Output
      tib_df(
        "formats",
        .names_to = "nms",
        tib_chr("text"),
      )

# format for tib_recursive works

    Code
      tib_recursive("data", .children = "children", tib_int("id"), tib_chr("name"), ) %>%
        print()
    Output
      tib_recursive(
        "data",
        .children = "children",
        tib_int("id"),
        tib_chr("name"),
      )

---

    Code
      tib_recursive("data", .children = "children", tib_int("id"), tib_chr("name"),
      .required = FALSE) %>% print()
    Output
      tib_recursive(
        "data",
        .children = "children",
        .required = FALSE,
        tib_int("id"),
        tib_chr("name"),
      )

# prints non-canonical names

    Code
      tspec_df(b = tib_int("a")) %>% format()
    Output
      [1] "tspec_df(\n  b = tib_int(\"a\"),\n)"
    Code
      tspec_df(b = tib_int(c("a", "b"))) %>% format()
    Output
      [1] "tspec_df(\n  b = tib_int(c(\"a\", \"b\")),\n)"

# can force to print canonical names

    Code
      format(tspec_df(a = tib_int("a"), b = tib_df("b", x = tib_int("x"))))
    Output
      [1] "tspec_df(\n  a = tib_int(\"a\"),\n  b = tib_df(\n    \"b\",\n    x = tib_int(\"x\"),\n  ),\n)"

# special ptypes correctly formatted

    Code
      tib_scalar("a", ptype = character(), ptype_inner = Sys.Date()) %>% format()
    Output
      [1] "tib_chr(\"a\", ptype_inner = vctrs::new_date())"
    Code
      tib_scalar("a", ptype = character(), ptype_inner = Sys.time()) %>% format()
    Output
      [1] "tib_chr(\"a\", ptype_inner = vctrs::new_datetime(tzone = \"\"))"

# correctly print results of tspec_object()

    Code
      tibblify(list(a = 1L), tspec_object(tib_int("a"))) %>% print()
    Output
      $a
      [1] 1
      

