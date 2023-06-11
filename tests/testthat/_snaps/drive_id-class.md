# as_id() errors for unanticipated input

    Code
      as_id(mean)
    Condition
      Error in `as_id()`:
      ! Don't know how to coerce an object of class <function> into a <drive_id>.

---

    Code
      as_id(1.2)
    Condition
      Error in `as_id()`:
      ! Don't know how to coerce an object of class <numeric> into a <drive_id>.

---

    Code
      as_id(1L)
    Condition
      Error in `as_id()`:
      ! Don't know how to coerce an object of class <integer> into a <drive_id>.

# drive_id's are formatted OK

    Code
      print(x$id)
    Output
      <drive_id[10]>
       [1] 1CEefQCUc5T7B4yrawnNfqwdWEbiDyDs9E5OB9p6AXQ8
       [2] 1oUrQNg-2lcAieZyCqoQ_vDwYLMVzhN4-oOSTt2L3Glw
       [3] 1V6qQhCVkgVRLUL24_lExApTklRsrDLv3           
       [4] 1uBR1UMWUXQ02OS9B6sQ3-98Z7QFUGUwn           
       [5] 1U_5_O1-Od_q30wQVhGgZlMevFkcxHr7V           
       [6] 1Y2O_otAmg7BN0Bk_5d-i9ZlGcflmw_uo           
       [7] 1o_UmldMPpRfr4JlVyZKu1ZR2vN_m-uhs           
       [8] 1oa-yeDNPd8x7sddbwHEWjGadY7HkGvMv           
       [9] 1yeH1TqZczcPvhZoJvSOnG2_rfFCycyix           
      [10] 1qSmvJtYUf6w1UtnA4XWUmG_qrVjjTnCN           

# drive_ids look OK in a dribble and truncate gracefully

    Code
      print(x)
    Output
      # A dribble: 10 x 3
         name                                 id       drive_resource   
         <chr>                                <drv_id> <list>           
       1 foo_sheet-TEST-drive_publish         1CEefQC~ <named list [36]>
       2 foo_doc-TEST-drive_publish           1oUrQNg~ <named list [36]>
       3 DESC-TEST-drive_mv-jenny-7694ef72    1V6qQhC~ <named list [40]>
       4 DESC-TEST-drive_mv-jenny-7694ef72    1uBR1UM~ <named list [40]>
       5 name-collision-TEST-path-utils-jenny 1U_5_O1~ <named list [39]>
       6 DESCRIPTION-TEST-drive-update-jenny  1Y2O_ot~ <named list [40]>
       7 name-collision-TEST-path-utils-jenny 1o_Umld~ <named list [39]>
       8 DESC-TEST-drive-mv-jenny             1oa-yeD~ <named list [40]>
       9 DESC-TEST-drive-mv-jenny             1yeH1Tq~ <named list [40]>
      10 DESC-TEST-drive-mv-jenny             1qSmvJt~ <named list [40]>

---

    Code
      print(drive_reveal(x, "mime_type"))
    Output
      # A dribble: 10 x 4
         name                                 mime_type        id       drive_resource
         <chr>                                <chr>            <drv_id> <list>        
       1 foo_sheet-TEST-drive_publish         application/vnd~ 1CEefQC~ <named list>  
       2 foo_doc-TEST-drive_publish           application/vnd~ 1oUrQNg~ <named list>  
       3 DESC-TEST-drive_mv-jenny-7694ef72    text/plain       1V6qQhC~ <named list>  
       4 DESC-TEST-drive_mv-jenny-7694ef72    text/plain       1uBR1UM~ <named list>  
       5 name-collision-TEST-path-utils-jenny application/oct~ 1U_5_O1~ <named list>  
       6 DESCRIPTION-TEST-drive-update-jenny  text/plain       1Y2O_ot~ <named list>  
       7 name-collision-TEST-path-utils-jenny application/oct~ 1o_Umld~ <named list>  
       8 DESC-TEST-drive-mv-jenny             text/plain       1oa-yeD~ <named list>  
       9 DESC-TEST-drive-mv-jenny             text/plain       1yeH1Tq~ <named list>  
      10 DESC-TEST-drive-mv-jenny             text/plain       1qSmvJt~ <named list>  

---

    Code
      print(x)
    Output
      # A dribble: 10 x 3
         name                                 id       drive_resource   
         <chr>                                <drv_id> <list>           
       1 foo_sheet-TEST-drive_publish         <NA>     <named list [36]>
       2 foo_doc-TEST-drive_publish           1oUrQNg~ <named list [36]>
       3 DESC-TEST-drive_mv-jenny-7694ef72    1V6qQhC~ <named list [40]>
       4 DESC-TEST-drive_mv-jenny-7694ef72    1uBR1UM~ <named list [40]>
       5 name-collision-TEST-path-utils-jenny 1U_5_O1~ <named list [39]>
       6 DESCRIPTION-TEST-drive-update-jenny  1Y2O_ot~ <named list [40]>
       7 name-collision-TEST-path-utils-jenny 1o_Umld~ <named list [39]>
       8 DESC-TEST-drive-mv-jenny             1oa-yeD~ <named list [40]>
       9 DESC-TEST-drive-mv-jenny             1yeH1Tq~ <named list [40]>
      10 DESC-TEST-drive-mv-jenny             1qSmvJt~ <named list [40]>

# gargle_map_cli() is implemented for drive_id

    Code
      gargle_map_cli(as_id(month.name[1:3]))
    Output
      [1] "{.field January}"  "{.field February}" "{.field March}"   

# validate_drive_id fails informatively

    Code
      validate_drive_id("")
    Condition
      Error in `validate_drive_id()`:
      ! A <drive_id> must match this regular expression: `^[a-zA-Z0-9_-]+$`
      Invalid input:
      x '""'

---

    Code
      validate_drive_id("a@&")
    Condition
      Error in `validate_drive_id()`:
      ! A <drive_id> must match this regular expression: `^[a-zA-Z0-9_-]+$`
      Invalid input:
      x 'a@&'

# you can't insert invalid strings into a drive_id

    Code
      x[2] <- ""
    Condition
      Error in `validate_drive_id()`:
      ! A <drive_id> must match this regular expression: `^[a-zA-Z0-9_-]+$`
      Invalid input:
      x '""'

