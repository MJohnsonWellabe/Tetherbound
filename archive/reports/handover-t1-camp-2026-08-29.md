# Handover — T1-CAMP — 2026-08-29

Coordination tooling dropped out; lanes are being stopped and restarted
fresh per owner decision. This is a full context dump, not a "task
complete" report — read it even where it overlaps
`ralph/reports/t1-camp-session-2026-08-29.md` (the session report this same
lane already wrote and pushed; that file has the full before/after
narrative and measurement detail, this file is the handover index into it).

**Branch:** `ralph/T1-CAMP`
**HEAD at handover time:** `d2c20325` (local and `origin/ralph/T1-CAMP`
are identical — confirmed with `git rev-parse HEAD` /
`git rev-parse origin/ralph/T1-CAMP` immediately before writing this file).
Working tree was already clean and fully pushed when this handover began —
there was no uncommitted or unpushed work to rescue.

```
d2c20325 T1-CAMP: round 2 session report -- bedroll fix, fire/workbench deferrals
73a9da2a T1-CAMP: commit .uid sibling for _capture_t1_camp_assets.gd
3c02e236 T1-CAMP: commit .uid siblings Godot generated for the new scratch tools
87db2287 T1-CAMP: replace the mismatched player bedroll with the camp-set bed
fbb8954c Merge remote-tracking branch 'origin/main' into ralph/T1-CAMP
961a8c02 <- main at merge time>
30caa55d T1-CAMP: fix player-built tent/creature-bed ground sink, add campfire ring
```

`main` was at `961a8c02` when merged in (round 2); confirm it has not
moved further before rebasing/cherry-picking anything from this branch.

## What I was asked to do

Owner-direction priority §17 (`docs/owner-direction/TETHERBOUND_VISUAL_STUNNING_PASS.md`),
campsite assets: Tent, Campfire, Player Bed/bedroll, Creature Bed,
Workbench. Bar: charming enough that players want to place it, one shared
material/style family, readable at gameplay distance, believable scale,
useful not decorative, composes attractively, low complexity for repeated
placement. Hard constraints: no new creature/Meshy generation for the
Meadows, no Meshy at all here (reserved for Team Tether hero objects, needs
owner reference art that doesn't exist for camp props), record any sourced
asset's provenance in `docs/ASSET_LEDGER.md`. A coordinator check-in
mid-session (round 2) explicitly ordered the remaining work: shared
material family first, then readability/scale/usefulness/composition/
complexity.

## Where I actually got to

### DONE and verified

1. **Player-built tent was sunk ~0.61m into the ground.** `camp_tent.glb`'s
   own glTF origin sits above its geometric base (same quirk
   `docs/ASSET_LEDGER.md` already names and compensates for via `sink_m` on
   the AUTHORED placement) — `scripts/build/camp.gd` positioned the tent
   node directly with no such compensation, so it rendered as a knee-high
   toy. Fixed: `TENT_POSITION`'s y raised by the measured 0.611m.
2. **Creature Bed had the identical bug** at 0.215m. Fixed in
   `scripts/build/creature_bed.gd` (`BED_SINK_LIFT`, applied in both
   `build_ghost()` and `build_real()`).
3. **Player-built campfire had no stone ring** — every authored camp in the
   game pairs `Bonfire_Fire` with `campfire_stone_ring.glb`; the player's
   own never did. Added, scaled/positioned to clear the tent in this camp's
   tight layout (`STONE_RING`, `STONE_RING_SCALE` = 0.8 in `camp.gd`).
4. **Player bedroll was the actual material-family defect**, not a colour
   problem. Round 1 tried an `albedo_color` tint on the Kenney bedroll and
   it made things WORSE (see "dead ends" below). Round 2 diagnosed it
   correctly with real close-up frames: the Kenney bedroll is flat-shaded
   with literally no texture, next to a richly-textured tent/creature-bed.
   Fixed by replacing it entirely with `camp_bed.glb` (`PLAYER_BED` in
   `camp.gd`) — the same mesh `creature_bed.gd` already places, and the
   same mesh the AUTHORED trail_camp already uses as a generic camp
   sleeping surface, not an exclusively-creature asset. No new sourcing, no
   Meshy, no new ledger row needed.

Verification commands and their actual output (re-run these, don't trust a
paraphrase):

```
tests/run_tests.gd -- --only=camp,creature_bed,build_catalogue,home_progress,gate_a_rest_torch,free_build,gateb_flags
  -> 42 tests, 854 assertions, 0 failed   (round 2, after the bedroll swap)
  -> 42 tests, 830 assertions, 0 failed   (round 1, before it — the 24-assertion
     delta is expected: test_free_build.gd's per-buildable-cost assertions
     scale with buildables.json's own entry count, unaffected by this lane)

tests/smoke_gate_a_rest_torch.gd (full production meadows_playground.tscn,
real controller-path placement of camp + creature_bed, real rest/torch use)
  -> passed clean both rounds, most recently on merged main (961a8c02):
     "fixture placed through controller: creature_bed"
     "fixture placed through controller: camp"
     "creature bed: visible body, gradual HP 30.00 -> 30.70, active selection refused"
     "torch: 6 physical draw/stow cycles restored prop and lights without duplicates"
     "[camp] rested; day 2"
     "player rest: day advanced, trainer healed, creature completed rest and returned active"
     "Gate A rest/torch smoke passed"
```

Full unpaginated `tests/run_tests.gd` (all ~114 files) was NOT run — it does
not fit a single invocation inside this sandbox's timeout (hit a 5-minute
wall clock limit mid-run and killed it rather than let it run indefinitely).
The filtered list above is every test file this lane's diff could plausibly
touch; a successor with more CI budget should still run the full suite once
before this merges anywhere.

### Investigated and deliberately NOT changed (this is a decision, not a gap)

- **`Bonfire_Fire`'s flat-shaded logs.** Genuinely textureless in the
  source `.mtl` (`Kd` colour only, no `map_Kd` line, confirmed by reading
  the file directly) — not an import bug. Left alone because this exact
  asset is what every AUTHORED campfire in the game already uses
  (band1/band3/band4 trail_camps, the stronghold rest point); texturing it
  only for the player-built camp would fix one family gap while creating a
  new one against every other campfire. A real fix needs a shared-code or
  shared-asset change, plus proof it doesn't break
  `campfire_glow.gd::ignite()`'s name-based match on the `Fire` surface —
  bigger than this lane's footprint should take unsupervised.
- **Workbench** (`Quaternius Fantasy`). Reads warmer/more saturated than the
  camp-set pieces but is real PBR wood-grain, not a material-language
  collision, and is the SAME prop family used for every other buildable and
  scatter prop across the entire game. Regrading it here would fix a mild
  local variance while breaking consistency with its own much larger family
  everywhere else. Left untouched on purpose, twice (both rounds), now with
  a side-by-side comparison frame backing the call.

### Still open (not started)

- No FPS/frame-cost measurement on real hardware — no ROG Ally in this
  sandbox, only llvmpipe software rendering, whose absolute frame times
  this repo's own tooling already documents as untrustworthy
  (`tools/_capture_structures.gd`'s header). Reasoned-but-unmeasured
  expectation only: the round-1 changes are one more mesh instance
  (already used elsewhere with no documented cost issue) plus pure
  `Vector3` offset changes, so expected delta is ~zero, not proven.
- §17's "readable at gameplay distance" / "compose attractively" for the
  FULL five-piece kit together (not just the `camp` sub-composition) was
  eyeballed via `tools/_capture_t1_camp.gd`'s wide shot but never put
  through an actual visual-judge pass — frames were captured and handed to
  the user/coordinator to route, but no judge verdict came back before
  stand-down.
- Bed repetition: the player bed and creature bed are now the literal same
  mesh in the same small camp. Visually it reads fine (different position/
  rotation, and both are correctly the reused asset by design), but nobody
  has asked a fresh critic whether two identical beds ten feet apart reads
  as "reuse" or "laziness." Worth a real judge opinion, not a guess.

## Numbers worth not re-deriving

- `camp_tent.glb`: measured size (1.598, 1.209, 1.897), `base_y = -0.611`
  (local AABB min y) — i.e. its own origin sits 0.611m above its visual
  base. Command: `tools/_probe_t1_camp.gd` under
  `xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver opengl3 --resolution 1280x800 --script tools/_probe_t1_camp.gd`.
- `camp_bed.glb`: size (1.229, 0.409, 1.901), `base_y = -0.215`.
- `campfire_stone_ring.glb`: size (2.000, 0.233, 1.999), `base_y = -0.116`,
  raw diameter effectively 2.00m. Its material (`material`, one surface)
  has `metallic=1.0` from Godot's read but WITH a real metallic-roughness
  texture (`metallic_tex=true`) — this is NOT the "black silhouette"
  glTF-default-metal bug (that bug needs factor=1.0 AND no texture); I
  chased this for a while in round 1 before ruling it out. Don't re-chase
  it.
- `Bonfire_Fire` raw AABB (Quaternius Survival): size (2.18, 2.31, 1.98),
  `base_y = -0.06` (already close to grounded, not a sink bug).
- `Workbench.gltf` raw AABB: size (2.019, 0.895, 1.024). Its
  `MI_Trim_Furniture`/`MI_Trim_Metal` materials read `metallic=1.0` with a
  real texture on raw import too — this IS one of the two cases already
  covered by `build_material_finish.gd`'s `FINISH` table (it zeroes and
  replaces regardless of texture presence, by design, per that file's own
  comment) — already fixed at runtime, do not "fix" it again.
- Bedroll tint experiment (round 1, reverted): `Color(0.75,0.55,0.42)` and
  `Color(0.92,0.85,0.75)` albedo multiplies both measured (via PIL pixel
  sampling on the rendered PNG, not eyeballing) to make the bright
  near-white pillow region read MORE saturated red under this scene's ACES
  tonemap, not less — R channel stays clipped at 255 while G/B fall. Do not
  retry a plain multiply-down tint on this asset; it doesn't work under
  this tonemap. If someone wants the old bedroll's colour fixed instead of
  replaced (I replaced it instead, see above), the fix needs either a
  genuinely different atlas UV column or a tonemap-aware grade, not a
  StandardMaterial3D albedo multiply.

## What I learned that is not visible in the diff

- **Godot 4.7 is not preinstalled in this remote sandbox.** No binary
  anywhere on `$PATH` or via `find`. `apt-cache search godot` only offers
  `godot3` (wrong major version — this project is Godot 4.7 / GL
  Compatibility per `project.godot`). What worked: downloading the official
  release directly —
  `curl -sSL -o godot47.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip`
  (75MB, succeeded through this session's proxy on the first try), unzip,
  `chmod +x`. `xvfb-run`/`Xvfb` WERE already installed
  (`apt list --installed | grep xvfb` showed `xvfb` present) — did not need
  installing. I put the extracted binary in the session scratchpad, not the
  repo; a fresh session will need to re-fetch it (~76MB, ~1 download, no
  other setup needed) before any capture/import/test work is possible at
  all. This cost real time both sessions — a successor should budget for it
  up front rather than discovering it mid-task.
- **`--headless --import` first run takes ~7.5 minutes** (104-step scene
  reimports for six humanoid rigs plus 726 general reimport steps); a
  second run after a small merge (only new `.gd`/`.shader` files, no
  changed binary assets) takes ~20 seconds. Budget for the first one
  accordingly; don't panic if it looks stalled.
- **New `.gd` script files need their own `.uid` sibling committed**, and
  that `.uid` is only generated by a project-wide scan (`--import`, or
  apparently anything that walks the full script class list) — NOT by
  directly running the new file with `--script`. I created three new
  `tools/_*.gd` files across two rounds and had to go back and run a bare
  `--import` a second time specifically to generate the third one's
  `.uid`, because I'd assumed (wrongly) that skipping reimport was fine
  since no *asset* had changed. Rule for next time: re-run
  `--headless --path . --import` after creating ANY new `.gd` file too,
  not just after asset changes, then `git status` for stray `.uid`s before
  committing.
- **A material with `metallic=1.0` on raw import is not automatically the
  "renders as black metal" bug.** That specific defect (documented in
  `scripts/world/imported_materials.gd`'s header, `GF-B-010`) needs BOTH
  factor=1.0 AND no metallic-roughness texture. I initially flagged
  `campfire_stone_ring`'s raw `metallic=1.0` as suspicious, wrote a whole
  probe to check it, and then found it does have a real ORM texture, so
  `IMPORTED_MATERIALS.make_dielectric()` correctly leaves it alone. Wasted
  maybe 15 minutes chasing a non-bug; check for the texture before
  diagnosing this failure mode, the existing helper file's own header says
  exactly this and I should have read it first.
- **ACES tonemap inverts intuition for darkening a bright/near-white
  texture region.** Multiplying albedo down on an already-near-clipped
  white surface makes the R channel stay clamped at 255 while G/B drop,
  which reads as MORE saturated, not less. This is a real, reproducible,
  measured (not guessed) property of this scene's render pipeline under
  Compatibility/llvmpipe — worth remembering for any future "just tint it
  darker" instinct on a bright asset in this project.
- **Root cause I found and did NOT fix**: the whole camp kit's incoherence
  traces to three different source pipelines in one small object cluster —
  Meshy owner-directed generation (tent/ring/bed), Quaternius Survival
  (bonfire, genuinely textureless), and Quaternius Fantasy (workbench, a
  totally different and much larger prop family used everywhere else in
  the game). There is no single "wrong" asset here so much as three
  correct-for-their-own-context assets that were never going to fully
  cohere without either (a) a fourth Meshy generation to unify them (banned
  by CLAUDE.md without owner reference art) or (b) accepting the bonfire
  and workbench as permanently slightly-off notes in an otherwise-matched
  kit. I made the trade I could make (swap the one asset that was flatly,
  objectively worse, not just a different-but-valid style) and left the
  rest as a named, bounded gap rather than chase an unreachable "perfect"
  under a hard no-Meshy constraint.
- **Nothing in this lane conflicted with `main`.** The `961a8c02` merge
  (seven-lane integration plus a scatter re-bake, watchtower landmark,
  grass_field changes, a trainer-band fix) touched zero files this lane
  also touched — `camp.gd` and `creature_bed.gd` were untouched by that
  merge. Clean, no manual conflict resolution needed. Do not assume the
  NEXT main-move will be equally clean; re-check `git diff --stat` against
  whatever `camp.gd`/`creature_bed.gd`/`build_piece.gd` look like on a
  fresh `main` before reapplying anything from here by hand.

## Disagreements / things I believe are wrong elsewhere

- The original task brief (and CLAUDE.md's own framing) implied the
  campsite kit's weakness was primarily a "these five objects don't share a
  material family" problem to be solved by grading/texturing. In practice
  two of the three real defects were placement/composition bugs
  (ground-sink) that had nothing to do with material, and the one genuine
  material-family defect (the bedroll) was better solved by **not using
  that asset at all** than by any amount of material work on it. If a
  future §17-style brief assumes "the fix is grading," it should say
  "diagnose first" instead — grading a broken composition wastes a cycle
  (I lost one whole round to it before the coordinator's own check-in
  reset my approach, and even then I re-diagnosed slowly).
- `docs/ASSET_LEDGER.md`'s existing entries for the camp set already
  documented the tent's and bed's sink measurements accurately
  (`sink_m: -0.64` / `-0.21` on the AUTHORED placement) — the bug was
  purely that `camp.gd`/`creature_bed.gd` (the PLAYER-built path) never
  read or replicated that compensation. This is worth flagging generally:
  any future asset that needs a `sink_m`-style correction on its authored
  scatter placement should be checked against EVERY other code path that
  also instantiates it directly (there are at least two — `props.gd`'s
  scatter path, and each hand-authored buildable script), because the
  ledger note only protects the path someone remembered to apply it to.
- I do not have an actual visual-judge verdict on any of this — I want to
  flag plainly that everything under "DONE and verified" is verified by
  tests and by my own eye against captured frames, not by the project's own
  blind-critic process. Do not upgrade my "looks clearly better to me" into
  "the judge passed it" in any downstream summary.

## File footprint

Everything this lane touched, full stop:

- `scripts/build/camp.gd` — MODIFIED (both rounds: sink fix + stone ring in
  round 1; bedroll->camp_bed swap in round 2. This is the file most likely
  to collide with any other lane also touching the player-built Camp.)
- `scripts/build/creature_bed.gd` — MODIFIED (sink fix only, round 1).
- `tools/_probe_t1_camp.gd` + `.uid` — NEW (measurement probe, round 1).
- `tools/_capture_t1_camp.gd` + `.uid` — NEW (assembled-camp capture,
  round 1).
- `tools/_capture_t1_camp_assets.gd` + `.uid` — NEW (per-asset close-frame
  capture, round 2).
- `ralph/reports/t1-camp-session-2026-08-29.md` — NEW (full session
  writeup, both rounds, the detailed companion to this handover).
- `ralph/reports/handover-t1-camp-2026-08-29.md` — NEW (this file).

Nothing else was staged, edited, or planned-but-not-applied. I was not
mid-edit on anything when the stand-down instruction arrived — the working
tree was already clean and pushed (see the git output at the top of this
file). No file was "about to be changed" beyond the still-open items listed
above, none of which had draft code written for them.

## What I would do next, concretely

1. Get an actual blind visual-judge pass (`.claude/skills/visual-judge` or
   the Fable dispatch the coordinator mentioned routing to) on
   `tools/_capture_t1_camp.gd`'s and `tools/_capture_t1_camp_assets.gd`'s
   output before doing anything else — don't guess further at what still
   reads wrong.
2. If the judge flags the bonfire logs specifically: the fix is a shared
   one (touches whatever both `camp.gd` and `props.gd`'s scatter path route
   through, or the source asset itself), and needs `campfire_glow.gd`'s
   `ignite()` re-verified against it afterward (it name-matches the `Fire`
   surface by string — confirm that survives whatever change is made).
   Don't scope it to just `camp.gd` again; that was this session's own
   mistake to avoid repeating.
3. If the judge flags the twin-bed repetition: the only lever without a new
   Meshy generation is differentiating the EXISTING `camp_bed.glb` via
   material variant (a colour/fabric swap in the same economy
   `tm_orb`'s "one mesh, ten materials" approach already uses elsewhere in
   this codebase, per `docs/ASSET_LEDGER.md`), not a second asset.
4. Get real ROG Ally frame-time numbers before/after this lane's changes —
   nobody has, and §21 asks for it explicitly.
5. Run the FULL `tests/run_tests.gd` suite (not just the filtered subset)
   once, with a longer timeout or sharded per this repo's own `--shard`
   flag, before this branch is trusted for merge.
