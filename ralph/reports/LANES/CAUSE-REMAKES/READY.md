# Cause lane: owner-rule remakes finish (tb/cause-remakes)

## Status at 23:45 UTC 1 Nov: nothing has run locally. Bramblebun fixed but not run; Ripplet parked

**No species in groups 6–15 has been run locally against the coordinator's named tests**
(`test_creature_model_flags`, `test_creature_rest_pose`, `test_dual_type`,
`test_f36_pose_candidates`, `smoke_combat`, `smoke_arena_contain`,
`smoke_bramblebun_colourway_binding`).
- **Why.** The container has 0.74 GB of disk left; a Godot import needs several GB.
- **What would free the space.** Replacing the 21 GB git store (2,021 commits) with a depth-1
  clone of this branch would free about 13 GB, and everything is pushed. That step was refused
  as an irreversible local deletion. It needs the owner's permission, or a lane with disk.
- **What "ready" means here.** Each fix argues its contract from the code path and is ready to
  run. CI or a lane with an import must confirm it before a flag turns on.

- **Bramblebun** (group 15; `tests/smoke_bramblebun_colourway_binding.gd`).
  - **Colourway source.** The remake flag now keeps `colourway_source_species:
    "bramblebun_nat1022"`, so Bramblebun's colourway rules (`shiny_colourways.json`
    `bramblebun`) still govern. The textures resolve beside the remake's own albedo
    (`creature_body._texture_for`, the `.jpg` branch), so they use the remake's UVs.
  - **Shiny and alpha.** `bramblebun/candidate_owner1101/source/author_colourways.py` writes:
    - `_Image_0_shiny.png` from `rules`: a pale silver hare with green veins, the rule's
      documented intent;
    - `_Image_0_alpha.png` from `vivid_rules`, because an alpha without `alpha_rules`
      inherits them (the repaint tool's convention): a warm hazel coat.
  - **Glow.** It also writes the matching `_arc_emission_<suffix>.png`. Without it the swap
    would self-light the whole albedo.
  - **Left out.** No `_vivid` is written, so the ordinary remake is unchanged. The old mesh's
    leaf-growth overlays would cover 17–22% of the body, so they are left out (owner rule: no
    full-body overgrowth).
  - **Known interaction.** With `remake_owner1101_plate_blend` ON, the alpha keeps the
    plate-blend albedo instead of its colourway: coat flags run first and rename the albedo.
- **Ripplet: PARKED** (`tests/smoke_combat.gd`: the camera's followed anchor sits 2.5 m from the
  trainer and 2.8 m from the creature).
  - **What the remake changes.** The remake's rendered box is 1.94 × 3.6 × 5.87 m, against the
    installed nat1024b's 2.86 × 3.6 × 5.73 m: 0.92 m narrower and 0.14 m longer.
  - **Where the anchor comes from.** The fight camera's pivot is
    `FIGHT_CAMERA.solve(...)`.pivot, applied as `set_framing_pivot_offset`
    (combat_manager.gd ~2834). The solver frames both rendered boxes. The smoke subtracts
    height and shoulder from the rig position but not that framing offset, so the box change
    moves the pivot toward the midpoint, and the trainer stands there (`trainer_aside`: 2.4 m
    side, 1.2 m back).
  - **Why parked.** This cannot be localised without running the solver. Matching the
    installed box, as was done for Terrapup, would mean making Ripplet 47% wider, which breaks
    its identity, and padding the box would only game the test. Next step: a lane with an
    import runs `smoke_combat` with the flag ON and logs `_fight_camera_solution` (pivot,
    distance, yaw offset) for both models.

## Terrapup and Riptusk: ready to turn ON (1 Nov, third coordinator request)

No test was edited. They are MANIFEST groups 13 and 14. As before, the named tests have not
run here: there is no Godot import and no game smoke in this container.

- **Terrapup** (`remake_owner1101_terrapup`; CI failure: `tests/smoke_arena_contain.gd` "could
  not engage the warrens wild creature").
  - **Why admission sees only the box.** Combat admission sees a creature only through its
    rendered mesh box (`RENDER_BOUNDS.measure`: corners, front extent, radial footprint), its
    height and its radius.
  - **The remake's box was not "longer".** It was 1.471 × 3.2 × 4.677 m: shorter than the
    installed dog3's 1.221 × 3.2 × 4.896 m, but 0.25 m wider (the plated shoulders). In the
    chamber-capped Warrens ring, that combination refused it.
  - **The fix.** `terrapup/candidate_owner1101/source/fit_installed_footprint.py`
    re-proportions the remake to exactly the installed box: x ×0.830, a leaner chest and
    shoulders; z ×1.047; height unchanged at 3.20 m. Every admission computation therefore
    matches the installed Terrapup's, which passes.
  - **What else changed.** Bones keep their rest rotations, their rest positions move with the
    mesh, and the skin is rebound; the rest-pose skin error is 4e-7. Translation keys keep
    their per-bone offsets. Idle, walk, attack and faint keep their shapes inside the new box.
    The silhouette still reads as the same lean dog. Plates, textures and glow are unchanged.
  - **Height arm.** `remake_owner1101_judged_short` (terrapup ×1.15) would grow it past that
    box again; its `_why` now says landing it needs the smoke re-run.
- **Riptusk** (`remake_owner1101_riptusk`; CI failure: `tests/test_creature_rest_pose.gd`, the
  water rest candidate).
  - `water_rest_pose_visual.gd` now also binds the remake model for `riptusk` and
    `water_riptusk`, as it already did for Torrentoad. The remake's faint clip role maps to its
    own `faint` clip, which ends lying prone.
  - The shipped allow list still keeps Riptusk on the legacy roll in play, until the remake's
    endpoint is judged.

## Aspect variants, Ashtusk and Frostclaw: ready to turn ON (1 Nov, second coordinator request)

No test was edited. The remake flags below are MANIFEST groups 8–12. The proof gap is the
same as for groups 6–7: the named tests have not run here, only `godot --check-only` on
the changed scripts.

- **Aspect variants** (`tests/test_dual_type.gd`: a variant reuses its base's mesh). Each base
  flag now also carries its variant onto the remake mesh:
  - `remake_owner1101_burrowback` carries Nightburrow.
  - `remake_owner1101_trailpup` carries Stormtrail.
  - `remake_owner1101_paddlenewt` carries Riftfrill.
  - `remake_owner1101_tuskroot` carries Ashtusk.
  - **New textures.** The aspect textures are repainted for the remake UVs by
    `tools/generate_aspect_variant_textures.py --remake`, which uses the same rules, glow
    layers and anatomy masks; the old candidates' files are untouched. For each remake there is
    an `<albedo>_<variant>.png`, plus a glow map:
    - The three remakes that already ship an emission map get it as
      `<arc_emission>_<variant>.png`, the name `creature_body._swapped_material` reads. Without
      it the swap would self-light the whole albedo.
    - Tuskroot, which has no emission map, gets it as `<albedo>_emissive_<variant>.png`.
  - **Stormtrail keeps its look.** Same rules: storm-grey coat, lighter muzzle and chest, blue
    storm veins (2.8% of the surface, 1.8% before). Its spine-line glow layer selects nothing on
    the remake; the veins carry the glow.
  - **Coat flags skip aspect variants** (`creature_body._apply_coat_flags`), as they already
    skip shinies. Otherwise `remake_owner1101_glow_read`, keyed by the shared remake albedo,
    would reach the variant and break its swap.
- **Ashtusk.** Its own-mesh flag `remake_owner1101_ashtusk` is removed, along with its
  glow-pass entry. Its old remake files stay on disk unreferenced. As a Tuskroot variant it
  rides `remake_owner1101_tuskroot`. That flag sets `aspect_source_species: "tuskroot"`, because
  the `ashtusk_native` branch would put the native Tuskroot's normal and roughness maps (old
  UVs) on the remake.
- **Frostclaw** (`tests/test_f36_pose_candidates.gd`, "installs on the measured rig").
  - `f36_pose_candidates.json` gains `species.frostclaw.model_alternates[0]`, a recipe measured
    on the remake: file hash, uid, rig and bind contract, and 15 bones.
  - It also gains the profile `frostclaw_owner1101_quadruped_anatomical`, which is the judged
    Frostclaw profile converted onto the remake rig. Each bone's rotation is re-expressed in
    the remake's rest frame (`C⁻¹·delta·C`), so every bone moves the same way in world space;
    the largest conversion error is 1.5e-6.
  - `creature_pose_candidates.gd` now picks the recipe whose model matches the live one
    (`recipe_for`). Script: `frostclaw/candidate_owner1101/source/author_f36_recipe.py`.
  - **Note for tb/cause-poses:** with this, the remake Frostclaw plays the F36 hit, faint,
    swim, fly_grip and ride poses (Frostclaw is owner-enabled) instead of its own dog3 clips,
    as the installed one does.

## Torrentoad and Meadowhart remakes: ready to turn ON (1 Nov, coordinator request after PR #793 CI)

Both fixes are on this branch. No test was edited. They are MANIFEST groups 6 and 7.

- **Torrentoad** (`remake_owner1101_torrentoad`). CI found a missing faint and a missing
  `attack_contact_phase`.
  - **Contact timing.** The flag's animation map replaced the installed map and dropped
    `attack_contact_phase`. The remake's attack clip also ran 25/24 s, against the installed
    23/24 s with contact at frame 15.
    - The remake attack keys are retimed piecewise by
      `torrentoad/candidate_owner1101/source/retime_attack_contact.py`. The wind-up now runs from
      0 to the strike peak at 15/24 s, and the recovery ends at 23/24 s.
    - The flag carries `attack_contact_phase: 0.652174` (15/23).
    - No other clip changed.
  - **Faint.** The rest test's empty faint came from `water_rest_pose_visual.gd`, which binds
    exact model paths. It now also accepts the remake model for `torrentoad` and
    `water_torrentoad`. The Riptusk ids stay bound to the installed model, so the
    exact-model-binding check still holds. The remake's dog3 faint ends lying prone with the
    legs drawn in.
- **Meadowhart** (`remake_owner1101_meadowhart`). The test needs one skinned MeshInstance3D named
  `MeadowhartBareBody`; `creature_body.meadowhart_bare_body_present()` uses the same name.
  - The remake's single skinned mesh node was `Mesh_0`, so it is renamed in the GLB.
  - The other conditions already held, measured from the GLB:
    - foreleg geometry: 26–121 vertices per height band, against a minimum of 12;
    - skin weights: 0 invalid of 8377;
    - all six production clips present.
- **Proof.**
  - Measured from the GLB: attack length 0.958333 s, and 0.958333 × 0.652174 = 0.625 s.
  - `water_rest_pose_visual.gd` passes `godot --check-only`.
  - The three named test files have **not run here**: this container cannot fit a Godot
    import. CI on the landing PR decides.

## Summary (1 Nov 2026)

Zero criteria closed (GPU scoring is the coordinator's). Five flags, all **OFF**, all listed in
`MANIFEST.json` (groups 1–5, 60 species rows). Each flag works the same whether or not the other
flags are on; turn on the remake model flags (`remake_owner1101_*`) first.

| Group | Flag | Species | What it changes |
|---|---|---|---|
| 1 | `creature_coat_flags.json:flags.remake_owner1101_glow_read` | 46 (every remake that has a glow mask; Ashtusk's own remake was dropped) | Glow that reads at gameplay distance: the existing mask is lit fully; eye-only and thin-line masks get a small halo inside their UV island; hue pushed toward the element colour so Compatibility's LDR clip keeps it; emission energy 2.6 / 2.0 / 1.4 by coverage. Bramblebun's veins are rebuilt from its crevice greens (0.85% → 3.0% coverage, energy 2.0). |
| 2 | `creature_coat_flags.json:flags.remake_owner1101_plate_blend` | terrapup, bramblebun | Terrapup: pale tile bevels flattened, stone tone varies between warm stone and moss, moss in the crevices, plate edges blend into the coat through moss and dirt. Bramblebun: the plaster-white bark becomes warm brown bark with its grain kept, moss creeps in from the veins; the white belly and inner-ear fur are left alone. |
| 3 | `creature_coat_flags.json:flags.remake_owner1101_dark_lift` | brooktail, voltarach | Gentle value lift on dark, low-saturation fur (same grade as `creatures_f36_coat_lift`); eyes, spots and sparks keep their pixels. |
| 4 | `creature_scale_flags.json:flags.remake_owner1101_body_line` | sparkit ×1.47, glimmermoth ×1.35, galewisp ×1.15, craghorn ×1.09, bramblebun ×1.1, shadelet ×1.08, cliffspike ×1.05 | Grows the body line (the top of the middle of the body, ears and tails excluded) to about 2.4 m. |
| 5 | `creature_scale_flags.json:flags.remake_owner1101_judged_short` | terrapup ×1.15, pipwing ×1.15 | Tests the judges' read; see the height note below. |

`_sheet_texture_ab.png` shows the texture before and after (Terrapup plates, Bramblebun bark,
Terrapup eye halo). These are texture crops, not in-game frames.

## Height note

I measured every remake GLB in its posed idle clip at its placeholder height
(`creature_body._fit`; no remake hits the footprint clamp). Every one is at least 2.65 m tall
overall. The body line is under 2.3 m only for the seven species in flag 4. Terrapup's body
line is 3.00 m and Pipwing's 2.73 m, so the judges' "at trainer height" read for those two
probably comes from camera framing rather than size. Flag 5 tests the read directly.
Craghorn ×1.09 (3.82 m) stays under its evolution Stormcapra (3.85 m). If flag 4 is enabled
together with `creatures_f36_taller_than_trainer_4` (bramblebun ×1.3), the two multiply, so
judge one or the other.

## Proof and gaps

- `tests/test_remake_owner1101_finish.gd` (new) checks that:
  - every finish flag ships OFF, and while off no remake albedo is remapped;
  - turning a flag on applies every key (glow map and energy, or regraded albedo) through
    `coat_material`;
  - every remake with a glow mask is covered by the glow pass;
  - scale factors are at least 1, every scaled species is a remake, and none outgrows its
    evolution.
  - The existing `tests/test_creature_coat_flags.gd` also covers the new coat flags.
  - **Only a parse check has passed** (`godot --check-only`, exit 0). This container has about
    0.9 GB of disk left, too little for a Godot import, so the test has not run.
- **No CPU capture.** Same cause: no import fits.
- The flags change only textures and heights; the meshes, rigs and clips are untouched, so
  every clip plays as before (`tests/test_creature_model_flags.gd`).
- `texture_import_policy.py --check` passes (1364 sidecars, mode 2). The new `.import` files
  copy their siblings' settings. Their uids are fresh and Godot rewrites them on import.
- Faint/hurt poses (tb/cause-poses) are untouched: no pose or clip data changed.

## Reproduce

- `python3 tools/art_pipeline/remake_owner1101_finish.py glow` (about 8 minutes on CPU)
- `python3 tools/art_pipeline/remake_owner1101_finish.py plate`
- `python3 tools/art_pipeline/grade_coat_value.py brooktail_owner1101 voltarach_owner1101`
