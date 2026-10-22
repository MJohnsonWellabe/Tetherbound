# Creatures close-1022 (lane tb/creatures)

Renderer for every capture: Godot 4.7 Compatibility (Low), Mesa llvmpipe under xvfb. Scoring waits for the
judge yardstick (tb/judge-yardstick) to land; until then this lane fixes and captures.

## RESUME
- Coordinator messaging is refused from this session (`elevated_session_untrusted_device`); see `OUTBOX.md`.
- Meshy remakes (two-style split, top GPU ask) are blocked on reference drafts: `remake-briefs.md`.
- Candidates, all OFF on the branch:
  - `f36_pose_postpass.py --candidate-1022` (+ `f36_arachnid_profile.py --candidate-1022`): every recoil hit becomes
    the body-carried shove at gain 1.5; Mirejaw side topple; Meadowhart resting-deer prone (antlers off the floor);
    Fulgocobra hood-drop prone (dip 3) + shove; Voltarach side-tip with legs curled.
  - `data/config/creature_surface_finish_1022_candidate.json`: value-gamma lift for Tanglevolt, Voltarach,
    Galecrest, Fulgocobra (shader uniforms `base_value_gamma`/`base_saturation_scale`, default 1.0 = unchanged).
  - Solmane / Pebbik shiny gradient maps: `<species>_extracted_base_color_shiny_gm.png`
    (`solmane/source/shiny_gradient_map.py`); live shiny png and the `shift` rows unchanged.
  - P2-030 r3 (ported from tb/shared-art ae6bafa24 with the fallback ON): `p2-030-r3-finishes.json`.
  - F29#3 growth: Stormursa 4.10 -> 5.00 m (species.json height/radius + ladder target) on this branch only.
