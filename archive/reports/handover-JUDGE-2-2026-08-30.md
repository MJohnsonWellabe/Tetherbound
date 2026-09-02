# Handover — JUDGE-2 (blind visual judge), 2026-08-30

Branch `ralph/JUDGE-2`, off `origin/main` @ `a97f3e84`. Deliverable:
`ralph/reports/JUDGE-VISUAL-2-2026-08-30.md`, frames beside it in
`ralph/reports/judge-visual-2-2026-08-30/`. Committed and pushed per
subject as completed; nothing in this session authored, staged or edited
any production code, data, or evidence it judged.

## What was rendered, from which tree

A **local throwaway integration** (never pushed): `origin/main`
(`a97f3e84`) + all ten lane branches (T1-SKY, T1-CAST, T1-UI, T1-GROUND,
T1-WARRENS-EXT, T1-HALL-DESIGN, T3-TYPECHART, T3-PICKUPS, T2-STRANDING,
T2-GATEF), every merge clean, local head `0791b1f6`. No integration
branch existed and no coordinator was available to name one, so the
brief's stated fallback was applied and the tree is documented in the
report header.

Renders, all via
`xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver
opengl3 --resolution <res> --script <tool>`:

1. `tools/_judge_capture_arch_0829.gd` — 11 architecture frames
   (castle ×4, stronghold ×2, warrens ext ×3 / int ×2), ~15 min.
2. `tools/_capture_ground_and_sky.gd` — 24 frames: bands 1–5
   day/golden/night, band-2 weather sweep, water ×6, ~50 min.
3. `tools/_capture_day_night_transition.gd` — 12 hour frames including
   the first genuine 22:00–02:00 (the y=−500 parking fix is in on the
   integrated tree and worked).
4. `tools/survey.gd` (5 stands, one FAIL — see below),
   `tools/capture_village_npcs.gd`, `tools/capture_creature_presentation.gd`
   (17 species portraits/fields + habitat shots),
   `tools/_capture_ui_survey.gd` at 1920×1080 (frames 01–09 used).

Every colour verdict carries sampled patch numbers (mean RGB + std-dev,
coordinates given) — the round's weighted focus.

## Which subjects got verdicts

All of them. Castle **BAD** (wall pixels identical to last round's
(212,203,185) — but see reconciliation: no lane worked it; the merged
Hall redesign supersedes retinting). Stronghold **ACCEPTABLE** (the
round's genuine move — up from BAD). Warrens exterior **ACCEPTABLE** (up
from BAD; one rock family now). Warrens interior **GOOD, protect it**
(held). Ground/paths **ACCEPTABLE** (bands 1/3 are the best frames in
the game; seams/smear/lime tint hold it back). Water: pond GOOD, river
ACCEPTABLE, stream still BAD/invisible. Sky/day-cycle **ACCEPTABLE**
(golden hour fixed on the driven clock; 22:00 genuinely good; new
defect — night brightens monotonically to a pale-mint 02:00).
Humanoids: material hole fixed, grunt presentation still near-black at
distance (mean luma 13 in sun). Creatures **GOOD** — strongest class in
the game, board-true. UI **ACCEPTABLE**. Macro **ACCEPTABLE** (horizon
boxes and missing eye-level aerial perspective persist).

§25 target question: **no overall, by a narrower margin than round 1**,
and the "no" is now a concrete shortlist (castle values, horizon boxes,
seams, smear, grass B-channel, 02:00). Bar questions: keyart **no**
(bands 1–3/pond/night/creatures individually yes); Palworld-kind
**yes for field+creatures, no overall** — the flip still happens when a
structure enters frame.

## What I learned that is not in the diff

- **The pixel that matters most this round:** the castle's lit wall
  samples (211,202,185) vs (212,203,185) last round. Not because a fix
  failed — because nothing was aimed at it. Don't let "castle failed
  again" enter the narrative; "the merged Hall is unbuilt" is the true
  statement.
- The first judge's "black villager" was almost certainly the band-2
  grunt picket; villager materials render clean on the stage rig.
- The night curve after midnight was never previously seen by anyone
  (red-vignette bug), and it turns out to be broken in a *new* way
  (backwards brightening) — first finding on genuinely new ground.
- `tools/survey.gd`'s stand 5 (`05-spawn-low-sun`) renders a flat frame
  and FAILs itself; it needs the settle/streaming fix its siblings got.
- Two full `meadows_playground` renders run fine concurrently on this
  box (~5 GB RSS each), but I serialized mine to keep llvmpipe timings
  sane. A judge session fits in ~5 hours wall-clock this way.
- `pkill -f <anything in your own command line>` kills your own shell.
  Use a launcher script and `pgrep -x godot`.

## What I would judge next

1. **The merged Meadows Hall, the moment it is built** — with
   `HALL_DESIGN_2026-08-30.md` §10's stands and §11's acceptance list,
   and nothing the design or build lane wrote about how good it looks.
2. The 02:00 curve and the seam glow after the next sky/ground lanes —
   both are new named defects with clean repro tools.
3. The groundmat/clover restore (T1-GROUND shipped it unverified; no
   band frame I took can confirm it reads).
4. A village close-up pass — no current capture tool photographs the
   village square at gameplay range with villagers in frame; that gap
   let the "black villager" misidentification survive a full round.
5. Creek Hollow water spawns after T1-CAST's radius fixes, and the
   campsite kit — both were queued for blind judgment and never routed.
