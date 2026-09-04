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

**Fix:** `scripts/world/south_bridge.gd` now overrides `_build_extras()` to build a
checkpoint gatehouse standing over the existing gate leaf (never a child of the leaf
itself, so it does not swing when the gate opens): two timber posts flanking the deck,
a lintel across them, and two hanging cloth banners — the same compass-sigil device
(`tether_sigil.gd`) and cloth shader (`banner_cloth.gdshader`) `road_gate.gd`'s own Sigil
Gate already uses for the identical finding (T1-HALL-3, JUDGE-5 D4: *"no sigil, no banner,
no gatehouse, no Team Tether mark of any kind"*), reused rather than reinvented. Built at
this bridge's own human scale (posts 2.5m, banners 1.7m) rather than the Sigil Gate's
6.2m causeway-pier scale, which would read as a fortress dropped on a footbridge. Verified
structurally with a throwaway probe (not committed) before rendering: 2 posts, 1 lintel,
2 banners, each carrying cloth + the shared device + two tails.

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

**Fix:** all five now share the inn's already-approved `#8a5a3a`, so the settlement's "one
roof family" (bible §12) is one COLOUR, not four buildings on a vendor default and one
tuned outlier. Checked against both oxblood tones live in the game (`#6b2a20` — road_gate.gd's
checkpoint cloth, `#7a2430` — the stronghold's own Banner retint): `#8a5a3a` is warmer,
lighter and more orange, with no plausible read as a faction mark.

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

[Filled in after the render/judge pass below — see the run log for the capture tool and
`_sheet_g3band1_route.png` for the contact sheet.]

---

## 9. What could not be verified

- The re-render in this report uses a FREE camera at each stand's recorded position/heading
  (`tools/gate_f/derive_gate2_route_captures.py`'s own generated step-script,
  `ralph/reports/GATE2-EVIDENCE-0903/run/G2C.json`, and its shot manifest, both committed —
  the raw telemetry the tool itself reads is git-ignored payload and is gone from this
  checkout), with the HUD off and the CameraRig disabled — the same free-camera pattern
  `tools/survey.gd` and this project's other `tools/_capture_*.gd` tools already use. This
  is an honest world-content comparison at the same positions and headings, not a
  reproduction of the original third-person gameplay-camera framing (which needs the rig
  itself, running, following a real player body) or of the HUD (a different lane's file).
  Anything the original judge said specifically ABOUT the HUD is out of scope for this
  report's own after-frames.
- The recorded `yaw_deg` in `G2C.json` is a constant -49° for every S04 stand and a constant
  0° for every S05 stand. That is very likely a real recorded heading for long straight
  stretches of a fairly straight corridor rather than a derivation bug, but it was not
  possible to confirm against the original route.csv (gone, gitignored), so it is used
  as-is rather than re-guessed.
