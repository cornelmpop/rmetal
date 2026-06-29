.rmetal_cache_root <- function() {
  opt <- getOption("rmetal.cache_dir", NULL)
  candidates <- c(opt, tryCatch(tools::R_user_dir("rmetal", "cache"),
                                error = function(e) NULL), tempdir())
  for (path in candidates[nzchar(candidates)]) {
    path <- path.expand(path)
    ok <- dir.exists(path) || dir.create(path, recursive = TRUE,
                                         showWarnings = FALSE)
    if (isTRUE(ok) && file.access(path, 2) == 0) {
      return(normalizePath(path, mustWork = TRUE))
    }
  }
  tempdir()
}

.rmetal_viewer_source <- function() {
  system.file("swift", "RMetalViewer.swift", package = "rmetal",
              mustWork = TRUE)
}

.rmetal_viewer_exe <- function() {
  file.path(.rmetal_viewer_bundle(), "Contents", "MacOS", "rmetal-viewer")
}

.rmetal_viewer_stamp <- function() {
  file.path(.rmetal_viewer_bundle(), "Contents", "Resources",
            "rmetal-viewer.md5")
}

.rmetal_viewer_bundle <- function() {
  file.path(.rmetal_cache_root(), "rmetal-viewer.app")
}

.rmetal_write_viewer_plist <- function() {
  plist <- file.path(.rmetal_viewer_bundle(), "Contents", "Info.plist")
  if (!file.exists(plist)) {
    writeLines(c(
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" ",
      "\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">",
      "<plist version=\"1.0\">",
      "<dict>",
      "  <key>CFBundleExecutable</key>",
      "  <string>rmetal-viewer</string>",
      "  <key>CFBundleIdentifier</key>",
      "  <string>org.rmetal.viewer</string>",
      "  <key>CFBundleName</key>",
      "  <string>rmetal</string>",
      "  <key>CFBundlePackageType</key>",
      "  <string>APPL</string>",
      "  <key>LSMinimumSystemVersion</key>",
      "  <string>13.0</string>",
      "</dict>",
      "</plist>"
    ), plist)
  }
}

.rmetal_viewer_compile <- function() {
  source <- .rmetal_viewer_source()
  exe <- .rmetal_viewer_exe()
  dir.create(dirname(exe), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(.rmetal_viewer_bundle(), "Contents", "Resources"),
             recursive = TRUE, showWarnings = FALSE)
  .rmetal_write_viewer_plist()

  stamp <- .rmetal_viewer_stamp()
  source_hash <- unname(tools::md5sum(source))
  cached_hash <- tryCatch(suppressWarnings(readLines(stamp, warn = FALSE,
                                                     n = 1L)),
                          error = function(e) character())
  if (file.exists(exe) && length(cached_hash) &&
      identical(cached_hash[[1L]], source_hash)) {
    return(exe)
  }

  swiftc <- Sys.which("swiftc")
  if (!nzchar(swiftc)) {
    stop("Cannot build rmetal viewer because swiftc is not on PATH.",
         call. = FALSE)
  }

  module_cache <- file.path(.rmetal_cache_root(), "clang-module-cache")
  dir.create(module_cache, recursive = TRUE, showWarnings = FALSE)
  if (isTRUE(getOption("rmetal.verbose", interactive()))) {
    message("Building rmetal RealityKit viewer. This is a one-time compile ",
            "for this cache.")
  }
  status <- system2(swiftc,
                    args = c("-O", "-framework", "AppKit",
                             "-framework", "RealityKit", source, "-o", exe),
                    env = c(paste0("CLANG_MODULE_CACHE_PATH=", module_cache)),
                    stdout = TRUE, stderr = TRUE)
  exit <- attr(status, "status") %||% 0L
  if (!identical(as.integer(exit), 0L)) {
    stop("Failed to build rmetal RealityKit viewer:\n",
         paste(status, collapse = "\n"), call. = FALSE)
  }
  Sys.chmod(exe, mode = "0755")
  writeLines(source_hash, stamp)
  exe
}

.rmetal_viewer_file <- function() {
  file <- .rmetal_state$viewer_file
  if (is.null(file) || !nzchar(file)) {
    file <- file.path(tempdir(), paste0("rmetal-scene-",
                                        Sys.getpid(), ".json"))
    file <- normalizePath(file, mustWork = FALSE)
    .rmetal_state$viewer_file <- file
  }
  file
}

.rmetal_heartbeat_file <- function(file = .rmetal_viewer_file()) {
  paste0(file, ".heartbeat")
}

.rmetal_command_file <- function(file = .rmetal_viewer_file()) {
  paste0(file, ".command.json")
}

.rmetal_selection_file <- function(file = .rmetal_viewer_file()) {
  paste0(file, ".selection.json")
}

.rmetal_viewer_alive <- function(file = .rmetal_viewer_file()) {
  heartbeat <- .rmetal_heartbeat_file(file)
  if (!file.exists(heartbeat)) {
    return(FALSE)
  }
  age <- as.numeric(difftime(Sys.time(), file.info(heartbeat)$mtime,
                             units = "secs"))
  line <- tryCatch(readLines(heartbeat, warn = FALSE, n = 1L),
                   error = function(e) character())
  line <- if (length(line)) line[[1L]] else ""
  pid <- suppressWarnings(as.integer(strsplit(line, "[[:space:]]+")[[1]][1]))
  pid_alive <- is.na(pid) || tools::pskill(pid, signal = 0)
  pid_alive && is.finite(age) &&
    age < getOption("rmetal.viewer_timeout", 15)
}

.rmetal_viewer_pid <- function(file = .rmetal_viewer_file()) {
  heartbeat <- .rmetal_heartbeat_file(file)
  if (!file.exists(heartbeat)) {
    return(NA_integer_)
  }
  line <- tryCatch(suppressWarnings(readLines(heartbeat, warn = FALSE, n = 1L)),
                   error = function(e) character())
  if (!length(line)) {
    return(NA_integer_)
  }
  suppressWarnings(as.integer(strsplit(line[[1L]], "[[:space:]]+")[[1]][1]))
}

.rmetal_viewer_starting <- function() {
  if (!isTRUE(.rmetal_state$viewer_started)) {
    return(FALSE)
  }
  launch_time <- .rmetal_state$viewer_launch_time
  if (is.null(launch_time)) {
    return(FALSE)
  }
  age <- as.numeric(difftime(Sys.time(), launch_time, units = "secs"))
  is.finite(age) && age < getOption("rmetal.viewer_startup_timeout", 10)
}

.rmetal_reset_viewer_files <- function(file = .rmetal_viewer_file()) {
  unlink(c(.rmetal_heartbeat_file(file), .rmetal_command_file(file),
           .rmetal_selection_file(file)),
         force = TRUE)
  invisible(NULL)
}

.rmetal_forget_viewer <- function(file = .rmetal_viewer_file(),
                                  reset_files = TRUE) {
  if (isTRUE(reset_files)) {
    .rmetal_reset_viewer_files(file)
  }
  .rmetal_state$viewer_started <- FALSE
  .rmetal_state$viewer_launch_time <- NULL
  .rmetal_state$last_selection_ray <- NULL
  invisible(NULL)
}

.rmetal_close_viewer <- function(file = .rmetal_viewer_file()) {
  file <- normalizePath(file, mustWork = FALSE)
  if (.rmetal_viewer_alive(file)) {
    pid <- .rmetal_viewer_pid(file)
    .rmetal_write_viewer_command("closeViewer", file = file)
    started <- Sys.time()
    while (.rmetal_viewer_alive(file) &&
           as.numeric(difftime(Sys.time(), started, units = "secs")) < 1.5) {
      Sys.sleep(0.05)
    }
  } else {
    pid <- NA_integer_
  }
  if (.rmetal_viewer_alive(file) && !is.na(pid)) {
    try(tools::pskill(pid, signal = 15), silent = TRUE)
    started <- Sys.time()
    while (.rmetal_viewer_alive(file) &&
           as.numeric(difftime(Sys.time(), started, units = "secs")) < 0.5) {
      Sys.sleep(0.05)
    }
  }
  .rmetal_forget_viewer(file)
}

.rmetal_prepare_draw <- function() {
  if (.rmetal_should_autoshow() &&
      isTRUE(.rmetal_state$viewer_started) &&
      !.rmetal_viewer_alive() &&
      !.rmetal_viewer_starting()) {
    .rmetal_reset_viewer_files()
    .rmetal_dispatch("open", list())
    .rmetal_state$viewer_started <- FALSE
    .rmetal_state$viewer_launch_time <- NULL
  }
  invisible(NULL)
}

.rmetal_should_autoshow <- function() {
  isTRUE(getOption("rmetal.autoshow", interactive())) &&
    !identical(Sys.getenv("TESTTHAT"), "true") &&
    !isTRUE(getOption("knitr.in.progress")) &&
    !identical(tolower(Sys.getenv("RMETAL_DISABLE_VIEWER")), "true")
}

.rmetal_write_viewer_command <- function(action, payload = NULL,
                                         file = .rmetal_viewer_file(), ...) {
  .rmetal_state$viewer_command_seq <- .rmetal_state$viewer_command_seq + 1L
  command <- list(seq = .rmetal_state$viewer_command_seq,
                  action = action, payload = payload,
                  timestamp = as.numeric(Sys.time()))
  extra <- list(...)
  if (length(extra)) {
    command <- c(command, extra)
  }
  write(as.character(.rmetal_json(command)), .rmetal_command_file(file),
        append = TRUE)
  invisible(NULL)
}

.rmetal_wait_for_viewer <- function(file = .rmetal_viewer_file(),
                                    timeout = getOption("rmetal.viewer_timeout",
                                                        15)) {
  start <- Sys.time()
  while (!.rmetal_viewer_alive(file)) {
    if (is.finite(timeout) &&
        as.numeric(difftime(Sys.time(), start, units = "secs")) > timeout) {
      return(FALSE)
    }
    Sys.sleep(0.05)
  }
  TRUE
}

.rmetal_present_if_needed <- function(force = FALSE, object = NULL) {
  if (force || .rmetal_should_autoshow()) {
    tryCatch({
      launch <- .rmetal_should_autoshow()
      alive <- launch && .rmetal_viewer_alive()
      if (!force && alive && !is.null(object)) {
        .rmetal_write_viewer_command("addObject", object)
      } else if (!force && launch && .rmetal_viewer_starting()) {
        rmetal_show(launch = FALSE)
      } else {
        rmetal_show(launch = launch)
      }
    },
             error = function(e) {
               .rmetal_state$viewer_error <- conditionMessage(e)
               if (!isTRUE(.rmetal_state$viewer_warned)) {
                 warning("Could not present rmetal scene: ",
                         conditionMessage(e), call. = FALSE)
                 .rmetal_state$viewer_warned <- TRUE
               }
             })
  }
  invisible(NULL)
}

#' Write and optionally present the current scene in the RealityKit viewer.
#'
#' @param scene Scene object returned by [scene3d()].
#' @param file JSON file used to communicate with the viewer.
#' @param launch Whether to launch the viewer process if it is not already
#'   running for this R session.
#' @return The scene JSON file path, invisibly.
rmetal_show <- function(scene = scene3d(), file = .rmetal_viewer_file(),
                        launch = interactive()) {
  rmetal_save_scene_json(file, scene = scene, pretty = FALSE)

  if (isTRUE(launch) && !.rmetal_viewer_alive(file)) {
    exe <- .rmetal_viewer_compile()
    scene_file <- normalizePath(file, mustWork = TRUE)
    heartbeat_file <- .rmetal_heartbeat_file(scene_file)
    command_file <- .rmetal_command_file(scene_file)
    unlink(command_file, force = TRUE)
    .rmetal_state$viewer_command_seq <- 0L
    opener <- Sys.which("open")
    if (nzchar(opener)) {
      system2(opener, args = c("-n", .rmetal_viewer_bundle(),
                               "--args", scene_file, heartbeat_file,
                               command_file),
              wait = FALSE, stdout = FALSE, stderr = FALSE)
    } else {
      system2(exe, args = c(scene_file, heartbeat_file, command_file),
              wait = FALSE,
              stdout = FALSE, stderr = FALSE)
    }
    .rmetal_state$viewer_started <- TRUE
    .rmetal_state$viewer_launch_time <- Sys.time()
  }

  invisible(normalizePath(file, mustWork = TRUE))
}

#' Return the compiled RealityKit viewer path.
#'
#' @return Path to the viewer executable, compiling it when needed.
rmetal_viewer_path <- function() {
  .rmetal_viewer_compile()
}

#' Check whether the RealityKit viewer can be compiled.
#'
#' @return `TRUE` if the viewer executable is available.
rmetal_viewer_available <- function() {
  isTRUE(file.exists(.rmetal_viewer_compile()))
}
