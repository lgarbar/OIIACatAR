import SwiftUI
import RealityKit

/// Main application view: displays the full-screen ARView alongside status and rave controls.
public struct ContentView: View {
    
    // MARK: - State & Managers
    @State private var appState = CatAppState()
    @State private var arSessionManager = ARSessionManager()
    @State private var raveController = RaveActionController()
    
    // Shared ARView reference
    @State private var arView = ARView(frame: .zero)
    
    // Animation pulse for rave button
    @State private var raveButtonPulse: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // MARK: - 1. Full-Screen AR View Container
            ARViewContainer(arView: arView, sessionManager: arSessionManager, appState: appState)
                .ignoresSafeArea()
            
            // MARK: - 2. HUD Overlay
            VStack {
                // Top Status Bar
                HStack(alignment: .top) {
                    // Status Pill
                    HStack(spacing: 8) {
                        Image(systemName: appState.isRaveActive ? "sparkles" : (appState.isCatPlaced ? "cat.fill" : "camera.viewfinder"))
                            .foregroundColor(appState.isRaveActive ? .yellow : .accentColor)
                            .symbolEffect(.bounce, value: appState.isRaveActive)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appState.statusMessage)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            if !appState.isCatPlaced && !appState.trackingStateDescription.isEmpty {
                                Text(appState.trackingStateDescription)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(appState.isRaveActive ? Color.yellow.opacity(0.8) : Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    Spacer()
                    
                    // Reset Placement Button
                    Button(action: handleReset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                    .accessibilityLabel("Reset Cat Placement")
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer()
                
                // Bottom Control Section
                VStack(spacing: 14) {
                    if !appState.isCatPlaced {
                        // Floor tap hint banner
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 16))
                            Text("Tap any detected flat surface to place cat")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.65), in: Capsule())
                        .shadow(radius: 6)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        // The Iconic "OIIA OIIA" Rave Toggle Button
                        Button(action: toggleRaveMode) {
                            HStack(spacing: 12) {
                                Text(appState.isRaveActive ? "🛑" : "🐱")
                                    .font(.system(size: 24))
                                
                                Text(appState.isRaveActive ? "STOP RAVE" : "✨ OIIA OIIA RAVE ✨")
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                                    .tracking(1.0)
                                    .foregroundColor(.white)
                                
                                Text(appState.isRaveActive ? "🛑" : "🎶")
                                    .font(.system(size: 22))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(
                                Group {
                                    if appState.isRaveActive {
                                        LinearGradient(
                                            colors: [Color.purple, Color.pink, Color.yellow],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        appState.isRaveActive ? Color.yellow : Color.white.opacity(0.4),
                                        lineWidth: appState.isRaveActive ? 2.5 : 1.0
                                    )
                            )
                            .shadow(
                                color: appState.isRaveActive ? Color.purple.opacity(0.7) : Color.black.opacity(0.3),
                                radius: appState.isRaveActive ? 16 : 8,
                                x: 0,
                                y: 4
                            )
                            .scaleEffect(raveButtonPulse ? 1.03 : 1.0)
                        }
                        .padding(.horizontal, 28)
                        .animation(.easeInOut(duration: 0.2), value: appState.isRaveActive)
                    }
                }
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            arSessionManager.setup(arView: arView, appState: appState)
        }
        .onChange(of: appState.isRaveActive) { _, isRaving in
            if isRaving {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    raveButtonPulse = true
                }
            } else {
                withAnimation(.default) {
                    raveButtonPulse = false
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleRaveMode() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if appState.isRaveActive {
            raveController.stopRave()
            appState.onRaveStateChanged(active: false)
        } else {
            guard let catEntity = arSessionManager.catModelEntity else { return }
            raveController.startRave(catEntity: catEntity, in: arView)
            appState.onRaveStateChanged(active: true)
        }
    }
    
    private func handleReset() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        raveController.stopRave()
        arSessionManager.reset()
    }
}

// MARK: - ARViewContainer (UIViewRepresentable)

/// Bridges RealityKit's ARView into SwiftUI.
public struct ARViewContainer: UIViewRepresentable {
    public let arView: ARView
    public let sessionManager: ARSessionManager
    public let appState: CatAppState
    
    public init(arView: ARView, sessionManager: ARSessionManager, appState: CatAppState) {
        self.arView = arView
        self.sessionManager = sessionManager
        self.appState = appState
    }
    
    public func makeUIView(context: Context) -> ARView {
        return arView
    }
    
    public func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview {
    ContentView()
}
