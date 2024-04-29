import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(\.openWindow) var openWindow
    @AppStorage("searchText") private var searchText: String = ""
    @State private var idols: [Idol] = []
    @State private var selectedIdol: Idol?
    @AppStorage("lastSelectedIdol") private var lastSelectedIdol: Data?
    @State private var previewRotation: Angle = .zero
    @State private var previewRotationOnDragStart: Angle?

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
                    Spacer()
                    Text("Preview").font(.title).fixedSize().padding()
                    AcrylClock(idol: selectedIdol, startSpinAnimationOnLoad: true, onTapGesture: {
                        $0.toggleAnimations()
                    })
                    .id(selectedIdol)
                    .frame(minWidth: 256, minHeight: 256)
                    .rotation3DEffect(previewRotation, axis: .y)
//                    .animation(.easeOut, value: previewRotation)
                    .offset(z: -150) // NOTE: z length might be change. affects collision (drag)
                    .offset(y: 70)
                    .gesture(DragGesture().onChanged { value in
                        if previewRotationOnDragStart == nil {
                            previewRotationOnDragStart = previewRotation
                        }
                        previewRotation = .degrees((previewRotationOnDragStart!.degrees + value.translation.width / 5).truncatingRemainder(dividingBy: 360))
                    }.onEnded { _ in
                        previewRotationOnDragStart = nil
                    })
                    .background(Color.black.opacity(0.1), in: .rect(cornerRadius: 40))
                    .padding()
                    Spacer().layoutPriority(1)
                    Button {
                        openWindow(id: "Volumetric", value: selectedIdol)
                    } label: {
                        Text("Place \(selectedIdol.name) Clock")
                            .shadow(color: .black, radius: 1)
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
