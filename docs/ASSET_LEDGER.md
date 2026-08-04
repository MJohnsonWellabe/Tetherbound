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
| Meadows key art board | Owner-supplied (AI-generated) | Provided by owner | Owner's own | No | `docs/reference/tetherbound-meadows-keyart.png` | None |
| Palworld screenshots ×5 | Pocketpair | Owner-supplied screenshots | Reference only, not shipped | No | `docs/reference/palworld-0*.jpg` | None |
| Trainer character (`Ranger`) | KayKit / Kay Lousberg | [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) | CC0 1.0 | No | `assets/characters/Ranger.glb` | Renamed from the pack layout. **No longer the trainer** — superseded by the Styloo knight above, and kept only because it is the fallback if the retarget is ever backed out. |
| Trainer character (`knight`) | Styloo | [Styloo "The Company" on the Godot Asset Store](https://store.godotengine.org/asset/styloo/company) | CC0 1.0, stated in the pack's own readme | No | `assets/characters/knight.glb` + two 2K colour maps | Renamed. Ships zero clips on a 176-bone Rigify skeleton; the 25 KayKit clips are retargeted onto it at load (`animation_retarget.gd`, map in `data/config/art.json`). The sword and shield are modelled into the same skinned mesh and are hidden by collapsing `DEF-shield` and `DEF-bone.01` — the trainer cannot fight. |
| Trainer animation rig — General | KayKit / Kay Lousberg | [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) | CC0 1.0 | No | `assets/characters/Rig_Medium_General.glb` | Clip source only; its mesh is never instanced. |
| Trainer animation rig — MovementBasic | KayKit / Kay Lousberg | [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) | CC0 1.0 | No | `assets/characters/Rig_Medium_MovementBasic.glb` | Clip source only; its mesh is never instanced. |
| Village props and build pieces ×35 | Quaternius | [Medieval Village MegaKit](https://quaternius.itch.io/medieval-village-megakit), Standard (free) tier | CC0 1.0, stated in the pack's own `License_Standard.txt` | No | `assets/buildings/*.gltf` + 20 PBR maps | 35 of 176. Ten standalone props (wagon, crate, log, chimney, support, bricks, fence) for authored landmarks, plus the M8 build set: 4 floors, 7 walls, doors and frames, windows, 4 roofs, 2 gable fronts, 2 stairs. The kit is modular and authored **in metres** — 2m walls, 2×2m floors, 3m storey — so it needs no import scale correction, unlike the nature packs. Normal maps taken from `Textures/Normals Godot-Unity/`, not the top-level ones: Godot wants the Y-down convention. |
| Station pieces ×3 — bed, pal bed, campfire | **primitive stand-ins**, except as noted | authored in-repo as `.tscn` | n/a — no third-party asset | n/a | `scenes/building/bed.tscn`, `pal_bed.tscn`, `campfire.tscn` | **These are not sourced art.** The Medieval Village subset contains no furniture of any kind — 35 of its 176 models are extracted and every one is architecture or a yard prop — so M6's pal bed and M8's bed and campfire are built from boxes. Sizes are measured, not guessed: bed 1.00 × 2.00 × 0.60m (one build cell), pal bed 1.60 × 1.60 × 0.26m, deliberately a different silhouette so the two are never confused at a glance. **The campfire is the exception**: its stones are 8 × `Pebble_Round_1/2/3` from the Quaternius nature pack and its logs are 3 × `log.glb` from the Kenney Nature Kit — both already licensed rows above — and only the flame is primitive. Per `CLAUDE.md`, these three must be replaced before the stronghold or the home loop is judged on how it looks. |
| Plumberry Plains Vol. 2 — 5 characters | GTB (owner-supplied) | Supplied by owner via Google Drive | Free for unlimited personal **and commercial** use. May NOT resell, redistribute or repackage the raw asset files, mint as NFTs, or train AI on them. | No | `assets/pals/plumberry/*.glb` | **3** of 10: bruno-the-bear, ernie-the-duck, ollie-the-songbird. This row said "curated 5" and that was wrong — only three `.glb` were ever committed, and the other two left 20 orphaned `.png.import` stubs behind, since removed. glTF with 26 baked clips each, embedded. No skinning — transform-node animation on rigid parts — so they import and play with no retargeting. |
| Stylized Nature MegaKit — 40 models | Quaternius | [Stylized Nature MegaKit](https://quaternius.com/packs/stylizednaturemegakit.html) | CC0 1.0 | No | `assets/environment/stylized_nature/*.gltf` | Trees (4 species), bushes, ferns, grass, flowers, rocks, path stones. Textured with normal maps. `Bush_Common` ships the crimson autumn leaf texture and is re-pointed at the green one per layer (`vegetation.json` `retexture`). |
| Kloppenheim 05 Pure Sky (HDRI) | Greg Zaal / Poly Haven | [Poly Haven](https://polyhaven.com/a/kloppenheim_05_puresky) | CC0 1.0 | No | `assets/environment/sky/day.hdr` | 2K Radiance HDR. Midday, partly cloudy. Sky-only ("puresky"), so it works as a sky dome with no ground half. |
| Table Mountain 1 Pure Sky (HDRI) | Greg Zaal / Poly Haven | [Poly Haven](https://polyhaven.com/a/table_mountain_1_puresky) | CC0 1.0 | No | `assets/environment/sky/golden.hdr` | 2K Radiance HDR. Sunset, partly cloudy. Drives the `golden` time of day. |
| Nature Kit — 27 models | Kenney | [Nature Kit](https://kenney.nl/assets/nature-kit) | CC0 1.0 | No | `assets/environment/nature/*.glb` | Superseded by the Quaternius kit above; retained for the flower and log shapes. Retinted at run time by material name (`vegetation.gd`). |
| Grass005 — colour, normal, roughness | ambientCG | [ambientCG Grass005](https://ambientcg.com/view?id=Grass005) | CC0 1.0 | No | `assets/environment/terrain/Grass005_*.jpg` | 2K JPG downsampled to 1024² to match the rest of the array — Terrain3D builds one Texture2DArray and rejects the whole set on a size mismatch. Base ground layer. |
| Grass004 — colour, normal, roughness | ambientCG | [ambientCG Grass004](https://ambientcg.com/view?id=Grass004) | CC0 1.0 | No | `assets/environment/terrain/Grass004_*.jpg` | 2K JPG. Was the base ground layer; kept, unused, as the dry-grass variant for a future second biome pass. |
| Ground003 — colour, normal, roughness | ambientCG | [ambientCG Ground003](https://ambientcg.com/view?id=Ground003) | CC0 1.0 | No | `assets/environment/terrain/Ground003_*.jpg` | 2K JPG. Soil/dirt layer. |
| Rock030 — colour, normal, roughness | ambientCG | [ambientCG Rock030](https://ambientcg.com/view?id=Rock030) | CC0 1.0 | No | `assets/environment/terrain/Rock030_*.jpg` | 2K JPG. Slope layer, blended by the auto shader. |

Everything currently in the build is **CC0 1.0**, so nothing here carries a legal
attribution obligation. Credits should still name Quaternius, Kay Lousberg,
Kenney and ambientCG — it costs a line and it is how these packs keep existing.

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
| Bramblit (Triceratops) | Quaternius | [Ultimate Animated Dinosaurs](https://quaternius.com/packs/ultimateanimateddinosaurs.html) | CC0 1.0 | Superseded by the Plumberry roster. Sat unreferenced in the repo for several commits after the swap — 3MB of FBX nothing loaded. | `assets/pals/bramblit.fbx` |
| Meadow Hopper (Frog) | Quaternius | [Animated Animals](https://quaternius.com/packs/animatedanimals.html) | CC0 1.0 | Superseded by the Plumberry roster; likewise orphaned. | `assets/pals/meadow_hopper.fbx` |
| Thornback (Stegosaurus) | Quaternius | [Ultimate Animated Dinosaurs](https://quaternius.com/packs/ultimateanimateddinosaurs.html) | CC0 1.0 | Superseded by the Plumberry roster; likewise orphaned. | `assets/pals/thornback.fbx` |
| Meadow Hopper (rabbit) | Google (Poly) | [Poly Pizza](https://poly.pizza/m/dyeBDJxhDwP) | CC-BY 3.0 | Unrigged static scan; could not animate, and CC-BY added an attribution obligation the rest of the roster does not carry. | `assets/pals/meadow_hopper.glb` |
| Thornback (boar) | Google (Poly) | [Poly Pizza](https://poly.pizza/m/57fSWum6F1P) | CC-BY 3.0 | Unrigged static scan. | `assets/pals/thornback.glb` |
| Bramblit (fox) | Google (Poly) | [Poly Pizza](https://poly.pizza/m/10u8FYPC5Br) | CC-BY 3.0 | Unrigged static scan. | `assets/pals/bramblit.glb` |

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
