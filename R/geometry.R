.rmetal_xyz <- function(x, y = NULL, z = NULL) {
  if (inherits(x, "mesh3d")) {
    return(t(x$vb[1:3, , drop = FALSE]))
  }

  if (is.null(y) && is.null(z)) {
    if (is.data.frame(x)) {
      x <- as.matrix(x)
    }
    if (is.matrix(x)) {
      if (ncol(x) < 3L) {
        stop("Coordinate matrices must have at least 3 columns.", call. = FALSE)
      }
      out <- x[, 1:3, drop = FALSE]
    } else if (is.numeric(x) && length(x) == 3L) {
      out <- matrix(x, nrow = 1L)
    } else {
      stop("Expected coordinates as x/y/z vectors, a 3-column matrix, ",
           "or a mesh3d object.", call. = FALSE)
    }
  } else {
    if (is.null(y) || is.null(z)) {
      stop("x, y, and z must be supplied together.", call. = FALSE)
    }
    out <- cbind(x, y, z)
  }

  storage.mode(out) <- "double"
  colnames(out) <- c("x", "y", "z")
  out
}

.rmetal_rows <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  x <- as.matrix(x)
  storage.mode(x) <- "double"
  unname(x)
}

.rmetal_primary_object_types <- c("triangles", "quads", "points", "spheres",
                                  "lines", "planes")

.rmetal_scene_has_primary_objects <- function(scene = scene3d()) {
  objects <- scene$objects %||% list()
  if (!length(objects)) {
    return(FALSE)
  }
  any(vapply(objects, function(object) {
    isTRUE((object$type %||% "") %in% .rmetal_primary_object_types)
  }, logical(1)))
}

.rmetal_index_rows <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  x <- as.matrix(x)
  if (nrow(x) %in% c(2L, 3L, 4L) && ncol(x) > nrow(x)) {
    x <- t(x)
  }
  storage.mode(x) <- "integer"
  unname(x)
}

.rmetal_color_value <- function(color) {
  color <- color %||% "white"
  if (length(color) > 1L) {
    color <- color[[1L]]
  }
  rgb <- tryCatch(grDevices::col2rgb(color), error = function(e) NULL)
  if (is.null(rgb)) {
    return(as.character(color))
  }
  grDevices::rgb(rgb[1, 1], rgb[2, 1], rgb[3, 1], maxColorValue = 255)
}

.rmetal_material <- function(..., color = NULL, col = NULL, alpha = NULL,
                             size = NULL, lwd = NULL, radius = NULL) {
  dots <- list(...)
  if (is.null(color)) {
    color <- col %||% dots$color %||% dots$col
  }
  if (is.null(alpha)) {
    alpha <- dots$alpha
  }
  if (is.null(size)) {
    size <- dots$size
  }
  if (is.null(lwd)) {
    lwd <- dots$lwd
  }
  if (is.null(radius)) {
    radius <- dots$radius
  }

  out <- dots
  out$color <- .rmetal_color_value(color)
  out$alpha <- alpha %||% 1
  if (!is.null(size)) out$size <- size
  if (!is.null(lwd)) out$lwd <- lwd
  if (!is.null(radius)) out$radius <- radius
  out
}

.rmetal_mesh_geometry <- function(x) {
  if (!inherits(x, "mesh3d")) {
    stop("Expected a mesh3d object.", call. = FALSE)
  }
  vb <- as.matrix(x$vb)
  if (nrow(vb) < 3L) {
    stop("mesh3d object has no vertex buffer.", call. = FALSE)
  }
  vertices <- t(vb[1:3, , drop = FALSE])
  if (nrow(vb) >= 4L) {
    w <- vb[4, ]
    ok <- is.finite(w) & w != 0
    vertices[ok, ] <- vertices[ok, , drop = FALSE] / w[ok]
  }

  indices <- NULL
  primitive <- "triangles"
  if (!is.null(x$it)) {
    indices <- t(as.matrix(x$it))
    primitive <- "triangles"
  } else if (!is.null(x$ib)) {
    indices <- t(as.matrix(x$ib))
    primitive <- "quads"
  }

  list(primitive = primitive,
       vertices = .rmetal_rows(vertices),
       indices = .rmetal_index_rows(indices))
}

.rmetal_mesh_edges <- function(x) {
  geom <- .rmetal_mesh_geometry(x)
  idx <- geom$indices
  if (!length(idx)) {
    return(matrix(numeric(), ncol = 3L))
  }
  edges <- do.call(rbind, lapply(seq_len(nrow(idx)), function(i) {
    face <- idx[i, ]
    face <- face[!is.na(face)]
    cbind(face, c(face[-1], face[1]))
  }))
  edges <- t(apply(edges, 1L, sort))
  edges <- unique(edges)
  vertices <- geom$vertices
  out <- vector("list", nrow(edges) * 2L)
  j <- 1L
  for (i in seq_len(nrow(edges))) {
    out[[j]] <- vertices[edges[i, 1L], ]
    out[[j + 1L]] <- vertices[edges[i, 2L], ]
    j <- j + 2L
  }
  do.call(rbind, out)
}

.rmetal_add_object <- function(type, geometry = list(), material = list(),
                               tag = NULL, ..., present = TRUE) {
  .rmetal_prepare_draw()
  payload <- list(type = type,
                  geometry = .rmetal_json_object(geometry),
                  material = .rmetal_json_object(material))
  if (!is.null(tag)) payload$tag <- as.character(tag)
  extra <- list(...)
  if (length(extra)) payload$extra <- extra
  res <- .rmetal_dispatch("addObject", payload)
  id <- structure(as.integer(res$id), class = "rglId")
  payload$id <- as.integer(res$id)
  if (isTRUE(present)) {
    .rmetal_present_if_needed(object = payload)
  }
  id
}

.rmetal_make_mesh <- function(vertices, indices = NULL, material = NULL,
                              normals = NULL, texcoords = NULL,
                              homogeneous = TRUE, kind = "triangles",
                              meshColor = "vertices") {
  vertices <- as.matrix(vertices)
  if (homogeneous && nrow(vertices) == 3L) {
    vertices <- rbind(vertices, 1)
  } else if (!homogeneous && nrow(vertices) == 3L) {
    vertices <- rbind(vertices, 1)
  } else if (ncol(vertices) %in% c(3L, 4L) && nrow(vertices) > ncol(vertices)) {
    vertices <- t(vertices)
    if (nrow(vertices) == 3L) {
      vertices <- rbind(vertices, 1)
    }
  }
  out <- list(vb = vertices, material = material, normals = normals,
              texcoords = texcoords, meshColor = match.arg(meshColor))
  if (!is.null(indices)) {
    indices <- as.matrix(indices)
    if (kind == "triangles") out$it <- indices else out$ib <- indices
  }
  structure(out, class = c("mesh3d", "shape3d"))
}

mesh3d <- function(x, y = NULL, z = NULL, vertices, material = NULL,
                   normals = NULL, texcoords = NULL, points = NULL,
                   segments = NULL, triangles = NULL, quads = NULL,
                   meshColor = c("vertices", "edges", "faces", "legacy")) {
  meshColor <- match.arg(meshColor)
  if (missing(vertices)) {
    coords <- .rmetal_xyz(x, y, z)
    vertices <- rbind(t(coords), 1)
  }
  out <- .rmetal_make_mesh(vertices, material = material, normals = normals,
                           texcoords = texcoords, meshColor = meshColor)
  if (!is.null(points)) out$ip <- points
  if (!is.null(segments)) out$is <- segments
  if (!is.null(triangles)) out$it <- triangles
  if (!is.null(quads)) out$ib <- quads
  out
}

tmesh3d <- function(vertices, indices, homogeneous = TRUE, material = NULL,
                    normals = NULL, texcoords = NULL,
                    meshColor = c("vertices", "edges", "faces", "legacy")) {
  .rmetal_make_mesh(vertices, indices, material, normals, texcoords,
                    homogeneous, "triangles", match.arg(meshColor))
}

qmesh3d <- function(vertices, indices, homogeneous = TRUE, material = NULL,
                    normals = NULL, texcoords = NULL,
                    meshColor = c("vertices", "edges", "faces", "legacy")) {
  .rmetal_make_mesh(vertices, indices, material, normals, texcoords,
                    homogeneous, "quads", match.arg(meshColor))
}

as.mesh3d <- function(x, ...) {
  if (inherits(x, "mesh3d")) x else stop("Cannot coerce object to mesh3d.",
                                         call. = FALSE)
}

as.tmesh3d <- as.mesh3d
as.qmesh3d <- as.mesh3d
