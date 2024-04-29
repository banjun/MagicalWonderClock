import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(\.openWindow) var openWindow
    @AppStorage("searchText") private var searchText: String = ""
    @State private var idols: [Idol] = []
    @State private var selectedIdol: Idol?
    @AppStorage("lastSelectedIdol") private var lastSelectedIdol: Data?

    var body: some View {
        HStack {
            VStack {
                Text("Magical Wonder Clock")
                    .fontDesign(.serif)
                    .font(.title)
                    .padding()
                Form {
                    TextField("Idol Name", text: $searchText)
                        .onSubmit(search)
                    IdolList(idols: idols, selectedIdol: $selectedIdol)
                }
                Spacer()
            }
            .padding()

            if let selectedIdol {
                VStack {
                    AcrylClock(idol: selectedIdol).id(selectedIdol)
                    Spacer()
                    Button("Place \(selectedIdol.name) Clock") {
                        openWindow(id: "Volumetric", value: selectedIdol)
                    }
                    .tint(selectedIdol.color.map(Color.init(cgColor:)))
                    .padding()
                }
            }
        }
        .onAppear {
            if let lastSelectedIdol {
                selectedIdol = try? JSONDecoder().decode(Idol.self, from: lastSelectedIdol)
            }
        }
        .onChange(of: selectedIdol) { _, new in
            lastSelectedIdol = try? JSONEncoder().encode(new)
        }
    }

    private func search() {
        guard !searchText.isEmpty else { return }
        Task {
            idols = try await Idol.find(name: searchText)
            selectedIdol = idols.first
        }
    }
}

struct IdolList: View {
    var idols: [Idol]
    @Binding var selectedIdol: Idol?

    var body: some View {
        Picker("", selection: $selectedIdol) {
            ForEach(idols, id: \.name) { idol in
                HStack {
                    Circle()
                        .foregroundColor(idol.color.map(Color.init(cgColor:)))
                        .frame(width: 32, height: 32)
                    Spacer().frame(width: 16)
                    Text(idol.name)
                }
                .tag(Idol?.some(idol))
            }
        }
        .pickerStyle(.inline)
    }
}

#Preview(windowStyle: .automatic) {
    IdolList(idols: [.init(name: "橘ありす1")], selectedIdol: .constant(nil))
}
