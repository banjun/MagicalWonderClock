import SwiftUI
import RealityKit
import RealityKitContent
import Ikemen

struct VolumetricView: View {
    @Environment(\.physicalMetrics) private var physicalMetrics

    var body: some View {
        RealityView { content in
            let scene = try! await Entity(named: "Scene", in: realityKitContentBundle)
            content.add(scene)

            do {
                let idols = try await Idol.find(name: "Arisu Tachibana") // TODO: UI for search text and choose one
                NSLog("%@", "idols found: \(idols)")
                guard let idol = idols.first else { return }
                guard let idolImageData = await idol.idolListImageURL() else { return }
                let idolImageFile = FileManager.default.temporaryDirectory.appendingPathComponent("idol.png")
                try idolImageData.write(to: idolImageFile)

                let idolEntity = scene.findEntity(named: "Idol")! as! ModelEntity
                let idolImageTexture = try! await TextureResource(contentsOf: idolImageFile)
                idolEntity.model!.materials[0] = (idolEntity.model!.materials[0] as! ShaderGraphMaterial) ※ {
                    try! $0.setParameter(name: "image", value: .textureResource(idolImageTexture))
                }
                if let color = idol.color {
                    let backgroundEntity = scene.findEntity(named: "Background")! as! ModelEntity
                    backgroundEntity.model!.materials[0] = (backgroundEntity.model!.materials[0] as! ShaderGraphMaterial) ※ {
                        try! $0.setParameter(name: "color", value: .color(color))
                    }
                }
            } catch {
                NSLog("%@", "error = \(String(describing: error))")
            }
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
