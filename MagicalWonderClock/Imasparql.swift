import Foundation
import SwiftSparql
import LinkPresentation
import UniformTypeIdentifiers

struct Idol: Codable {
    var name: String
    var idolListURLString: String?
    var colorHex: String?
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
                .schemaName(is: Var("schemaName"))
                .optional { $0
                    .imasColor(is: Var("colorHex"))
                    .imasIdolListURL(is: Var("idolListURLString"))
                }
                .filter(.CONTAINS(v: Var("schemaName"), sub: name))
                                       // FIXME: SwiftSparql.Serializer generates extra parens for LCASE
                                       //                .filter(.CONTAINS(.init(.LCASE(Expression(Var("schemaName")))), Expression(stringLiteral: name.lowercased())))
                .triples)))
        .fetch()
    }
}
