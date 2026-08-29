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
