# Gate F — defects lane log

Branch `ralph/GATE-F-DEFECTS`. Tier 1 of
`ralph/COORDINATION_2026-08-27_POST_PHASE_B.md`, running parallel to the rig
lane. Nothing under `tools/gate_f/**` is touched by this lane.

Source items: `ralph/reports/gate-f-phase-b/FINAL_BACKLOG.md` (on
`origin/ralph/GATE-F-PHASE-B`; not present on `main` at the time of writing, so
it is read with `git show`).

Every claim below is a file, a config value, a container measurement or a frame
rendered in this container on llvmpipe. Composition, colour and silhouette are
trustworthy in those frames; **frame times are not**, and device frame rate,
GPU, VRAM and thermals are [OWNER-ONLY] and are never claimed here.

---

## `GF-B-010` — NPCs render as unlit black silhouettes in daylight — **ROOT CAUSE FOUND, FIXED**

### The cause

**Every one of the six humanoid rigs imports as a fully-rough metal.**

glTF 2.0's default for an **absent** `metallicFactor` is **1.0**, not 0. Read
straight out of the JSON chunk of all six .glb files:

| rig | `metallicFactor` | `roughnessFactor` | metallic/ORM texture |
|---|---|---|---|
| `trainer_lod0.glb` | absent → 1.0 | absent → 1.0 | **none** |
| `grandpa_lod0.glb` | absent → 1.0 | absent → 1.0 | **none** |
| `villager_male_lod0.glb` (2 materials) | absent → 1.0 | absent → 1.0 | **none** |
| `villager_female_lod0.glb` (2 materials) | absent → 1.0 | absent → 1.0 | **none** |
| `warden_lod0.glb` | absent → 1.0 | absent → 1.0 | **none** |
| `grunt_lod0.glb` | absent → 1.0 | absent → 1.0 | **none** |

Confirmed as imported, in engine, via `tools/_probe_npc_materials.gd`:
`metallic=1.00 roughness=1.00` on every body surface of every rig.

A metal has **no diffuse term at all**. Its only response is a specular lobe,
and roughness 1.0 spreads that lobe over the whole hemisphere until it returns
almost nothing. So the body renders near-black whichever way the sun points —
which is exactly why the coordinator's sun-azimuth hypothesis could not explain
it, and why the same frame's grass, trees, terrain and props are fine.

### Why the props in the same frame are the proof, not the counter-example

They omit `metallicFactor` too. Measured in engine:

| object | `metallic` | metallic texture |
|---|---|---|
| `Crate_Wooden.gltf` surface 0 | 1.00 | `T_Trim_Furniture_ORM.png`, blue channel |
| `Crate_Wooden.gltf` surface 1 | 1.00 | `T_Trim_Metal_ORM.png`, blue channel |
| `creature_bramblebun_lod0.glb` | 1.00 | `..._metallic_roughness.jpg`, blue channel |

Their per-texel blue channel multiplies that 1.0 back down to dielectric. Every
Tetherbound creature .glb is in the same position. **The six humanoid rigs are
the one class in the project that carries a metallic factor with no texture to
modulate it** — which is precisely the condition the fix tests for.

### The A/B

`tools/_probe_npc_metallic_ab.gd`. Six rigs plus a wooden crate as the control,
under the game's own `art.json` `day` block applied by `world_look.gd` — not a
hand-made sun. Both halves are built through `character_model.gd`, and the
BEFORE half differs from the AFTER half by exactly one property, so the
comparison cannot be about the height fit, the hair part or the accessories.

- `before-as-imported.png` — six jet-black cut-outs, correctly lit crate a metre
  away. This reproduces the coordinator's frame in a controlled scene.
- `after-character-model.png` — every rig shows folds, straps, boots, hair, the
  Warden's coat and the grunt's oxblood. Crate unchanged.

### The fix

`scripts/characters/character_model.gd`, two changes:

1. `_apply_palette()` now walks **every** character, not only the tinted ones.
   The four rigs that needed the correction most (trainer — which is also the
   PLAYER's own body — Grandpa, the Warden, the grunt) declare neither `palette`
   nor `tint` and so returned before touching a material. An absent tint reads
   as the identity multiply `#ffffff`, which `art.json` already writes
   explicitly for all five villagers, so no colour changes anywhere.
2. `_shared_variant_material()` sets `metallic = 0.0` when the source material
   has `metallic > 0` and **no** metallic texture, and only when the caller's
   `finish` dict did not ask for metal itself. A rank badge that deliberately
   asks for a specular falloff keeps it; a rig that later ships a real ORM map
   keeps whatever that map says.

Roughness is deliberately left at the imported 1.0. It is the same absent-
default, but a fully rough dielectric is correct matte cloth, and picking a
sheen for six rigs is a look decision this defect does not license.

### Regression coverage

`tests/test_character_metallic.gd`, four tests, 27 assertions. Asserts against
`config_for()`'s real production configs rather than a fixture — the defect was
in what the shipped rigs import as, and a fixture would have passed throughout.
Verified to actually fail without the fix: reverting the one assignment turns
`test_every_rig_body_surface_builds_dielectric` red and leaves the other three
green.

`tests/smoke_art.gd` and `tests/test_character_hair_split.gd` /
`test_character_lying.gd` pass unchanged.

### Two findings this turns up, recorded rather than acted on

- **The rank value ramp exists to compensate for this bug.** `smoke_art.gd`'s
  own comment records that Team Tether's palette was rebuilt as
  grunt `#8a8a8a` → officer `#c2c2c2` → captain `#ffffff` because the old bottom
  rung (`#4a5049`) "was crushing Team Tether NPCs to black on screen". So was
  every other rung; the body had no diffuse term. With the metal corrected that
  ramp is now brightening bodies that no longer need it, and the faction may
  read washed. Re-judging it is a look decision, not this defect, and it needs a
  visual pass rather than a number.
- **`character_model.gd`'s emission prose is stale.** The long `NP2` /
  `STRANDED-P3` comment describes rigs whose materials ship
  `emission_enabled = true` with an emission texture. Measured on today's six
  .glb files: `emission_enabled` is **false** on every one, `emission_texture` is
  null, `emission_operator` is 0. The rigs were rebuilt since. The block is dead
  for every character in the game today. Annotated in place rather than deleted —
  it is still correct for a rig that does arrive carrying emission, and it is the
  only written record of why an emission floor has to be additive.

### Status

Fixed and pushed. In-world confirmation in bands 2 and 4 still to capture.
