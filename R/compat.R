.rmetal_unsupported <- function(name) {
  force(name)
  function(...) {
    warning("rmetal does not yet implement rgl::", name,
            "(); returning a compatibility no-op.", call. = FALSE)
    invisible(NULL)
  }
}

.rmetal_rgl_exports <- c(
  ".check3d", "%>%", "%||%", "abclines3d", "addNormals", "addToSubscene3d",
  "ageControl", "arc3d", "arrow3d", "as.mesh3d", "as.rglscene",
  "as.tmesh3d", "as.triangles3d", "asEuclidean", "asEuclidean2",
  "asHomogeneous", "asHomogeneous2", "asRow", "axes3d", "axis3d",
  "bbox3d", "bg3d", "bgplot3d", "box3d", "Buffer", "checkDeldir",
  "clear3d", "clearSubsceneList", "clipMesh3d", "clipObj3d",
  "clipplaneControl", "clipplanes3d", "close3d", "compare_proxy.mesh3d",
  "contourLines3d", "cube3d", "cuboctahedron3d", "cur3d",
  "currentSubscene3d", "cylinder3d", "decorate3d", "deform.mesh3d",
  "delFromSubscene3d", "divide.mesh3d", "dodecahedron3d", "dot3d",
  "drape3d", "elementId2Prefix", "ellipse3d", "expect_known_scene",
  "extrude3d", "facing3d", "figHeight", "figWidth", "filledContour3d",
  "gc3d", "getBoundary3d", "getr3dDefaults", "getShaders",
  "getWidgetId", "gltfTypes", "GramSchmidt", "grid3d", "highlevel",
  "hook_rgl", "hook_webgl", "hover3d", "icosahedron3d", "identify3d",
  "identityMatrix", "ids3d", "in_pkgdown", "in_pkgdown_example",
  "layout3d", "legend3d", "light3d", "lines3d", "lowlevel",
  "makeDependency", "material3d", "mergeVertices", "mesh3d",
  "mfrow3d", "movie3d", "mtext3d", "newSubscene3d", "next3d",
  "normalize.mesh3d", "observer3d", "octahedron3d", "oh3d", "open3d",
  "par3d", "par3dinterp", "par3dinterpControl", "particles3d",
  "pch3d", "persp3d", "planes3d", "play3d", "playwidget",
  "playwidgetOutput", "plot3d", "plotmath3d", "points3d", "polygon3d",
  "pop3d", "projectDown", "propertyControl", "qmesh3d", "quads3d",
  "r3dDefaults", "readOBJ", "readSTL", "registerSceneChange",
  "renderPlaywidget", "renderRglwidget", "rgl.abclines", "rgl.attrib",
  "rgl.attrib.count", "rgl.attrib.info", "rgl.bbox", "rgl.bg",
  "rgl.bringtotop", "rgl.clear", "rgl.clipplanes", "rgl.close",
  "rgl.cur", "rgl.dev.list", "rgl.getAxisCallback",
  "rgl.getMouseCallbacks", "rgl.getWheelCallback", "rgl.ids",
  "rgl.incrementID", "rgl.init", "rgl.light", "rgl.lines",
  "rgl.linestrips", "rgl.material", "rgl.material.names",
  "rgl.material.readonly", "rgl.open", "rgl.par3d.names",
  "rgl.par3d.readonly", "rgl.pixels", "rgl.planes", "rgl.points",
  "rgl.pop", "rgl.postscript", "rgl.primitive", "rgl.projection",
  "rgl.quads", "rgl.quit", "rgl.select", "rgl.select3d", "rgl.set",
  "rgl.setAxisCallback", "rgl.setMouseCallbacks", "rgl.setWheelCallback",
  "rgl.snapshot", "rgl.spheres", "rgl.sprites", "rgl.surface",
  "rgl.Sweave", "rgl.Sweave.off", "rgl.texts", "rgl.triangles",
  "rgl.useNULL", "rgl.user2window", "rgl.viewpoint", "rgl.window2user",
  "rglExtrafonts", "rglFonts", "rglId", "rglMouse", "rglShared",
  "rglToBase", "rglToLattice", "rglwidget", "rglwidgetOutput",
  "rotate3d", "rotationMatrix", "safe.dev.off", "scale3d",
  "scaleMatrix", "scene3d", "sceneChange", "segments3d", "select3d",
  "selectionFunction3d", "selectpoints3d", "set3d", "setAxisCallbacks",
  "setGraphicsDelay", "setupKnitr", "setUserCallbacks", "setUserShaders",
  "shade3d", "shadow3d", "shapelist3d", "shinyGetPar3d",
  "shinyResetBrush", "shinySetPar3d", "show2d", "snapshot3d",
  "spheres3d", "spin3d", "sprites3d", "subdivision3d", "subsceneInfo",
  "subsceneList", "subsetControl", "surface3d", "Sweave.snapshot",
  "tagged3d", "terrain3d", "tetrahedron3d", "text3d", "texts3d",
  "textureSource", "thigmophobe3d", "title3d", "tkpar3dsave",
  "tkspin3d", "tkspinControl", "tmesh3d", "toggleWidget", "transform3d",
  "translate3d", "translationMatrix", "triangles3d", "triangulate",
  "turn3d", "useSubscene3d", "vertexControl", "view3d", "wire3d",
  "writeASY", "writeOBJ", "writePLY", "writeSTL", "writeWebGL"
)

.rmetal_implemented_exports <- c(
  "%||%", "as.mesh3d", "as.qmesh3d", "as.rglscene", "as.tmesh3d",
  "asEuclidean", "asEuclidean2", "asHomogeneous", "asHomogeneous2",
  "asRow", "clear3d", "close3d", "create_rgl_compat_package", "cube3d",
  "cur3d", "figHeight", "figWidth", "GramSchmidt", "identityMatrix",
  "ids3d", "in_pkgdown", "in_pkgdown_example", "lines3d", "material3d",
  "mesh3d", "next3d", "normalize.mesh3d", "oh3d", "open3d", "par3d",
  "planes3d", "plot3d", "points3d", "pop3d", "qmesh3d", "quads3d",
  "rgl.clear", "rgl.close", "rgl.cur", "rgl.dev.list", "rgl.ids",
  "rgl.lines", "rgl.linestrips", "rgl.material", "rgl.material.names",
  "rgl.material.readonly", "rgl.open", "rgl.planes", "rgl.points",
  "rgl.pop", "rgl.postscript", "rgl.quads", "rgl.quit", "rgl.snapshot",
  "rgl.spheres", "rgl.set", "rgl.texts", "rgl.triangles", "rgl.useNULL",
  "rgl.viewpoint", "rmetal_backend",
  "rmetal_save_scene_json", "rmetal_scene_json", "rmetal_show",
  "rmetal_viewer_available", "rmetal_viewer_path", "rotate3d",
  "rotationMatrix", "safe.dev.off", "scale3d", "scaleMatrix", "scene3d",
  "segments3d", "set3d", "shade3d", "shapelist3d", "snapshot3d",
  "spheres3d", "tagged3d", "tetrahedron3d", "text3d", "texts3d",
  "tmesh3d", "transform3d", "translate3d", "translationMatrix",
  "triangles3d", "use_rmetal_in_package", "view3d", "wire3d"
)

.rmetal_partial_exports <- c(
  "abclines3d", "addNormals", "addToSubscene3d", "arc3d", "arrow3d",
  "axes3d", "axis3d", "bbox3d", "bg3d", "box3d", "clearSubsceneList",
  "clipMesh3d", "clipObj3d", "contourLines3d", "cuboctahedron3d",
  "currentSubscene3d", "decorate3d", "deform.mesh3d", "delFromSubscene3d",
  "divide.mesh3d", "dodecahedron3d", "dot3d", "drape3d", "extrude3d",
  "facing3d", "filledContour3d", "gc3d", "getr3dDefaults", "grid3d",
  "highlevel", "identify3d", "icosahedron3d", "legend3d", "light3d",
  "lowlevel", "mergeVertices", "mtext3d", "newSubscene3d",
  "observer3d", "octahedron3d", "particles3d", "pch3d", "persp3d",
  "polygon3d", "r3dDefaults", "rgl.attrib", "rgl.attrib.count",
  "rgl.attrib.info", "rgl.bg", "rgl.bringtotop", "rgl.clipplanes",
  "rgl.incrementID", "rgl.init", "rgl.light", "rgl.pixels",
  "rgl.primitive", "rgl.projection", "rgl.select", "rgl.spheres",
  "rgl.sprites", "rgl.surface", "rgl.user2window", "rgl.window2user",
  "select3d", "selectionFunction3d", "selectpoints3d", "setGraphicsDelay",
  "shadow3d", "sprites3d", "subdivision3d", "subsceneInfo",
  "subsceneList", "surface3d", "terrain3d", "title3d", "useSubscene3d"
)

rmetal_compatibility_status <- function() {
  exported <- sort(unique(c(.rmetal_rgl_exports,
                            .rmetal_implemented_exports,
                            .rmetal_partial_exports,
                            "create_rgl_compat_package",
                            "rmetal_backend",
                            "rmetal_compatibility_status",
                            "rmetal_save_scene_json",
                            "rmetal_scene_json",
                            "rmetal_show",
                            "rmetal_viewer_available",
                            "rmetal_viewer_path",
                            "use_rmetal_in_package")))
  status <- rep("not implemented", length(exported))
  status[exported %in% .rmetal_partial_exports] <- "partial"
  status[exported %in% .rmetal_implemented_exports] <- "implemented"
  notes <- ifelse(status == "implemented",
                  "Implemented for the rmetal scene store and RealityKit viewer.",
                  ifelse(status == "partial",
                         "Compatibility behavior is limited; see ?rmetal_compatibility_status.",
                         "Compatibility stub that warns and returns invisibly."))
  data.frame(function_name = exported, status = status, notes = notes,
             stringsAsFactors = FALSE)
}

.rmetal_register_compat <- function() {
  ns <- topenv(parent.frame())
  for (nm in .rmetal_rgl_exports) {
    if (!exists(nm, envir = ns, inherits = FALSE)) {
      assign(nm, .rmetal_unsupported(nm), envir = ns)
    }
  }
}

.rmetal_register_compat()

rgl.dev.list <- function(...) {
  id <- cur3d()
  if (id == 0L) NULL else structure(id, names = "rmetal")
}

safe.dev.off <- function(...) invisible(TRUE)
next3d <- function(...) cur3d()
oh3d <- function(...) open3d(...)
figWidth <- function(...) 7
figHeight <- function(...) 7
in_pkgdown <- function(...) FALSE
in_pkgdown_example <- function(...) FALSE
getr3dDefaults <- function(...) list()
r3dDefaults <- new.env(parent = emptyenv())
highlevel <- function(...) invisible(NULL)
lowlevel <- function(...) invisible(NULL)
shapelist3d <- function(...) list(...)
rglId <- function(id, type = NA_character_) structure(list(id = id, type = type),
                                                      class = "rglId")
