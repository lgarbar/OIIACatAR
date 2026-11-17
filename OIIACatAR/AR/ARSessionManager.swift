import RealityKit
import ARKit
import UIKit
import Combine

/// Manages ARSession configuration, horizontal plane detection, raycasting, and world-locked cat placement.
@MainActor
public final class ARSessionManager: NSObject, ARSessionDelegate {
    
    // MARK: - Properties
    public private(set) weak var arView: ARView?
    public private(set) var catAnchor: AnchorEntity?
    public private(set) var catModelEntity: ModelEntity?
    
    private var appState: CatAppState?
    private var tapGestureRecognizer: UITapGestureRecognizer?
    
    /// Notification hook triggered whenever the cat ModelEntity is placed or replaced.
    public var onCatModelUpdated: ((ModelEntity) -> Void)?
    
    // MARK: - Lifecycle & Setup
    
    public func setup(arView: ARView, appState: CatAppState) {
        self.arView = arView
        self.appState = appState
        
        arView.session.delegate = self
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        setupTapGesture(on: arView)
    }
    
    private func setupTapGesture(on arView: ARView) {
        if let existing = tapGestureRecognizer {
            arView.removeGestureRecognizer(existing)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tap)
        self.tapGestureRecognizer = tap
    }
    
    // MARK: - Tap-to-Place Raycasting
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView, let appState = appState else { return }
        
        // Prevent duplicate placement; user can tap Reset to place anew
        guard !appState.isCatPlaced else { return }
        
        let tapLocation = gesture.location(in: arView)
        
        // 1. Raycast against existing horizontal planes first, fallback to estimated planes
        let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
        
        guard let firstResult = results.first else {
            DispatchQueue.main.async {
                appState.statusMessage = "No surface detected here. Try aiming at the floor or table."
            }
            return
        }
        
        placeCat(at: firstResult.worldTransform)
    }
    
    /// Instantiates and positions the world-locked AnchorEntity and Cat ModelEntity.
    public func placeCat(at worldTransform: simd_float4x4) {
        guard let arView = arView else { return }
        
        // Remove existing anchor if present
        if let existingAnchor = catAnchor {
            arView.scene.removeAnchor(existingAnchor)
            catAnchor = nil
            catModelEntity = nil
        }
        
        // 1. Create a world-locked AnchorEntity at the exact raycast world transform
        let anchor = AnchorEntity(world: worldTransform)
        anchor.name = "WorldLockedCatAnchor"
        
        // 2. Load or generate the 3D Cat ModelEntity
        let catEntity = ProceduralCatFactory.loadCatModel()
        catEntity.name = "OIIACatEntity"
        
        // 3. Orient cat towards the camera at placement time
        if let cameraTransform = arView.session.currentFrame?.camera.transform {
            let cameraPos = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
            let catWorldPos = SIMD3<Float>(worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z)
            let dir = cameraPos - catWorldPos
            let angle = atan2(dir.x, dir.z)
            catEntity.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
        }
        
        // 4. Attach cat to anchor, and anchor to scene
        anchor.addChild(catEntity)
        arView.scene.addAnchor(anchor)
        
        self.catAnchor = anchor
        self.catModelEntity = catEntity
        
        DispatchQueue.main.async { [weak self] in
            self?.appState?.onCatPlaced()
        }
        
        onCatModelUpdated?(catEntity)
    }
    
    // MARK: - Model Hot-Swapping (USDZ)
    
    /// Replaces the active cat model with an external `.usdz` asset, preserving the world anchor.
    public func replaceCatModel(with url: URL) {
        guard let anchor = catAnchor else {
            print("Cannot replace cat model: No active anchor placed.")
            return
        }
        
        do {
            let newModelEntity = try ModelEntity.loadModel(contentsOf: url)
            newModelEntity.name = "CustomHotSwappedCat"
            
            // Retain orientation and position of the previous cat model
            if let current = catModelEntity {
                newModelEntity.orientation = current.orientation
                newModelEntity.position = current.position
                current.removeFromParent()
            }
            
            // Ensure collision component is active on the new model
            newModelEntity.generateCollisionShapes(recursive: true)
            
            anchor.addChild(newModelEntity)
            self.catModelEntity = newModelEntity
            
            onCatModelUpdated?(newModelEntity)
            print("Successfully hot-swapped cat model from: \(url.lastPathComponent)")
        } catch {
            print("Failed to hot-swap cat model: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Reset Session
    
    public func reset() {
        guard let arView = arView else { return }
        
        if let anchor = catAnchor {
            arView.scene.removeAnchor(anchor)
            catAnchor = nil
            catModelEntity = nil
        }
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        DispatchQueue.main.async { [weak self] in
            self?.appState?.reset()
        }
    }
    
    // MARK: - ARSessionDelegate
    
    nonisolated public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if anchor is ARPlaneAnchor {
                Task { @MainActor [weak self] in
                    self?.appState?.onPlaneDetected()
                }
                break
            }
        }
    }
    
    nonisolated public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let trackingState = camera.trackingState
        Task { @MainActor [weak self] in
            guard let self = self, let appState = self.appState else { return }
            switch trackingState {
            case .normal:
                appState.trackingStateDescription = "Tracking Normal"
            case .limited(let reason):
                switch reason {
                case .excessiveMotion:
                    appState.trackingStateDescription = "Limited: Excessive Motion"
                case .insufficientFeatures:
                    appState.trackingStateDescription = "Limited: Low Light / Few Features"
                case .initializing:
                    appState.trackingStateDescription = "AR Initializing..."
                case .relocalizing:
                    appState.trackingStateDescription = "Relocalizing..."
                @unknown default:
                    appState.trackingStateDescription = "Tracking Limited"
                }
            case .notAvailable:
                appState.trackingStateDescription = "Tracking Unavailable"
            }
        }
    }
}
