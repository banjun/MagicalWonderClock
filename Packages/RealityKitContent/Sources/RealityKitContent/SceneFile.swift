import Foundation
import RealityKit
import RealityFoundation
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
    public let clockEntity: ModelEntity
    public let secondHandEntity: ModelEntity

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
        clockEntity = await scene.findEntity(named: "Clock")! as! ModelEntity
        let idolImageEntityExtents = await idolImageEntity.visualBounds(relativeTo: nil).extents
        idolImageRatio = Double(idolImageEntityExtents.x / idolImageEntityExtents.y)
        let nameEntityExtents = await nameEntity.visualBounds(relativeTo: nil).extents
        nameEntitySize = CGSize(width: CGFloat(nameEntityExtents.x), height: CGFloat(nameEntityExtents.y))

        secondHandEntity = if let e = (await scene.findEntity(named: "SecondHand") as? ModelEntity) { e } else {
            await Task { @MainActor in
                var handMaterial = PhysicallyBasedMaterial()
                handMaterial.baseColor = .init(tint: .black)
                handMaterial.roughness = 0.1

                var secondMeshDescriptor = MeshDescriptor(name: "Second")
                func x(y: Float) -> Float {
                    let a: Float = 5
                    let t: Float = -0.7
                    return 0.1 * cos(a * (y - t)) * exp(-a * (y - t))
                }
                let points = [Float](stride(from: -1, to: 1, by: 0.02))
                let vertices: [SIMD3<Float>] = (points.map {
                    SIMD3<Float>(max(0.01, x(y: $0)), $0, 0)
                } + points.reversed().map {
                    SIMD3<Float>(-max(0.01, x(y: $0)), $0, 0)
                })
                    .map { $0 * 0.025 }
                    .map { SIMD3<Float>($0.x, $0.y + 0.01, $0.z) }
                secondMeshDescriptor.positions = .init(vertices)
                secondMeshDescriptor.primitives = .polygons([UInt8(vertices.count)], Array(0..<(UInt32(vertices.count))))

                let e = try! await ModelEntity(mesh: .init(from: [secondMeshDescriptor]), materials: [handMaterial])
                e.name = "SecondHand"
                e.position.z = 0.01
                return e
            }.value
        }

        Task { @MainActor in
            guard scene.findEntity(named: "ClockAnchor") == nil else { return }
            let clockAnchorEntity = Entity()
            clockAnchorEntity.name = "ClockAnchor"
            clockAnchorEntity.transform.rotation = scene.convert(transform: clockEntity.transform, from: clockEntity).rotation
            clockAnchorEntity.position = clockEntity.position(relativeTo: scene)
            clockAnchorEntity.addChild(secondHandEntity)
            scene.addChild(clockAnchorEntity)
        }
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
