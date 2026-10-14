import SwiftUI

// All geometry uses view-local points, with a top-left origin.
enum FilmFormat: String, CaseIterable, Identifiable {
    case format135 = "135 · 3:2"
    case format120 = "120 · 6×9"
    var id: String { rawValue }
    var aspectRatio: CGFloat { 3.0 / 2.0 }
}

struct LightGeometry {
    static func rect(in size: CGSize, center: CGPoint?, scale: CGFloat, aspect: CGFloat, fill: Bool) -> CGRect {
        guard size.width > 0, size.height > 0 else { return .zero }
        if fill { return CGRect(origin: .zero, size: size) }
        let fittedWidth = min(size.width, size.height * aspect)
        let width = fittedWidth * min(max(scale, 0.1), 1)
        let height = width / aspect
        let requested = center ?? CGPoint(x: size.width / 2, y: size.height / 2)
        let x = min(max(requested.x, width / 2), size.width - width / 2)
        let y = min(max(requested.y, height / 2), size.height - height / 2)
        return CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height)
    }

    static func color(gain: Float, headroom: Float, rgb: SIMD3<Float>) -> SIMD4<Float> {
        let peak = max(rgb.x, max(rgb.y, rgb.z))
        let multiplier = min(max(gain, 1), max(headroom, 1) / max(peak, 1))
        return SIMD4(rgb.x * multiplier, rgb.y * multiplier, rgb.z * multiplier, 1)
    }
}

final class ViewerState: ObservableObject {
    @Published var format: FilmFormat = .format135
    @Published var scale: Double = 0.6
    @Published var center: CGPoint?
    @Published var fill = false
    @Published var gain: Double = 10
    @Published var red: Double = 1
    @Published var green: Double = 1
    @Published var blue: Double = 1
    @Published var headroom: Double = 1
    @Published var status = "正在检测显示器"
    @Published var controlsVisible = true
    var viewport: CGSize = .zero
    weak var window: NSWindow?
    var focusCanvas: (() -> Void)?

    var lightRect: CGRect {
        LightGeometry.rect(in: viewport, center: center, scale: scale, aspect: format.aspectRatio, fill: fill)
    }
    func move(dx: CGFloat, dy: CGFloat) {
        guard !fill else { return }
        let rect = lightRect
        center = CGPoint(x: rect.midX + dx, y: rect.midY + dy)
        let clamped = lightRect
        center = CGPoint(x: clamped.midX, y: clamped.midY)
    }
    func zoom(_ delta: Double) { scale = min(max(scale + delta, 0.1), 1) }
}
