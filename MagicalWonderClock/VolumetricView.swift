import SwiftUI
import RealityKit

struct VolumetricView: View {
    let minVolumetricLength: CGFloat
    @Environment(\.physicalMetrics) private var physicalMetrics

    var body: some View {
        ZStack(alignment: .bottom) {
            // make the image front aligned within lower depth limit
            RealityView {
                $0.add(ModelEntity(mesh: .generateBox(size: physicalMetrics.convert(.init(minVolumetricLength), to: .meters) - 0.07), materials: [UnlitMaterial(color: .clear)]))
            }
            AcrylClock()
                .frame(width: physicalMetrics.convert(15, from: .centimeters),
                       height: physicalMetrics.convert(10, from: .centimeters))
                .frame(depth: physicalMetrics.convert(7, from: .centimeters))
        }
    }
}

#Preview(immersionStyle: .mixed) {
    VolumetricView(minVolumetricLength: 300)
}
