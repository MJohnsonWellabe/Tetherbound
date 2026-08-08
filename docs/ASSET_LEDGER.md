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
| Terrapup/Ripplet/Galewisp/trainer turnaround crops ×16 | Derived from the owner's art pack | `tools/art_pipeline/crop_views.py` | Owner's own. Reference only; `.gdignore`d out of the export | No | `assets/pals/tetherbound/*/reference/*.png` | Cut from the four production sheets: one figure per image, shared scale, flat background. Regenerate with the script; never hand-edited. |
| Meadows art pack — 11 reference sheets and boards | Owner-supplied (AI-generated) | Provided by owner, commit `408c757` | Owner's own. Reference only; excluded from the export | No | `docs/art/reference/0*.png`, `1*.png` | Moved from the repository root. One byte-identical duplicate of sheet `04` deleted. Canon and precedence recorded in `docs/art/REFERENCE_CANON.md`. |
| Palworld screenshots ×5 | Pocketpair | Owner-supplied screenshots | Reference only, not shipped | No | `docs/reference/palworld-0*.jpg` | None |
| Trainer character (`Ranger`) | KayKit / Kay Lousberg | [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) | CC0 1.0 | No | `assets/characters/Ranger.glb` | Renamed from the pack layout. Ships with no AnimationPlayer; one is created at load and the two rigs' libraries are merged onto it (`trainer_model.gd`). |
| Trainer animation rig — General | KayKit / Kay Lousberg | [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) | CC0 1.0 | No | `assets/characters/Rig_Medium_General.glb` | Clip source only; its mesh is never instanced. |
| Trainer animation rig — MovementBasic | KayKit / Kay Lousberg | [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) | CC0 1.0 | No | `assets/characters/Rig_Medium_MovementBasic.glb` | Clip source only; its mesh is never instanced. |
| Bramblit (Triceratops) | Quaternius | [Ultimate Animated Dinosaurs](https://quaternius.com/packs/ultimateanimateddinosaurs.html) | CC0 1.0 | No | `assets/pals/bramblit.fbx` | Renamed. Imported by Godot 4.7's native FBX path with its clips. Scaled at runtime to the gameplay collider. |
| Meadow Hopper (Frog) | Quaternius | [Animated Animals](https://quaternius.com/packs/animatedanimals.html) | CC0 1.0 | No | `assets/pals/meadow_hopper.fbx` | Renamed. Scaled at runtime. |
| Thornback (Stegosaurus) | Quaternius | [Ultimate Animated Dinosaurs](https://quaternius.com/packs/ultimateanimateddinosaurs.html) | CC0 1.0 | No | `assets/pals/thornback.fbx` | Renamed. Scaled at runtime. |
| Plumberry Plains Vol. 2 — 5 characters | GTB (owner-supplied) | Supplied by owner via Google Drive | Free for unlimited personal **and commercial** use. May NOT resell, redistribute or repackage the raw asset files, mint as NFTs, or train AI on them. | No | `assets/pals/plumberry/*.glb` | Curated 5 of 10. glTF with 26 baked clips each, embedded. No skinning — transform-node animation on rigid parts — so they import and play with no retargeting. |
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
