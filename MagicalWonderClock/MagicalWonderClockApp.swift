import SwiftUI

@main
struct MagicalWonderClockApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        let minVolumetricLength: CGFloat = 300 // lower limit seems to be around 300pt
        WindowGroup(id: "Volumetric") {
            ZStack {
                // make the image front aligned within lower depth limit
                Spacer().frame(depth: minVolumetricLength / 2)
                VolumetricView()
            }
        }
        .defaultSize(width: 15, height: 10, depth: 7, in: .centimeters)
        .windowStyle(.volumetric)
        .windowResizability(.contentSize)
    }
}
