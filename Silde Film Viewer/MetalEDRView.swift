//
//  MetalEDRView.swift
//  Silde Film Viewer
//
//  Created by 卫奕铭 on 2025/3/21.
//

import SwiftUI
import MetalKit

struct MetalEDRView: NSViewRepresentable {
    @Binding var highlightPosition: CGPoint

    func makeNSView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("No Metal device found")
        }

        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.colorPixelFormat = .rgba16Float
        mtkView.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
        
        // 启用 EDR
        if let layer = mtkView.layer as? CAMetalLayer {
            layer.wantsExtendedDynamicRangeContent = true
        }
        
        // 让渲染仅在 setNeedsDisplay 时更新
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true

        mtkView.delegate = context.coordinator
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.highlightPosition = highlightPosition
        nsView.setNeedsDisplay(nsView.bounds)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalEDRView
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?
        var device: MTLDevice?

        // 记录矩形位置
        var highlightPosition: CGPoint = .zero

        // 顶点缓冲：用来画一个 300×300 的矩形
        var vertexBuffer: MTLBuffer?

        init(_ parent: MetalEDRView) {
            self.parent = parent
            super.init()

            // 创建 device/commandQueue
            guard let device = MTLCreateSystemDefaultDevice() else {
                fatalError("Metal device not found")
            }
            self.device = device
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
            
            // ★ 新增：告诉渲染管线如何匹配顶点属性
            let mtlVertexDescriptor = MTLVertexDescriptor()

            // 第 0 个属性为 .float2，offset=0，来自缓冲区索引 0
            mtlVertexDescriptor.attributes[0].format = .float2
            mtlVertexDescriptor.attributes[0].offset = 0
            mtlVertexDescriptor.attributes[0].bufferIndex = 0

            // 每个顶点占用 stride=2个float (即 2 * 4 bytes = 8)
            mtlVertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 2
            mtlVertexDescriptor.layouts[0].stepRate = 1
            mtlVertexDescriptor.layouts[0].stepFunction = .perVertex

            // 把这个 vertexDescriptor 赋给 pipelineDesc
            pipelineDesc.vertexDescriptor = mtlVertexDescriptor


            // 3) 创建渲染管线
            self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)

            // 4) 创建顶点数据（两个三角形组成一个 300x300 的矩形）
            //   这里是NDC坐标范围(-1~1)，要把300x300转成[-1,1]区间自己换算
            //   但为了简单，这里我们先假设(0,0)->(300,300)不会直接可见
            //   所以我们使用NDC简单定义一块0.5x0.5大小的方形
            //   之后通过 offset 做平移
            let halfWidth: Float  = 0.3  // 代表矩形的一半宽度(0.3 => 0.6覆盖屏幕60%)
            let halfHeight: Float = 0.3

            // 顶点数据 (x,y)
            let vertices: [Float] = [
                // 三角形1
                -halfWidth, -halfHeight,
                 halfWidth, -halfHeight,
                -halfWidth,  halfHeight,

                // 三角形2
                -halfWidth,  halfHeight,
                 halfWidth, -halfHeight,
                 halfWidth,  halfHeight
            ]

            // 创建 MTLBuffer
            self.vertexBuffer = device.makeBuffer(bytes: vertices,
                                                  length: vertices.count * MemoryLayout<Float>.size,
                                                  options: [])
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // 如果需要对窗口尺寸进行计算，可以在这里处理
        }

        func draw(in view: MTKView) {
            guard let commandQueue = commandQueue,
                  let descriptor = view.currentRenderPassDescriptor,
                  let drawable = view.currentDrawable,
                  let pipelineState = pipelineState
            else { return }

            // 1) 清屏为黑色
            descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].storeAction = .store

            // 2) 创建命令缓冲
            let commandBuffer = commandQueue.makeCommandBuffer()!

            // 3) 创建渲染命令编码器
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
            encoder.setRenderPipelineState(pipelineState)

            // 4) 设置顶点缓冲(插槽0)
            if let vb = vertexBuffer {
                encoder.setVertexBuffer(vb, offset: 0, index: 0)
            }

            // 5) 计算 offset，用 NDC 坐标来移动
            //    典型屏幕NDC从 -1..1, 0..0 处于屏幕中心
            //    你可自行换算 highlightPosition => NDC
            //    比如 scale = 2.0 / 1440 for x, 2.0 / 900 for y (假设屏幕分辨率)
            //    这里只是演示：简单粗暴
            let screenWidth = Float(view.drawableSize.width)
            let screenHeight = Float(view.drawableSize.height)

            // 将 macOS 坐标(0,0)左下角 => Metal NDC(0,0)在屏幕中心
            // 先将 highlightPosition 换成NDC:
            let ndcX = (Float(highlightPosition.x) / screenWidth) * 2.0 - 1.0
            let ndcY = (Float(highlightPosition.y) / screenHeight) * 2.0 - 1.0

            var offset = SIMD2<Float>(ndcX, ndcY)
            encoder.setVertexBytes(&offset,
                                   length: MemoryLayout<SIMD2<Float>>.size,
                                   index: 1)

            // 6) 绘制顶点 (6个)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            encoder.endEncoding()

            // 7) 呈现并提交
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
