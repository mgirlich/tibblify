# checks input

    Code
      expect_error(guess_tspec("a"))

---

    Code
      (expect_error(guess_tspec_list(list())))
    Output
      <error/rlang_error>
      Error in `guess_tspec_list()`:
      ! `list()` must not be empty.

---

    Code
      (expect_error(guess_tspec_list(list(a = 1, 1))))
    Output
      <error/rlang_error>
      Error in `guess_tspec_list()`:
      ! `list(a = 1, 1)` is neither an object nor a list of objects.
      An object
      v is a list,
      x is fully named,
      v and has unique names.
      A list of objects is
      x a data frame or
      v a list and
      x each element is `NULL` or an object.
    Code
      (expect_error(guess_tspec_list(list(a = 1, a = 1))))
    Output
      <error/rlang_error>
      Error in `guess_tspec_list()`:
      ! `list(a = 1, a = 1)` is neither an object nor a list of objects.
      An object
      v is a list,
      v is fully named,
      x and has unique names.
      A list of objects is
      x a data frame or
      v a list and
      x each element is `NULL` or an object.

# can guess spec for discog

    Code
      guess_tspec(discog) %>% print()
    Output
      tspec_df(
        tib_int("instance_id"),
        tib_chr("date_added"),
        tib_row(
          "basic_information",
          tib_df(
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
            tib_variant("descriptions", required = FALSE),
            tib_chr("text", required = FALSE),
            tib_chr("name"),
            tib_chr("qty"),
          ),
          tib_chr("cover_image"),
          tib_chr("resource_url"),
          tib_int("master_id"),
        ),
        tib_int("id"),
        tib_int("rating"),
      )

# can guess spec for gh_users

    Code
      guess_tspec(gh_users) %>% print()
    Output
      tspec_df(
        tib_chr("login"),
        tib_int("id"),
        tib_chr("avatar_url"),
        tib_chr("gravatar_id"),
        tib_chr("url"),
        tib_chr("html_url"),
        tib_chr("followers_url"),
        tib_chr("following_url"),
        tib_chr("gists_url"),
        tib_chr("starred_url"),
        tib_chr("subscriptions_url"),
        tib_chr("organizations_url"),
        tib_chr("repos_url"),
        tib_chr("events_url"),
        tib_chr("received_events_url"),
        tib_chr("type"),
        tib_lgl("site_admin"),
        tib_chr("name"),
        tib_chr("company"),
        tib_chr("blog"),
        tib_chr("location"),
        tib_chr("email"),
        tib_lgl("hireable"),
        tib_chr("bio"),
        tib_int("public_repos"),
        tib_int("public_gists"),
        tib_int("followers"),
        tib_int("following"),
        tib_chr("created_at"),
        tib_chr("updated_at"),
      )

# can guess spec for gh_repos

    Code
      guess_tspec(gh_repos) %>% print()
    Output
      tspec_df(
        tib_int("id"),
        tib_chr("name"),
        tib_chr("full_name"),
        tib_row(
          "owner",
          tib_chr("login"),
          tib_int("id"),
          tib_chr("avatar_url"),
          tib_chr("gravatar_id"),
          tib_chr("url"),
          tib_chr("html_url"),
          tib_chr("followers_url"),
          tib_chr("following_url"),
          tib_chr("gists_url"),
          tib_chr("starred_url"),
          tib_chr("subscriptions_url"),
          tib_chr("organizations_url"),
          tib_chr("repos_url"),
          tib_chr("events_url"),
          tib_chr("received_events_url"),
          tib_chr("type"),
          tib_lgl("site_admin"),
        ),
        tib_lgl("private"),
        tib_chr("html_url"),
        tib_chr("description"),
        tib_lgl("fork"),
        tib_chr("url"),
        tib_chr("forks_url"),
        tib_chr("keys_url"),
        tib_chr("collaborators_url"),
        tib_chr("teams_url"),
        tib_chr("hooks_url"),
        tib_chr("issue_events_url"),
        tib_chr("events_url"),
        tib_chr("assignees_url"),
        tib_chr("branches_url"),
        tib_chr("tags_url"),
        tib_chr("blobs_url"),
        tib_chr("git_tags_url"),
        tib_chr("git_refs_url"),
        tib_chr("trees_url"),
        tib_chr("statuses_url"),
        tib_chr("languages_url"),
        tib_chr("stargazers_url"),
        tib_chr("contributors_url"),
        tib_chr("subscribers_url"),
        tib_chr("subscription_url"),
        tib_chr("commits_url"),
        tib_chr("git_commits_url"),
        tib_chr("comments_url"),
        tib_chr("issue_comment_url"),
        tib_chr("contents_url"),
        tib_chr("compare_url"),
        tib_chr("merges_url"),
        tib_chr("archive_url"),
        tib_chr("downloads_url"),
        tib_chr("issues_url"),
        tib_chr("pulls_url"),
        tib_chr("milestones_url"),
        tib_chr("notifications_url"),
        tib_chr("labels_url"),
        tib_chr("releases_url"),
        tib_chr("deployments_url"),
        tib_chr("created_at"),
        tib_chr("updated_at"),
        tib_chr("pushed_at"),
        tib_chr("git_url"),
        tib_chr("ssh_url"),
        tib_chr("clone_url"),
        tib_chr("svn_url"),
        tib_chr("homepage"),
        tib_int("size"),
        tib_int("stargazers_count"),
        tib_int("watchers_count"),
        tib_chr("language"),
        tib_lgl("has_issues"),
        tib_lgl("has_downloads"),
        tib_lgl("has_wiki"),
        tib_lgl("has_pages"),
        tib_int("forks_count"),
        tib_unspecified("mirror_url"),
        tib_int("open_issues_count"),
        tib_int("forks"),
        tib_int("open_issues"),
        tib_int("watchers"),
        tib_chr("default_branch"),
      )

# can guess spec for got_chars

    Code
      spec
    Output
      tspec_df(
        tib_chr("url"),
        tib_int("id"),
        tib_chr("name"),
        tib_chr("gender"),
        tib_chr("culture"),
        tib_chr("born"),
        tib_chr("died"),
        tib_lgl("alive"),
        tib_chr_vec("titles"),
        tib_variant("aliases"),
        tib_chr("father"),
        tib_chr("mother"),
        tib_chr("spouse"),
        tib_variant("allegiances"),
        tib_variant("books"),
        tib_chr_vec("povBooks"),
        tib_chr_vec("tvSeries"),
        tib_chr_vec("playedBy"),
      )

# can guess spec for citm_catalog

    Code
      guess_tspec(x)
    Output
      tspec_object(
        tib_row(
          "areaNames",
          tib_chr("205705993"),
          tib_chr("205705994"),
          tib_chr("205705995"),
        ),
        tib_row(
          "audienceSubCategoryNames",
          tib_chr("337100890"),
        ),
        tib_unspecified("blockNames"),
        tib_df(
          "events",
          .names_to = ".names",
          tib_unspecified("description"),
          tib_int("id"),
          tib_chr("logo"),
          tib_chr("name"),
          tib_int_vec("subTopicIds"),
          tib_unspecified("subjectCode"),
          tib_unspecified("subtitle"),
          tib_int_vec("topicIds"),
        ),
        tib_df(
          "performances",
          tib_int("eventId"),
          tib_int("id"),
          tib_unspecified("logo"),
          tib_unspecified("name"),
          tib_df(
            "prices",
            tib_int("amount"),
            tib_int("audienceSubCategoryId"),
            tib_int("seatCategoryId"),
          ),
          tib_df(
            "seatCategories",
            tib_df(
              "areas",
              tib_int("areaId"),
              tib_unspecified("blockIds"),
            ),
            tib_int("seatCategoryId"),
          ),
          tib_unspecified("seatMapImage"),
          tib_dbl("start"),
          tib_chr("venueCode"),
        ),
        tib_row(
          "seatCategoryNames",
          tib_chr("338937235"),
          tib_chr("338937236"),
          tib_chr("338937238"),
        ),
        tib_row(
          "subTopicNames",
          tib_chr("337184262"),
          tib_chr("337184263"),
          tib_chr("337184267"),
        ),
        tib_unspecified("subjectNames"),
        tib_row(
          "topicNames",
          tib_chr("107888604"),
          tib_chr("324846098"),
          tib_chr("324846099"),
          tib_chr("324846100"),
        ),
        tib_row(
          "topicSubTopics",
          tib_int_vec("107888604"),
          tib_int("324846098"),
          tib_int_vec("324846099"),
          tib_int_vec("324846100"),
        ),
        tib_row(
          "venueNames",
          tib_chr("PLEYEL_PLEYEL"),
        ),
      )

---

    Code
      guess_tspec_list(x, simplify_list = FALSE)
    Output
      tspec_object(
        tib_row(
          "areaNames",
          tib_chr("205705993"),
          tib_chr("205705994"),
          tib_chr("205705995"),
        ),
        tib_row(
          "audienceSubCategoryNames",
          tib_chr("337100890"),
        ),
        tib_unspecified("blockNames"),
        tib_df(
          "events",
          .names_to = ".names",
          tib_unspecified("description"),
          tib_int("id"),
          tib_chr("logo"),
          tib_chr("name"),
          tib_int_vec("subTopicIds"),
          tib_unspecified("subjectCode"),
          tib_unspecified("subtitle"),
          tib_int_vec("topicIds"),
        ),
        tib_df(
          "performances",
          tib_int("eventId"),
          tib_int("id"),
          tib_unspecified("logo"),
          tib_unspecified("name"),
          tib_df(
            "prices",
            tib_int("amount"),
            tib_int("audienceSubCategoryId"),
            tib_int("seatCategoryId"),
          ),
          tib_df(
            "seatCategories",
            tib_df(
              "areas",
              tib_int("areaId"),
              tib_unspecified("blockIds"),
            ),
            tib_int("seatCategoryId"),
          ),
          tib_unspecified("seatMapImage"),
          tib_dbl("start"),
          tib_chr("venueCode"),
        ),
        tib_row(
          "seatCategoryNames",
          tib_chr("338937235"),
          tib_chr("338937236"),
          tib_chr("338937238"),
        ),
        tib_row(
          "subTopicNames",
          tib_chr("337184262"),
          tib_chr("337184263"),
          tib_chr("337184267"),
        ),
        tib_unspecified("subjectNames"),
        tib_row(
          "topicNames",
          tib_chr("107888604"),
          tib_chr("324846098"),
          tib_chr("324846099"),
          tib_chr("324846100"),
        ),
        tib_row(
          "topicSubTopics",
          tib_int_vec("107888604"),
          tib_int("324846098"),
          tib_int_vec("324846099"),
          tib_int_vec("324846100"),
        ),
        tib_row(
          "venueNames",
          tib_chr("PLEYEL_PLEYEL"),
        ),
      )

# can guess spec for gsoc-2018

    Code
      guess_tspec(x)
    Output
      tspec_df(
        .names_to = ".names",
        tib_chr("@context"),
        tib_chr("@type"),
        tib_chr("name"),
        tib_chr("description"),
        tib_row(
          "sponsor",
          tib_chr("@type"),
          tib_chr("name"),
          tib_chr("disambiguatingDescription"),
          tib_chr("description"),
          tib_chr("url"),
          tib_chr("logo"),
        ),
        tib_row(
          "author",
          tib_chr("@type"),
          tib_chr("name"),
        ),
      )

# can guess spec for twitter

    Code
      guess_tspec(x)
    Output
      tspec_object(
        tib_df(
          "statuses",
          tib_row(
            "metadata",
            tib_chr("result_type"),
            tib_chr("iso_language_code"),
          ),
          tib_chr("created_at"),
          tib_dbl("id"),
          tib_chr("id_str"),
          tib_chr("text"),
          tib_chr("source"),
          tib_lgl("truncated"),
          tib_dbl("in_reply_to_status_id"),
          tib_chr("in_reply_to_status_id_str"),
          tib_int("in_reply_to_user_id"),
          tib_chr("in_reply_to_user_id_str"),
          tib_chr("in_reply_to_screen_name"),
          tib_row(
            "user",
            tib_dbl("id"),
            tib_chr("id_str"),
            tib_chr("name"),
            tib_chr("screen_name"),
            tib_chr("location"),
            tib_chr("description"),
            tib_chr("url"),
            tib_df(
              "entities",
              .names_to = ".names",
              tib_df(
                "urls",
                tib_chr("url"),
                tib_chr("expanded_url"),
                tib_chr("display_url"),
                tib_int_vec("indices"),
              ),
            ),
            tib_lgl("protected"),
            tib_int("followers_count"),
            tib_int("friends_count"),
            tib_int("listed_count"),
            tib_chr("created_at"),
            tib_int("favourites_count"),
            tib_int("utc_offset"),
            tib_chr("time_zone"),
            tib_lgl("geo_enabled"),
            tib_lgl("verified"),
            tib_int("statuses_count"),
            tib_chr("lang"),
            tib_lgl("contributors_enabled"),
            tib_lgl("is_translator"),
            tib_lgl("is_translation_enabled"),
            tib_chr("profile_background_color"),
            tib_chr("profile_background_image_url"),
            tib_chr("profile_background_image_url_https"),
            tib_lgl("profile_background_tile"),
            tib_chr("profile_image_url"),
            tib_chr("profile_image_url_https"),
            tib_chr("profile_banner_url", required = FALSE),
            tib_chr("profile_link_color"),
            tib_chr("profile_sidebar_border_color"),
            tib_chr("profile_sidebar_fill_color"),
            tib_chr("profile_text_color"),
            tib_lgl("profile_use_background_image"),
            tib_lgl("default_profile"),
            tib_lgl("default_profile_image"),
            tib_lgl("following"),
            tib_lgl("follow_request_sent"),
            tib_lgl("notifications"),
          ),
          tib_unspecified("geo"),
          tib_unspecified("coordinates"),
          tib_unspecified("place"),
          tib_unspecified("contributors"),
          tib_int("retweet_count"),
          tib_int("favorite_count"),
          tib_row(
            "entities",
            tib_df(
              "hashtags",
              tib_chr("text"),
              tib_int_vec("indices"),
            ),
            tib_unspecified("symbols"),
            tib_unspecified("urls"),
            tib_df(
              "user_mentions",
              tib_chr("screen_name"),
              tib_chr("name"),
              tib_int("id"),
              tib_chr("id_str"),
              tib_int_vec("indices"),
            ),
            tib_df(
              "media",
              .required = FALSE,
              tib_dbl("id"),
              tib_chr("id_str"),
              tib_int_vec("indices"),
              tib_chr("media_url"),
              tib_chr("media_url_https"),
              tib_chr("url"),
              tib_chr("display_url"),
              tib_chr("expanded_url"),
              tib_chr("type"),
              tib_df(
                "sizes",
                .names_to = ".names",
                tib_int("w"),
                tib_int("h"),
                tib_chr("resize"),
              ),
              tib_dbl("source_status_id"),
              tib_chr("source_status_id_str"),
            ),
          ),
          tib_lgl("favorited"),
          tib_lgl("retweeted"),
          tib_chr("lang"),
          tib_row(
            "retweeted_status",
            .required = FALSE,
            tib_row(
              "metadata",
              .required = FALSE,
              tib_chr("result_type"),
              tib_chr("iso_language_code"),
            ),
            tib_chr("created_at", required = FALSE),
            tib_dbl("id", required = FALSE),
            tib_chr("id_str", required = FALSE),
            tib_chr("text", required = FALSE),
            tib_chr("source", required = FALSE),
            tib_lgl("truncated", required = FALSE),
            tib_unspecified("in_reply_to_status_id", required = FALSE),
            tib_unspecified("in_reply_to_status_id_str", required = FALSE),
            tib_unspecified("in_reply_to_user_id", required = FALSE),
            tib_unspecified("in_reply_to_user_id_str", required = FALSE),
            tib_unspecified("in_reply_to_screen_name", required = FALSE),
            tib_row(
              "user",
              .required = FALSE,
              tib_int("id"),
              tib_chr("id_str"),
              tib_chr("name"),
              tib_chr("screen_name"),
              tib_chr("location"),
              tib_chr("description"),
              tib_unspecified("url"),
              tib_df(
                "entities",
                .names_to = ".names",
                tib_df(
                  "urls",
                  tib_chr("url"),
                  tib_chr("expanded_url"),
                  tib_chr("display_url"),
                  tib_int_vec("indices"),
                ),
              ),
              tib_lgl("protected"),
              tib_int("followers_count"),
              tib_int("friends_count"),
              tib_int("listed_count"),
              tib_chr("created_at"),
              tib_int("favourites_count"),
              tib_int("utc_offset"),
              tib_chr("time_zone"),
              tib_lgl("geo_enabled"),
              tib_lgl("verified"),
              tib_int("statuses_count"),
              tib_chr("lang"),
              tib_lgl("contributors_enabled"),
              tib_lgl("is_translator"),
              tib_lgl("is_translation_enabled"),
              tib_chr("profile_background_color"),
              tib_chr("profile_background_image_url"),
              tib_chr("profile_background_image_url_https"),
              tib_lgl("profile_background_tile"),
              tib_chr("profile_image_url"),
              tib_chr("profile_image_url_https"),
              tib_chr("profile_banner_url"),
              tib_chr("profile_link_color"),
              tib_chr("profile_sidebar_border_color"),
              tib_chr("profile_sidebar_fill_color"),
              tib_chr("profile_text_color"),
              tib_lgl("profile_use_background_image"),
              tib_lgl("default_profile"),
              tib_lgl("default_profile_image"),
              tib_lgl("following"),
              tib_lgl("follow_request_sent"),
              tib_lgl("notifications"),
            ),
            tib_unspecified("geo", required = FALSE),
            tib_unspecified("coordinates", required = FALSE),
            tib_unspecified("place", required = FALSE),
            tib_unspecified("contributors", required = FALSE),
            tib_int("retweet_count", required = FALSE),
            tib_int("favorite_count", required = FALSE),
            tib_row(
              "entities",
              .required = FALSE,
              tib_df(
                "hashtags",
                tib_chr("text"),
                tib_int_vec("indices"),
              ),
              tib_unspecified("symbols"),
              tib_unspecified("urls"),
              tib_unspecified("user_mentions"),
              tib_df(
                "media",
                .required = FALSE,
                tib_dbl("id"),
                tib_chr("id_str"),
                tib_int_vec("indices"),
                tib_chr("media_url"),
                tib_chr("media_url_https"),
                tib_chr("url"),
                tib_chr("display_url"),
                tib_chr("expanded_url"),
                tib_chr("type"),
                tib_df(
                  "sizes",
                  .names_to = ".names",
                  tib_int("w"),
                  tib_int("h"),
                  tib_chr("resize"),
                ),
              ),
            ),
            tib_lgl("favorited", required = FALSE),
            tib_lgl("retweeted", required = FALSE),
            tib_lgl("possibly_sensitive", required = FALSE),
            tib_chr("lang", required = FALSE),
          ),
          tib_lgl("possibly_sensitive", required = FALSE),
        ),
        tib_row(
          "search_metadata",
          tib_dbl("completed_in"),
          tib_dbl("max_id"),
          tib_chr("max_id_str"),
          tib_chr("next_results"),
          tib_chr("query"),
          tib_chr("refresh_url"),
          tib_int("count"),
          tib_int("since_id"),
          tib_chr("since_id_str"),
        ),
      )

