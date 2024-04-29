import SwiftUI
import RealityKit
import RealityKitContent
import Ikemen
import CryptoKit
import UniformTypeIdentifiers

struct AcrylClock: View {
    let idol: Idol
    let startSpinAnimationOnLoad: Bool
    let onTapGesture: ((Self) -> Void)?
    @State private var yaw: Angle2D = .zero
    @State private var timer: Timer? {
        didSet { oldValue?.invalidate() }
    }

    init(idol: Idol, startSpinAnimationOnLoad: Bool = false, onTapGesture: ((Self) -> Void)? = nil) {
        self.idol = idol
        self.startSpinAnimationOnLoad = startSpinAnimationOnLoad
        self.onTapGesture = onTapGesture
    }

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

            if startSpinAnimationOnLoad {
                startSpinAnimation()
            }
        } update: { content in
            guard let scene = content.entities.first else { return }
            scene.transform.rotation = simd_quatf(.init(angle: yaw, axis: .y))
        }
        .onTapGesture {
            onTapGesture?(self)
        }
    }

    func startSpinAnimation() {
        var start = Date().timeIntervalSince1970
        let duration: Double = 5
        let from: Double = yaw.radians.truncatingRemainder(dividingBy: 2 * .pi)
        let to: Double = from + 2 * .pi
        timer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { _ in
            let now = Date().timeIntervalSince1970
            let elapsed = now - start
            guard elapsed < duration else {
                start = now
                return
            }
            let k: Double = 4
            func base(_ t: Double) -> Double {
                1 / (1 + exp(-k * t)) - 0.5
            }
            let t = 0.5 / base(1) * base(2 * (elapsed / duration) - 1) + 0.5
            yaw = .init(radians: from * t + to * (1 - t))
        }
    }
    func stopAnimations() {
        timer = nil
    }
    func toggleAnimations() {
        if timer != nil {
            stopAnimations()
        } else {
            startSpinAnimation()
        }
    }
}

#Preview {
    AcrylClock(idol: .init(name: "橘ありす"))
}
