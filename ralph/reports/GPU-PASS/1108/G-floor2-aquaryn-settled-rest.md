# G-floor2-aquaryn-settled-rest: settled resting pose for Aquaryn (F39#6 close-out; GPU High)

Frames: `tb/gpu-frames-1108` d6d0f5a1b, High, seed 2042, `tb/floor2` b8ab0b384.
- The creature stage is on in the tree on both sides, as on main.
- Capture: `phase2_capture_creatures.gd --biome=water --only=aquaryn --poses=idle,resting,fainted`.
- base = tree as is.
- arm = base + `FLOOR2-AQUAPOSE/overlay_aquaryn_rest.json` (`creature_pose_settle.json` floor2_aquaryn_scope + settled_rest, rest only): belly on the sand, legs folded, snout lowered.
- Idle and fainted are unchanged.

Sheet: idle, resting and fainted, stacked at full size, on F39#6's brief and recorded defect, as in `G-stage-r3-f41-13-f39-6.md`.

Render check: resting 13.0% of pixels changed; idle 3.7% and fainted 4.1% (noise). Blank frames: 0 of 3 per side.

Batch `G-ar`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22, so this is a confirming batch.

Fit: linear, slope 1.5419, intercept −2.7102, r 0.967, anchor RMSE 0.254. No warnings.

## Verdict: SHIP. +0.72, 3/3. High maps **7.47**: 0.03 under the bar, so no Medium yet

| Row | Base | Arm | Gain | Judges preferring arm | Previous |
|---|---|---|---|---|---|
| F39#6 creature faint state (aquaryn) | 6.75 | **7.47** | **+0.72** | **3/3** | 7.24 (`G-x13`, stage only) |

Raw Bar A, base → arm (judges a, b, c): 5.8, 6.6, 6.0 → 6.3, 7.0, 6.5. Mapped arm: 7.00, 8.08, 7.31.

Recorded defect: base PARTIAL 2/3, FIXED 1/3 (judge b); arm PARTIAL 2/3, FIXED 1/3 (judge b).

**Does High map 7.5 or above? No: 7.47.** That is not above the top anchor, in a confirming batch. F39#6 sits on the bar but does not meet it, so **no Medium capture yet**. Under the close-out exception, one more near-bar change should take it across. That change is the fainted pose (below).

The base here (6.75) is close to `G-x13`'s 7.24 on the same stage, within scatter.

## What the judges see
- **Resting, arm (3/3):** "a believable low crouch with the head lowered to the sand. It is grounded and reads as resting", "a head-down crouch that reads as resting".
- **Resting, base (3/3):** "lies sideways with its legs raised in the air. It reads as dead or ragdolled, not resting, which leaves no difference between resting and fainted".
- **Fainted, unchanged, the same on both sides:** the head is down on the sand, so "the alert head is gone, so it reads as defeated". But:
  - "the limbs stick up stiffly" in a "dead bug" pose (3/3);
  - "the shadow offset suggests the body hovers slightly above the sand" (judges a and b).
  - This is why judges a and c keep the defect at PARTIAL on both sides.
- **Idle (both sides):** strong. A cyan-scaled sea dragon, clearly taller than the trainer, in a bright Tidewake scene.
- **Other notes:**
  - No visible elemental trait, such as aqua glow on the eyes or markings (judges b and c).
  - The shallow-water ring behind the dragon is "a flat banded gradient disc, which reads as an artefact" (judge b).

## The next change (scene): a grounded faint
Give the fainted pose a relaxed, physically settled collapse: legs folded or slack, body weight on the sand, a contact shadow. All three judges name it. It is the one remaining recorded-defect gap, and the likeliest step across 7.5.
