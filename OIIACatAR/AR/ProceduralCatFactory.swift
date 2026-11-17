import RealityKit
import UIKit

/// Factory responsible for loading or procedurally generating a low-poly 3D Tuxedo Cat model.
public enum ProceduralCatFactory {
    
    // MARK: - Public API
    
    /// Loads `default_cat.usdz` from the main bundle if present; otherwise generates
    /// a procedural low-poly sitting tuxedo cat with zero external asset dependencies.
    public static func loadCatModel() -> ModelEntity {
        if let url = Bundle.main.url(forResource: "default_cat", withExtension: "usdz"),
           let loadedEntity = try? ModelEntity.loadModel(contentsOf: url) {
            return loadedEntity
        }
        return createTuxedoCat()
    }
    
    /// Generates a composite `ModelEntity` representing a faceted, low-poly sitting tuxedo cat.
    /// - Max bounding box: ~0.26m (fits within 0.3m).
    /// - Base centered at `y = 0`.
    /// - Tuxedo coloring: Black body, back, ears, tail, face-sides; White chest, muzzle, paws, tail-tip.
    public static func createTuxedoCat() -> ModelEntity {
        // Base anchor root entity with identity transform
        let root = ModelEntity()
        root.name = "TuxedoCatRoot"
        
        // MARK: - Materials
        var blackMat = SimpleMaterial(color: .black, isMetallic: false)
        blackMat.roughness = 0.95
        
        var whiteMat = SimpleMaterial(color: .white, isMetallic: false)
        whiteMat.roughness = 0.95
        
        var pinkMat = SimpleMaterial(color: UIColor(red: 1.0, green: 0.65, blue: 0.72, alpha: 1.0), isMetallic: false)
        pinkMat.roughness = 0.8
        
        var eyeYellowMat = SimpleMaterial(color: UIColor(red: 1.0, green: 0.85, blue: 0.1, alpha: 1.0), isMetallic: false)
        eyeYellowMat.roughness = 0.2
        
        var pupilBlackMat = SimpleMaterial(color: .black, isMetallic: false)
        pupilBlackMat.roughness = 0.1
        
        // MARK: - 1. Torso & Hindquarters (Black)
        // Lower body / hips sitting base
        let lowerBodyMesh = makeCylinder(height: 0.08, radius: 0.065)
        let lowerBody = ModelEntity(mesh: lowerBodyMesh, materials: [blackMat])
        lowerBody.position = [0, 0.04, -0.01]
        root.addChild(lowerBody)
        
        // Upper torso (tapered chest)
        let upperBodyMesh = makeCone(height: 0.11, radius: 0.06)
        let upperBody = ModelEntity(mesh: upperBodyMesh, materials: [blackMat])
        upperBody.position = [0, 0.12, 0.0]
        upperBody.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0]) // inverted cone tapering down
        root.addChild(upperBody)
        
        // MARK: - 2. Tuxedo White Chest / Bib
        let chestMesh = MeshResource.generateBox(width: 0.065, height: 0.085, depth: 0.025, cornerRadius: 0.008)
        let chest = ModelEntity(mesh: chestMesh, materials: [whiteMat])
        chest.position = [0, 0.10, 0.052]
        root.addChild(chest)
        
        // MARK: - 3. Head (Black base with White Muzzle & Blaze)
        // Head cube
        let headMesh = MeshResource.generateBox(width: 0.085, height: 0.075, depth: 0.080, cornerRadius: 0.012)
        let head = ModelEntity(mesh: headMesh, materials: [blackMat])
        head.position = [0, 0.19, 0.015]
        root.addChild(head)
        
        // White muzzle
        let muzzleMesh = MeshResource.generateBox(width: 0.046, height: 0.030, depth: 0.030, cornerRadius: 0.006)
        let muzzle = ModelEntity(mesh: muzzleMesh, materials: [whiteMat])
        muzzle.position = [0, 0.172, 0.060]
        root.addChild(muzzle)
        
        // White forehead blaze (stripe between eyes)
        let blazeMesh = MeshResource.generateBox(width: 0.016, height: 0.042, depth: 0.005, cornerRadius: 0.002)
        let blaze = ModelEntity(mesh: blazeMesh, materials: [whiteMat])
        blaze.position = [0, 0.205, 0.056]
        root.addChild(blaze)
        
        // Pink nose
        let noseMesh = MeshResource.generateBox(width: 0.012, height: 0.008, depth: 0.008, cornerRadius: 0.002)
        let nose = ModelEntity(mesh: noseMesh, materials: [pinkMat])
        nose.position = [0, 0.182, 0.075]
        root.addChild(nose)
        
        // Big yellow meme cat eyes
        let eyeMesh = MeshResource.generateBox(width: 0.016, height: 0.016, depth: 0.004, cornerRadius: 0.004)
        let leftEye = ModelEntity(mesh: eyeMesh, materials: [eyeYellowMat])
        leftEye.position = [-0.024, 0.198, 0.056]
        root.addChild(leftEye)
        
        let rightEye = ModelEntity(mesh: eyeMesh, materials: [eyeYellowMat])
        rightEye.position = [0.024, 0.198, 0.056]
        root.addChild(rightEye)
        
        // Eye pupils
        let pupilMesh = MeshResource.generateBox(width: 0.006, height: 0.012, depth: 0.002)
        let leftPupil = ModelEntity(mesh: pupilMesh, materials: [pupilBlackMat])
        leftPupil.position = [-0.024, 0.198, 0.059]
        root.addChild(leftPupil)
        
        let rightPupil = ModelEntity(mesh: pupilMesh, materials: [pupilBlackMat])
        rightPupil.position = [0.024, 0.198, 0.059]
        root.addChild(rightPupil)
        
        // MARK: - 4. Ears (Black with Pink Inner Inset)
        let earMesh = makeCone(height: 0.038, radius: 0.020)
        let innerEarMesh = makeCone(height: 0.028, radius: 0.014)
        
        // Left Ear
        let leftEar = ModelEntity(mesh: earMesh, materials: [blackMat])
        leftEar.position = [-0.030, 0.242, 0.010]
        leftEar.orientation = simd_quatf(angle: 0.2, axis: [0, 0, 1])
        root.addChild(leftEar)
        
        let leftInnerEar = ModelEntity(mesh: innerEarMesh, materials: [pinkMat])
        leftInnerEar.position = [-0.030, 0.240, 0.016]
        leftInnerEar.orientation = simd_quatf(angle: 0.2, axis: [0, 0, 1])
        root.addChild(leftInnerEar)
        
        // Right Ear
        let rightEar = ModelEntity(mesh: earMesh, materials: [blackMat])
        rightEar.position = [0.030, 0.242, 0.010]
        rightEar.orientation = simd_quatf(angle: -0.2, axis: [0, 0, 1])
        root.addChild(rightEar)
        
        let rightInnerEar = ModelEntity(mesh: innerEarMesh, materials: [pinkMat])
        rightInnerEar.position = [0.030, 0.240, 0.016]
        rightInnerEar.orientation = simd_quatf(angle: -0.2, axis: [0, 0, 1])
        root.addChild(rightInnerEar)
        
        // MARK: - 5. White Paws (Front "Mittens")
        let pawMesh = MeshResource.generateBox(width: 0.028, height: 0.022, depth: 0.042, cornerRadius: 0.006)
        
        let leftPaw = ModelEntity(mesh: pawMesh, materials: [whiteMat])
        leftPaw.position = [-0.032, 0.011, 0.058]
        root.addChild(leftPaw)
        
        let rightPaw = ModelEntity(mesh: pawMesh, materials: [whiteMat])
        rightPaw.position = [0.032, 0.011, 0.058]
        root.addChild(rightPaw)
        
        // MARK: - 6. Hind Legs (Sitting posture)
        let haunchMesh = makeCylinder(height: 0.065, radius: 0.032)
        
        let leftHaunch = ModelEntity(mesh: haunchMesh, materials: [blackMat])
        leftHaunch.position = [-0.062, 0.035, -0.015]
        leftHaunch.orientation = simd_quatf(angle: .pi / 3, axis: [1, 0, 0])
        root.addChild(leftHaunch)
        
        let rightHaunch = ModelEntity(mesh: haunchMesh, materials: [blackMat])
        rightHaunch.position = [0.062, 0.035, -0.015]
        rightHaunch.orientation = simd_quatf(angle: .pi / 3, axis: [1, 0, 0])
        root.addChild(rightHaunch)
        
        let hindPawMesh = MeshResource.generateBox(width: 0.025, height: 0.018, depth: 0.035, cornerRadius: 0.005)
        let leftHindPaw = ModelEntity(mesh: hindPawMesh, materials: [whiteMat])
        leftHindPaw.position = [-0.068, 0.009, 0.025]
        root.addChild(leftHindPaw)
        
        let rightHindPaw = ModelEntity(mesh: hindPawMesh, materials: [whiteMat])
        rightHindPaw.position = [0.068, 0.009, 0.025]
        root.addChild(rightHindPaw)
        
        // MARK: - 7. Tail (Black with White Tip)
        let tailBaseMesh = makeCylinder(height: 0.10, radius: 0.012)
        let tailBase = ModelEntity(mesh: tailBaseMesh, materials: [blackMat])
        tailBase.position = [0, 0.06, -0.075]
        tailBase.orientation = simd_quatf(angle: -.pi / 4, axis: [1, 0, 0])
        root.addChild(tailBase)
        
        let tailTipMesh = makeCylinder(height: 0.035, radius: 0.012)
        let tailTip = ModelEntity(mesh: tailTipMesh, materials: [whiteMat])
        tailTip.position = [0, 0.11, -0.11]
        tailTip.orientation = simd_quatf(angle: -.pi / 3, axis: [1, 0, 0])
        root.addChild(tailTip)
        
        // MARK: - 8. 3D Collision Bounds & Physics
        // Accurate bounding box covering the entire composite cat entity
        let boxShape = ShapeResource.generateBox(size: [0.18, 0.26, 0.21]).offsetBy(translation: [0, 0.13, -0.015])
        root.components[CollisionComponent.self] = CollisionComponent(shapes: [boxShape], mode: .trigger, filter: .default)
        
        return root
    }
    
    // MARK: - Helper Methods for Backward Compatibility (iOS 17+)
    
    private static func makeCone(height: Float, radius: Float) -> MeshResource {
        if #available(iOS 18.0, *) {
            return MeshResource.generateCone(height: height, radius: radius)
        } else {
            // Faceted pyramid/cone approximation for iOS 17
            return MeshResource.generateBox(width: radius * 1.6, height: height, depth: radius * 1.6, cornerRadius: radius * 0.4)
        }
    }
    
    private static func makeCylinder(height: Float, radius: Float) -> MeshResource {
        if #available(iOS 18.0, *) {
            return MeshResource.generateCylinder(height: height, radius: radius)
        } else {
            // Faceted cylinder approximation for iOS 17
            return MeshResource.generateBox(width: radius * 1.8, height: height, depth: radius * 1.8, cornerRadius: radius * 0.7)
        }
    }
}
