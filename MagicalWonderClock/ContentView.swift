import SwiftUI
import RealityKit
import RealityKitContent

private extension View {
    func stackWidth(minWidth: CGFloat = 200) -> some View {
        frame(minWidth: minWidth, maxWidth: .infinity)
    }
}

struct ContentView: View {
    @AppStorage("searchText") private var searchText: String = ""
    @State private var idols: [Idol] = []
    @State private var selectedIdol: Idol?
    @AppStorage("lastSelectedIdol") private var lastSelectedIdol: Data?
    @State private var image: UIImage?

    var body: some View {
        VStack(alignment: .center) {
            MainTitle(text: "Magical Wonder Clock")
            HStack(alignment: .top, spacing: 20) {
                SourcePane(idols: idols, searchText: $searchText, selectedIdol: $selectedIdol, search: search).stackWidth()
                
                if let selectedIdol {
                    EditorPane(idol: selectedIdol, image: $image).stackWidth()
                } else {
                    EmptyPane().stackWidth()
                }

                if let selectedIdol, let image = image?.pngData() {
                    PreviewPane(idol: selectedIdol, image: image).stackWidth()
                } else {
                    EmptyPane().stackWidth()
                }
            }
            .padding()
        }
        .onAppear {
            if let lastSelectedIdol {
                selectedIdol = try? JSONDecoder().decode(Idol.self, from: lastSelectedIdol)
            }
        }
        .onChange(of: selectedIdol) { _, new in
            lastSelectedIdol = try? JSONEncoder().encode(new)
            image = nil
        }
    }

    private func search() {
        guard !searchText.isEmpty else { return }
        Task {
            idols = try await Idol.find(name: searchText)
            selectedIdol = idols.first
        }
    }

    struct MainTitle: View {
        let text: String
        var body: some View {
            Text(text).fontDesign(.serif).font(.largeTitle).foregroundColor(.secondary).padding(.top, 40)
        }
    }

    struct PaneTitle: View {
        let text: String
        var body: some View {
            HStack {
                Text(text).font(.title)
                Spacer()
            }
            .padding()
        }
    }

    struct SourcePane: View {
        let idols: [Idol]
        @Binding var searchText: String
        @Binding var selectedIdol: Idol?
        let search: () -> Void
        var body: some View {
            VStack() {
                PaneTitle(text: "Idol")
                Form {
                    TextField("Idol Name", text: $searchText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit(search)
                    IdolList(idols: idols, selectedIdol: $selectedIdol)
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
    }

    struct EditorPane: View {
        let idol: Idol
        @Binding var image: UIImage?
        @State private var idolListImage: UIImage?
        @State private var offsetX: CGFloat = 0
        @State private var dragStartOffsetX: CGFloat?
        let ratio = 0.6 / 0.755
        let imageViewMaxHeight: CGFloat = 150
        var body: some View {
            VStack {
                PaneTitle(text: "Editor")
                if let idolListImage {
                    Color.clear
                        .aspectRatio(ratio, contentMode: .fit)
                        .overlay {
                            Image(uiImage: idolListImage).resizable().aspectRatio(contentMode: .fill)
                                .offset(x: offsetX)
                        }
                        .frame(maxHeight: imageViewMaxHeight)
                        .clipShape(.rect)
                        .gesture(DragGesture().onChanged {
                            if dragStartOffsetX == nil {
                                dragStartOffsetX = offsetX
                            }
                            let maxTranslation = (idolListImage.size.width - idolListImage.size.height * ratio) * (imageViewMaxHeight / idolListImage.size.height) / 2
                            offsetX = max(-maxTranslation, min(maxTranslation, dragStartOffsetX! + $0.translation.width))
                        }.onEnded { _ in
                            dragStartOffsetX = nil
                            clipImage()
                        })
                } else {
                    ProgressView()
                        .task {
                            guard let data = await idol.idolListImageURL(),
                                  let idolListImage = UIImage(data: data) else {
                                self.image = ImageRenderer(content: Color.gray).uiImage
                                return
                            }
                            self.idolListImage = idolListImage
                            clipImage()
                        }
                }
            }
            .onChange(of: idol) { _, _ in idolListImage = nil }
        }

        @MainActor private func clipImage() {
            guard let idolListImage else { return }
            let canvasSize = CGSize(width: 2048, height: 2048)
            image = ImageRenderer(
                content: Color.clear
                    .aspectRatio(ratio, contentMode: .fit)
                    .overlay {
                        Image(uiImage: idolListImage).resizable().aspectRatio(contentMode: .fill)
                            .offset(x: offsetX * canvasSize.height / imageViewMaxHeight)
                    }
                    .clipShape(.rect)
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    // scale to square texture
                    .scaleEffect(CGSize(width: 1 / ratio, height: 1))
            ).uiImage
        }
    }

    struct EmptyPane: View {
        var body: some View {
            Text("Select Idol to Edit")
        }
    }

    struct PreviewPane: View {
        let idol: Idol
        let image: Data
        @State private var previewRotation: Angle = .zero
        @State private var previewRotationOnDragStart: Angle?
        @Environment(\.openWindow) var openWindow
        var body: some View {
            VStack {
                let input = AcrylClock.Input(idol: idol, image: image)
                PaneTitle(text: "Preview")
                AcrylClock(input: input, startSpinAnimationOnLoad: true, onTapGesture: {
                    $0.toggleAnimations()
                })
                .id(input)
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
                    openWindow(id: "Volumetric", value: AcrylClock.Input(idol: idol, image: image))
                } label: {
                    Text("Place \(idol.name) Clock")
                        .shadow(color: .black, radius: 1)
                }
                .tint(idol.color.map(Color.init(cgColor:)))
                .padding()
            }
        }
    }
}

#Preview("ContentView", windowStyle: .automatic) {
    ContentView()
}

import Ikemen
#Preview("Source", windowStyle: .automatic) {
    struct P: View {
        @State private var searchText = ""
        @State private var selectedIdol: Idol?
        var body: some View {
            ContentView.SourcePane(idols: [
                .橘ありす ※ {$0.name += "1"},
                .橘ありす ※ {$0.name += "2"},
                .橘ありす ※ {$0.name += "3"},
            ], searchText: $searchText, selectedIdol: $selectedIdol, search: {})
        }
    }
    return P()
}

#Preview("Editor", windowStyle: .automatic) {
    struct P: View {
        @State private var image: UIImage?
        var body: some View {
            ContentView.EditorPane(idol: .橘ありす, image: $image)
        }
    }
    return P()
}
