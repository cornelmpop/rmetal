.rmetal_r_default_par <- function() {
  list(
    scale = c(1, 1, 1),
    zoom = 1,
    FOV = 30,
    fov = 30,
    userMatrix = diag(4),
    mouseMode = c(none = "none", left = "trackball", right = "zoom",
                  middle = "fov", wheel = "pull")
  )
}

.rmetal_r_state <- new.env(parent = emptyenv())
.rmetal_r_state$scenes <- list()
.rmetal_r_state$current <- 0L
.rmetal_r_state$next_scene <- 1L
.rmetal_r_state$next_object <- 1L
.rmetal_r_state$par <- .rmetal_r_default_par()

.rmetal_r_ensure_scene <- function() {
  if (.rmetal_r_state$current == 0L ||
      is.null(.rmetal_r_state$scenes[[as.character(.rmetal_r_state$current)]])) {
    .rmetal_r_dispatch("open", list())
  }
  .rmetal_r_state$current
}

.rmetal_r_dispatch <- function(action, payload = list()) {
  switch(action,
    reset = {
      .rmetal_r_state$scenes <- list()
      .rmetal_r_state$current <- 0L
      list(reset = TRUE)
    },
    open = {
      id <- .rmetal_r_state$next_scene
      .rmetal_r_state$next_scene <- id + 1L
      .rmetal_r_state$current <- id
      .rmetal_r_state$par <- .rmetal_r_default_par()
      .rmetal_r_state$scenes[[as.character(id)]] <- list(
        id = id, backend = "R scene store + RealityKit viewer", objects = list(),
        par = .rmetal_r_state$par
      )
      list(id = id)
    },
    close = {
      id <- as.integer(payload$id %||% .rmetal_r_state$current)
      .rmetal_r_state$scenes[[as.character(id)]] <- NULL
      if (identical(.rmetal_r_state$current, id)) {
        ids <- as.integer(names(.rmetal_r_state$scenes))
        .rmetal_r_state$current <- if (length(ids)) ids[[length(ids)]] else 0L
        .rmetal_r_state$par <-
          .rmetal_r_state$scenes[[as.character(.rmetal_r_state$current)]]$par %||%
          .rmetal_r_default_par()
      }
      list(id = id)
    },
    current = list(id = .rmetal_r_state$current),
    addObject = {
      scene_id <- .rmetal_r_ensure_scene()
      obj <- payload
      obj$id <- .rmetal_r_state$next_object
      .rmetal_r_state$next_object <- obj$id + 1L
      scene <- .rmetal_r_state$scenes[[as.character(scene_id)]]
      scene$objects[[length(scene$objects) + 1L]] <- obj
      .rmetal_r_state$scenes[[as.character(scene_id)]] <- scene
      list(id = obj$id, scene = scene_id)
    },
    removeObject = {
      scene_id <- .rmetal_r_ensure_scene()
      ids <- as.integer(unlist(payload$ids %||% payload$id))
      scene <- .rmetal_r_state$scenes[[as.character(scene_id)]]
      keep <- !vapply(scene$objects, function(x) as.integer(x$id) %in% ids,
                      logical(1))
      scene$objects <- scene$objects[keep]
      .rmetal_r_state$scenes[[as.character(scene_id)]] <- scene
      list(ids = ids)
    },
    clear = {
      scene_id <- .rmetal_r_ensure_scene()
      scene <- .rmetal_r_state$scenes[[as.character(scene_id)]]
      scene$objects <- list()
      .rmetal_r_state$scenes[[as.character(scene_id)]] <- scene
      list(id = scene_id)
    },
    scene = {
      scene_id <- as.integer(payload$id %||% .rmetal_r_state$current)
      .rmetal_r_state$scenes[[as.character(scene_id)]] %||%
        list(id = 0L, backend = "R scene store + RealityKit viewer", objects = list(),
             par = .rmetal_r_state$par)
    },
    tagged = {
      scene_id <- .rmetal_r_ensure_scene()
      tags <- as.character(unlist(payload$tags))
      scene <- .rmetal_r_state$scenes[[as.character(scene_id)]]
      ids <- vapply(scene$objects, function(x) {
        if (!is.null(x$tag) && as.character(x$tag) %in% tags) {
          as.integer(x$id)
        } else {
          NA_integer_
        }
      }, integer(1))
      list(ids = stats::na.omit(ids))
    },
    ids = {
      scene_id <- .rmetal_r_ensure_scene()
      scene <- .rmetal_r_state$scenes[[as.character(scene_id)]]
      list(ids = lapply(scene$objects, function(x) {
        list(id = x$id, type = x$type %||% "unknown")
      }))
    },
    parGet = {
      scene_id <- .rmetal_r_ensure_scene()
      scene <- .rmetal_r_state$scenes[[as.character(scene_id)]]
      par <- scene$par %||% .rmetal_r_state$par
      keys <- payload$keys
      if (is.null(keys) || !length(keys)) {
        par
      } else {
        par[keys]
      }
    },
    parSet = {
      scene_id <- .rmetal_r_ensure_scene()
      scene <- .rmetal_r_state$scenes[[as.character(scene_id)]]
      par <- scene$par %||% .rmetal_r_state$par
      for (nm in names(payload$values)) {
        par[[nm]] <- payload$values[[nm]]
        if (identical(nm, "FOV")) {
          par$fov <- payload$values[[nm]]
        }
        if (identical(nm, "fov")) {
          par$FOV <- payload$values[[nm]]
        }
      }
      scene$par <- par
      .rmetal_r_state$scenes[[as.character(scene_id)]] <- scene
      .rmetal_r_state$par <- par
      list(values = par)
    },
    stop("Unknown rmetal fallback action: ", action, call. = FALSE)
  )
}
