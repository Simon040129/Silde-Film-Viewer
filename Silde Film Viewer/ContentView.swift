import SwiftUI

struct ContentView: View {
    @State private var highlightPosition = CGPoint(x: 1500, y: 500)
    @State private var keyboardMonitor: Any?

    var body: some View {
        ZStack {
            // 全屏 Metal EDR 视图
            MetalEDRView(highlightPosition: $highlightPosition)
                .edgesIgnoringSafeArea(.all)
            
            // 叠加一些 UI 控件 / 调试文字
            VStack {
                Text("Use arrow keys to move the highlight")
                    .foregroundColor(.white)
                    .padding()
                Spacer()
            }
        }
        .onAppear {
            // 在视图出现时监听键盘
            keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                handleKeyDown(event)
                return event
            }
        }
        .onDisappear {
            // 离开此视图时移除监听（避免泄漏）
            if let monitor = keyboardMonitor {
                NSEvent.removeMonitor(monitor)
                keyboardMonitor = nil
            }
        }
    }

    private func handleKeyDown(_ event: NSEvent) {
        // 每次按下方向键，更新highlightPosition
        let step: CGFloat = 20

        switch event.keyCode {
        case 123: // Left arrow
            highlightPosition.x -= step
        case 124: // Right arrow
            highlightPosition.x += step
        case 125: // Down arrow
            highlightPosition.y -= step
        case 126: // Up arrow
            highlightPosition.y += step
        default:
            break
        }
    }
}
