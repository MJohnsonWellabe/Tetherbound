# Creature remakes 2: ready for GPU judging

## Summary (1 Nov 2026, second creature-remake lane, tb/creature-remakes-2)

All 21 assigned Meshy candidates are prepared, rigged, scaled, emission-masked where the
albedo has glow, and wired behind per-species flags, all **OFF**: Pebbik, Reedwing,
Ribbonray, Ripplet, Riptusk, Riverdrake, Shadelet, Sirenseal, Skyrill, Solmane, Sparkit,
Staticub, Stormbrush, Stormraven, Tempestwing, Thundertunnel, Tidecoil, Torrentoad,
Tuskroot, Voltarach, Voltwig. `MANIFEST.json` lists them for the GPU sweep (groups 1–21).
Nothing closes until the GPU judges them (High first, mapped 7.5 bar). None parked.

| Species | Rig and clips | In game | Glow |
|---|---|---|---|
| Pebbik | dog3 quadruped, 11 roles | 3.25 m | green-gold lines, amber eyes |
| Reedwing | rig_bird, 19 bones, folded wings, 6 roles | 2.65 m | aqua eyes and lines |
| Ribbonray | rig_bird, 6 roles (stands on two legs; ray wings rig as spread wings) | 3.70 m | sky-blue eyes |
| Ripplet | dog3, 11 roles (ride, swim rows captured) | 3.60 m | aqua markings, eyes |
| Riptusk | dog3, 11 roles | 4.25 m | aqua hide lines, eyes |
| Riverdrake | dog3, 11 roles | 4.00 m | aqua scale lines, eyes |
| Shadelet | dog3, 11 roles; grass disc stripped | 2.80 m | violet eyes (painted violet lines also read) |
| Sirenseal | dog3, 11 roles | 3.25 m | aqua frill lines, eyes |
| Skyrill | rig_glider + animate_quadruped glider clips, 6 roles | 3.25 m | sky-blue eyes |
| Solmane | dog3, 11 roles | 6.70 m | none found in the albedo |
| Sparkit | dog3, 11 roles | 1.95 m, x1.6 scale flag → 3.12 m | blue eyes, leg lightning |
| Staticub | dog3, 11 roles | 3.25 m | blue lightning lines, eyes |
| Stormbrush | dog3, 11 roles | 3.25 m | blue-white quill lightning, eyes |
| Stormraven | rig_bird via Pipwing torso wrapper, folded wings, 6 roles | 3.40 m | blue-white veins, eyes |
| Tempestwing | dog3, 11 roles (wings follow the spine) | 4.15 m | cyan eyes |
| Thundertunnel | dog3, 11 roles; plinth stripped | 2.80 m | blue lightning lines, eyes |
| Tidecoil | dog3, 11 roles | 5.50 m | aqua specks, eyes |
| Torrentoad | dog3, 11 roles | 3.25 m | aqua lines, eyes |
| Tuskroot | dog3, 11 roles (ride row captured) | 3.60 m | none: natural amber eyes |
| Voltarach | dog3, 11 roles (4 of 8 legs on leg bones) | 4.25 m | blue sparks, eyes |
| Voltwig | dog3, 11 roles | 3.25 m | blue eyes, spark points |

**What was done per species** (lane 1's recipe, `ralph/reports/LANES/REMAKES/READY.md`).
Ground patch stripped where Meshy baked one (`strip_ground_patch.py`). Quadrupeds:
`prepare_remake_quadruped.py` (dog3 measured-leg rig and skin, 15 bones, decimated to
≤28k triangles, 0 unweighted vertices) then dog3's `author_native_clips.py` (all 11
roles, a superset of every installed clip map). Birds: `rig_bird.py` (6 roles). Glider:
`rig_glider.py` + `animate_quadruped.py` (6 roles). Embedded maps re-encoded to JPEG
(q88, 2048 px; Meshy's PNG normal made each GLB ~13 MB). Emission: albedo-derived
emissive map (`arc_emission.py`, 19 rules `<species>_owner1101` in
`data/creatures/arc_emission.json`). `texture_import_policy.py --check` PASS. Provenance
per species in `candidate_owner1101/source/provenance.json`; ART_DIRECTION §7.3 has 21 rows.

**Proof so far.** `tests/test_creature_model_flags.gd`: 2 tests, 446 assertions, 0 failed
(all 26 flags, lane 1's five included): every flag ships OFF, an enabled flag swaps the
model, the species stays taller than the trainer and is never shrunk, every clip role
exists. One CPU capture per species (`capture_f36_poses.gd --whole-body --context`, flag ON
locally, Low/Compatibility) is in `_sheet_owner1101_f36_cpu.png` (standing hit-000 and
faint-100 per species): all 21 load, stand above the 1.80 m trainer, and play hit and faint;
Ripplet also plays ride and swim, Tuskroot ride. Blender pose sheets (idle, walk, attack,
hit, faint) were checked for every species. CPU frames are a sanity check, not a verdict.

**Departures from the brief, and why.**
- **Rig route.** Lane 1's dog3 recipe (its stated departure) instead of
  `rig_quadruped` + `skin_transfer` + `animate_quadruped`, so all 21 share its clip names.
- **Shared changes.** `strip_ground_patch.strip(low_islands=...)` is new and opt-in (default
  unchanged): Shadelet's Meshy mesh was fragmented, and the keep-largest-island step
  deleted the body with the grass. `tests/test_creature_model_flags.gd` now skips non-clip
  metadata beside a clip map (Torrentoad's installed `attack_contact_phase` number and its
  `_comment`); every clip role is still asserted. Torrentoad's flag omits
  `attack_contact_phase`, which described the old clip, so its new attack plays at impact time.
- **Stormraven** needed the Pipwing shell-aware torso wrapper (copied as
  `prepare_stormraven_owner1101.py`); without it the folded wings rigged as spread.
- **Local import only:** disk was too tight for 84 full-size compressed textures, so the
  local test/capture import used `size_limit=1024` in the sidecars; sidecars were restored
  to full size before every commit.

**Open candidates / known risks for judging.** These are body plans the 15-bone dog3
skeleton fits loosely: Voltarach (8 legs, 4 on leg bones), Tempestwing (wings ride the
spine), Sirenseal (an upright seal on four "legs"), Tidecoil (an upright serpent),
Ribbonray (a biped with ray wings on the bird rig). Torrentoad's walk stretches a front
toe toward the hind foot on one frame. Shadelet's body is low-poly (3.4k triangles),
because Meshy spent most of the polycount on the grass. Solmane and Tuskroot have no
emission: Tuskroot's reference has natural eyes, and no glow pixel was found for
Solmane's pale eyes. The dog3 faint rolls the body onto its back, as on lane 1's models.
Shiny/vivid colourways fall back to the surface-finish hue shift.

**Runbook (reuse).** Run `tools/art_pipeline/setup.sh blender godot` and
`apt-get update && apt-get install libegl1 libgl1`. Disk was about 2 GB free, which is not
enough for Blender plus a full import. Delete `/root/.cache/uv` and `/var/lib/apt/lists/*`.
Hide everything except the models under test with temporary, **uncommitted** `.gdignore`
files. Then: `texture_import_policy.py --apply`, then import. Delete `.godot` before committing.
Blender pose sheet per model: idle, side, walk, attack, hit and faint frames rendered from
`turntable.py`'s helpers, about 25 s per model.
