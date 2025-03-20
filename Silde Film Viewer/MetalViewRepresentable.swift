//
//  MetalViewRepresentable.swift
//  Silde Film Viewer
//
//  Created by 卫奕铭 on 2025/3/6.
//

import SwiftUI
import MetalKit

struct MetalViewRepresentable: NSViewRepresentable {
    // 创建并配置 MTKView
    func makeNSView(context: Context) -> MTKView {
        // 1) 获取默认的 Metal 设备
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("当前机器不支持 Metal！")
        }
        
        // 2) 用这个设备初始化 MTKView
        let mtkView = MTKView(frame: .zero, device: device)
        
        // 3) 设置像素格式、颜色空间，用于支持高动态范围
        mtkView.colorPixelFormat = .rgba16Float
        mtkView.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
        
        // 4) 显式启用 EDR
        if let metalLayer = mtkView.layer as? CAMetalLayer {
            metalLayer.wantsExtendedDynamicRangeContent = true
        }
        
        // 5) 设置渲染代理
        mtkView.delegate = context.coordinator
        
        // 让渲染在需要的时候才触发（避免空转）
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        
        return mtkView
    }
    
    // 当 SwiftUI 的状态变化时，会调用此函数更新视图（此示例里不需要额外操作）
    func updateNSView(_ nsView: MTKView, context: Context) {}

    // 创建并返回一个渲染协调器
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalViewRepresentable
        var commandQueue: MTLCommandQueue?

        init(_ parent: MetalViewRepresentable) {
            self.parent = parent
            // 创建命令队列，用于后续渲染提交
            if let device = MTLCreateSystemDefaultDevice() {
                self.commandQueue = device.makeCommandQueue()
            }
        }

        // 当视图尺寸变更时被调用
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // 可以在此处理视口或其他尺寸相关逻辑
        }

        // 每次需要绘制时被调用
        func draw(in view: MTKView) {
            guard let commandQueue = commandQueue,
                  let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor else {
                return
            }

            // 在此处指定一个超出[0,1]范围的清屏颜色，比如 10.0
            descriptor.colorAttachments[0].clearColor = MTLClearColorMake(10.0, 10.0, 10.0, 1.0)
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].storeAction = .store
            
            // 创建命令缓冲
            let commandBuffer = commandQueue.makeCommandBuffer()!
            // 创建渲染命令编码器
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
            
            // 这里暂时不绘制任何图形，只是清屏到超亮白色
            encoder.endEncoding()

            // 呈现并提交
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
