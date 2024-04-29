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
    @Binding private var isWindowHandleVisible: Visibility

    init(idol: Idol, startSpinAnimationOnLoad: Bool = false, isWindowHandleVisible: Binding<Visibility> = .constant(Visibility.automatic), onTapGesture: ((Self) -> Void)? = nil) {
        self.idol = idol
        self.startSpinAnimationOnLoad = startSpinAnimationOnLoad
        self._isWindowHandleVisible = isWindowHandleVisible
        self.onTapGesture = onTapGesture
    }

    var body: some View {
        RealityView { content, attachments in
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

                let nameEntity = scene.findEntity(named: "Name")!
                let nameAttachment = attachments.entity(for: "Name")!
                nameAttachment.transform = scene.convert(transform: nameEntity.transform, from: nameEntity.parent!) // use scene coordinate for simplicity
                nameAttachment.scale = .one // reset scales as it's manipulated as components are created in pure RCP
//                nameAttachment.position.z += 0.01 // front shift by the thickness of name entity
                scene.addChild(nameAttachment)
                nameEntity.isEnabled = false
            } catch {
                NSLog("%@", "error = \(String(describing: error))")
            }

            if startSpinAnimationOnLoad {
                startSpinAnimation()
            }
        } update: { content, attachments in
            guard let scene = content.entities.first else { return }
            scene.transform.rotation = simd_quatf(.init(angle: yaw, axis: .y))
        } attachments: {
            Attachment(id: "Name") {
                Name(name: (idol.schemaNameEn ?? idol.schemaNameJa ?? idol.name).uppercased())
                // NOTE: possibly visionOS 1.2 bug: an Attachment accidentally take overs the parent window persistentSystemOverlays and it causes uncontrollable visibility of the window handle at the top view hierarchy. as a workaround, we propagate parent state into this layer.
                    .persistentSystemOverlays(isWindowHandleVisible)
            }
        }
        .onTapGesture {
            onTapGesture?(self)
        }
    }

    struct Name: View {
        let name: String
        @Environment(\.physicalMetrics) private var physicalMetrics
        var body: some View {
            EmptyView()
            let pointsPerMeter: Double = 1360.0 // NOTE: physicalMetrics sometimes is affected by something and returns 685.7549438476562 while the expected is 1360.0
            // let width = physicalMetrics.convert(6, from: .centimeters)
            // let height = physicalMetrics.convert(6, from: .millimeters)
            // let stroke = physicalMetrics.convert(4, from: .millimeters)
            // _ = {NSLog("%@", "physicalMetrics = \(physicalMetrics), width = \(width), height = \(height)"); return 0}()
            let width = 0.06 * pointsPerMeter
            let height = 0.006 * pointsPerMeter
            let stroke: Double = 40 //0.06 * pointsPerMeter
            OutlineStringView(
                text: name,
                font: {UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .headline).withDesign(.serif)!, size: height * 2)},
                textColor: .white,
                strokeWidth: stroke,
                strokeColor: UIColor(red: 0.75, green: 0.61, blue: 0.42, alpha: 1),
                size: .init(width: width, height: height))
            .frame(width: width, height: height)
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
