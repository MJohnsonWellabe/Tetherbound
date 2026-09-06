# Free asset candidates for Tetherbound art gaps

All downloads below were fetched into
`/tmp/claude-0/-home-user-Tetherbound/821c8399-59f9-53da-af7f-4bf6ff4cfedf/scratchpad/asset_search/<candidate>/`
and verified with `curl -sSI` (or a full `curl -sS -o` when a HEAD wasn't informative). Nothing was
copied into the repo. Any pack that could not be verified with curl (itch.io's own download button
requires a browser session/CSRF token, and poly.pizza returns HTTP 403 to non-browser clients via
Cloudflare) is called out as an **unverified lead**, not listed as a checked candidate.

---

## Already have (do not re-source)

Inventoried from `assets_raw/vendor/*` and `assets/props/kenney_survival/`:

| Gap keyword | Already vendored | Where |
|---|---|---|
| Rock / boulder | `Rock_Medium_1..4`, `Rock_Big_1..2`, `Pebble_Round_1..5`, `Pebble_Square_1..6`, `RockPath_*` modular ground pieces | `assets_raw/vendor/quaternius_stylized-nature-megakit/` |
| Torch | `Torch_Metal.gltf` — **single mesh, single material `MI_Trim_Metal`, no flame geometry/material** (confirmed by inspecting the glTF JSON) | `assets_raw/vendor/quaternius_fantasy-props-megakit/glTF/` |
| Lantern / candle | `Lantern_Wall`, `CandleStick`, `CandleStick_Stand`, `CandleStick_Triple`, `Chandelier` | same pack |
| Crate / barrel / sack-ish | `Crate_Metal`, `Crate_Wooden`, `Barrel`, `Barrel_Apples`, `Barrel_Holder`, `FarmCrate_Apple/Carrot/Empty`, `Bag`, `Pouch_Large`, `Chest_Wood` | same pack |
| Rack | `Peg_Rack`, `Shelf_Arch`, `Shelf_Simple`, `Shelf_Small_Bottles`, `WeaponStand` | same pack |
| Chain | `Chain_Coil` (coiled, not a hanging run) | same pack |
| Cage | `Cage_Small` (one small size only) | same pack |
| Rope | `Rope_1`, `Rope_2`, `Rope_3` | same pack |
| Banner / heraldry | `Banner_1`, `Banner_1_Cloth`, `Banner_2`, `Banner_2_Cloth` (2 designs) | same pack |
| Bedroll | `bedroll.glb`, `bedroll-frame.glb`, `bedroll-packed.glb` | `assets/props/kenney_survival/` |
| Mushroom | `Mushroom_Common`, `Mushroom_RedCap`, `Mushroom_Oyster`, `Mushroom_Laetiporus` — **inspected `Mushroom_RedCap.gltf`: 472 verts, one mesh, one material; cap is a simple textured dome, no gill/lamellae geometry underneath** | `assets_raw/vendor/quaternius_stylized-nature-megakit/` |
| Vine (hangable greenery) | `Prop_Vine1/2/4/5/6/9` | `assets_raw/vendor/quaternius_medieval-village-megakit/` |

**Net effect on the five gaps:** rocks/mushrooms/torches/banners/cages/racks/chains/ropes/lanterns all
already have *a* vendored option, but each falls short of the brief in a specific way — no tall
cliff/ledge modules, no lit-flame mesh, only one small cage, only 2 banner designs, and mushrooms with
no real cap/gill profile. The candidates below target those specific shortfalls, not wholesale
replacement.

---

## 1. Cliff / rock kit (sky-island cliff biome)

| Name | Author | Licence (exact) | Format | Direct URL | Verified | Style-fit | Recommendation |
|---|---|---|---|---|---|---|---|
| **Kenney Nature Kit** (v2.1) | Kenney | *"License: (Creative Commons Zero, CC0) … free to use in personal, educational and commercial projects. Support us by crediting Kenney (not mandatory)"* — from the pack's own `License.txt` | glTF/GLB, FBX, OBJ, DAE, STL | `https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip` | HTTP 200, 10,537,521 bytes | 168 modular `cliff_*` pieces (block/corner/diagonal/slope/half/quarter/cave/wall — genuine tall-face + ledge modules, not just boulders). Inspected two GLBs: `cliff_block_rock.glb` uses flat `baseColorFactor` materials named "grass" (teal) and "dirt" (tan); `cliff_large_stone.glb` uses a flat pale-blue "stone" material. **No moss/granite texture out of the box** — these ship as flat placeholder colors meant to be recolored, exactly like Quaternius's flat-shaded style, so retinting to grey-green mossy granite in Godot is a trivial material swap, not a rebuild. Same flat-shaded low-poly language as the vendored Quaternius/Kenney packs. | **Try first.** Biggest, only truly modular tall-cliff kit found, official Kenney CC0, already glTF, and its flat-color materials are cheap to retint to the mossy-granite palette. |
| Quaternius Stylized Nature MegaKit — `Rock_Big_1/2`, `Rock_Medium_1..4` (already vendored) | Quaternius | CC0 (`License_Standard.txt` in repo) | glTF | already in repo | n/a (already have) | Boulders only, no tall faces/ledges — use alongside Kenney cliffs for scatter detail at the cliff base, not as the cliff itself. | Use as set-dressing next to option 1, not a cliff substitute. |
| Low Poly Cliff Pack (brokenvector, itch.io) | brokenvector | **Not stated on the page** — itch listing gives no CC/attribution text at all | Collada (.dae) mesh + separate texture zip; no glTF/FBX | `https://brokenvector.itch.io/low-poly-cliff-pack` (itch download button, **not curl-verifiable** — no external file host) | Not verified (itch CSRF-gated); page fetched via WebFetch only | 13 cliff tiles (concave/convex/diagonal/straight/pass) + 5 rock tiles, grey/yellow/red textures — genuinely modular ledge geometry, but unverified licence and DAE-only means a conversion + a legal question before use. | **Unverified lead only** — don't use until the author states a licence; Kenney's kit already covers the same need with a clean CC0 grant. |
| CC0 rock/moss PBR textures — Poly Haven | Poly Haven | CC0 1.0 (Poly Haven's blanket licence for all assets) | JPG/PNG/EXR PBR sets (diffuse+normal+rough+AO+displacement) | `mossy_rock`: `https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/mossy_rock/mossy_rock_diff_1k.jpg` · `rock_face_03`: `https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/rock_face_03/rock_face_03_diff_1k.jpg` · `aerial_rocks_04`: `https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/aerial_rocks_04/aerial_rocks_04_diff_1k.jpg` | All three: HTTP 200 (1,124,438 / 927,082 / 841,479 bytes respectively) | Photoreal PBR, not flat-shaded — **not a style match on their own**, but usable as a moss/lichen overlay blended at low strength onto the flat-color Kenney cliff materials, or baked into a stylized gradient ramp, rather than applied 1:1. | Use `mossy_rock` (best grey-green lichen coverage) as a *detail/overlay* texture on the Kenney cliff meshes, not as the primary diffuse — keep the flat-shaded look dominant. |

---

## 2. Castle interior dressing (torch/sconce w/ flame, braziers, crates, racks, sacks, bedrolls, chains, cages)

| Name | Author | Licence (exact) | Format | Direct URL | Verified | Style-fit | Recommendation |
|---|---|---|---|---|---|---|---|
| **KayKit — Dungeon Remastered 1.0** | Kay Lousberg (kaylousberg.com) | CC0 1.0 Universal — from `LICENSE.txt`: *"License: (Creative Commons Zero, CC0) … This content is free to use in personal, educational and commercial projects. Support me by crediting Kay Lousberg (this is not mandatory)."* | .FBX, .GLTF, .OBJ (GLB variants present) | e.g. `torch_lit`: `https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0/main/addons/kaykit_dungeon_remastered/Assets/gltf/torch_lit.gltf.glb` · `torch_mounted`: same path, `torch_mounted.gltf.glb` · `box_large`: `box_large.gltf.glb` · `crates_stacked`: `crates_stacked.gltf.glb` · `banner_patternA_blue`: `banner_patternA_blue.gltf.glb` | All HTTP 200: torch_lit 31,244 B, torch_mounted 33,220 B, box_large 28,740 B, crates_stacked 103,704 B, banner_patternA_blue 25,164 B | Opened `torch_lit.glb`: single mesh (`Cylinder.021`) + single material — **the flame is modelled geometry baked into the torch mesh** (KayKit's signature single-gradient-atlas style), so it drops in as a genuine "torch with a flame mesh," not a texture trick. Flat gradient-shaded low-poly reads close to Quaternius; slightly chunkier silhouette than Kenney but blends fine as dressing rather than structure. Pack also ships `box_small/large`, `crates_stacked`, `keg`, `bed_frame/decorated/floor`, `shelf_*`, `keyring_hanging` — good crate/sack-adjacent/rack coverage. **No dedicated brazier, sack, hanging-chain-run, or cage mesh found in the file listing.** | **Try first for the flame prop specifically** (`torch_lit` / `torch_mounted`) — it is the only verified source in this search with an actual modelled flame. Pair with the already-vendored Quaternius `Chain_Coil`/`Cage_Small`/`Chandelier` for the remaining dressing since no better verified source turned up for those. |
| Kenney Fantasy Town Kit (2.0) | Kenney | CC0 (pack `License.txt`, same wording as Nature Kit) | GLB, plus other formats | `https://kenney.nl/media/pages/assets/fantasy-town-kit/efe948d309-1754222374/kenney_fantasy-town-kit_2.0.zip` | HTTP 200, 3,854,691 bytes; unzip listing inspected | Has `lantern.glb`, `banner-green.glb`, `banner-red.glb`, plus a full exterior wall/roof/fountain/stall kit — but it's an **exterior town** kit, not interior dressing. No torch, brazier, crate, sack, rack, chain, or cage found in the file listing. | Secondary source for one more lantern silhouette / two more banner colours only — not a real answer to the interior-dressing gap. |
| Quaternius Fantasy Props MegaKit (already vendored) | Quaternius | CC0 | glTF | already in repo | n/a | Covers crates/barrels/racks/chains/cages/candles already ("already have" above), but its `Torch_Metal` has no flame and there's no brazier. | Keep using for the non-flame furniture; don't expect a brazier or lit torch from it. |
| Brazier (any style-matched CC0/CC-BY mesh) | — | — | — | — | **Not found.** Targeted search of Poly Haven, OpenGameArt, Kenney's Castle Kit, Kenney's Fantasy Town Kit, and Quaternius's dungeon/fantasy-props packs turned up no standalone brazier mesh with a checkable licence and a curl-verifiable URL. Poly Pizza lists brazier results but the whole site 403s to non-browser clients (Cloudflare), so nothing there could be verified. | — | **No verified pick.** Recommend substituting the already-vendored Quaternius `Chandelier` (hanging fire/candle fixture) or KayKit's `torch_lit` on a short post as a floor-standing brazier stand-in until a real brazier mesh is sourced, or ask the owner whether a Meshy generation is warranted (this is a "Team Tether hero object"-adjacent prop, not a creature/humanoid, so it may fall inside the one exception CLAUDE.md allows if reference art is supplied). |

---

## 3. Banner / heraldry

| Name | Author | Licence (exact) | Format | Direct URL | Verified | Style-fit | Recommendation |
|---|---|---|---|---|---|---|---|
| Quaternius Fantasy Props MegaKit — `Banner_1/1_Cloth/2/2_Cloth` (already vendored) | Quaternius | CC0 | glTF | already in repo | n/a | Already matches project style exactly since it's already in use. Only 2 designs. | Keep as the base; supplement with more variety below if the Meadows needs more than 2 heraldic looks. |
| **KayKit — Dungeon Remastered banners** | Kay Lousberg | CC0 1.0 (see gap 2 licence text) | GLB/GLTF/OBJ/FBX | e.g. `https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0/main/addons/kaykit_dungeon_remastered/Assets/gltf/banner_patternA_blue.gltf.glb` (36 banner variants total: plain / patternA / patternB / patternC / shield / thin / triple, × blue/brown/green/red/white/yellow) | HTTP 200, 25,164 bytes (spot-checked one; file-listing confirmed 36 total via the GitHub tree) | Same gradient-shaded low-poly language as the torch above — flat, chunky, reads as a cousin of Quaternius rather than a twin, but far more heraldic variety (36 colour/pattern combinations) than the 2 already vendored. | **Try first for variety** — biggest verified, CC0, glTF banner set found, and it is a single coherent family (won't fragment the "one nature/village/prop family" rule if used instead of mixing multiple partial sources). |
| Kenney Castle Kit — `flag.glb`, `flag-wide.glb`, `flag-pennant.glb`, `flag-banner-long/short.glb` | Kenney | CC0 (pack `License.txt`, same wording as Nature Kit) | GLB | `https://kenney.nl/media/pages/assets/castle-kit/a395102d20-1711543616/kenney_castle-kit.zip` | HTTP 200, 2,232,589 bytes; unzip listing inspected, 5 flag/banner meshes confirmed | Kenney's flat-color-material style, matches the vendored Kenney UI/icon packs' authorship if not their exact geometry family; good pennant/wide-flag shapes not covered by KayKit's rectangular banners. | Use only if pennant/tapered-flag silhouettes (not rectangular hanging cloth) are specifically needed; otherwise KayKit alone covers more ground. |
| CC0 cloth/fabric PBR texture — Poly Haven `fabric_pattern_07` | Poly Haven | CC0 1.0 | JPG/PNG/EXR, multiple colourways (`col_1`, `col_2`, `col_03`) | `https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/fabric_pattern_07/fabric_pattern_07_col_1_1k.jpg` | HTTP 200, 788,593 bytes | Photoreal woven-cloth texture, not flat-shaded — best used as a subtle normal/roughness detail layer under a flat heraldic colour, not as the visible diffuse, to avoid breaking the stylized look. | Optional detail-only texture; not a primary banner solution. |

---

## 4. Aviary dressing (domed open-lattice stronghold — perches, ropes/nets, hanging cloth, static birds, lanterns)

| Name | Author | Licence (exact) | Format | Direct URL | Verified | Style-fit | Recommendation |
|---|---|---|---|---|---|---|---|
| Quaternius Fantasy Props MegaKit — `Rope_1/2/3`, `Chain_Coil` (already vendored) | Quaternius | CC0 | glTF | already in repo | n/a | Direct match, already in the project's material language. | Use for hanging rope/net-substitute dressing; there is no true net mesh in any verified source found this session. |
| Quaternius Fantasy Props MegaKit — `Lantern_Wall`, `CandleStick_*`, `Chandelier` (already vendored) | Quaternius | CC0 | glTF | already in repo | n/a | Direct match. | Use for the aviary's lantern dressing — no better verified alternative found. |
| Quaternius / Kenney tree branch or log pieces (e.g. Kenney Nature Kit tree/branch meshes, or the already-vendored `tree-log.glb`/`tree-log-small.glb` in `kenney_survival`) | Kenney / Quaternius | CC0 | glTF/GLB | `tree-log.glb`/`tree-log-small.glb` already in repo; Kenney Nature Kit adds more trunk/branch variants at the URL in gap 1 | tree-log already in repo (n/a); Kenney Nature Kit zip verified above | A plain log or branch segment reused as a bird perch is a legitimate low-effort reuse within the "one nature family" rule — no new mesh family introduced. | **Use the already-vendored tree-log pieces as perches** rather than sourcing a dedicated "perch" mesh; none was found as a distinct product anyway. |
| Static stylized bird prop (crow/raven/generic songbird, CC0/CC-BY, flat-shaded, curl-verifiable) | — | — | — | — | **Not found.** Checked OpenGameArt's "CC0 3D Animals/Creatures" collection (lists a "Raven" and "Bird basemesh" but the specific submission page/download link could not be located), Kenney's asset tag search (no 3D bird packs), and Quaternius's animal packs (itch-gated, not curl-verifiable). Poly Pizza has a Google-Poly-sourced "Fishing net" and presumably bird models, but the entire poly.pizza domain returns HTTP 403 to curl and to the fetch tool (Cloudflare bot-blocking) so nothing there could be verified. | — | **No verified pick — flag as an open gap.** Leads worth a manual (browser) look: OpenGameArt's "CC0 - 3D Animals / Creatures" collection page (`opengameart.org/content/cc0-3d-animals-creatures`, lists a Raven and Bird basemesh among its submissions) and Quaternius's itch.io "Everything Library 01 – Animals" (mentions Birds among its categories). Both need a human with a browser session to actually pull the file; neither could be curl-verified this session. |

---

## 5. Mushroom props with gills and a real cap profile (burrow interior)

| Name | Author | Licence (exact) | Format | Direct URL | Verified | Style-fit | Recommendation |
|---|---|---|---|---|---|---|---|
| **Free Mushroom Asset Kit** (AssetQuest) | Asset Quest (assetquest.dev) | CC0 — from the pack's own `License.txt`: *"License: (Creative Commons Zero, CC0) … You can use this content for personal, educational, and commercial purposes. Support by crediting 'Asset Quest' (this is not a requirement)."* | FBX (no glTF/OBJ in the archive — needs a one-time FBX→glTF pass, or Godot's built-in FBX importer) | `https://opengameart.org/sites/default/files/free_mushroom_pack_assetquest.zip` | HTTP 200, 54,791,351 bytes (54.8 MB, under the 60 MB cap); downloaded and unzipped to confirm contents | 5 real species (Fly Agaric, Bay Bolete, Inky Cap, Amethyst Deceiver, Artist's Conk) × Small/Basic/Big + 2 pre-grouped clusters = 25 meshes on one shared 3.5 MB texture. Species-accurate silhouettes (Inky Cap's bell cap, Fly Agaric's domed spotted cap, Bay Bolete's bun shape) give a far more "real cap profile" read than the vendored Quaternius mushrooms; single flat-ish shared texture keeps it compatible with the low-poly look, though it leans slightly more painterly/detailed than Quaternius's flat-color style. Gill/lamellae detail specifically is not confirmed geometrically (didn't decode the FBX mesh topology), but the size/shape variety and species accuracy is a clear step up from the 472-vert dome already vendored. | **Try first.** Only verified, true-CC0, differently-detailed mushroom source found; correct licence text with no redistribution caveats (contrast with the Cosmo pack below). |
| Low Poly Mushrooms (Cosmo, itch.io) | Cosmo | **Labelled CC0 on the page but the actual text reads:** *"You're free to use these assets in any commercial or non-commercial project without attribution. However, you cannot sell, license, or distribute the assets as-is or with minor modifications … including selling them on asset marketplaces or as standalone content."* — this is **not** true CC0 (real CC0 permits resale); treat it as a custom free licence with a no-resale clause. | OBJ/FBX/GLTF (per page) | itch.io download button only — **not curl-verifiable**, no external host found | Not verified (itch CSRF-gated) | 27 mushroom models, page doesn't describe gill detail. | **Do not use without re-reading the licence carefully** — the CC0 badge on the page is misleading; if used at all, it's under the custom restricted terms quoted above, not CC0. Prefer the AssetQuest kit, which is unambiguous. |
| Kenney Nature Kit — `mushroom_red`/`mushroom_tan` (+ Group/Tall variants) | Kenney | CC0 (pack `License.txt`) | glTF/GLB, FBX, OBJ, DAE, STL | included in the Nature Kit zip verified in gap 1 | HTTP 200 (same zip as gap 1) | Same flat-color, no-gill dome style as the already-vendored Quaternius mushrooms — doesn't move the needle on "real cap profile / gills." | Skip for this gap; it duplicates what's already vendored rather than filling the shortfall. |

---

## Summary — one pick per gap

1. **Cliffs:** Kenney Nature Kit's 168 `cliff_*` modules (CC0, glTF, verified 10.5 MB) — retint the flat "grass"/"dirt"/"stone" materials to grey-green mossy granite; optionally blend in Poly Haven's `mossy_rock` CC0 texture as a detail overlay.
2. **Interior dressing:** KayKit Dungeon Remastered's `torch_lit.glb` / `torch_mounted.glb` (CC0, verified) for the actual flame mesh; no verified brazier exists anywhere checked this session — flagged as an open gap with a `Chandelier`/`torch_lit`-on-a-stand workaround.
3. **Banners:** KayKit Dungeon Remastered's 36-variant banner set (CC0, verified) alongside the 2 already vendored.
4. **Aviary:** reuse already-vendored rope/chain/lantern/log props; no verified static-bird mesh found — flagged as an open gap needing a manual (browser) look at OpenGameArt's CC0 Animals collection or Quaternius's itch library.
5. **Mushrooms:** AssetQuest's Free Mushroom Asset Kit (CC0, verified, 54.8 MB, 5 species × sizes) — clearly better cap-profile variety than the vendored Quaternius mushrooms.

Two open gaps remain unresolved by any curl-verifiable, licence-clean source found this session:
a dedicated **brazier** mesh, and a **static stylized bird** prop. Both would benefit from either a
wider manual (logged-in) search of itch.io/poly.pizza, or an owner call on whether either is worth
a Meshy generation against supplied reference art per the CLAUDE.md exception.
