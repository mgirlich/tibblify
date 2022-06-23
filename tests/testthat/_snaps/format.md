# can format tib_unspecified()

    Code
      tib_unspecified("a") %>% print()
    Output
      tib_unspecified("a")

# format for vectors works

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
      tib_int("a", default = NA_integer_) %>% print()
    Output
      tib_int("a")

---

    Code
      tib_int("a", default = 1) %>% print()
    Output
      tib_int("a", default = 1L)

---

    Code
      tib_int("a", transform = as.integer) %>% print()
    Output
      tib_int("a", transform = .Primitive("as.integer"))

---

    Code
      tib_int("a", default = NA_integer_, transform = as.integer) %>% print()
    Output
      tib_int("a", transform = .Primitive("as.integer"))

---

    Code
      tib_scalar("a", ptype = new_difftime(units = "mins")) %>% print()
    Output
      tib_scalar("a", ptype = vctrs::new_duration())

---

    Code
      tib_row("a", x = tib_int("x"), y = tib_dbl("y", default = NA_real_), z = tib_chr(
        "z", default = "abc")) %>% print()
    Output
      tib_row(
        "a",
        x = tib_int("x"),
        y = tib_dbl("y"),
        z = tib_chr("z", default = "abc"),
      )

# format breaks long lines

    Code
      tib_row("path", a_long_name = tib_dbl("a looooooooooooooooooooong name",
        default = 1)) %>% print(width = 70)
    Output
      tib_row(
        "path",
        a_long_name = tib_dbl("a looooooooooooooooooooong name", default = 1),
      )

---

    Code
      tib_row("path", a_long_name = tib_dbl("a looooooooooooooooooooong name",
        default = 1)) %>% print(width = 69)
    Output
      tib_row(
        "path",
        a_long_name = tib_dbl(
          "a looooooooooooooooooooong name",
          default = 1,
        ),
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

# format for tib_row works

    Code
      tib_row("formats", text = tib_chr("text", default = NA_character_)) %>% print()
    Output
      tib_row(
        "formats",
        text = tib_chr("text"),
      )

---

    Code
      tib_row("formats", text = tib_chr("text"), .required = FALSE) %>% print()
    Output
      tib_row(
        "formats",
        .required = FALSE,
        text = tib_chr("text"),
      )

---

    Code
      tib_row("basic_information", labels = tib_row("labels", name = tib_chr("name"),
      entity_type = tib_chr("entity_type"), catno = tib_chr("catno"), resource_url = tib_chr(
        "resource_url"), id = tib_int("id"), entity_type_name = tib_chr(
        "entity_type_name")), year = tib_int("year"), master_url = tib_chr(
        "master_url", default = NA), artists = tib_df("artists", join = tib_chr(
        "join"), name = tib_chr("name"), anv = tib_chr("anv"), tracks = tib_chr(
        "tracks"), role = tib_chr("role"), resource_url = tib_chr("resource_url"),
      id = tib_int("id")), id = tib_int("id"), thumb = tib_chr("thumb"), title = tib_chr(
        "title"), formats = tib_df("formats", descriptions = tib_chr_vec(
        "descriptions", default = NULL), text = tib_chr("text", default = NA), name = tib_chr(
        "name"), qty = tib_chr("qty")), cover_image = tib_chr("cover_image"),
      resource_url = tib_chr("resource_url"), master_id = tib_int("master_id")) %>%
        print()
    Output
      tib_row(
        "basic_information",
        labels = tib_row(
          "labels",
          name = tib_chr("name"),
          entity_type = tib_chr("entity_type"),
          catno = tib_chr("catno"),
          resource_url = tib_chr("resource_url"),
          id = tib_int("id"),
          entity_type_name = tib_chr("entity_type_name"),
        ),
        year = tib_int("year"),
        master_url = tib_chr("master_url"),
        artists = tib_df(
          "artists",
          join = tib_chr("join"),
          name = tib_chr("name"),
          anv = tib_chr("anv"),
          tracks = tib_chr("tracks"),
          role = tib_chr("role"),
          resource_url = tib_chr("resource_url"),
          id = tib_int("id"),
        ),
        id = tib_int("id"),
        thumb = tib_chr("thumb"),
        title = tib_chr("title"),
        formats = tib_df(
          "formats",
          descriptions = tib_chr_vec("descriptions"),
          text = tib_chr("text"),
          name = tib_chr("name"),
          qty = tib_chr("qty"),
        ),
        cover_image = tib_chr("cover_image"),
        resource_url = tib_chr("resource_url"),
        master_id = tib_int("master_id"),
      )

# format for tib_df works

    Code
      tib_df("formats", text = tib_chr("text", default = NA_character_)) %>% print()
    Output
      tib_df(
        "formats",
        text = tib_chr("text"),
      )

---

    Code
      tib_df("formats", text = tib_chr("text"), .required = FALSE) %>% print()
    Output
      tib_df(
        "formats",
        .required = FALSE,
        text = tib_chr("text"),
      )

---

    Code
      tib_df("formats", .names_to = "nms", text = tib_chr("text")) %>% print()
    Output
      tib_df(
        "formats",
        .names_to = "nms",
        text = tib_chr("text"),
      )

