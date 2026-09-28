# P2-042 first matched candidate verdict

Source: b97d44a1017ebc04755f427d2663a2371ad6fbeb, with only
`presentation.phase_readability_candidate.enabled` temporarily true.
The flag was restored to false. Windows/NVIDIA Compatibility, 1920x1080,
seed 2042, production camera and the same two stands as the baseline.
All eight stills and 160 temporal samples completed without capture failures.
Camera positions match within 0.0002 m. Decorative lightning streams are
randomized by production weather; seed parity is not identical flash timing.

Compact evidence: `after-r1/manifest.json` and
`after-r1-motion/manifest.json`. Raw images remain in the ignored
`.tmp/stormwood-phase2/p2042-after-r1/` directory.

Independent code-blind reviewer: `stormwood_phase_after_judge`, fresh context,
images/manifests and visual-judge rubric only. Inspected all 16 before/after
native stills, first/last native samples of all eight stand/phase combinations
in both sets, the four candidate Stormheart middle samples, both still sheets
and all 14 temporal sheets (320 thumbnails). References were the Meadows key
art, both Stormheart stronghold boards, and all five Palworld gameplay images.

**Four-phase readability: FAIL. Readability preservation: PASS.**
**Bar A: NO. Bar B: NO.**

- Fading is now clearly identifiable at both stands. Pale low ground mist
  persists throughout the sampled sequence, with lighter broken clouds at
  Sentinel. The mist stays translucent and mostly below the trainer's torso;
  trainer, NPC, path, rocks and Sentinel trunk remain readable.
- Break remains identifiable through heavy rain, darker values and exposed
  lightning at Sentinel, plus intermittent Stormheart ground warnings.
- Calm and Building remain too similar beneath Stormheart. In candidate
  Calm/Building stills and temporal samples 00, 10 and 19, heavier rain and
  slightly cooler/darker light are visible at native size but weak at tile
  size. The enclosing dark structure, green foreground and pulsing gold lines
  dominate both states. Sentinel separates them better through its sky, but
  the requirement covers both stands.
- No material new scene-readability regression appeared. Existing Stormheart
  structural obstruction remains severe.

The three largest reference gaps are inconsistent trainer/NPC styling and
lack of creature emphasis; enormous flat bark faces and a black band hiding
Stormheart's living-tree identity; and sparse, repetitive ground cover with
an empty distant horizon. Scene work can improve lighting, staging, grounding,
planting and depth. Cohesive character styling and authored root/trunk forms
also require asset work. Available asset inventory was not assessed by the
blind reviewer.

This review covers sampled fixed views, not traversal, full transitions,
continuous motion, performance or HUD. The next phase candidate must retain
the accepted Fading distinction while separating Building beneath the canopy.
The item remains open and the candidate remains disabled.
