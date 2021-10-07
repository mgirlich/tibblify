# missing elements produce error

    empty or absent element at path a

# known examples discog

    Code
      result
    Output
      # A tibble: 155 x 5
         instance_id date_added  basic_informatio~ $year $master_url   $artists    $id
               <int> <chr>       <list<tibble[,6]> <int> <chr>         <list<t>  <int>
       1   354823933 2019-02-16~           [1 x 6]  2015 <NA>           [1 x 7] 7.50e6
       2   354092601 2019-02-13~           [1 x 6]  2013 https://api.~  [1 x 7] 4.49e6
       3   354091476 2019-02-13~           [1 x 6]  2017 https://api.~  [1 x 7] 9.83e6
       4   351244906 2019-02-02~           [3 x 6]  2017 https://api.~  [1 x 7] 9.77e6
       5   351244801 2019-02-02~           [1 x 6]  2015 https://api.~  [1 x 7] 7.24e6
       6   351052065 2019-02-01~           [1 x 6]  2019 https://api.~  [1 x 7] 1.31e7
       7   350315345 2019-01-29~           [1 x 6]  2014 https://api.~  [1 x 7] 7.11e6
       8   350315103 2019-01-29~           [1 x 6]  2015 https://api.~  [1 x 7] 1.05e7
       9   350314507 2019-01-29~           [1 x 6]  2017 https://api.~  [1 x 7] 1.13e7
      10   350314047 2019-01-29~           [1 x 6]  2017 <NA>           [1 x 7] 1.17e7
      # ... with 145 more rows, and 2 more variables: id <int>, rating <int>

# gh_repos works

    Code
      tibblify(gh_repos)
    Output
      # A tibble: 30 x 68
               id name   full_name owner$login    $id $avatar_url  $gravatar_id $url  
            <int> <chr>  <chr>     <chr>        <int> <chr>        <chr>        <chr> 
       1 61160198 after  gaborcsa~ gaborcsardi 660288 https://ava~ ""           https~
       2 40500181 argufy gaborcsa~ gaborcsardi 660288 https://ava~ ""           https~
       3 36442442 ask    gaborcsa~ gaborcsardi 660288 https://ava~ ""           https~
       4 34924886 basei~ gaborcsa~ gaborcsardi 660288 https://ava~ ""           https~
       5 61620661 citest gaborcsa~ gaborcsardi 660288 https://ava~ ""           https~
       6 33907457 clisy~ gaborcsa~ gaborcsardi 660288 https://ava~ ""           https~
       7 37236467 cmaker gaborcsa~ gaborcsardi 660288 https://ava~ ""           https~
       8 67959624 cmark  gaborcsa~ gaborcsardi 660288 https://ava~ ""           https~
       9 63152619 condi~ gaborcsa~ gaborcsardi 660288 https://ava~ ""           https~
      10 24343686 crayon gaborcsa~ gaborcsardi 660288 https://ava~ ""           https~
      # ... with 20 more rows, and 64 more variables: private <lgl>, html_url <chr>,
      #   description <chr>, fork <lgl>, url <chr>, forks_url <chr>, keys_url <chr>,
      #   collaborators_url <chr>, teams_url <chr>, hooks_url <chr>,
      #   issue_events_url <chr>, events_url <chr>, assignees_url <chr>,
      #   branches_url <chr>, tags_url <chr>, blobs_url <chr>, git_tags_url <chr>,
      #   git_refs_url <chr>, trees_url <chr>, statuses_url <chr>,
      #   languages_url <chr>, stargazers_url <chr>, contributors_url <chr>, ...

# gh_users works

    Code
      tibblify(gh_users)
    Output
      # A tibble: 6 x 30
        login           id avatar_url gravatar_id url   html_url followers_url following_url
        <chr>        <int> <chr>      <chr>       <chr> <chr>    <chr>         <chr>        
      1 gaborcsardi 6.60e5 https://a~ ""          http~ https:/~ https://api.~ https://api.~
      2 jennybc     5.99e5 https://a~ ""          http~ https:/~ https://api.~ https://api.~
      3 jtleek      1.57e6 https://a~ ""          http~ https:/~ https://api.~ https://api.~
      4 juliasilge  1.25e7 https://a~ ""          http~ https:/~ https://api.~ https://api.~
      5 leeper      3.51e6 https://a~ ""          http~ https:/~ https://api.~ https://api.~
      6 masalmon    8.36e6 https://a~ ""          http~ https:/~ https://api.~ https://api.~
      # ... with 22 more variables: gists_url <chr>, starred_url <chr>,
      #   subscriptions_url <chr>, organizations_url <chr>, repos_url <chr>,
      #   events_url <chr>, received_events_url <chr>, type <chr>, site_admin <lgl>,
      #   name <chr>, company <chr>, blog <chr>, location <chr>, email <chr>,
      #   hireable <lgl>, bio <chr>, public_repos <int>, public_gists <int>,
      #   followers <int>, following <int>, created_at <chr>, updated_at <chr>

# got_chars works

    Code
      tibblify(got_chars)
    Output
      # A tibble: 30 x 18
         url        id name   gender culture born   died   alive titles aliases father
         <chr>   <int> <chr>  <chr>  <chr>   <chr>  <chr>  <lgl> <list> <list<> <chr> 
       1 https:~  1022 Theon~ Male   "Ironb~ "In 2~ ""     TRUE     [3]     [4] ""    
       2 https:~  1052 Tyrio~ Male   ""      "In 2~ ""     TRUE     [2]    [11] ""    
       3 https:~  1074 Victa~ Male   "Ironb~ "In 2~ ""     TRUE     [2]     [1] ""    
       4 https:~  1109 Will   Male   ""      ""     "In 2~ FALSE    [1]     [1] ""    
       5 https:~  1166 Areo ~ Male   "Norvo~ "In 2~ ""     TRUE     [1]     [1] ""    
       6 https:~  1267 Chett  Male   ""      "At H~ "In 2~ FALSE    [1]     [1] ""    
       7 https:~  1295 Cress~ Male   ""      "In 2~ "In 2~ FALSE    [1]     [1] ""    
       8 https:~   130 Arian~ Female "Dorni~ "In 2~ ""     TRUE     [1]     [1] ""    
       9 https:~  1303 Daene~ Female "Valyr~ "In 2~ ""     TRUE     [5]    [11] ""    
      10 https:~  1319 Davos~ Male   "Weste~ "In 2~ ""     TRUE     [4]     [5] ""    
      # ... with 20 more rows, and 7 more variables: mother <chr>, spouse <chr>,
      #   allegiances <list<chr>>, books <list<chr>>, povBooks <list<chr>>,
      #   tvSeries <list<chr>>, playedBy <list<chr>>

# sw_films works

    Code
      tibblify(sw_films)
    Output
      # A tibble: 7 x 14
        title  episode_id opening_crawl    director  producer  release_date characters
        <chr>       <int> <chr>            <chr>     <chr>     <chr>        <list<chr>
      1 A New~          4 "It is a period~ George L~ Gary Kur~ 1977-05-25         [18]
      2 Attac~          2 "There is unres~ George L~ Rick McC~ 2002-05-16         [40]
      3 The P~          1 "Turmoil has en~ George L~ Rick McC~ 1999-05-19         [34]
      4 Reven~          3 "War! The Repub~ George L~ Rick McC~ 2005-05-19         [34]
      5 Retur~          6 "Luke Skywalker~ Richard ~ Howard G~ 1983-05-25         [20]
      6 The E~          5 "It is a dark t~ Irvin Ke~ Gary Kut~ 1980-05-17         [16]
      7 The F~          7 "Luke Skywalker~ J. J. Ab~ Kathleen~ 2015-12-11         [11]
      # ... with 7 more variables: planets <list<chr>>, starships <list<chr>>,
      #   vehicles <list<chr>>, species <list<chr>>, created <chr>, edited <chr>,
      #   url <chr>

