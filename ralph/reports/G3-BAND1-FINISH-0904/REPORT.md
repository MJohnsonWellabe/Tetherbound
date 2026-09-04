# G3-BAND1-FINISH-0904 — closing Gate 2's residual half

**Lane:** `ralph/G3-BAND1-FINISH-0904`, branched from `ralph/G3-LAND-0904`.
**Why this lane exists:** `ralph/reports/GATE2-EVIDENCE-0903/REPORT.md` §6 found that Gate
2's blind-judge acceptance names residual gaps — props, fence, signposts, water, terrain —
that none of tasks 2.2–2.7 (vegetation, creature, night work) could ever move. This lane
owns that residual band: the South Bridge itself, the oxblood reservation, 2.13's list, a
Band 1 roster decision on the direct route, and tree scale where reachable outside
`vegetation.json`.

---

## 0. Verdict

Five of the residual items are fixed, in files this lane owns, with no new mesh. Two —
tree scale/trunk proportion and the terrain "dome hill" — are blocked by the `vegetation.json`
/`terrain_playground.json` freshness-guarded freeze this lane was explicitly told never to
touch; both are written up as exact proposed diffs below, not applied. One item (mill
sails) turned out to be a mis-statement of the actual gap once inspected, and is corrected
in the gap list rather than "fixed" by reopening a closed design decision (D24: no
windmill).

See §8 for the blind judge's verdict on the after state, on the same sixteen stands
`GATE2-EVIDENCE-0903`'s own judge used.

---

## 1. The South Bridge (highest-priority item)

**Before** (`ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md` §3, standing on the crossing
itself, `G2-S05-0755-objective`): *"a bare plank frame, half off-corner, no gate, no
banner, no guard, for the chapter's first physical gate and the thing Team Tether is
supposed to be holding."*

**What was there:** `gated_crossing.gd`'s gate leaf (`south_bridge_gate`,
`building_prefabs.json`) is the same unpainted `Prop_WoodenFence_*` two-course panel every
ordinary field fence in the game stands on. Nothing about it, or the span around it, said
a faction held this crossing.

**Fix, round 1:** `scripts/world/south_bridge.gd` now overrides `_build_extras()` to build a
checkpoint gatehouse standing over the existing gate leaf (never a child of the leaf
itself, so it does not swing when the gate opens): two timber posts flanking the deck, a
lintel across them, and two hanging banners. Verified structurally with a throwaway probe
(not committed) before rendering: 2 posts, 1 lintel, 2 banners.

**Round 1's render found two real defects, both from a blind pass, both fixed:**

1. **Posts intersected the deck's own permanent parapet rail.** The first cut spaced the
   posts off the gate leaf's own width, which put them close enough to the ALWAYS-THERE
   17.2m parapet rail (`south_bridge` prefab) to visibly pass through it. Fixed by spacing
   the posts at the parapet rail's own z line instead (`ARCH_HALF_Z := 0.95`) and offsetting
   the whole archway 0.5m further toward the village than the gate leaf (`ARCH_X_OFFSET`),
   so it clears both the rail and the leaf's own picket geometry instead of straddling
   either.
2. **The banners read as "flat vertical slabs... no cloth shape, no hanging rod, no hem, no
   taper, no fold."** The first cut copied `road_gate.gd::_hang_sigil_banner`'s own
   construction (a rigid `BoxMesh` panel plus two rigid tail boxes) — which is the SAME
   "reads as a laminated sign" defect JUDGE-6 found on the Meadows Hall's own banners before
   `stronghold.gd::_hang_banner` replaced it with one subdivided plane wearing
   `banner_cloth.gdshader` (a real per-vertex sway, the swallowtail notch, the selvage and
   the hem baked into the shader). That shader lives under
   `assets/environment/team_tether/hall/` but is generic, not Hall-specific, so round 2 of
   this fix reuses it directly rather than re-implementing rigid boxes a second time at a
   second scale. A follow-up blind pass on the round-2 render: *"three bright red banners
   (hue 6.3°, sat 67%)... carrying a white circular emblem, hung under a dark timber arch
   over the only bridge. Red-plus-emblem-over-a-choke-point does read as 'somebody has
   claimed this.'"*

Same compass-sigil device (`tether_sigil.gd`) `road_gate.gd`'s own Sigil Gate already uses
for the identical original finding (T1-HALL-3, JUDGE-5 D4: *"no sigil, no banner, no
gatehouse, no Team Tether mark of any kind"*) — reused rather than reinvented, at this
bridge's own human scale (posts 2.5m, banners 1.55m) rather than the Sigil Gate's 6.2m
causeway-pier scale, which would read as a fortress dropped on a footbridge.

**What the round-2 blind pass still names as open, honestly recorded rather than glossed
over:** the same pass found the archway itself "completely open... nothing spans the road,"
i.e. the gate leaf `gated_crossing.gd` already builds did not read as a clear barrier from
that particular recorded camera stand — the mechanism is real (the leaf and its lock are
unchanged, still the thing `_on_tried()`/`item_gate.gd` gate) but the leaf sits far enough
past the new archway, and dark enough against the archway's own shadow, that a viewer at
this one angle does not immediately see it as "something blocking the road". The same pass
found the one Team Tether grunt genuinely in frame but distant, off the road, and carrying
no faction colour of his own — his position and uniform are `trainers.json`
(`south_bridge_grunt`), not a file this lane owns. Both are named here rather than chased
further: this lane's mandate was gate, banner and guard PRESENCE (all three now exist and
render), not a full restage of the checkpoint's blocking silhouette or the grunt's own
costume.

**Owns:** `scripts/world/south_bridge.gd` only. No change to `gated_crossing.gd` (shared
with the Old Mill Crossing, band 3, out of scope) or to `building_prefabs.json`'s gate/span
recipes.

---

## 2. The oxblood reservation

**Before** (JUDGE.md §2, §8.1 item 3): *"the reddest objects in this world are the village
roofs ... and the tree trunks ... Meanwhile the Team Tether grunt in `G2-S05-0755-objective`
wears near-black with no red at all — the one hostile element in sixteen frames carries none
of the faction's oxblood, while forests and friendly houses carry it everywhere."*

**What was there:** `building_prefabs.json`'s `inn` prefab was the ONLY settlement building
with a `MI_RoundTiles` (roof) retint (`#8a5a3a`, a muted terracotta approved by an earlier
lane, R7.9/HIST-164). `workshop`, `cottage_a`, `cottage_b`, `farmhouse_shell` and the `mill`
had none at all, so their `Roof_RoundTiles_*` modules exported at the kit's raw, more
saturated default — the most visible roofs in the square (the workshop is the largest
building on it; Grandpa's own farmhouse is the first roof the player ever sees) reading
redder than the one Team Tether grunt in the whole route.

**Fix, round 1:** all five now share the inn's already-approved `#8a5a3a`, so the
settlement's "one roof family" (bible §12) is one COLOUR, not four buildings on a vendor
default and one tuned outlier.

**Round 1 was not enough, and a fresh blind pass on that render proved it, still measuring
this roof at essentially the game's own reserved-oxblood hue.** Root cause, found by
sampling `assets/buildings/quaternius_medieval/T_RoundTiles_BaseColor.png` directly:
`building_prefabs.gd::_apply_retint`'s `color` key MULTIPLIES the existing texture rather
than replacing it, and that texture's own baked hue is a near-invariant ~5–17° (measured:
whole-texture average, darkest 5% and brightest 5% of texels all land inside that band) at
0.7+ saturation — a plain colour multiply cannot move a result's hue far from a base this
saturated, whatever the tint is, because a multiply can only scale channels down, never
inject a ratio the base does not already carry enough of.

**Fix, round 2:** also swap the texture, via `_apply_retint`'s existing texture-swap key
(the same mechanism the settlement's authored trees already use to move off a texture no
multiply could reach), to `T_RockTrim_BaseColor.png` — an already-vendored, nearly neutral
warm grey in the SAME kit (measured saturation 0.145). Against a near-neutral base, the
colour multiply becomes the actual film that determines the final hue. New value `#8a6448`.
Measured on the re-rendered frames (`G2-S04-0400-dialogue.png`, direct pixel sampling of
the roof region): **hue 29°, saturation 0.42** — against the banner's own measured **hue
14°, saturation 0.74** at the South Bridge checkpoint (§1) in the same render batch. A
fresh blind pass confirms the separation: *"measured, the village roof is not more
saturated than anything nearby... it is the reddest by hue [before this fix]... push toward
terracotta/ochre, hue 18–25°, and it stops competing"* — which is what round 2 does. Same
tile GEOMETRY everywhere (`Roof_RoundTiles_*`, D24's one roof family); only the diffuse
film moved.

**Not fixed, out of ownership:** the grunt's own clothing colour (`trainers.json`, not
listed as this lane's) and the friendly HUD icon half of the same finding (`scripts/ui/**`,
explicitly G3-HUD's). The South Bridge checkpoint above puts a second, architectural oxblood
presence into the world regardless of whether the grunt's own palette moves.

---

## 3. 2.13 — props, fence and signposts

**Bridge-approach fence** (props.json's own `bridge_approach_fence`, `order: 1051`). The
original four panels sat 19.98m / 19.98m / 21.7m apart — checked by direct coordinate
distance, not eyeballed — against a ~2m panel width each: four isolated fence posts, not a
fence LINE, which is exactly what an observer without this file's own `_why` (an
intentionally-broken old field fence) would read as orphaned. Five linearly-interpolated
panels close the two intact runs (before and after the already-toppled third panel) to
~6-7m spacing; the run leading INTO the toppled panel keeps the widest remaining gap on
purpose, since that is the stretch meant to read as rotted away. Same three already-vendored
fence module variants, alternated, no new prop family.

**Signposts as bare posts.** `scripts/world/signpost.gd::build()` now calls a new
`_build_base_dressing()` after the post's own collision is built: a loose ring of six small,
irregularly-sized stone blocks around the post's foot, jittered from a hash of the post's own
world position (deterministic — a re-render never shows the stones rearranged). This is
every signpost in the game, junction and trailhead alike, since they all go through this one
file.

**Terrain "dome hill" at the village approach and the tree-layout item.** Both are
`terrain_playground.json`/`vegetation.json` — see §5, not touched, proposed only.

**Water shading.** Not touched. See §6 — this is a documented, converged ceiling
(`data/config/water.json`'s own `_comment_round1`–`_comment_rounds5_8`), not a live defect;
re-opening tuning that eight blind rounds already converged on, for a complaint that is a
single far-distance framing artefact, would be more likely to regress it than improve it.

---

## 4. Tree scale and trunk proportion — proposed diff, not applied

**Before** (JUDGE.md §8): trees measuring only ~2.3× the 1.80m trainer (≈4-4.5m) on
"redwood-thick" trunks, with "no visible branch structure below the canopy" on the
`CommonTree_*` family used along the corridor.

**Where it lives:** `data/config/vegetation.json`'s `layers.trees` block —
`models: [CommonTree_1, CommonTree_2, CommonTree_3]`, `scale_min: 0.5`, `scale_max: 1.45`.
This is squarely a `vegetation.json` value, and this lane was told, twice, never to touch
that file (a single `_comment` change fails its freshness guard for every other lane on the
coordinator's branch).

**Proposed diff (not applied):**

```diff
-    "scale_min": 0.5,
-    "scale_max": 1.45,
+    "scale_min": 2.2,
+    "scale_max": 4.0,
```

Reasoning: the judge's ask is 12-18m against the 1.80m trainer; the current range's top
(1.45) is what produces the measured ~4-4.5m trees, so the range needs to move by roughly
the same factor the height gap implies (~3-4x), not be nudged. The exact multiplier should
be checked against `tools/measure_models.gd`'s real native mesh height for
`CommonTree_1/2/3` rather than taken from this arithmetic alone — this lane did not run
that tool, to avoid opening the config file it reads into for anything more than a diff on
paper. Per CLAUDE.md, this is a "grow the smaller side" fix — the trainer does not move.

The trunk-diameter-vs-height complaint ("a redwood stump, not a 4-metre tree") is very
likely a symptom of the current undersizing rather than a second, independent mesh defect:
the same mesh scaled to its correct height should not carry the same trunk-to-canopy ratio
complaint a tree a third that size does, since a real tree's trunk reads as proportion,
not absolute width. That is a claim to VERIFY once the scale itself moves, not a second fix
to make blind.

The judge's separate "scatter reads as a rule" finding (twelve identical evenly-spaced
trees, a one-mesh tree wall with no mouth) is `vegetation.json`'s own
`corridor_bands`/clearings authoring and is equally out of reach here — recorded, not
diffed, since it is a placement question this lane's own brief says to write up and stop on
rather than guess a specific clearing layout for.

---

## 5. The terrain "dome hill" — not touched

`terrain_playground.json` is the second file this lane was told never to touch. The smooth
primitive dome the judge named at the village approach is that file's own heightfield
authoring; no diff is proposed here because this lane did not locate the specific field
responsible without opening the file for more than a read, and a guessed diff against a
freshness-guarded terrain bake is worse than none. Flagged for the coordinator to route to
whichever lane does own that file next.

---

## 6. What was investigated and found already correct

- **The mill's "add sails" note.** `building_prefabs.json`'s `mill` prefab is a working
  WATER mill (a real turning wheel built from seven fence-picket paddles at r=1.75m, an
  axle, three courses of the settlement's own kit) — a deliberate choice recorded in
  `village.json`'s own comment: *"The TowerWindmill is gone, not replaced... a mismatched
  second-family landmark is exactly the split-the-difference failure D24 closed."* Adding
  sails would re-open that closed decision. `docs/VISUAL_BIBLE.md` §4a corrects the ask to
  what is actually open (wheel legibility at route distance), rather than shipping sails
  against a standing decision.
- **Water shading.** `data/config/water.json` carries eight blind-judged rounds, converged,
  with an explicit recorded ceiling (no reflections — bible §15 rules out the expensive
  tier, and the Compatibility renderer has no SSR). The evidence run's complaint is the pond
  seen once, at extreme distance, in the background of one frame — not a shading defect this
  file's converged values should be re-opened for.

---

## 7. Roster decision on the direct Band 1 route (2.12)

**Before:** Gate 2.5's own acceptance asks for "at least one roster decision in play" on
the direct route; `GATE2-EVIDENCE-0903`'s played route (tournament → Lower Meadows → South
Bridge, no detour taken) produced mid-fight rotation but no catch and no keep-or-release
moment.

**What was there:** Band 1 already has two authored "temptation" creatures
(`data/config/bands/band1_lower_meadows/spawns.json`, both test-pinned by
`tests/test_spawns_data.gd::test_band1_clears_the_roster_temptation_floor`) — the Meadowhart
herd at the bridge approach (order 1005) and the elder Mosshell at the Pond (order 1900).
Both were sited, on purpose, 40m and 75m off the corridor spine respectively: their own
`_why_d1` entries are explicit that finding either one is meant to cost a real detour. The
played route, walked straight, met neither — which is those sitings working exactly as an
earlier lane (BAND1-D1, BAND1-ECOLOGY-0903/PW2) authored them to.

**Fix:** order 1005 (the Meadowhart pair) is moved along the same perpendicular from the
same nearest route point, 40m → 12m off centreline — the disc (radius unchanged at 22m) now
reaches from -10m to +34m of the route, so part of the herd's own scatter draw can land ON
the walkable line a player actually takes, rather than requiring a deliberate side-trip.
Order 1900 (the elder Mosshell) is untouched — it stays the region's deliberately
curiosity-gated temptation, and the coordinator's brief for this item only asked for the
DIRECT route to meet one, not for every authored temptation to stop costing a detour.

**Owns:** `data/config/bands/band1_lower_meadows/spawns.json` only. Species, count, radius
and level band untouched; `tests/test_spawns_data.gd`'s own assertions (species identity,
`order` key, the `elder` block on 1900) are unaffected by a centre-coordinate change.

---

## 8. Blind judge, same stands, after this pass

Four blind passes were run on this lane's own re-renders as the gatehouse and roof fixes
went through rounds. All four used `.claude/skills/visual-judge/SKILL.md`'s full protocol —
a fresh sub-agent each time, no knowledge of what changed, no knowledge of any earlier
pass's findings, `_sheet_g3band1_route.png` plus all 15 individual frames plus
`docs/reference/`. The fourth (asked two direct measurement questions, on the render with
both the roof texture-swap and the gatehouse's real cloth banners) is the standing verdict
this section reports in full; the earlier three are summarised as the rounds that got there.

**Both bar questions: no**, same as `GATE2-EVIDENCE-0903`, on all four passes. This is
expected and does not mean this lane's fixes did nothing — the judge's own headline finding,
every round, is that **no creature appears in any of the fifteen frames**, which by itself
is enough to fail Bar B regardless of anything else in the scene, and is content this lane's
file ownership cannot supply. Round 4, verbatim: *"there is no creature in this game...
Fifteen frames of a creature-training game contain zero creatures... Whatever else is true
below, a stranger shown these fifteen frames would not guess this game has creatures in it
at all."* What the four rounds show is this lane's own items moving from "not fixed" to
"fixed" to "confirmed fixed by direct measurement", read off the same instrument each time,
against a bar question this lane was never going to move alone.

**The South Bridge, round by round:**

- Round 1 (rigid-box banners, posts spaced off the leaf): the render itself was defective —
  a first capture-tool cut put the camera at first-person eye height with no pushout, and
  four of fifteen frames (including this exact stand) were substantially or entirely inside
  geometry. Re-shot after fixing the capture tool (§9), the same round's banners read as
  *"flat vertical slabs... no cloth shape, no hanging rod, no hem, no taper, no fold... read
  as painted door jambs,"* and the posts visibly intersected the deck's own parapet rail.
- Round 2 (real `banner_cloth.gdshader` cloth, posts repositioned to the parapet rail's own
  line): *"three bright red banners (hue 6.3°, sat 67%)... carrying a white circular emblem,
  hung under a dark timber arch over the only bridge. Red-plus-emblem-over-a-choke-point
  does read as 'somebody has claimed this.'"* The intersection defect was gone. Still named:
  *"There is no gate. The arch is completely open. Nothing spans the road... A structure
  called a checkpoint that you can walk straight through is a decoration, not a barrier,"*
  and the one guard in frame *"stands roughly 15-20m away and uphill... not facing the
  road... carries no faction colour and no weapon."*
- Round 3 (same geometry as round 2, plus the roof fix): confirmed the checkpoint reads as
  manned/held ("half" — the banners and the guard's mere presence carry it, the open
  archway does not) and confirmed the roof/banner colour separation directly.
- Round 4 (asked the same two questions again, with its own fresh measurements): confirmed
  round 2/3's finding independently — *"No physical barrier spans the road. The archway is
  open"* — and traced it precisely: the ordinary pasture fence crossing the deck *"has no
  leaf, no hinge, no post-and-bar closure... it is farm fence that happens to be in the way,
  not a barricade,"* while `gated_crossing.gd`'s own gate leaf (unchanged by this lane) sits
  further back and was not what the judge's crop found in the archway's opening. Scored the
  checkpoint *"about 30% of the way"* to reading as held: present and counted — the arch, the
  banners, the sigil, one guard; absent — a guard actually posted under the arch, any colour
  link between the guard and the banners, a second guard, and any camp dressing (brazier,
  crates, a barricade). New, useful, and acted on immediately: *"the banners are too bright
  for the brief"* — measured at hue 5-12°/sat 65-79%/value 56-61%, against the SAME judge's
  own direct sample of the key art's stronghold banners at hue 9°/sat 60%/**value 39%**. This
  lane's own `FACTION_CLOTH` constant (`scripts/world/south_bridge.gd`) was `#6b2a20`
  (road_gate.gd's own established checkpoint colour, itself close to the target as a flat
  value) — but `banner_cloth.gdshader`'s fold shading and this sun angle rendered it visibly
  brighter than the reference through that shader. Round 3.5 (not separately judged, verified
  by this lane's own direct pixel sampling instead, to avoid a fifth full render+judge cycle
  for one constant): `FACTION_CLOTH` set to `#633128`, the key art's own measured value
  directly. Re-rendered and re-sampled: hue 18°/sat 0.68/**value 0.43** — value moved from
  ~0.56-0.61 down to 0.43, materially closer to the 0.39 target, while staying clearly
  distinguishable as red. This is the render committed with this report.

**Net effect:** the exact three things `GATE2-EVIDENCE-0903` named — *"no gate, no banner,
no guard"* — are now *"no [spanning] gate, banner [present, now colour-tuned to the key
art's own reference], guard [present but distant/uncoloured]."* Two of three are
substantively answered; the third (a physical barrier that reads as spanning the road from
this one camera angle, and a guard sited/dressed to visibly belong to the checkpoint) is
named honestly as open in §1 rather than claimed fixed, because it is: the gate MECHANISM is
real and unchanged (the leaf, the lock, `item_gate.gd`'s check — a player without the key
still cannot cross), but its silhouette from this specific recorded stand does not read as a
barrier, and the guard's own position/costume is `trainers.json`, a file this lane does not
own. Four independent blind passes agreeing on the same residual, by two different
methods (visual read, then a traced crop), is a real finding to hand to whichever lane picks
up checkpoint staging next — not one this lane is positioned to argue with.

**The oxblood reservation, round by round:**

- Round 1 (`#8a5a3a` colour multiply only, no texture swap) was rendered and judged
  TWICE inadvertently (the roof fix landed before the camera-clipping fix, so both the
  first and second blind passes saw it): *"the reddest objects in this world are the
  village roofs ... while the one Team Tether grunt wears unrelieved black"* (first pass,
  measuring hue ~6°/sat ~0.84 on the farmhouse roof); *"measured, the village roof is not
  more saturated than anything nearby [by casual look]... it is the reddest by hue [~11°]...
  five degrees from the Team Tether banner [~6°] — indistinguishable to the eye"* (second
  pass, more precise). Both independently converged on the same finding despite different
  sampling: hue proximity to the reserved oxblood, not raw saturation, is the actual defect.
- Round 2 (texture swap to `T_RockTrim_BaseColor.png` + `#8a6448`): this lane's own direct
  pixel sampling on the re-rendered frame measured roof hue 29°/sat 0.42 against the
  checkpoint banner's own hue 14°/sat 0.74 in the same batch — a ~15° hue separation and a
  materially lower saturation.
- Round 4 (asked to sample and compare the two directly, with no knowledge of rounds 1-3):
  *"Clearly different colours. Not close. The reservation is holding."* Its own fresh
  samples: roof (shadowed face) RGB (38,27,19), hue 25°, sat 50%, **value 15%**; roof
  (sunlit ridge) hue 29°, sat 31%, value 44%; banner (left) hue 12°, sat 65%, value 56%;
  banner (right) hue 5°, sat 79%, value 61%. Separation on the closest comparison (sunlit
  roof vs. the less-saturated banner): 24° of hue, 48 points of saturation, 17 points of
  value. *"The roof is a dark desaturated umber-brown shingle... The banner is a bright
  scarlet. No viewer would associate them, and no player would misread the village roofline
  as a Team Tether marker."* This item is closed, confirmed by an instrument with no
  knowledge of what changed, on its own independent measurement.

**What the judges named that is real, and belongs to other lanes or later work, not
buried here:** no creature at any size in any frame (content, not scene work, per the
skill's own split); the trainer's identical idle pose in all fifteen frames and his
brightness relative to shaded surroundings; a camera-inside-geometry frame at
`G2-S05-0271-route.png` that this lane's capture-tool fix (§9) reduced from four such
frames to (at last count) one, in a stand this lane does not own dressing for; trunk colour
and canopy-to-trunk mismatch (§4, blocked by the `vegetation.json` freeze); several small
prop-clipping artefacts (grass through the bench in `G2-S04-0206-dialogue.png`, a stray
placeholder cube under the bridge arch) that were named but are outside this pass's named
scope and are recorded here for whichever lane picks up general prop polish next.

---

## 9. What could not be verified

- The re-render in this report (`tools/_capture_g3band1_route_stands.gd`, committed) uses a
  FREE camera at each stand's recorded position/heading (from
  `tools/gate_f/derive_gate2_route_captures.py`'s own generated step-script,
  `ralph/reports/GATE2-EVIDENCE-0903/run/G2C.json`, and its shot manifest, both committed —
  the raw telemetry the tool itself reads is git-ignored payload and is gone from this
  checkout), HUD off, CameraRig disabled. Round 1 of this tool planted the camera exactly AT
  the recorded position at roughly eye height — effectively first-person — and a blind pass
  on that render found four of fifteen frames substantially or entirely the INSIDE of nearby
  geometry (a tree trunk; at the bridge stand, this lane's own new checkpoint post). Round 2
  reproduces `scripts/player/camera_rig.gd`'s own real third-person values instead (5.2m
  behind the recorded position, 1.75m above it) with a raycast pushout standing in for the
  real rig's SpringArm3D shapecast, which cleared all four. This is a closer reproduction of
  the real gameplay camera than round 1, but is still not the HUD (a different lane's file)
  — anything a judge says specifically ABOUT the HUD is out of scope for this report's own
  after-frames.
- The recorded `yaw_deg` in `G2C.json` is a constant -49° for every S04 stand and a constant
  0° for every S05 stand. That is very likely a real recorded heading for long straight
  stretches of a fairly straight corridor rather than a derivation bug, but it was not
  possible to confirm against the original route.csv (gone, gitignored), so it is used
  as-is rather than re-guessed.
