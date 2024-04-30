import Foundation
import SwiftSparql
import LinkPresentation
import UniformTypeIdentifiers

struct Idol: Codable, Hashable {
    var name: String
    var schemaNameJa: String?
    var schemaNameEn: String?
    var idolListURLString: String?
    var colorHex: String?
}
extension Idol {
    /// sample expected data
    static let 橘ありす: Idol = .init(name: "橘ありす", schemaNameJa: "橘ありす", schemaNameEn: "Arisu Tachibana", idolListURLString: "https://idollist.idolmaster-official.jp/detail/20104", colorHex: "5881C1")
}
extension Idol {
    var idolListURL: URL? { idolListURLString.flatMap { URL(string: $0) }}
    var color: CGColor? {
        guard let colorHex, colorHex.count == 6,
              let r = Int(colorHex.dropFirst(0).prefix(2), radix: 16),
              let g = Int(colorHex.dropFirst(2).prefix(2), radix: 16),
              let b = Int(colorHex.dropFirst(4).prefix(2), radix: 16) else { return nil }
        return CGColor(red: .init(r) / 255, green: .init(g) / 255, blue: .init(b) / 255, alpha: 1)
    }

    func idolListImageURL() async -> Data? {
        guard let idolListURL else { return nil }
        guard let imageProvider = try? await LPMetadataProvider().startFetchingMetadata(for: idolListURL).imageProvider else { return nil }
        return try? await withCheckedThrowingContinuation { c in
            imageProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                if let error {
                    c.resume(throwing: error)
                } else {
                    c.resume(returning: url.flatMap {try? Data(contentsOf: $0)})
                }
            }
        }
    }
}

extension Idol {
    static func find(name: String) async throws -> [Idol] {
        try await Request(
            endpoint: URL(string: "https://sparql.crssnky.xyz/spql/imas/query")!,
            select: .init(where: .init(patterns: subject(Var("idol"))
                .rdfTypeIsImasIdol()
                .rdfsLabel(is: Var("name"))
                .schemaName(is: Var("schemaName")) // just for filter
                .filter(.CONTAINS(.init(.LCASE(Expression(Var("schemaName")))), Expression(stringLiteral: name.lowercased())))
                .optional { $0
                    .schemaName(is: Var("schemaNameJa")) // for capture jp
                    .filter(.LANGMATCHES(.init(.LANG(.init(Var("schemaNameJa")))), "ja"))
                }
                .optional { $0
                    .schemaName(is: Var("schemaNameEn")) // for capture en
                    .filter(.LANGMATCHES(.init(.LANG(.init(Var("schemaNameEn")))), "en"))
                }
                .optional { $0.imasColor(is: Var("colorHex")) }
                .optional { $0.imasIdolListURL(is: Var("idolListURLString")) }
                .triples)))
        .fetch()
    }
}
