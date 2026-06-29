rmetal_live_viewer_tests_enabled <- function() {
  identical(tolower(Sys.getenv("RMETAL_RUN_LIVE_VIEWER_TESTS")), "true") &&
    identical(Sys.info()[["sysname"]], "Darwin")
}

expect_live_viewer_scene_loaded <- function(code, expected_objects,
                                            timeout = 20) {
  testthat::skip_if_not(rmetal_live_viewer_tests_enabled(),
                        "live RealityKit viewer tests are opt-in")
  testthat::skip_if_not(rmetal_viewer_available(),
                        "RealityKit viewer is not available")

  ns <- asNamespace("rmetal")
  old_autoshow <- getOption("rmetal.autoshow")
  old_testthat <- Sys.getenv("TESTTHAT", unset = NA_character_)
  on.exit({
    options(rmetal.autoshow = old_autoshow)
    if (is.na(old_testthat)) {
      Sys.unsetenv("TESTTHAT")
    } else {
      Sys.setenv(TESTTHAT = old_testthat)
    }
    close3d()
  }, add = TRUE)

  options(rmetal.autoshow = TRUE)
  Sys.unsetenv("TESTTHAT")
  eval.parent(substitute(code))

  scene_file <- get(".rmetal_viewer_file", ns)()
  log_file <- paste0(scene_file, ".viewer.log")
  started <- Sys.time()
  lines <- character()
  repeat {
    if (file.exists(log_file)) {
      lines <- readLines(log_file, warn = FALSE)
      add_commands <- sum(grepl("command addObject", lines, fixed = TRUE))
      loaded_objects <- rmetal_viewer_loaded_object_count(lines)
      if (any(grepl("loadScene complete", lines, fixed = TRUE)) &&
          loaded_objects + add_commands >= expected_objects) {
        break
      }
    }
    if (as.numeric(difftime(Sys.time(), started, units = "secs")) > timeout) {
      break
    }
    Sys.sleep(0.05)
  }

  testthat::expect_true(
    !any(grepl("loadScene decode failed", lines, fixed = TRUE)),
    info = paste("viewer log:", log_file)
  )
  testthat::expect_true(
    any(grepl("loadScene complete", lines, fixed = TRUE)),
    info = paste("viewer log:", log_file)
  )
  testthat::expect_true(
    rmetal_viewer_loaded_object_count(lines) +
      sum(grepl("command addObject", lines, fixed = TRUE)) >=
      expected_objects,
    info = paste("viewer log:", log_file)
  )
  invisible(log_file)
}

rmetal_viewer_loaded_object_count <- function(lines) {
  matches <- regmatches(
    lines,
    regexec("loadScene complete objects=([0-9]+)", lines)
  )
  counts <- vapply(matches, function(match) {
    if (length(match) >= 2L) as.integer(match[[2L]]) else NA_integer_
  }, integer(1))
  counts <- counts[!is.na(counts)]
  if (length(counts)) max(counts) else 0L
}
