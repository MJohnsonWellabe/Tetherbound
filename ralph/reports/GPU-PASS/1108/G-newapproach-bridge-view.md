# G-newapproach-bridge-view: landing tree cleared (A) and stone waymark (B) (F40#8; GPU High)

Frames: `tb/gpu-frames-1108` 4b5648a93, High, main e2138671a (#900), seed 2042.
- Capture: `phase2_capture_locations.gd --biome=cloudreach --subset=three_bells_bridge --views=close`, at day, golden and night.
- base = main as is (landing_tree_clear: LandingTree171).
- armA = base + `NEWAPPROACH-BRIDGETREE/overlay_bridge_landing_tree.json`: also clears LandingTree926, the trunk in front of the stand.
- armB = armA + `world_payoffs.anchor_waymark`: the Storm Anchor's cyan column becomes a 2.1 m stone waymark (stone #8c8676, cap #a8873f).

Sheets: day, golden and night stacked at full size. Two paired sets on F40#8's brief and recorded defect, base against A and base against B. The base sheet is the same in both.

Render check: A changes 15–17% of pixels against base; B changes 18–22%. Blank frames: 0 of 3 per side.

Batch `G-bv`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.0836, intercept 0.1628, r 0.894, anchor RMSE 0.619. No warnings.

## Verdict: SHIP arm B. B gains +1.48 at 3/3; A gains only +0.44.

| Pair | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| **B (tree cleared + stone waymark)** | 5.29 | **6.77** | **+1.48** | **3/3** |
| A (tree cleared only) | 5.29 | 5.73 | +0.44 | 3/3 |

Raw Bar A (judges a, b, c):
- base: 4.5, 4.8, 4.9;
- A: 4.8, 5.3, 5.3;
- B: 5.7, 6.2, 6.4.
- Mapped B: 6.34, 6.88, 7.10.

The board has 5.85; B takes F40#8 to 6.77 at High.

Recorded defect, the saturated cyan posts and rings competing with the landmarks:
- base: PRESENT 1/3, PARTIAL 2/3. The trunk hides most of the post.
- A: PRESENT 3/3.
- B: FIXED for judges b and c, PARTIAL for judge a.

**A on its own** clears the trunk, but it reveals the cyan post in full. All three judges call it "a flat saturated cyan pole with copper rings ... a placeholder or gameplay gizmo" that clashes with the bell gate. Its +0.44 is under 0.5, and F40#8 is not near the bar, so A would not ship on its own.

## What the judges see on B
- A pale stone obelisk with a copper cap and a soft pale-blue band. It "sits with Cloudreach's pale stratified stone and the bridge's copper bells", grounded on a plinth (3/3).
- It reads at day, golden and night. At night the band glows gently "without shouting". This matches the GPU lane's luminance check: peak 172, below the trainer and the moon.
- **Remaining issues:**
  - a simple primitive form (smooth tapering faces, "pencil or rocket"), with no carving, weathering or moss (3/3);
  - posterised colour banding on the right-hand cliff and in the sky, most visible by day (3/3; on all sides, so not caused by the arm).
- The yellow launch-platform pointer in the recorded defect is not in these frames. It stays open for the aerie and launch views.

## What would add the most
1. **Waymark detail (scene or new_art):** carving, weathering, a little moss and a lantern glow at night. Judge b calls this new_art: a carved hero form in the obelisk direction.
2. **Cliff banding (scene):** fix the posterised, banded cliff texture and the sky banding behind Three Bells.
3. **Other bridge views (scene):** carry the stone waymark to the aerie and launch platform, and check the yellow pointer there.
