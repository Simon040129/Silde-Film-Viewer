import SwiftUI

struct ContentView: View {
    var body: some View {
        // 一个简单的示例UI，展示文字+Metal视图
        VStack {
//            Text("EDR Demo")
//                .font(.title)
//                .padding()

            // Metal 渲染视图
            MetalViewRepresentable()
                .frame(minWidth: 300, minHeight: 300) // 你可按需调整大小
        }
    }
}
