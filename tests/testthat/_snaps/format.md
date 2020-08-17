# format for vectors works

    lcol_chr("a")

---

    lcol_dat("a")

---

    lcol_dbl("a")

---

    lcol_dtt("a")

---

    lcol_guess("a", .default = NULL)

---

    lcol_lgl("a")

---

    lcol_lst("a")

---

    lcol_skip("a", .parser = .parser)

---

    lcol_int("a")

---

    lcol_int("a", .default = NA)

---

    lcol_int("a", .parser = as.integer)

---

    lcol_int(
      "a",
      .parser = as.integer,
      .default = NA
    )

# format breaks long lines

    lcols(
      just_a_very_long_name = lcol_dbl(
        list("this", "is", "just_a_very_long_name"),
        .parser = ~and_a_long_function_name(.x)
      )
    )

# format for lst_flat works

    lcol_lst_flat("a", .ptype = character(0))

# format for lcol_df works

    lcol_df(
      "formats",
      text = lcol_chr("text", .default = NA)
    )

---

    lcol_df(
      "basic_information",
      labels = lcol_df(
        "labels",
        name = lcol_chr("name"),
        entity_type = lcol_chr("entity_type"),
        catno = lcol_chr("catno"),
        resource_url = lcol_chr("resource_url"),
        id = lcol_int("id"),
        entity_type_name = lcol_chr("entity_type_name")
      ),
      year = lcol_int("year"),
      master_url = lcol_chr("master_url", .default = NA),
      artists = lcol_df_lst(
        "artists",
        join = lcol_chr("join"),
        name = lcol_chr("name"),
        anv = lcol_chr("anv"),
        tracks = lcol_chr("tracks"),
        role = lcol_chr("role"),
        resource_url = lcol_chr("resource_url"),
        id = lcol_int("id")
      ),
      id = lcol_int("id"),
      thumb = lcol_chr("thumb"),
      title = lcol_chr("title"),
      formats = lcol_df_lst(
        "formats",
        descriptions = lcol_lst_flat(
          "descriptions",
          .ptype = character(0),
          .parser = ~vec_c(!!!.x, .ptype = character()),
          .default = NULL
        ),
        text = lcol_chr("text", .default = NA),
        name = lcol_chr("name"),
        qty = lcol_chr("qty")
      ),
      cover_image = lcol_chr("cover_image"),
      resource_url = lcol_chr("resource_url"),
      master_id = lcol_int("master_id")
    )

# format lcols works

    lcols(
      instance_id = lcol_int("instance_id"),
      date_added = lcol_chr("date_added")
    )

---

    lcols(
      instance_id = lcol_int("instance_id"),
      date_added = lcol_chr("date_added"),
      .default = lcol_chr(zap())
    )

---

    lcols(
      instance_id = lcol_int("instance_id"),
      date_added = lcol_chr("date_added"),
      basic_information = lcol_df(
        "basic_information",
        labels = lcol_df_lst(
          "labels",
          name = lcol_chr("name"),
          entity_type = lcol_chr("entity_type"),
          catno = lcol_chr("catno"),
          resource_url = lcol_chr("resource_url"),
          id = lcol_int("id"),
          entity_type_name = lcol_chr("entity_type_name")
        ),
        year = lcol_int("year"),
        master_url = lcol_chr("master_url", .default = NA),
        artists = lcol_df_lst(
          "artists",
          join = lcol_chr("join"),
          name = lcol_chr("name"),
          anv = lcol_chr("anv"),
          tracks = lcol_chr("tracks"),
          role = lcol_chr("role"),
          resource_url = lcol_chr("resource_url"),
          id = lcol_int("id")
        ),
        id = lcol_int("id"),
        thumb = lcol_chr("thumb"),
        title = lcol_chr("title"),
        formats = lcol_df_lst(
          "formats",
          descriptions = lcol_lst_flat(
            "descriptions",
            .ptype = character(0),
            .parser = ~vec_c(!!!.x, .ptype = character()),
            .default = NULL
          ),
          text = lcol_chr("text", .default = NA),
          name = lcol_chr("name"),
          qty = lcol_chr("qty")
        ),
        cover_image = lcol_chr("cover_image"),
        resource_url = lcol_chr("resource_url"),
        master_id = lcol_int("master_id")
      ),
      id = lcol_int("id"),
      rating = lcol_int("rating")
    )

