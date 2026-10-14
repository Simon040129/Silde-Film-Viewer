import SwiftUI
import MetalKit

struct MetalEDRView: NSViewRepresentable {
    @ObservedObject var state: ViewerState
    func makeNSView(context: Context) -> LightTableView { LightTableView(state: state) }
    func updateNSView(_ view: LightTableView, context: Context) { view.needsDisplay = true }
}

final class LightTableView: MTKView, MTKViewDelegate {
    private let state: ViewerState
    private var queue: MTLCommandQueue?
    private var pipeline: MTLRenderPipelineState?
    private var observers: [NSObjectProtocol] = []
    private var failure: String?
    override var acceptsFirstResponder: Bool { true }

    init(state: ViewerState) {
        self.state = state
        let device = MTLCreateSystemDefaultDevice()
        super.init(frame: .zero, device: device)
        colorPixelFormat = .rgba16Float
        colorspace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
        (layer as? CAMetalLayer)?.wantsExtendedDynamicRangeContent = true
        clearColor = MTLClearColorMake(0, 0, 0, 1)
        isPaused = true
        enableSetNeedsDisplay = true
        delegate = self
        do {
            guard let device, let queue = device.makeCommandQueue() else {
                throw RendererError.unavailable
            }
            self.queue = queue
            let library = try device.makeDefaultLibrary(bundle: .main)
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "simpleVertexShader")
            descriptor.fragmentFunction = library.makeFunction(name: "simpleFragmentShader")
            descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
            pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch { failure = "Metal 渲染不可用：\(error.localizedDescription)" }
    }
    required init(coder: NSCoder) { fatalError("Storyboard initialization is unsupported") }
    enum RendererError: Error { case unavailable }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        state.window = window
        state.focusCanvas = { [weak self] in
            guard let self else { return }
            self.window?.makeFirstResponder(self)
        }
        guard let window else { return }
        for name in [NSWindow.didChangeScreenNotification, NSWindow.didChangeBackingPropertiesNotification,
                     NSWindow.didResizeNotification, NSWindow.didEnterFullScreenNotification,
                     NSWindow.didExitFullScreenNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                self?.refreshDisplay()
            })
        }
        observers.append(NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refreshDisplay()
        })
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.window?.makeFirstResponder(self)
            self.refreshDisplay()
        }
    }
    deinit { observers.forEach(NotificationCenter.default.removeObserver) }

    private func refreshDisplay() {
        state.viewport = bounds.size
        let headroom = max(window?.screen?.maximumExtendedDynamicRangeColorComponentValue ?? 1, 1)
        state.headroom = headroom
        state.status = failure ?? "\(window?.screen?.localizedName ?? "显示器") · 当前 EDR 余量 \(String(format: "%.1f", headroom))×（非 nit 测量）"
        needsDisplay = true
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Drawable uses pixels; model and NDC conversion both use local points.
        DispatchQueue.main.async { [weak self] in self?.refreshDisplay() }
    }
    override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self) }
    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection([.command, .shift, .control, .option])
        let key = event.charactersIgnoringModifiers?.lowercased()
        if flags == .command || flags == [.command, .shift] {
            if key == "=" || key == "+" { state.zoom(0.05); return }
            if key == "-" { state.zoom(-0.05); return }
        }
        guard flags.isEmpty || flags == .shift else { super.keyDown(with: event); return }
        let step: CGFloat = flags.contains(.shift) ? 1 : 10
        switch event.keyCode {
        case 123: state.move(dx: -step, dy: 0)
        case 124: state.move(dx: step, dy: 0)
        case 125: state.move(dx: 0, dy: step)
        case 126: state.move(dx: 0, dy: -step)
        case 53:
            if window?.styleMask.contains(.fullScreen) == true { window?.toggleFullScreen(nil) }
            else { state.controlsVisible = true }
        default:
            if key == "c" { state.center = nil }
            else if key == "h" { state.controlsVisible.toggle() }
            else { super.keyDown(with: event) }
        }
    }
    func draw(in view: MTKView) {
        guard bounds.width > 0, bounds.height > 0, let pipeline, let queue,
              let pass = currentRenderPassDescriptor, let drawable = currentDrawable,
              let command = queue.makeCommandBuffer(), let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { return }
        state.viewport = bounds.size
        let rect = state.lightRect
        var transform = SIMD4<Float>(Float(rect.midX / bounds.width * 2 - 1),
                                     Float(1 - rect.midY / bounds.height * 2),
                                     Float(rect.width / bounds.width * 2),
                                     Float(rect.height / bounds.height * 2))
        let headroom = Float(window?.screen?.maximumExtendedDynamicRangeColorComponentValue ?? 1)
        var color = LightGeometry.color(gain: Float(state.gain), headroom: headroom,
                                       rgb: SIMD3(Float(state.red), Float(state.green), Float(state.blue)))
        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBytes(&transform, length: MemoryLayout<SIMD4<Float>>.stride, index: 1)
        encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: 2)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()
        command.present(drawable)
        command.commit()
    }
}
