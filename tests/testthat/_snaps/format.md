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
      tib_vector("a", ptype = Sys.Date()) %>% print()
    Output
      tib_vector("a", ptype = vctrs::new_date())

---

    Code
      tib_vector("a", ptype = Sys.Date(), input_form = "object", values_to = "vals",
      names_to = "names") %>% print()
    Output
      tib_vector(
        "a",
        ptype = vctrs::new_date(),
        input_form = "object",
        values_to = "vals",
        names_to = "names",
      )

---

    Code
      tib_int_vec("a", fill = 1:2) %>% print()
    Output
      tib_int_vec("a", fill = 1:2)

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

# can force to print canonical names

    Code
      format(spec_df(a = tib_int("a"), b = tib_df("b", x = tib_int("x"))))
    Output
      [1] "spec_df(\n  a = tib_int(\"a\"),\n  b = tib_df(\n    \"b\",\n    x = tib_int(\"x\"),\n  ),\n)"

