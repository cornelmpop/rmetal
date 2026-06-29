test_that("rmetal_show writes a scene file without launching in tests", {
  open3d()
  on.exit(close3d(), add = TRUE)
  points3d(c(0, 0, 0))

  file <- tempfile(fileext = ".json")
  out <- rmetal_show(file = file, launch = FALSE)
  expect_true(file.exists(out))
  scene <- jsonlite::fromJSON(out, simplifyVector = FALSE)
  expect_equal(scene$objects[[1]]$type, "points")
})

test_that("viewer meshes are double-sided without duplicate coplanar triangles", {
  source <- system.file("swift", "RMetalViewer.swift", package = "rmetal",
                        mustWork = TRUE)
  swift <- readLines(source, warn = FALSE)

  expect_true(any(grepl("material.faceCulling = .none", swift, fixed = TRUE)))
  expect_true(any(grepl("descriptor.primitives = .triangles(triangleIndices)",
                        swift, fixed = TRUE)))
  expect_false(any(grepl("doubleSidedIndices", swift, fixed = TRUE)))
})

test_that("viewer Swift source avoids known type-checker timeout patterns", {
  source <- system.file("swift", "RMetalViewer.swift", package = "rmetal",
                        mustWork = TRUE)
  swift <- readLines(source, warn = FALSE)
  text <- paste(swift, collapse = "\n")

  expect_true(grepl("older Swift toolchains can time out", text,
                    fixed = TRUE))
  expect_true(grepl("func planeVertices", text, fixed = TRUE))
  expect_false(grepl("point - u * size - v * size", text, fixed = TRUE))
  expect_false(grepl("Float(sqrt(2.0)) - len", text, fixed = TRUE))
})

test_that("empty scene payload objects encode as JSON objects", {
  ns <- asNamespace("rmetal")
  as_object <- get(".rmetal_json_object", ns)
  to_json <- get(".rmetal_json", ns)

  expect_equal(as.character(to_json(list(geometry = as_object(list())))),
               "{\"geometry\":{}}")
  expect_equal(as.character(to_json(list(material = as_object(list())))),
               "{\"material\":{}}")
})

test_that("viewer heartbeat controls relaunch decisions", {
  ns <- asNamespace("rmetal")
  file <- tempfile(fileext = ".json")
  heartbeat <- get(".rmetal_heartbeat_file", ns)(file)
  viewer_alive <- get(".rmetal_viewer_alive", ns)
  expect_false(viewer_alive(file))

  writeLines(paste(Sys.getpid(), as.numeric(Sys.time())), heartbeat)
  expect_true(viewer_alive(file))

  writeLines(paste(999999L, as.numeric(Sys.time())), heartbeat)
  expect_false(viewer_alive(file))
})

test_that("viewer commands are queued for rapid multi-object drawing", {
  ns <- asNamespace("rmetal")
  file <- tempfile(fileext = ".json")
  state <- get(".rmetal_state", ns)
  old_file <- state$viewer_file
  old_seq <- state$viewer_command_seq
  on.exit({
    state$viewer_file <- old_file
    state$viewer_command_seq <- old_seq
  }, add = TRUE)
  state$viewer_file <- file
  state$viewer_command_seq <- 0L

  write_command <- get(".rmetal_write_viewer_command", ns)
  write_command("addObject", list(type = "lines"))
  write_command("addObject", list(type = "text"))

  lines <- readLines(get(".rmetal_command_file", ns)(file), warn = FALSE)
  expect_length(lines, 2)
  decoded <- lapply(lines, jsonlite::fromJSON, simplifyVector = FALSE)
  expect_equal(vapply(decoded, `[[`, integer(1), "seq"), 1:2)
  expect_equal(vapply(decoded, function(x) x$payload$type, character(1)),
               c("lines", "text"))
})

test_that("selection commands carry button and result path metadata", {
  ns <- asNamespace("rmetal")
  file <- tempfile(fileext = ".json")
  result <- tempfile(fileext = ".json")
  state <- get(".rmetal_state", ns)
  old_file <- state$viewer_file
  old_seq <- state$viewer_command_seq
  on.exit({
    state$viewer_file <- old_file
    state$viewer_command_seq <- old_seq
  }, add = TRUE)
  state$viewer_file <- file
  state$viewer_command_seq <- 0L

  get(".rmetal_write_viewer_command", ns)("select", file = file,
                                          button = "right",
                                          resultPath = result)
  command <- jsonlite::fromJSON(readLines(get(".rmetal_command_file", ns)(file),
                                          warn = FALSE),
                                simplifyVector = FALSE)
  expect_equal(command$action, "select")
  expect_equal(command$button, "right")
  expect_equal(command$resultPath, result)
})

test_that("pop3d queues live removeObject commands", {
  ns <- asNamespace("rmetal")
  state <- get(".rmetal_state", ns)
  old_file <- state$viewer_file
  old_seq <- state$viewer_command_seq
  old_started <- state$viewer_started
  old_testthat <- Sys.getenv("TESTTHAT", unset = NA_character_)
  old_autoshow <- getOption("rmetal.autoshow")
  on.exit({
    state$viewer_file <- old_file
    state$viewer_command_seq <- old_seq
    state$viewer_started <- old_started
    if (is.na(old_testthat)) Sys.unsetenv("TESTTHAT") else Sys.setenv(TESTTHAT = old_testthat)
    options(rmetal.autoshow = old_autoshow)
  }, add = TRUE)

  file <- tempfile(fileext = ".json")
  state$viewer_file <- file
  state$viewer_command_seq <- 0L
  state$viewer_started <- TRUE
  Sys.unsetenv("TESTTHAT")
  options(rmetal.autoshow = TRUE)
  writeLines(paste(Sys.getpid(), as.numeric(Sys.time())),
             get(".rmetal_heartbeat_file", ns)(file))

  open3d()
  id <- points3d(matrix(c(1, 2, 3), nrow = 1), tag = 1)
  unlink(get(".rmetal_command_file", ns)(file), force = TRUE)
  pop3d(id = tagged3d(tags = 1))

  command <- jsonlite::fromJSON(readLines(get(".rmetal_command_file", ns)(file),
                                          warn = FALSE),
                                simplifyVector = FALSE)
  expect_equal(command$action, "removeObject")
  expect_equal(as.integer(command$ids), as.integer(id))
})

test_that("window2user returns cached selection ray when present", {
  ns <- asNamespace("rmetal")
  state <- get(".rmetal_state", ns)
  old_ray <- state$last_selection_ray
  on.exit(state$last_selection_ray <- old_ray, add = TRUE)

  ray <- matrix(c(1, 2, 3, 4, 5, 6), nrow = 2, byrow = TRUE)
  state$last_selection_ray <- ray
  expect_equal(rgl.window2user(c(10, 10), c(20, 20), c(0, 0.1)), ray)
})

test_that("viewer startup grace period distinguishes launch from close", {
  ns <- asNamespace("rmetal")
  state <- get(".rmetal_state", ns)
  old_started <- state$viewer_started
  old_launch_time <- state$viewer_launch_time
  on.exit({
    state$viewer_started <- old_started
    state$viewer_launch_time <- old_launch_time
  }, add = TRUE)

  starting <- get(".rmetal_viewer_starting", ns)
  state$viewer_started <- TRUE
  state$viewer_launch_time <- Sys.time()
  expect_true(starting())

  state$viewer_launch_time <- Sys.time() - 60
  expect_false(starting())
})

test_that("stale viewer state starts a fresh implicit scene before drawing", {
  ns <- asNamespace("rmetal")
  old_testthat <- Sys.getenv("TESTTHAT", unset = NA_character_)
  old_autoshow <- getOption("rmetal.autoshow")
  on.exit({
    if (is.na(old_testthat)) Sys.unsetenv("TESTTHAT") else Sys.setenv(TESTTHAT = old_testthat)
    options(rmetal.autoshow = old_autoshow)
  }, add = TRUE)

  open3d()
  points3d(c(0, 0, 0))
  expect_equal(length(scene3d()$objects), 1L)

  Sys.unsetenv("TESTTHAT")
  options(rmetal.autoshow = TRUE)
  state <- get(".rmetal_state", ns)
  state$viewer_started <- TRUE
  state$viewer_file <- tempfile(fileext = ".json")
  get(".rmetal_prepare_draw", ns)()
  expect_equal(length(scene3d()$objects), 0L)
})
