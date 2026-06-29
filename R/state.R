.rmetal_state <- new.env(parent = baseenv())
.rmetal_state$viewer_started <- FALSE
.rmetal_state$viewer_launch_time <- NULL
.rmetal_state$viewer_command_seq <- 0L
.rmetal_state$viewer_file <- NULL
.rmetal_state$viewer_error <- NULL
.rmetal_state$viewer_warned <- FALSE
.rmetal_state$last_selection_ray <- NULL

.rmetal_json <- function(x) {
  jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", digits = NA,
                   dataframe = "rows")
}

.rmetal_json_object <- function(x) {
  if (is.list(x) && !length(x) && is.null(names(x))) {
    return(structure(list(), names = character()))
  }
  x
}

.rmetal_dispatch <- function(action, payload = list()) {
  .rmetal_r_dispatch(action, payload)
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

rmetal_backend <- function() {
  list(scene_store = "R", viewer = "RealityKit")
}
