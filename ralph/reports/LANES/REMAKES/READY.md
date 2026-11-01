# Creature remakes: ready for GPU judging

## Summary (1 Nov 2026, creature-remake lane, tb/creature-remakes)

Five owner-picked Meshy candidates (1 Nov) are prepared, rigged, scaled, emission-masked
and wired behind per-species flags, all **OFF**: Terrapup, Bramblebun, Trailpup, Brooktail
and Pipwing. `MANIFEST.json` lists them for the GPU sweep. Nothing closes until the
GPU judges them (High first, mapped 7.5 bar). Galewisp and Mudsnout had not arrived when this was written.

| Item | Flag (`data/config/creature_model_flags.json`) | Rig and clips | In-game height | Glow |
|---|---|---|---|---|
| F36 (0) #1 Terrapup | `remake_owner1101_terrapup` | dog3 quadruped, 15 bones, all 11 roles | 3.20 m | jade eyes |
| F36 (0) #5 Bramblebun | `remake_owner1101_bramblebun` | dog3 quadruped, 11 roles | 3.00 m | green veins and eyes (leaf tail unlit) |
| F36 (1) Trailpup | `remake_owner1101_trailpup` | dog3 quadruped, 11 roles | 3.10 m | amber paw pads and eyes |
| F36 (1) Brooktail | `remake_owner1101_brooktail` | dog3 quadruped, 11 roles (installed had 6) | 2.10 m, x1.4 scale flag → 2.94 m | aqua spots and eyes |
| F36 (1) Pipwing | `remake_owner1101_pipwing` | rig_bird, 19 bones, folded wings, its 6 roles | 1.90 m, x1.6 scale flag → 3.04 m | ice-blue eyes only |

**What was done per species.** Meshy's baked ground patch (or loose grass tufts) was
stripped (`tools/art_pipeline/blender/strip_ground_patch.py`). The mesh was welded and
decimated where needed: 8–28k triangles, no unweighted vertices. Textures are kept;
the embedded maps were re-encoded to JPEG and Godot extracts them on the VRAM-compressed
path (`texture_import_policy.py --check` PASS, 20 sidecars). Each model was rigged at
the species' established height and given every gameplay clip the installed model plays.
Emission is an albedo-derived emissive map (`arc_emission.py`, rules in
`data/creatures/arc_emission.json`). Provenance in each `candidate_owner1101/source/provenance.json`; ART_DIRECTION §7.3 has five rows.

**Proof so far.** `tests/test_creature_model_flags.gd` passes: 2 tests, 88 assertions. It checks
that every flag ships OFF, that an enabled flag swaps the model, that the species stays taller than
the trainer and is never shrunk, and that every required clip exists. One CPU capture per species
(`capture_f36_poses.gd --whole-body --context`, flag ON locally, Low/Compatibility) is in
`_sheet_owner1101_f36_cpu.png`. All five load, stand above the 1.80 m trainer, and play hit and
faint. Terrapup also plays ride. CPU frames are a sanity check, not a verdict.

**Departures from the brief, and why.**
- **Rig route.** I used the Terrapup dog3 candidate's recipe instead of `rig_quadruped` +
  `skin_transfer` + `animate_quadruped`. It is the project's most recent live Meshy-quadruped precedent:
  measured legs, anatomical skin regions, and its own `author_native_clips.py`. It produces the
  installed clip names directly, with no donor transfer. Generalised as
  `tools/art_pipeline/blender/prepare_remake_quadruped.py`.
- **Pipwing.** `rig_bird.torso_half_width` read Meshy's hollow surface shell as a 0.05 m torso and
  rigged the folded wings as spread. `pipwing/candidate_owner1101/source/prepare_pipwing_owner1101.py`
  replaces only that measurement, following the Galecrest wrapper precedent.
- **Pipwing feather-edge lines are not lit.** They have the same saturation as the pale-blue coat, so
  any mask that catches them lights the whole wing. Only the eyes glow.
- **Owner-direction tension, for the coordinator.** CLAUDE.md (24 Oct) says "current creature meshes
  stay (no remake programme)", and 25 Oct says no glowing seams on fur or hide. I took these
  candidates as today's owner pick (as briefed) and kept everything flag-off. Bramblebun's veins and
  Trailpup's paws are the concept's trait, but they are the kind of glow the 25 Oct line restricts. Judges should weigh that.

**Open candidates / known risks for judging.** Brooktail's source pose has the head
turned to one side, which the rig keeps. Pipwing's in-game scale comes from the existing x1.6 flag.
Bramblebun is not rideable, so it has no ride row. Shiny/vivid colourways fall back to the
surface-finish hue shift (there are no authored colourway textures for these meshes).

**Runbook (reuse).** Run `tools/art_pipeline/setup.sh blender godot`, then
`apt-get install libegl1 libgl1` for turntables. Disk was too tight for a full import (about 1.9 GB
free against 5 GB of assets), so I imported a subset by putting temporary, **uncommitted**
`.gdignore` files on unrelated asset folders (props, environment, other creatures, ralph, docs).
Godot then imports in about 2 minutes, and the F36 capture still runs. Remove them before any real import.
