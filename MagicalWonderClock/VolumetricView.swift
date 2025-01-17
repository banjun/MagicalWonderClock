import SwiftUI
import RealityKit

struct VolumetricView: View {
    let minVolumetricLength: CGFloat
    let input: AcrylClock.Input
    @Environment(\.physicalMetrics) private var physicalMetrics
    @State private var isWindowHandleVisible: Visibility = .visible

    var body: some View {
        ZStack(alignment: .bottom) {
            // make the image front aligned within lower depth limit
            RealityView {
                let spacer = ModelEntity(mesh: .generateBox(size: physicalMetrics.convert(.init(minVolumetricLength), to: .meters) - 0.07), materials: [UnlitMaterial(color: .clear)])
                spacer.isEnabled = false
                $0.add(spacer)
            }
            AcrylClock(input: input, playsSoundEffect: true, startSpinAnimationOnLoad: .once, isWindowHandleVisible: $isWindowHandleVisible)
                .frame(width: physicalMetrics.convert(15, from: .centimeters),
                       height: physicalMetrics.convert(10, from: .centimeters))
                .frame(depth: physicalMetrics.convert(7, from: .centimeters))
                .simultaneousGesture(TapGesture().onEnded {
                    isWindowHandleVisible = switch isWindowHandleVisible {
                    case .automatic, .visible: .hidden
                    case .hidden: .visible
                    }
                })
        }
        .persistentSystemOverlays(isWindowHandleVisible)
        .volumeBaseplateVisibility(.hidden)
    }
}

#Preview(immersionStyle: .mixed) {
    VolumetricView(minVolumetricLength: 300, input: .init(idol: .橘ありす, image: nil))
}
