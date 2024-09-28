import SwiftUI

@main
struct MagicalWonderClockApp: App {
    var body: some Scene {
        WindowGroup(id: "Main") {
            ContentView()
        }
        .defaultSize(width: 900, height: 600)
        .volumeWorldAlignment(.gravityAligned)
        
        let minVolumetricLength: CGFloat = 300 // lower limit seems to be around 300pt
        WindowGroup(id: "Volumetric", for: AcrylClock.Input.self) { $input in
            VolumetricView(minVolumetricLength: minVolumetricLength, input: input!)                .handlesExternalEvents(preferring: [], allowing: []) // causes the main window active on re-opening the app, or open a main window), without activating this group.
        }
        .defaultSize(width: minVolumetricLength, height: minVolumetricLength, depth: minVolumetricLength)
        .windowStyle(.volumetric)
        .windowResizability(.contentSize)
        .volumeWorldAlignment(.gravityAligned)
    }
}

