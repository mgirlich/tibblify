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
            descriptions = tib_chr_vec(
              "descriptions",
              required = FALSE,
              transform = function (x) 
              vec_unchop(x = x, ptype = character(0))
            ),
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

# can guess spec for gh_repos

    Code
      guess_spec(gh_repos) %>% print()
    Output
      spec_df(
        id = tib_int("id"),
        name = tib_chr("name"),
        full_name = tib_chr("full_name"),
        owner = tib_row(
          "owner",
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
          site_admin = tib_lgl("site_admin")
        ),
        private = tib_lgl("private"),
        html_url = tib_chr("html_url"),
        description = tib_chr("description"),
        fork = tib_lgl("fork"),
        url = tib_chr("url"),
        forks_url = tib_chr("forks_url"),
        keys_url = tib_chr("keys_url"),
        collaborators_url = tib_chr("collaborators_url"),
        teams_url = tib_chr("teams_url"),
        hooks_url = tib_chr("hooks_url"),
        issue_events_url = tib_chr("issue_events_url"),
        events_url = tib_chr("events_url"),
        assignees_url = tib_chr("assignees_url"),
        branches_url = tib_chr("branches_url"),
        tags_url = tib_chr("tags_url"),
        blobs_url = tib_chr("blobs_url"),
        git_tags_url = tib_chr("git_tags_url"),
        git_refs_url = tib_chr("git_refs_url"),
        trees_url = tib_chr("trees_url"),
        statuses_url = tib_chr("statuses_url"),
        languages_url = tib_chr("languages_url"),
        stargazers_url = tib_chr("stargazers_url"),
        contributors_url = tib_chr("contributors_url"),
        subscribers_url = tib_chr("subscribers_url"),
        subscription_url = tib_chr("subscription_url"),
        commits_url = tib_chr("commits_url"),
        git_commits_url = tib_chr("git_commits_url"),
        comments_url = tib_chr("comments_url"),
        issue_comment_url = tib_chr("issue_comment_url"),
        contents_url = tib_chr("contents_url"),
        compare_url = tib_chr("compare_url"),
        merges_url = tib_chr("merges_url"),
        archive_url = tib_chr("archive_url"),
        downloads_url = tib_chr("downloads_url"),
        issues_url = tib_chr("issues_url"),
        pulls_url = tib_chr("pulls_url"),
        milestones_url = tib_chr("milestones_url"),
        notifications_url = tib_chr("notifications_url"),
        labels_url = tib_chr("labels_url"),
        releases_url = tib_chr("releases_url"),
        deployments_url = tib_chr("deployments_url"),
        created_at = tib_chr("created_at"),
        updated_at = tib_chr("updated_at"),
        pushed_at = tib_chr("pushed_at"),
        git_url = tib_chr("git_url"),
        ssh_url = tib_chr("ssh_url"),
        clone_url = tib_chr("clone_url"),
        svn_url = tib_chr("svn_url"),
        homepage = tib_chr("homepage"),
        size = tib_int("size"),
        stargazers_count = tib_int("stargazers_count"),
        watchers_count = tib_int("watchers_count"),
        language = tib_chr("language"),
        has_issues = tib_lgl("has_issues"),
        has_downloads = tib_lgl("has_downloads"),
        has_wiki = tib_lgl("has_wiki"),
        has_pages = tib_lgl("has_pages"),
        forks_count = tib_int("forks_count"),
        mirror_url = tib_unspecified("mirror_url"),
        open_issues_count = tib_int("open_issues_count"),
        forks = tib_int("forks"),
        open_issues = tib_int("open_issues"),
        watchers = tib_int("watchers"),
        default_branch = tib_chr("default_branch")
      )

# can guess spec for citm_catalog

    Code
      guess_spec(x)
    Output
      spec_object(
        areaNames = tib_chr_vec(
          "areaNames",
          transform = function (x) 
          vec_unchop(x = x, ptype = character(0))
        ),
        audienceSubCategoryNames = tib_chr_vec(
          "audienceSubCategoryNames",
          transform = function (x) 
          vec_unchop(x = x, ptype = character(0))
        ),
        blockNames = tib_unspecified("blockNames"),
        events = tib_df(
          "events",
          .names_to = ".names",
          description = tib_unspecified("description"),
          id = tib_int("id"),
          logo = tib_chr("logo"),
          name = tib_chr("name"),
          subTopicIds = tib_int_vec("subTopicIds"),
          subjectCode = tib_unspecified("subjectCode"),
          subtitle = tib_unspecified("subtitle"),
          topicIds = tib_int_vec("topicIds")
        ),
        performances = tib_df(
          "performances",
          eventId = tib_int("eventId"),
          id = tib_int("id"),
          logo = tib_unspecified("logo"),
          name = tib_unspecified("name"),
          prices = tib_df(
            "prices",
            amount = tib_int("amount"),
            audienceSubCategoryId = tib_int("audienceSubCategoryId"),
            seatCategoryId = tib_int("seatCategoryId")
          ),
          seatCategories = tib_df(
            "seatCategories",
            areas = tib_df(
              "areas",
              areaId = tib_int("areaId"),
              blockIds = tib_unspecified("blockIds")
            ),
            seatCategoryId = tib_int("seatCategoryId")
          ),
          seatMapImage = tib_unspecified("seatMapImage"),
          start = tib_dbl("start"),
          venueCode = tib_chr("venueCode")
        ),
        seatCategoryNames = tib_chr_vec(
          "seatCategoryNames",
          transform = function (x) 
          vec_unchop(x = x, ptype = character(0))
        ),
        subTopicNames = tib_chr_vec(
          "subTopicNames",
          transform = function (x) 
          vec_unchop(x = x, ptype = character(0))
        ),
        subjectNames = tib_unspecified("subjectNames"),
        topicNames = tib_chr_vec(
          "topicNames",
          transform = function (x) 
          vec_unchop(x = x, ptype = character(0))
        ),
        topicSubTopics = tib_list(
          "topicSubTopics",
          transform = function (x) 
          new_list_of(x = x, ptype = integer(0))
        ),
        venueNames = tib_chr_vec(
          "venueNames",
          transform = function (x) 
          vec_unchop(x = x, ptype = character(0))
        )
      )

---

    Code
      guess_spec(x, check_flatten = FALSE)
    Output
      spec_object(
        areaNames = tib_row(
          "areaNames",
          `205705993` = tib_chr("205705993"),
          `205705994` = tib_chr("205705994"),
          `205705995` = tib_chr("205705995")
        ),
        audienceSubCategoryNames = tib_row(
          "audienceSubCategoryNames",
          `337100890` = tib_chr("337100890")
        ),
        blockNames = tib_unspecified("blockNames"),
        events = tib_df(
          "events",
          .names_to = ".names",
          description = tib_unspecified("description"),
          id = tib_int("id"),
          logo = tib_chr("logo"),
          name = tib_chr("name"),
          subTopicIds = tib_int_vec("subTopicIds"),
          subjectCode = tib_unspecified("subjectCode"),
          subtitle = tib_unspecified("subtitle"),
          topicIds = tib_int_vec("topicIds")
        ),
        performances = tib_df(
          "performances",
          eventId = tib_int("eventId"),
          id = tib_int("id"),
          logo = tib_unspecified("logo"),
          name = tib_unspecified("name"),
          prices = tib_df(
            "prices",
            amount = tib_int("amount"),
            audienceSubCategoryId = tib_int("audienceSubCategoryId"),
            seatCategoryId = tib_int("seatCategoryId")
          ),
          seatCategories = tib_df(
            "seatCategories",
            areas = tib_df(
              "areas",
              areaId = tib_int("areaId"),
              blockIds = tib_unspecified("blockIds")
            ),
            seatCategoryId = tib_int("seatCategoryId")
          ),
          seatMapImage = tib_unspecified("seatMapImage"),
          start = tib_dbl("start"),
          venueCode = tib_chr("venueCode")
        ),
        seatCategoryNames = tib_row(
          "seatCategoryNames",
          `338937235` = tib_chr("338937235"),
          `338937236` = tib_chr("338937236"),
          `338937238` = tib_chr("338937238")
        ),
        subTopicNames = tib_row(
          "subTopicNames",
          `337184262` = tib_chr("337184262"),
          `337184263` = tib_chr("337184263"),
          `337184267` = tib_chr("337184267")
        ),
        subjectNames = tib_unspecified("subjectNames"),
        topicNames = tib_row(
          "topicNames",
          `107888604` = tib_chr("107888604"),
          `324846098` = tib_chr("324846098"),
          `324846099` = tib_chr("324846099"),
          `324846100` = tib_chr("324846100")
        ),
        topicSubTopics = tib_row(
          "topicSubTopics",
          `107888604` = tib_int_vec("107888604"),
          `324846098` = tib_int("324846098"),
          `324846099` = tib_int_vec("324846099"),
          `324846100` = tib_int_vec("324846100")
        ),
        venueNames = tib_row(
          "venueNames",
          PLEYEL_PLEYEL = tib_chr("PLEYEL_PLEYEL")
        )
      )

