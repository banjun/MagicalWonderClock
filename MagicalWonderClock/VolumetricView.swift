import SwiftUI
import RealityKit
import RealityKitContent

struct VolumetricView: View {
    @Environment(\.physicalMetrics) private var physicalMetrics

    var body: some View {
        RealityView { content in
            let scene = try! await Entity(named: "Scene", in: realityKitContentBundle)
            content.add(scene)
        }
        .frame(minWidth: physicalMetrics.convert(15, from: .centimeters),
               maxWidth: physicalMetrics.convert(15, from: .centimeters),
               minHeight: physicalMetrics.convert(10, from: .centimeters),
               maxHeight: physicalMetrics.convert(10, from: .centimeters))
    }
}

#Preview(immersionStyle: .mixed) {
    VolumetricView()
}
