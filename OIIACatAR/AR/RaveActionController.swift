import RealityKit
import ARKit
import AVFoundation
import Combine
import UIKit

/// Manages the OIIA OIIA Rave Engine:
/// - Smooth elevation (+0.25m over 0.3s)
/// - Continuous high-speed spin (4π rad/s) with vertical sine-wave bobbing
/// - 3 Orbiting RGB PointLights pulsing at 120 BPM
/// - Seamless audio playback (oiia_loop.mp3 or synthesized AVAudioEngine fallback)
/// - Strict resource cleanup on stop and deinit
public final class RaveActionController {
    
    // MARK: - State & References
    public private(set) var isRaveActive: Bool = false
    
    private weak var arView: ARView?
    private weak var catEntity: ModelEntity?
    private var initialTransform: Transform?
    
    // Animation subscription
    private var updateSubscription: Cancellable?
    private var raveStartTime: TimeInterval = 0
    private var currentYaw: Float = 0
    
    // Orbiting lights
    private var pointLights: [PointLight] = []
    
    // Audio engine components
    private var audioPlayer: AVAudioPlayer?
    private var synthAudioEngine: SynthesizedRaveAudioEngine?
    
    // MARK: - Lifecycle
    
    public init() {}
    
    deinit {
        stopRave()
    }
    
    // MARK: - Rave Control
    
    /// Launches the Rave mode on the specified Cat ModelEntity within the ARView scene.
    public func startRave(catEntity: ModelEntity, in arView: ARView) {
        // Prevent duplicate rave triggers
        guard !isRaveActive else { return }
        
        self.arView = arView
        self.catEntity = catEntity
        self.initialTransform = catEntity.transform
        self.isRaveActive = true
        self.raveStartTime = CACurrentMediaTime()
        self.currentYaw = 0
        
        // 1. Setup and start audio
        startAudioPlayback()
        
        // 2. Spawn 3 orbiting RGB PointLights
        spawnOrbitingLights(on: catEntity.parent ?? catEntity)
        
        // 3. Subscribe to RealityKit per-frame update loop
        updateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.handleFrameUpdate(deltaTime: Float(event.deltaTime))
        }
    }
    
    /// Halts rave mode, cleans up animations, audio, and lights, and restores resting transform.
    public func stopRave() {
        guard isRaveActive else { return }
        isRaveActive = false
        
        // 1. Cancel RealityKit update loop subscription
        updateSubscription?.cancel()
        updateSubscription = nil
        
        // 2. Stop and release audio
        stopAudioPlayback()
        
        // 3. Remove orbiting lights
        for light in pointLights {
            light.removeFromParent()
        }
        pointLights.removeAll()
        
        // 4. Restore original resting transform
        if let initial = initialTransform, let cat = catEntity {
            cat.transform = initial
        }
        
        initialTransform = nil
        catEntity = nil
        arView = nil
    }
    
    // MARK: - Animation Frame Loop
    
    private func handleFrameUpdate(deltaTime: Float) {
        guard let cat = catEntity, let initial = initialTransform else { return }
        
        let elapsed = Float(CACurrentMediaTime() - raveStartTime)
        
        // 1. Smooth Elevation: +0.25m over 0.3s with quadratic ease-out
        let ascendDuration: Float = 0.3
        let ascendProgress = min(1.0, elapsed / ascendDuration)
        let easeOut = ascendProgress * (2.0 - ascendProgress)
        let currentElevation = easeOut * 0.25
        
        // 2. Continuous Yaw Spin: 4 * .pi rad/s (2 full revolutions per second)
        let spinSpeed: Float = 4.0 * .pi
        currentYaw += spinSpeed * deltaTime
        let spinRotation = simd_quatf(angle: currentYaw, axis: [0, 1, 0])
        
        // 3. Vertical Sine-Wave Bob: 120 BPM = 2.0 Hz
        let bpmFrequency: Float = 2.0 // 120 / 60
        let omega = 2.0 * .pi * bpmFrequency
        let bobAmplitude: Float = 0.02 // 2cm bob
        let bob = sin(elapsed * omega) * bobAmplitude
        
        // Apply composite position & rotation
        let baseY = initial.translation.y
        cat.position = SIMD3<Float>(
            initial.translation.x,
            baseY + currentElevation + bob,
            initial.translation.z
        )
        cat.orientation = spinRotation * initial.rotation
        
        // 4. Update Orbiting RGB PointLights
        updateOrbitingLights(elapsed: elapsed, omega: omega, baseElevation: baseY + currentElevation)
    }
    
    // MARK: - Orbiting RGB PointLights
    
    private func spawnOrbitingLights(on parentEntity: Entity) {
        let colors: [UIColor] = [.systemRed, .systemGreen, .systemBlue]
        
        for i in 0..<3 {
            let light = PointLight()
            light.name = "RaveLight_\(i)"
            light.light.color = colors[i]
            light.light.intensity = 5000
            light.light.attenuationRadius = 1.2
            
            parentEntity.addChild(light)
            pointLights.append(light)
        }
    }
    
    private func updateOrbitingLights(elapsed: Float, omega: Float, baseElevation: Float) {
        guard pointLights.count == 3 else { return }
        
        let orbitRadius: Float = 0.32
        let orbitSpeed: Float = 2.0 * .pi // 1 complete orbit revolution per second
        
        for (index, light) in pointLights.enumerated() {
            let phaseOffset = Float(index) * (2.0 * .pi / 3.0)
            let currentAngle = elapsed * orbitSpeed + phaseOffset
            
            // Orbit coordinates
            let x = cos(currentAngle) * orbitRadius
            let z = sin(currentAngle) * orbitRadius
            let y = baseElevation + 0.12 // slightly above cat center
            light.position = SIMD3<Float>(x, y, z)
            
            // 120 BPM rhythmic intensity pulse
            let pulse = 0.5 + 0.5 * sin(elapsed * omega + phaseOffset)
            light.light.intensity = 3000 + 7000 * pulse
        }
    }
    
    // MARK: - Audio Playback Engine
    
    private func startAudioPlayback() {
        // Configure AVAudioSession
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("AVAudioSession error: \(error.localizedDescription)")
        }
        
        // 1. Attempt to load bundled oiia_loop.mp3
        if let soundURL = Bundle.main.url(forResource: "oiia_loop", withExtension: "mp3") {
            do {
                let player = try AVAudioPlayer(contentsOf: soundURL)
                player.numberOfLoops = -1 // Infinite loop
                player.prepareToPlay()
                player.play()
                self.audioPlayer = player
                return
            } catch {
                print("Failed to initialize AVAudioPlayer with oiia_loop.mp3: \(error)")
            }
        }
        
        // 2. Zero-asset fallback: Synthesized 120 BPM tone loop via AVAudioEngine
        let synth = SynthesizedRaveAudioEngine()
        synth.start()
        self.synthAudioEngine = synth
    }
    
    private func stopAudioPlayback() {
        if let player = audioPlayer {
            player.stop()
            self.audioPlayer = nil
        }
        
        if let synth = synthAudioEngine {
            synth.stop()
            self.synthAudioEngine = nil
        }
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Synthesized 120 BPM Fallback Engine

/// Generates and seamlessly loops a bouncy 120 BPM electronic rave melody using AVAudioEngine.
final class SynthesizedRaveAudioEngine {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var isPlaying = false
    
    init() {
        setupEngine()
    }
    
    deinit {
        stop()
    }
    
    private func setupEngine() {
        engine.attach(playerNode)
        let mainMixer = engine.mainMixerNode
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        engine.connect(playerNode, to: mainMixer, format: format)
    }
    
    func start() {
        guard !isPlaying else { return }
        
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        // 120 BPM = 0.5s per beat; 4-beat loop = 2.0s = 88,200 samples
        let bpm: Double = 120.0
        let secondsPerBeat = 60.0 / bpm
        let totalDuration = secondsPerBeat * 4.0
        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else { return }
        
        // Iconic bouncy arpeggio frequencies: D5, E5, D5, A4, D5, E5, G5, E5
        let melodyNotes: [Double] = [587.33, 659.25, 587.33, 440.0, 587.33, 659.25, 783.99, 659.25]
        let framesPerNote = Int(frameCount) / melodyNotes.count
        
        for frame in 0..<Int(frameCount) {
            let noteIdx = (frame / framesPerNote) % melodyNotes.count
            let freq = melodyNotes[noteIdx]
            let timeInNote = Double(frame % framesPerNote) / sampleRate
            let noteDuration = Double(framesPerNote) / sampleRate
            
            // Pluck envelope: rapid attack with smooth decay
            let envelope = max(0.0, 1.0 - (timeInNote / noteDuration))
            
            // Lead synth wave (sine + harmonics)
            let phase = 2.0 * .pi * freq * Double(frame) / sampleRate
            let lead = (sin(phase) + 0.35 * sin(phase * 2.0) + 0.15 * sin(phase * 3.0)) * envelope * 0.22
            
            // 120 BPM Kick-bass thump on quarter beats
            let beatFrame = frame % Int(sampleRate * secondsPerBeat)
            let timeInBeat = Double(beatFrame) / sampleRate
            let kickFreq = max(45.0, 150.0 - timeInBeat * 350.0)
            let kickEnv = max(0.0, 1.0 - timeInBeat * 4.5)
            let kick = sin(2.0 * .pi * kickFreq * timeInBeat) * kickEnv * 0.38
            
            let mixedSample = Float(lead + kick)
            leftChannel[frame] = mixedSample
            rightChannel[frame] = mixedSample
        }
        
        do {
            try engine.start()
            playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            playerNode.play()
            isPlaying = true
        } catch {
            print("SynthesizedRaveAudioEngine failed to start: \(error)")
        }
    }
    
    func stop() {
        guard isPlaying else { return }
        playerNode.stop()
        engine.stop()
        isPlaying = false
    }
}
