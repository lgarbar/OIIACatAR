# Workspace Rule: GitHub Issue Synchronization & Project Management

## Repository Context
- **Repository:** `lgarbar/OIIACatAR`
- **Primary Branch:** `main`
- **Project Roadmap:** Consult [`ROADMAP.md`](file:///Users/danielgarcia-barnett/Desktop/Coding/Funsies/OIIACatAR/ROADMAP.md) for the active technical phases and architecture.

---

## 🔄 Automatic GitHub Issue Synchronization Protocol

Whenever you finish implementing, updating, or refactoring any module or phase in this project:

### 1. Identify the Corresponding Issue & Phase
Refer to the project issue mapping:
- **Phase 1: AR Foundation & World-Locked Cat Placement**
  - **Issue:** [#1](https://github.com/lgarbar/OIIACatAR/issues/1) &bull; **Label:** `phase-1`
  - **Key Modules:** `ARSessionManager.swift`, `CatAppState.swift`, AR plane anchoring & raycasting
- **Phase 2: OIIA OIIA Levitation, Spin & Rave Engine**
  - **Issue:** [#2](https://github.com/lgarbar/OIIACatAR/issues/2) &bull; **Label:** `phase-2`
  - **Key Modules:** `RaveActionController.swift`, `ContentView.swift`, spin/levitate animation, audio sync, rave lights, haptics
- **Phase 3: Photo-to-3D Pipeline**
  - **Issue:** [#3](https://github.com/lgarbar/OIIACatAR/issues/3) &bull; **Label:** `phase-3`
  - **Key Modules:** Vision background removal (`VNGenerateForegroundInstanceMaskRequest`), Image-to-USDZ hot-swap, `ModelHotSwapService.swift`
- **Phase 4: Gesture "Petting" Trigger**
  - **Issue:** [#4](https://github.com/lgarbar/OIIACatAR/issues/4) &bull; **Label:** `phase-4`
  - **Key Modules:** `PettingGestureRecognizer.swift`, 3D bounding-box stroke recognizer, particle feedback, auto-rave trigger

---

### 2. Commenting on the Issue
Upon completing work on a module or submodule:
- Use the GitHub MCP tool `add_issue_comment` (or `issue_write`) to post an update comment on the issue.
- **Comment Format:**
  - **What was implemented / updated**: Summary of code changes and files created or modified.
  - **Acceptance Criteria Verification**: Check off the specific items in the issue's technical acceptance criteria that were met.
  - **Verification Steps / Testing**: Brief note on how it was verified (build status, simulator, unit tests, or code checks).
  - **Commit Reference**: Include git commit hash(es) associated with the change.

---

### 3. Closing or Updating Issue State
- If **all** technical acceptance criteria for the phase are fulfilled and the phase is fully implemented and tested:
  - Update the issue state to `closed` with `state_reason: "completed"` using `issue_write`:
    ```json
    {
      "method": "update",
      "owner": "lgarbar",
      "repo": "OIIACatAR",
      "issue_number": <number>,
      "state": "closed",
      "state_reason": "completed"
    }
    ```
  - Post a final closing summary comment detailing the completed deliverables.
- If the phase is partially completed:
  - Leave the issue `open`.
  - Check off the completed acceptance criteria boxes in the issue description or leave a status progress comment.

---

### 4. Git Commit Hygiene
- In git commit messages, reference the associated GitHub issue number (e.g. `feat(ar): add ARSessionManager for horizontal plane detection (closes #1)` or `feat(rave): implement spin loop in RaveActionController (#2)`).
