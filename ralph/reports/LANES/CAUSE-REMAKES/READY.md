# Cause lane: owner-rule remakes finish (tb/cause-remakes)

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
| 1 | `creature_coat_flags.json:flags.remake_owner1101_glow_read` | 47 (every remake that has a glow mask) | Glow that reads at gameplay distance: the existing mask is lit fully; eye-only and thin-line masks get a small halo inside their UV island; hue pushed toward the element colour so Compatibility's LDR clip keeps it; emission energy 2.6 / 2.0 / 1.4 by coverage. Bramblebun's veins are rebuilt from its crevice greens (0.85% → 3.0% coverage, energy 2.0). |
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
