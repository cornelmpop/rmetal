import AppKit
import Foundation
import RealityKit
import simd

struct SceneFile: Decodable {
  var id: Int?
  var backend: String?
  var objects: [SceneObject]
  var par: ParSpec?
}

struct ParSpec: Decodable {
  var zoom: Double?
  var fov: Double?
  var FOV: Double?
  var theta: Double?
  var phi: Double?
  var userMatrix: [[Double]]?
}

struct SceneObject: Decodable {
  var id: Int?
  var type: String
  var geometry: Geometry?
  var material: MaterialSpec?
  var tag: String?

  enum CodingKeys: String, CodingKey {
    case id
    case type
    case geometry
    case material
    case tag
  }

  init(id: Int?, type: String, geometry: Geometry?,
       material: MaterialSpec?, tag: String?) {
    self.id = id
    self.type = type
    self.geometry = geometry
    self.material = material
    self.tag = tag
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try? container.decode(Int.self, forKey: .id)
    type = (try? container.decode(String.self, forKey: .type)) ?? "unknown"
    geometry = try? container.decode(Geometry.self, forKey: .geometry)
    material = try? container.decode(MaterialSpec.self, forKey: .material)
    if let value = try? container.decode(String.self, forKey: .tag) {
      tag = value
    } else if let value = try? container.decode(Int.self, forKey: .tag) {
      tag = "\(value)"
    } else {
      tag = nil
    }
  }
}

struct SceneCommand: Decodable {
  var seq: Int?
  var action: String
  var payload: SceneObject?
  var ids: [Int]?
  var button: String?
  var resultPath: String?
  var timestamp: Double?

  enum CodingKeys: String, CodingKey {
    case seq
    case action
    case payload
    case ids
    case button
    case resultPath
    case timestamp
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    seq = try? container.decode(Int.self, forKey: .seq)
    action = try container.decode(String.self, forKey: .action)
    payload = try? container.decode(SceneObject.self, forKey: .payload)
    ids = Self.decodeInts(container, key: .ids)
    button = try? container.decode(String.self, forKey: .button)
    resultPath = try? container.decode(String.self, forKey: .resultPath)
    timestamp = try? container.decode(Double.self, forKey: .timestamp)
  }

  static func decodeInts(_ container: KeyedDecodingContainer<CodingKeys>,
                         key: CodingKeys) -> [Int]? {
    if let values = try? container.decode([Int].self, forKey: key) {
      return values
    }
    if let value = try? container.decode(Int.self, forKey: key) {
      return [value]
    }
    return nil
  }
}

struct Geometry: Decodable {
  var primitive: String?
  var vertices: [[Double]]?
  var indices: [[Int]]?
  var texts: [String]?
  var coefficients: [[Double]]?
  var radius: Double?

  enum CodingKeys: String, CodingKey {
    case primitive
    case vertices
    case indices
    case texts
    case coefficients
    case radius
  }

  init(primitive: String?, vertices: [[Double]]?, indices: [[Int]]?,
       texts: [String]?, coefficients: [[Double]]?, radius: Double?) {
    self.primitive = primitive
    self.vertices = vertices
    self.indices = indices
    self.texts = texts
    self.coefficients = coefficients
    self.radius = radius
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    primitive = try? container.decode(String.self, forKey: .primitive)
    vertices = Self.decodeDoubleRows(container, key: .vertices)
    indices = Self.decodeIntRows(container, key: .indices)
    texts = Self.decodeStrings(container, key: .texts)
    coefficients = Self.decodeDoubleRows(container, key: .coefficients)
    radius = try? container.decode(Double.self, forKey: .radius)
  }

  static func decodeDoubleRows(_ container: KeyedDecodingContainer<CodingKeys>,
                               key: CodingKeys) -> [[Double]]? {
    if let rows = try? container.decode([[Double]].self, forKey: key) {
      return rows
    }
    if let row = try? container.decode([Double].self, forKey: key) {
      return [row]
    }
    if let value = try? container.decode(Double.self, forKey: key) {
      return [[value]]
    }
    return nil
  }

  static func decodeIntRows(_ container: KeyedDecodingContainer<CodingKeys>,
                            key: CodingKeys) -> [[Int]]? {
    if let rows = try? container.decode([[Int]].self, forKey: key) {
      return rows
    }
    if let row = try? container.decode([Int].self, forKey: key) {
      return [row]
    }
    if let value = try? container.decode(Int.self, forKey: key) {
      return [[value]]
    }
    return nil
  }

  static func decodeStrings(_ container: KeyedDecodingContainer<CodingKeys>,
                            key: CodingKeys) -> [String]? {
    if let values = try? container.decode([String].self, forKey: key) {
      return values
    }
    if let value = try? container.decode(String.self, forKey: key) {
      return [value]
    }
    if let value = try? container.decode(Int.self, forKey: key) {
      return ["\(value)"]
    }
    if let value = try? container.decode(Double.self, forKey: key) {
      return ["\(value)"]
    }
    return nil
  }
}

struct MaterialSpec: Decodable {
  var color: String?
  var alpha: Double?
  var size: Double?
  var lwd: Double?
  var radius: Double?
}

final class RMetalARView: ARView {
  weak var viewerController: ViewerController?

  override var acceptsFirstResponder: Bool { true }

  func rglPoint(_ event: NSEvent) -> CGPoint {
    let p = convert(event.locationInWindow, from: nil)
    let y = isFlipped ? bounds.height - p.y : p.y
    return CGPoint(x: p.x, y: y)
  }

  override func mouseDown(with event: NSEvent) {
    window?.makeFirstResponder(self)
    if viewerController?.handleSelection(button: "left", event: event) == true {
      return
    }
    viewerController?.trackballBegin(at: rglPoint(event))
  }

  override func rightMouseDown(with event: NSEvent) {
    window?.makeFirstResponder(self)
    if viewerController?.handleSelection(button: "right", event: event) == true {
      return
    }
    viewerController?.zoomBegin(at: rglPoint(event))
  }

  override func otherMouseDown(with event: NSEvent) {
    window?.makeFirstResponder(self)
    if viewerController?.handleSelection(button: "middle", event: event) == true {
      return
    }
    viewerController?.fovBegin(at: rglPoint(event))
  }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == 53 && viewerController?.cancelSelection() == true {
      return
    }
    super.keyDown(with: event)
  }

  override func mouseDragged(with event: NSEvent) {
    viewerController?.trackballMove(to: rglPoint(event))
  }

  override func rightMouseDragged(with event: NSEvent) {
    viewerController?.zoomMove(to: rglPoint(event))
  }

  override func otherMouseDragged(with event: NSEvent) {
    viewerController?.fovMove(to: rglPoint(event))
  }

  override func mouseUp(with event: NSEvent) {
    viewerController?.trackballEnd()
  }

  override func rightMouseUp(with event: NSEvent) {
    viewerController?.zoomEnd()
  }

  override func otherMouseUp(with event: NSEvent) {
    viewerController?.fovEnd()
  }

  override func scrollWheel(with event: NSEvent) {
    viewerController?.wheelZoom(deltaY: event.scrollingDeltaY,
                                fine: event.modifierFlags.contains(.shift))
  }

  override func magnify(with event: NSEvent) {
    viewerController?.magnify(by: Float(event.magnification))
  }
}

final class ViewerController: NSObject, NSApplicationDelegate, NSWindowDelegate {
  let scenePath: String
  let heartbeatPath: String
  let commandPath: String
  let logPath: String
  var window: NSWindow!
  var arView: RMetalARView!
  var timer: Timer?
  var lastModified: Date?
  var lastCommandModified: Date?
  var lastCommandSize: UInt64 = 0
  var lastCommandToken: Double = 0
  var rootAnchor = AnchorEntity(world: .zero)
  var contentPivot = Entity()
  var contentRoot = Entity()
  var objectEntities: [Int: Entity] = [:]
  var camera = PerspectiveCamera()
  var light = DirectionalLight()
  var sceneCenter = SIMD3<Float>.zero
  var sceneRadius: Float = 1
  var cameraBaseOffset = SIMD3<Float>(0, -2.6, 1.35)
  var panOffset = SIMD3<Float>.zero
  var userMovedCamera = false
  var sceneBounds = SceneBounds()
  var contentRotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 0, 1))
  var trackballBase: SIMD3<Float>?
  var trackballSavedRotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 0, 1))
  var zoomBaseY: CGFloat = 0
  var zoomBase: Float = 1
  var fovBaseY: CGFloat = 0
  var fovBase: Float = 30
  var viewZoom: Float = 1
  var fovDegrees: Float = 30
  var viewTheta: Float?
  var viewPhi: Float?
  var selectionButton: String?
  var selectionResultPath: String?
  var eventMonitor: Any?

  init(scenePath: String, heartbeatPath: String, commandPath: String) {
    self.scenePath = scenePath
    self.heartbeatPath = heartbeatPath
    self.commandPath = commandPath
    self.logPath = "\(scenePath).viewer.log"
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    try? "rmetal viewer start \(Date())\n".write(toFile: logPath,
                                                 atomically: true,
                                                 encoding: .utf8)
    let frame = NSRect(x: 80, y: 80, width: 900, height: 700)
    window = NSWindow(contentRect: frame,
                      styleMask: [.titled, .closable, .resizable, .miniaturizable],
                      backing: .buffered,
                      defer: false)
    window.title = "rmetal"
    window.delegate = self
    arView = RMetalARView(frame: frame)
    arView.viewerController = self
    window.contentView = arView
    window.makeKeyAndOrderFront(nil)
    window.makeFirstResponder(arView)
    NSApp.activate(ignoringOtherApps: true)
    installEventMonitor()

    reloadIfNeeded(force: true)
    timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
      self?.writeHeartbeat()
      self?.reloadIfNeeded(force: false)
      self?.applyCommandIfNeeded()
    }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }

  func windowWillClose(_ notification: Notification) {
    viewerLog("windowWillClose")
    closeViewer()
  }

  func applicationWillTerminate(_ notification: Notification) {
    timer?.invalidate()
    removeEventMonitor()
    try? FileManager.default.removeItem(atPath: heartbeatPath)
  }

  func installEventMonitor() {
    eventMonitor = NSEvent.addLocalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown]
    ) { [weak self] event in
      guard let self = self else { return event }
      guard event.window === self.window else { return event }
      switch event.type {
      case .keyDown:
        if event.keyCode == 53 && self.cancelSelection() {
          return nil
        }
      case .leftMouseDown:
        if self.handleSelection(button: "left", event: event) {
          return nil
        }
      case .rightMouseDown:
        if self.handleSelection(button: "right", event: event) {
          return nil
        }
      case .otherMouseDown:
        if self.handleSelection(button: "middle", event: event) {
          return nil
        }
      default:
        break
      }
      return event
    }
  }

  func removeEventMonitor() {
    if let eventMonitor = eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
      self.eventMonitor = nil
    }
  }

  func closeViewer() {
    timer?.invalidate()
    removeEventMonitor()
    try? FileManager.default.removeItem(atPath: heartbeatPath)
    DispatchQueue.main.async {
      NSApp.terminate(nil)
    }
  }

  func writeHeartbeat() {
    let pid = ProcessInfo.processInfo.processIdentifier
    let value = "\(pid) \(Date().timeIntervalSince1970)\n"
    try? value.write(toFile: heartbeatPath, atomically: true, encoding: .utf8)
  }

  func viewerLog(_ message: String) {
    guard let data = "\(Date()) \(message)\n".data(using: .utf8),
          let handle = FileHandle(forWritingAtPath: logPath) else {
      return
    }
    defer { try? handle.close() }
    do {
      try handle.seekToEnd()
      try handle.write(contentsOf: data)
    } catch {
      return
    }
  }

  func reloadIfNeeded(force: Bool) {
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: scenePath),
          let modified = attrs[.modificationDate] as? Date else {
      return
    }
    if !force && lastModified == modified { return }
    if loadScene() {
      lastModified = modified
    }
  }

  func loadScene() -> Bool {
    let started = Date()
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: scenePath)) else {
      viewerLog("loadScene could not read scene file")
      return false
    }
    let scene: SceneFile
    do {
      scene = try JSONDecoder().decode(SceneFile.self, from: data)
    } catch {
      viewerLog("loadScene decode failed: \(String(describing: error))")
      return false
    }
    viewerLog("loadScene decoded objects=\(scene.objects.count) bytes=\(data.count)")

    arView.scene.anchors.removeAll()
    rootAnchor = AnchorEntity(world: .zero)
    contentPivot = Entity()
    contentRoot = Entity()
    objectEntities = [:]
    contentPivot.addChild(contentRoot)
    rootAnchor.addChild(contentPivot)
    arView.scene.addAnchor(rootAnchor)

    sceneBounds = SceneBounds()
    for object in scene.objects {
      sceneBounds.include(vertices(object))
    }
    sceneCenter = sceneBounds.center
    sceneRadius = max(sceneBounds.radius, 1)
    applyViewParameters(scene.par, resetView: true)
    updateContentTransform()

    for object in scene.objects {
      add(object: object, to: contentRoot, bounds: sceneBounds)
    }

    addCamera(to: rootAnchor, bounds: sceneBounds, resetView: true)
    addLights(to: rootAnchor, bounds: sceneBounds)
    viewerLog("loadScene complete objects=\(scene.objects.count) radius=\(sceneRadius) elapsed=\(Date().timeIntervalSince(started))")
    writeHeartbeat()
    return true
  }

  func applyCommandIfNeeded() {
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: commandPath),
          let modified = attrs[.modificationDate] as? Date else {
      return
    }
    let size = attrs[.size] as? UInt64 ?? 0
    if lastCommandModified == modified && lastCommandSize == size { return }
    lastCommandModified = modified
    lastCommandSize = size
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: commandPath)) else {
      return
    }
    for command in decodeCommands(from: data) {
      let token = command.seq.map(Double.init) ??
        command.timestamp ?? (lastCommandToken + 1)
      if token <= lastCommandToken { continue }
      apply(command)
      lastCommandToken = max(lastCommandToken, token)
    }
  }

  func decodeCommands(from data: Data) -> [SceneCommand] {
    let decoder = JSONDecoder()
    if let commands = try? decoder.decode([SceneCommand].self, from: data) {
      return commands
    }
    if let command = try? decoder.decode(SceneCommand.self, from: data) {
      return [command]
    }
    guard let text = String(data: data, encoding: .utf8) else {
      return []
    }
    return text.split(whereSeparator: \.isNewline).compactMap { line in
      try? decoder.decode(SceneCommand.self, from: Data(String(line).utf8))
    }
  }

  func apply(_ command: SceneCommand) {
    switch command.action {
    case "addObject":
      if let object = command.payload {
        add(object: object, to: contentRoot, bounds: sceneBounds)
        viewerLog("command addObject type=\(object.type) id=\(object.id.map(String.init) ?? "nil")")
        sceneCenter = sceneBounds.center
        sceneRadius = max(sceneBounds.radius, 1)
        updateContentTransform()
        if !userMovedCamera {
          addCamera(to: rootAnchor, bounds: sceneBounds, resetView: true)
        }
      }
    case "removeObject":
      for id in command.ids ?? [] {
        objectEntities[id]?.removeFromParent()
        objectEntities[id] = nil
      }
    case "select":
      selectionButton = normalizeButton(command.button ?? "left")
      selectionResultPath = command.resultPath
      window.title = "rmetal - select \(selectionButton ?? "left") click, ESC cancels"
      window.makeKeyAndOrderFront(nil)
      window.makeFirstResponder(arView)
      NSApp.activate(ignoringOtherApps: true)
      viewerLog("select armed button=\(selectionButton ?? "left") path=\(selectionResultPath ?? "")")
    case "closeViewer":
      viewerLog("closeViewer command")
      closeViewer()
    default:
      break
    }
  }

  func normalizeButton(_ button: String) -> String {
    switch button.lowercased() {
    case "1", "left":
      return "left"
    case "2", "right":
      return "right"
    case "3", "middle", "center", "centre":
      return "middle"
    default:
      return button.lowercased()
    }
  }

  func handleSelection(button: String, event: NSEvent) -> Bool {
    guard let wanted = selectionButton,
          let path = selectionResultPath,
          wanted == normalizeButton(button) else {
      return false
    }
    let rgl = arView.rglPoint(event)
    let local = arView.convert(event.locationInWindow, from: nil)
    let ray = cameraRay(through: local)
    let length = max(sceneRadius * 20,
                     simd_length(currentCameraOffset()) + sceneRadius * 4,
                     1000)
    let a = userPoint(fromWorld: ray.origin)
    let rayEnd: SIMD3<Float> = ray.origin + (ray.direction * length)
    let b = userPoint(fromWorld: rayEnd)
    writeSelection(path: path, x: Float(rgl.x), y: Float(rgl.y),
                   ray: (a, b), cancelled: false)
    viewerLog("selection click button=\(button) x=\(rgl.x) y=\(rgl.y)")
    clearSelection()
    return true
  }

  func cancelSelection() -> Bool {
    guard let path = selectionResultPath else {
      return false
    }
    writeSelection(path: path, x: 0, y: 0, ray: nil, cancelled: true)
    viewerLog("selection cancelled")
    clearSelection()
    return true
  }

  func clearSelection() {
    selectionButton = nil
    selectionResultPath = nil
    window.title = "rmetal"
  }

  func writeSelection(path: String, x: Float, y: Float,
                      ray: (SIMD3<Float>, SIMD3<Float>)?,
                      cancelled: Bool) {
    var out: [String: Any] = [
      "x": Double(x),
      "y": Double(y),
      "cancelled": cancelled,
      "timestamp": Date().timeIntervalSince1970
    ]
    if let ray = ray {
      out["ray"] = [
        [Double(ray.0.x), Double(ray.0.y), Double(ray.0.z)],
        [Double(ray.1.x), Double(ray.1.y), Double(ray.1.z)]
      ]
    }
    guard let data = try? JSONSerialization.data(withJSONObject: out, options: []),
          let text = String(data: data, encoding: .utf8) else {
      return
    }
    try? text.write(toFile: path, atomically: true, encoding: .utf8)
  }

  func add(object: SceneObject, to anchor: Entity, bounds: SceneBounds) {
    let container = Entity()
    switch object.type {
    case "triangles", "quads":
      addMesh(object: object, to: container, bounds: bounds)
    case "points", "spheres":
      addPoints(object: object, to: container, bounds: bounds)
    case "lines":
      addLines(object: object, to: container, bounds: bounds)
    case "text":
      addText(object: object, to: container, bounds: bounds)
    case "planes":
      addPlanes(object: object, to: container, bounds: bounds)
    case "axes":
      addAxes(to: container, bounds: bounds)
    case "box":
      addBox(to: container, bounds: bounds, material: material(object.material))
    default:
      break
    }
    if !container.children.isEmpty {
      anchor.addChild(container)
      if let id = object.id {
        objectEntities[id] = container
      }
    }
  }

  func vertices(_ object: SceneObject) -> [SIMD3<Float>] {
    (object.geometry?.vertices ?? []).compactMap { row in
      guard row.count >= 3 else { return nil }
      return SIMD3<Float>(Float(row[0]), Float(row[1]), Float(row[2]))
    }
  }

  func addMesh(object: SceneObject, to anchor: Entity, bounds: SceneBounds) {
    let verts = vertices(object)
    guard !verts.isEmpty else { return }
    bounds.include(verts)

    var triangleIndices: [UInt32] = []
    for face in object.geometry?.indices ?? [] {
      if face.count == 3 {
        triangleIndices.append(contentsOf: face.map { UInt32(max($0 - 1, 0)) })
      } else if face.count == 4 {
        let f = face.map { UInt32(max($0 - 1, 0)) }
        triangleIndices.append(contentsOf: [f[0], f[1], f[2], f[0], f[2], f[3]])
      }
    }
    if triangleIndices.isEmpty {
      let count = verts.count - (verts.count % 3)
      triangleIndices = (0..<count).map { UInt32($0) }
    }
    var descriptor = MeshDescriptor(name: "rmetal mesh")
    descriptor.positions = MeshBuffers.Positions(verts)
    descriptor.primitives = .triangles(triangleIndices)

    guard let mesh = try? MeshResource.generate(from: [descriptor]) else { return }
    let entity = ModelEntity(mesh: mesh, materials: [material(object.material)])
    anchor.addChild(entity)
  }

  func addPoints(object: SceneObject, to anchor: Entity, bounds: SceneBounds) {
    let verts = vertices(object)
    guard !verts.isEmpty else { return }
    bounds.include(verts)

    let r: Float
    if let explicitRadius = object.material?.radius ?? object.geometry?.radius {
      r = Float(explicitRadius)
    } else {
      let size = Float(max(object.material?.size ?? 6, 1))
      r = max(sceneRadius * size / 700, sceneRadius * 0.004, 0.02)
    }
    let mesh = MeshResource.generateSphere(radius: max(r, 0.02))
    for v in verts {
      let entity = ModelEntity(mesh: mesh, materials: [material(object.material)])
      entity.position = v
      anchor.addChild(entity)
    }
  }

  func addLines(object: SceneObject, to anchor: Entity, bounds: SceneBounds) {
    let verts = vertices(object)
    guard verts.count >= 2 else { return }
    bounds.include(verts)

    let radius = Float(max(object.material?.lwd ?? object.material?.size ?? 2, 1)) / 150.0
    let pairs: [(SIMD3<Float>, SIMD3<Float>)]
    if object.geometry?.primitive == "segments" {
      pairs = stride(from: 0, to: verts.count - 1, by: 2).map { (verts[$0], verts[$0 + 1]) }
    } else {
      pairs = (0..<(verts.count - 1)).map { (verts[$0], verts[$0 + 1]) }
    }
    for (a, b) in pairs {
      addCylinder(from: a, to: b, radius: radius, material: material(object.material),
                  anchor: anchor)
    }
  }

  func addText(object: SceneObject, to anchor: Entity, bounds: SceneBounds) {
    let verts = vertices(object)
    guard !verts.isEmpty else { return }
    bounds.include(verts)

    let texts = object.geometry?.texts ?? []
    let textSize = max(max(sceneRadius, bounds.radius) * 0.06, 0.05)
    let font = NSFont.systemFont(ofSize: CGFloat(textSize))
    for (index, v) in verts.enumerated() {
      let text = index < texts.count ? texts[index] : ""
      if text.isEmpty { continue }
      let mesh = MeshResource.generateText(text,
                                           extrusionDepth: textSize * 0.02,
                                           font: font,
                                           containerFrame: .zero,
                                           alignment: .center,
                                           lineBreakMode: .byWordWrapping)
      let entity = ModelEntity(mesh: mesh, materials: [material(object.material)])
      entity.position = v
      anchor.addChild(entity)
    }
  }

  func addPlanes(object: SceneObject, to anchor: Entity, bounds: SceneBounds) {
    let rows = object.geometry?.coefficients ?? []
    guard !rows.isEmpty else { return }

    for row in rows {
      if row.count < 4 { continue }
      let normal = SIMD3<Float>(Float(row[0]), Float(row[1]), Float(row[2]))
      let normalLength = simd_length(normal)
      if normalLength <= 0 { continue }
      let n = normal / normalLength
      let d = Float(row[3]) / normalLength
      let center = bounds.center
      let planeOffset: Float = simd_dot(n, center) + d
      let point: SIMD3<Float> = center - (n * planeOffset)
      let helper = abs(n.z) < 0.9 ? SIMD3<Float>(0, 0, 1) : SIMD3<Float>(0, 1, 0)
      let u = simd_normalize(simd_cross(n, helper))
      let v = simd_normalize(simd_cross(n, u))
      let size = max(max(bounds.radius, sceneRadius) * 2.5, 1)
      let verts = planeVertices(center: point, u: u, v: v, size: size)

      var descriptor = MeshDescriptor(name: "rmetal plane")
      descriptor.positions = MeshBuffers.Positions(verts)
      descriptor.primitives = .triangles([0, 1, 2, 0, 2, 3])
      guard let mesh = try? MeshResource.generate(from: [descriptor]) else {
        continue
      }
      let entity = ModelEntity(mesh: mesh, materials: [material(object.material)])
      anchor.addChild(entity)
    }
  }

  func planeVertices(center: SIMD3<Float>, u: SIMD3<Float>, v: SIMD3<Float>,
                     size: Float) -> [SIMD3<Float>] {
    // Keep this arithmetic split up: older Swift toolchains can time out
    // type-checking chained SIMD expressions during lazy viewer compilation.
    let scaledU: SIMD3<Float> = u * size
    let scaledV: SIMD3<Float> = v * size
    let lowerLeft: SIMD3<Float> = (center - scaledU) - scaledV
    let lowerRight: SIMD3<Float> = (center + scaledU) - scaledV
    let upperRight: SIMD3<Float> = (center + scaledU) + scaledV
    let upperLeft: SIMD3<Float> = (center - scaledU) + scaledV
    return [lowerLeft, lowerRight, upperRight, upperLeft]
  }

  func addAxes(to anchor: Entity, bounds: SceneBounds) {
    let center = bounds.center
    let radius = max(bounds.radius, 1)
    let specs: [(SIMD3<Float>, NSColor, String)] = [
      (SIMD3<Float>(1, 0, 0), .systemRed, "x"),
      (SIMD3<Float>(0, 1, 0), .systemGreen, "y"),
      (SIMD3<Float>(0, 0, 1), .systemBlue, "z")
    ]
    for (axis, color, label) in specs {
      var mat = SimpleMaterial()
      mat.color = .init(tint: color)
      let axisRadius: SIMD3<Float> = axis * radius
      let axisStart: SIMD3<Float> = center - axisRadius
      let axisEnd: SIMD3<Float> = center + axisRadius
      addCylinder(from: axisStart,
                  to: axisEnd,
                  radius: max(radius * 0.006, 0.01),
                  material: mat,
                  anchor: anchor)
      let labelOffset: SIMD3<Float> = axis * (radius * Float(1.08))
      let labelPoint: SIMD3<Float> = center + labelOffset
      let textSpec = SceneObject(id: nil, type: "text",
                                 geometry: Geometry(primitive: nil,
                                                    vertices: [[Double(labelPoint.x),
                                                                Double(labelPoint.y),
                                                                Double(labelPoint.z)]],
                                                    indices: nil,
                                                    texts: [label],
                                                    coefficients: nil,
                                                    radius: nil),
                                 material: nil,
                                 tag: nil)
      addText(object: textSpec, to: anchor, bounds: bounds)
    }
  }

  func addBox(to anchor: Entity, bounds: SceneBounds,
              material: RealityKit.Material) {
    let minPoint = bounds.minPointOrDefault
    let maxPoint = bounds.maxPointOrDefault
    let corners = [
      SIMD3<Float>(minPoint.x, minPoint.y, minPoint.z),
      SIMD3<Float>(maxPoint.x, minPoint.y, minPoint.z),
      SIMD3<Float>(maxPoint.x, maxPoint.y, minPoint.z),
      SIMD3<Float>(minPoint.x, maxPoint.y, minPoint.z),
      SIMD3<Float>(minPoint.x, minPoint.y, maxPoint.z),
      SIMD3<Float>(maxPoint.x, minPoint.y, maxPoint.z),
      SIMD3<Float>(maxPoint.x, maxPoint.y, maxPoint.z),
      SIMD3<Float>(minPoint.x, maxPoint.y, maxPoint.z)
    ]
    let edges = [(0, 1), (1, 2), (2, 3), (3, 0),
                 (4, 5), (5, 6), (6, 7), (7, 4),
                 (0, 4), (1, 5), (2, 6), (3, 7)]
    let radius = max(bounds.radius * 0.004, 0.008)
    for (a, b) in edges {
      addCylinder(from: corners[a], to: corners[b], radius: radius,
                  material: material, anchor: anchor)
    }
  }

  func addCylinder(from a: SIMD3<Float>, to b: SIMD3<Float>, radius: Float,
                   material: RealityKit.Material, anchor: Entity) {
    let delta = b - a
    let length = simd_length(delta)
    if length <= 0 { return }

    let mesh = MeshResource.generateCylinder(height: length, radius: max(radius, 0.01))
    let entity = ModelEntity(mesh: mesh, materials: [material])
    entity.position = (a + b) / 2

    let yAxis = SIMD3<Float>(0, 1, 0)
    let direction = simd_normalize(delta)
    let dotValue = min(max(simd_dot(yAxis, direction), -1), 1)
    let angle = acos(dotValue)
    let axis = simd_cross(yAxis, direction)
    if simd_length(axis) > 0.0001 {
      entity.orientation = simd_quatf(angle: angle, axis: simd_normalize(axis))
    } else if dotValue < 0 {
      entity.orientation = simd_quatf(angle: Float.pi, axis: SIMD3<Float>(1, 0, 0))
    }
    anchor.addChild(entity)
  }

  func material(_ spec: MaterialSpec?) -> RealityKit.Material {
    var material = SimpleMaterial()
    material.color = .init(tint: color(spec?.color, alpha: spec?.alpha))
    material.roughness = .float(0.55)
    material.metallic = .float(0.0)
    material.faceCulling = .none
    return material
  }

  func color(_ name: String?, alpha: Double?) -> NSColor {
    let a = CGFloat(alpha ?? 1.0)
    guard let raw = name?.lowercased() else {
      return NSColor(calibratedWhite: 0.85, alpha: a)
    }
    let named: [String: NSColor] = [
      "black": .black, "white": .white, "red": .red, "green": .systemGreen,
      "blue": .systemBlue, "purple": .systemPurple, "yellow": .systemYellow,
      "orange": .systemOrange, "cyan": .systemCyan, "gray": .systemGray,
      "grey": .systemGray
    ]
    if let c = named[raw] { return c.withAlphaComponent(a) }
    if raw.hasPrefix("#"), raw.count == 7 {
      let scanner = Scanner(string: String(raw.dropFirst()))
      var value: UInt64 = 0
      if scanner.scanHexInt64(&value) {
        return NSColor(calibratedRed: CGFloat((value >> 16) & 255) / 255,
                       green: CGFloat((value >> 8) & 255) / 255,
                       blue: CGFloat(value & 255) / 255,
                       alpha: a)
      }
    }
    return NSColor(calibratedWhite: 0.85, alpha: a)
  }

  func addCamera(to anchor: AnchorEntity, bounds: SceneBounds, resetView: Bool) {
    sceneCenter = bounds.center
    sceneRadius = max(bounds.radius, 1)
    if resetView {
      cameraBaseOffset = baseCameraOffset(radius: sceneRadius)
      panOffset = .zero
      userMovedCamera = false
    }
    if camera.parent == nil {
      camera = PerspectiveCamera()
      anchor.addChild(camera)
    }
    let distance = simd_length(currentCameraOffset())
    camera.camera.near = max(0.001, min(sceneRadius * 0.01, distance * 0.1))
    camera.camera.far = max(distance + sceneRadius * 4, sceneRadius * 20)
    camera.camera.fieldOfViewInDegrees = fovDegrees
    updateCamera()
  }

  func addLights(to anchor: AnchorEntity, bounds: SceneBounds) {
    let radius = max(bounds.radius, 1)
    light = DirectionalLight()
    light.light.intensity = 1800
    light.look(at: bounds.center, from: bounds.center + SIMD3<Float>(-radius, -radius, radius * 2),
               relativeTo: nil)
    anchor.addChild(light)
  }

  func applyViewParameters(_ par: ParSpec?, resetView: Bool) {
    guard resetView else { return }
    viewZoom = clamp(Float(par?.zoom ?? 1), 0.0001, 10000)
    fovDegrees = clamp(Float(par?.FOV ?? par?.fov ?? 30), 1, 179)
    viewTheta = par?.theta.map { Float($0) }
    viewPhi = par?.phi.map { Float($0) }
    if let matrix = par?.userMatrix,
       let rotation = quaternion(fromUserMatrix: matrix) {
      contentRotation = rotation
    } else {
      contentRotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 0, 1))
    }
  }

  func updateContentTransform() {
    contentPivot.position = sceneCenter
    contentPivot.orientation = contentRotation
    contentRoot.position = -sceneCenter
  }

  func quaternion(fromUserMatrix matrix: [[Double]]) -> simd_quatf? {
    guard matrix.count >= 3,
          matrix[0].count >= 3,
          matrix[1].count >= 3,
          matrix[2].count >= 3 else {
      return nil
    }
    var c0 = SIMD3<Float>(Float(matrix[0][0]), Float(matrix[1][0]), Float(matrix[2][0]))
    var c1 = SIMD3<Float>(Float(matrix[0][1]), Float(matrix[1][1]), Float(matrix[2][1]))
    var c2 = SIMD3<Float>(Float(matrix[0][2]), Float(matrix[1][2]), Float(matrix[2][2]))
    if simd_length(c0) <= 0 || simd_length(c1) <= 0 || simd_length(c2) <= 0 {
      return nil
    }
    c0 = simd_normalize(c0)
    c1 = simd_normalize(c1)
    c2 = simd_normalize(c2)
    return simd_quatf(simd_float3x3(columns: (c0, c1, c2)))
  }

  func screenToVector(_ point: CGPoint) -> SIMD3<Float> {
    let width = max(Float(arView.bounds.width), 1)
    let height = max(Float(arView.bounds.height), 1)
    let radius: Float = max(width, height) / 2
    let center: SIMD2<Float> = SIMD2<Float>(width, height) / 2
    var pt = SIMD2<Float>(Float(point.x), Float(point.y))
    pt = (pt - center) / radius
    let len: Float = simd_length(pt)
    if len > 1.0e-6 {
      pt /= len
    }
    // Keep the numeric types explicit for Swift compiler portability.
    let sqrtTwo: Float = Float(sqrt(2.0))
    let normalizedDistance: Float = (sqrtTwo - len) / sqrtTwo
    let halfPi: Float = Float.pi / 2.0
    let angle: Float = normalizedDistance * halfPi
    let z: Float = sin(angle)
    let zSquared: Float = z * z
    let projectedLength: Float = sqrt(max(Float(1.0) - zSquared, Float(0.0)))
    pt *= projectedLength
    return SIMD3<Float>(pt.x, pt.y, z)
  }

  func screenBasis() -> (right: SIMD3<Float>, up: SIMD3<Float>, out: SIMD3<Float>) {
    let offset = currentCameraOffset()
    let forward = simd_normalize(-offset)
    let out = simd_normalize(offset)
    let worldUp = SIMD3<Float>(0, 0, 1)
    var right = simd_cross(forward, worldUp)
    if simd_length(right) < 0.0001 {
      right = SIMD3<Float>(1, 0, 0)
    } else {
      right = simd_normalize(right)
    }
    let up = simd_normalize(simd_cross(right, forward))
    return (right, up, out)
  }

  func worldAxis(fromScreenAxis axis: SIMD3<Float>) -> SIMD3<Float> {
    let basis = screenBasis()
    let worldRight: SIMD3<Float> = basis.right * axis.x
    let worldUp: SIMD3<Float> = basis.up * axis.y
    let worldOut: SIMD3<Float> = basis.out * axis.z
    let world: SIMD3<Float> = (worldRight + worldUp) + worldOut
    if simd_length(world) < 0.000001 {
      return SIMD3<Float>(0, 0, 1)
    }
    return simd_normalize(world)
  }

  func trackballBegin(at point: CGPoint) {
    userMovedCamera = true
    trackballBase = screenToVector(point)
    trackballSavedRotation = contentRotation
  }

  func trackballMove(to point: CGPoint) {
    guard let base = trackballBase else { return }
    let current = screenToVector(point)
    let denom = simd_length(base) * simd_length(current)
    if denom <= 0 { return }
    let dotValue = clamp(simd_dot(base, current) / denom, -1, 1)
    let angle = acos(dotValue)
    if angle == 0 || !angle.isFinite { return }
    let axis = simd_cross(base, current)
    if simd_length(axis) < 0.000001 { return }
    let rotation = simd_quatf(angle: angle,
                              axis: worldAxis(fromScreenAxis: axis))
    contentRotation = rotation * trackballSavedRotation
    updateContentTransform()
  }

  func trackballEnd() {
    trackballBase = nil
  }

  func zoomBegin(at point: CGPoint) {
    userMovedCamera = true
    zoomBaseY = point.y
    zoomBase = max(viewZoom, 0.0001)
  }

  func zoomMove(to point: CGPoint) {
    let height = max(Float(arView.bounds.height), 1)
    let dy = Float(point.y - zoomBaseY)
    viewZoom = clamp(exp(log(zoomBase) + dy / height), 0.0001, 10000)
    updateCamera()
  }

  func zoomEnd() {
  }

  func fovBegin(at point: CGPoint) {
    userMovedCamera = true
    fovBaseY = point.y
    fovBase = fovDegrees
  }

  func fovMove(to point: CGPoint) {
    let height = max(Float(arView.bounds.height), 1)
    let dy = Float(point.y - fovBaseY)
    fovDegrees = clamp(fovBase + 180 * dy / height, 1, 179)
    camera.camera.fieldOfViewInDegrees = fovDegrees
  }

  func fovEnd() {
  }

  func wheelZoom(deltaY: CGFloat, fine: Bool) {
    guard deltaY != 0 else { return }
    userMovedCamera = true
    let step: Float = fine ? 1.005 : 1.05
    let multiplier = deltaY < 0 ? step : (1 / step)
    viewZoom = clamp(viewZoom * multiplier, 0.0001, 10000)
    updateCamera()
  }

  func magnify(by magnification: Float) {
    userMovedCamera = true
    viewZoom = clamp(viewZoom * max(0.05, 1 + magnification), 0.0001, 10000)
    updateCamera()
  }

  func currentCameraOffset() -> SIMD3<Float> {
    cameraBaseOffset / max(viewZoom, 0.0001)
  }

  func baseCameraOffset(radius: Float) -> SIMD3<Float> {
    guard let theta = viewTheta, let phi = viewPhi else {
      return SIMD3<Float>(0, -radius * 2.6, radius * 1.35)
    }
    let degreesToRadians: Float = Float.pi / 180.0
    let thetaRad: Float = theta * degreesToRadians
    let phiRad: Float = phi * degreesToRadians
    let distance: Float = radius * 3
    let xy: Float = cos(phiRad)
    let x: Float = sin(thetaRad) * xy * distance
    let y: Float = -cos(thetaRad) * xy * distance
    let z: Float = sin(phiRad) * distance
    return SIMD3<Float>(x, y, z)
  }

  func cameraRay(through point: CGPoint) -> (origin: SIMD3<Float>, direction: SIMD3<Float>) {
    let width = max(Float(arView.bounds.width), 1)
    let height = max(Float(arView.bounds.height), 1)
    let ndcX = Float(point.x) / width * 2 - 1
    let pointY = arView.isFlipped ? height - Float(point.y) : Float(point.y)
    let ndcY = pointY / height * 2 - 1
    let target = sceneCenter + panOffset
    let origin = target + currentCameraOffset()
    let forward = simd_normalize(target - origin)
    let basis = screenBasis()
    let fovRadians: Float = fovDegrees * Float.pi / 360.0
    let halfHeight: Float = tan(fovRadians)
    let halfWidth: Float = halfHeight * width / height
    let xOffset: SIMD3<Float> = basis.right * (ndcX * halfWidth)
    let yOffset: SIMD3<Float> = basis.up * (ndcY * halfHeight)
    let rayDirection: SIMD3<Float> = (forward + xOffset) + yOffset
    let direction = simd_normalize(rayDirection)
    return (origin, direction)
  }

  func userPoint(fromWorld point: SIMD3<Float>) -> SIMD3<Float> {
    sceneCenter + contentRotation.inverse.act(point - sceneCenter)
  }

  func updateCamera() {
    let target = sceneCenter + panOffset
    let from = target + currentCameraOffset()
    camera.look(at: target, from: from, relativeTo: nil)
  }

  func clamp(_ x: Float, _ minValue: Float, _ maxValue: Float) -> Float {
    min(max(x, minValue), maxValue)
  }
}

final class SceneBounds {
  var minPoint = SIMD3<Float>(Float.greatestFiniteMagnitude,
                              Float.greatestFiniteMagnitude,
                              Float.greatestFiniteMagnitude)
  var maxPoint = SIMD3<Float>(-Float.greatestFiniteMagnitude,
                              -Float.greatestFiniteMagnitude,
                              -Float.greatestFiniteMagnitude)

  func include(_ points: [SIMD3<Float>]) {
    for p in points {
      minPoint = simd_min(minPoint, p)
      maxPoint = simd_max(maxPoint, p)
    }
  }

  var center: SIMD3<Float> {
    if minPoint.x == Float.greatestFiniteMagnitude { return .zero }
    return (minPoint + maxPoint) / 2
  }

  var minPointOrDefault: SIMD3<Float> {
    if minPoint.x == Float.greatestFiniteMagnitude {
      return SIMD3<Float>(-1, -1, -1)
    }
    return minPoint
  }

  var maxPointOrDefault: SIMD3<Float> {
    if maxPoint.x == -Float.greatestFiniteMagnitude {
      return SIMD3<Float>(1, 1, 1)
    }
    return maxPoint
  }

  var radius: Float {
    if minPoint.x == Float.greatestFiniteMagnitude { return 1 }
    return max(simd_length(maxPoint - minPoint) / 2, 1)
  }
}

let args = Array(CommandLine.arguments.dropFirst())
let path = args.first ?? ""
let heartbeat = args.dropFirst().first ?? "\(path).heartbeat"
let command = args.dropFirst(2).first ?? "\(path).command.json"
let app = NSApplication.shared
let delegate = ViewerController(scenePath: path, heartbeatPath: heartbeat,
                                commandPath: command)
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
