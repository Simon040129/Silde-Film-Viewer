import Testing
import Foundation
@testable import Silde_Film_Viewer

struct Silde_Film_ViewerTests {
    @Test func centeredAndAspectCorrect() {
        let rect = LightGeometry.rect(in: CGSize(width: 1000, height: 800), center: nil, scale: 0.6, aspect: 1.5, fill: false)
        #expect(rect.midX == 500)
        #expect(rect.midY == 400)
        #expect(rect.width == 600)
        #expect(rect.height == 400)
    }
    @Test func clampsAfterResizeAndOversize() {
        let rect = LightGeometry.rect(in: CGSize(width: 300, height: 200), center: CGPoint(x: -100, y: 900), scale: 15, aspect: 1.5, fill: false)
        #expect(rect == CGRect(x: 0, y: 0, width: 300, height: 200))
    }
    @Test func emptyAndFill() {
        #expect(LightGeometry.rect(in: .zero, center: nil, scale: 1, aspect: 1.5, fill: false) == .zero)
        #expect(LightGeometry.rect(in: CGSize(width: 300, height: 400), center: nil, scale: 0.2, aspect: 1.5, fill: true) == CGRect(x: 0, y: 0, width: 300, height: 400))
    }
    @Test func headroomPreservesRGBRatio() {
        let color = LightGeometry.color(gain: 10, headroom: 3, rgb: SIMD3(2, 1, 0.5))
        #expect(color == SIMD4(3, 1.5, 0.75, 1))
        #expect(LightGeometry.color(gain: 10, headroom: 1, rgb: SIMD3(repeating: 1)) == SIMD4(repeating: 1))
    }
}
