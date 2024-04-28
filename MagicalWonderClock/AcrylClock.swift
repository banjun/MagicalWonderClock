import SwiftUI
import RealityKit
import RealityKitContent
import Ikemen
import CryptoKit
import UniformTypeIdentifiers

struct AcrylClock: View {
    let idol: Idol
    
    var body: some View {
        RealityView { content in
            let scene = try! await Entity(named: "Scene", in: realityKitContentBundle)
            content.add(scene)

            do {
                guard let idolImageData = await idol.idolListImageURL() else { return }
                guard let library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first else { return }
                let idolImageFolder = URL(filePath: library).appendingPathComponent("idolImages")
                try FileManager.default.createDirectory(at: idolImageFolder, withIntermediateDirectories: true)
                let idolImageFilenameBase: String = String(idol.name.data(using: .utf8)!.base64EncodedString().prefix(32))
                let idolImageFile = idolImageFolder.appendingPathComponent(idolImageFilenameBase).appendingPathExtension(for: UTType.png)
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
    }
}

#Preview {
    AcrylClock(idol: .init(name: "橘ありす"))
}
