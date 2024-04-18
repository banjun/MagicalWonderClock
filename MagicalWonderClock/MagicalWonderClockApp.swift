//
//  MagicalWonderClockApp.swift
//  MagicalWonderClock
//
//  Created by banjun on R 6/04/18.
//

import SwiftUI

@main
struct MagicalWonderClockApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
