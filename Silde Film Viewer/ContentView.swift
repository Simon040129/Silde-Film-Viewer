import SwiftUI

struct ContentView: View {
    @StateObject private var state = ViewerState()

    var body: some View {
        MetalEDRView(state: state)
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                if state.controlsVisible {
                    VStack(spacing: 10) {
                        HStack {
                            Picker("画幅", selection: $state.format) {
                                ForEach(FilmFormat.allCases) { Text($0.rawValue).tag($0) }
                            }.frame(width: 150)
                            Button("恢复位置") { state.resetPosition() }
                                .help("将亮区恢复到底部居中位置（C）")
                            Toggle("铺满亮区", isOn: $state.fill)
                            Button("窗口全屏") { state.window?.toggleFullScreen(nil) }
                            Button { state.controlsVisible = false; state.focusCanvas?() } label: {
                                Image(systemName: "eye.slash")
                            }.help("隐藏控制栏（H 恢复）")
                            .accessibilityLabel("隐藏控制栏")
                        }
                        HStack {
                            Text("大小")
                            Slider(value: $state.scale, in: 0.1...1).disabled(state.fill)
                            Text(state.scale, format: .percent.precision(.fractionLength(0))).monospacedDigit().frame(width: 45)
                            Text("EDR 倍率")
                            Slider(value: $state.gain, in: 1...10)
                            Text(state.gain, format: .number.precision(.fractionLength(1))).monospacedDigit()
                        }
                        DisclosureGroup("白平衡 · RGB 微调") {
                            HStack {
                                Text("R"); Slider(value: $state.red, in: 0...2)
                                Text("G"); Slider(value: $state.green, in: 0...2)
                                Text("B"); Slider(value: $state.blue, in: 0...2)
                                Button("中性白") { state.red = 1; state.green = 1; state.blue = 1 }
                            }
                            Text("RGB 微调不等同于色彩校准；翻拍请固定显示设置和相机白平衡。")
                                .font(.caption)
                        }
                        Text(state.status).font(.caption).foregroundStyle(.secondary)
                        Text("点击灯箱后：方向键移动 · ⇧ 精细移动 · ⌘+/− 缩放 · C 恢复位置 · H 隐藏/显示 · Esc 退出全屏")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: 680)
                    .foregroundStyle(.white)
                    .background(Color(white: 0.10), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(white: 0.35), lineWidth: 1))
                    .padding()
                } else {
                    Button {
                        state.controlsVisible = true
                        state.focusCanvas?()
                    } label: {
                        Label("显示控制栏", systemImage: "eye")
                    }
                    .help("显示控制栏，也可点击灯箱后按 H")
                    .padding(8)
                    .foregroundStyle(.white)
                    .background(Color(white: 0.10), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color(white: 0.35), lineWidth: 1))
                    .padding(12)
                }
            }
            .preferredColorScheme(.dark)
            .frame(minWidth: 720, minHeight: 420)
    }
}
