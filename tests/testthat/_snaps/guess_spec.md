# can guess spec for discog

    Code
      guess_spec(discog) %>% print()
    Output
      spec_df(
        instance_id = tib_int("instance_id"),
        date_added = tib_chr("date_added"),
        basic_information = tib_row(
          "basic_information",
          labels = tib_df(
            "labels",
            name = tib_chr("name"),
            entity_type = tib_chr("entity_type"),
            catno = tib_chr("catno"),
            resource_url = tib_chr("resource_url"),
            id = tib_int("id"),
            entity_type_name = tib_chr("entity_type_name")
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
            id = tib_int("id")
          ),
          id = tib_int("id"),
          thumb = tib_chr("thumb"),
          title = tib_chr("title"),
          formats = tib_df(
            "formats",
            descriptions = tib_list("descriptions", required = FALSE),
            text = tib_chr("text", required = FALSE),
            name = tib_chr("name"),
            qty = tib_chr("qty")
          ),
          cover_image = tib_chr("cover_image"),
          resource_url = tib_chr("resource_url"),
          master_id = tib_int("master_id")
        ),
        id = tib_int("id"),
        rating = tib_int("rating")
      )

# can guess spec for gh_users

    Code
      guess_spec(gh_users) %>% print()
    Output
      spec_df(
        login = tib_chr("login"),
        id = tib_int("id"),
        avatar_url = tib_chr("avatar_url"),
        gravatar_id = tib_chr("gravatar_id"),
        url = tib_chr("url"),
        html_url = tib_chr("html_url"),
        followers_url = tib_chr("followers_url"),
        following_url = tib_chr("following_url"),
        gists_url = tib_chr("gists_url"),
        starred_url = tib_chr("starred_url"),
        subscriptions_url = tib_chr("subscriptions_url"),
        organizations_url = tib_chr("organizations_url"),
        repos_url = tib_chr("repos_url"),
        events_url = tib_chr("events_url"),
        received_events_url = tib_chr("received_events_url"),
        type = tib_chr("type"),
        site_admin = tib_lgl("site_admin"),
        name = tib_chr("name"),
        company = tib_chr("company"),
        blog = tib_chr("blog"),
        location = tib_chr("location"),
        email = tib_chr("email"),
        hireable = tib_lgl("hireable"),
        bio = tib_chr("bio"),
        public_repos = tib_int("public_repos"),
        public_gists = tib_int("public_gists"),
        followers = tib_int("followers"),
        following = tib_int("following"),
        created_at = tib_chr("created_at"),
        updated_at = tib_chr("updated_at")
      )

