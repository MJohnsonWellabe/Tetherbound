# Code-blind judge — Stormwood strike motion (F10#3)

Inputs: 57 frames (seqA day/storm, seqB night/storm, seqC night/storm with reduced motion), contact sheets, LABELS.txt, ART_DIRECTION.md (Stormwood row, weather/phase paragraph), SKILL.md. Pixels only.

## Q1 Telegraph reads as a strike: PARTIAL
- **Spot: yes.** A saturated magenta ring with a darkened disc marks a specific ground patch from t000 (seqA_t000). It stands out against the purple/green scene in every warning frame. Scale is a rough estimate: the trainer (1.80 m, about 260 px tall at the far rim, seqA_t110) against a disc about 1180 px wide nearer the camera suggests a diameter of about 5–6 m. That is closer to a 3 m *radius* than a 3 m diameter. Confirm which one the spec means.
- **Timing: no.** The warning does not progress. In A/B the ring only pulses in brightness (seqA_t040 vs t050 vs t100). In C it is static. There is no shrink, fill, sweep, colour ramp or accelerating beat, and seqA_t110 looks the same as seqA_t010. A player cannot judge when 1.2 s will run out.
- **Impact: partly.** At t120 a bolt lands inside the ring, and the ring turns white (seqA_t120, seqC_t125). But the bolt comes down on the trainer's feet near the **far rim**, not at the ring centre (seqA_t120 bolt base at about y790, ring spans about y730–1040). It is a flat, uniform, straight-edged white cylinder with no branching, jitter or ground burst. It reads as a light pillar or beacon, not as lightning, and it hides the trainer's torso (seqC_t125).
- Ring is cut off by the bottom frame edge in every warning frame (seqA_t000–t110). With this camera the near half of the zone is off-screen.

## Q2 Night merge: PASS (with a caveat)
seqB is pixel-for-pixel the same as seqA apart from rain noise (mean channel diff 1–3/255 at every sample). Mean luminance matches (41 vs 41 in the warning, 115 vs 115 at seqA/B_t120). The warning and bolt keep full contrast in B. This is consistent with the owner ruling that Stormwood has a fixed purple storm and no day/night presentation, but it also means this set does not test a darker night.

## Q3 Reduced-motion flashes: PASS for seqC; A/B note
- seqC has no full-frame wash. Frame mean luminance goes 40 → 58 → 49 → 48 (t110–t130), which is only the bolt and the white ring. There is no strobing. The warning and impact stay readable (seqC_t120–t130), and there is a faint ring afterglow at seqC_t140.
- seqA/B: a single frame-wide wash jumps mean luminance from about 41 to 115 at t120 (2.8×) and decays over about 0.3 s (t140 = 82, t150 = 53). It does not hide play, because the scene gets brighter rather than blown out and the ring stays visible. But it turns the purple storm sky grey-white and flattens the ring/bolt contrast (seqA_t120–t130). It is a single flash, not a strobe.

## Defects
1. No readable countdown during 0–1.1 s (seqA_t010–t110, seqC_t000–t110).
2. Bolt lands off-centre, at the far rim/trainer (seqA_t120, seqC_t120).
3. Bolt is a flat white cylinder and does not read as lightning (seqA_t120–t130).
4. Warning ring is clipped by the frame bottom (all warning frames).
5. Non-reduced impact wash desaturates the storm and cuts ring contrast (seqA_t120–t140, seqB same).
6. Ring diameter is probably about 5–6 m against the approximately 3 m target (seqA_t110). Verify.
7. Copper ground veins glow the same before, during and after impact, so there is no post-strike steam/afterglow or scar beat (seqA_t150–t170 vs t000) as ART_DIRECTION asks.

## Overall F10#3 motion verdict: PARTIAL

## Ranked fixes
1. Add visible warning progression that ends at impact: an inner fill or a shrinking ring closing on the centre, plus a brightness/colour ramp or faster pulse in the last 0.3 s. Keep a non-pulsing version for reduced motion.
2. Centre the bolt's ground contact on the ring centre, or centre the ring on the strike point.
3. Replace the cylinder with a jagged, branching white-violet bolt, a ground burst and scorch, then a steam/afterglow residue for about 0.5 s.
4. Frame or shrink the zone so the whole circle is on-screen at the player camera, and match the diameter to spec.
5. Cap the non-reduced flash: tint it white-violet rather than grey, limit it to about 1.5× luminance, keep the ring/bolt above the wash, and shorten the decay.

---
Provenance (VIS, added after the judge returned). The frames are from render.yml runs 36310845684 (seqA), 36312800214 (seqB) and 36312802264 (seqC). All three ran at `tb/vis` `07695fc1`, which is main `4316362e` plus `tools/vis_capture_strike_motion.gd`, with fixed-fps 60 and exact 0.1 s spacing. This is **main's strike**: #365's strike rework (forked bolt, localised flash) is not on main and was not captured, because the tool cannot run at #365's head without a forbidden branch.

Shortcuts, disclosed:
- one staged warning plus impact aimed at the trainer through the client event path, with no damage;
- random strikes suppressed;
- the surge clock pinned to Break;
- the hour frozen;
- a debug teleport to the Cinder Verge stand;
- the HUD hidden.

Measured flash_level at impact: 0.95 in A and B, 0.10 in C. Night matches day by design (`storm_base.pin_time_of_day`). All frames are software GL.
