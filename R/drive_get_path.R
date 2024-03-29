# all the helpers behind:
# drive_get(path =)
# drive_reveal(what = "path")

drive_reveal_path <- function(x, ancestors = c("none", "parents", "all")) {
  stopifnot(inherits(x, "dribble"))
  if (no_file(x)) {
    return(dribble_with_path())
  }
  ancestors <- ancestors %||% dribble()

  if (!inherits(ancestors, "dribble")) {
    ancestors <- arg_match(ancestors)
    if (ancestors == "all") {
      tmp <- sort_out_shared_drive_and_corpus(x)
      shared_drive <- tmp$shared_drive
      corpus <- tmp$corpus
    }
    ancestors <- switch(
      ancestors,
      none = dribble(),
      parents = get_immediate_parents(x),
      all = get_folders(shared_drive = shared_drive, corpus = corpus)
    )
  }

  resolve_paths(x, ancestors)
}

drive_reveal_canonical_path <- function(x) {
  drive_reveal_path(x, ancestors = "all")
}

# TODO: can this somehow be unified with drive_find()'s fussing about with
# (shared_drive, corpus) and with shared_drive_params()?
sort_out_shared_drive_and_corpus <- function(x) {
  shared_drive <- NULL
  corpus <- NULL
  sid <- map_chr(x$drive_resource, "driveId", .default = NA)
  sid <- unique(sid[!is.na(sid)])
  if (length(sid) == 1) {
    shared_drive <- as_id(sid)
  }
  if (length(sid) > 1) {
    corpus <- "allDrives"
  }
  list(shared_drive = shared_drive, corpus = corpus)
}

drive_get_path <- function(path = NULL,
                           shared_drive = NULL,
                           corpus = NULL) {
  if (length(path) == 0) {
    return(dribble_with_path())
  }
  stopifnot(is_path(path))
  path <- rootize_path(path)

  last_path_part <- get_last_path_part(path)
  candidates <- get_by_name(
    last_path_part,
    shared_drive = shared_drive, corpus = corpus
  )
  candidates <- drive_reveal_path(candidates)

  # setup a tibble to structure the work
  dat <- tibble(
    orig_path = path,
    doomed = !map_lgl(last_path_part, path_has_match, haystack = candidates$path),
    done = FALSE
  )

  dat$done <- map_lgl(dat$orig_path, path_has_match, haystack = candidates$path)
  if (all(dat$done | dat$doomed)) {
    return(finalize(dat, candidates))
  }
  # all undone paths assert something about parent folder(s)

  candidates <- drive_reveal_path(candidates, "parents")
  dat$done <- map_lgl(dat$orig_path, path_has_match, haystack = candidates$path)
  if (all(dat$done | dat$doomed)) {
    return(finalize(dat, candidates))
  }

  candidates <- drive_reveal_path(candidates, "all")
  dat$done <- map_lgl(dat$orig_path, path_has_match, haystack = candidates$path)
  if (all(dat$done | dat$doomed)) {
    return(finalize(dat, candidates))
  }

  # TODO: paths that are still undone could possibly be resolved by considering
  # folder shortcuts, i.e. non-canonical paths
  # but for now, just return what we've got
  finalize(dat, candidates)
}

path_match <- function(needle, haystack) {
  if (!has_slash(needle)) {
    haystack <- strip_slash(haystack)
  }
  if (startsWith(needle, "[/~]")) {
    needle <- paste0("^", needle)
  }
  needle <- paste0(escape_regex(needle), "$")
  grep(needle, haystack)
}

path_has_match <- function(needle, haystack) {
  any(path_match(needle, haystack))
}

get_folders <- function(shared_drive = NULL, corpus = NULL) {
  # TODO: could possibly be nice to limit the fields
  folders <-
    drive_find(type = "folder", shared_drive = shared_drive, corpus = corpus)
  folders <- vec_rbind(root_folder(), folders)
}

get_immediate_parents <- function(x) {
  stopifnot(inherits(x, "dribble"))
  x <- drive_reveal(x, "parent")
  parent_ids <- unique(x$id_parent[!is.na(x$id_parent)])
  # TODO: I suspect I must deal with the case where don't have permission to
  # drive_get() one of these ids, but I haven't tripped up on this yet myself.
  # TODO: could possibly be nice to limit the fields
  drive_get(id = as_id(parent_ids))
}

resolve_paths <- function(d, folders = dribble()) {
  probands <- pthize(d)
  ancestors <- pthize(folders)
  raw_paths <- map(probands, ~ pth(list(.x), ancestors))
  pretty_paths <- map_chr(raw_paths, pathify)
  put_column(d, nm = "path", val = pretty_paths, .after = "name")
}

# converts files in a dribble to the form used in pth()
pthize <- function(d) {
  d <- d %>%
    drive_reveal("mime_type") %>%
    drive_reveal("parent") %>%
    drive_reveal("shortcut_details")
  purrr::transpose(
    d[c(
      "id", "id_parent", # needed to resolve path relationships
      "name", "mime_type", "shortcut_details" # needed to create path string
    )]
  )
}

# turns the output of pth() (a list) into a filepath (a string)
pathify <- function(x) {
  x <- map_if(x, ~ .x$id == root_id(), ~ {
    .x$name <- "~"
    .x
  })

  last_mime_type <- pluck(last(x), "mime_type")
  last_is_folder <- identical(last_mime_type, drive_mime_type("folder"))
  last_is_folder_shortcut <-
    identical(last_mime_type, drive_mime_type("shortcut")) &&
      identical(
        pluck(last(x), "shortcut_details", "targetMimeType"),
        drive_mime_type("folder")
      )
  if (last_is_folder || last_is_folder_shortcut) {
    nm <- pluck(last(x), "name")
    purrr::pluck(x, length(x), "name") <- append_slash(nm)
  }

  glue_collapse(map_chr(x, "name"), sep = "/")
}

# the recursive workhorse that walks up a file tree
# x is a list, each element describes 1 file
# a file is described by:
# - id
# - id_parent        (can be NA)
# - name             (just along for the ride; needed to create path strings)
# - mime_type        (ditto)
# - shortcut_details (ditto; is often NULL)
# typical x at start: list(some_file)
# typical x at finish: list(grandparent_folder, parent_folder, some_file)
pth <- function(x, ancestors) {
  this <- x[[1]]
  if (is.na(this$id_parent)) {
    return(x)
  }
  parent <- purrr::detect(ancestors, ~ identical(.x$id, this$id_parent))
  if (is.null(parent)) {
    return(x)
  }
  pth(c(list(parent), x), ancestors)
}

finalize <- function(dat, candidates) {
  scratch <- dat
  scratch$m <- map(dat$orig_path, path_match, haystack = candidates$path)
  scratch$nm <- lengths(scratch$m)
  scratch$status <- NA_character_

  # doomed: never even found a file with correct name, much less path
  # (remember this filter goes a bit beyond the name, e.g. maybe folder-hood)
  scratch$status[scratch$doomed] <- "unmatched"

  # empty_string: special case of doomed
  scratch$status[!nzchar(scratch$orig_path)] <- "empty_string"

  # not doomed, but undone: these could be valid paths, but we won't know until
  # we start resolving non-canonical paths
  scratch$status[!scratch$done & !scratch$doomed] <- "undone"

  # unspecific: path is compatible with more than 1 file
  scratch$status[scratch$done & scratch$nm > 1] <- "unspecific"

  # resolved: path identifies exactly 1 file
  scratch$status[scratch$done & scratch$nm == 1] <- "resolved"

  no_status <- is.na(scratch$status)
  if (any(no_status)) {
    abort("Internal error: paths with missing status")
  }

  report_weird_stuff <- function(x, indicator, problem) {
    weird <- vec_slice(x, x[["status"]] == indicator)
    if (vec_size(weird) == 0) {
      return()
    }
    drive_bullets(c(
      "!" = "Problem with {nrow(weird)} path{?s}: {problem}",
      # these really should be sub-bullets, but not possible at this time
      bulletize(gargle_map_cli(weird[["orig_path"]], "{.path <<x>>}"), bullet = " ")
    ))
  }
  report_weird_stuff(scratch, "unmatched", "no files found by this name")
  report_weird_stuff(scratch, "undone", "no file has such a canonical path")
  report_weird_stuff(scratch, "unspecific", "path is compatible with more than 1 file")

  n_empty_string <- sum(scratch$status == "empty_string")
  if (n_empty_string > 0) {
    drive_bullets(c(
      "!" = "Problem with {n_empty_string} path{?s}: \\
             path is empty string"
    ))
  }

  index <- unlist(scratch$m)
  dupes <- duplicated(index)
  if (any(dupes)) {
    multis <- vec_slice(candidates, unique(index[dupes]))

    drive_bullets(c(
      "!" = "{nrow(multis)} file{?s} in the output {?is/are} associated with \\
             more than 1 input {.arg path}",
      # these really should be sub-bullets, but not possible at this time
      bulletize(gargle_map_cli(multis), bullet = " ")
    ))
  }

  resolved <- scratch$status == "resolved"
  if (all(resolved)) {
    if (nrow(scratch) > 1) {
      b <- c(v = "All {nrow(scratch)} input {.arg path}s resolved to exactly \\
                  1 file.")
    } else {
      b <- c(v = "The input {.arg path} resolved to exactly 1 file.")
    }
  } else if (any(resolved)) {
    b <- c("!" = "{sum(scratch$status == 'resolved')} out of {nrow(scratch)} \\
                  input paths resolved to exactly 1 file.")
  } else {
    # TODO: this wording is not great, yet I don't know what would be better
    b <- c("!" = "No path resolved to exactly 1 file.")
  }
  drive_bullets(b)

  vec_slice(candidates, index[!dupes])
}

get_by_name <- function(names, shared_drive = NULL, corpus = NULL) {
  nms <- strip_slash(unique(names))
  is_root <- nms == "~"
  nms <- nms[!is_root]
  q_clauses <- glue("name = {sq(nms)}")

  # fields <-
  #   c("kind", "id", "name", "mimeType", "parents", "shortcutDetails", "driveId")
  if (length(q_clauses) == 0) {
    found <- dribble()
  } else {
    found <- drive_find(
      q = or(q_clauses),
      # fields = prep_fields(fields),
      shared_drive = shared_drive, corpus = corpus
    )
  }

  if (any(is_root)) {
    found <- vec_rbind(root_folder(), found)
  }

  found
}

# you might think this can be merged with partition_path(), but their purposes
# are different enough that it's not worth it
get_last_path_part <- function(path) {
  stopifnot(is_path(path))
  path <- rootize_path(path)

  # NOTE: we ignore (but retain) a trailing slash
  # why? googledrive encourages the user to use a trailing slash to explicitly
  # indicate a path that refers to a folder
  slash_pos <- gregexpr(pattern = "/.", path)
  no_slash <- map_lgl(slash_pos, ~ all(.x == -1))
  last_slash <- map_int(slash_pos, max)
  ifelse(no_slash, path, substr(path, last_slash + 1, nchar(path)))
}
