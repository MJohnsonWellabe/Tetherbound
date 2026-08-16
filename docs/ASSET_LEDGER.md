# Asset Ledger

Provenance for every non-original asset in the project, per `CLAUDE.md` and
`docs/TECHNICAL_START.md`.

Assets do not need to be CC0 for this private project. The rule is that nothing
ships without a row here, so attribution is a lookup rather than an archaeology
project, and so a licence audit before any public release is possible at all.

A row is required **before** the file is committed. Record the licence as found
at the time it was fetched, not as remembered.

| Asset | Creator | Source | Licence | Paid | Local path | Modifications |
|---|---|---|---|---|---|---|
| Torch prop (`torch_prop.tscn`) | Original, built from primitives in `scripts/world/torch_prop.gd` (no vendor source) | N/A — no torch/brand/lantern mesh exists anywhere under `assets/` (checked before building: `find -iname "*torch*" -o -iname "*flame*" -o -iname "*lantern*"` across `assets/` turns up only the Quaternius Survival bonfire, whose "Fire" surface shares one ArrayMesh with its log geometry and cannot be pulled out standalone) — D24 forbids a Meshy generation with no owner-supplied reference board, so this is code-built geometry: a tapered `CylinderMesh` stick, a flame and embers as radial-gradient billboard quads (the same procedural-texture technique `vegetation_harvest_point.gd`'s glint halo already uses, so no flame/ember texture asset was needed either) | Original work; not applicable | No | `assets/props/built/torch_prop.tscn`, `scripts/world/torch_prop.gd` | OF24. The stick's colour is not invented: `Kd 0.384608 0.289962 0.254778`, copied from the Quaternius Survival bonfire's own "Wood" material (`assets/props/quaternius_survival/Bonfire_Fire.mtl`) rather than picked fresh. Reused as-is for both the carried torch (`scripts/player/torch.gd`, bone-attached to the trainer rig's `Hips`) and the free `torch` ground buildable (`data/items/buildables.json`); neither the light nor the flicker lives in this scene — each caller adds its own `OmniLight3D` from its own data (`movement.json`'s `torch` block; the buildable's own `light` block). |
| Meadows key art board | Owner-supplied (AI-generated) | Provided by owner | Owner's own | No | `docs/reference/tetherbound-meadows-keyart.png` | None |
| Creature colour refresh boards ×2 (2026-08-15) | Owner-supplied (AI-generated) | Provided by owner with the 2026-08-16 implementation brief | Owner's own | No | `docs/reference/owner-board-2026-08-15-creature-colors.png`, `docs/reference/owner-board-2026-08-15-systems-and-castle.png` | None. **These are the authority for the roster's ordinary (vivid) colourways** — per-species palette captions ("Warm earth tones + Moss accents", "Deep blues + Translucent fins", …), move/TM tables, the Meadows castle concept, Grandpa's five dialogue beats, and the potions set. Vendored because the first vivid colour pass (OF28 base half) was authored by a session that could not see them and went jewel-toned against their direction — the boards living only in a chat thread is exactly how that happens twice. Owner's framing: direction, not pixel targets ("none are the exact direction"). |
| Input Prompts — 4 more files extracted (`xbox_lt.png`, `xbox_rt.png`, `xbox_button_start.png`, `keyboard_l.png`) | Kenney | [Input Prompts](https://kenney.nl/assets/input-prompts) (already staged raw, see the full-pack row below) | CC0 1.0 | No | `assets/ui/input_prompts/` | Owner playtest report fixes. `xbox_lt.png`/`xbox_rt.png`: combat's `quick`/`charged` verbs and build's `build_rotate_left`/`build_rotate_right` were showing the LB/RB SHOULDER icons as stand-ins for their real LT/RT trigger bindings — a documented "on-screen control instruction lies about its binding" defect (`scripts/ui/input_glyph.gd`) — now shown correctly; the real trigger art was already sitting in the raw vendor pack, unextracted. `xbox_button_start.png`/`keyboard_l.png`: prompts for the new starting-torch toggle (`torch_toggle`). Unmodified, straight copies from the already-logged raw pack, same as every other `assets/ui/input_prompts/*.png` file extracted before this row (none of which had their own ledger row until now — a pre-existing gap, not introduced here). |
| Input Prompts — 3 more files extracted (`xbox_stick_r_press.png`, `keyboard_b.png`, `keyboard_p.png`) | Kenney | [Input Prompts](https://kenney.nl/assets/input-prompts) (already staged raw, see the full-pack row below) | CC0 1.0 | No | `assets/ui/input_prompts/` | OF21 (same-context gamepad collision fix). `xbox_stick_r_press.png`: `torch_toggle`'s new dedicated gamepad glyph — `torch_toggle` moved OFF the Start/Menu button (where it collided with `backpack_drop`); a first pass put it on the Guide button, but Guide-class buttons are captured by the system overlay on the ROG Ally and never reach the game, so it landed on R3 (button 8), whose only other reader is menu-context. (`xbox_guide.png` was briefly extracted for that first pass and removed again — never shipped.) `keyboard_b.png`/`keyboard_p.png`: prompts for the two new world-context actions this same pass added, `build_open` (B) and `torch_place` (P). Unmodified, straight copies from the already-logged raw pack, same convention as the row above. |
| NPC bases concept board | Owner-supplied (AI-generated) | Provided by owner | Owner's own | No | `docs/art/reference/12_NPC_Bases_Reusable.png` | None. Specifies three reusable base bodies; supersedes spec §22's "one or two" per D24. |
| Tether Energy Pylon board | Owner-supplied (AI-generated) | Provided by owner | Owner's own | No | `docs/art/reference/13_Tether_Energy_Pylon.png` | None. Production brief, not mood art: **2K–3K triangle** target, human height +, and a five-part modular build (base + core module + supports ×4 + top frame + tether crystal). One of the three hero objects D24 reserves Meshy for. |
| Tether Energy Pylon — production hero object | Generated (Meshy multi-image-to-3D preview ×3, retexture on the winner) from crops of the owner's board `13_Tether_Energy_Pylon.png`; textures separated and graded in-pipeline | `tools/art_pipeline/`, task ids in `assets_raw/tether_pylon/manifest.json` and `c_tex/provenance.json` | Meshy ToS at generation date (paid credits of owner's account); derived from owner's own concept art. All Rights Reserved / proprietary, owner-licensed | Paid credits (~90) | `assets/environment/team_tether/tether_pylon.glb` + `tether_pylon_albedo.png` / `tether_pylon_albedo_dead.png` | SF33. One of the three hero objects D24 reserves Meshy for, and the first built. 3,041 triangles against the board's 2K–3K target. Candidate C won on the board's signature features (large faceted floating crystal, claw frame, lantern core). GLB is geometry-only (125KB); the 2K Meshy albedo was downscaled to 1024 and split into a live state (as textured) and a dead state (teal drained to cold slate via hue-masked grade) — per-material variants, one mesh. A baked emission-mask texture was built and then REMOVED: gl_compatibility (D01) ignores the mask and floods the whole mesh with the emission colour; the live read is albedo-carried, only the procedural conduit cables use uniform-colour emission. |
| Relay Apparatus board | Owner-supplied (AI-generated) | Provided by owner | Owner's own | No | `docs/art/reference/14_Relay_Apparatus.png` | None. Band 3. Artist note is the build spec: *"modular construction, core and rings serviceable, conductor arms and manifolds replaceable"*. Five labelled subassemblies. Serves `SE23`. |
| Legendary Tether Machine board | Owner-supplied (AI-generated) | Provided by owner | Owner's own | No | `docs/art/reference/15_Legendary_Tether_Machine.png` | None. Warden stronghold, ~15 m against its own 0–20 m scale bar. **Depicts a bound legendary inside the containment ring — the board licenses the MACHINE, not its occupant.** D23 §20 forbids new creature meshes at any credit balance, so the bound creature is an existing roster asset or VFX. |

| Relay Apparatus — production hero object | Generated (Meshy multi-image-to-3D: preview x3 to choose, then refine x2) from FRONT/SIDE/REAR crops of the owner's board `14_Relay_Apparatus.png`, cut by `tools/art_pipeline/crop_prop_views.py` | `tools/art_pipeline/`, task ids in `assets_raw/relay_apparatus/*/provenance.json`; winner `01a00ae3-9cf0-7e34-83b2-1d3504f13236` | Meshy ToS at generation date (paid credits of owner's account); derived from owner's own concept art. All Rights Reserved / proprietary, owner-licensed | Paid credits (100: 3 preview + 2 refine) | `assets/environment/team_tether/relay_apparatus.glb` | SE23. D24's second reserved hero. The board's hero render is NOT among the inputs — its callout numbers and leader lines sit on the object. Installed at the `ApparatusSeam` in `scripts/world/tether_relay.gd` and fitted to `apparatus.height` (4.2m) by the mesh's own visual bounds; the placeholder massing stays as the fallback the code takes when `model` is unset. In-engine renders: `shots/_hero_relay_*.png`. |
| Legendary Tether Machine — production hero object | Generated (Meshy multi-image-to-3D: preview x3 rejected, preview x3 accepted, then refine x2) from four crops of the owner's board `15_Legendary_Tether_Machine.png` — **and the front and side crops had the bound legendary programmatically LIFTED OUT of them first** (`crop_prop_views.py::lift_occupant`) | `tools/art_pipeline/`, task ids in `assets_raw/tether_machine/*/provenance.json`; winner `01a00ae7-0325-7f01-b8db-07097a7929e1` | Meshy ToS at generation date (paid credits of owner's account); derived from owner's own concept art. All Rights Reserved / proprietary, owner-licensed | Paid credits (200: 6 preview + 2 refine) | `assets/environment/team_tether/tether_machine.glb` | R8.2. D24's third and last reserved hero. **THE BOARD LICENSES THE MACHINE, NOT ITS PRISONER** — D24, and D23 §20 forbids a new creature mesh at any balance. The occupant was removed from the INPUT IMAGES rather than only banned in the negative prompt, because image-to-3D follows its pictures. Every candidate was checked by eye and none contains a creature. Installed at `machine.model` in `data/config/stronghold.json`, fitted to `machine.height` (15m) — `smoke_stronghold` measures it at 16.6 x 15.0 x 12.0 m. In-engine renders: `shots/_hero_machine_*.png`. |

> **All three of D24's reserved hero objects are now generated.** The Tether
> Energy Pylon (SF33), the Relay Apparatus (SE23) and the Legendary Tether
> Machine (R8.2). No further Meshy generation is licensed for the Meadows: D23
> §20 forbids creature meshes at any balance, and CLAUDE.md forbids generating
> anything the owner has not supplied a reference board for.
> The Warden was rebuilt separately on 2026-08-16 from the owner's own
> character sheet (board 16) — see the row below. No further Meshy generation
> is licensed for the Meadows.

| Warden Aldis — rebuilt character | Body generated (Meshy multi-image-to-3D preview x3) from board 16's front/back turnaround; HEAD generated separately (preview x3, twice — the first crops included shoulders and produced whole figures) from board 16's four head views; grafted, textured, auto-rigged and animated in-pipeline | `tools/art_pipeline/`, task ids in `assets_raw/warden_body/*/`, `assets_raw/warden_head/*/`, `assets_raw/warden/tex_final/`, `assets_raw/warden/rig_final/` | Meshy ToS at generation date (paid credits of owner's account); derived from owner's own concept art. All Rights Reserved / proprietary, owner-licensed | Paid credits (~320) | `assets/characters/warden/warden_lod0.glb` | R8.3 / D49. **Board 16 supersedes board 06 for this character**: bare bearded face with a painted green eye-marking, not a visored soldier. His face is MODELLED now rather than painted, which was the point. Body candidate `b` won because the `staff` negative took on it. Recipe and the two tool flags it needed (`--skip-voxel`, `--drop 0.45`) are in D49. Renders: `shots/_warden_before_after.png`. |

**Most of the build is CC0 1.0 — but not all of it, and this ledger previously
claimed otherwise.** Corrected 2026-08-12: the Meshy-generated creatures and
characters (Ripplet, Galewisp, Grandpa Elias, and the rest of the roster
generated the same way — see their own rows above) are **not** CC0; they
carry Meshy's ToS at generation date, derived from the owner's own concept
art, and are treated as **All Rights Reserved / proprietary, owner-licensed**
for this project. The **Plumberry Plains Vol. 2** pack (also above) is not
CC0 either — its own row already states its real terms (free for personal and
commercial use, no resale/redistribution/repackaging, no AI training), also
treated as proprietary/owner-licensed rather than open. Everything else in
this table genuinely is CC0 1.0, and for that portion nothing here carries a
legal attribution obligation — though credits should still name Quaternius,
Kay Lousberg, Kenney and ambientCG; it costs a line and it is how these packs
keep existing.

The creature models remain stand-ins for bespoke art (`docs/decisions/D10`), and
the blind critic has said so in two consecutive reviews (`docs/reviews/MA-01`,
`MA-02`). They are in the build because a rigged, animated, correctly-scaled
stand-in proves the systems; they are not the answer to the owner's bar.

## Retired

Kept for audit history. These files are no longer in the repository, but they
were committed at some point and a licence audit should be able to see that.

| Asset | Creator | Source | Licence | Retired because | Was at |
|---|---|---|---|---|---|
| Trainer character (`character-a`) | Kenney | [Blocky Characters](https://kenney.nl/assets/blocky-characters) | CC0 1.0 | Minecraft-proportioned blocky figure in a different art language from the creatures beside it — the critic's lead complaint in `MA-01`. | `assets/characters/trainer.glb` |
| Trainer textures | Kenney | [Blocky Characters](https://kenney.nl/assets/blocky-characters) | CC0 1.0 | Went with the model above. | `assets/characters/Textures/` |
| Meadow Hopper (rabbit) | Google (Poly) | [Poly Pizza](https://poly.pizza/m/dyeBDJxhDwP) | CC-BY 3.0 | Unrigged static scan; could not animate, and CC-BY added an attribution obligation the rest of the roster does not carry. | `assets/creatures/meadow_hopper.glb` |
| Thornback (boar) | Google (Poly) | [Poly Pizza](https://poly.pizza/m/57fSWum6F1P) | CC-BY 3.0 | Unrigged static scan. | `assets/creatures/thornback.glb` |
| Bramblit (fox) | Google (Poly) | [Poly Pizza](https://poly.pizza/m/10u8FYPC5Br) | CC-BY 3.0 | Unrigged static scan. | `assets/creatures/bramblit.glb` |

## Rules

- `docs/` carries a `.gdignore`, so nothing in it is imported by Godot or
  included in an export. The reference images are documentation, not game
  content, and the Windows export preset excludes them explicitly.
- Never assume an asset is redistributable. "Free to download" is not a licence.
- Prefer assets with animations appropriate to their role over assets that look
  better in a still.
- Test scale and materials in-engine before committing to a roster. A pack that
  looks cohesive on a store page can fall apart under one directional light.
- If the game is ever distributed publicly, audit this table and purchase or
  replace anything that needs it.
