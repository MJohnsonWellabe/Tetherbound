# T1-CREATURE — Track 1 §15, creature presentation in world, 2026-08-29

Scope: `docs/owner-direction/TETHERBOUND_VISUAL_STUNNING_PASS.md` §15 (and its
overlap with §7's "readable habitat pockets" for Creek Hollow). Hard
constraint respected throughout: no new creature meshes, no Meshy
generations — every change below is data (a spawn centre) or tooling, never
a new asset.

## Godot was not installed in this session's container

Same gap `ralph/reports/T1-CASTLE_castle_2026-08-29.md` hit. Downloaded
Godot 4.7-stable (the version `ci.yml` pins) to `~/godot-bin`, ran
`godot --headless --path . --import` once before any capture, per
CLAUDE.md's own trap list.

## What was already done, verified rather than redone

§15 asks for legible silhouettes, habitat framing, water creatures reading
near shore, alphas catching the eye, and readable combat backgrounds. Before
touching anything, I read the git history for this exact area and found
substantial prior work already landed under the "catching sucks" lane
(commits `23368a70`, `634c5cde`, `0f1e82c8`, `2f3deedb`):

- Bramblebun (0.78m→0.96m) and Pipwing (0.60m→0.76m) were raised to clear
  `grass_field.json`'s own tallest tuft (0.86m), measured against a real
  frame rather than eyeballed.
- A per-species opt-in silhouette rim (`_apply_field_separation` in
  `creature_body.gd`, `placeholder.field_rim` in species.json) exists for any
  species that still needs it — controlled-A/B tested and found to be a
  measured no-op at the strengths that don't collide with an alpha's own
  identity tell, so it is currently off everywhere on purpose, not
  unimplemented.
- Alpha individuals already get a stronger rim, a slow idle-motes aura, and
  (where authored) a distinct `_alpha` colourway (`alpha_aura.gd`,
  `creature_body.gd::_apply_alpha_presence`); rendered and visually
  confirmed larger + weathered-looking against an ordinary individual
  (`shots/creature_presentation/burrowback_alpha_x1.30.png`,
  `galecrest_alpha_x1.40.png`).
- One open item from that lane, explicitly left for the owner and not
  re-litigated here: Bramblebun still measures 1.08:1 luminance against the
  field at 0.96m (a colour problem, not a size problem), and the two levers
  that would fix it — a repainted colourway or a stronger rim once an
  alpha's own tell is re-differentiated — are both flagged as owner
  decisions in `2f3deedb`'s own commit message.

Re-rendering the whole roster against a grass-matched card
(`tools/capture_creature_presentation.gd`, already in the repo) confirmed
the roster reads with distinct silhouettes and colours at gameplay distance;
`_portraits.png`/`_field_thumbs.png` are the existing contact sheets. Nothing
here needed touching.

## What was genuinely unclaimed: habitat framing

`data/config/bands/band1_lower_meadows/spawns.json` carries a `habitat` tag
(`creek_edge`, `rock_overhang`, `water_edge`, `open_basin`, `rocky_shoulder`,
`grove`, `far_water_edge`) on every Creek Hollow spawn — the file's own
comment says this is "presentation metadata for authoring/tests;
encounter_director.gd intentionally ignores it" and claims the existing
pond/mill/footbridge/reed-arc/grove dressing already delivers each tag's
promise. Nobody had rendered that claim.

Wrote `tools/_probe_creek_hollow_habitat.gd`: loads the real
`meadows_playground.tscn`, pins time to day, and shoots all seven
habitat-tagged clusters from a shore vantage. First version hand-picked one
eye offset per cluster and landed three of seven inside a rock, a wall, or a
tree trunk — Creek Hollow's whole point is dense rock/tree dressing, so a
blind offset has good odds of standing on the dressing itself. Rewrote it to
cast a ray from a ring of candidate eye positions toward each cluster centre
and keep whichever clears the most (the way a player's own camera collision
pushes back off a wall instead of clipping through it) — this is the
generally-useful part and is what stayed in the tool.

## The real finding: three water spawns stand on the lakebed, not the shore

The vantage-finder's own first pass exposed a second, more interesting
problem: for `creek_edge` and `rock_overhang` it preferred a *submerged*
camera, because an underwater sightline has nothing solid to hit and reports
huge "clearance" for free. That is a degenerate answer, not a useful one —
but it is also evidence. A direct probe against the live analytic
heightfield confirmed why:

| spawn (habitat) | terrain height | water.level | depth | body height | clears surface? |
|---|---|---|---|---|---|
| paddlenewt (creek_edge) | −20.32m | −17.0m | 3.32m under | 1.15m | no — 2.17m short |
| mosshell (rock_overhang) | −19.89m | −17.0m | 2.89m under | 1.40m | no — 1.49m short |
| brooktail (water_edge) | −18.77m | −17.0m | 1.77m under | 1.05m | no — 0.72m short |

All three sit on the actual lakebed, deeper than their own body height, so
none of them ever broke the surface. Rendered from a legitimate above-water
shore vantage (after adding a `WATER_LEVEL` floor to the vantage-finder so it
can no longer pick a submerged camera), all three read as an indistinct pale
smudge seen through the water rather than a visible creature — see
`shots/rock_overhang-BEFORE.png` next to `shots/rock_overhang-AFTER.png`.
This directly fails §15 ("water creatures read near shore") and the
acceptance standard's #11 ("creatures remain visually prominent in their
habitats"). It most likely dates to the OW5D pond relocation
(`terrain_playground.json`'s own comments already flag that pass's ground
truth at the new basin site was "NOT re-probed" for the stream and outlet;
this is the same class of gap for the spawn table).

**Fix**: grid-searched the live heightfield for the nearest point (clear of
any prop/building collision, checked by ray) where the lakebed sits close
enough to the surface for most of each species' body to clear it, and moved
each spawn centre there — 7m, 12m and 14m respectively, all still inside the
7-cluster hollow and inside `test_spawns_data.gd`'s own Creek Hollow bounding
box. Species, count, radius and habitat tag are unchanged; this is a depth
correction, not a re-authored encounter. `tests/test_spawns_data.gd` (19
tests, 1389 assertions) passes unchanged.

Re-rendered from the same shore vantage after the fix:

- **rock_overhang (mosshell)** — dramatic improvement. Shell, face and legs
  all clearly visible above the waterline, mill building readable in the
  background. `shots/rock_overhang-AFTER.png`.
- **water_edge (brooktail)** — now sitting visibly on a sandbar at the
  shoreline rather than as a submerged smudge. `shots/water_edge-AFTER.png`.
- **creek_edge (paddlenewt)** — the shore vantage itself is a genuinely
  attractive frame (footbridge, mill, far shore), but neither of the two
  scattered individuals happened to be in this particular frame — the centre
  fix corrects the depth at the cluster's middle, not the whole 14m scatter
  disc, so an individual that lands near the disc's outer edge can still be
  in deeper water. Left as a residual: the systemic defect (centre point
  underwater) is fixed and verified elsewhere in the same cluster set;
  whether the full scatter disc needs a smaller radius or a per-point depth
  clamp is a smaller follow-up, not blocking.

## What was NOT done, and why

Considered clamping a water-type creature's stand height to the water
surface in `creature_body.gd` (a general fix that would also help in
combat) instead of moving spawn centres. Did not: that function is shared
by every creature in every context including live combat, changing it risks
combat hit-box/positioning behaviour for water species, and it is a bigger,
riskier change than this task's evidence justified when the data-only fix
(move the centre) was available, tested green, and directly verified by
render. Left as a note for whoever next touches water-creature movement,
not implemented speculatively here.

`open_basin`, `rocky_shoulder`, `grove` and `far_water_edge` were also
rendered; none showed the underwater defect (all sit well above
`water.level`), but the vantage-finder's blind bearing search landed a few
of them inside tree cover rather than in the open the habitat tag implies.
That is a sampling artefact of a single automated frame per point, not
confirmed evidence of a real problem — a real player's fixed approach path
may see these areas quite differently. Not chased further this session.

## Evidence

`ralph/reports/T1-CREATURE/shots/` (carried in-repo; `/shots/` at the repo
root is gitignored per its own comment about exactly this class of loss):

- `rock_overhang-BEFORE.png` / `rock_overhang-AFTER.png` — the clearest
  before/after pair, same shore vantage, only the spawn centre moved.
- `creek_edge-AFTER.png`, `water_edge-AFTER.png` — the other two fixed
  clusters, post-fix.

`shots/creature_presentation/` (working captures, not carried — regenerate
with `tools/capture_creature_presentation.gd` and
`tools/_probe_creek_hollow_habitat.gd` as needed).

---

## Session 2: the Warrens Guardian's lost silhouette

Fable's blind pass (`ralph/reports/JUDGE-VISUAL-2026-08-29.md` sec4,
`ralph/JUDGE-VISUAL`) called the Warrens den interior GOOD overall — the one
architecture verdict in the world that passed, protect it — but logged one
watch item, squarely §15:

> The guardian's dark shell merges into the shadowed back wall
> (`W-int-01-den-wide.png`) — its silhouette is nearly lost at the exact
> moment the room wants you to see it. A rim of warmer bounce or a lighter
> back wall behind the den would protect the read.

### Root cause

`data/config/burrow_warrens.json`'s den already carries a warm key light
(`{"at":[3.0,43.0],"y":3.1,"energy":1.5,"range":13.0,"colour":"#d9a05c"}`)
sited right alongside the guardian's own stand (den centre `[0,40]` +
guardian `offset:[3,4]` = `[3,44]`) — a broad wash chosen deliberately over a
tight spotlight because the guardian is a wandering wild body
(`_comment_lights_authored`'s own round-1 lesson). That light lights the
guardian's *near* side but leaves the wall directly behind it — and
therefore the guardian's silhouette against that wall — exactly as dark as
the rest of the room.

### Fix

One more data-only light, no `.gd` changes: `burrow_warrens.gd::_build_lights`
is already fully generic over the `lights` array, so this is a single JSON
entry, `{"at":[3.0,46.0],"y":1.8,"energy":0.55,"range":6.0,"colour":"#c9814a"}`
— sited just short of the den's far wall (depth 14 centred on z=40 puts the
wall at z≈47) and at the guardian's own body height rather than ceiling
height (the exact mistake round 1 of the key light made — "the frames
showed it lighting the CEILING while the guardian went to silhouette"), so
it backlights the silhouette and lifts the wall value at the same time,
without needing to track the guardian's 1.5m wander on a leash. Warm but a
shade duskier than the key so it reads as bounce, not a second sun.
`interior_structure.gd` and `burrow_warrens.gd` are both untouched.

### Verification

Rendered with the judge's own tool/stand
(`tools/capture_warrens_63.gd`'s `06-den-and-guardian`, `aim_guardian: true`).
The guardian is a live wandering wild body with an unseeded wander target
(`_comment_vault_trailpup_wander` already documents this for a different
resident), so the resulting camera angle is not pixel-identical to the
judge's own capture instant — the full frame shows a different facing, not
the same composition. Judging the silhouette-vs-wall read on its own merits
instead, cropped to the guardian at comparable scale in each:

- `guardian-den-BEFORE-full.png` / `guardian-silhouette-BEFORE-crop.png` —
  the judge's own frame. The wall behind the guardian is nearly the same
  dark value as the guardian's own shadowed underside; only the moss
  highlights separate at all.
- `guardian-den-AFTER-full.png` / `guardian-silhouette-AFTER-crop.png` —
  this fix, same tool/stand. The wall behind the guardian is visibly
  lighter and warmer, with legible stone-joint texture, giving real value
  separation around the whole silhouette edge; the white muzzle/chest patch
  reads clearly against it.

Per conventions.md, this lane does not grade its own fix — before/after
evidence above is ready to route back to the independent judge.

---

## Session 2 continued: sampling Band 2 for the same class of defect

Coordinator's hypothesis: bands 2 and 4 carry the most vegetation and the
most rock, so a creature silhouette is most likely to fail there the way
Creek Hollow's water creatures failed against the pond. Band 2/4's own
`spawns.json` carry no `habitat` tag and no water species at all (every
entry is Ground/Air: trailpup, burrowback, meadowhart, duskhush, mudsnout,
galecrest, pipwing), so the exact "standing below the water line" defect
class does not apply there by construction — there is nothing to
depth-check. All species heights were already confirmed clear of
`grass_field.json`'s tallest tuft in session 1's table above.

That leaves rock-background silhouette contrast as the open question. Wrote
`tools/_probe_band2_rock_silhouette.gd` (same clear-vantage instrument,
generalised past Creek Hollow) and sampled the two Band 2 spawns nearest The
Old Quarry's worked rock face (`map_landmarks.json` centre ~[400,1800]):
order 2029 (burrowback, 45m out) and order 2027 (burrowback, ~215m out, the
next-nearest).

**No defect found at either sampled point** — `band2-quarry-near-2029.png`,
`band2-quarry-near-2027.png`. Both burrowbacks read with strong contrast:
dark grey/black bodies with a white face patch, clearly separated against
open hillside grass and tree trunks. Neither spawn actually stands on the
quarry's own rock terrain — that dressing is localised to the quarry's exact
working-face props (`data/config/bands/band2_stone_and_root/props.json`'s
`quarry_station` cluster), not the surrounding hillside the nearby wild
spawns occupy. The "band 2 is rock-heavy so creatures fail there" hypothesis
does not hold at these two points; a two-point sample does not clear the
whole band (55 spawn clusters), but it does not support spending more
render budget chasing this specific theory without a more specific lead.
Band 4 was not sampled this session — no comparable "nearest landmark"
anchor was identified for it in the time available.
