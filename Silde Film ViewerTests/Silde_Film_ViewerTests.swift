import Testing
import Foundation
@testable import Silde_Film_Viewer

struct Silde_Film_ViewerTests {
    @Test func bottomAlignedAndAspectCorrect() {
        let rect = LightGeometry.rect(in: CGSize(width: 1000, height: 800), center: nil, scale: 0.6, aspect: 1.5, fill: false)
        #expect(rect.midX == 500)
        #expect(rect.maxY == 800)
        #expect(rect.width == 600)
        #expect(rect.height == 400)
    }
    @Test func bottomAnchorFollowsResizeAndZoom() {
        for size in [CGSize(width: 720, height: 420), CGSize(width: 1600, height: 1000)] {
            for scale: CGFloat in [0.1, 0.6, 1] {
                let rect = LightGeometry.rect(in: size, center: nil, scale: scale, aspect: 1.5, fill: false)
                #expect(abs(rect.maxY - size.height) < 0.0001)
                #expect(abs(rect.midX - size.width / 2) < 0.0001)
            }
        }
    }
    @Test func resetRestoresBottomAnchor() {
        let state = ViewerState()
        state.viewport = CGSize(width: 1000, height: 800)
        state.move(dx: 80, dy: -100)
        state.resetPosition()
        #expect(state.lightRect.midX == 500)
        #expect(state.lightRect.maxY == 800)
        #expect(state.center == nil)
        state.viewport = CGSize(width: 1200, height: 900)
        state.zoom(-0.2)
        #expect(abs(state.lightRect.maxY - 900) < 0.0001)
        #expect(state.lightRect.midX == 600)
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
