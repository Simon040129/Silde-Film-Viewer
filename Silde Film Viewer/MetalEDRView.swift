import SwiftUI
import MetalKit

struct MetalEDRView: NSViewRepresentable {
    @Binding var centerPosition: CGPoint
    var currentFormat: ContentView.FilmFormat
    var scaleFactor: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("No Metal device found")
        }
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.colorPixelFormat = .rgba16Float
        mtkView.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
        
        if let layer = mtkView.layer as? CAMetalLayer {
            layer.wantsExtendedDynamicRangeContent = true
        }
        
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        mtkView.delegate = context.coordinator
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.centerPosition = centerPosition
        context.coordinator.currentFormat = currentFormat
        context.coordinator.scaleFactor = scaleFactor
        nsView.setNeedsDisplay(nsView.bounds)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalEDRView
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?
        
        // 传入的数据
        var centerPosition: CGPoint = .zero
        var currentFormat: ContentView.FilmFormat = .format135
        var scaleFactor: CGFloat = 3.0

        // 记录画幅信息
        let formatInfo: [ContentView.FilmFormat: (baseSize: CGSize, aspect: CGSize)] = [
            .format135: (CGSize(width: 900, height: 300), CGSize(width: 3, height: 2)),
            .format120: (CGSize(width: 900, height: 550), CGSize(width: 6, height: 4))
        ]

        // 顶点缓冲:
        var vertexBuffer: MTLBuffer?

        init(_ parent: MetalEDRView) {
            self.parent = parent
            super.init()
            setupMetal()
        }

        private func setupMetal() {
            guard let device = MTLCreateSystemDefaultDevice() else { return }
            self.commandQueue = device.makeCommandQueue()

            // 1) 加载 .metal 着色器
            let library = try! device.makeDefaultLibrary(bundle: .main)
            let vertexFunc = library.makeFunction(name: "simpleVertexShader")
            let fragFunc   = library.makeFunction(name: "simpleFragmentShader")

            // 2) 创建渲染管线描述
            let pipelineDesc = MTLRenderPipelineDescriptor()
            pipelineDesc.vertexFunction = vertexFunc
            pipelineDesc.fragmentFunction = fragFunc
            pipelineDesc.colorAttachments[0].pixelFormat = .rgba16Float

            // 3) 设置 vertexDescriptor
            let mtlVertexDescriptor = MTLVertexDescriptor()
            mtlVertexDescriptor.attributes[0].format = .float2
            mtlVertexDescriptor.attributes[0].offset = 0
            mtlVertexDescriptor.attributes[0].bufferIndex = 0

            mtlVertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 2
            mtlVertexDescriptor.layouts[0].stepRate = 1
            mtlVertexDescriptor.layouts[0].stepFunction = .perVertex

            pipelineDesc.vertexDescriptor = mtlVertexDescriptor

            // 4) 创建渲染管线
            self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)

            // 注意：顶点数据可以在 draw(in:) 动态生成。但这里也可先做一个默认的 [-0.5..0.5]方块
            // 我们稍后在 draw(in:) 中修改 offset & scale
            let squareVertices: [Float] = [
                // 第1个三角形
                -0.5, -0.5,
                 0.5, -0.5,
                -0.5,  0.5,

                // 第2个三角形
                -0.5,  0.5,
                 0.5, -0.5,
                 0.5,  0.5
            ]

            self.vertexBuffer = device.makeBuffer(
                bytes: squareVertices,
                length: squareVertices.count * MemoryLayout<Float>.size,
                options: []
            )
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // do nothing
        }

        func draw(in view: MTKView) {
            guard let pipelineState = pipelineState,
                  let commandQueue = commandQueue,
                  let descriptor = view.currentRenderPassDescriptor,
                  let drawable = view.currentDrawable else { return }

            // 1) 清屏黑
            descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0,0,0,1)
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].storeAction = .store

            let commandBuffer = commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
            encoder.setRenderPipelineState(pipelineState)

            // 设置顶点缓冲
            if let vb = vertexBuffer {
                encoder.setVertexBuffer(vb, offset: 0, index: 0)
            }

            // 2) 计算 NDC 坐标：把 centerPosition 转到 [-1..1]
            let screenW = Float(view.drawableSize.width)
            let screenH = Float(view.drawableSize.height)

            let ndcX = (Float(centerPosition.x) / screenW) * 2.0 - 1.0
            let ndcY = (Float(centerPosition.y) / screenH) * 2.0 - 1.0

            // 3) 计算实际高亮矩形相对于“默认 -0.5..0.5”方块的 scale
            // baseSize -> scaleFactor -> / screen size -> * 2
            let (baseSize, _) = formatInfo[currentFormat]!
            let scaledWidth  = Float(baseSize.width  * scaleFactor)
            let scaledHeight = Float(baseSize.height * scaleFactor)

            // 由于我们的顶点在 -0.5..0.5 之间，这代表1.0 宽高
            // 需要把 scaledWidth / screenW 变成(0..1)区间，再做 *2.0
            let scaleX = (scaledWidth  / screenW)
            let scaleY = (scaledHeight / screenH)

            // 4) 把这些 offset + scale 传给着色器 (slot 1)
            var transformData = TransformData(
                offset: SIMD2<Float>(ndcX, ndcY),
                scale:  SIMD2<Float>(scaleX, scaleY)
            )
            encoder.setVertexBytes(&transformData, length: MemoryLayout<TransformData>.size, index: 1)

            // 5) 画矩形(6 顶点)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            encoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

// 你在 .metal 里可以定义更复杂的结构。
// 这里在 Swift 里定义一下 transformData，对应顶点函数中的 constant
struct TransformData {
    var offset: SIMD2<Float>
    var scale:  SIMD2<Float>
}
