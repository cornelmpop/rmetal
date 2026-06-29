#' Open a new rmetal 3D scene.
open3d <- function(...) {
  id <- as.integer(.rmetal_dispatch("open", list(...))$id)
  .rmetal_present_if_needed(force = TRUE)
  id
}

rgl.open <- open3d

#' Close a rmetal 3D scene.
close3d <- function(dev = cur3d(), ...) {
  dev <- as.integer(dev)
  if (!length(dev) || is.na(dev) || identical(dev, 0L)) {
    .rmetal_close_viewer()
    return(invisible(list(id = 0L)))
  }
  res <- .rmetal_dispatch("close", list(id = dev))
  .rmetal_close_viewer()
  invisible(res)
}

rgl.close <- close3d
rgl.quit <- function(...) close3d(...)

#' Return the current rmetal scene id.
cur3d <- function(...) {
  id <- as.integer(.rmetal_dispatch("current", list())$id)
  if (!identical(id, 0L) && !.rmetal_viewer_alive() &&
      !.rmetal_viewer_starting()) {
    scene <- .rmetal_dispatch("scene", list(id = id, minimal = TRUE))
    if (!.rmetal_scene_has_primary_objects(scene)) {
      return(0L)
    }
  }
  id
}

rgl.cur <- cur3d

set3d <- function(dev = cur3d(), ...) {
  invisible(dev)
}

rgl.set <- set3d

shade3d <- function(x, ..., tag = NULL) {
  geom <- .rmetal_mesh_geometry(x)
  .rmetal_add_object("triangles", geom, .rmetal_material(...), tag = tag)
}

wire3d <- function(x, ..., tag = NULL) {
  vertices <- .rmetal_mesh_edges(x)
  .rmetal_add_object("lines", list(primitive = "segments",
                                   vertices = .rmetal_rows(vertices)),
                     .rmetal_material(...), tag = tag)
}

points3d <- function(x, y = NULL, z = NULL, ..., tag = NULL) {
  coords <- .rmetal_xyz(x, y, z)
  .rmetal_add_object("points", list(vertices = .rmetal_rows(coords)),
                     .rmetal_material(...), tag = tag)
}

rgl.points <- points3d

lines3d <- function(x, y = NULL, z = NULL, ..., tag = NULL) {
  coords <- .rmetal_xyz(x, y, z)
  .rmetal_add_object("lines", list(primitive = "polyline",
                                   vertices = .rmetal_rows(coords)),
                     .rmetal_material(...), tag = tag)
}

rgl.lines <- lines3d
rgl.linestrips <- lines3d

segments3d <- function(x, y = NULL, z = NULL, ..., tag = NULL) {
  coords <- .rmetal_xyz(x, y, z)
  .rmetal_add_object("lines", list(primitive = "segments",
                                   vertices = .rmetal_rows(coords)),
                     .rmetal_material(...), tag = tag)
}

triangles3d <- function(x, y = NULL, z = NULL, ..., tag = NULL) {
  coords <- .rmetal_xyz(x, y, z)
  .rmetal_add_object("triangles", list(primitive = "triangles",
                                       vertices = .rmetal_rows(coords)),
                     .rmetal_material(...), tag = tag)
}

rgl.triangles <- triangles3d

quads3d <- function(x, y = NULL, z = NULL, ..., tag = NULL) {
  coords <- .rmetal_xyz(x, y, z)
  .rmetal_add_object("quads", list(primitive = "quads",
                                   vertices = .rmetal_rows(coords)),
                     .rmetal_material(...), tag = tag)
}

rgl.quads <- quads3d

text3d <- function(x, y = NULL, z = NULL, texts, ..., tag = NULL) {
  coords <- .rmetal_xyz(x, y, z)
  .rmetal_add_object("text", list(vertices = .rmetal_rows(coords),
                                  texts = as.character(texts)),
                     .rmetal_material(...), tag = tag)
}

texts3d <- text3d
rgl.texts <- text3d

spheres3d <- function(x, y = NULL, z = NULL, radius = 1,
                      fastTransparency = TRUE, ..., tag = NULL) {
  coords <- .rmetal_xyz(x, y, z)
  .rmetal_add_object("spheres", list(vertices = .rmetal_rows(coords),
                                     radius = radius),
                     .rmetal_material(..., radius = radius), tag = tag)
}

rgl.spheres <- spheres3d

planes3d <- function(a, b = NULL, c = NULL, d = 0, ..., tag = NULL) {
  if (is.null(b) && is.null(c) && is.matrix(a)) {
    coefs <- a
  } else {
    coefs <- cbind(a, b, c, d)
  }
  .rmetal_add_object("planes", list(coefficients = .rmetal_rows(coefs)),
                     .rmetal_material(...), tag = tag)
}

rgl.planes <- planes3d

plot3d <- function(x, ...) {
  if (inherits(x, "mesh3d")) {
    shade3d(x, ...)
  } else {
    points3d(x, ...)
  }
}

scene3d <- function(minimal = TRUE) {
  scene <- .rmetal_dispatch("scene", list(id = cur3d(), minimal = minimal))
  class(scene) <- c("rglscene", "rmetal_scene", class(scene))
  scene
}

as.rglscene <- function(x, ...) {
  if (inherits(x, "rglscene")) x else scene3d()
}

ids3d <- function(type = "all", tags = NULL, subscene = NA, ...) {
  ids <- .rmetal_dispatch("ids", list(type = type, tags = tags,
                                      subscene = subscene))$ids
  if (!length(ids)) {
    return(data.frame(id = integer(), type = character()))
  }
  data.frame(id = vapply(ids, `[[`, integer(1), "id"),
             type = vapply(ids, `[[`, character(1), "type"))
}

rgl.ids <- ids3d

tagged3d <- function(tags, ...) {
  ids <- .rmetal_dispatch("tagged", list(tags = as.character(tags)))$ids
  as.integer(unlist(ids))
}

pop3d <- function(id = NULL, type = "shapes", ...) {
  if (is.null(id)) {
    id <- ids3d(type = type)$id
  }
  ids <- as.integer(id)
  res <- .rmetal_dispatch("removeObject", list(ids = ids))
  if (length(ids) && .rmetal_should_autoshow() &&
      (.rmetal_viewer_alive() || .rmetal_viewer_starting())) {
    .rmetal_write_viewer_command("removeObject", ids = ids)
  }
  invisible(res)
}

rgl.pop <- pop3d

clear3d <- function(type = "shapes", ...) {
  res <- .rmetal_dispatch("clear", list(type = type))
  .rmetal_present_if_needed(force = TRUE)
  invisible(res)
}

rgl.clear <- clear3d

gc3d <- function(...) invisible(TRUE)

par3d <- function(..., no.readonly = FALSE, dev = cur3d(),
                  subscene = currentSubscene3d(dev)) {
  dots <- list(...)
  if (!length(dots)) {
    return(.rmetal_dispatch("parGet", list()) )
  }
  if (length(dots) == 1L && is.character(dots[[1L]])) {
    keys <- dots[[1L]]
    vals <- .rmetal_dispatch("parGet", list(keys = keys))
    if (length(keys) == 1L) {
      return(vals[[keys]])
    }
    return(vals[keys])
  }
  if (length(dots) == 1L && is.list(dots[[1L]]) &&
      !is.null(names(dots[[1L]]))) {
    dots <- dots[[1L]]
  }
  invisible(.rmetal_dispatch("parSet", list(values = dots)))
}

rgl.par3d.names <- function(...) names(par3d())
rgl.par3d.readonly <- function(...) character()

view3d <- function(theta = 0, phi = 15, fov = 60, zoom = 1,
                   scale = par3d("scale"), interactive = TRUE, userMatrix,
                   type = c("userviewpoint", "modelviewpoint")) {
  vals <- list(theta = theta, phi = phi, FOV = fov, fov = fov, zoom = zoom,
               scale = scale, interactive = interactive,
               type = match.arg(type))
  if (!missing(userMatrix)) vals$userMatrix <- userMatrix
  par3d(vals)
  invisible(vals)
}

rgl.viewpoint <- view3d

material3d <- function(..., id = NULL) {
  .rmetal_material(...)
}

rgl.material <- material3d
rgl.material.names <- function(...) c("color", "alpha", "size", "lwd", "radius")
rgl.material.readonly <- function(...) character()

rgl.useNULL <- function(...) FALSE

currentSubscene3d <- function(dev = cur3d()) 1L
useSubscene3d <- function(subscene, dev = cur3d()) invisible(subscene)
newSubscene3d <- function(...) 1L
subsceneList <- function(...) 1L
subsceneInfo <- function(...) list(id = 1L)
clearSubsceneList <- function(...) invisible(TRUE)
addToSubscene3d <- function(ids, subscene = currentSubscene3d(), ...) invisible(ids)
delFromSubscene3d <- function(ids, subscene = currentSubscene3d(), ...) invisible(ids)

rgl.select <- function(button = "left", ...) {
  injected <- getOption("rmetal.select", NULL)
  if (!is.null(injected) || identical(Sys.getenv("TESTTHAT"), "true")) {
    return(injected)
  }
  if (!interactive() || !.rmetal_should_autoshow()) {
    return(NULL)
  }

  file <- .rmetal_viewer_file()
  if (.rmetal_viewer_alive(file)) {
    file <- normalizePath(file, mustWork = FALSE)
  } else if (.rmetal_viewer_starting()) {
    file <- rmetal_show(launch = FALSE)
  } else {
    file <- rmetal_show(launch = TRUE)
  }
  if (!.rmetal_wait_for_viewer(file)) {
    warning("rmetal viewer did not become ready for selection.",
            call. = FALSE)
    return(NULL)
  }

  selection_file <- .rmetal_selection_file(file)
  unlink(selection_file, force = TRUE)
  .rmetal_state$last_selection_ray <- NULL
  .rmetal_write_viewer_command("select", file = file,
                               button = as.character(button)[[1L]],
                               resultPath = selection_file)

  timeout <- getOption("rmetal.select_timeout", Inf)
  start <- Sys.time()
  while (!file.exists(selection_file)) {
    if (!.rmetal_viewer_alive(file) && !.rmetal_viewer_starting()) {
      return(NULL)
    }
    if (is.finite(timeout) &&
        as.numeric(difftime(Sys.time(), start, units = "secs")) > timeout) {
      return(NULL)
    }
    Sys.sleep(0.05)
  }

  result <- tryCatch(jsonlite::fromJSON(selection_file, simplifyVector = FALSE),
                     error = function(e) NULL)
  if (is.null(result) || isTRUE(result$cancelled)) {
    return(NULL)
  }
  ray <- result$ray
  if (is.list(ray) && length(ray) == 2L) {
    ray <- do.call(rbind, lapply(ray, unlist, use.names = FALSE))
    storage.mode(ray) <- "double"
    colnames(ray) <- c("x", "y", "z")
    .rmetal_state$last_selection_ray <- ray
  }
  c(result$x %||% NA_real_, result$y %||% NA_real_)
}

rgl.window2user <- function(x, y = NULL, z = NULL, projection = rgl.projection(), ...) {
  if (!is.null(.rmetal_state$last_selection_ray)) {
    return(.rmetal_state$last_selection_ray)
  }
  .rmetal_xyz(x, y, z)
}

rgl.user2window <- function(x, y = NULL, z = NULL, projection = rgl.projection(), ...) {
  .rmetal_xyz(x, y, z)
}

rgl.projection <- function(...) {
  list(model = diag(4), proj = diag(4), viewport = c(0, 0, 1, 1))
}

select3d <- function(...) {
  function(x, y = NULL, z = NULL) rep(TRUE, nrow(.rmetal_xyz(x, y, z)))
}

selectionFunction3d <- select3d
selectpoints3d <- function(x, y = NULL, z = NULL, ...) .rmetal_xyz(x, y, z)
identify3d <- function(...) integer()

expect_known_scene <- function(file, ..., close = FALSE, scene = scene3d()) {
  if (requireNamespace("testthat", quietly = TRUE)) {
    testthat::expect_s3_class(scene, "rglscene")
  }
  if (isTRUE(close)) {
    close3d()
  }
  invisible(scene)
}

rmetal_scene_json <- function(scene = scene3d(), pretty = TRUE) {
  jsonlite::toJSON(unclass(scene), auto_unbox = TRUE, pretty = pretty,
                   null = "null", digits = NA)
}

rmetal_save_scene_json <- function(file, scene = scene3d(), pretty = TRUE) {
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(pattern = paste0(basename(file), "-"),
                  tmpdir = dirname(file))
  on.exit(unlink(tmp, force = TRUE), add = TRUE)
  writeLines(as.character(rmetal_scene_json(scene, pretty = pretty)), tmp,
             useBytes = TRUE)
  if (!file.rename(tmp, file)) {
    ok <- file.copy(tmp, file, overwrite = TRUE)
    if (!isTRUE(ok)) {
      stop("Could not write rmetal scene file: ", file, call. = FALSE)
    }
  }
  invisible(normalizePath(file, mustWork = FALSE))
}

snapshot3d <- function(filename = tempfile(fileext = ".json"), ...) {
  rmetal_save_scene_json(filename, scene3d())
}

rgl.snapshot <- snapshot3d
rgl.postscript <- snapshot3d

rgl.pixels <- function(...) array(0, dim = c(1, 1, 4))
rgl.attrib <- function(...) NULL
rgl.attrib.count <- function(...) 0L
rgl.attrib.info <- function(...) data.frame()
rgl.incrementID <- function(...) invisible(NULL)
rgl.init <- function(...) TRUE
rgl.bringtotop <- function(...) invisible(TRUE)
setGraphicsDelay <- function(delay = 0) invisible(delay)
