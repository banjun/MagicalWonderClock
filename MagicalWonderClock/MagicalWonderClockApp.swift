import SwiftUI

@main
struct MagicalWonderClockApp: App {
    var body: some Scene {
        WindowGroup(id: "Main") {
            ContentView()
        }
        .defaultSize(width: 600, height: 600)

        let minVolumetricLength: CGFloat = 300 // lower limit seems to be around 300pt
        WindowGroup(id: "Volumetric", for: Idol.self) { $idol in
            VolumetricView(minVolumetricLength: minVolumetricLength, idol: idol!)
        }
        .defaultSize(width: minVolumetricLength, height: minVolumetricLength, depth: minVolumetricLength)
        .windowStyle(.volumetric)
        .windowResizability(.contentSize)
    }
}
