import SwiftUI
import Observation

/// Central observable application state for OIIACatAR.
@Observable
@MainActor
public final class CatAppState {
    // MARK: - Core State
    public var isCatPlaced: Bool = false
    public var isRaveActive: Bool = false
    public var statusMessage: String = "Scan the floor and tap to place your cat."
    
    // MARK: - Tracking State
    public var isPlaneDetected: Bool = false
    public var trackingStateDescription: String = "Initializing..."
    
    public init() {}
    
    // MARK: - Actions
    public func onPlaneDetected() {
        if !isCatPlaced {
            isPlaneDetected = true
            statusMessage = "Surface detected! Tap anywhere to place your cat."
        }
    }
    
    public func onCatPlaced() {
        isCatPlaced = true
        statusMessage = "Cat placed! Tap 'OIIA OIIA' to launch Rave Mode."
    }
    
    public func onRaveStateChanged(active: Bool) {
        isRaveActive = active
        if active {
            statusMessage = "🐱 OIIA OIIA RAVE IN FULL EFFECT! 🐱"
        } else {
            statusMessage = isCatPlaced ? "Cat resting. Tap 'OIIA OIIA' to party again." : "Scan the floor and tap to place your cat."
        }
    }
    
    public func reset() {
        isCatPlaced = false
        isRaveActive = false
        isPlaneDetected = false
        statusMessage = "Scan the floor and tap to place your cat."
        trackingStateDescription = "Resetting session..."
    }
}
