import SwiftUI
import RealityKit

struct VolumetricView: View {
    let minVolumetricLength: CGFloat
    let idol: Idol
    @Environment(\.physicalMetrics) private var physicalMetrics
    @Environment(\.openWindow) private var openWindow
    @State private var isWindowHandleVisible: Visibility = .visible

    var body: some View {
        ZStack(alignment: .bottom) {
            // make the image front aligned within lower depth limit
            RealityView {
                $0.add(ModelEntity(mesh: .generateBox(size: physicalMetrics.convert(.init(minVolumetricLength), to: .meters) - 0.07), materials: [UnlitMaterial(color: .clear)]))
            }
            AcrylClock(idol: idol)
                .frame(width: physicalMetrics.convert(15, from: .centimeters),
                       height: physicalMetrics.convert(10, from: .centimeters))
                .frame(depth: physicalMetrics.convert(7, from: .centimeters))
                .simultaneousGesture(TapGesture().onEnded {
                    isWindowHandleVisible = switch isWindowHandleVisible {
                    case .automatic, .visible: .hidden
                    case .hidden: .visible
                    }
                })
            if isWindowHandleVisible == .visible {
                Button { openWindow(id: "Main") } label: { Image(systemName: "gearshape.2") }
            }
        }
        .persistentSystemOverlays(isWindowHandleVisible)
    }
}

#Preview(immersionStyle: .mixed) {
    VolumetricView(minVolumetricLength: 300, idol: .init(name: "橘ありす"))
}
