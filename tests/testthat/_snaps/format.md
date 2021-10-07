# format for vectors works

    Code
      lcol_chr("a") %>% print()
    Output
      lcol_chr("a")

---

    Code
      lcol_dat("a") %>% print()
    Output
      lcol_dat("a")

---

    Code
      lcol_dbl("a") %>% print()
    Output
      lcol_dbl("a")

---

    Code
      lcol_dtt("a") %>% print()
    Output
      lcol_dtt("a")

---

    Code
      lcol_guess("a") %>% print()
    Output
      lcol_guess("a", .default = NULL)

---

    Code
      lcol_int("a") %>% print()
    Output
      lcol_int("a")

---

    Code
      lcol_lgl("a") %>% print()
    Output
      lcol_lgl("a")

---

    Code
      lcol_lst("a") %>% print()
    Output
      lcol_lst("a")

---

    Code
      lcol_skip("a") %>% print()
    Output
      lcol_skip("a", .parser = .parser)

---

    Code
      lcol_int("a", .default = NA_integer_) %>% print()
    Output
      lcol_int("a", .default = NA_integer_)

---

    Code
      lcol_int("a", .parser = as.integer) %>% print()
    Output
      lcol_int("a", .parser = as.integer)

---

    Code
      lcol_int("a", .default = NA_integer_, .parser = as.integer) %>% print()
    Output
      lcol_int(
        "a",
        .parser = as.integer,
        .default = NA_integer_
      )

---

    Code
      lcol_vec("a", ptype = new_difftime(units = "mins")) %>% print()
    Output
      lcol_vec("a", ptype = structure(numeric(0), class = "difftime", units = "mins"))

# format breaks long lines

    Code
      lcol_df("path", a_long_name = lcol_dbl("a loooooooooooooooooooog name",
        .default = 1)) %>% print(width = 70)
    Output
      lcol_df(
        "path",
        a_long_name = lcol_dbl("a loooooooooooooooooooog name", .default = 1)
      )

---

    Code
      print(x, width = width)
    Output
      lcol_df(
        "path",
        a_long_name = lcol_dbl(
          "a loooooooooooooooooooog name",
          .default = 1
        )
      )NULL

# format for lst_of works

    Code
      lcol_lst_of("a", .ptype = character()) %>% print()
    Output
      lcol_lst_of("a", .ptype = character(0))

# format for lcol_df works

    Code
      lcol_df("formats", text = lcol_chr("text", .default = NA_character_)) %>% print()
    Output
      lcol_df(
        "formats",
        text = lcol_chr("text", .default = NA_character_)
      )

---

    Code
      lcol_df("basic_information", labels = lcol_df("labels", name = lcol_chr("name"),
      entity_type = lcol_chr("entity_type"), catno = lcol_chr("catno"), resource_url = lcol_chr(
        "resource_url"), id = lcol_int("id"), entity_type_name = lcol_chr(
        "entity_type_name")), year = lcol_int("year"), master_url = lcol_chr(
        "master_url", .default = NA), artists = lcol_df_lst("artists", join = lcol_chr(
        "join"), name = lcol_chr("name"), anv = lcol_chr("anv"), tracks = lcol_chr(
        "tracks"), role = lcol_chr("role"), resource_url = lcol_chr("resource_url"),
      id = lcol_int("id")), id = lcol_int("id"), thumb = lcol_chr("thumb"), title = lcol_chr(
        "title"), formats = lcol_df_lst("formats", descriptions = lcol_lst_of(
        "descriptions", .ptype = character(0), .default = NULL), text = lcol_chr(
        "text", .default = NA), name = lcol_chr("name"), qty = lcol_chr("qty")),
      cover_image = lcol_chr("cover_image"), resource_url = lcol_chr("resource_url"),
      master_id = lcol_int("master_id")) %>% print()
    Output
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
          descriptions = lcol_lst_of(
            "descriptions",
            .ptype = character(0),
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

    Code
      lcols(lcol_int("instance_id"), lcol_chr("date_added")) %>% print()
    Output
      lcols(
        instance_id = lcol_int("instance_id"),
        date_added = lcol_chr("date_added")
      )

---

    Code
      lcols(lcol_int("instance_id"), lcol_chr("date_added"), .default = lcol_chr(zap())) %>%
        print()
    Output
      lcols(
        instance_id = lcol_int("instance_id"),
        date_added = lcol_chr("date_added"),
        .default = lcol_chr(zap())
      )

---

    Code
      col_specs %>% print()
    Output
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
            descriptions = lcol_lst_of(
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

