# ART-REFERENCE — the three boards the owner draws next, and what happens to them

**Written 2026-09-04.** Companion to `docs/FINISH_THE_MEADOWS.md` §1.7 (CL-A1) and
`docs/GATE2_GATE3_CLOSURE_PLAN.md` §4.3. This prompt exists because the art-sourcing
rule now has a shape that costs the project a day every time it is hit cold:

> free packs first → three failed candidates produce a **brief** → the owner supplies
> reference art → only then is a Meshy generation spent.

The owner's words, 2026-09-04: *"you shouldn't use Meshy keys without art first."*
That is `CLAUDE.md`'s hard rule restored, not relaxed. The board is the unlock. So the
cheapest thing this project can do is have the boards **drawn before they are needed**,
for the objects most likely to need them, in the exact sheet format the pipeline already
knows how to cut.

This file carries three image-generator prompts the owner can paste into ChatGPT (or any
image model), the sheet contract each board must satisfy, and the intake steps that turn a
saved board into an installed model. **Nothing here spends a credit.** Section 5 says
when spending one becomes allowed, per object.

---

## 1. Why these three, and not others

Checked against the tree on 2026-09-04:

- The three objects `docs/decisions/D24` reserved Meshy for are **done**:
  `assets/environment/team_tether/tether_pylon.glb`, `relay_apparatus.glb`,
  `tether_machine.glb`, all from owner boards 13–15. The Warden is rebuilt from board 16.
  The Tuskroot "stand-in" that `data/creatures/species.json`'s header still mentions is
  stale: `assets/creatures/tetherbound/tuskroot/models/creature_tuskroot_lod0.glb` exists
  with Ashtusk, shiny and vivid textures. **No reserved object is outstanding.**
- Creatures and new humanoid bodies are ruled out by hard rule and stay ruled out.
- Candy, potions and revives are small props with an installed-then-free-pack path and a
  shared glow (`scripts/world/pickup_glow.gd`); they are unlikely to reach Meshy and are
  not here.

What is left is ranked by how likely the free-pack route is to fail:

| # | Object | Today | Why a pack will probably not cover it |
|---|---|---|---|
| A | **South Bridge checkpoint gate**, Team Tether | `scripts/world/south_bridge.gd` builds two `BoxMesh` posts, a lintel and two oxblood sigil banners over a field-fence leaf | It is a **Team Tether object**, the one category Meshy is reserved for. Every blind judge has named it. The closure plan already lists "a hero gate mesh" as the fallback if the dressed version is judged insufficient. |
| B | **Ruined watchtower landmark**, Upper Meadows wind ridge | `scripts/world/watchtower_landmark.gd` is primitive drums by its own admission ("placeholder geometry … easy to replace wholesale") | It has to read as a silhouette at 400 m on the far plane and belong to the key art's stone-timber vernacular. Packs give generic towers; the judge asks for *one* landmark the player navigates by. |
| C | **Riding Saddle**, generic, earned | No saddle mesh exists anywhere in `assets/`; only `assets/ui/icons/items/saddle_frame.png` | The owner's rule (2026-09-04): *"Nothing that is rideable should come with a saddle on it. You have to build the saddle and put it on then it visually appears."* One saddle must sit on three bodies: Terrapup 2.30 m, Tuskroot 2.15 m, Burrowback 1.70 m. Species-fitted props are where packs stop helping. |

A and C are Team Tether or player-craft objects and fit the reserved category or the
build system without touching the one-family rules. **B is not Team Tether**: generating it
relaxes the one-village-family rule for that one object, which CL-A1 permits only after the
three free-pack candidates fail *and* the owner has drawn the board. The board can still be
drawn now; §5 says when it may be spent.

---

## 2. The sheet contract — every board must look like board 13

`tools/art_pipeline/crop_prop_views.py` cuts generator inputs out of a board using
explicit per-view boxes in `prop_views.json`. It needs each view to be a clean figure with
**its caption below it and nothing else in the box**. Board 13
(`docs/art/reference/13_Tether_Energy_Pylon.png`) is the model; copy its layout exactly:

1. **Title block**, top left: `TETHERBOUND` / object name / `TEAM TETHER • MEADOWS BIOME`
   (or `MEADOWS VILLAGE FAMILY`, `PLAYER CRAFT`), then a three-sentence OVERVIEW.
2. **Beauty render**, left half: the object on a small patch of its own ground, 3/4 view,
   soft neutral light, with **callout labels on leader lines** naming its parts.
3. **ORTHOGRAPHIC VIEWS**, right half, a 2×2 grid, each cell captioned **below** the
   figure: `FRONT VIEW`, `SIDE VIEW`, `BACK VIEW`, `ALTERNATE ANGLE`. Same apparent scale
   in all four. Neutral pose. No text inside the figure. Light grey paper background.
4. **MODULAR BUILD LOGIC**, bottom left: the object exploded into 4–6 named subassemblies
   with `+` between them and a caption under each.
5. **DETAIL CLOSE-UP**, bottom right: one material close-up.
6. **Footer strip**: FACTION · BIOME · ROLE · SCALE (against a 1.80 m human figure) ·
   POLYCOUNT TARGET.

Why the format matters, in the pipeline's own words (`tools/art_pipeline/meshy.py`):
*"image-to-3D follows pictures over prose."* Four consistent views at one scale are the
signal multi-image-to-3D reconciles on. A beautiful single render with inconsistent side
views produces a worse model than a plain sheet with matching ones.

**Style language for all three** (from `docs/VISUAL_BIBLE.md` and `data/config/palette.json`):
stylised hand-painted PBR, between Valheim and Palworld, no photoreal surfaces, clean
readable silhouettes, modest surface noise. Team Tether grammar: dark weathered stone,
blackened timber, aged iron and brass trim, moss in the joints, **oxblood** (`#6b2a20`
family, muted, the key art's stronghold-banner value) only on banners, equipment and
uniforms, **teal** (`#3fe8c4`) only where Tether machinery is live. Friendly and village
objects never carry oxblood or teal.

---

## 3. The three prompts

Paste each as written. Where a line is in `[brackets]`, the owner may substitute. Keep the
sheet-format paragraph in every prompt; it is what makes the board cuttable.

### Prompt A — South Bridge checkpoint gate (Team Tether)

```
Create a game-art production sheet in the exact layout of a concept "production board":
title block top-left reading "TETHERBOUND / SOUTH BRIDGE CHECKPOINT GATE / TEAM TETHER •
MEADOWS BIOME" with a three-sentence overview; a large beauty render on the left half with
callout labels on thin leader lines; on the right half a 2x2 grid titled "ORTHOGRAPHIC
VIEWS" with cells captioned BELOW each figure: FRONT VIEW, SIDE VIEW, BACK VIEW, ALTERNATE
ANGLE, all four at the same scale, neutral light, no text inside the figures; bottom-left a
row titled "MODULAR BUILD LOGIC" showing the object exploded into named subassemblies with
"+" signs; bottom-right a "DETAIL CLOSE-UP"; a footer strip with FACTION, BIOME, ROLE,
SCALE (next to a 1.80 m human silhouette) and POLYCOUNT TARGET. Light grey paper background.

The object: a Team Tether field checkpoint built over the end of an old timber footbridge
in a green meadow. This is the FIRST Team Tether presence the player meets, early in the
game, so it is a modest occupation of a rustic bridge, not a fortress. Two squared
blackened-timber posts with aged iron strapping and rivets; a timber lintel across them; a
swinging gate leaf of iron-braced planks about 1.4 m tall; a movable timber-and-iron
barricade (a knife-rest of crossed beams) to one side; two hanging oxblood cloth banners
(muted deep red, weathered, never bright) each carrying one white compass-rose sigil;
one small hooded iron lantern on a bracket holding a faint teal crystal glow; a low sandbag
or stacked-crate guard post with a folding stool. Materials: dark weathered stone footings,
blackened timber, aged iron, brass rivets, moss in the joints, dry grass at the base. The
compass sigil is the only symbol. No skulls, no spikes, no chains, no glowing runes, no
machinery beyond the one lantern.

Style: stylised hand-painted PBR game art between Valheim and Palworld, clean readable
silhouette, modest surface noise, no photorealism, no lens effects. Subassemblies for the
build-logic row: POST (x2), LINTEL, GATE LEAF, BARRICADE, BANNER (x2), LANTERN, GUARD POST.
Scale: the lintel clears a 1.80 m human by half a head; total width about 4 m. Polycount
target 4K–6K triangles. The bridge deck itself is NOT part of the object; show only enough
deck under the posts to seat them.
```

### Prompt B — Ruined watchtower landmark (Upper Meadows, village family)

```
Create a game-art production sheet in the exact layout of a concept "production board":
title block top-left reading "TETHERBOUND / RIDGE WATCHTOWER (RUINED) / MEADOWS VILLAGE
FAMILY • UPPER MEADOWS" with a three-sentence overview; a large beauty render on the left
half with callout labels on thin leader lines; on the right half a 2x2 grid titled
"ORTHOGRAPHIC VIEWS" with cells captioned BELOW each figure: FRONT VIEW, SIDE VIEW, BACK
VIEW, ALTERNATE ANGLE, all four at the same scale, neutral light, no text inside the
figures; bottom-left a row titled "MODULAR BUILD LOGIC" showing the object exploded into
named subassemblies with "+" signs; bottom-right a "DETAIL CLOSE-UP"; a footer strip with
FACTION, BIOME, ROLE, SCALE (next to a 1.80 m human silhouette) and POLYCOUNT TARGET.
Light grey paper background.

The object: a ruined stone watchtower on a windy grass ridge, built long ago by the meadow
villages, not by any faction. A round drum of large weathered grey-tan fieldstone about
14 m tall, tapering slightly, with the top third broken away on one side so the silhouette
is unmistakably a tower with a bite out of it; a surviving stub of timber-framed upper
storey and a few thatch-and-timber roof rafters still clinging to the intact side; a narrow
arched doorway at the base; two slit windows; a collapsed section of curtain wall trailing
off into rubble; ivy and moss on the shaded side; a stunted wind-bent tree growing from the
rubble; a stone stair fragment inside visible through the break. The whole thing must read
as ONE clear shape from very far away: think of it as the landmark a traveller steers by.
Weathered gray/tan stone with per-stone value variation, moss in the mortar, timber the
same dark brown as a village barn. No banners, no glow, no metal, no faction marks.

Style: stylised hand-painted PBR game art between Valheim and Palworld, clean readable
silhouette, modest surface noise, no photorealism. Subassemblies for the build-logic row:
DRUM BASE, DRUM UPPER (BROKEN), TIMBER STOREY STUB, ROOF RAFTERS, CURTAIN WALL FRAGMENT,
RUBBLE SKIRT. Scale: about 14 m tall, 7 m across at the base, beside a 1.80 m human.
Polycount target 6K–9K triangles.
```

### Prompt C — Riding Saddle (player craft, one design for three mounts)

```
Create a game-art production sheet in the exact layout of a concept "production board":
title block top-left reading "TETHERBOUND / RIDING SADDLE / PLAYER CRAFT • MEADOWS BIOME"
with a three-sentence overview; a large beauty render on the left half with callout labels
on thin leader lines; on the right half a 2x2 grid titled "ORTHOGRAPHIC VIEWS" with cells
captioned BELOW each figure: FRONT VIEW, SIDE VIEW, BACK VIEW, ALTERNATE ANGLE, all four at
the same scale, neutral light, no text inside the figures; bottom-left a row titled
"MODULAR BUILD LOGIC" showing the object exploded into named subassemblies with "+" signs;
bottom-right a "DETAIL CLOSE-UP"; a footer strip with FACTION, BIOME, ROLE, SCALE (next to
a 1.80 m human silhouette) and POLYCOUNT TARGET. Light grey paper background.

The object: a hand-built creature riding saddle that a traveller crafts at a workbench
from ironwood, rootstone and fibre, then straps onto a large four-legged companion animal.
Show the saddle ALONE, resting on a plain wooden saddle stand, NOT on an animal. A curved
seat of oiled tan leather over a bent ironwood frame (pale hardwood with a visible grain);
a raised front pommel with a wrapped-cord handhold; a low cantle at the back; two wide
woven-fibre girth straps with carved rootstone (dull grey-green stone) toggle buckles;
two short leather stirrup loops; a rolled blanket pad beneath in a muted meadow-green
weave; a small leather saddlebag on one side. Everything must look adjustable: buckles,
lacing and straps with visible spare length, because the same saddle fits animals between
1.7 m and 2.3 m tall. Warm, friendly, homemade craft. No metal armour, no spikes, no
faction symbols, no oxblood red, no glowing parts.

Style: stylised hand-painted PBR game art between Valheim and Palworld, clean readable
silhouette, modest surface noise, no photorealism. Subassemblies for the build-logic row:
IRONWOOD FRAME, LEATHER SEAT, POMMEL + HANDHOLD, GIRTH STRAPS (x2) WITH ROOTSTONE
BUCKLES, STIRRUP LOOPS, BLANKET PAD, SADDLEBAG. Scale: seat about 0.6 m long, 0.45 m wide;
show it beside a 1.80 m human silhouette in the footer. Polycount target 2K–3K triangles.
```

If the generator will not put captions *below* the figures or crowds the orthographic cells
with text, ask it for the orthographic 2×2 grid alone as a second image with the same
object and lighting; `prop_views.json` can point at a second file.

---

## 4. Intake — from a saved board to an installed model

Numbering continues from board 16. Save the owner's images unchanged as:

```
docs/art/reference/17_South_Bridge_Checkpoint_Gate.png
docs/art/reference/18_Ridge_Watchtower_Ruined.png
docs/art/reference/19_Riding_Saddle.png
```

Then, per object, the route `docs/decisions/D49` proved on the relay apparatus and the
machine (nothing new is invented here):

1. **Boxes.** Add an entry to `tools/art_pipeline/prop_views.json` with `[x0, y0, x1, y1]`
   per view containing the figure and nothing else (stop short of the caption). Record the
   paper colour for the pad. Run `tools/art_pipeline/crop_prop_views.py --check` and look
   at the contact sheet before trusting the crops.
2. **Candidates.** `tools/art_pipeline/meshy.py generate <name> --tier preview`, **three
   candidates**, cheap tier first (§25 of the pipeline doc). Never accept candidate 1
   unseen. Refine only the winner.
3. **Inspect and render.** `blender/inspect_glb.py` on each (it can only reject), then
   `blender/turntable.py` from the same camera for all three, and put the three renders
   to the blind judge (`.claude/skills/visual-judge/SKILL.md`) against the board's own
   orthographic crops. Never judge your own candidates.
4. **Install** beside its family: `assets/environment/team_tether/south_bridge_gate.glb`,
   `assets/environment/nature/` or `assets/buildings/` for the tower (the visual lane
   decides which family it joins), and `assets/props/built/riding_saddle.glb` for the
   saddle, because it is a built item.
5. **Seat it through the existing seam, fitted by visual bounds.** D49's lesson: a Meshy
   GLB arrives at the generator's own scale with an arbitrary origin. Every seam fits the
   mesh to the authored height by the mesh's measured bounds, never by its transform.
   - Gate: `south_bridge.gd`'s posts, lintel and banners are children of the crossing,
     never of the swinging leaf. The hero mesh replaces the posts and lintel; the leaf
     stays the leaf so `gated_crossing.gd`'s open animation is untouched. Keep the
     `BoxMesh` massing as the fallback when `model` is unset (D49: "not dead code").
   - Tower: `watchtower_landmark.gd` was written to be replaced wholesale "without
     touching siting, collision or the reward pickup beside it." Do exactly that.
   - Saddle: attach to the mount's `mount_offset` point on `creature_body.gd` **only when
     the saddle item is fitted**. Per species it scales to the mount's `height`; per the
     owner, no rideable species may carry it at spawn.
6. **Render in the game's renderer** with `tools/capture_hero_asset.gd` (gl_compatibility
   is where the pylon's emission bug hid), then on the stand where the judge named the gap:
   the bridge approach, the band 4→5 seam ridge, and a mounted Terrapup for the saddle.
7. **Tests.** `smoke_art.gd` requires every `model` path to exist; `smoke_stronghold`'s
   `_aabb_of` measures through the full transform; add the same bounds assert for each new
   seam so a 1.7 m raw export cannot ship as a 14 m tower.

---

## 5. When a credit may be spent — per object

| Object | Spend allowed when |
|---|---|
| A — gate | The board exists in `docs/art/reference/`. It is a Team Tether object; D24's reservation covers it. Do not wait for a free-pack search: no pack carries a Team Tether checkpoint. |
| C — saddle | The board exists **and** the earned-saddle rule is implemented (saddle absent at spawn, appears when fitted), so there is a seam to install into. A quick free-pack look (Kenney/Quaternius survival kits already installed under `assets/props/`) is reasonable but not required. |
| B — tower | The board exists **and** CL-A1's three free-pack candidates (the installed Quaternius castle `Watchtower.obj` counts as one) have been rendered on the ridge stand and judged blind as failing. Only then is the one-village-family rule relaxed for this one object. |

**Fails if** a generation is run for any object without its board in the tree; if the
tower is generated before its three pack candidates are judged; if any rideable creature
spawns wearing the saddle; or if a candidate is installed from its own render without the
blind judge seeing all three against the board.

## 6. Out of scope, on purpose

- A hero mesh for the Meadows Hall, the Sigil Gate or the relay stations. The Hall asset
  pack (`docs/art/reference/hall-asset-pack-2026-08-30/`) already supplied those.
- Any creature, any humanoid.
- A branching tree form. `D73` §3 permits foliage cards and canopy break-up on the installed
  trees first; that lane has not run.
- Candy, potion and revive pickups. Installed-then-free-pack, see prompt 73 and the
  addendum §D.
