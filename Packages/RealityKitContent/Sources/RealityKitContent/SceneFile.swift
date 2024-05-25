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
                    let a: Float = 10
                    let t: Float = -0.85
                    return 0.05 * cos(a * (y - t)) * exp(-a * (y - t))
                }
                let points = [Float](stride(from: -1, through: 1, by: 0.02))
                let vertices1: [SIMD3<Float>] = points.map { SIMD3<Float>(max(0.01, x(y: $0)), $0, 0) } // right side, bottom to top
                let vertices2: [SIMD3<Float>] = vertices1.reversed().map { SIMD3<Float>(-$0.x, $0.y, $0.z) } // left side, top to bottom
                let vertices3: [SIMD3<Float>] = vertices2.reversed().map { SIMD3<Float>($0.x, $0.y, $0.z - 0.0005 / 0.025) } // left in back side, bottom to top
                let vertices4: [SIMD3<Float>] = vertices1.reversed().map { SIMD3<Float>($0.x, $0.y, $0.z - 0.0005 / 0.025) } // right in back side, top to bottom
                let vertices: [SIMD3<Float>] = (vertices1 + vertices2 + vertices3 + vertices4)
                    .map { (v: SIMD3<Float>) -> SIMD3<Float> in v * 0.025 } // scale
                    .map { SIMD3<Float>($0.x, $0.y + 0.01, $0.z) } // traslate
                secondMeshDescriptor.positions = .init(vertices)
                let polygonVerticesCounts: [UInt8] = [
                    UInt8(vertices1.count + vertices2.count),
                    UInt8(vertices3.count + vertices4.count),
                    UInt8(vertices4.count + vertices1.count),
                    UInt8(vertices2.count + vertices3.count),
                ]
                let verticesIndices1: [UInt32] = (0..<vertices1.count).map {UInt32($0)}
                let verticesIndices2: [UInt32] = (0..<vertices2.count).map {UInt32(vertices1.count + $0)}
                let verticesIndices3: [UInt32] = (0..<vertices3.count).map {UInt32(vertices1.count + vertices2.count + $0)}
                let verticesIndices4: [UInt32] = (0..<vertices4.count).map {UInt32(vertices1.count + vertices2.count + vertices3.count + $0)}
                let polygonVerticesIndices1: [UInt32] = verticesIndices1 + verticesIndices2
                let polygonVerticesIndices2: [UInt32] = verticesIndices3 + verticesIndices4
                let polygonVerticesIndices3: [UInt32] = [UInt32](verticesIndices4.reversed()) + [UInt32](verticesIndices1.reversed())
                let polygonVerticesIndices4: [UInt32] = [UInt32](verticesIndices2.reversed()) + [UInt32](verticesIndices3.reversed())
                secondMeshDescriptor.primitives = .polygons(polygonVerticesCounts, [
                    polygonVerticesIndices1,
                    polygonVerticesIndices2,
                    polygonVerticesIndices3,
                    polygonVerticesIndices4,
                ].flatMap {$0})

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
