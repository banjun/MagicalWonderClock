import Foundation
import RealityKit
import CoreGraphics
import SwiftUI

/// the RCP file values and hardcoded accessors
public final class SceneFile {
    public let scene: Entity
    public let idolImageEntity: ModelEntity
    public let idolImageRatio: Double
    public let nameEntity: ModelEntity
    public let nameEntitySize: CGSize
    public let backgroundEntity: ModelEntity

    static private var scene: Entity?

    public init() async throws {
        if let loaded = Self.scene {
            scene = await loaded.clone(recursive: true)
        } else {
            scene = try await Entity(named: "Scene", in: realityKitContentBundle)
            Self.scene = scene
        }
        idolImageEntity = await scene.findEntity(named: "Idol")! as! ModelEntity
        nameEntity = await scene.findEntity(named: "Name")! as! ModelEntity
        backgroundEntity = await scene.findEntity(named: "Background")! as! ModelEntity
        let idolImageEntityExtents = await idolImageEntity.visualBounds(relativeTo: nil).extents
        idolImageRatio = Double(idolImageEntityExtents.x / idolImageEntityExtents.y)
        let nameEntityExtents = await nameEntity.visualBounds(relativeTo: nil).extents
        nameEntitySize = CGSize(width: CGFloat(nameEntityExtents.x), height: CGFloat(nameEntityExtents.y))
    }

    // custom shaders must be set in RCP file
    private func setShaderGraphMaterial(of modelEntity: ModelEntity, name: String, value: MaterialParameters.Value) {
        var material = modelEntity.model!.materials[0] as! ShaderGraphMaterial
        try! material.setParameter(name: name, value: value)
        modelEntity.model!.materials[0] = material
    }

    public func setIdolImage(_ image: TextureResource) {
        setShaderGraphMaterial(of: idolImageEntity, name: "image", value: .textureResource(image))
    }

    public func setBackgroundColor(_ color: CGColor) {
        setShaderGraphMaterial(of: backgroundEntity, name: "color", value: .color(color))
    }

    public func replaceNameEntity(with attachment: ViewAttachmentEntity) {
        attachment.transform = nameEntity.parent!.convert(transform: nameEntity.transform, to: nil) // use world coordinate for simplicity
        attachment.scale = .one // reset scales as it's manipulated as components are created in pure RCP
        scene.addChild(attachment)
        nameEntity.isEnabled = false
    }
}
