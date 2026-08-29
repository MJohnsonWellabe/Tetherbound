# Handover — T1-CREATURE (§15, creature presentation in world), 2026-08-29

Stand-down handover. Coordination tooling dropped out on the coordinator's
side; lanes are being stopped and restarted fresh. This is everything from
this lane that is not already obvious from the diff.

**Branch:** `ralph/T1-CREATURE`, pushed and matching `origin/ralph/T1-CREATURE`
at commit `72217e1d3ba708b51edf1cf3e515f7a50eac0959`. Working tree is clean —
nothing uncommitted, nothing unpushed. Merged `origin/main` (`961a8c02`) in
at `4b989218` partway through, so this branch is current against main, not
stale.

Commits, oldest to newest (the first two — `12123fdf`, and everything before
`5dda45b3` — predate this conversation's own context and were pushed in an
earlier turn of the same lane; listed here for completeness since a
successor needs the full picture, not just this session's slice):

```
12123fdf  T1-CREATURE (§15): add a Creek Hollow habitat-pocket probe
5dda45b3  T1-CREATURE (§15): fix vantage-finder parse errors, reject submerged eyes
523c6924  T1-CREATURE (§15): move Creek Hollow's three water spawns off the lakebed
4b989218  Merge origin/main (961a8c02) into ralph/T1-CREATURE
4699cd40  T1-CREATURE (§15): session report and before/after evidence
abc7ebaf  Warrens den: backlight the guardian's silhouette against the back wall
7b4b8491  T1-CREATURE: Warrens Guardian backlight verification evidence
72217e1d  T1-CREATURE: sample Band 2 for the rock-silhouette hypothesis (negative)
```

Full narrative write-up (more detail than this file, evidence tables, exact
depth numbers): `ralph/reports/T1-CREATURE_habitat_2026-08-29.md`. This
handover summarizes it and adds what that file does not cover.

---

## What I was asked to do

1. Original brief: Track 1 aesthetics lane, §15 "creature presentation in
   world" from `docs/owner-direction/TETHERBOUND_VISUAL_STUNNING_PASS.md` —
   grass hiding creatures, silhouette legibility, habitat framing, water
   creatures reading near shore, alphas catching the eye, readable combat
   backgrounds. No new creature meshes, no Meshy generations (hard
   constraint, respected throughout — every change below is JSON data or a
   dev tool script, never a new asset).
2. Mid-session, a coordinator message (routed through a scheduled trigger)
   redirected me: read `ralph/reports/JUDGE-VISUAL-2026-08-29.md` (Fable's
   blind visual-judge pass, branch `ralph/JUDGE-VISUAL`), fix the one watch
   item it raised against §15 (the Warrens Guardian's silhouette merging
   into the den's back wall), then continue §15 into bands 2/4 using the
   instrument built for Creek Hollow.

## Where I actually got to

### DONE and verified (render + test evidence in hand)

1. **Three Creek Hollow water spawns were standing on the lakebed, not the
   shore.** `data/config/bands/band1_lower_meadows/spawns.json` orders 6, 7,
   8 (paddlenewt/creek_edge, mosshell/rock_overhang, brooktail/water_edge)
   had terrain heights of −20.32m / −19.89m / −18.77m against
   `terrain_playground.json`'s `water.level` of −17.0m — 3.32m / 2.89m /
   1.77m underwater, all deeper than the species' own body height (1.15m /
   1.40m / 1.05m), so none of them ever broke the surface. From a legitimate
   shore vantage they rendered as an indistinct pale smudge, failing §15's
   "water creatures read near shore" outright.
   - **Measured with:** a one-off script printing
     `HEIGHTFIELD.load_config()` + `.height_at(x,z)` against each spawn
     centre, compared to `terrain_playground.json`'s `water.level`. (Script
     was in `/tmp`, not committed — trivial to re-write, ~15 lines, see the
     narrative report's own table for the exact numbers.)
   - **Fixed by:** grid-searching the live heightfield for the nearest point
     (ray-checked clear of prop/building collision) where the lakebed sits
     close enough to the surface for most of the body to clear it, and
     moving each spawn centre there (7m / 12m / 14m moves, all still inside
     the hollow's own bounding box). Species/count/radius/habitat tag
     unchanged — this is a depth correction, not a re-authored encounter.
   - **Test:** `godot --headless --path . --script tests/run_tests.gd --
     --only=test_spawns_data` → 19 tests, 1394 assertions, 0 failed (was
     1389 before the merge brought in unrelated new assertions elsewhere in
     the same file; still 0 failed either way).
   - **Rendered before/after:** `ralph/reports/T1-CREATURE/shots/
     rock_overhang-BEFORE.png` / `rock_overhang-AFTER.png` is the clearest
     pair — same shore vantage, only the spawn centre moved, mosshell goes
     from a barely-visible smudge to a fully readable creature above the
     surface. `creek_edge-AFTER.png` / `water_edge-AFTER.png` are the other
     two, post-fix.

2. **Warrens Guardian silhouette** (the judge's watch item). Added one
   shadowless `OmniLight3D` entry to `data/config/burrow_warrens.json`'s
   `lights` array (`burrow_warrens.gd::_build_lights` is already fully
   generic over that array — zero `.gd` changes), sited just short of the
   den's back wall at the guardian's own body height (not ceiling height —
   that specific mistake is already documented in this same file's own
   `_comment_lights_authored` history for a different light, and I made
   sure not to repeat it). Backlights the silhouette and lifts the wall
   value at the same time.
   - **Rendered with:** the judge's own tool, unmodified —
     `tools/capture_warrens_63.gd`'s `06-den-and-guardian` stand
     (`aim_guardian: true`).
   - **Caveat, important for whoever reviews this:** the guardian is a live
     wandering wild body with an *unseeded* wander target (this is already
     documented elsewhere in `burrow_warrens.json` for a different resident
     — `_comment_vault_trailpup_wander` says explicitly "never seeded, so a
     different roll every boot"). My after-frame's camera ended up at a
     visibly different facing than the judge's own before-frame — different
     wall in the foreground, doorway not in frame — because `aim_guardian`
     re-aims at wherever the guardian actually is when the shot fires, and
     that position is not reproducible run to run. **I did not get a
     pixel-identical before/after.** I cropped both frames to the guardian
     at comparable scale and judged the wall/body value separation on that
     basis instead — real, visible improvement (see
     `ralph/reports/T1-CREATURE/shots/guardian-silhouette-BEFORE-crop.png`
     vs `-AFTER-crop.png`) — but a successor or the judge re-rendering this
     stand should expect a different composition each time, not a mismatch
     between frames.
   - Per `ralph/conventions.md`'s "do not grade your own visual work" rule,
     I did not declare this fixed myself — evidence is packaged and named
     as ready to route back to Fable, but that routing had not happened
     before stand-down.

### Done but NOT independently verified

- The Warrens Guardian fix above: I am confident in it (the crop comparison
  is real and the reasoning is sound), but per this repo's own stated
  process it needs Fable's blind pass to actually confirm, and that pass
  has not run against my change. Treat it as "implemented and
  self-consistent," not "closed."

### Still open / not attempted

- **Creek Hollow's `creek_edge` (paddlenewt) individual read.** The centre
  fix corrects the depth at the cluster's *middle*; the species still
  scatters 2 individuals across a 14m-radius disc, and my after-render
  happened not to catch either individual in frame (the shore vantage
  itself looks great — footbridge, mill, far shore — just no creature in
  it). I don't know if this is bad luck in one render or a real residual
  (an individual landing near the disc's outer edge could still be in
  deeper water). **Next step:** either re-render a few times to sample the
  scatter, or consider shrinking the radius / adding a per-point depth
  clamp if it's real.
- **Band 2 rock-silhouette hypothesis: sampled, not resolved.** Coordinator
  suggested bands 2/4 (most rock, most vegetation) are where a creature
  silhouette is most likely to fail the way Creek Hollow's water spawns
  failed. I checked: bands 2/4's `spawns.json` carry no `habitat` tag and no
  water species at all — every entry is Ground/Air — so the *specific*
  underwater-depth defect class cannot occur there by construction, and all
  species heights were already confirmed clear of the tallest grass tuft
  (0.86m; only pipwing at 0.76m is short, and that's an already-reasoned,
  already-owner-flagged tradeoff from a prior lane, not new). That leaves
  rock-background contrast as the open question. I sampled exactly 2 of
  Band 2's 55 spawn clusters (the two nearest The Old Quarry's rock face —
  orders 2029 and 2027) with a generalised version of the Creek Hollow
  vantage-finder tool. **Both read fine** — strong contrast, neither spawn
  actually stands on the quarry's own worked-rock dressing (that's
  localised to specific props, not the surrounding hillside). This is a
  genuine negative result on 2 points, not a clearance of the hypothesis —
  53 more Band 2 clusters and all of Band 4 are unexamined. I stopped here
  because a 2-point sample already cost a full render cycle (~15 min) and I
  had no sharper lead (no equivalent of Creek Hollow's `habitat` tag or
  water-depth number to prioritise which of 100+ remaining points to check
  next) — continuing would have been diminishing-returns guessing, not
  targeted verification.
- **Band 4 was not touched at all.** No sampling, no reasoning beyond "same
  species-height table already covers it, same lack of habitat tags/water
  spawns applies." If it has a real silhouette problem, it is undiscovered.
- **The bramblebun colour problem** (pre-existing, not mine): Bramblebun
  still measures 1.08:1 luminance against the field even at its corrected
  0.96m height — a colour problem, not a size problem. A prior lane
  (`2f3deedb`, before this session) already flagged the two fixes that would
  work — a repainted colourway or a stronger silhouette rim once an alpha's
  own rim-tell is re-differentiated from an ordinary creature's — as owner
  decisions, not something to invent. I verified this is still the state of
  things and did not re-litigate or touch it.

---

## File footprint — everything I changed or touched this lane

**Data (gameplay-adjacent, reviewed carefully, tests still green):**
- `data/config/bands/band1_lower_meadows/spawns.json` — 3 spawn centres
  moved (paddlenewt/mosshell/brooktail), each with an inline
  `_comment_depth_0829` explaining the exact before/after numbers and why.
- `data/config/burrow_warrens.json` — 1 new entry in the `lights` array,
  plus an inline `_comment_guardian_backlight_0829` explaining it.

**Tooling (dev-only, not shipped in any build, all in `tools/`):**
- `tools/_probe_creek_hollow_habitat.gd` (+ `.uid`) — renders all 7
  habitat-tagged Creek Hollow spawn clusters from a raycast-verified clear
  shore vantage. Rewritten twice in earlier turns of this lane (see its own
  header comments): v1 hand-picked eye offsets and landed 3 of 7 inside a
  rock/wall/tree; v2 added the ray-cast vantage-finder; a `WATER_LEVEL`
  floor was added after v2's own vantage-finder was found to prefer
  submerged cameras (nothing solid to hit underwater, so "clearance" was
  gamed for free). **This is the reusable instrument** — if picking up
  bands 2/4, start here rather than writing a new one. Supports
  `OS.get_cmdline_user_args()` filtering (pass habitat tags after `--` to
  render a subset).
- `tools/_probe_band2_rock_silhouette.gd` (+ `.uid`) — same vantage-finder,
  generalised to arbitrary `[tag, centre, radius]` points instead of the
  Creek Hollow-specific cluster list. This is the one to extend for further
  band 2/4 sampling — just add more points to its `POINTS` constant.

**Reports (documentation, no gameplay effect):**
- `ralph/reports/T1-CREATURE_habitat_2026-08-29.md` — the full narrative,
  written incrementally across both sessions of this lane. Read this first;
  it has the exact numbers this handover only summarizes.
- `ralph/reports/T1-CREATURE/shots/*.png` — 11 files, before/after evidence,
  carried here specifically because repo-root `/shots/` is gitignored (its
  own comment says why — exactly this class of evidence loss).
- `ralph/reports/handover-T1-CREATURE-2026-08-29.md` — this file.

**Nothing else was touched.** I did not touch `interior_structure.gd`,
`burrow_warrens.gd`, `creature_body.gd`, `encounter_director.gd`, or any
other shared/load-bearing script, on purpose — see "what I considered and
did not do" below.

---

## What I considered and deliberately did NOT do

- **Clamping a water-type creature's stand height to the water surface in
  `creature_body.gd`** instead of moving spawn centres. This function is
  shared by every creature in every context including live combat. Changing
  it risks combat hit-box/positioning behaviour for every water species
  everywhere, not just these three spawns, and it's a bigger, riskier change
  than the evidence justified when the data-only fix (move the centre) was
  available, tested green, and directly render-verified. Left as a note for
  whoever next touches water-creature movement generally — this is a
  *systemic* lever that would help more broadly (any future water spawn
  near a steep lakebed has the same failure mode), but I did not want to
  make a shared-code behavioural change on a single lane's evidence.
- **Repainting Bramblebun's colourway** to fix its still-poor grass contrast.
  A prior lane already flagged this as an owner decision (it's an
  established creature's canon appearance, sourced from
  `docs/art/wild/`), not mine to invent. Did not reopen it.
- **A general per-species rim-strength bump** instead of the Warrens
  Guardian's specific backlight. `FIELD_RIM_MAX`/rim strength constants in
  `creature_body.gd` are global — bumping them for readability would affect
  every creature using the field-separation rim system, not just the one
  the judge flagged. The targeted light fixes the specific reported
  instance without touching a shared visual system.

## Environment notes for whoever picks this up

- **Godot is not installed in this remote session's container.** I
  downloaded 4.7-stable (the version CI pins) to `~/godot-bin/godot`. That
  is local to my container and will NOT carry over to a fresh session — a
  successor will hit the exact same gap and needs to redo this download
  (`https://github.com/godotengine/godot/releases/download/4.7-stable/
  Godot_v4.7-stable_linux.x86_64.zip`, unzip, chmod +x). This is not new —
  `ralph/reports/T1-CASTLE_castle_2026-08-29.md` hit the same thing earlier
  today; it is apparently a per-container gap, not a one-off.
- **`godot --headless --path . --import` must be run once before any
  capture** after any asset/scene change (not needed for pure JSON edits
  like mine, but I ran it anyway before writing new `.gd` tool files, since
  that's what generates their `.uid` sidecar — CLAUDE.md requires committing
  those).
- **Never combine `--headless` with `--rendering-driver opengl3`** — hangs
  forever. Confirmed this trap is real (did not personally hit it this
  session, but it's exactly as documented).
- **Render cost is real and should be budgeted for:** each full world-load
  + settle + shot cycle on this box's software (llvmpipe) rasterizer runs
  roughly 12–25 minutes depending on settle-frame count and shot count.
  `tools/capture_warrens_63.gd` in particular uses a 240-frame settle
  (~50+ minutes) — that is the existing tool's own established number, not
  something I'd second-guess without knowing why it's tuned that high, but
  budget for it if reusing that specific tool.
- **A capture tool's "frames -> ..." line in its own stdout is the real
  completion signal**, not process exit — `capture_warrens_63.gd` kept
  running for a few seconds after printing that line and before its process
  actually terminated. Poll for that line, not just `kill -0` on the pid,
  the way I ended up doing after the coordinator's own warning about this
  exact failure mode.

## Things I believe are worth flagging as disagreements / corrections

- **The `habitat` field in `data/config/bands/band1_lower_meadows/spawns.json`
  says "encounter_director.gd intentionally ignores it" and implies the
  existing terrain dressing already delivers each tag's promise** ("the
  existing pond, mill, footbridge, ranger station, reed arcs, grove scatter
  and west-bank hollow provide the water edge, open bank, rocky/mill
  shoulder, grove and overhang equivalents"). That claim was **not actually
  true for 3 of the 7 tags** (creek_edge, rock_overhang, water_edge) — the
  water creatures those tags describe were standing on the lakebed, not at
  any edge a player could see. I don't think this was ever rendered and
  checked before my probe did it; the comment reads as confident but was
  wrong. I'd treat any other "this already works, trust the comment"
  claim in this codebase (there are many, in the same confident voice) with
  the same "render it before believing it" discipline CLAUDE.md already
  asks for — this is a concrete instance of that discipline paying off, not
  a hypothetical.
- **No disagreement with the coordinator's Band 2/4 hypothesis** — I think
  it's a reasonable thing to have checked, I just don't think 2 sample
  points is enough evidence either way, and I don't think blindly rendering
  all 100+ remaining spawn clusters is a good use of render budget without
  a sharper prioritisation signal (e.g., which specific clusters' terrain
  height/colour actually looks close to a rock material's, computed rather
  than guessed). If someone picks this back up, I'd write that
  prioritisation check first rather than keep sampling blind.

## What I would do next, concretely

1. Read `ralph/reports/T1-CREATURE_habitat_2026-08-29.md` in full (this
   handover is a summary, that file has the numbers).
2. Get the Warrens Guardian before/after (`ralph/reports/T1-CREATURE/shots/
   guardian-silhouette-*-crop.png`) in front of Fable via whatever the
   coordinator's replacement routing mechanism is. That verification is the
   single most important loose end — my fix is unconfirmed by the
   independent judge.
3. Re-run `tools/_probe_creek_hollow_habitat.gd -- creek_edge` two or three
   times to see if the paddlenewt individuals ever land in a bad spot; if
   they consistently do, shrink that cluster's radius or add a depth clamp
   to the scatter, not just the centre.
4. If continuing the Band 2/4 rock hypothesis: before rendering more points
   blindly, write a script that reads each spawn's terrain material (or at
   minimum, distance to the nearest quarry/rock-family prop cluster in that
   band's `props.json`) and ranks candidates by actual rock proximity,
   the same way the water-depth check gave a hard number to prioritise
   Creek Hollow's 3 broken spawns out of 7. That turns "sample 2 of 55
   blindly" into "check the 5 that are actually near rock."
