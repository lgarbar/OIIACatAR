# 🐱 OIIACatAR

An Augmented Reality iOS experience built with **RealityKit**, **ARKit**, and **SwiftUI** that places a world-locked 3D cat into your physical room and unleashes the viral **"OIIA OIIA"** meme rave engine: smooth levitation, high-RPM spin, orbiting RGB disco lights, and rhythmic audio.

> **Zero Asset Dependencies:** OIIACatAR is fully runnable immediately without downloading external 3D models or audio tracks. It includes an in-engine procedural low-poly tuxedo cat generator and a synthesized 120 BPM audio engine fallback.

---

## 📸 Overview & Features

- **World-Locked AR Surface Anchoring:** Leverages `ARKit` horizontal plane detection and raycasting to attach a 3D cat onto floors, desks, or tables using a true `AnchorEntity(world:)` world-lock that remains stationary as the camera moves.
- **Procedural Low-Poly Tuxedo Cat:** Hand-crafted composite `ModelEntity` with flat-shaded black and white `SimpleMaterial`s, cute meme eyes, sitting posture, tail, and 3D collision bounds—generated dynamically in code.
- **OIIA OIIA Rave Engine:**
  - **Smooth Levitation:** Ascends `+0.25m` above resting anchor over `0.3s` with quadratic ease-out.
  - **High-RPM Yaw Spin:** Continuous rotation at `4 * .pi` rad/s (2 full revolutions per second) synchronized via RealityKit frame updates (`SceneEvents.Update`).
  - **Vertical Sine-Wave Bob:** 120 BPM vertical bobbing rhythm (2.0 Hz, 2cm amplitude).
  - **Orbiting RGB PointLights:** 3 orbiting point lights (Red, Green, Blue) pulsing light intensity to the 120 BPM tempo.
  - **Audio System:** Plays `oiia_loop.mp3` via `AVAudioPlayer` with seamless infinite looping, or falls back to an in-memory 120 BPM synthesized electronic melody + kick bass via `AVAudioEngine`.
- **Modern Architecture:** Built for iOS 17.0+ with Swift Observation (`@Observable`), Swift 6 concurrency compliance, and XcodeGen project configuration.

---

## 📊 Current Implementation Status

Tracked on [**GitHub Project: OIIACatAR Roadmap #1**](https://github.com/users/lgarbar/projects/1) and [`ROADMAP.md`](file:///Users/danielgarcia-barnett/Desktop/Coding/Funsies/OIIACatAR/ROADMAP.md).

| Phase | Milestone | Scope / Deliverables | Status |
| :---: | :--- | :--- | :---: |
| **Phase 1** | **AR Foundation & World-Locked Cat Placement** | `ARSessionManager.swift`, `CatAppState.swift`, `ProceduralCatFactory.swift`, horizontal raycasting | ✅ **Implemented** &bull; [Issue #1](https://github.com/lgarbar/OIIACatAR/issues/1) *(Needs Device Testing)* |
| **Phase 2** | **OIIA OIIA Levitation, Spin & Rave Engine** | `RaveActionController.swift`, `ContentView.swift`, 4π rad/s spin, RGB light orbits, audio engine | ✅ **Implemented** &bull; [Issue #2](https://github.com/lgarbar/OIIACatAR/issues/2) *(Needs Device Testing)* |
| **Phase 3** | **Photo-to-3D Pipeline** | Vision subject lifting (`VNGenerateForegroundInstanceMaskRequest`), Image-to-USDZ hot-swap | ⚪ **Planned / Backlog** &bull; [Issue #3](https://github.com/lgarbar/OIIACatAR/issues/3) |
| **Phase 4** | **Gesture "Petting" Trigger** | 3D bounding-box stroke recognizer (`PettingGestureRecognizer.swift`), spatial interaction | ⚪ **Planned / Backlog** &bull; [Issue #4](https://github.com/lgarbar/OIIACatAR/issues/4) |

### Completed Capabilities
- [x] Automated Xcode project generation via `project.yml` (XcodeGen).
- [x] Procedural low-poly tuxedo cat generator with black/white flat shading, pink ears/nose, yellow meme eyes, and collision box.
- [x] Surface plane detection and tap-to-place raycasting onto horizontal surfaces.
- [x] World-locked `AnchorEntity(world:)` positioning and camera-facing alignment.
- [x] Smooth levitation (+0.25m over 0.3s) and 60/120fps continuous spin (4π rad/s).
- [x] 120 BPM vertical sine-wave bobbing and 3 orbiting RGB dynamic `PointLight` entities.
- [x] Dual audio engine: `oiia_loop.mp3` loader + synthesized 120 BPM tone loop fallback with `AVAudioEngine`.
- [x] Full-screen SwiftUI interface with frosted glass status pill, reset control, and glowing neon rave toggle.
- [x] Future-ready `replaceCatModel(with url: URL)` hook for Phase 3 USDZ hot-swapping.

---

## 🏛️ Project Architecture

```
OIIACatAR/
├── project.yml                          # Declarative XcodeGen configuration
├── ROADMAP.md                           # Detailed 4-phase technical roadmap & diagrams
├── .gemini/
│   └── GEMINI.md                        # Workspace rule for GitHub PM sync
└── OIIACatAR/
    ├── App/
    │   └── OIIACatARApp.swift           # App entry point (WindowGroup + ContentView)
    ├── Models/
    │   └── CatAppState.swift            # Observable app state (placement, rave, tracking status)
    ├── AR/
    │   ├── ARSessionManager.swift       # ARSession config, plane detection, tap raycasting, world locking
    │   ├── ProceduralCatFactory.swift   # Procedural tuxedo cat mesh generator + default_cat.usdz loader
    │   └── RaveActionController.swift   # Rave engine: levitation, 4π spin, RGB lights, audio synthesis
    └── Views/
        └── ContentView.swift            # ARViewContainer (UIViewRepresentable), HUD pill, rave button
```

### Module Responsibilities

- **`ProceduralCatFactory.swift`**: Constructs the sitting tuxedo cat composite entity using primitive shapes (`MeshResource.generateBox`, `generateCone`, `generateCylinder`) and flat `SimpleMaterial`s. Bounding box is kept under `0.3m` (~`0.26m` height) with the base resting at `y = 0`.
- **`ARSessionManager.swift`**: Configures `ARWorldTrackingConfiguration` with `.horizontal` plane detection. Evaluates tap locations on `ARView`, casts rays against surfaces, and instantiates a world-locked `AnchorEntity(world: transform)`. Includes `replaceCatModel(with:)` preserving world anchor coordinates.
- **`RaveActionController.swift`**: Subscribes to RealityKit's `SceneEvents.Update` to drive frame-synchronized animations. Handles quadratic elevation easing, yaw rotation math, orbiting light coordinates, and audio lifecycle management with strict cleanup on `stopRave()` and `deinit`.
- **`CatAppState.swift`**: Observable model (`@Observable`) binding UI state to AR session events and user actions.
- **`ContentView.swift`**: Full-screen SwiftUI layer hosting the `ARViewContainer` alongside an adaptive HUD overlay with responsive haptics.

---

## 📱 Setup & Running on Physical iPhone

ARKit world tracking and plane detection require a physical iOS device with a camera and A12 Bionic chip or newer.

### 1. Prerequisites
- macOS Sonoma or macOS Sequoia with **Xcode 15.0+** (tested with Xcode 16 / 27).
- [Homebrew](https://brew.sh) installed.
- iPhone running **iOS 17.0+**.

### 2. Generate the Xcode Project
Run XcodeGen from the repository root:
```bash
# Install XcodeGen if not already installed
brew install xcodegen

# Generate OIIACatAR.xcodeproj
xcodegen generate
```

### 3. Open in Xcode & Configure Signing
1. Open the generated project:
   ```bash
   open OIIACatAR.xcodeproj
   ```
2. In Xcode's Project Navigator, select the **OIIACatAR** project at the top.
3. Select the **OIIACatAR** target and go to the **Signing & Capabilities** tab.
4. Under **Signing**, select your personal Apple Developer account from the **Team** dropdown.
5. If necessary, adjust the **Bundle Identifier** (e.g. `com.<your-name>.OIIACatAR`).

### 4. Run on iPhone
1. Connect your iPhone to your Mac via USB or Wi-Fi.
2. On your iPhone, enable Developer Mode:
   - Go to **Settings > Privacy & Security > Developer Mode** and switch it **On**. Restart your phone if prompted.
3. In Xcode, select your physical device from the destination menu (top bar).
4. Press **`Cmd + R`** (or click the Play button) to build and run.
5. On the iPhone, tap **Allow** when prompted for Camera permissions.
6. Aim the camera at the floor or a tabletop, wait for the status pill to indicate surface detection, and **tap the screen** to place your cat!
7. Tap the glowing **"✨ OIIA OIIA RAVE ✨"** button to start the party!

---

## 🎨 Optional Custom Assets Hot-Loading

While the app functions 100% out-of-the-box with zero assets, you can customize the cat and music at any time:

- **Custom 3D Cat (`default_cat.usdz`)**:
  - Drag and drop any `.usdz` 3D model named `default_cat.usdz` into the `OIIACatAR` group in Xcode.
  - Check **"Copy items if needed"** and add to the `OIIACatAR` target.
  - The app will automatically detect and display your custom model instead of the procedural tuxedo cat.
- **Custom Soundtrack (`oiia_loop.mp3`)**:
  - Drag and drop an audio file named `oiia_loop.mp3` into the `OIIACatAR` group in Xcode.
  - The app will automatically play and loop your audio file with `AVAudioPlayer` instead of the synthesized tone engine.

---

## 📄 License

MIT License. See repository for details.
