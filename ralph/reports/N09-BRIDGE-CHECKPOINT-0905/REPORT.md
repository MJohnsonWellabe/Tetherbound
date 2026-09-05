# N09-BRIDGE-CHECKPOINT-0905 — report

Branch `ralph/N09-BRIDGE-CHECKPOINT-0905`, from `origin/main` at `f8a47ee4`.

Brief: `ralph/briefs/0905-followup/N09-BRIDGE-CHECKPOINT.md` — close the three
"do not ship" items W22-BRIDGE-SIGNPOST-0904's landing-time blind judge named at the
South Bridge checkpoint (`ralph/reports/W22-BRIDGE-SIGNPOST-0904/JUDGE.md`, run by
W24-LANDING under the owner directive of 2026-09-05 02:24 UTC), plus a scope check on
the fourth. The judge's own framing: **ship the bridge deck/rail, do not ship the
signpost or the checkpoint dressing as they stand** — but *"the remaining work is scene
and material work, not new art"*. Nothing below adds a mesh, a texture or a generation.

## Files changed

| File | What |
|---|---|
| `scripts/world/south_bridge.gd` | barricade frames moved off the verge into the roadway (`BARRICADE_SIDE` 2.4 → 1.65) and turned into a shallow inward funnel (`BARRICADE_YAW_A`/`_B`, sign flipped against `side` so the inner end is the one nearer the gate); new `_wood_trim()` builds the barricade timbers' material from the buildings kit's own `MI_WoodTrim` maps at `build_material_finish.gd`'s own grade, UV-scaled into the trim sheet's wood band. Geometry and colliders untouched |
| `data/config/south_bridge_dressing.json` | the Bridge Sentry takes a per-individual `palette` override (`#ff6943`) so the grunt rig's own oxblood paint saturates without darkening; `_why_palette` records the measurement and both rounds of it |
| `scripts/world/signpost.gd` | the label is fitted and centred on the board this arm actually shows past its post (`_label_scale(label, span)`, `LABEL_POST_MARGIN`) instead of a fixed `0..ARM_LENGTH`, which is the "Relay Statio" clip the judge read; `outline_size` 12 → 18 |
| `tests/test_signpost_geometry.gd` | two new behavioural tests: no label runs under the post, and the ink outline is weighted between its two known limits |
| `tests/smoke_traversal.gd` | `_assert_the_checkpoint_narrows_the_road_without_closing_it` — a real 0.4 m shape query against the built collision space, with a positive control at the barricade's own beam so a query that is not seeing the world fails instead of passing |
| `tools/_probe_n09_checkpoint.gd` | new: prints the checkpoint's real built geometry (how far each barricade reaches into the road, the clear gap, the hero gate's material list, BoxMesh UV bounds). Every placement number below came out of it |
| `docs/decisions/D87-the-checkpoint-narrows-the-road-and-its-guard-wears-the-colour.md` | new |
| `docs/CURRENT_STATE.md` | §3 and §4b rows |
| `ralph/reports/N09-BRIDGE-CHECKPOINT-0905/` | this report, `JUDGE.md` and `JUDGE2.md` (two blind rounds), `JUDGE_PROMPT.md`, and one sheet per round: `_sheet_bridge_ab.png` + `_sheet_signpost_ab.png` (round 1), `_sheet_checkpoint_r2_ab.png` (round 2) |

Not touched: the hero gate mesh or its material, `npc_ranks.json`, the grunt rig, the
signpost's plank/post materials or any mesh, `building_prefabs.json`, the barricade's
own geometry or collision box, `docs/owner/*`.

## What the player sees

- **The road into the South Bridge checkpoint is pinched.** The two crossed-timber
  barricades no longer stand on the verge beside the road: they reach in from both
  sides, each turned a few degrees so its inner end is the one nearer the gate, and
  what is left between them is a gap a person walks and a cart does not. They are
  timber now — the same weathered kit wood the bridge deck and every village wall's
  exterior trim wear, with real grain and a normal map — rather than the flat
  single-colour blocks that were the least finished thing in the frame.
- **The guard is a Team Tether guard.** The grunt posted under the lantern wears the
  faction's oxblood instead of reading as a near-black figure; their uniform's own
  paint, which was always in the right hue family, is now saturated enough to be a
  colour at the distance a player meets them. A blind critic put it as *"a red mark
  that rhymes with the banners — the eye ties them together"*, against *"reads as a
  traveller, not a garrison"* on today's `main`.
- **Signposts say the whole word.** A destination name no longer starts behind the
  post — every label is fitted and centred on the board its own arm actually shows —
  so "Relay Station" is not "Relay Statio" any more, and every name carries a heavier
  dark edge that holds the word together at the distance a sign is read from the path.

## Numbers decided before the render

All measured on the really-built world by `tools/_probe_n09_checkpoint.gd`, and on the
source textures directly, before anything was rendered.

**Barricade placement** (crossing-local metres; the road is 3.00 m wide, so its
half-width is 1.50):

| | inner collision edge, \|z\| | reach INTO the roadway | clear collider gap | gap between the visible beam TIPS |
|---|---|---|---|---|
| `main` (`BARRICADE_SIDE` 2.4, yaw 6°) | 1.44 | 0.06 m | 2.88 m | 2.91 m |
| round 1 (1.85, yaw 24°/28° inward) | 0.76 / 0.75 | 0.74 / 0.75 m | 1.51 m | 2.11 m |
| **round 2, shipped** (1.65, yaw 6°/8° inward) | 0.69 / 0.67 | **0.81 / 0.83 m** | **1.36 m** | **1.51 m** |

`main` narrowed a 3.00 m road by 4 %. What ships narrows it by **55 %**, to a gap a
person walks and a cart does not.

The last column is why there are two rounds. Round 1 got the collider gap to 1.51 m and
the round-1 blind judge still said *"the dirt lane runs clean and unobstructed between
them … wide enough to drive a cart through"* — because a viewer reads the TIMBER, and a
28° yaw swings a beam's tip away from the centreline (by `cos(yaw)`) while adding to the
collider's own z extent (by the frame's half-width times `sin(yaw)`). The strong funnel
angle bought the idea of control and paid for it in the only measurement anyone actually
takes. Flattening the yaw to 6°/8° makes the two agree: the tips come in to \|z\| 0.76 and
the visible gap closes from 2.11 m to 1.51 m, while the walkable collider gap barely
moves. The player capsule is 0.4 m in radius, so **0.28 m of clearance survives on each
side**; the barricade geometry and its `1.3 × 1.3 × 1.8` collision box are byte-identical
throughout, only the frame's position and yaw moved.

**Barricade material.** `T_WoodTrim_BaseColor.png` is a trim sheet — horizontal bands,
each a different material, selected by `v`. Sampled 32 rows deep: `v` 0.00–0.31 is
grained wood, mean `#916337`, per-texel standard deviation 0.050; `v` 0.31–0.62 is a
near-flat dark brown (sd 0.011, no grain); above `v` 0.78 it is stone and metal. A
`BoxMesh`'s UVs span the full 0..1 in both axes (probed), so the material's `uv1_scale`
compresses `v` into 0.03–0.27 — the first band only — and tiles `u` twice so the grain
repeats along a beam. Through the `south_bridge` recipe's own `MI_WoodTrim` retint
(`#cfd6d4`, the multiply the deck already wears) that band lands at `#765a2e`, against
board 18's sampled plank brown `#875e42`. `roughness` 0.72 / `metallic_specular` 0.28 /
no roughness map are read out of `build_material_finish.gd::FINISH["MI_WoodTrim"]`
rather than copied, so a retune there moves this timber with the rest of the game.

**Guard tint.** `grunt_lod0_texture_0.png`, 4.09 M non-black texels: median RGB
(0.173, 0.129, 0.129) — hue 340°, saturation 0.35, **value 0.173**. Through the rank's
neutral `#dcdcdc` and through the new `#ffab9c`:

| | rendered albedo | H | S | V | additive emission floor (`tint × 0.18`) |
|---|---|---|---|---|---|
| before | (0.1489, 0.1116, 0.1116) | 0.0° (grey) | 0.250 | 0.149 | (0.155, 0.155, 0.155) neutral |
| after | (0.1725, 0.0868, 0.0792) | 4.9° | **0.541** | **0.173** | (0.180, 0.121, 0.110) red-biased |

Saturation more than doubles and value goes **up** 16 %: a palette entry is an albedo
multiply and can only darken, so the red channel is held at 255 and only green and blue
are cut. The hue lands in the same family as the two staked banners beside them
(`FACTION_CLOTH` `#633128`, hue 12°).

**Signpost ink.** Rendered board `#b67c55` (the landing judge's own sample) has relative
luminance 0.250; the cream ink `#f4ecd8` is 0.842 and the dark edge `#2a1a10` is 0.013.
So the cream carries **2.97:1** against the board and the edge carries **4.79:1**, in
opposite directions — which is both of the judge's numbers at once: 3.0:1 in the studio
rows where the glyphs are 38–60 px and the cream core wins, and about 1.3:1 in the
in-world rows where the whole glyph band is 7–10 px, every letter is subpixel, and one
screen pixel averages cream, edge and board into something within a whisker of the board
itself. `outline_size` 12 → 18 moves the edge-to-core area ratio from roughly 2:1 to 3:1,
so the word resolves at distance as a dark mark ON the board at the edge's own 4.79:1
rather than averaging into it. 18/144 is 12.5 % of the em, well under the ~21 % GF-B-013
measured as the point where the edge floods an `o`'s counter.

## Measured in the rendered frames

Same crop, same stand (`bridge-approach-played`), same lighting, four trees:

| | guard's torso (35 × 70 px, median) | red-to-blue |
|---|---|---|
| `main` | `#4e483f` — H 36°, S 0.19, V 0.31 | 1.24 |
| round 1 (`#ffab9c`) | `#563b31` — H 16°, S 0.43, V 0.34 | 1.76 |
| round 2 first pass (`#ff7a5c`) | `#603528` — H 14°, S 0.58, V 0.38 | 2.40 |
| **round 2, shipped (`#ff6943`)** | `#5f3125` — **H 12°, S 0.61, V 0.37** | **2.57** |
| the two staked banners in the same frame, for scale | `#8e382a` — H 8°, S 0.70, V 0.56 | 3.38 |

The round-1 judge measured this crop itself and got 1.22 → 1.72 for the same two trees, so
these numbers and its are the same measurement. **This is also where the ceiling on a
palette override is**: the tint's own red-to-blue went 2.77 → 3.81 between the two passes
of round 2 and the rendered ratio moved only 2.40 → 2.57, because the grunt rank's additive
emission floor and the tonemap both pull toward neutral and neither is reachable from a
`palette` entry. The guard now sits in the banners' own hue family (12° against 8°) at
0.61 saturation against their 0.70, and getting the last of the way to 3.38 needs something
this lane does not own — the rank's `emission_floor`, the rig's texture, or an accessory.

| | barricade beam, per-pixel luminance sd | median luminance |
|---|---|---|
| `main` | 0.079 / 0.089 | 0.41 / 0.45 |
| shipped | **0.141 / 0.147** | 0.46 / 0.47 |

Surface variance nearly doubles — that is the grain and the normal map giving the key light
something to find, which is the whole content of "untextured". Median luminance is
essentially unchanged, so the barricade did not become the brightest thing in the frame: it
renders at V 0.57–0.62 against the kit crate beside it at 0.69 and the gate leaf at 0.59.

Whole-frame oxblood fraction (H 350–15°, S > 0.45) is 3.63 % → 3.68 %. The guard is a small
part of the frame and this number barely moves; it is recorded because it is the number W22
used, and it is honest that a body-tint change does not show up in it.

## The four brief items, one by one

### 1. Barricades — textured, and reaching into the road. Done.

Both halves of the judge's call. Placement and material are described above with
their numbers; `docs/decisions/D87` records the one design call inside it, which is
that D86 §1's rule is restated from a coordinate (`|z| >= 1.5 m`) to the thing that
coordinate was standing in for: **the barricade may narrow the road and may never
close it, and never stands on the deck.** D86 §1's actual reason — `gated_crossing.gd`'s
leaf is the one thing that shuts this road, and a sealed approach would need a second
unlock — is untouched and is why the gap is a real 1.36 m rather than a token one.

It took two rounds, and the second round is the interesting one: round 1 hit the collider
number and the blind judge still read the road as open, because a viewer measures the
TIMBER and a strong funnel yaw swings the timber away from the centreline while adding to
the collider's reach. The two disagreed and the judge was right about the thing that
matters. See the placement table above for the arithmetic and both rounds' numbers.

The material is the buildings kit's own `MI_WoodTrim`, the material this bridge's deck
and every village wall's exterior timber already wear, at the grade
`build_material_finish.gd` applies to every other `MI_WoodTrim` surface in the game.
`assets/environment/team_tether/` holds no barricade or blockade material — it is four
Meshy hero objects, two shaders and a pylon albedo — so the brief's "check
`assets/environment/team_tether/` for barricade/blockade materials already used
elsewhere" resolved to "there are none; use the one the rest of the crossing wears".

### 2. Guard faction colour — done, scoped to this one body.

`docs/art/HUMANOID_ASSET_INVENTORY.md`'s claim that Team Tether grunts have faction
colouring available is true, and the reason it was not visible is measured above: the
colour is in the rig's paint at value 0.173 and the rank's neutral multiply leaves it
at 0.149. The lever used is `village_npcs.gd::model_config`'s per-individual `palette`
override, applied in `data/config/south_bridge_dressing.json` — a material/tint change
on the existing rig, no new geometry, no accessory added.

Tuned in three passes against a number the round-1 judge supplied by measuring it (the
banners' own red-to-blue in the same frame), and **it hit a ceiling short of that number**:
rendered red-to-blue went 1.24 → 1.76 → 2.40 → 2.57 against the banners' 3.38, while the
tint's own ratio went 1.00 → 1.49 → 2.77 → 3.81. The last step bought 0.17. The guard is
now unmistakably in the faction's hue family (12° against the banners' 8°, saturation 0.61
against 0.70, and the value deliberately unmoved so they stay in a dark uniform) and closing
the rest needs the rank's `emission_floor`, the rig's texture, or an accessory — none of
which is a checkpoint-dressing lane's. That ceiling is measured, not assumed, and it is
recorded rather than chased further.

`npc_ranks.json` is deliberately NOT edited. Repainting the grunt rank repaints every
Team Tether body in the game; that is a cast-wide look decision two blind rounds have
already tuned and is not a checkpoint-dressing lane's to make. Recorded in D87 §2,
including what should happen to this override if a later cast lane does make it.

### 3. Gate banners — ROUTED, not fixed. The material is not separable.

The brief's condition was "retint the gate's banner material if it's a separate
swappable material slot ... check the `.glb`'s material list before assuming this needs
new geometry". Checked both ways, and it is not:

- **In the file.** `assets/environment/team_tether/south_bridge_gate.glb`'s JSON chunk
  carries `"materials"` of length **1**, `"meshes"` of length 1 with a single primitive
  bound to material 0, one `"textures"` entry and one `"images"` entry
  (`south_bridge_gate_0.jpg`, an embedded JPEG).
- **On the imported scene.** `tools/_probe_n09_checkpoint.gd` instantiates it and walks
  every `MeshInstance3D`: one node, one surface, `material_0`, albedo texture present,
  no normal or roughness map.
- **The banners are in that one texture.** Sampled at 1-in-101 texels: 2.30 % of the
  atlas is blue-family (hue 190–260°, S > 0.25), median hue 216° / S 0.49 / V 0.27 — the
  banners — against 0.149 % red-family. There is no second slot to retint.

So the only material on the gate paints its posts, lintel, lanterns and stonework as
well as its cloth, and retinting it would recolour the whole hero gate. Per the brief's
own instruction, this sub-item is **routed to the coordinator as needing a Team Tether
asset lane** — either a re-generation from board 21 with oxblood cloth, or a texture
repaint of the banner region of `south_bridge_gate_0.jpg`, both of which are asset work
outside this lane's ownership and outside "materials and placement". D86's own "what
this does not decide" already flagged it as a board question; this adds the measurement
that settles the "is it even a material fix" half.

### 4. Signpost legibility — the material half fixed, the size half routed.

The scope check the brief asked for, first: **the signpost's text is a `Label3D`, not
baked UV or geometry detail.** `signpost.gd::_add_arm` builds two `Label3D` nodes per
arm, one per broad face, and sets `text`, `font_size`, `pixel_size`, `modulate`,
`outline_size` and `outline_modulate` on them. So "increasing contrast and glyph weight
in that material" is in scope, and it was done — see the ink numbers above for the
cancellation that produces the judge's 3.0:1 / 1.3:1 pair and what `outline_size`
12 → 18 does to it.

The second thing in scope turned out to be the defect the judge actually quoted.
*"Both columns also clip the last character ('Relay Statio') because the label runs
under the post"* is not a mystery: each arm mounts at its own golden-angle point on the
post's circumference, so the post's centreline falls at a different `z` in every arm's
own frame — anywhere within ±`ARM_MOUNT_RADIUS` (0.16 m) — and `_label_scale()` fitted
and centred every label against a fixed `0..ARM_LENGTH` board regardless. On an arm
whose mount sits on the far side of the post from its own bearing, the trunk reaches
past where the text starts. Measured on the built signpost: the text began at z 0.084
against a trunk face at 0.090 on three of the four test arms, `Relay Station` among
them. The fit and the centre are now taken against the board that arm actually shows.

**What is NOT fixed, and why it is not material work.** The judge's headline signpost
number is a glyph cap height of **5–7 px** at `south-bridge-trailhead`. That is a
0.24 m board read from 10–15 m, and no `Label3D` property reaches it: `_label_scale()`
already fits the glyphs to the board, so making letters bigger means a bigger board
(geometry, and R9.4 cut this assembly down after a blind critic measured it at ~1.5×
oversized) or shorter destination names (a content decision). **That half is a
Bucket-B art/design gap and is recorded as one rather than attempted.** The check that
justifies the call is the one above: the text is a `Label3D`, so contrast and weight
were reachable and were changed; cap height is a function of board size, which is the
base mesh, which this lane does not own.

## The blind judge

Two rounds. Both used contact sheets built the same way and both were run by a code-blind
sub-agent (opus) given only the sheets, `docs/reference/`, board 18
(`docs/art/reference/18_Signpost_Bridge_Modular_Props.png`) and
`.claude/skills/visual-judge/SKILL.md`, told nothing about what changed, told the columns
were "A" and "B" with no statement of which was newer, and told explicitly not to assume
either column was the improvement. `JUDGE_PROMPT.md` beside this report is exactly what it
was given; `JUDGE.md` is round 1's verdict in full.

**Both columns of every sheet were rendered in this container, minutes apart, from
`origin/main` at `f8a47ee4`** — the "before" column by stashing this lane's four tracked
edits out of the tree (`git stash`), rendering, and restoring them. W22's own committed
sheets were NOT reused as the before column: today's `main` carries several waves of
vegetation, terrain and tree work that landed after W22 rendered, and a column shot on that
older tree would have handed the judge differences this lane did not make. **A is this
lane's work and B is `main`.** W22's sheets put its new work in B and its judge picked B;
the columns are deliberately the other way round here so a second round cannot be scored by
position.

### Round 1 — what flipped, and what did not

Round 1's sheets were the four bridge stands, two studio deck stands, the in-world signpost
stand and the two studio signpost stands. The judge answered the landing judge's own four
questions. Its own words, unprompted and without being told which column was which:

- **Barricade texture — resolved, flatly.** *"**A:** fully textured timber. Visible grain,
  knots, weathering, saw-cut ends, bevelled edges. Reads as the same material family as the
  crate, the hay bales and the gate standing beside it. **B:** untextured blockout. Flat,
  uniform, desaturated taupe-mauve prisms with smooth-shaded facets, zero grain, zero
  variation. Beside an A-quality crate and hay bale they read as primitives someone has not
  got to yet."* And in its ship call: *"B's barricades specifically must not ship in any
  form."* B is `main`.
- **Signpost lettering — resolved, and it found the exact defect this lane fixed without
  being pointed at it.** *"A is closer, decisively... B sets larger type on every arm and
  pays for it by clipping the destination: 'Relay Station' renders as 'Relay Statio', the
  final glyph swallowed by the post and the arm bracket. A fits all four names inside their
  planks with margin... Shipping a truncated place name is a hard fail."* Same call on both
  studio rows.
- **Guard colour — moved, not resolved.** It measured it: banner oxblood `(146,58,44)`,
  red-to-blue **3.35**; guard torso **A `(91,61,53)`, red-to-blue 1.72**; **B `(83,74,68)`,
  red-to-blue 1.22**, *"effectively neutral grey-black... furthest from the faction colour
  of anything in frame."* A is *"a warm brown, R/B 1.72. Closest of the two, but it is
  brown, not oxblood."*
- **Barricade PLACEMENT — not resolved.** *"Do they control passage? No — in neither
  column... the dirt lane runs clean and unobstructed between them... the gap between the
  two pieces is wide enough to drive a cart through."* This is the finding round 2 exists
  for, and it is a fair one: see round 2 below for why the collider numbers and the judge's
  read disagreed and which of them was right.
- **It independently corroborated the routed banner finding.** *"Competing navy livery
  (39,64,88) on both gate uprights"* — a second blind read, on different frames, of the
  same hero-gate cloth this lane routed as unfixable without an asset lane.
- **Everything else it ranked** is on the bridge deck and rail (plank direction, the
  near-white post-base blocks, missing ironwork, post-to-deck value ratio, the stone apron,
  staggered posts, the rope), on the signpost's proportions and finial, on the lantern's
  cyan, and on the in-world signpost's ~12 px caps at ~2.6:1. **None of those is in this
  lane's ownership**, and the judge itself noted the two deck rows are pixel-identical
  between A and B — this lane did not touch the deck. They are recorded here as the
  standing bridge backlog, not as this lane's residue.

### Round 2 — the two open items, judged by a fresh critic

Round 2 changed only the barricade placement and the guard tint, re-rendered the two
checkpoint stands, and put them to a **fresh** sub-agent with no memory of round 1 and no
access to round 1's frames, verdict or scratch directory. Its questions were narrowed to
the two open items and written so they could only be answered by measuring. `JUDGE2.md`
is the full verdict. On the brief's three named "do not ship" items:

- **Barricade texture — resolved.** *"**A:** textured, in both rows. Longitudinal wood
  grain, darker knot streaks, saw-cut ends showing end grain, colour variation along each
  beam… This matches the material language of the owner's prop board. **B:** untextured
  blockout, in both rows. Flat matte putty-brown prisms with a single diffuse albedo and
  nothing but hard-facet Lambert shading."* It measured it: high-frequency detail (per-pixel
  luminance minus a 1.5 px Gaussian) inside one beam face, **A hf std 16.57 against B's
  1.89 at the same mean luminance — 8.8×**, and it placed A inside the frame's normal
  material range (gate timber 23.4, crate 15.3) while *"B's is an order of magnitude below
  everything else in the picture."*
- **Barricade placement — resolved.** It measured the road at ~2.3 m and then the gap:
  *"**A — they control passage, partially.** … Clear projected channel: 76 px = **1.25 m**,
  about 54 % of the road [row 1]. … 48 px = **~1.0 m**, about 28 % of the road at that depth
  [row 2]. **What fits: a person, comfortably. A handcart, scraping. A wagon or a cart team,
  no. That is a real checkpoint gap, and it is the single strongest thing column A does.**"*
  Against `main`: *"**B — they stand beside the road and control nothing.** … It stops 6 px
  short of the verge — entirely off the carriageway. … Clear channel: ~180 px, versus a road
  of 139 px. **The gap is wider than the road.** … What fits: everything."*
- **Guard colour — resolved.** *"**A: yes, unambiguously. B: no, not remotely.**"* Six
  on-body samples per column against the banner cloth in the same tile: A hue 11.5–16.4°
  against the banner's 8.0–8.5°, saturation 0.59–0.67 against 0.70, red-to-blue 2.4–3.0
  against 3.3–3.4 — *"She is darker than the cloth… which is exactly what leather/wool reads
  as against a dyed banner. **A player reads that figure as wearing the livery.**"* Against
  `main`: saturation 0.15–0.28, *"below the point where a hue reads as a colour at all"*,
  red-to-blue 1.17–1.38, *"the signature of a neutral, not a red… A player does not read that
  figure as wearing anything."*

**"A is the better column, on all three counts, without qualification,"** and *"Column B is
not a candidate for shipping in any form."* B is `main`.

### What the round-2 judge still calls DO NOT SHIP, and why none of it is this lane's

Its overall call on the checkpoint is still **DO NOT SHIP**, and it is right, but its ship
gate is three items this lane does not own — it says so itself when it splits each one:

1. **"Nothing in the frame casts a shadow."** Not the banners, not the gate, not the
   trestles, not the crate, not the trainer, not the guard. Its own fix: *"Turn on shadow
   casting for the directional light and give the props a contact/AO term. No new asset.
   Highest value per hour on this list by a wide margin."* That is a global lighting call
   in `world_look.gd` affecting every frame in the game — the largest single finding this
   lane surfaced, and it belongs to whoever owns world lighting.
2. **"The crossing is narrowed but not closed, and is trivially walked around."** The gap
   is now right; the verges either side of the checkpoint are open meadow, so a player can
   step around the whole thing. Closing that needs a line running from the gate out into
   the terrain until it dies on something impassable — repeated trestles at minimum, a
   fence or palisade asset properly, and the judge notes no such asset appears in any of
   the frames. It is also a bigger call than dressing: D86 §1's whole mechanism argument is
   about what may and may not stop a player at this crossing.
3. **"The slab in front of the gate is untextured blockout."** A flat blue-grey plate at
   the dead centre of the composition where the road meets the gate. Present in every
   column including `main`; it is part of the crossing's own span/gate, which this lane is
   explicitly told not to touch. Its fix is a material already in the same frame.

Everything else it ranks (sawhorse silhouette, the guard's idle and placement, the cyan
lantern and blue pier drapes, rigid flat banners, the dirt-splat road, no notice board,
foreground framing) is likewise outside `south_bridge.gd`'s checkpoint dressing or needs
art. All of it is routed below rather than half-attempted.

## Tests and smokes

Godot 4.7-stable installed fresh in this container (none was preinstalled) and used for
every run below. No self-report: every number is from a run in this container, on this
tree, at the state named.

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_signpost_geometry.gd` | **8 tests, 133 assertions, 0 failed** |
| the same, with the three signpost edits reverted in place (**the seen-red run**) | **2 failed, both new tests, for the right reasons.** `test_no_label_runs_under_the_post`: *"Arm_Relay Station: 'Relay Station' starts at z 0.084, inside the post's face at 0.090"* — the same arm and the same word the landing judge read as "Relay Statio", reproduced as a number. Also red on `Arm_Grandpa's House` and `Arm_Watchtower Spur`; `Arm_The Pond` is short enough that its fit is height-bound and it clears. `test_the_ink_outline_is_weighted_between_its_two_known_limits`: *"outline is 8.3% of the em, too thin to carry the word at distance"* on all four arms. Restored: 8/8 |
| `... --only=test_signpost_geometry.gd,test_crossing_failsafe_placement.gd,test_river_crossings_stay_open.gd,test_item_gate.gd` (the brief's four-file crossing set) | **28 tests, 216 assertions, 0 failed** |
| `godot --headless --path . --script tests/smoke_traversal.gd` (final tree) | **`traversal: OK`.** *"South Bridge, held: 18 rail posts, 2 banners, sentry posted"* · *"South Bridge, road: barricades solid, 0.8m centreline probe walks the gap"* (the new assertion) · *"the South Bridge, locked: reached −5.0m past the gap"* · *"unlocked: reached +22.9m past the gap"* · *"South Bridge, opened: sentry stood down, barricade still standing"*. The two walk figures are identical to W22's own, so the narrowed approach costs the gated walk nothing. Old Mill Crossing (−8.0 / +23.5) and the Sigil Gate sweep unchanged |
| the same, with the new road assertion's two conditions deliberately broken in `south_bridge.gd` — side A's collider not built, side B moved onto the centreline (**the seen-red run**) | **both halves red, each for its own reason**: *"traversal FAIL: barricade A is not solid to a 0.40m probe at its own beam — either it has no collider or this query is not seeing the world, and the road-clear check below cannot be trusted either"* and *"traversal FAIL: barricade B closes the road: a 0.40m probe on the centreline is blocked. The checkpoint narrows the way through, it never seals it (D87 §1)"*. Breaks reverted; green again |
| `tools/_probe_n09_checkpoint.gd` (headless, real built world), on `main` and after each round | the placement table above |

The new `smoke_traversal` assertion is a real physics query, not a coordinate check: it
sweeps a sphere of the player's own 0.4 m radius against the built world's collision space.
Its **positive control is the point of it** — the same sphere is asked at the barricade's
own beam first, where it must be blocked, because Terrain3D runs in Dynamic/Game here and
"clear" and "no collision shapes loaded yet" would otherwise look identical. The red run
above proves both halves fire.

### The one red, and why it is not this lane's

The first `smoke_traversal` run on this branch ended
`traversal FAIL: player got wedged (held an input, stayed grounded, moved under 0.5m for
1.0s+) at 1 spot(s): move_left at (-11, -167)` — in the free-walk probe near spawn, in
the village. It did not reproduce, and it is not this lane's:

| run | tree | free-walk `move_left` | verdict |
|---|---|---|---|
| 1 | this branch | wedged at (−11.1, 3.7, −166.9) | FAIL |
| 2 | `origin/main`, this lane's four tracked edits stashed out (`git stash`, same container, same binary) | walked to (−1020.5, …) with no stall | **OK** |
| 3 | this branch again (`git stash pop`) | walked to (100.4, −5.0, −166.4) | see the table above |

The probe is not deterministic run to run: the same `move_right` leg ended at
(129.6, −4.2, −166.4) on run 1 and at (133.7, −3.1, −166.4) on runs 2 and 3, on trees that
differ only in this lane's diff for one of the three. The wedge site is **1,497 m from the
South Bridge** and 160 m from the village junction signpost, and this lane changed exactly
three things: barricade placement and material at world (8, 1317.6), one NPC's palette at
world (6.4, 1319.2), and `Label3D` properties, which carry no collider anywhere. There is
no mechanism by which any of them wedges a body in the village. Reported rather than
buried, and reported as intermittent rather than as fixed — nobody chased it.

## Findings routed on, not fixed here

Ranked by what they would buy. The first is the largest thing either round surfaced and it
is not about this checkpoint at all.

1. **Nothing in the game casts a shadow in these frames.** Round 2's judge, unprompted and
   as its top-ranked finding: *"Not the two 3 m banners, not the gate, not the trestles, not
   the crate, not the trainer, not the guard. Zoomed to 8×, the trainer's boots meet pale
   ground with zero darkening and zero contact occlusion… The only shading present is
   surface-normal shading. This is the loudest defect in the picture and it is why the whole
   checkpoint reads as decals stuck on a hillside rather than objects standing on ground."*
   It measures this against the owner's own key art (*"built on long directional shadows
   across grass"*) and the Palworld bar (*"a hard contact shadow under every character,
   creature and tree"*), and it prices the fix: *"Turn on shadow casting for the directional
   light and give the props a contact/AO term. No new asset. Highest value per hour on this
   list by a wide margin."* That is `world_look.gd` / the world's directional light and it
   affects every frame in the game, so it is emphatically not a checkpoint-dressing lane's —
   but it is the single item most likely to move a blind verdict anywhere in the Meadows,
   and it should be someone's next lane. These renders are software GL in this container,
   so a first step is confirming the same is true on a real GPU before changing anything.
2. **The checkpoint can be walked around on the grass.** The gap through the barricades is
   now right; the verges either side are open meadow. *"A checkpoint that can be bypassed on
   foot in three seconds is not a checkpoint."* Its fix — a line running from the gate out
   into the terrain until it dies on something impassable — is both a bigger scene change
   than dressing and a design call D86 §1 deliberately did not make (its whole argument is
   about what may stop a player at this crossing and what may not). Needs an owner who can
   reopen D86, and probably a fence or palisade asset: the judge could not find one in any
   frame.
3. **The grey slab where the road meets the gate is undisguised blockout.** *"A flat
   blue-grey plate (median ~(120,128,133), essentially uniform)… It has a visible hard edge
   against the dirt and does not read as stone, plank, threshold or ramp. It is the one
   piece of undisguised placeholder left in column A and it sits at the exact centre of the
   composition."* Present on `main` too. It belongs to the crossing's own span/gate, which
   this lane is told not to touch, and the fix is a material already in the same frame
   (the gate piers' stone, or the gate's own plank).
4. **The hero checkpoint gate's blue banners need a Team Tether asset lane.**
   `assets/environment/team_tether/south_bridge_gate.glb` is one node, one mesh, one
   primitive, one material, one baked atlas — measured both in the file's JSON chunk and on
   the imported scene — and 2.30 % of that atlas is blue banner cloth (median hue 216°,
   S 0.49, V 0.27) against 0.15 % red-family. There is no separable slot, so the only
   material on the gate paints its posts, lintel, lanterns and stonework as well as its
   cloth. The fix is a re-generation from board 21 with oxblood cloth, or a repaint of the
   banner region of `south_bridge_gate_0.jpg`. **Both blind rounds found this
   independently** — round 1 as *"competing navy livery (39,64,88) on both gate uprights"*,
   round 2 as *"deep blue drapes hang on both gate piers, immediately behind and beside the
   oxblood banners… oxblood should be the only saturated non-natural colour at this
   crossing."* Whoever owns `docs/specs/ASSET_LEDGER.md`'s Team Tether entries owns this.
5. **The barricade's SILHOUETTE is a sawhorse, and this lane could not change it.**
   *"A single hip-height rail (~0.97 m) on an X frame. No stakes, no points, no lashings,
   no rope, no crossed spears… The iron bands are good; the form is wrong."* The brief
   scoped this lane to "materials and placement only", and its Verify line says in as many
   words that the geometry must not change, so the frame was left byte-identical. A lane
   that owns the barricade geometry should read that paragraph of `JUDGE2.md` first.
6. **The posted sentry stands in the lantern post, from the played stand.** *"In row 1 a
   black iron lamp post passes vertically straight through her silhouette and cuts her in
   half."* Both are this lane's dressing and the fix is one number — the lantern sits at
   crossing-local (−10.5, +2.0) and the sentry at (−10.8, +1.6), nearly collinear from the
   played camera at (−16.4, −1.9); moving the lantern to about z +2.6 separates them. It is
   **not done here** because it cannot be verified without another 25-minute world render
   and this lane would be claiming a fix it had not seen. It is small, it is cheap, and it
   should be picked up with any other change to this file.
7. **The lantern's cyan is deliberate and is being read as a defect in daylight.** Round 2:
   *"Its glass is a flat, opaque cyan swatch… with no emission, no bloom, no falloff."* It
   does carry emission and a real `OmniLight3D` at 0.7 energy; what it does not do is show
   in a **day** frame, which is exactly what W22 and D86 intended (`palette.json`'s
   `tether_teal` is *"reserved for live faction machinery"*, and D86 wanted it faint by
   day). Both blind rounds have now called it a cold sticker anyway. Not overturned here —
   a reserved-colour decision two documents deep is not a dressing lane's to reverse on a
   daylight read — but recorded, because the third judge to say it should be listened to,
   and nobody has yet graded this checkpoint in a NIGHT frame where the choice would pay off.
8. **Signpost glyph cap height is a board-size problem, not a material one.** 5–7 px at
   `south-bridge-trailhead` (round 1's judge independently measured ~12 px at 1280×800 with
   ~2.6:1 contrast) comes from a 0.24 m board read at 10–15 m. Reaching it means a bigger
   board — and R9.4 already cut this assembly down after a blind critic measured it at ~1.5×
   oversized against the 1.4 m well beside it — or shorter destination names. Bucket-B, and
   it needs someone who owns both the board's proportions and the route labels.
9. **`place5-bridge-approach` is still shot at knee height with a heavy depth-of-field
   blur.** Two independent blind judges (W05's and W22's) already flagged this stand, and
   round 1 here looked at the same camera. It is a defect in the capture tooling's viewpoint
   list, not in anything at the crossing, and it belongs to whoever owns
   `tools/_capture_band1_places.gd`. Repeated only because a third round has now paid for it.
10. **`npc_ranks.json`'s `_comment_oxblood` is stale and misleads.** It states the
    grunt/officer/captain body palettes are "a warm rose-red family multiplied onto the
    grunt rig's own dark tactical texture"; T1-GROUND replaced all three with a neutral
    value ladder five days later and the comment was never updated. A reader checking
    whether Team Tether wears its own colour gets the wrong answer from the file that should
    settle it — which is how this lane's item 2 came to exist. One paragraph, in a file this
    lane deliberately did not touch.

11. **Twelve scripts on `main` are missing their `.uid` sidecars.** A first
    `godot --headless --import` in a clean container generates
    `autoload/realm_heart_state.gd.uid`, `scripts/world/cloudreach_world.gd.uid`,
    `scripts/world/realm_gate.gd.uid`, `scripts/world/realm_heart_shrine.gd.uid`,
    `tests/smoke_cloudreach_foundation.gd.uid`, `tests/smoke_cloudreach_transition.gd.uid`,
    `tests/test_cloudreach_chapter_data.gd.uid`, `tests/test_cloudreach_world_data.gd.uid`,
    `tests/test_meadows_cloudreach_handoff.gd.uid`, `tests/test_realm_heart_state.gd.uid`,
    `tests/test_realm_world_components.gd.uid` and
    `tools/capture_cloudreach_foundation.gd.uid` as untracked files. The repo tracks `.uid`
    sidecars everywhere else (this lane's own `tools/_capture_w22_bridge_signpost.gd.uid`
    is one), so these twelve Cloudreach/realm-heart scripts landed without theirs. Godot
    mints a fresh random UID per machine, so every clean checkout produces twelve different
    untracked files and any two lanes that commit them collide. **Deleted rather than
    committed here** — they are generated output for files outside this lane's ownership,
    and committing another lane's sidecars with UIDs minted in this container is worse than
    leaving the gap. It belongs to whoever owns the Cloudreach scripts.

Round 2's judge also ranks the rigid flat banners, the dirt-splat road, the guard's idle
and weapon, the absent notice board and the row-1 framing. All of those are either art that
must be made or files outside this lane; its own §5 table splits each one. `JUDGE2.md` is
committed in full rather than summarised, because that table is the useful artefact.

## Known limitations, and what was deliberately not done

- **The gate's blue banners are still blue.** Routed, with the measurement that settles
  why it is not a material fix (above, and D87's "what this does not decide").
- **Signpost cap height at gameplay distance is unchanged**, and cannot be changed at
  material level. Recorded as Bucket-B rather than attempted.
- **Nothing walks the chicane on the real player route.** `smoke_traversal`'s bridge walk
  starts at `near_point(11.0)`, 1.4 m PAST the barricade frames, and `smoke_gate_b_continuous`
  ends the chapter before the crossing (its own header: *"`south_bridge_open` is
  deliberately not a row here"*), so no existing harness drives a body up the road
  through the gap. The gap is asserted two ways instead — measured off the built
  colliders by `tools/_probe_n09_checkpoint.gd`, and asked of the real physics space in
  `smoke_traversal.gd::_assert_the_checkpoint_narrows_the_road_without_closing_it`, with
  a positive control at the barricade's own beam so a query that is not seeing the world
  fails loudly instead of passing. A walked crossing of the chicane is the better test
  and belongs with whoever next extends the Gate C route walk.
- **`npc_ranks.json` untouched**, so every other Team Tether body in the game still
  renders at the value its own rank palette gives it. Only the Bridge Sentry changed.
- **The barricade's geometry and collision box are unchanged** — the brief's own line
  ("you are not changing collision/geometry, only materials and placement") was held
  literally: `BARRICADE_LENGTH`, the beam, the four legs and the `1.3 × 1.3 × 1.8`
  `BoxShape3D` are byte-identical, and the collider moves only because the frame it is a
  child of moved.
- **The trim sheet's wood band is sampled with an anisotropic UV scale** (`v` compressed
  to 0.24 so a `BoxMesh`'s 0..1 unwrap lands inside one band). The grain therefore
  stretches across a timber's short axis. It is a real texture with a real normal map
  where there was none, and it reads as timber at every distance shot here, but it is not
  a proper unwrap and a lane that owns the barricade geometry could do better with one.
- **The full unit suite was not run** (the brief named the four-file crossing set and
  `test_signpost_geometry.gd`, and both were run). `verify-terrain-bake-freshness` and
  its unit shard are the known red on `main` that N10 owns; nothing here touches
  `data/terrain/` or `data/config/terrain_playground.json`.
- **No Meshy generation was spent and no asset was added.** The barricade's material is
  built from `assets/buildings/quaternius_medieval`'s already-installed `T_WoodTrim_*`
  maps; nothing new was imported.

## Against the brief's acceptance criterion

> *A fresh blind judge, given the same four questions the landing judge asked, confirms
> the barricade and guard-colour "do not ship" verdicts are resolved. Bridge banner
> consistency is either fixed or explicitly routed further with a clear reason. The
> signpost item is either fixed (if a material-level fix) or explicitly left as a
> Bucket-B art gap with the check that justifies that call.*

- **Barricade and guard colour — met, and by two independent blind rounds.** Round 1 ran
  the landing judge's own four questions unchanged and flipped the barricade-texture and
  signpost-lettering verdicts; round 2 ran a fresh critic with no memory of round 1 on the
  two items round 1 left open, and it flipped both: *"A is the better column, on all three
  counts, without qualification"*, with the barricade *"textured, in both rows"* at 8.8× the
  surface detail of `main`, *"they control passage"* through a measured 1.0–1.25 m gap in a
  2.3 m road (*"a person, comfortably… a wagon or a cart team, no"*), and the guard *"yes,
  unambiguously… a player reads that figure as wearing the livery."* Both verdicts are
  committed in full, `JUDGE.md` and `JUDGE2.md`.
- **The checkpoint as a whole is still DO NOT SHIP, and that is reported rather than
  buried.** Round 2's ship gate is three items — nothing in the game casts a shadow, the
  crossing can be walked around on the verge, and the grey blockout slab at the gate — none
  of which is in this lane's file list, and its own §5 table says so for each. They are
  routed above, first, and the shadow finding is the largest thing this lane surfaced.
- **Banner consistency** — explicitly routed, with the reason measured twice (the `.glb`'s
  own material list and the imported scene's), because there is no separable material to
  retint. See "Findings routed on".
- **Signpost** — split, with the check that justifies the split: the text is a `Label3D`,
  so contrast, weight and fit were reachable and were fixed (and a clipped destination
  name the judge quoted is now provably not clipped, under a test that fails without the
  fix); the 5–7 px cap height is a function of board size, which is the base mesh, and is
  left as a Bucket-B gap rather than attempted.

## Branch and commit

Branch `ralph/N09-BRIDGE-CHECKPOINT-0905`, pushed. Final commit: `fc12ac3e3` (this report's own hash-recording commit; the work is `f6313dc43`).
No pull request opened, per COMMON.
