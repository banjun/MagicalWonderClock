import SwiftUI
import RealityKit
import RealityKitContent

struct AcrylClock: View {
    struct Input: Codable, Hashable {
        var idol: Idol
        var image: Data?
    }
    let idol: Idol
    @State private var image: Data?
    let startSpinAnimationOnLoad: SpinAnimation
    enum SpinAnimation { case never, once, infinite }
    let onTapGesture: ((Self) -> Void)?
    @State private var yaw: Angle2D = .zero
    @State private var timer: Timer? {
        didSet { oldValue?.invalidate() }
    }
    @State private var nameEntitySize: CGSize = .zero
    @Binding private var isWindowHandleVisible: Visibility

    @State private var sceneFile: SceneFile?
    private let tickTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var hourAngle = Angle2D.degrees(0)
    @State private var minuteAngle = Angle2D.degrees(0)
    @State private var secondAngle = Angle2D.degrees(0)
    private let playsSoundEffect: Bool

    init(input: Input, playsSoundEffect: Bool = false, startSpinAnimationOnLoad: SpinAnimation = .never, isWindowHandleVisible: Binding<Visibility> = .constant(Visibility.automatic), onTapGesture: ((Self) -> Void)? = nil) {
        self.idol = input.idol
        self.image = input.image
        self.startSpinAnimationOnLoad = startSpinAnimationOnLoad
        self._isWindowHandleVisible = isWindowHandleVisible
        self.onTapGesture = onTapGesture
        self.playsSoundEffect = playsSoundEffect
    }

    var body: some View {
        RealityView { content, attachments in
            let sceneFile: SceneFile
            do {
                sceneFile = try await SceneFile()
                content.add(sceneFile.scene)
                self.sceneFile = sceneFile
            } catch {
                NSLog("%@", "error = \(String(describing: error))")
                return
            }

            if let image {
                do {
                    let idolImageFile = try await DownloadFolder.shared.saveIdolImage(idol: idol, image: image)
                    sceneFile.setIdolImage(try await TextureResource(contentsOf: idolImageFile))
                } catch {
                    NSLog("%@", "error = \(String(describing: error))")
                }
            }

            if let color = idol.color {
                sceneFile.setBackgroundColor(color)
            }

            nameEntitySize = sceneFile.nameEntitySize
            sceneFile.replaceNameEntity(with: attachments.entity(for: "Name")!)

            switch startSpinAnimationOnLoad {
            case .never: break
            case .once: startSpinAnimation(infinite: false, duration: 1)
            case .infinite: startSpinAnimation(infinite: true)
            }
        } update: { content, attachments in
            guard let scene = content.entities.first else { return }
            scene.transform.rotation = simd_quatf(.init(angle: yaw, axis: .y))

            guard let sceneFile else { return }
            sceneFile.hourHandEntity.transform.rotation = .init(.init(angle: hourAngle, axis: .z))
            sceneFile.minuteHandEntity.transform.rotation = .init(.init(angle: minuteAngle, axis: .z))
            sceneFile.secondHandEntity.transform.rotation = .init(.init(angle: secondAngle, axis: .z))
        } attachments: {
            Attachment(id: "Name") {
                Name(name: (idol.schemaNameEn ?? idol.schemaNameJa ?? idol.name).uppercased(), nameEntitySize: nameEntitySize)
                // NOTE: possibly visionOS 1.2 bug: an Attachment accidentally take overs the parent window persistentSystemOverlays and it causes uncontrollable visibility of the window handle at the top view hierarchy. as a workaround, we propagate parent state into this layer.
                    .persistentSystemOverlays(isWindowHandleVisible)
            }
        }
        .onTapGesture {
            onTapGesture?(self)
        }
        .task {
            guard image == nil else { return }
            image = await idol.idolListImageURL()
        }
        .onReceive(tickTimer) { _ in
            let now = Date()
            hourAngle = .degrees(Double(-30 * Calendar.autoupdatingCurrent.component(.hour, from: now)))
            minuteAngle = .degrees(Double(-6 * Calendar.autoupdatingCurrent.component(.minute, from: now)))
            secondAngle = .degrees(Double(-6 * Calendar.autoupdatingCurrent.component(.second, from: now)))
            if playsSoundEffect {
                sceneFile?.playHandSoundEffect()
            }
        }
    }

    struct Name: View {
        let name: String
        var nameEntitySize: CGSize
        @Environment(\.physicalMetrics) private var physicalMetrics
        var body: some View {
            EmptyView()
            let pointsPerMeter: Double = 1360.0 // NOTE: physicalMetrics sometimes is affected by something and returns 685.7549438476562 while the expected is 1360.0
            // let width = physicalMetrics.convert(6, from: .centimeters)
            // let height = physicalMetrics.convert(6, from: .millimeters)
            // let stroke = physicalMetrics.convert(4, from: .millimeters)
            // _ = {NSLog("%@", "physicalMetrics = \(physicalMetrics), width = \(width), height = \(height)"); return 0}()
            let width = nameEntitySize.width * pointsPerMeter
            let height = nameEntitySize.height * pointsPerMeter
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

    func startSpinAnimation(infinite: Bool, duration: Double = 5) {
        var start = Date().timeIntervalSince1970
        let from: Double = yaw.radians.truncatingRemainder(dividingBy: 2 * .pi)
        let to: Double = from + 2 * .pi
        timer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { _ in
            let now = Date().timeIntervalSince1970
            let elapsed = now - start
            guard elapsed < duration else {
                if !infinite { timer = nil }
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
            startSpinAnimation(infinite: true)
        }
    }
}

#Preview("AcrylClock", windowStyle: .volumetric) {
    AcrylClock(input: .init(idol: .橘ありす, image: nil))
}
