import Foundation
import UniformTypeIdentifiers

final actor DownloadFolder {
    static let shared: DownloadFolder = .init()

    private let idolImageFolder: URL

    private init() {
        let library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
        idolImageFolder = URL(filePath: library).appendingPathComponent("idolImages")
        try! FileManager.default.createDirectory(at: idolImageFolder, withIntermediateDirectories: true)
    }

    func saveIdolImage(idol: Idol, image: Data) throws -> URL {
        let idolImageFilenameBase: String = String(idol.name.data(using: .utf8)!.base64EncodedString().prefix(32))
        let idolImageFile = idolImageFolder.appendingPathComponent(idolImageFilenameBase).appendingPathExtension(for: UTType.png)
        try image.write(to: idolImageFile)
        return idolImageFile
    }
}
