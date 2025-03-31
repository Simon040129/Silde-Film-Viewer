import SwiftUI

struct ContentView: View {
    // 1. 画幅选择
    enum FilmFormat: String, CaseIterable {
        case format135 = "135"
        case format120 = "120"
    }
    
    // 2. 中心位置 & 缩放因子 & 当前画幅
//    @State private var centerPosition = CGPoint.zero
    @State private var centerPosition = CGPoint(x: 1550, y: 450)
    @State private var scaleFactor: CGFloat = 3.0
    @State private var currentFormat: FilmFormat = .format135
    @State private var isFullScreen: Bool = false
    @State private var redWeight: Double = 1.0
    @State private var greenWeight: Double = 1.0
    @State private var blueWeight: Double = 1.0

    
    // 3. 键盘监听
    @State private var keyboardMonitor: Any?
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 4. Metal EDR 视图
            MetalEDRView(
                centerPosition: $centerPosition,
                currentFormat: currentFormat,
                scaleFactor: scaleFactor,
                isFullScreen: isFullScreen,       // 新增参数
                redWeight: redWeight,             // 下文RGB混色参数
                greenWeight: greenWeight,
                blueWeight: blueWeight
            )
            .edgesIgnoringSafeArea(.all)
            
            // 左侧：切换画幅
            VStack(alignment: .leading, spacing: 10) {
                ForEach(FilmFormat.allCases, id: \.self) { format in
                    Button(action: {
                        currentFormat = format
                    }) {
                        Text(format.rawValue)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 30, alignment: .center) // 指定明确的按钮尺寸
                    }
                    .background(currentFormat == format ? Color.blue : Color.gray)
                    .cornerRadius(6)
                    .buttonStyle(PlainButtonStyle()) // 禁用默认样式，避免额外 padding 干扰
                    .contentShape(Rectangle()) // 确保整个背景可点击
                }
                Spacer()
            }
            .padding(.top, 20)
            .padding(.leading, 5)

            
            // 3) 右上角：缩放 & 按钮
            //    用一个 VStack + 半透明背景面板
            VStack(alignment: .center) {
                Text("Scale: \(String(format: "%.2f", scaleFactor))")
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
                
                Slider(
                    value: Binding(
                        get: { scaleFactor },
                        set: { newVal in
                            scaleFactor = newVal
                        }
                    ),
                    in: 0.5...15.0 // 你可以调整范围
                )
                .frame(width: 150)
                .padding(.bottom, 8)
                
                HStack(spacing: 20) {
                    Button("-") {
                        scaleFactor = max(scaleFactor - 0.1, 0.5)
                    }
                    .padding(.horizontal, 10)  // 按钮内部水平间距
                    .padding(.vertical, 4)     // 按钮内部垂直间距
                    .background(Color.white.opacity(0.2)) // 按钮背景色（半透明白）
                    .foregroundColor(.white)
                    .cornerRadius(6)  // 圆角
                    
                    Button("+") {
                        scaleFactor = min(scaleFactor + 0.1, 15.0)
                    }
                    .padding(.horizontal, 10)  // 按钮内部水平间距
                    .padding(.vertical, 4)     // 按钮内部垂直间距
                    .background(Color.white.opacity(0.2)) // 按钮背景色（半透明白）
                    .foregroundColor(.white)
                    .cornerRadius(6)  // 圆角
                    
                    Button("全屏切换") {
                        isFullScreen.toggle()
                    }
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)

                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.gray.opacity(0.3)) // 浅灰半透明背景
            .cornerRadius(10)
            // 让它在右上角：先让 ZStack 占满，再在右上角对齐
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 5)
            .padding(.top, 20)
            
            // 在缩放控制面板下方添加
            VStack(alignment: .leading, spacing: 4) {
                Text("Red: \(String(format: "%.2f", redWeight))")
                    .foregroundColor(.red)
                Slider(value: $redWeight, in: 0...2)
                    .frame(width: 150)
                
                Text("Green: \(String(format: "%.2f", greenWeight))")
                    .foregroundColor(.green)
                Slider(value: $greenWeight, in: 0...2)
                    .frame(width: 150)
                
                Text("Blue: \(String(format: "%.2f", blueWeight))")
                    .foregroundColor(.blue)
                Slider(value: $blueWeight, in: 0...2)
                    .frame(width: 150)
            }
            .padding(.top, 20)
        }
        .onAppear {
            // 监听键盘 (方向键 + cmd +/-)
            keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                handleKeyDown(event)
                return event
            }
        }
        .onDisappear {
            if let monitor = keyboardMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
//    }
    
//    // 封装成单独的方法
//    private func updateCenterPosition(to size: CGSize) {
//        centerPosition = CGPoint(x: size.width / 2, y: size.height / 2)
//    }
    
    // MARK: - 处理键盘事件
    private func handleKeyDown(_ event: NSEvent) {
        // cmd + "+" / cmd + "-"
        if event.modifierFlags.contains(.command) {
            let c = event.charactersIgnoringModifiers
            switch c {
            case "=": // "+"
                scaleFactor = min(scaleFactor + 0.1, 5.0)
            case "-":
                scaleFactor = max(scaleFactor - 0.1, 0.5)
            default: break
            }
        }
        
        // 方向键
        let step: CGFloat = 20
        switch event.keyCode {
        case 123: // left
            centerPosition.x -= step
        case 124: // right
            centerPosition.x += step
        case 125: // down
            centerPosition.y -= step
        case 126: // up
            centerPosition.y += step
        default:
            break
        }
    }
}
