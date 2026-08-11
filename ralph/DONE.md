# Done

Append-only. Newest at the top. One entry per shipped backlog item: what
shipped, the commit, and anything the next firing should know.

## SA8 — Grandpa's opening dialogue: the Team Tether urgency beat
`031f571`. `tests: smoke_opening` (green, run locally headless).

Two new lines in `grandpa_house` (`data/dialogue/opening.json`), owner
directive close to verbatim: someone has to stop Team Tether, he waited
because the player was too young, and they are only getting stronger.
Slotted between the existing physical excuse ("I get winded crossing my
own meadow") and the existing "So you go" — the briefing already
established that Team Tether exists and that Grandpa can't walk; this adds
why it has to be the player, and why now. Everything else in the
conversation, including the belt-limit and camp/gather lines the item
explicitly said to leave alone, is untouched. `smoke_opening.gd` still
passes; beat 3 now closes after 16 presses instead of 14, which the test
counts dynamically rather than asserting a fixed number.

## CO1 — Manual pal summon, dismiss and swap
`f6d21c4` (code), `565feca` (settings-screen fixup, see below).
`tests: smoke_opening, smoke_catching, smoke_aggression, smoke_combat,
smoke_pal_control` (all green, run locally headless) plus the full
`tests/run_tests.gd` suite (305/305).

Two real gaps closed, not one. There was no way to put the following pal
away or call it back. And `tab_pals.gd`'s "send this one out first" already
called `Game.party.set_active()` — but nothing ever read that back, so
choosing a different active pal in the party menu had no effect on who was
actually standing beside the trainer.

`encounter_director.gd`: `adopt_starter()`'s spawn logic split into a
shared `_spawn_ally_body(pal)`, reused by the new `summon_active_pal()`
(brings `Game.party`'s active pal out) and `dismiss_active_pal()` (puts the
current one away; refuses mid-fight, same guard `_set_exploration_active()`
already has). `_sync_active_pal()` polls `party.revision` — the same idiom
`autoload/party.gd`/`autoload/inventory.gd` already use — and swaps the
live body when the party screen's active slot changes underneath it.

New `pal_recall` input action (keyboard R, gamepad D-Pad Up, both
previously unbound) toggles dismiss/summon, read the same way
`_read_engage_input()` already is. Its prompt reuses `PROMPTS`' existing
single-line contract (`prompt_arbiter.gd`) as a non-actionable, low-priority
fallback in `interaction_offer()`, so it never competes with "Engage X" —
with a real `HD1`-style device-aware glyph (`input_glyph.gd`'s `GLYPHS`
gains a `pal_recall` entry; two Kenney PNGs staged from the
already-ledgered Input Prompts pack, no new ledger line needed).

**The fixup commit** (`565feca`, folded in during shipping): CI caught a
gap the smoke tests didn't — `test_controls.gd`'s
`test_every_rebindable_action_is_on_the_screen` fails for any input-map
action missing from `menu.json`'s `settings.controls`. `pal_recall` now
sits in "The world" group next to `interact`/`tool_cycle`, with a label.

New `tests/smoke_pal_control.gd` (not in CO1's own `tests: none`, but
`adopt_starter()` was refactored and nothing else exercised any of this):
dismiss, recall, a live swap via `party.set_active()`, and the mid-fight
refusal.

**Shipping this took far longer than the work itself** — worth recording
since it happened live and taught real things about the pipeline, not
because CO1 itself was unusual. `ralph/CO1` was rebased and re-pushed
roughly a dozen times across ~3 hours before landing, entirely because of
infrastructure, not code: every automatic rebase dispatches CI via
`gh workflow run` (a `workflow_dispatch` run), and GitHub's default-token
recursion guard means `workflow_dispatch` runs never raise a `workflow_run`
event — so `ralph-merge.yml`'s event-triggered merge could structurally
never fire for a rebased branch's own green CI, not intermittently, every
time. `ralph-sweep.yml` (a 10-minute cron reconciler, landed mid-firing by
another lane) is the real fix and is what finally shipped this — but it
also has its own real 3-rebase cap per sweep pass (`ship_branch.sh`), which
this branch hit twice in one of tonight's unusually high-churn windows
(many lanes landing within minutes of each other). Both times the fix was
the same: rebase and push by hand, which resets the count, then let the
sweep pick it back up. `ralph-sweep.yml` also accepts a manual
`workflow_dispatch` — used directly a few times here rather than waiting
out an apparently-delayed cron tick, which is a legitimate, documented way
to nudge it. None of this needed a code fix; it's recorded here as
evidence for whoever next looks at the sweep's dropped-cron-tick behavior
or its rebase cap under heavy concurrent load.

## EV9 (third slice) — tab_backpack.gd quantity-clipping fix, finished on an abandoned branch
`b6628ba` (code, an earlier firing's), `05b8948`/rebased tips (ship, this
firing). `tests: smoke_menu` (green, run locally headless).

**What happened.** `ralph/EV9` had one commit sitting green on CI since
2026-08-11 22:43, never merged — its own lease long dead, the branch itself
stale by both the timestamp and branch-liveness tests in `PROMPT.md`. Rather
than pick a fresh backlog item, this firing rebased it cleanly onto current
`main`, reran the item's own named test locally, and pushed. No new
diagnosis needed; the abandoned commit's own message already has the full
story: the theme's default 26px button font clips a long item name plus
quantity entirely off a 168px tile with no ellipsis (`clip_text` hard-cuts),
caught by `EV9`'s own round-3 blind-judge pass. Fixed with a measured 20px
override (the largest size that keeps the longest current item name plus a
quantity inside the tile's content width) and a doubled-space-to-single fix
in the format string.

## EV4-hillside-seam rounds 3-4 — rock went from mathematically unreachable to a proportionate accent
`25c6606` (round 3), `68541a9` (round 4). `tests: smoke_traversal` (green,
both rounds). Visual-affecting: three local blind `.claude/skills/visual-judge`
rounds ran in this checkout, one push per round (round 2's own WIP push had
already landed via the merge workflow before this firing could critique it
locally — see the honesty note below).

**What shipped:**

1. **Round 3 fixed rock being unreachable.** Round 2 (already on `main`
   before this firing started) doubled `blend_deg` 7→14 to fix a round-1
   critic's "hard, unblended seam" complaint. A fresh round-3 blind critic
   given the rebaked frames instead reported **no rock or distinct soil band
   anywhere, on any of three viewpoints** — not a seam problem, an absence
   problem. Root-caused with `tools/debug_slope_probe.gd` against
   `rises.peaks[0]` (centre `[140,-90]`, radius 78, the exact landform
   `capture_hillside.gd` frames): pure rock only starts at
   `rock_slope_deg + blend_deg`, and round 2's 44+14=58 degrees sat outside
   this landform's own reachable slope — probed directly, this gentle, wide
   dome (height 46 over radius 78) peaks at ~52.5 degrees around 72m out
   along the east bearing and then *recedes* toward its base skirt, so 58
   degrees never occurs anywhere on it. Fixed by lowering `rock_slope_deg`
   44→40 (a pre-existing, untouched-by-this-item value that simply never fit
   this specific landform's shape) rather than narrowing the blend back down,
   which would have reintroduced round 1's seam complaint.
2. **Round 4 fixed rock then dominating.** The round-3 fix worked — rock
   became visible — but overcorrected: a fresh critic found rock covering
   60-75% of two of three frames, and still no visible soil band, because
   `blend_deg=8` with `rock_slope_deg=40` left only a 2-degree pure-soil
   plateau. Fixed with `blend_deg` 8→6 and `rock_slope_deg` 40→44 (its
   *original*, pre-`EV4-hillside-seam` value), opening an 8-degree pure-soil
   plateau (36-44) while pushing pure rock back to 50 degrees — the same
   probe confirms that band still occurs, narrowly, from ~68m to ~74m out.
   A third blind critic confirmed the proportion fix in two of three frames
   (rock reduced to a minor accent) but named three further, different-in-kind
   defects — see `EV4-hillside-seam-remainder` in `BACKLOG.md`, opened rather
   than continuing to tune blind: the remaining issues are texture/placement
   quality (a near-black rock texture, no visible soil tone, ring-like
   placement uniformity), not slope-threshold numbers.

**Honesty note on how round 2 shipped.** This firing picked up
`ralph/EV4-hillside-seam` as abandoned WIP (last commit ~55min stale, no
live lease) and pushed it once (round 2 + a missing `.uid` sidecar fix,
`dfc9a67`) *before* running the local blind-judge pass — a deliberate
deviation from `conventions.md`'s "push once at the end," made because a
repo stop-hook required no uncommitted/unpushed state at every turn boundary
in this session and there was no way to hold the work locally indefinitely.
`ralph-merge.yml` fast-forwarded it to `main` before the critique ran, so
round 2's rock-unreachable bug was briefly live. Rounds 3 and 4 fixed it
promptly in the same session; each of those two rounds *was* committed and
pushed only after a local `smoke_traversal` check, and round 4 after a full
local blind-judge round on round 3's own render. Recording this plainly
because `PROMPT.md` asks for it, not because it's a pattern to repeat: the
push-once-at-the-end discipline is still correct when nothing is forcing an
earlier push.

## EV3-remainder-2 (square-convergence half) — a per-instance jitter on the path-exclusion cutoff, not a clump-placement fix
`tests: smoke_art`, green locally throughout. Two full local blind-judge
rounds (`.claude/skills/visual-judge`, genuinely blind sub-agents, no
knowledge of what changed), plus a scratch (never committed) screen-
projection tool that painted real placement data into `capture_paths.gd`'s
own camera to confirm the diagnosis against pixels, not guesses.

**Root cause, confirmed empirically before writing any fix:**
`terrain_playground.json`'s four routes all share one endpoint, the village
well — so `scatter_rules.gd::_consider`'s path-exclusion test
(`path_factor() > 0.3`, one fixed isoline every ground-cover layer shares)
draws four straight wedges meeting at that single point. A debug overlay
that projected every `grass`/`drygrass`/`flowers`/`bushes` placement into
the survey camera showed all four layers tracing the *same* straight fan —
not a flowers-only clump artefact, which is what the original finding's own
name ("row-planted flowers") assumed.

**Fix:** a new per-layer `path_edge_jitter` (`scatter_rules.gd`) that
jitters the 0.3 cutoff by up to this many units, per placement instance,
before testing it — deliberately NOT touching `path_factor()` itself, which
`build_playground_terrain.gd`'s own dirt-texture blend also reads and which
took five `EV4` rounds to tune. Set to 0.15 on `bushes`/`grass`/`drygrass`/
`flowers` in `vegetation.json`. Round 1's fresh blind critic called
`square-convergence.png` "the mildest version" of the row pattern, down
from "visible parallel diagonal rows... a planted crop field"; round 2's
independent critic went further, calling it "the exception... doesn't show
the hedge pattern" outright.

**A second lever was tried and reverted, honestly, not silently dropped.**
Bumping flowers' `path_bias` 0.35 → 0.5 (theory: `grandpas-house-route.png`
just drew too few path-anchored clumps by seed luck) made a DIFFERENT
complaint worse: round 1's critic called the result "a hedge planted along
a driveway" on that same frame, plus a *new* "diagonal row" on
`the-rise-route.png` that `EV3-remainder`'s own round 1 had already fixed.
More clumps anchoring one corridor raised the repetition, not just the
density — the wrong lever for this symptom. Reverted to 0.35 before
shipping.

**`grandpas-house-route.png` is NOT closed by this item.** A second blind
critic, run against the reverted state (flowers' `path_bias` back at its
untouched original value), still named the same hedge pattern on both
`grandpas-house-route.png` and `the-rise-route.png` — and was explicit that
the tufts producing it are `grass`/`drygrass`, not flowers ("the flower
patch on the left is looser and reads better — it's the tuft placement
specifically that's the problem"). Neither `grass` nor `drygrass` has ever
used `path_bias`, which rules it out as the cause and means the original
diagnosis ("flowers read as thin, uniform scatter") was the wrong half of
the picture — the real defect survived a change to the layer that was never
responsible for it. Opened as `EV3-remainder-3`, scoped correctly this
time, with the screen-projection technique that worked here handed forward
as the way to confirm before guessing again.

## EV3-remainder (round 1 of 2) — flowers gain path_bias and a jitter to break up the collinear "hedge"
`334fafc`. `tests: smoke_art` (green). Also extended `test_scatter_rules.gd` for the new
`path_bias_jitter` mechanism (backward-compat no-op test, plus a test that
jitter actually moves clumps off the exact centreline), 31/31 green locally.
Visual-affecting: two local blind `.claude/skills/visual-judge` rounds ran
(see below) — no push happened between them, per conventions.md.

**What shipped:**

1. **`flowers` gets `path_bias: 0.35`.** Round 1 of this item's own predecessor
   (`EV3`) tried tightening `flowers`' `clump_radius` the same way that worked
   for `grass`/`drygrass` and made things worse (reverted, documented in that
   entry) — the right lever is WHERE a clump lands, not how tightly it packs.
   `path_bias` snaps roughly a third of flower clumps toward the road, same
   mechanism `path_stones` already validated; the other two-thirds stay
   unbiased, so flowers still read as a general meadow accent, not the road's
   own material.

2. **New `path_bias_jitter` (`scatter_rules.gd`), set to `4.0` for `flowers`.**
   A first render with `path_bias` alone showed real improvement in one
   respect (flowers now visibly gather near paths, e.g. a garden-bed-like
   cluster at Grandpa's-house door) but a fresh blind critic named a new,
   more specific problem: path-biased clumps all snap to the EXACT nearest
   point on the route, so several strung along one straight stretch are
   themselves collinear — "a hedge planted with a ruler... same interval,
   same offset distance from the path edge." `path_bias_jitter` displaces the
   snapped centre by up to N metres in a random direction before the clump's
   own `clump_radius` scatters instances around it, so clump centres land at
   genuinely different distances from the path. `path_stones` is untouched —
   it wants the exact snap (stones ARE the path) and the key defaults to
   `0.0`.

**Two local blind-judge rounds, `tools/capture_paths.gd`'s three wide path
frames, entirely local, one push:**

- Round 1 (path_bias only): critic said the flower clustering "still reads as
  generator output... same species, same clump size, same interval, same
  offset distance from the path edge" — worst in `the-rise-route.png`.
  Flagged as the priority finding, judged a real, specific, actionable defect
  (not a re-statement of `EV3`'s own earlier "even strips" finding, which was
  about `grandpas-house-route.png` specifically and had actually improved).
- Round 2 (path_bias + jitter): a **second, independent** blind critic found
  genuine, measurable movement — `the-rise-route.png` now has "real
  variety... fern clumps of different sizes, flower patches of different
  sizes, a bit of bare grass between clusters" and was called "a real step
  toward it... should be the reference for the other two [frames]." No
  regression on the other two frames (neither was called out as worse than
  round 1). Two things did NOT resolve: `square-convergence.png`'s flower
  patch still reads as row-planted, and `grandpas-house-route.png` is still
  under-clustered rather than over-uniform — both carried forward as
  `EV3-remainder-2`, since the second critique's own diagnosis makes clear
  they are not obviously the same mechanism as the jitter fix (see that
  entry for the detail worth reading before guessing at round 3).

**Stopped after two rounds, not because the stopping rule's own convergence
test was met — it wasn't; round 2 showed real movement — but because the
owner checked in mid-session** on the combination of a long infra-blocked
wait (`EV3` itself; see its own entry) and this item's slower, iterative
render-critique-render pace, and asked directly whether progress was being
made. Conventions.md's own budget guard ("if you are running low on context
or time, stop at the current round, record the state") applies to a live
"is this worth continuing" check the same way it applies to a context limit.
Shipping the genuine, tested, net-positive improvement now rather than
opening a third render round un-asked-for is the honest reading of that
signal. `EV3-remainder-2` carries the rest forward with enough diagnostic
detail that a future pass does not have to re-render blind to find out where
the two remaining problems are.

## LP5 — A conflicting rebase in `ralph-sweep.yml`'s loop stranded every branch behind it, not just itself
Found live, not from the backlog: while waiting for `SA2-flake` to ship, its
green branch sat un-merged through a full 10-minute sweep cycle. Read the
sweep run's own log (`31548370180`) rather than guessing, per `PROMPT.md`'s
own standing note — and the log named the mechanism directly: after
`ralph/EV3` failed to rebase (a real `DONE.md` conflict, correctly reported),
every branch considered AFTER it in the same sweep — `EV4-hillside-seam`,
`EV4-textures-remainder`, `EV9`, `LP3`, `SA2-flake`, `SA5` — failed with
`tools/ci/ship_branch.sh: No such file or directory`. Six already-green
branches silently skipped, sweep after sweep, because of one unrelated
conflict.

**Root cause.** `ship_branch.sh`'s conflict path does
`git checkout -B "$BRANCH" "$SHA"` (landing HEAD on the branch's OLD,
pre-rebase tip), attempts `git rebase origin/main`, and on failure calls
`git rebase --abort`. `--abort` restores HEAD to exactly where the rebase
started — the branch's own stale tree, not a fresh copy of `main`. If that
branch predates `ship_branch.sh` itself being added to the repo (true for
`EV3`, an older branch), the script's own file vanishes from the checkout
along with everything else `main` has gained since. `ralph-sweep.yml` calls
`tools/ci/ship_branch.sh` by relative path, in a loop, against ONE shared
checkout — so the very next branch in the loop finds no such file, and the
one after that, and so on to the end of the list. `ralph-merge.yml` never hits
this because it only ever ships one branch per invocation; `ralph-sweep.yml`'s
loop is what exposes it.

**Reproduced in isolation before believing it**, not just read off the log: a
scratch repo with a `feature` branch that predates a tracked `ship_branch.sh`
file on `main`, forced into a real content conflict, rebased and aborted the
same way the real script does. Confirmed empirically — `ship_branch.sh`
present after abort: **NO** on the unpatched sequence, **YES** once the fix's
extra `git checkout -B __ship origin/main` runs first.

**Fix:** one line added right after `git rebase --abort || true` in the
conflict path — `git checkout --quiet -B __ship origin/main` — landing the
working tree back on a scratch ref pinned to `origin/main`, which by
definition contains every file `main` has, including this script itself. A
branch that cannot rebase still correctly stops and reports itself stuck; it
just no longer takes the rest of the sweep down with it.

Same `area: loop` as `SA2-flake`, found and fixed while waiting for that
branch's own ship — batched onto `ralph/SA2-flake` as a third commit rather
than opening a second branch, per `conventions.md`'s batching rule (same
area, still under the 4-item cap).

## R9.4-remainder-8-followup — one real fix (rocks floating on slopes), one false alarm (roof foliage)
`c6057e4`. `tests: none` named, ran `tests/test_scatter_rules.gd` and
`tests/test_playground_heightfield.gd` (part of the full suite) as due
diligence since the fix touches shared scatter code, not just data — full
suite green, 303/303, before and after rebasing onto a concurrent `EV3` push
that touched the same two files (`path_bias`; auto-merged clean, verified by
diff after).

**Boulders sitting proud of the ground — real, fixed.** Root cause found by
reading code before rendering anything: `vegetation.gd` places every scatter
instance world-up, sampled at one centre-point height, with a flat 0.06m
`SINK` — the `rocks` layer is the one layer with a *minimum* slope
(`min_slope_deg: 6.0`) specifically so boulders gather on rises, so it is
also the one layer where a flat, untilted placement is most visible: a wide
rock's downhill edge hangs above the actual ground with daylight showing
under it. Confirmed with a real render (a boulder on the hillside behind the
farmhouse, `tools/capture_buildings.gd`'s `05-windmill-from-meadow` viewpoint)
before writing any fix, per `conventions.md`'s cross-checking rule.

Fix: `playground_heightfield.gd` exposes the ground normal it already computed
internally for `slope_degrees_at` as a new `normal_at()`. `scatter_rules.gd`
stores that normal on a placement only when the layer sets a new
`align_to_slope` flag (`vegetation.json`, `rocks` layer only — grass/bushes/
trees stay world-up on purpose, since a plant grows against gravity rather
than perpendicular to the slope it's rooted in). `vegetation.gd` rotates the
instance basis toward that normal before applying yaw/scale. Collision
(`_add_collision`'s cylinder shapes) is untouched — it was already a coarse
camera-blocker independent of visual orientation, not something this fix
needed to touch.

Verified two ways: re-rendered the exact same boulder and confirmed the gap
is gone (now flush with the slope), and ran the mandatory blind
`.claude/skills/visual-judge` pass — a genuinely blind sub-agent (told nothing
about what changed, asked to judge the frames against the full rubric) named,
unprompted, that rocks in frames `05`/`06` "sit low... read as grounded rather
than floating." Same critic independently flagged a real but out-of-scope
finding — the rocks read as one instance duplicated (shape/colour variety, not
placement) — split out as `R9.4-remainder-8-rocks-repeat` in `BACKLOG.md`
rather than folded into this fix.

**Foliage clipping the farmhouse roof ridge — checked, did NOT reproduce.**
The original finding was from one frame (`buildings/04`, the `04-barn-cluster`
viewpoint). Rendered four fresh viewpoints close around the house from every
side (NW, NE, SW, and a raised top-down angle) before touching any code — the
roofline was clean from all four, no foliage anywhere near it. Also queried
the actual scatter placements within 14m of the house centre directly (a
scratch probe script against `scatter_rules.gd`'s own `all_placements`, not a
guess): zero tree/grove/bush entries that close, only grass/drygrass/flowers.
Conclusion: the original frame's apparent clip is a camera-angle coincidence —
a background tree aligning with the roof silhouette from that one specific
eye position — the same false-positive class `R9.4-remainder-8`'s own
windmill-rock finding already hit and closed the same way. No code change;
recorded here rather than left to be re-investigated blind next time.

## EV3 (first slice) — path_stones anchored to the real paths, grass/drygrass clumping tightened
`8528bbd`. `tests: smoke_art` (named test, green: "art: OK — models loaded,
sized to their colliders, and the meadow is dressed"). Also added and ran
`test_scatter_rules.gd`/`test_playground_heightfield.gd` coverage for the new
mechanism, 29/29 green locally (a scratch SceneTree runner, since these are
`test_*.gd` pure-logic files, not `smoke_*.gd` — `run_tests.gd` runs the full
suite, not a subset, so a one-off runner was the only way to check just these
two without paying the full-suite cost). Visual-affecting: a local blind
`.claude/skills/visual-judge` pass ran (see below).

**What shipped, concretely:**

1. **`path_stones` clumps anchor to the road.** `scatter_rules.gd` gains
   `path_bias`, the same shape as the existing `ridge_bias` but a different
   mechanism: `ridge_bias` samples a handful of candidates and keeps the
   highest ground because height varies smoothly everywhere; `path_factor()`
   is zero almost everywhere and nonzero only within a few metres of a route,
   so a candidate search would almost never land near one. Instead a
   path-biased clump snaps its centre straight to
   `playground_heightfield.gd::nearest_point_on_paths()` (new — closest point
   on any route segment, `Vector2.INF` sentinel when the config has no
   routes, same pattern `height_at` already uses). The clump's own
   `clump_radius` still spreads instances off that snapped point, so a
   biased clump straddles the road rather than lining up on its centreline.
   `path_stones` gets `path_bias: 1.0` (this layer's entire purpose is being
   the road's own texture; `strays` are left unbiased on purpose — they're
   the loose stones elsewhere in the meadow). Measured directly:
   unbiased placements average `path_factor` 0.002 across their instances,
   biased average 0.194 — roughly two orders of magnitude closer to the
   actual road. This is the fix `BACKLOG.md`'s own `path_stones` finding
   named exactly: "clumps bias toward `path_factor()`... so a stone cluster
   sits ON the dirt it's supposedly part of."

2. **`grass`/`drygrass` pack tighter, same instance count.**
   `R7.1-remainder-2`'s third round named the untried lever directly: "a
   genuine density lever inside the clumps themselves (more `per_clump`,
   smaller `clump_radius` for tighter packing) rather than further
   redistributing the same instance count." `clump_radius` 16.0→10.0 (grass)
   and 19.0→12.0 (drygrass); `clumps`/`per_clump`/`strays` untouched, so
   total instance count and render cost are unchanged — only how tightly
   each clump's own instances pack together.

**The mandatory local blind-judge pass (conventions.md), one round:**
`tools/capture_paths.gd`'s four close-range frames (village square,
Grandpa's-house route, the Rise route, an edge-detail crop) rendered, a blind
sub-agent critiqued them cold against `docs/reference/`. Verdict: both bar
questions "no" — but the critic's OWN ranked list is the useful part.
**Explicitly praised the fix this item shipped**: "The one place stones sit
convincingly *beside* the path is the cluster in `the-rise-route.png` — that's
the standout positive of the set and worth reusing elsewhere." The critic's
top three gaps, in order: (1) a hard-edged shadow artefact — not vegetation,
already being worked as `EV4-textures-lighting` (a different lane's lease was
live on `lighting` at the same `updated` timestamp this pass ran); (2) the
path material itself reading as flat/decal-stamped — not vegetation, already
`EV4-textures-remainder`'s named scope (`area: terrain`); (3) vegetation and
props reading as generator output — PARTLY this item's area (see
`EV3-remainder`'s flowers finding, opened and then reverted, below) and partly
not (a disconnected fence, an unreadable signpost — village/props, not
vegetation).

**One further change was tried and reverted, on purpose, before this
commit — kept here so the next firing does not retry it blind.** The critic
named `flowers` specifically as reading like evenly-spaced strips beside
Grandpa's-house route. Applying the same `clump_radius` tightening that
worked for `grass`/`drygrass` (9.0→6.0) and re-rendering showed the SAME
clump centres (unmoved — `clump_radius` doesn't reposition a clump, only how
far its instances spread from it) simply stopped reaching that particular
path stretch at the tighter radius, so the frame went from "flowers read as
uniform" to "no flowers visible near the path at all" — trading one named
defect for a different, arguably worse one, without a second blind pass to
confirm it was actually better. Reverted rather than shipped on a guess; see
`EV3-remainder` for the more promising untried lever (`path_bias` on
`flowers`, not `clump_radius`).

**Honest gap to the item's full bar.** `EV3`'s own done-when — "a blind
critic stops calling the scatter generator output" — is not reached. This
slice fixed one concretely-diagnosed defect and validated one already-named
density lever; it did not attempt "elevation" or "landmark-distance"
placement biases from bible §7C (neither exists as a mechanism yet, only
`ridge_bias` and the new `path_bias`), and did not touch the two issues the
critic ranked ahead of anything in this item's own area. `EV3-remainder`
carries the rest forward rather than this entry claiming a pass it did not
get.

**Shipped by direct fast-forward push to `main`, not through the normal
`ralph/**` → CI → merge path** — `tools/ci/ship_branch.sh`'s own instruction
once a branch is over the rebase cap, the same precedent `LP3` set (see its
entry below). `ralph/EV3` hit a genuine, reproducible `ralph/DONE.md` conflict
on every rebase attempt (three, the cap) because `main` kept moving faster
than the ~5 minute CI cycle could catch up to (a neighbouring lane pushing
four separate `EV4-hillside-seam` WIP commits inside 30 minutes, plus a merged
PR, plus `LP3`/`NP3`/`EV4-textures-lighting` all landing in the same window) —
a conflict-then-abort never dispatches a new CI run, so the rebase-attempt
counter (`ship_branch.sh` counts dispatched `workflow_dispatch` CI runs since
the branch's last author push) never advanced past the point of the first
conflict; the automated path would have retried the identical conflict every
ten minutes forever. Confirmed via `ralph-sweep.yml` run `31545945642`'s own
log: `ralph/EV3 conflicts with main and cannot be rebased automatically. A
human or a firing has to resolve it.` **Also fixed the same conflict for every
branch queued behind it in that sweep** — the sweep script's own loop stayed
on the checked-out `ralph/EV3` tree after the failed rebase instead of
returning to `main`, so `ralph/EV4-hillside-seam`, `ralph/EV4-textures-lighting`,
`ralph/EV4-textures-remainder`, `ralph/EV9` and `ralph/LP3` all failed the
same run with `tools/ci/ship_branch.sh: No such file or directory` (that file
did not exist on `ralph/EV3`'s own tree, since `LP4` landed on `main` after
`ralph/EV3` branched) — landing this branch directly clears that queue for the
next sweep too. Code diff verified unchanged from the last green CI run
(`31542718904`, `f6c2a878`) before pushing — only the rebase base moved, no
new code. Dispatched `release.yml` manually afterward, same reason
`ship_branch.sh`'s own last step exists.

## SA6 — Separate the five birds by palette
`9375ab9`. `tests: smoke_art` (green, local + import). No Meshy spend —
`grade.py`'s repair path, `SPECIES["pipwing"|"duskhush"|"galecrest"|
"reedwing"]` each gained a `palette` block. Their `eye_guard` rects already
existed (structural work from an earlier pass, full quadrant-by-quadrant
scans, 2-5 rects per species) — this item only had to add the colour.

Measured each installed 2048×2048 `base_color` atlas directly (numpy, via
`grade.py`'s own `rgb_to_hsv`) before writing anything. Pipwing: 50% of
saturated texels in the 160-200° hue band (teal/cyan) — shifted to ochre/gold
(hue_toward 42°), existing tan enriched, a charcoal accent added for the
third named colour. Duskhush: 67.5% in 15-60° (warm brown/gold, "pale
cream-and-brown" per the backlog's own diagnosis) — shifted to cool
slate/lavender-grey (hue_toward 222°/250°), amber eyes untouched by
construction (the op only ever sees texels the guard rects don't cover).
Galecrest: 35.8% in 180-200° (blue-grey) plus 55.7% warm tan — shifted the
blue to rust/chestnut (hue_toward 16°), the warm band deepened toward
chestnut, dark plumage desaturated toward charcoal, pale chest warmed toward
sand. Reedwing was never named broken (teal already present, ~38% combined
across 140-200°) — an ENRICH pass, not a rotation: existing teal deepened
(hue_toward 182°, saturation×1.25), existing tan pushed toward copper
(hue_toward 24°). Galewisp untouched, per spec. Ran for real on all four,
not dry runs; eye guard confirmed 0.00 delta inside every rect on every
species.

**Two real bugs found and fixed mid-pass, both from actually rendering the
graded models rather than trusting the raw texture average — this is the
part worth reading before anyone touches `grade.py`'s birds again:**

1. `hue_toward`'s interpolation is linear, not circular. A first pass at
   `hue_amount` 0.85-0.88 left Pipwing with a real residual 60-80° olive
   band instead of clearing into gold, because a 220° source pixel moving
   88% toward 42° lands near 63°, not 42°. Raised to 0.97 across all four
   species so the residual spread stays inside the target family regardless
   of where a given pixel started.
2. Galecrest's first "dark plumage -> charcoal" op pushed `hue_toward 220`
   (blue) on top of a `saturation_mul` that didn't fully desaturate —
   which repainted exactly the slate-grey mottling the pass was trying to
   remove, but only inside the darkest feathers (value 0.12-0.38), because
   by the time that op ran the main blue-to-rust op had already fixed the
   *lighter* wing texels and this one was re-darkening a fresh blue onto
   what it should have been neutralising. A whole-texture hue histogram
   never caught this — the wings are a small fraction of the UV space — a
   rendered close-up crop did. Dropped the hue push entirely; the fix is
   `saturation_mul` alone.

Also found: Godot's glTF importer bakes the extracted texture into the
imported `.scn` at GLB-import time. Editing the loose PNG under `models/`
and re-running `--headless --path . --import` is NOT enough to see the
change rendered — the standalone texture's own `.ctex` cache refreshes, but
the mesh's material inside the cached `.scn` does not. Deleting the specific
`.godot/imported/pal_<species>_lod0.glb-*.scn` file (path is in the GLB's
own `.import`) before reimporting is what actually picks up a texture edit.
Cost real time to find on this item; every future loose-texture regrade
should expect it.

**Two local blind-critic rounds**, general-purpose sub-agents shown only
`tools/capture_species_closeup.gd`'s colour and silhouette renders (all five
species, no labels, no context) — no working in-repo sub-agent-spawn tool
was found in this checkout either, matching `EV4-textures-lighting`'s same
finding, so this is a rigorous blind pass via a spawned agent rather than
the visual-judge skill's own sub-agent path, recorded honestly rather than
hidden. Round 1 caught bug 2 above (the critic still named Galecrest and
Galewisp as colour-confusable) and named a framing crop bug in the capture
tool (fixed: the two-species framing constant didn't scale to five). Round 2,
after both fixes: Galecrest now described as "warm brown-tan and rust
mottled feathers, cream chest, dark wingtips" and NOT grouped with Galewisp
on colour — the pair the backlog itself called "the most broken and the
easiest to fix" is fixed and confirmed.

**Remainder, not chased further — a spec tension, not a bug:** Duskhush
(slate/lavender-grey, per spec) and Galewisp (unchanged, per spec) still sit
in the same broad cool-toned family and the round-2 critic named them as the
closer pair now ("under flat lighting or at distance they'd read as
colour-siblings"), though it did not call them confused outright. Both
species' target colours are cool by design — closing this further would mean
pushing one of them off its own named spec palette, not fixing a defect.
Separately, the same critic noted Galecrest and Galewisp share a spread-wing
display *pose* at two different scales — a modelling/animation observation,
out of a palette-only item's scope.

`tools/capture_species_closeup.gd` copied from `SA5`'s own (unmerged as of
this writing) branch, which built it for exactly this next task and said so
in its own header comment — not rebuilt from scratch. Framing multiplier
0.72 → 1.65 (the original was tuned for SA5's own two-species pair and
cropped the outer creatures once five stood in the row).

## LP3 — release.yml's own concurrency setting was starving the download build
`dd72a2a`, landed by direct fast-forward push to `main` per `tools/ci/ship_branch.sh`'s
own instruction (see below) — not a bypass of the "never push to main" rule,
the fix `LP4` shipped is what tells a firing to do exactly this once the cap
trips.

**The bug:** `release.yml`'s `concurrency: cancel-in-progress: true` killed
whatever Release run was currently in flight the instant a new push landed to
`main`. The job's real work (Godot install, import, export, boot-check the
exported `.exe`, package, publish) takes several minutes — far longer than the
gap between pushes once multiple Ralph lanes land concurrently by design.
Found by checking pipeline health first, per the updated `PROMPT.md`: the
published release's `published_at` was over a week stale (`2026-08-03`)
despite dozens of real commits landing on `main` since — D23/D24, EV1–EV10,
NP1–NP4 among them. A sampled cancelled run's job log confirmed it directly:
killed 14 seconds after starting, still on checkout, every later step skipped.
Fix: `cancel-in-progress: false`, so runs queue instead of dying — every push
either finishes or waits its turn.

**Shipping this one-line fix took roughly three and a half hours and became
its own investigation.** `ralph/LP3` went through 15 rebase cycles chasing
`main` as it moved under a green-CI branch that could never fast-forward. This
firing's own repeated manual `ci.yml` redispatches (via the GitHub API, a
different token identity than the bot's own `gh workflow run` calls) kept
producing completions that DID trigger `ralph-merge.yml` — while every
bot-dispatched completion silently did not, a clean, repeated pattern across
every single rebase cycle. That observation matches `LP4` exactly (see below,
shipped independently mid-firing by an owner-directed session): the
`GITHUB_TOKEN` recursion guard blocks `workflow_run` from firing for a
`workflow_dispatch` run that same token initiated, so `ralph-merge.yml`'s own
rebase-and-redispatch healing loop could dispatch CI but could never see it
finish. `LP4`'s fix (`ralph-sweep.yml` + `tools/ci/ship_branch.sh`'s `MAX_REBASES`
cap) landed on `main` mid-struggle, but `ralph/LP3` had already accumulated
more rebase attempts than the new cap allows before the fix took effect, so
`ship_branch.sh` stopped it with an explicit "A human or a firing has to land
it" rather than burning another CI run. Rebased `ralph/LP3` onto `origin/main`
locally (clean, single-file diff, no conflicts), verified the diff was
exactly the intended one-line change, and fast-forward-pushed directly —
the same action the script itself takes, just run by hand once the automation
declined to. Dispatched `release.yml` manually afterward for the same reason
`ship_branch.sh`'s own last step exists: the push that lands on `main` cannot
trigger it on its own.

**Worth knowing for whoever watches the next Release run:** confirm
`published_at` actually advances past `2026-08-03` — that's the real proof
this works, not just the merged diff.

## SA2-flake — `smoke_opening` beat-4 flake: a pattern fix, same shape as LP2
`tests: smoke_opening`, green locally 31/31 across this firing (19 with the
fix applied, 12 on the unmodified pre-fix test as a baseline check) — but see
below for what that number does and does not prove.

**Picked up because it was caught live, not just read off the backlog.**
Before claiming this, `main`'s latest completed CI run (`31544774295`, on
`525ffa28`) had failed at "Smoke-test the opening" with exactly the string
this item's own description names: *"confirming an orb with `menu_confirm`
did not close the picker; beat 4 does not advance."* Read directly from the
job log, not inferred from the backlog text — confirmation this is a live,
currently-red symptom, not a stale description of something that stopped
happening.

**Root cause, found by reading `starter_picker.gd`, not by guessing.** Its
`_physics_process` is a single `if`/`elif` chain, all three branches gated on
`Input.is_action_just_pressed`:

```
if Input.is_action_just_pressed("ui_right"):
	_move(1)
elif Input.is_action_just_pressed("ui_left"):
	_move(-1)
elif Input.is_action_just_pressed("menu_confirm"):
	_confirm()
```

Nothing here is a real Godot `Control` — no `_gui_input`, no `grab_focus`, no
focus navigation of any kind. It is a plain poll, same shape for `ui_right`/
`ui_left` as for `menu_confirm`. But `smoke_opening.gd`'s beat 4 was sending
`ui_right` via `_press()` — the belt-and-braces helper that sends BOTH
`Input.action_press()` AND a parsed `InputEventAction`, which
`_press_polled()`'s own docstring already documents (from `LP2`) as capable of
registering "just pressed" a physics frame LATER than the action-state path
under load. `starter_picker.gd` doesn't need the parsed event at all — it
never reads one — so the second signal is pure redundancy for this reader,
and if its late registration lands on the SAME physics frame as the very next
`menu_confirm` press, the `elif` chain checks `ui_right` first and the
`menu_confirm` branch is never reached — for the one frame `menu_confirm` was
ever going to read as "just pressed." That is the exact observed symptom:
`_confirm()` never fires, the picker never closes.

`name_prompt.gd` (beat 5) was checked for the same shape and does NOT have it:
its direction handling (`_tick_cursor`) reads `Input.is_action_pressed`
(continuous, not edge-triggered) and runs unconditionally, separate from the
`menu_confirm`/`menu_cancel` `if`/`elif` — there is no branch for `ui_right`
in that chain to steal the slot from `menu_confirm`. So this fix is scoped to
beat 4 only; beat 5's presses are untouched.

**Fix:** `tests/smoke_opening.gd`, beat 4's `await _press("ui_right")` →
`await _press_polled("ui_right")` — the same fix shape `LP2` already used for
beat 3's `interact`, applied to the one other place in this file sending a
real reader's redundant parsed event.

**Honest about what local testing does and does not prove, matching `LP2`'s
own precedent exactly.** 19 runs with the fix applied all passed. As a
control, 12 runs of the unmodified pre-fix test *also* all passed locally —
this race does not reliably reproduce under this environment's conditions
either way, the same experience `LP2`'s own entry already recorded for a
different beat of this same test after three separate forced-repro attempts.
The fix is shipped on the strength of (1) a real, structural bug found by
reading the code, not guessed at, (2) an exact precedent already proven in
this file (`LP2`), and (3) the failure reproducing for real on `main`'s CI
with the exact predicted signature just before this was picked up. If
`smoke_opening` flakes again on beat 4 with this same message, that is new
information — either this was not the whole cause, or CI's timing hits a
window local runs do not — and the next firing to see that recurrence should
re-open this rather than assume it is solved.

## LP4 — Green branches were silently never merging; four were stranded
Owner-directed interactive session, 2026-08-11. See `D26` for the full record.

Reported by a lane as *"a dispatch gap in the merge workflow"* on
`EV4-textures-remainder`. Right that something was broken, wrong about the
scope and the mechanism.

**`ralph-merge.yml`'s rebase path could never merge anything.** It rebases a
branch that `main` moved under, force-pushes, and dispatches CI with the default
`GITHUB_TOKEN`. The dispatch works — `workflow_dispatch` escapes GitHub's
recursion guard. The *completion* does not: no `workflow_run` event is raised
for a run initiated by that token, so nothing ever woke up to merge the branch
it had just rebased and re-tested. Escaping the guard on the way in does not
escape it on the way out. Same guard that left `release.yml` unfired for twelve
hours and twenty-five commits.

**The evidence separates the two paths exactly.** Every live branch whose latest
green CI run came from a `push` had merged (`NP3`, `NP3-bookkeeping`, `SA2`,
`EV3-path-stones-note`, `lease-file-legibility`). Every one whose green run came
from a `workflow_dispatch` was stranded (`EV3`, `EV4-textures-remainder`, `EV9`,
`LP3`). Under ~10 lanes the rebase path is the COMMON path, because `main` moves
during most 5-minute CI runs.

Shipped: `ralph-sweep.yml`, a ten-minute reconciler that lists `ralph/**` and
ships any branch whose tip has a completed green run and fast-forwards — no
event required. Ship logic extracted to `tools/ci/ship_branch.sh`, called by
both workflows. Rebase cap of 3 (the `ralph-merge.yml` comment had asked for one
in advance; `LP3` hit six), counted since the branch's last author push so a
fresh push is a fresh start. And the rebased sha is checked for an existing
green run before dispatching, which was the `EV3` double-dispatch.

**Not confirmed live yet, and it cannot be from a branch.** Scheduled workflows
and `workflow_dispatch` only run from the DEFAULT branch, so the sweep does
nothing until this lands on `main`. The four stranded branches are still
stranded until then — `LP3` fast-forwards as-is, the other three need the rebase
route. First sweep after merge is the real test; watch that it ships those four
and leaves red `CO1` alone.

## SA5 — Recolour Burrowback away from Terrapup
`tests: smoke_art` (green, local + import). No Meshy spend — the repair path,
`grade.py`'s `SPECIES["burrowback"]`, gained a `palette` block; geometry and
Terrapup are both untouched.

Measured the installed 2048×2048 `base_color` atlas directly (numpy, through
`grade.py`'s own `rgb_to_hsv` so the thresholds match what the grade actually
sees) before writing anything: 83% of it sits in one 30–45° warm-brown hue
band — Terrapup's own fur family, confirming the backlog's diagnosis that only
body shape separated the two. Partitioned that one family by VALUE/SATURATION
rather than hue, five ops in order: the main coat (hue 20–55°, `sat≥0.28`,
`value<0.55`, 83% of the measured pixels) crushed toward charcoal via
`value_mul 0.42`/`saturation_mul 0.28`; a lighter, still-saturated band the
coat op's own value ceiling leaves untouched pushed toward a restrained
rust-brown (`hue_toward 18`, `saturation_mul 0.85`, `value_mul 0.80`) rather
than brightened, so it reads as an accent and not a highlight; the golden/
moss-fleck class (hue 45–70°, the "moss-and-stone mantle" R9.4's render
named) muted toward a low-weight cool grey-green instead of removed outright,
matching the brief's "minimal green" rather than "no green"; the low-
saturation mid-value stone texels blended toward a fixed slate; the brightest,
lowest-saturation band (nothing in this atlas sits above albedo value 0.8) —
the face stripe — blended toward a cool pale grey instead of Terrapup's warm
cream. Each op's own numbers were checked to confirm its output falls outside
every later op's selector range before ordering them, so nothing gets
processed twice by accident.

Ran for real, not a dry run: mean albedo value 0.368 → 0.218, a large
measured shift; eye guard confirmed 0.00 delta inside its rect (`grade.py`'s
own check).

**Blind-judge pass, one round, converged outright.** Wrote
`tools/capture_species_closeup.gd` (two named species side by side, tight
framing, plus a silhouette pass — reusable for `SA6` next, which has the same
"the roster row is too small to judge colour by" problem `preview_creatures.gd`
carries). A genuinely blind sub-agent, shown only the colour and silhouette
frames with no labels: described the left creature as "grey/black-masked...
amber eyes... long low badger-like silhouette" and the right as "warm brown...
teal eyes... compact, tall, big-eared cub-like silhouette," and answered
directly — "Two clearly different creatures... this isn't a subtle recolour,
it's a distinct build and face structure." No defect named against either
model. One out-of-scope observation kept for whoever next touches either
creature's mesh: the moss-fleck shoulder patch sits in near-identical
placement/shape on both bodies, "like the same decal/overlay pasted onto two
different bodies" — a shared-topology/UV artefact from the two models'
lineage, not something a colour-only grade can reach, and not chased here.

`tools/capture_species_closeup.gd`'s first run wasted ~2 minutes: passed
`--headless` alongside `xvfb-run`, which disables the real display driver
rendering needs under this renderer — `preview_creatures.gd`'s own doc
comment omits `--headless` for exactly this reason; missed it once, corrected.

## NP3 — The named Meadows cast: identities for Mira/Oskar/Tam, plus the Quarry Foreman and the Rescued Ranger
`f6c27f6`. `tests: tests/run_tests.gd` (299/299, `test_dialogue_runner`'s 12
included). Visual-affecting (two new bodies added to the village square): a
blind `.claude/skills/visual-judge` pass ran, entirely local, against
purpose-built close-up frames of the two new NPCs (`scratch/np3_capture.gd`,
not committed — throwaway per `conventions.md`'s scratch/** rule).

**Scoped down from a literal reading of the spec bullets, on purpose.** The
spec text under §35 that names Mira/Oskar/Tam ("introductory trainer battle,"
"reward: South Bridge Key," etc.) actually belongs to §12, a different
section — checked directly. §35 itself, the section this item's own name
points at, only asks for identity: which reused rig, which palette. Real
trainer combat needs `R8.1` (a whole substrate: trainer-vs-player battle
triggers, a trainer roster/AI, item/TM/key-item data that doesn't exist yet)
plus `SC12`–`SC15`, all separately staged later in the backlog behind
levelling (`R4.1`) and movesets (`R4.3`). Building that under `NP3` would have
been a large, wrong-shaped item; this instead gave Mira ("Meadow Keeper"),
Oskar ("Bridgehand"), and Tam ("Field Scout") one identity/foreshadowing line
each in `data/dialogue/village.json`, with **no** battle offer, reward, or XP
— none of that is testable by `test_dialogue_runner` (the test this item
names, confirmed by reading it: purely a dialogue-data validator) and all of
it stays tracked under `R8.1`/`SC12`–`SC15`.

**Added two new reused-rig villagers** per §35's own list: Quarry Foreman
(Grandpa's rig, dark stone/workwear tint, `villager_quarryman` in `art.json`)
and Rescued Ranger (trainer rig, `villager_ranger`), placed via the existing
`village_npcs.json`/`village_npcs.gd` pipeline (`NP1`/`R7.2`) — positions and
`facing_deg` computed with the same atan2-to-well formula reverse-engineered
from Mira/Oskar/Tam's own existing data (verified to reproduce their values
to 1 decimal place before trusting it for new ones), each 5m+ clear of every
structure and every other villager.

**A real defect, caught before push, not asserted.** The Ranger's first tint
was `#2c7a78`, the teal the spec names as its first option. Rendered, it came
out a saturated green nearly indistinguishable from Oskar/`villager_keeper`'s
existing `#4f8a5b` — both readable as "green" despite quite different hue
math, because `character_model.gd`'s emission-multiply tinting mechanism
(documented there since `NP2`) multiplies onto a base texture region with a
strong green bias, and Tam's blue (`#3f5a8c`) survives that same multiply
fine while teal didn't. Moved to the spec's own named alternative, a pale tan
(`#c2a878`) — a light, desaturated neutral rather than another saturated hue
fighting the same bias — and a fresh render confirmed it reads as warm tan,
clearly distinct. A genuinely blind sub-agent critic (no knowledge of the
teal attempt or anything else in this session) then verdict on the corrected
frames: "pass as legible, distinct-enough additions" against the rest of the
cast. It separately flagged that the Foreman and the Ranger's palettes still
both sit in a narrow earth-tone band with no role-signalling prop (no
hard hat, no bow) — real, but explicitly scoped by the critic as a
roster-wide material/prop-pass question, not specific to these two, and not
chased further here.

## EV4-textures-lighting — Two different causes hiding under one "unmotivated shadow" description; the blown highlight was the fixable one
`bd680b3` (config-only: `data/config/art.json`) · `tests: none (visual)` named,
`smoke_art`/`smoke_traversal` also run locally since this touches the shared
`environment` block (both green) · local blind-pass rounds, all rendered and
critiqued in this checkout before the single push, per `conventions.md`.

Root-cause leads from the backlog entry pointed at two places: `SA1`'s
shadow-atlas cut, and `art.json`'s exposure/energy. Neither guess survived
contact with instrumentation, and the real split was between the two named
frames, not within either lever.

**`square-convergence.png`'s dark diagonal is a real occlusion shadow —
confirmed, not assumed.** Toggling `sun.shadow_enabled` off on that exact
viewpoint made the whole shape disappear; toggling it back on reproduced it
pixel-for-pixel. It comes from the Barn, 6m from that viewpoint's camera —
a scratch node dump (position/AABB, no rendering) found the barn's own
6.6m-tall footprint sits close enough that its shadow reaches the camera at
the sun's current 44° elevation. `SA1`'s shadow-atlas cut is **ruled out**:
raising `directional_shadow/size` from 2048 to 4096 at runtime
(`RenderingServer.directional_shadow_atlas_set_size`) produced a
pixel-identical edge, not a sharper one. The shape isn't blurry because the
atlas is small; it's blurry because that's genuinely how large and soft a
barn's shadow is at this range and sun angle.

**`grandpas-house-route.png`'s flanking bands are NOT a shadow at all.**
Same toggle test: identical with `shadow_enabled` true or false. Also
identical with SSAO on or off. A pure-heightfield diagnostic (`slope_degrees_at`,
no scene load) found the ground there measures dead flat — 0.0° across the
whole sampled width, so there's no normal-facing-away-from-sun explanation
either. Direct pixel sampling settled it: ordinary grass at luma ~70-100
sitting directly against a path blown to ~190-200 reads as "a shadow with no
caster" purely by contrast, even though the grass pixels themselves are
unremarkable and match grass luma everywhere else in frame. Confirmed by
flooding `ambient_light_energy` to 6.0 as a one-off probe: the "band"
visibly thinned along with everything else compressing toward white under
ACES, which a true occlusion shadow would not do.

**The fix that reaches both: de-blow the highlight.** `near_luma`
(`tools/frame_stats.py`, mean luma of the bottom 15% of frame) measured 0.692
on `grandpas-house-route` against Palworld's own 0.419-0.600 range, and the
sunlit path itself sampled at ~197/255. A modest exposure trim did almost
nothing — 1.22 → 0.95 moved the sampled path pixel by 0/255, because ACES's
highlight shoulder is essentially flat at this operating point; it took a
real cut to 0.6 (`day` inherits the base `environment` block; `golden` and
`night` already override `exposure` explicitly and are untouched) to bring
the path to ~151/255, inside Palworld's range, and `near_luma` down to 0.504.
`ambient_energy` 1.02 → 1.5 gives back some of the shadow floor (measured:
tripling ambient moved the sunlit path only ~197→215 but moved the Barn
shadow's floor ~15→40, because ambient is a much larger fraction of what a
shadowed point receives) — a deliberately smaller step than that, because a
bigger one measurably crept back into the sunlit path once stacked with the
exposure cut, undoing the highlight fix it was supposed to complement.

**Two further rounds tried to soften the Barn shadow's edge specifically
(the backlog's "tonally abrupt" wording) and both went flat**, which is why
this stopped at two: `shadow_blur` 1.0 → 3.0 plus a further `ambient_energy`
1.5 → 1.8 changed the sampled shadow edge by single-digit luma (~17→21,
noise-level); `light_angular_distance` 0.6 → 4.0 on top of that changed
nothing visible at all. Both are consistent with `docs/decisions/D01`/D06's
Compatibility renderer not implementing the soft-shadow machinery those two
properties drive under Forward+ — worth re-testing on real hardware
(the shipped renderer) rather than concluding the levers themselves are
dead ends.

**Did not fully clear the bar.** A self-administered rubric pass (see below)
still named the Barn's shadow in `square-convergence.png`, and a *second*,
previously-undiagnosed instance in `the-rise-route.png` — that one traces to
real terrain self-shadowing from the Rise's own nearby crest (a genuine
occlusion shadow, confirmed by the same slope diagnostic showing the local
ground is real but modestly sloped, not flat), not to the Barn. Both are
physically motivated shadows, not artifacts, and both are reduced in
apparent severity by the highlight fix (less contrast to be judged against)
but not eliminated. Reaching further needs either a sun-angle change (already
a carefully-negotiated tradeoff — see `R9.4`'s pitch history in this same
file — between terrain-form contrast and shadow length) or a scene-level
change (moving the Barn, reshaping the Rise's crest), neither of which is a
`lighting`-scope config edit. Recorded as `EV4-textures-lighting-remainder`
in `BACKLOG.md` rather than pushed further here.

**Process note: no sub-agent-spawn tool was available in this checkout.**
`conventions.md` and this item's own instructions call for a blind critic
that never sees the diff. The `visual-judge` Skill loaded its rubric into
this same session rather than dispatching an isolated agent, and no
`Agent`/`Task`-equivalent tool was present to spawn one by hand (checked via
tool search before proceeding). The rubric pass recorded above was run as
rigorously as this session could manage — full rubric, no leading language,
genuinely re-examining the frames rather than confirming the fix — but it is
not the blind read the process calls for, and the next firing with that
tooling available should re-run it properly against
`shots/paths/*.png` before trusting this item's "did not fully clear the
bar" verdict as final.

## EV2-trunk-colour — Bark retint compensates for a cool ambient wash
`fda64dc`. `tests: full suite` (299/299). Visual-affecting: a mandatory
blind `.claude/skills/visual-judge` pass ran against the standard
`tools/survey.sh` 5-frame set after the fix.

**The item's own guess (minification) was wrong, found by testing it
directly rather than assuming it.** Rendering the same trunk at point-blank
range — full texel resolution, nothing to minify — still showed the pale
salmon/pink colour, which rules distance out immediately. Zeroing
`art.json`'s `ambient_light_energy` on the identical shot moved the colour
most of the way back toward true brown, isolating the real mechanism:
`ambient_colour` (`#a8bccc`, a cool blue-grey deliberately tuned by an
earlier fix for GROUND shadow legibility) washes warm surfaces toward pale
and neutral, and thin curved trunk geometry draws a disproportionately
large share of its total light from that ambient fill compared to a flat
ground plane, which receives most of its light from the direct sun instead.

Couldn't recolour ambient globally without re-risking the ground fix it
exists for, so used the same lever the `rocks` layer already carries for
the identical class of problem (a source measured as warm/neutral, washed
toward the wrong hue by scene lighting): added `Bark_NormalTree` and
`Bark_TwistedTree` entries to `vegetation.json`'s global `retint` map.
Values solved from the measured per-channel gain (rendered ÷ source texture
colour, sampled directly from a close-up PNG) against a believable-brown
target, then verified by reading `albedo_color` straight off the actual
scattered `MultiMesh` material in a running scene — not by trusting a
render, after an early attempt rendered a manually-`load()`ed tree that
never went through `vegetation.gd`'s retint pipeline at all and showed no
change, a wrong turn caught by checking the data instead of the picture a
second time. `Bark_DeadTree` left alone: it already carries its own
separate tint and grey dead wood was never the reported bug.

**Blind pass converged in one round**, in the sense that matters for this
item: a fresh critic, told nothing, did not name trunk/bark colour as a
defect anywhere in five frames — the thing it was reliably naming
unprompted in `EV2`'s own rounds 1 and 2 is gone. The same pass surfaced a
long list of other findings (value/lighting range, scatter density and
clustering, no groves, no water, a creature-art style mismatch, a handful
of concrete render artefacts), but essentially all of it duplicates
already-open backlog territory rather than naming something new:
value/lighting range and horizon haze is `EV8`'s (shipped) and `EV10`'s
remit, empty/uniform scatter is `EV3`, no groves is `EV2-landmark-ceiling`,
water is `EV5`, and the creature-art style mismatch is the same question
already sitting in `BLOCKED.md` ("Does the creature roster clear a
Palworld-level appeal bar"). Checked rather than assumed: the "flat unlit
violet tower" finding is the landmark stronghold silhouette, sampled at
RGB(81,77,99) — a muted dark slate, not the loud violet the critic's prose
suggested, and deliberately unshaded by `landmark.gd`'s own design (so
atmosphere never washes it out) — not a new bug. Not opening a new backlog
item for any of this; it would just be duplicate bookkeeping for existing
entries.

One genuinely new, minor observation, not worth its own item: the
`04-three-quarter` survey viewpoint's fixed camera sits close enough to a
scattered boulder to show its near-clip face filling the bottom of the
frame in a way that reads as a translucent dome. This is a fixed-viewpoint
composition artefact of that one survey camera position under this
deterministic scatter seed, not a confirmed gameplay-visible bug — the
real third-person camera orbits and is not fixed to this spot. Worth a
glance if `tools/survey.gd`'s viewpoints are ever retuned, not urgent on
its own.

## EV4-textures-remainder — Moss blobs reshaped from circular stamps to varied streaks (partial)
`tools/art_pipeline/reshape_moss_blobs.py` (new) · `tests: none named, smoke_traversal
run anyway as a sanity check on the terrain rebake, green` · two local blind-judge rounds

**Root cause matched the item's own diagnosis exactly.** The moss patches in
`Ground030_Color.jpg` (already desaturated by `EV4-textures`' shader-level
fix, untouched by this) are near-circular, similarly-sized, semi-regularly
spaced photo content — real content, not a tint/blend bug, so no shader lever
could reach it.

**The fix: reshape the source photo directly, not the shader.**
`reshape_moss_blobs.py` detects each moss blob (green-dominant colour mask,
connected components via `scipy.ndimage`), then for each of the 52 blobs
`>=60px` (the visually real clumps; smaller ones are fine background speckle,
left alone): stretches it along a random per-blob axis (1.7-3x), narrows it
perpendicular (reads as an elongated streak, not a bigger circle), roughens
the boundary with coarse noise, feathers the edge, and blends at a per-blob
strength for density variety. Deterministic — seeded per blob id, so a re-run
reproduces the identical output. One real bug caught before landing: a flat
45px patch margin clipped the stretched tail on the biggest blobs, so the
most visible ones barely changed in a first pass — fixed by scaling the
margin to each blob's own half-extent times its own elongation factor.

**Round 1 (stretch + narrow + edge roughening) — closed the original
complaint.** A blind critic, told nothing about what changed: "no perfect
geometric circles... edges consistently soft, not stamped... that specific
complaint [hard-edged decal] is not present anymore." Genuinely fixed, not
asserted.

**Round 1 also surfaced two follow-ons, one addressed, one deliberately
not:**
- **Shape variety still thin** ("nearly everything else is a soft
  round-to-oval blob... needs 2-3 more distinct silhouette variants").
  Addressed in round 2: added a per-blob asymmetric taper (biases the edge
  threshold along the stretch axis so ~60% of blobs fray into a wisp at one
  end while staying fuller at the other — a comma/flame silhouette instead
  of a bigger ellipse; ~40% stay untapered for genuine variety rather than
  one uniform new style).
- **A second, visually distinct class of grey-green fibrous "tuft" blobs**
  (texture/luminance-variance driven, not colour) reads as repeating across
  world locations — inherent to tiling a single 1024² texture, and this
  fix's colour-based detector structurally can't catch them (confirmed: a
  stricter local-variance detector found only small, unreliable partial
  cores, not clean full silhouettes — the fibrous edge fades gradually
  rather than having a clean colour boundary). **Deliberately not touched**:
  a global two-class detector risked false positives across the whole
  photo, and the earlier `EV4-textures` saturation fix already targeted the
  same green mask this fix does, which is evidence "moss" means the green
  class specifically, not the tufts.

**Round 2 (taper) — real but only partial movement, and this is where the
pass stopped.** A second blind critic, also told nothing: the hard-edge
complaint stayed resolved, but shape variety was still called limited —
"still reads as one repeated template (a soft round/oval dab)... a viewer
would register 'the same splotch, resized.'" Exactly one patch out of ~15
surveyed was called out as genuinely asymmetric/elongated; the rest still
read as round-to-oval. **Stopped here rather than pushing a third round**:
this matches what the item's own text predicted going in — "no colour/tint/
normal_depth lever reaches this; it would need... a re-worked moss layer" —
and round 2 is direct evidence that even a real, working geometric warp on
one source photo can only partially deliver genuine silhouette *variety*
(as opposed to irregularity), because every blob is still fundamentally a
deformed copy of the same handful of source shapes. Real hand-authored moss
variants would need actual new texture content, not more procedural tuning
of this one photo — out of scope for a `low priority... finish question`
item. No new remainder opened; the honest state is recorded here and in
`docs/ASSET_LEDGER.md`'s `Ground030` row.

Terrain rebaked (texture-content-only change — confirmed no control-map or
height diff via `git status`). `smoke_traversal` green both rounds (248m
furthest, 0 airborne frames, unaffected by a colour-only texture edit).

## NP4-rig — Rig, animate and install the three NP4 bases
`tests: smoke_art` (green, local headless + Godot import clean)

`finish.py`'s `rig`/`install` subcommands were creature-only (`RIGS` covers
quadruped/glider/bird/sitter; `install` only wrote
`assets/pals/tetherbound/<species>/models/`). Added a `--kind humanoid` path
to both instead of re-deriving whatever manual process installed the
trainer/Grandpa/Warden originally:

- `rig --kind humanoid` calls out to `meshy.py rig` (Meshy's own auto-rigger
  — the one endpoint that documents itself as humanoid-only) and
  `meshy.py fetch --stage rig`, then runs the existing
  `blender/animate_humanoid.py` locally on whatever skeleton comes back —
  same five procedural clips (idle/walk/sprint/jump/throw) the trainer
  already ships, no new Blender script needed.
- `install --kind humanoid` writes to `assets/characters/<species>/<species>_lod0.glb`,
  matching the trainer/grandpa/warden layout (no `models/` subdir, no
  `pal_` prefix), instead of the creature path.
- No humanoid `grade` step: `grade.py` has no `SPECIES` entries for
  trainer/grandpa/warden either, and `install` already falls back to
  `animated.glb` when `graded.glb` doesn't exist.

Ran all three of `NP4`'s bases end to end, serially: `villager_female`
(`--height 1.75`), `villager_male` (`--height 1.78`), `grunt` (`--height
1.85`, matching the Warden's). Each rigged and animated cleanly on the first
attempt — 15 credits total (4805 → 4790), confirming the backlog item's own
note that this was pipeline plumbing, not an art problem. Verified each
installed GLB directly (parsed the glTF JSON): 1 skin, 26 nodes, and
`['Armature|clip0|baselayer', 'idle', 'walk', 'sprint', 'jump', 'throw']` —
byte-for-byte the same animation-track shape as the existing trainer/
grandpa/warden GLBs, including the same harmless leftover base-layer track
from Meshy's rig export.

Godot headless `--import` ran clean (no script errors); it auto-extracted a
`<species>_lod0_texture_0.png` next to each GLB, same as the existing three
humans — nothing manual needed there, and `project.godot` was not touched so
no `git checkout` was required. `smoke_art` ran green locally
(`art: OK — models loaded, sized to their colliders, and the meadow is
dressed.`) — it doesn't test these three directly since nothing in
`data/config/art.json` references them yet (unchanged from `NP4`'s own
scope note: `NP1`/`NP3` still reuse the trainer/Grandpa/Warden rigs
directly), so this is a clean regression check, not new coverage.

Ledgered all three in `docs/ASSET_LEDGER.md` (the generate/texture stage
from `NP4` had never been ledgered — added now, alongside the rig stage).

`NP4`'s two honest remainders (villager_female's UV-seam shin blotch and
occluded ponytail silhouette; villager_male's cold trousers colour) are
unchanged — this item was pipeline plumbing only, not a re-texture pass.
These three bases still aren't consumed by any live NPC; that's `NP1-geometry`
or a future `NP3`/`NP2`-style item's job, not this one's.

## EV4-textures — moss-blotch saturation and slope-specific edge stepping, three rounds, converged
`912af7f`..`b4e7954` (round 1: tint search; round 2: texture-level moss
desaturation + tint revert; round 3: pushed desaturation further; final:
comment) · `tests: none (visual)`, `smoke_traversal` unaffected (no gameplay
code touched) · local blind-judge pass, three rounds, all rendered and
critiqued in this checkout before the single push, per `conventions.md`.

Narrowed from EV4 round 5's own two remainders. **Slope-edge stepping: never
reproduced as the originally-reported hard staircase.** Instrumented
`_path_control`'s dominant-texture pick directly (a scratch diagnostic, not
shipped) before guessing: only 28 pixels in the entire 512m bake sit in the
genuine overlap zone (path fade band AND natural slope-transition band both
fractional at once), and a dithered version of the dominant pick — shipped
anyway, since it is a real theoretical soft-spot even though this bake
doesn't exercise it (`playground_heightfield.gd`'s new `path_dominant_dither`
noise field, `build_playground_terrain.gd::_path_control`'s new `dither`
param) — changed **zero** of them, confirmed by hashing the baked `.res`
files before/after. Three independent blind-critic rounds on
`tools/capture_paths.gd` never found a clear rectangular-notch staircase
either; round 3 called it explicitly "largely resolved." Closed.

**Moss saturation: fixed at the pixel level, not by fighting it through a
tint.** Round 1's tint-only attempt (blue-lifted near-neutral,
brute-force-searched against the real JPG for the tint that most reduces
moss saturation through the `albedo_color` multiply) measured real movement
but a second critic named a NEW defect it caused: the whole path read "too
pale... closer to bone/sand/chalk," because desaturating moss through a
global multiplier also flattened the dirt's own warmth. Rounds 2-3 instead
locally edited `assets/environment/terrain/Ground030_Color.jpg` itself (CC0,
`ASSET_LEDGER.md` updated) — a feathered mask (hue 65-175°, saturation
threshold tightened 0.20→0.15 across the two rounds) blended the moss
regions toward their own luminance in place, taking the same measured patch
from saturation 0.36 → 0.13 → 0.09, at/below the photo's own ~0.11 baseline.
`tint` then reverted to the original warm `#e4dac2` and `normal_depth` came
back up to 0.22 (from round 5's 0.25) now that the pixels carried the fix
instead of the multiplier. Round 3's critic confirmed real, described
improvement ("no longer hard flat circles... softer-edged and less garishly
saturated").

**Did not fully clear the bar — two remainders opened, one in scope for this
item, one not:**
- `EV4-textures-remainder` (`area: terrain`): the moss blobs' own roughly
  circular, similarly-sized shape and semi-regular scattering — real content
  in the source photo — still reads as "a repeated stamped-decal layer" at
  close range. No saturation/tint/normal_depth lever reaches a shape
  complaint; it needs different or additional moss content, not more tuning.
- `EV4-textures-lighting` (`area: lighting`, **not this item's scope**): an
  unmotivated hard-edged shadow and blown-out highlights on sunlit path
  ground, named independently by all three critic rounds in different words.
  Likely `SA1`'s shadow-atlas VRAM cut, not a path-texture problem. Left for
  `EV8` or whoever owns lighting next; not touched here to stay inside the
  `terrain` area this item claimed.

**Process note for whoever reads the git history on this branch**: mid-task,
a `git reset --hard` run while still on this task branch (chasing the
`ralph-status` lease file on a separate branch) accidentally moved the
branch pointer and discarded uncommitted edits. Recovered via
`git reflog` (the branch's prior tip was one entry back) and re-applied the
lost edits from scratch — no work was actually lost, but it is why this
branch commits in three visible rounds with WIP messages rather than one
clean commit per round, and why every subsequent step in this task committed
locally before doing anything else.

## R9.4-remainder-8 — three of eight findings were real; the rest were checked, not assumed
`55fa8f1` (grass-through-floor + windmill footprint), `8a3fc0c` (barn scale).
`tests: full suite` (299/299, both commits). Visual-affecting: rendered
`tools/capture_buildings.gd` before and after every change, plus one blind
`.claude/skills/visual-judge` pass, per `conventions.md`.

**The discipline that mattered here was cross-checking every claim against
real measurements before acting on it** — pixel measurements against the
1.80m trainer, raw mesh AABBs read straight off the `.obj` files, and a
`placements_for()` probe of the actual scatter — rather than trusting either
the original critic text or the blind-judge re-pass at face value. Half the
list did not survive that check:

**Fixed:**
- **Grass grew through Grandpa's own interior floor and rug.** Root cause:
  grass/drygrass/flowers are deliberately exempt from the wide 16–22m
  `clearings` (so the meadow doesn't go bald near the arena/village square),
  and that exemption had no reason to also cover a building's own footprint.
  Added a second, narrower, unconditional `footprints` list in
  `vegetation.json` that every layer respects regardless of
  `cleared_by_clearings` (`scripts/world/scatter_rules.gd::_inside_a_footprint`).
  Confirmed gone in a re-render, no bald patch introduced around the exterior
  walls.
- **The big Barn was undersized** — its own 0.75 scale, applied under this
  pack's blanket "authored at 2x real size" assumption, put the eave at chest
  height and the door under 1.5m against the 1.80m trainer standing beside it.
  Corroborated three ways: my own pixel measurement, the raw `Barn.obj` math
  (0.75 × 6.01m raw = 4.51m ridge), and the blind-judge sub-agent
  independently. Bumped to 1.1 (→ ~6.6m ridge). `SmallBarn`'s own separate
  correction (0.8 × 4.96m raw ≈ 4m) already read fine and was left alone —
  this pack does not follow one blanket ratio across every model in it.
- **A boulder could spawn against the windmill's own base** — the windmill
  sits at ~22.8m from the village-square clearing's own 22m-radius centre,
  just outside it, so the `rocks` layer (which DOES respect clearings, unlike
  grass) could still land a boulder there. Added a 5m footprint. Verified
  with a `placements_for()` probe: zero rocks within 15m of the windmill now.

**Checked and did NOT reproduce, or were out of scope — recorded so nobody
re-chases them blind:**
- **"Miniature copy of the barn beside the well"** — it's a `ChickenCoop`
  (`village.json` has only one `Barn` entry, no duplicate), correctly scaled
  at 0.9, a different colour from the real barn. Misread as a scaled-down
  barn at a glance; not a bug.
- **"The interior table reads as a 3.5m bench"** — raw `Table2.obj` AABB is
  0.82m tall; at `FURNITURE_SCALE` 0.5 that's a 0.41m table top, genuinely
  *below* the 0.53m chair back beside it (both measured off the mesh, not the
  render). The blind-judge pass repeated this finding from a pixel read of
  the same fixed interior viewpoint, where the table sits ~2.4m from the
  camera against Grandpa's own ~5.7m — a foreshortening illusion of one fixed
  camera angle, not a world-space defect. Same conclusion reached twice,
  independently, by two different methods.
- **"The rabbit (Bramblebun) renders 1.0–1.3m, 2–3x life size"** — it renders
  at its own declared `species.json` height (1.5m), which the wild-roster
  canon (`docs/art/wild/21_MEADOWS_WILD_ROSTER_CANON.md`) explicitly asks
  for: "these Pals live in the same physical scale as the player... do not
  let the roster drift into toy-sized creatures", with Bramblebun named as
  merely the *relatively* smallest, not small in absolute terms. This is the
  same already-open, owner-blocked design question in `BLOCKED.md` ("Does the
  creature roster clear a Palworld-level appeal bar") wearing a scale-shaped
  costume, not an independent bug — resizing a canon creature without an
  owner call is exactly what `CLAUDE.md`'s ask-before-inventing list exists to
  stop.
- **"The windmill is undersized by about half"** — did not reproduce even
  before the barn fix: raw `TowerWindmill.obj` (11.41m) × 0.8 scale = 9.13m,
  already ~2x the *original* undersized barn's 4.51m ridge. (After the barn
  fix above, the ratio is a less dramatic ~1.4x — still taller, which is what
  "clears neighbouring roofs" requires.)
- **Farmhouse windows read undersized** — plausible from the render, but the
  farmhouse is one hand-built `grandpa_house.gd` shell with a single
  Quaternius-cohesion material look; there is no separate window mesh to
  rescale independently of the wall. An asset/geometry question for whoever
  next touches the farmhouse shell, not a `village.json`/`scatter_rules.gd`
  placement fix.

**Not investigated — genuinely open, split into
`R9.4-remainder-8-followup`:** foliage clipping the farmhouse roof ridge, and
boulders sitting proud of the ground generally (distinct from the one
windmill-adjacent instance above, which WAS investigated and turned out to be
a camera-angle artefact of one fixed 45m survey viewpoint, not a real
placement defect — confirmed by comparing the same windmill's base from a
second angle in `buildings/04`, where it reads clean).

**Shipping mechanics worth recording for the next firing hitting the same
wall:** `tools/capture_buildings.gd` genuinely hangs (not just slow) if
`--headless` is added to its invocation — the tool's own header comment never
asks for it, and dropping it fixed rendering entirely (confirmed with an
instrumented scratch script: settle+camera setup completes in under 10
seconds either way; only `--headless` made `await
RenderingServer.frame_post_draw` spin forever with no image ever produced).
Separately, the barn-fix commit needed five rebase-and-repush cycles to land
(955a087 → 7f6881d → ca29fff → a6b2f24 → 8a3fc0c): CI went green on the
identical diff every time while `main` kept moving under it from other
concurrent lanes, and the fourth green run (`a6b2f24`) got no
`ralph-merge.yml` trigger at all — the same `workflow_run`-dispatch
reliability gap `NP4`'s entry documented earlier the same day, confirmed a
second time. Re-ran that stuck CI run via the Actions API rather than pushing
a no-op commit; the fifth push landed cleanly without needing `NP4`'s
manual-push-to-main fallback.

## NP2 — Team Tether rank palettes
`eb7475f` · `tests: smoke_art` (run locally headless: 299 unit tests,
`smoke_art`, `smoke_opening` all green before push)

Grunt/officer/captain/Warden, all on the Warden's rig — the only faction-
appropriate body actually installed (`NP4`'s Grunt textured GLB exists but
has no rigged/installed path into the game yet, see `NP4-rig`, `lane:art`).

**First attempt failed blind review, and the reason why is the real find
here.** A body-tint-only ladder (darkest for grunt, the Warden's own full
brightness at the top) rendered as an almost imperceptible difference —
tracked down to `character_model.gd`'s three human materials all shipping
`emission_enabled = true` with `emission_texture` set to the SAME painted
texture as `albedo_texture`, full-white multiplier. Emission is additive
and lighting-independent, so it completely swamps any `_apply_palette()`
tint. Proved with a throwaway diagnostic: tinting the Warden's
`albedo_color` pure red (`(1,0,0,1)`, confirmed via `body_material()`)
still rendered him fully, unchanged green. **This means `NP1`'s whole
palette mechanism — shipped, unit-tested, believed working — has never
actually been visible on screen.** Its own tests only ever read
`body_material().albedo_color`, never a rendered pixel. Fixed by tinting
`emission` in `_shared_variant_material()` the same way `albedo_color`
already was — one line, and it now benefits every caller, not just this one.

Even with that fixed, a body-brightness-only ladder still wasn't the
answer: round 1 of blind visual-judge called it "a lighting gradient, not a
rank system... someone duplicated a mesh four times and nudged an exposure
value." Real rank marker that shipped: a chest badge using `NP1`'s existing
accessory mechanism, escalating in colour AND size (grey → orange → deep
orange → crimson, small → largest). Hit a second bug getting there —
`_attach_part()`'s placeholder offset/size are set inside the same 0.01-
scale Armature chain `docs/HANDOFF.md` §6 already documents for the giant-
player bug, so a "size 0.13" badge was rendering at 0.0013m, invisible.
Measured the actual scale directly (three offset probes, each landing
almost exactly 100× short of the requested world-space move) rather than
guessing, and compensated in `npc_ranks.json`'s own data — not in the
shared `_attach_part()`, which `NP1`'s hair placeholder also calls and
which this item had no mandate to touch (that would be an unreviewed
visual change to already-shipped work). `BACKLOG.md`'s `NP1-geometry`
entry now carries the same warning for whoever picks it up.

**Three rounds of blind visual-judge**, `tools/capture_npc_ranks.gd`:
round 1 rejected the brightness-only ladder outright; round 2 passed the
badge approach in principle but caught a gold-on-gold collision between
captain and the Warden ("the color plateau between rank 3 and rank 4");
round 3, after moving the Warden's badge to the reserved `tether_oxblood`
red family (`data/config/palette.json`'s own "Team Tether banners,
equipment and uniforms" reservation — he IS that faction's top of it) and
re-tuning officer/captain into a cool→warm→hot ramp, returned "yes, it
works." Two round-3 nits (captain/warden still close, grunt reading as
underlit) fixed inline without a fourth render-and-critique round.

## EV8 (follow-on) — the website capture tool had the same sky-mismatch bug, in a different file
`tests: none named`. Visual-affecting; blind-judge pass run locally on
`shots/site/*.png` (7 real frames) before push. Built in parallel with, and
blind to, the main `EV8` fix below (different lane, same window) — not a
duplicate: this is `tools/capture_site_shots.gd`, a separate tool from the
exploration survey the main fix targeted, so the bug survived independently
of it.

`tools/capture_site_shots.gd`'s `camp-dusk` shot hand-rotated the
`DirectionalLight3D` to a warm colour/angle directly, leaving the sky/fog/
ambient at whatever the `day` preset had last set — the same "sun disagrees
with sky" defect class the main `EV8` entry root-caused for the survey, just
in a tool that scene doesn't touch. Routed it through
`WorldLook.apply_time("golden")` instead, so sun/sky/fog/ambient move
together as one preset. Blind critic (fresh sub-agent, no knowledge of the
change) confirmed `camp-dusk` now reads as "coherent within itself" with no
sun/sky mismatch. It separately named a real but different problem with the
same frame — shadows read as a flat orange multiply with no cool fill,
against the bible's "warm sun, cool ambient fill" — worth re-checking against
the main `EV8` fix's now-higher `golden.ambient_energy` (1.15 → 1.5) and
panorama removal, both landed after this was written; if a fresh blind pass
on the exploration survey (which now uses the updated preset) still shows a
flat-orange golden hour, that is real and not this entry's stale guess.

Went looking for the horizon-band fix independently too (`tools/
diag_horizon_haze.gd`, kept as a diagnostic) and ruled out every fog control
`world_look.gd` exposed at the time (`fog_aerial_perspective`: no measurable
effect under Compatibility; `fog_height`/`fog_height_density`: either no
effect or re-fogs the tuned midground) — correct as far as it went, but the
main `EV8` entry found the actual fix is not a fog control at all
(`world_background = 0`, not a value `diag_horizon_haze.gd` tried because the
existing code comment only discussed `NOISE` vs `FLAT`). No `EV8-horizon`
backlog item needed; recording the ruled-out fog values here in case anyone
lands on this file wondering why `diag_horizon_haze.gd` exists.

## SA2 — Grandpa's exterior door gated until the briefing is heard

`1790ed1`. Spec §1D: the player cannot leave the farmhouse until the required Grandpa
opening interaction is complete. Two pieces:

**The physical stop** — `grandpa_house.gd` now builds an invisible
`StaticBody3D`/`CollisionShape3D` box across the exterior doorway opening
(`_build_door_gate()`), toggled by a new `set_door_open(open: bool)` method.
Invisible rather than a visible closed door on purpose: the file's own header
already explains the door leaf is left open against the wall because a
closing animation is out of scope for the slice, so a second, shut door in
the same opening would read as a modelling error rather than a story beat.

**The gate logic** — `sequence_director.gd`'s new `_refresh_door_gate()`,
polled every frame the same way `_refresh_lockout`/`_refresh_prompts` already
are. Closed while `BEATS.at_or_after(_beat, BEATS.WALK_OUT)` is false, opened
for good the moment it's true (never re-checked backwards, matching the
existing `_set_beat` refusal to move beats backwards) — so it lifts once and
only once, exactly when the sequence would send the player outside anyway.

The one behaviour beyond blocking: an approach within `DOOR_CALLOUT_RADIUS`
(2.6m) of the door marker, while on the `house` beat specifically and no
dialogue is already open, auto-starts Grandpa's briefing — the same
conversation pressing interact on him opens. Spec §1D explicitly rules out a
sterile "talk to Grandpa first" message, so the door itself is the second way
in to the same required conversation.

**Restricted to the `house` beat, not every beat the gate physically covers,
and this was found by testing, not reasoned out in advance.** `choose` and
`name` are also before `walk_out` and the door stays shut through both
correctly, but their own conversations (`grandpa_waiting`, "Still deciding?")
are incidental, not the required one. Triggering the auto-conversation on
every gated beat reopened a fresh conversation the instant the previous one's
box cleared — the player is still standing where the briefing left them, well
inside the callout radius — which starved `_maybe_open_picker()` of the
closed-dialogue frame it needs and the starter picker never opened. Caught by
running the new test locally before pushing, not by CI.

**`smoke_opening.gd`** gained `_the_door_is_gated_until_grandpa_is_heard()`,
run between getting up and the existing Grandpa-approach step: walks the
player down the stairs, via the open floor near Grandpa's own standing spot
(stops 0.8m short of him, same as any `_walk_toward_point` target — not close
enough to touch his collider), then straight at the door marker. A first
version aimed directly from the stairs' foot at the door and made zero
progress for 400 frames — that line clips the corner where the stairs meet a
piece of furniture and the north wall, and a yaw-homing walk wedged into a
real corner is not the same failure as a gate working correctly, so the route
was changed rather than the assertion. Asserts the dialogue is open (no
interact press sent) and that the player stopped meaningfully short (≥0.8m)
of the door marker. `_grandpa_says_his_piece()` immediately below already
knew how to advance a conversation left open on arrival, so no change was
needed there.

**Found in passing, not fixed here:** beat 4's starter-picker `menu_confirm`
flakes intermittently on unmodified `main` — confirmed via `git stash` back
to pre-`SA2` code and running `smoke_opening.gd` headless several times,
roughly one run in three fails there and passes on retry, while `SA2`'s own
door-gate behaviour passed every run. Opened as `SA2-flake` in
`BACKLOG.md`, same class of finding `LP1`/`LP2` exist for.

tests: `smoke_opening.gd`, run headless, locally, multiple times (both with
and without the change, via `git stash`, to separate the new gate's own
reliability from the pre-existing flake). Not full-suite — not an autoload or
save-format change.

## EV8 — Lighting and atmosphere

Two rounds of the blind pass, both entirely local (five renders total, one
push). Closes `R9.4-remainder-2`.

**Root cause of the pale horizon (`R9.4-remainder-2`) was not fog.** Every
outdoor frame showed a large pale wavy dune-shaped mass filling 30-50% of the
upper frame past the 512m bake — not subtle washing, an actively ugly shape,
because Terrain3D's `world_background = 2` (NOISE) continues the terrain
procedurally with visible dune-like relief and no colour/texture control.
`FLAT` (1) was already ruled out (0.146 luminance seam). The untried third
option, `world_background = 0` (NONE) — draw nothing past the bake, let the
real sky show through — turned out to be the fix: `frame_stats` sky% dropped
from ~40-52% to 12-26% across the five exploration frames, inside or near
Palworld's 2-21% reference range, with no seam regression (max 0.09 across
all five, well under the FLAT-mode 0.146-0.18 benchmark).

**Root cause of the sky-treatment inconsistency (EV8's other named defect)
was the photographic HDRI panoramas.** `day.hdr`/`golden.hdr` are static
equirect photos with their own baked-in sun position, unrelated to
`art.json`'s `sun.pitch_deg`/`yaw_deg` — so whichever way a viewpoint faced,
the photographed sky and the real `DirectionalLight3D` could disagree about
where the light was coming from. Round 1's blind critic caught this exactly:
`02-valley-floor`'s sky read as dusk while its own ground lit as bright
midday, same "day" preset as three other frames that looked correctly
midday. Dropped both panoramas back to the existing procedural-gradient
fallback (already built for this purpose, previously used only by `night`),
whose glow is generated from the real sun direction and so cannot disagree
with the ground in any direction — not just survey's five. Confirmed:
`02`'s sky matches `01`/`03`/`04` exactly after the fix. Costs the cloud
detail the panoramas bought; `ProceduralSkyMaterial` cannot render clouds at
all (documented in `world_look.gd`'s own long-standing comment) — an
accepted, deliberate trade for the consistency EV8 exists to deliver, not an
oversight.

**A third, smaller fix**: `fog_colour` didn't match `sky.horizon_colour` for
any of the three time presets (`day` was `#cdd0c6` vs. a `#b9c8cf` horizon).
Since `fog_sky_affect` is deliberately 0 (the sky is never fogged), those two
colours are the only thing that has to agree for distance-fogged terrain to
meet the sky without a seam — round 1's critic caught this too, as a hard
pale band sitting well short of the true horizon in `03-rise-overlook`.
Matched all three presets' fog colour to their own horizon colour.

**Round 2 also caught `05-spawn-low-sun`'s ground crushed near-black**
against a still-bright sky once the panorama stopped partially masking it.
Lifted golden's `ambient_energy` 1.15 → 1.5 (measured: near-field luminance
0.126 → 0.139); the cool ambient tint stays deliberate (real golden-hour sky
fill reads cool against a warm key).

**Stopped after round 2**, not because nothing moved (round 2 named real
things round 1 hadn't) but because what was left split cleanly into
out-of-scope and structural-tradeoff, neither of which EV8 can address:
frame emptiness/density and creature/character art quality were both
round 1's and round 2's #1 and #2 ranked gaps, and both are already owned
elsewhere — `EV3` (scatter/clustering) and `BLOCKED.md`'s standing
creature-appeal entry, respectively, not new findings this task can act on.
One genuinely unresolved residual: `03-rise-overlook` still shows a soft
grey-white horizontal band at the horizon, unmoved by the fog-colour fix
(`frame_stats` seam stayed 0.009 before and after) — this looks like a
structural consequence of `world_background = 0` at this viewpoint's
elevated, grazing-angle look: gaps between distant ridgelines show the sky
dome's own sky-hemisphere/ground-hemisphere seam through them. Small (well
under any seam threshold that's flagged a problem elsewhere in this file)
and not further reachable by fog or ambient tuning; worth knowing about if
`EV3`/`EV5` end up reshaping the terrain this viewpoint looks across.

Warm sun and cool ambient fill (the bible's other two `EV8` asks) were
already correctly built via `art.json` + `world_look.gd` before this task —
verified intact, not reworked.

`80db19f` (config-only: `data/config/art.json`,
`data/config/terrain_playground.json`) · `tests: none` named; ran
`tests/smoke_art.gd` anyway since the touched file also carries creature/human
config (untouched sections) — green.

## EV9 (first slice) — the exploration HUD, for real this time
`eea16a9` · `tests: smoke_menu` green, plus `run_tests.gd` (299/299),
`smoke_mouse_look`, `smoke_playground`, `smoke_opening`, all run locally
headless before push.

`playground_hud.gd`/`.tscn` rebuilt from the M1 debug dump into the real
exploration HUD bible §16 describes: a styled health/stamina panel (dark
translucent, teal border, rounded corners, "HP"/"STA" labels) that fades to
a low-emphasis state when full and idle rather than to invisible, a
party/orb count panel reading `Game.party`/`Game.inventory` live, and the
contextual interact prompt read from `InteractionArbiter.prompt()`. The old
always-on movement/input telemetry dump is still there — genuinely still
needed for M1 tuning — just behind an F3 toggle now instead of covering a
third of the screen by default.

**Scoped deliberately small.** EV9's full brief (inventory grid + crafting
panel reskin, input-glyph device tracking, objective line, icons, a display
font) is bigger than one "smallest coherent version" pass, especially after
watching visual-judge iteration cost on `SA0-orbs`/`SA0-orbs-remainder`. Full
remainder list is in `BACKLOG.md`'s EV9 entry — read it before starting the
next EV9 slice rather than re-deriving the same scope split.

**Visual-judge, 3 rounds** (`tools/capture_exploration_hud.gd`, two frames —
idle and a forced-hurt state — of the same viewpoint):
- Round 1 found the vitals bars unlabeled, low-contrast against their own
  track (fill alpha 0.28 was reading as a rendering glitch, not a calm
  state), and the two panels looking visually mismatched. Fixed: added
  "HP"/"STA" labels, raised the idle-fade floor to 0.55.
- Round 2 found the panels reading as flat engine-default rectangles — the
  10px corner radius and 30%-alpha border were too subtle to register, and
  the label padding looked cramped. Fixed: border alpha/width up, corner
  radius 10→14, labels vertically centered against their bars.
- Round 3 verdict: **"Coherent, intentional game UI? Yes."** Two small notes
  (bar-fill corner radius vs. panel radius, stamina teal too close to the
  border teal) fixed inline without a further round. Everything else the
  critic named it explicitly split out as "needs new assets" (icon glyphs, a
  branded display font, gradient bar fills) rather than more scene tuning —
  that split is what seeded the BACKLOG remainder list above.

**Also swept up in this push:** three `.uid` sidecar files
(`scripts/ui/starter_picker.gd.uid`, `tests/helpers/unhandled_probe.gd.uid`,
`tools/capture_starter_picker.gd.uid`) that earlier firings had left
uncommitted next to already-tracked scripts. Harmless on their own — Godot
just regenerates them — but a fresh checkout would regenerate a *different*
random uid than the one already baked into any `.tscn` reference, which is
the kind of thing that only surfaces as a confusing import error much later.
Committed them rather than filing a ticket for something this cheap to fix.

**For the next EV9 firing:** the auto-merge bot rebased this branch once on
its own (`ralph-bot`, run 328) and still hadn't landed it several minutes
later because two other lanes (`R9.4-remainder-8`, then a run of `EV4`
commits) kept moving `main` underneath it. Rebasing it myself and
force-pushing (`--force-with-lease`, safe since it's a solo-owned feature
branch with no one else's commits on it) is what actually got it merged —
worth doing proactively rather than waiting out the bot's retry cycle when
`main` is this active.
## EV9 (second slice, built in parallel with `HD1`'s discovery) — real Kenney Input Prompts glyphs
`2fba96f` (glyph mechanism) · `f74ce06`/`310a79d` (two legibility fixes) ·
`tests: smoke_menu`, green locally; full 299-test suite also run since the
change touches `test_prompt_arbiter.gd` directly, all green;
`smoke_opening`/`smoke_combat` also reverified since both scenes render
panels this ship touched.

**Landed at the same time as the owner's own report that seeded `HD1`
(Phase -0.85) — the two were built without knowledge of each other, and
this entry does not close `HD1`; see that item's own entry for the accurate
remaining scope (`combat_hud.gd`'s Actions row, and the real last-used-
device tracker this ship's simpler heuristic stands in for).**

**Real button-glyph icons, not literal bracket text.** Bible
§18: use Kenney Input Prompts, map by device, and "do not display both
keyboard and controller prompts simultaneously unless context requires
it" — five places in this project drew a hint like `"[X] / [E]"` or
`"[A]"`, always showing both devices at once, which violates that last
rule directly. `scripts/ui/input_glyph.gd` (new) maps the four glyph ids
the UI actually needs (`interact`/`confirm`/`cancel`/`horizontal`) to a
Kenney icon for the connected device, returned as inline `RichTextLabel`
BBCode. Device is "a joypad is connected," not true last-input-used live
switching — bible §18 asks for the latter, but that needs a shared
observer every scene can reach, and `project.godot`'s one autoload
(`Game`) is explicitly meant to stay the project's only one; recorded as a
known gap rather than silently simplified. Five call sites wired:
`dialogue_panel.gd`, `name_prompt.gd`, `starter_picker.gd`,
`prompt_arbiter.gd`'s `format()` (the real exploration-HUD prompt) and
`encounter_director.gd`'s matching combat-engage prompt. All five
Hint/Prompt `Label` nodes became `RichTextLabel` (`bbcode_enabled`), since
`Label` cannot render inline images; `font_color` became `default_color`,
`RichTextLabel`'s equivalent theme property.

**Three local blind-judge rounds, all real defects, all fixed before push
— `tools/capture_ui_glyphs.gd` (new) is the purpose-built capture, five
panels, none of which the fixed five-viewpoint survey or
`capture_wayfinding.gd` can frame.**

- **Round 1** found the icon sourcing itself was wrong twice before it was
  right: cropping the Kenney sprite atlas by its own XML rects picked the
  wrong sub-regions entirely (confirmed by compositing onto a dark
  background — a meaningless squiggle, not a button); the pack's own
  pre-cropped `Default/` folder gave correct icons directly. This round's
  first render also surfaced a doubled prompt line from two different HUD
  panels bleeding into one frame -- traced to a real, pre-existing,
  player-visible bug (`EV9-double-prompt`, opened in `BACKLOG.md`, not
  something this ship introduced), and worked around in
  `capture_ui_glyphs.gd` by isolating each HUD's visibility per shot rather
  than fixed in the game, since it is an arbitration question, not a glyph
  one.
- **Round 2** found `keyboard_enter.png` (5 letters of baked-in "ENTER"
  text) and the combined `keyboard_arrows_horizontal.png`/
  `xbox_dpad_horizontal.png` icons illegible at the ~28px this renders at
  — confirmed by simulating the exact render size locally before guessing
  at a fix. Swapped `confirm`'s keyboard icon to `keyboard_return.png` (a
  plain return-arrow symbol, no text) and `horizontal` to two
  single-direction icons shown side by side instead of one combined glyph
  (`input_glyph.gd`'s `GLYPHS` now allows an Array per device for exactly
  this case).
- **Round 3** found `cancel`'s keyboard icon (`keyboard_escape.png`, "ESC")
  still illegible at 28px even after round 2's swaps addressed the two
  worse offenders. Confirmed locally that 36px reads clearly where 28px
  does not; bumped `input_glyph.gd`'s default size across the board, since
  every other glyph is simple enough that a larger render only helps it.
- **Round 4 converged without a new confirmed defect.** The critic read
  `combat-prompt.png`'s and `dialogue-panel.png`'s "E" icons as blank
  keycaps with no visible letter, inconsistent with `exploration-prompt.png`'s
  legible "E" despite plausibly being the identical icon. Direct pixel-level
  crops of all three (`/tmp/crop_*.png` at the time, not committed) show the
  same "E" glyph legible in all three frames — the finding did not survive
  verification. Stopped here per `conventions.md`'s convergence rule.

**Not touched, and named rather than silently folded in:** `combat_hud.gd`'s
`Actions` row (five combat verbs — quick/charged/throw/switch-left/
switch-right — each needing its own keyboard-and-gamepad glyph pair, `HD1`'s
own reproduction case) and rebinding-aware glyph lookup (the bracket text
this replaces had the identical gap; the four glyph ids here still read
`project.godot`'s default bindings, not whatever `tab_settings.gd` remapped
them to — also `HD1`'s to fix). `EV9` itself stays open too: inventory grid,
crafting panel, the tracked-objective line and the compass are all still
ahead, per the original item's own scope.

## LP2 — `smoke_opening` beat-3 press flake: a pattern fix, the race not directly reproduced
`tests: smoke_opening`, green locally 3/3 (always exactly 14 presses, matching
`grandpa_house`'s real line count) before push.

**What was ruled out, in order, each with real evidence rather than a guess:**

- **The dialogue content itself.** `data/dialogue/opening.json`'s
  `grandpa_house` entry has exactly 14 lines and no conditional branches; the
  passing runs' "14 presses" is not a coincidence, it is the real count. No
  `randi`/`randf`/`randomize` anywhere in `dialogue_runner.gd` or
  `sequence_director.gd`. `dialogue_runner.gd::advance()` is fully
  deterministic — one `advance()` call, one line, always, until `close()`.
  So the only way to close in 7 real presses is for `advance()` to fire twice
  per test-side press, not for the conversation to genuinely be shorter.
- **The arbiter re-activating Grandpa while his conversation is already
  open.** `interaction_arbiter.gd` and `dialogue_panel.gd` both read
  `interact` by polling `Input.is_action_just_pressed` from their own
  `_physics_process`, so a press could plausibly be seen by both. But
  `sequence_director.gd::_start_conversation()` guards
  `if _dialogue.is_open(): return false` — re-firing Grandpa's `activated`
  signal while his conversation is running is already a safe no-op, so this
  cannot be adding extra `advance()` calls.
- **A one-off timing coincidence.** It isn't: 14 lines closing in exactly 7
  presses is exactly half, and the failing CI run's own log shows this held
  for the *whole* conversation, not one press out of many — whatever caused
  it, it was consistent across the run, not a single unlucky frame.

**What is left, and could not be forced to reproduce here despite three
separate attempts** (a bare `is_action_just_pressed` probe against an idle
SceneTree, 60 repeats of the same probe against the real, fully-loaded
meadows playground under its actual 23k-prop background load, and a probe
that explicitly forced `action_press()` and the parsed `InputEventAction`
onto different physics frames by hand) — all three came back with exactly one
`is_action_just_pressed` hit per logical press, never two. A fourth attempt
under `xvfb-run` + `--rendering-driver opengl3` (the one condition
`conventions.md` already documents as 25× slower and prone to exactly this
class of flake under CPU load) was tried specifically to force real
Godot physics-catch-up — multiple physics ticks running between two
`_process()` calls when a frame falls behind — but it did not finish inside
this firing's time budget and was killed rather than let run indefinitely.

**The fix shipped anyway, on the strength of the elimination above plus an
exact precedent already proven in this same file.** `dialogue_panel.gd` and
`interaction_arbiter.gd` both poll `Input.is_action_just_pressed` from
`_physics_process` — exactly the reader class `smoke_opening.gd`'s own
`_press_polled()` comment already names for `menu_confirm`: *"under a heavy
scene the two [signals] can land in DIFFERENT physics frames, which a
polling reader counts as two presses. Typing 'Bud' came out 'Buudd'."* Beat
3's `interact` presses were the one place still using `_press()` (which
sends `action_press()` AND a parsed `InputEventAction`, "belt and braces")
against that same class of reader. `docs/HANDOFF.md` §10's actual rule — the
reason `_press()` sends both in the first place — is scoped to **UI focus
navigation**, which `interact` never drives, unlike `ui_*`. Switched both
call sites (`_grandpa_says_his_piece`'s advance loop and the shared
`_walk_to_and_activate`) to `_press_polled("interact")`, matching the
already-established pattern exactly rather than inventing a new one.

**Say this plainly rather than overclaim it: this removes a real, provable
redundancy (an unnecessary parsed event feeding a purely-polled reader,
already a demonstrated failure class in this file) but the specific race
that produced the "7 vs 14" observation was not directly reproduced either
before or after the fix.** If `smoke_opening` flakes again on beat 3 with a
press-count anomaly, that is new information — either this was not the whole
cause, or the timing window this fix closes is not the one CI hit. The next
firing to see that recurrence should re-open this rather than assume it is
solved, and the `xvfb-run` reproduction attempt above is the fastest
remaining path to a forced repro if it comes to that.

## EV2 — An approved Meadows nature subset
`f4bf576` (curate + variant tints) · `2fe56e7` (round 2: fix cyan-highlight
artifact) · `1cdd5e2` (round 3: widen hue/value spread) · `tests: smoke_art`
green locally throughout; full suite (299 tests) also green, confirming no
regression from trimming layer model lists.

Curated `trees` (standard canopy) from 5 CommonTree forms to the 3 with the
widest canopy footprint (measured with `measure_models.gd`, not guessed —
the acceptance bar is a silhouette read at thumbnail size, not a triangle
count), and `grove` (hero trees) from 5 TwistedTree forms to the 3 with the
widest footprint, tallest height and most asymmetric silhouette. Added a new
`saplings` layer reusing the two dropped CommonTree forms at young-tree scale
instead of discarding them — same species, a different age, no new geometry.
Gave `vegetation.gd::_build_batch` an optional per-MODEL `variant_retint`
lookup (falls back to the layer's existing per-material `retint` when a model
has no entry) so a layer can assign controlled spring/deep/yellow-green
variants instead of one flat colour, since several models share one material
name and a layer-wide colour can't tell them apart.

**Three real rounds of the mandatory local blind-judge pass, each one
finding something genuine — this is the record of what each one caught and
fixed, not a pass-first-try story:**

- **Round 1** (initial curation + first variant colours, reusing R9.4's
  shipped `#9dcaff` as `spring`): an independent blind critic found visible
  cyan/teal flecks in canopy highlights, described unprompted as "a stray
  specular/vertex-color artifact." Traced algebraically: `#9dcaff` and its
  darkened sibling are BLUE-hued multiply colours (hue ~213°) that land in
  the intended green family on `Leaves.png`'s dark/average texels but
  multiply through nearly unchanged on the texture's bright highlight
  speckle, reading as cyan on the lit parts of the canopy specifically.
- **Round 2**: replaced the tint family with green-hued multiplies (hue
  77–112° instead of 213°). A second, independent blind critic confirmed the
  flecks were gone (zero cyan/teal pixels found by its own pixel scan) — but
  its close inspection found the three variants still rendered in a tight
  63–84° hue band once scene lighting compressed the on-paper 77–112° spread
  further, reading as one uniform green rather than 2–3 distinguishable
  varieties.
- **Round 3**: widened both hue AND value (not hue alone) — `deep` in
  particular is now genuinely darker, not just a different hue at the same
  brightness (values 0.09/0.19/0.20 vs round 2's 0.19/0.19/0.20), while a
  highlight-case check (synthetic near-white texel multiply) confirmed the
  wider spread still stays short of the ~150° line where the round-1
  artifact started. A third independent blind critic confirmed no fleck
  regression and found genuine, sortable colour variety in the farm-cluster
  frame (pale sage / mid olive / dark saturated green) — one specific
  treeline in a different frame still read as fairly uniform, but that
  reads as the stochastic scatter happening to draw similar models in that
  one local cluster rather than a mechanism failure, since the same
  mechanism visibly works elsewhere in the same frame set.

**Stopped after round 3**, not because it passed clean, but because both
objectively-fixable defects the critics named (the cyan artifact, the
variant separation) show confirmed, independently-verified improvement, and
what's left is genuinely outside `EV2`'s lever — see below.

**Two honest remainders, not faked:**

- **Wetland forms** (bible's "1–2 forms near river") — not done. No river
  exists yet (`EV5`, unshipped) and there is nothing to place wetland
  vegetation near.
- **Rock family's "2–3 large" tier** — not done. The imported subset has no
  distinct large-format rock mesh; the fuller Stylized Nature MegaKit that
  might carry one is itch.io-blocked (`EV1-remainder`). Reusing the existing
  `Rock_Medium` meshes in a second layer was considered and rejected: it
  would put the same model in two layers' `models` lists, which
  `vegetation.gd::_build_batch` groups by model path for drawing —
  `_warn_about_shared_models`'s own docstring explains why that silently
  drops one layer's tint/collision settings. The single `rocks` layer's
  existing 0.28–2.1 scale span already produces large-boulder reads from the
  same 3 medium meshes and stands as the honest ceiling.

**Two new findings opened in `BACKLOG.md`, not chased here** (both found
independently by multiple blind critics across the three rounds, neither
fixable with `EV2`'s own lever): `EV2-trunk-colour` (tree trunks render pale
salmon/pink instead of brown bark — source bark textures are ordinary warm
browns, so this looks like a lighting/minification effect on thin geometry
under the Compatibility renderer, not a texture or retint bug) and
`EV2-landmark-ceiling` (even the best 3-of-5 hero-tree subset doesn't read
as a true landmark specimen against the key art — a critic's own verdict was
that this needs broader-canopy geometry the imported subset doesn't have,
which is the same itch.io block as the rock tier, not a curation problem).

## SA1-lod — vegetation stops discarding the importer's LOD chain
`de8657c` · `tests: smoke_art`, green locally before every push (three of
them — see below), and in CI (run 31511759144, then 31514823852 attempt 2).

Root cause: `vegetation.gd::_retint()` rebuilt every scattered mesh with a
fresh `ArrayMesh` via `surface_get_arrays()`/`add_surface_from_arrays()`,
which only round-trips base LOD0 geometry — there is no public getter for the
importer's LOD dict, so it and the shadow mesh were silently dropped on every
retint. Every tree and tuft therefore drew at LOD0 at every distance, 23,452
instances of it. Fix: `duplicate(false)` the source mesh instead of rebuilding
it — `ArrayMesh.duplicate()` carries the LOD chain over through its own
`_surfaces` storage, and `surface_set_material()` on the duplicate retints
without touching any of that. `false` (no subresource duplication) is
deliberate: the shadow mesh carries no material and is never touched, so
sharing the one original instance across every retint variant is correct and
free. `smoke_art.gd` gained a check that reads the LOD chain and shadow mesh
back off a retinted `CommonTree_1` standing in the world and compares it to
the un-retinted source file; verified it fails against the pre-fix code
([0, 0], no shadow mesh) and passes against the fix ([10, 4], matching the
source).

**Shipping this took three rebase-and-push cycles, none of them code
changes.** The fix itself was already correct and CI-green when this firing
picked it up — a previous firing (`ralph-lane-generalist`) had done the real
work and left its lease reading `shipped`, but `ralph/SA1-lod` had never
actually fast-forwarded `main`: three other lanes (`NP1`, `SA0-orbs-
remainder`, `ralph/tether-hero-boards`) were landing on `main` in the same
window, and `ralph-merge.yml`'s fast-forward-only gate lost that race
repeatedly. This firing rebased onto current `main` and re-pushed three times
(never touched `main` directly, never force-pushed it) until one push's CI
finished before the next lane's landed. One of those CI runs failed for a
real but unrelated reason — see `LP2` below, opened from the same evidence.

## LP2 opened — `smoke_opening` beat-3 press-count flake
Not fixed, recorded in `BACKLOG.md` Phase -0.95. Same commit (`c8ece6a`)
failed once and passed twice across three runs (one CI, one CI rerun, one
local) with zero code differences — closing Grandpa's conversation in 7
presses on the failing run and 14 on both passing ones. Likely the same class
of frame-timing race `smoke_opening.gd`'s own comments already warn about for
polled input, not investigated further here; see the `BACKLOG.md` entry for
the evidence trail.

## SA0-orbs-remainder — lighting, UI-chrome ownership, creature appeal
`c5b492c` (scope note + BLOCKED.md split) · `d18899f` (rim light + selected
label) · `tests: smoke_opening` green locally, both before and after a rebase
onto current `main`.

Picked up the three open questions `SA0-orbs`'s own remainder left, one at a
time:

**(a) One more lighting pass, since the remainder said it had "reachable
value."** Added a cool-tinted rim/kicker light against the warm key + ambient
— the specific gap round 4's blind critic named by name ("no visible
rim/kicker light… compare this to any of the Palworld shots"). Ran a fifth
blind-judge round: the rim light helped the two pale creatures (Ripplet,
Galewisp) separate from the dark orb background, but did little for the
darker Terrapup, and the round's other findings were either repeats (creature
material quality — see below) or apparent misreadings with no basis in the
code (a claimed "selected creature renders larger/closer" and a "pose swap on
selection" — neither exists; the only per-frame difference is the picker's
own intentional idle turntable spin, and more real time had passed in the
second capture). The one genuinely new, cheap, real finding — the selected
orb's name label carried no cue of its own, "an easy win being left on the
table" — got its own fix (gold colour + a couple points larger, matching the
ring) and a sixth render to confirm it visually. Stopped there: five rounds
of blind judging is already past `R9.4`'s own four-round precedent, and every
remaining finding across rounds 4–5 was either this label nit (now fixed) or
the same "creature art itself is below the bar" verdict every single round
independently reached — which is exactly the wall `conventions.md`'s
stopping rule exists to detect, not a premature stop.

**(b) Who owns wiring `EV1`'s Kenney Input Prompts icons into narrative UI.**
Did not build a device-aware icon system inside the picker — that would have
duplicated `EV9` and left `dialogue_panel.gd`/`name_prompt.gd` inconsistent
with it. Instead read `docs/ENVIRONMENT_AND_UI_BIBLE.md` directly: §16
("Dialogue") asks for "a controller-first continue prompt" and §18's own
worked example opens with "E / X button for interact" — the literal hint
`dialogue_panel.gd` draws today as bracket text. `EV9`'s one-paragraph
`BACKLOG.md` summary just never said its own source material already covered
narrative panels. Fixed with a scope-note naming `dialogue_panel.gd`,
`name_prompt.gd` and `scripts/ui/starter_picker.gd` explicitly, so whoever
picks up `EV9` does not have to rediscover this mid-task.

**(c) Whether the creature-appeal gap needs its own backlog item.** It does
not — "improve creature appeal" has no concrete done-when a firing could aim
at without first deciding how much material/lighting rework is worth
committing against a fixed ceiling (`D23` §20 forbids new creature meshes at
any balance). That is a resourcing call, not a design decision on
`CLAUDE.md`'s flagged list, but it still is not a firing's to make
unilaterally. Opened as a new `BLOCKED.md` entry instead — "Does the creature
roster clear a Palworld-level appeal bar, or does it need to?" — distinct
from `SA5`/`SA6`'s narrow pairwise mandate (stopping two specific species
reading alike), asking the owner whether a roster-wide pass is worth
commissioning at all.

## EV4 — Paths become a control-map material, not a colour-map tint
`f5d77ec` (mechanism) · `6b12e30`/`eacf0f3` (tint/relief tuning, later
reverted) · `9e25288` (edge-wobble fix) · `c6e6763` (dedicated `path`
texture) · `tests: smoke_traversal`, green locally; full 299-test suite also
run as a broader check since `playground_heightfield.gd`'s `path_factor()`
is shared with `scatter_rules.gd`, all green.

**The mechanism absorbs `R9.4-remainder-4` and `R7.1-found-3` and genuinely
ships.** `build_playground_terrain.gd`'s `_paint_control_map` used to paint
paths only as a lerp toward a tan colour on the COLOUR map, over whatever
texture the slope-driven control map had already chosen — "a worn-earth
tint," never a different material, which is exactly what both critics named.
It now paints a real texture id into the CONTROL map along every route
(`_path_control`, ~2148 pixels), overriding the slope-driven choice rather
than tinting on top of it. The old `paths.tint` colour-map lerp is removed
outright, not layered under the new mechanism.

**The edge is genuinely organic, not a mathematically exact offset.**
`path_factor()` (`playground_heightfield.gd`) perturbs its own fade band
with a dedicated noise field (`_path_edge`) so the boundary bulges and
pinches rather than tracing a perfect parallel curve of the route polyline —
verified test-side (`test_the_paths_reach_where_they_promise` still passes:
route waypoints stay fully on-path, well-off-road points stay fully clear)
and visually (`the-rise-route.png` shows a path that narrows and widens
along its length).

**Five blind-judge rounds on `tools/capture_paths.gd` (new — four
standing-eye-level viewpoints on the actual routes; neither the fixed
five-viewpoint survey nor `capture_wayfinding.gd` frames the ground at the
angle a path needs to be judged from). The first four rounds tuned the wrong
lever; round 5 found the right one and the material genuinely improved:**

- **Round 1** (mechanism only, reusing `soil`/`Ground003_Color.jpg` at its
  original neutral-grey tint): "essentially the grass shader recolored a
  darker green-brown... no visible soil/dirt texture break."
- **Round 2** (`soil.tint` → warm `#d19e6b`): measured movement
  (`frame_stats.py`: saturation/chroma/hue shifted warmer) but a NEW defect
  — "irregular near-black blotches... a broken material/vertex-paint blend"
  on the hillside slope band — plus the path still "clearly carries
  grass-blade geometry... underneath" up close.
- **Round 3** (`soil.normal_depth` 0.4→0.15, tint eased to `#c7a680`,
  mirroring the grass texture's own earlier relief fix): root-caused rounds
  1-2's real problem — `Ground003_Color.jpg` is a photo of a weedy lawn with
  real green grass tufts painted into its own albedo, not a clean dirt
  photo, so no tint or relief value can repaint it. Critic still said
  "tinted grass, not dirt" (same core complaint) but separately named a
  resolution problem in the edge itself: "jagged, stair-stepped."
- **Round 4** (`_path_edge` frequency 0.2→0.05, octaves 2→1, so the wobble's
  wavelength is long enough for the bake's 1m vertex grid to resolve without
  aliasing): addressed round 3's edge-geometry finding specifically.
- **Round 5 — the actual fix.** Another lane sourced and ledgered ambientCG
  `Ground030` (a real dirt/pebble pathway photo, no baked-in grass) and
  `Ground037` independently while this task was in flight, deliberately
  leaving them unwired to avoid a collision (see its own `EV4-textures`
  commit on `main`). Wired `Ground030` in as a NEW `path` texture entry
  (`_texture_ids`/`_path_control` prefer it over `soil`, falling back
  gracefully if absent) and reverted `soil` to its original R9.4 values,
  since it goes back to being a hillside-only texture. **Cost a debugging
  detour worth recording**: the rebase that brought `Ground030`/`Ground037`
  in landed AFTER the local `.godot/` import cache had already been built,
  so the two new textures were never actually imported — `_build_texture_
  list()`'s own uniform-size guard (correctly) refused to build a mismatched
  array and the WHOLE terrain, not just the path, silently fell back to the
  flat colour map (a wash of pale near-white). Re-running `godot --headless
  --path . --import` fixed it — `conventions.md`'s own "import cache does
  not travel between worktrees" warning, hit for real. Once genuinely
  rendering, the blind critic's verdict changed materially: "mostly a
  different material, not simple grass tinting... real progress... [the
  path] correctly connects the well, Grandpa's house, the barn and the
  hilltop landmark... works as a navigational read" — the clearest
  affirmative verdict any round produced.

**Stopping here with two named, narrower remainders — not a silent pass.**
Round 5 did not fully clear the bar: the critic still names green
moss-blotch patches on the path texture reading "too saturated and too
crisply circular... a texture-blend artifact rather than moss," and a
stepped/aliased path edge specifically where a route climbs the hillside
slope (distinct from round 4's flat-ground fix). `EV4-textures` is
downgraded from "source a texture" (done) to a tuning-scope remainder for
the moss-blotch saturation and the slope-specific edge stepping.
`EV4-hillside-seam`'s round-3 zigzag finding gets a real answer round 5
provides for free: `soil` reverted to its untouched original values and the
hillside still reads "mottled... blotchy all over the dome" to a fresh
blind critic, which settles the attribution question the original entry
left open — **pre-existing, not introduced by EV4.**

## SA0-orbs — the starter choice moves into Grandpa's conversation
`2036b28` (director+data+tests) · `4912dc1`..`55e708c` (five visual-pass fixes)
`tests: smoke_opening, smoke_wake_softlock`, both green locally, both replayed
green again after a rebase onto current main.

Owner directive, 2026-08-11: *"the starters should be in orbs and you preview
them while talking to Grandpa."* The three starters no longer stand outside
Grandpa's door as physical bodies you walk up to. `scripts/ui/starter_picker.gd`
(new) opens automatically the instant his briefing conversation closes — still
indoors — and previews all three live: a real creature body inside its own
`SubViewport`, the same construction `tools/preview_creatures.gd` uses for the
art survey, each with `own_world_3d = true` so three creatures and three lights
never leak into the meadow's own world or each other's. `sequence_director.gd`
drops the ~50 lines that placed, tracked and freed the three physical starter
bodies (`_starter_bodies`, `_starter_prompts`, `STARTER_COLLISION_LAYER`, the
whole of the old `_spawn_starters`) in favour of reading a choice back from the
picker's `chosen` signal — the same "ask a panel, read the outcome" split this
file already keeps with `dialogue_panel.gd` and `name_prompt.gd`.

**Reverses a written decision, amended rather than silently edited.**
`docs/OPENING_SEQUENCE.md` and `data/config/opening.json`'s `starters` block
both used to say the choice is "physical, not a menu… a list box would undo
it." Both now record the reversal in place, with the owner's own words as the
reason. Grandpa's actual spoken lines in `data/dialogue/opening.json` are
rewritten to match — he no longer sends the player out a door to meet three
creatures that no longer stand there.

**`tests/smoke_opening.gd` redriven for the new mechanic**, not just patched:
beat 4 used to walk the player outside and activate a "Choose <name>"
interactable; it now closes Grandpa's conversation for real and waits for the
picker to open **on its own** (proving the director's own beat-driven open
logic, not calling it directly), then drives orb selection and confirmation
with the real `ui_right`/`menu_confirm` actions — the same "real buttons, not
method calls" rule the naming grid below it already followed.

**The blind visual-judge pass ran four uncapped rounds** (`conventions.md`),
and it is the honest reason this shipped later than the code did — this is new
UI a player can see, so the rule applied. Round-by-round, because the specific
bugs are worth keeping:

- **Round 1** found the orbs rendering **completely empty** — `pal_body.gd`'s
  `setup()` gates its mesh build on `is_inside_tree()`, and the orb shell was
  still off-tree when `setup()` ran, so nothing errored and nothing built. This
  is the exact trap `tools/preview_creatures.gd`'s own header names, and it was
  missed here on the first attempt anyway — worth a second read next time
  something builds a creature off the main scene tree. Also found the square
  `SubViewport` render visibly poking past the round panel border. Both fixed:
  the shell now goes into the live `Orbs` tree before the creature is built
  inside it, and a `canvas_item` shader on the `SubViewportContainer` masks the
  render to a circle and vignettes the rim.
- **Round 2** (post-fix) found the panel was actually a vertical capsule, not a
  circle — the name label lived inside the same `PanelContainer` as the 3D
  view, and its line height stretched the panel taller than it was wide. Also
  found the new vignette darkened far enough in to eat into a standing
  creature's own feet. Both fixed: the label moved to a sibling below the
  panel (which is now exactly `VIEWPORT_SIZE` on both axes, a true circle), and
  the vignette falloff eased (0.55→0.7 start, 0.6→0.5 max strength). Cameras
  also pulled back (2.4→2.7 distance multiplier) after a winged species'
  wingtips crowded its own orb edge.
- **Round 3** found flat, low-key lighting inside every orb and ~170px of
  unbalanced dead space between the labels and the button hint. Both addressed:
  ambient light raised 1.6→2.2 and warmed, key light 1.4→2.0, and the layout
  tightened from both sides.
- **Round 4 named nothing new** — restatements of round 3's still-partially-
  addressed items (lighting depth, layout balance, tight per-creature framing)
  plus items already flagged in rounds 2–3 as out of this task's scope (no
  branded UI font/chrome anywhere in the project; the creature models' general
  appeal gap against the Palworld bar). `conventions.md` is explicit that
  reworded repeats are not improvement. This is the same wall `R9.4` hit after
  its own uncapped pass — real, reachable bugs get found and fixed every round
  until the remaining gaps are asset-quality-limited rather than
  composition-limited, and continuing to iterate past that point is exactly
  what the stopping rule exists to prevent. `SA0-orbs-remainder` in
  `BACKLOG.md` records the honest split of what is left and why it stopped
  here rather than running a fifth round.

**`tools/capture_starter_picker.gd`** (new, permanent tool) renders the picker
in isolation rather than booting the full meadows scene — the first attempt at
this loaded the full playground (`diagnose_frame.gd`'s own pattern) and the
whole process died silently under `xvfb`+`opengl3` partway through rendering,
cause not isolated. The picker needs no terrain or scatter behind it, so
narrowing to just the picker sidestepped the crash and is the more honest test
of what actually changed.

**Full local unit suite** (299 tests) run once, unaffected. Not part of this
item's named tests, run anyway as a diligence check given the scope of the
`sequence_director.gd` changes; not repeated on later commits since nothing
touched after that point could plausibly affect it.

## NP4 — Generate the three bases from the board
`fa7636b`/`51c5f28`/`1429832` · `tests: smoke_art` (green, local + import)

`villager_female`, `villager_male` and `grunt` added to `views.json` (5
turnaround columns per row on `docs/art/reference/12_NPC_Bases_Reusable.png`
— more than any other sheet in the pack — only 4 of 5 named per row, since
`meshy.py`'s `VIEWS` has no slot for a second three-quarter angle; see the
sheet's own `_comment_npc_bases`) and to `meshy.py`'s `SPECIES_PROMPTS`/
`HUMANS`. Two crop-time defects found and masked out: a decorative title
flourish bled into `villager_female`'s front crop, and `grunt`'s row has no
clean gap between its feet and its own FRONT/SIDE/etc. caption row.

Generated 3 preview candidates per base (candidate `a` won all three on
fidelity to the board), cleaned with `blender/cleanup_mesh.py` (57k-tri
non-manifold triangle soup → clean 28k-tri manifolds) and retextured.

**Two full rounds of the mandatory blind visual-judge pass** (`conventions.md`),
each a genuinely blind subagent with no knowledge of what changed:

- **Round 1** found real defects: `villager_female`'s twin ponytails invisible
  in the FRONT silhouette (reads as a bob), `villager_male`'s vest textured
  brown against what looked like a blue-gray reference, `grunt`'s face
  rendered completely bare with no mask/goggle geometry.
- **Investigated before reacting.** The vest "defect" traced to the reference
  sheet itself: `12_NPC_Bases_Reusable.png` draws `villager_male`'s vest
  blue-gray in the FRONT panel only and brown in the other four (3/4-front,
  side, 3/4-back, back) — confirmed by eye against the source PNG, not a crop
  bug. The render was correctly following the turnaround's majority signal;
  told round 2's critic about this so it wouldn't re-flag an inconsistency
  that isn't the model's fault.
- Strengthened all three prompts (ponytail-from-front emphasis, dropped the
  wrong vest colour, added goggles as a named signature feature) and
  re-generated/re-textured. **Real, verified improvement on `grunt`**: round 2
  confirmed a mask and defined eyes now render where round 1 found bare skin,
  and marked `grunt` **ACCEPTABLE as-is**. **No improvement on
  `villager_female`'s ponytail** after a fresh 2-candidate regeneration —
  multi-image-to-3D is dominated by the 4 reference images (which themselves
  only show subtle ponytail wisps from the front) more than by prompt text,
  and round 2 itself judged the front-view occlusion "minor... a viewing-angle
  artifact, not a missing asset," which is the honest read of a genuine tier
  limit, not a regression.
- Round 2 surfaced two **new**, real defects that round 1's coarser sheet
  hadn't resolved: `villager_female` has a blotchy, asymmetric UV-seam-style
  texture smudge on one shin/leg (retried the retexture once more, identical
  result both times — not retry noise, a base-mesh UV defect) and a missing
  chest cord/strap; `villager_male`'s trousers render too dark/cold
  (near-charcoal) against the reference's warm medium chocolate brown (tried
  a third retexture naming the actual tone explicitly — no movement).

**Stopped here per `conventions.md`'s convergence rule** — two dedicated
attempts at both `villager_female`'s leg texture and `villager_male`'s
trousers colour produced no movement, the signature of a tuning wall rather
than an in-progress fix (same pattern as `R9.4`'s "needs art that is not in
the build" wall). Shipping `grunt` as fully converged/acceptable and the two
villager bases with their specific remaining defects named plainly rather
than iterating further or quietly calling them done. `NP4-rig` in
`BACKLOG.md` is the follow-on (rig/animate/install have no humanoid path in
`finish.py` at all — that is separate plumbing work, not blocked on these
defects).

Committed the winning lineage into `assets_raw/` per the existing wild-roster
convention (e.g. `brooktail`): each base's 3 generate-stage candidates +
`manifest.json` + the winning texture pass, not the intermediate
`build/clean.glb` or the abandoned round-2 regeneration attempt (~600 credits
spent total across generate + 3 rounds of retexture fixes; balance checked
before/after every call, never exceeded plan).

## NP1 — The modular NPC variant system
`122f04c` (rebased) on `ralph/NP1` · `tests: smoke_art`

Surveyed first, against the actual .glb source files rather than assuming:
**none of the three canon rigs (trainer, Grandpa, Warden) has separable hair
or accessory geometry.** Each is one fused mesh (`char1`), one material
(`Material_1`), one skeleton, five clips — confirmed by parsing the glTF JSON
directly. So "swappable hair" and "show/hide accessory parts" cannot mean
toggling real sub-meshes on today's rigs; that needs `NP4`'s Meshy-generated
modular bases or `EV1-remainder`'s CC0 packs, neither landed yet.

Built the **data and attachment mechanism** instead, honestly scoped to what
that survey found achievable now:

- `character_model.gd`'s flat `_apply_tint` (one colour, multiplied over
  every surface — spec §21's own named failure) is replaced by
  `_apply_palette`, which reads an optional per-material `palette` dict and
  falls back to the legacy `tint` field read as `{"*": tint}`. R7.2's three
  villagers need no data change and render identically — verified: same
  white-base × tint albedo output before and after, checked directly.
- `hair` and `accessories` are new optional data: shape, colour, `visible`,
  attached via `BoneAttachment3D` (so a part follows the rig's clips instead
  of floating fixed), each independent of the other and of the body's own
  palette. The shapes are placeholder `PrimitiveMesh`s, not real geometry —
  `CLAUDE.md`'s Prototyping section is explicit that this proves a mechanism
  and is not to be judged as a look.
- A `static` material cache, keyed by `(model, part name, colour)`, shares
  one `Material` across every NPC asking for the same variant — the "keep
  colour calls low with shared materials" the NPC board asks for, and the
  "mints a material per variant" mistake NP1 was told not to repeat
  (`vegetation.gd::_tint_for` proves the same pattern for foliage; that
  file's own LOD-discarding bug, `SA1-lod`, is still open and was not
  touched here).
- `character_model.gd` gained `build_from_config()`, so a test (or a future
  picker) can drive a one-off variant without writing fixtures into the
  shared `art.json`.

**No shipped NPC's live config changed** beyond one comment: trainer,
Grandpa, Warden and all three villagers still carry only `tint`. The
playable village renders unchanged. Judgment call, recorded rather than
silently skipped: `conventions.md`'s blind-visual-judge pass is for
player-visible change, and there is none in this ship. Wiring real geometry
into an actual NPC — the next step, opened as `NP1-geometry` in
`BACKLOG.md`, blocked on `NP4`/`EV1-remainder` — genuinely will need it.

`tests/smoke_art.gd` gained two checks: one rebuilds `villager_farmer`,
`villager_keeper` and `villager_smith` and confirms they still tint through
the new `palette` translation (not an untouched default-white material);
one builds two NPCs off the same base with different `palette`/`hair`/
`accessories` data and asserts they differ independently — NP1's own "done
when". Run headless, post-rebase, immediately before pushing: 31 lines
printed (22 creatures, trainer + 3 human fits, the 3 villager tints, the new
variant check, vegetation), zero failures — `art: OK`.

## EV1 (Kenney half) — the four HUD/icon packs, staged and ledgered
`fb396b8` · `tests: none` (EV1's own field)

Downloaded and staged all four Kenney packs `EV1` names — UI Pack, UI Pack
(RPG Expansion), Input Prompts, Game Icons + Expansion — under
`assets_raw/vendor/`, CC0, ledgered in `docs/ASSET_LEDGER.md`. `kenney.nl`'s
"Download Now" popup resolves directly to a CDN `.zip` with no login or claim
step, so this half was a plain `curl`. Covers the whole of
`ENVIRONMENT_AND_UI_BIBLE.md` section 5 for `EV9`'s HUD rebuild.

**The two Quaternius MegaKits are not in this shipment.** Opened as
`EV1-remainder` in `BACKLOG.md` and recorded in `BLOCKED.md`: itch.io's
anonymous-claim flow gates the real file URL behind a client-side purchase
round-trip that neither `curl` nor headless Chromium (Playwright, tried and
ruled out — it cannot reach *any* HTTPS host through this session's proxy,
not just itch.io's) could complete. Needs the owner to supply the two zips,
or a future firing with a working itch.io session.

## RB1-actual — Mouse look: the HUD was eating every mouse motion event
`68e0faf` — owner-directed interactive session, 2026-08-11.
`tests: smoke_mouse_look` (new), regression-checked against `smoke_menu`,
`smoke_input`, `smoke_opening`.

**The owner reported mouse look still broken after RB1 shipped.** That is the
on-device confirmation RB1's entry was waiting for, and it came back negative.

**The real cause is one missing line.** `scenes/ui/playground_hud.tscn`'s `Root`
is a full-rect `Control` with no `mouse_filter` set, so it takes Godot's default
of `MOUSE_FILTER_STOP`. GUI input handling runs **before** `_unhandled_input`,
and `camera_rig.gd` accumulates look in `_unhandled_input` — so the HUD consumed
every `InputEventMouseMotion` and the rig never saw a single delta. No error, no
warning, from the first frame.

**Why only mouse look broke.** Gamepad look is *polled* in `_process` via
`Input.get_vector("look_left", …)` and never travels the event path. Movement is
actions, same story. Mouse look is the one input that goes through
`_unhandled_input`, which is exactly the input the owner reported.

**Every other UI scene already had this right** — `combat_hud.tscn`,
`dialogue_panel.tscn` and `name_prompt.tscn` all set `mouse_filter = 2`, and
`game_menu.tscn` sets `MOUSE_FILTER_STOP` deliberately because a pause menu
*should* take the mouse. `playground_hud.tscn` was the one that missed it.

**Proven, not argued — which is the whole point.** RB1 was diagnosed by reading
code and shipped unverified, and it was wrong. This one was reproduced first:
a probe node's `_unhandled_input` sees the motion **with** the fix and does
**not** see it with the single `mouse_filter` line removed. Both directions run.

**A test trap worth knowing before writing another input test.** The obvious
test — push a motion event, assert the camera yaw changed — **cannot work
headless**. Setting `Input.mouse_mode = MOUSE_MODE_CAPTURED` reads back `0`
(VISIBLE): the headless DisplayServer refuses capture. `camera_rig.gd` only
accumulates look while that reads CAPTURED, so a yaw assertion fails identically
whether the bug is present or fixed. That was the first version of this test and
it was worthless. `smoke_mouse_look.gd` asserts **delivery** instead, via
`tests/helpers/unhandled_probe.gd`, plus a structural assertion that no
full-rect `MOUSE_FILTER_STOP` Control is visible during gameplay so a regression
names its own cause.

**RB1's fix is kept.** Re-asserting capture on `focus_entered` is correct
behaviour and `SH53` still wants it; it just was not this bug.

**RB1's entry also contains a disproven guess** — that the owner could not reach
Grandpa because they could not turn toward him, "a symptom of RB1, not a second
bug." Wrong. `SA0` root-caused that to a one-way beat machine. Two independent
real bugs, and the guess linking them cost time. Worth remembering next time a
single report seems to explain two symptoms.

**Still only answerable on the owner's hardware:** whether Windows delivers
relative motion to the process while the cursor is captured. Same device-layer
split `smoke_input.gd` documents.

## LP1 — Kill the `smoke_traversal` and `smoke_combat` flakes
`330ba3d` on `ralph/LP1`. `tests: smoke_traversal, smoke_combat`.

**Traversal was already fixed** by the `below`-surface-vs-airborne-slope
invariant already sitting in `tests/smoke_traversal.gd` — nothing to change
there. Verified rather than assumed: 19/20 headless passes clean in one
uncontended batch (the one non-pass was a 90s timeout killed by *my own*
concurrent combat runs competing for CPU, not a test failure), plus a
second, fully isolated batch afterward with the same result. Between the
two, every clean run held; no `sank below the terrain surface` failure
appeared once.

**Combat had a real bug, found the way `RB3` and `R4.11` both prescribe:
a recorded run log, not more reasoning about the code.** An instrumented
copy of `smoke_combat.gd` (per-frame position watchdog across the whole
fight, never committed) caught the exact moment things go wrong:
`_a_swing_at_empty_air_misses()` stages the player's pal across the arena
with `_ally.global_position = centre + out.normalized() * (radius - 1.5)`
— a raw position write that carries the arena centre's own Y across a
9.5m horizontal jump. On flat ground this is harmless; on this rolling
terrain it occasionally lands the pal embedded under Terrain3D's
one-sided heightfield collider, below the true surface at the new x/z,
with no floor to catch it. Once that happens the pal free-falls at
terminal velocity for the rest of the fight — one instrumented run
logged the ally's Y crossing from -0.17 to below -900 over the following
~2000 frames — and every downstream assertion this file has ever failed
on falls straight out of that: the "did no damage 95.0 -> 95.0" miss this
item was opened for, "the enemy never landed a hit", "the fight never
resolved after 2500 action frames", "the camera did not return to the
trainer". Two separate instrumented runs caught it live (~2 failures in
17 runs of the *unfixed* test, matching the file's own history of rare,
CI-only flakes).

This is exactly the bug class `combat_manager.gd::_stand_the_trainer_aside`
already paid for once (its own comment names D09: never carry a Y across
a horizontal move) — just not applied to this test's own teleport. Fix:
re-ground via `place_on_ground` (the same helper `combat_manager.gd::_place`
already uses), falling back to the raw write only if grounding fails,
matching the established pattern exactly.

Verified: 20/20 consecutive clean headless runs of the fixed
`smoke_combat.gd`, zero failures, after 17 runs of the pre-fix version
that had already reproduced the failure twice. Traversal and combat do
**not** share a cause, as the item's own note warned — traversal's fix
predates this firing, combat's is a genuine teleport bug local to one
test helper.

## D25 — Loop speedups: parallel lanes, batched pushes, local critic iteration
`6b848b6` and `346e6e0` — owner-directed interactive session, 2026-08-11.
Full reasoning: `docs/decisions/D25-batch-the-push-not-the-testing.md`.

The owner asked for a faster loop and offered a floor (chain firings instead of
idling to the hour) and a ceiling (do not test or ship until a whole phase is
done). **The floor is adopted; the ceiling is rejected**, and D25 carries the
arithmetic so it is not re-proposed.

**Measure before optimising — two numbers the loop had been reasoning from were
wrong.** A branch CI run is **5.2 minutes**, not the 8–9 `conventions.md` and
`ci.yml` both claimed; the loop had been optimising against a figure 80% too
high. And a three-round blind visual pass had cost **8 pushes, ~36 minutes of
CI**, not one. So CI is not where the time goes — the visual-pass amplification
is, and about a third of the backlog is visual-affecting.

**The largest change is therefore the cheapest**: render, critique, fix and
re-critique in the firing's own checkout, push once at the end. The blind pass
is unchanged and still required; only where its rounds run moved.

Also shipped: per-`area` leases with one block per live firing (a firing stands
down only when its *own* area is held); expiry 90 → 40 minutes, made safe by
checking the task branch for recent commits rather than trusting the clock;
`lane: art` so unkeyed lanes skip Meshy items silently instead of reporting
blocked; batching 1–4 items per branch, never across areas and never a red item
with a green one; successors chained 2–3 minutes out.

**`LP1` promoted** to a new Phase -0.95 from a bullet at the bottom of the file.
Batching makes the `smoke_traversal`/`smoke_combat` flakes worse, not better —
one random red now rejects up to four finished items.

**Two operational facts found the hard way, both now in `MANUAL.md`.** An agent
cannot create a working lane: `create_trigger` has no `sources` parameter, so
the sessions it fires come up with **no repository checked out**. Two lanes were
created that way, fired on schedule, and produced nothing at all while reading
`enabled: true` with a correct cron in every listing. And the keyed "Ralph"
Routine was created via the HTTP API, so **no agent can unpause it** — only the
Routines UI can. `ralph/LANE_PROMPT.md` holds the exact prompt text and the
ten-minute test for whether a new lane actually works.

## D24 — The art bible, the NPC board, and one family per category
`4eeff21` — owner-directed interactive session, 2026-08-11.
Full reasoning: `docs/decisions/D24-one-nature-family-one-village-family.md`.

The owner's words: *"the visuals is the most important part and we're not
bailing the palworld look and it's not getting fixed from what I can tell."*
R9.4's own evidence agrees — **both blind critics ranked "needs art that is not
in the build" first**, and scene tuning had genuinely run out of road. The audit
behind the decision: 42 of 116 nature models present, **no** village kit, **no**
props kit, **no** UI assets beyond two portraits.

Landed verbatim behind provenance headers: `docs/ENVIRONMENT_AND_UI_BIBLE.md`
and `docs/art/reference/12_NPC_Bases_Reusable.png` (numbered `12_` to follow the
existing convention). D24 makes them canon: one nature family, one village
family, one prop family; **Medieval Village MegaKit is the Meadows civilian
vernacular**; keep Terrain3D; do not return to Forward+; Meshy is reserved for
Team Tether hero objects; the HUD gets rebuilt on Kenney UI. Free Standard tiers
only — the Source editions' foliage shaders are **not** available and nothing
may assume them.

**Two rules changed, and both will stop a task dead if learned late.** No Meshy
generation without an owner-supplied reference board — the account went to 5000
credits and reference art, not money, is the constraint now. And **D23 §20
stands at any balance**: the owner reaffirmed it *with* 5000 available, which
proves it was never a budget rule. Creatures and humans are rework-only,
permanently, and the fidelity gap a critic called "the loudest single problem in
the whole review" is an accepted cost rather than an oversight.

**Both `BLOCKED.md` design questions close.** The settlement's vernacular is
named by the bible; art cohesion resolves to rework on both halves. What
replaces them is a standing list of what the owner still has to *draw* — the
Tether pylon, the relay apparatus, the legendary tether machine.

`BACKLOG.md` gains Phase -0.6 (`EV1`–`EV10`, the look) and Phase -0.55
(`NP1`–`NP4`, the cast). **Ten items are collapsed into them rather than left
running in parallel** — `R9.4-remainder-1/-2/-3/-4/-5/-7`, `R7.1-remainder-2`,
`R7.1-found-3`, `SB7`, `SB8` — each keeping its original evidence, because the
superseding item inherits it as the bar to clear. Two stay open on purpose:
`-8` is a metre-is-a-metre problem a new kit inherits rather than cures, and
`-6` is the `survey_combat` hang, unrelated to art.

## SA1 — Reclaim ~630 MB of VRAM on the ROG Ally
`28af489` — owner-directed interactive session, 2026-08-11.

Owner report: *"the game on the rog is really choppy. it runs high memory, no
cpu and only like 25% GPU. so I think it's a memory issue."* They were right,
and the profile itself was the clue — a GPU at 25% while the frame time is bad
is memory-bandwidth-bound, not shader-bound.

**~808 MB of creature texture VRAM was resident at world start, ~650 MB of it
avoidable.** Thirteen of seventeen species imported `compress/mode=0`
(Lossless → uploads as raw RGBA8) instead of S3TC, because
`detect_3d/compress_to` **never fires for textures only ever `load()`ed at
runtime** — `pal_body.gd:179` does exactly that, so the editor's detect-3D hook
had never run on them. Measured: `brooktail` base colour **21.3 MB** against
`bramblebun`, correctly compressed, at **2.7 MB**.

**~192 MB of it was 2048² emissive maps that are flat black** — 12 KB on disk,
21.3 MB in VRAM each. All twelve verified `max channel value == 0` before being
shrunk to 4×4, so nothing visible was lost.

Also fixed: foliage mipmaps were off on all 14 textures (un-mipmapped 512²
sampled at ~50:1 minification is aliasing by construction); both shadow atlases
sat at Godot's **4096 desktop default** — ~67 MB each — because no atlas size
had ever been set; MSAA 4× → 2×. And `project.godot`'s `config/features` still
read "Forward Plus" while the renderer below it said `gl_compatibility`, left
over from RB4.

**Ruled out** rather than guessed at: terrain (~3 MB), `preload()` (all 67 are
scripts), MultiMesh instance buffers (~1.7 MB), per-frame allocation.

**On-device confirmation is still open — CI cannot measure VRAM**, same as RB4.
If it is better but not fixed, the next suspect is already written down and
queued as `SA1-lod`: `vegetation.gd::_retint()` rebuilds an `ArrayMesh` and
discards the importer's LOD chain, so 23,452 instances draw at LOD0 at every
distance.

## SA0 — The opening soft-locked, so the game was uncompletable
`6dffa21` — owner-directed interactive session, 2026-08-11.

Owner report: *"you still can't interact with grandpa at the beginning. so then
you leave the house and never get a starter."*

**It was not an interaction bug**, which is where the investigation started and
where it would have stayed without checking. The interaction system is clean —
pure 3D distance, no facing, no line-of-sight — and no house geometry blocks
Grandpa; every R9.4 addition passes `solid = false`, and his prompt radius
reaches most of the ground floor.

**It was a one-way state machine with an unguarded exit.** During the `wake`
beat, `conversation_for("wake")` is `""`, so the director leaves Grandpa's
`Interactable` **disabled**, and a disabled node returns an empty offer, so the
arbiter never sees him. The **only** thing in the game that leaves `wake` is
pressing interact on the bed — and nothing forced it, because `_refresh_lockout()`
never gated locomotion on the beat. The fade cleared after ~2.1 s, the player
walked off the bed, and the beat stayed `wake` forever: Grandpa mute, starters
inert (they enable at `choose`), door ungated. Exactly the reported symptom.

Fixed with `_check_left_the_bed()` — a `BED_LEAVE_RADIUS` of 3.2 m off a
recorded bed anchor advances the beat. **A second route to the same deadlock**
was fixed in the same commit: a world with no house had no bed and therefore no
exit at all, and the comment claiming a bare-scene fallback worked was false.
Deleted `_advance()`, which had no callers anywhere.

**Why the existing test was blind to it, corrected.** I first assumed
`smoke_opening` shortcuts by driving beats directly. **It does not** — it
genuinely walks, waits for the arbiter, and presses the real `interact` action.
It cannot see this bug because it **hard-codes the correct order**, always
pressing the bed first. The new `tests/smoke_wake_softlock.gd` walks off the bed
*without* pressing it, and **was verified to fail against the unfixed code**
before the fix landed: *"SOFT-LOCK: walked 4.8m from the bed without pressing it
and the beat is STILL 'wake'."* A test that has not been seen to fail is not
evidence.

`SA0-orbs` in Phase -0.9 is the rest of the owner's instruction — the starter
choice moving into Grandpa's conversation — and is deliberately not in this
commit; it needs a dialogue-effect vocabulary and an orb-as-container concept
that do not exist yet.

## R9.4 — Full visual pass, two blind critics, three render rounds
`86c9eb2` (spec landing), `585cb67` (tooling), `6cfe752` (round 1), plus the
round-2/3 commits above — owner-directed interactive session, 2026-08-11.
Full record: `docs/reviews/2026-08-11-r9.4-full-visual-pass.md`.

**Shipped as PARTIAL, deliberately.** The pass moved every measured axis and
fixed a great deal, and it did not reach the bar. Six honestly-named remainders
are open in `BACKLOG.md` (`R9.4-remainder-1` … `-6`) and one design question
went to `BLOCKED.md`. Do not read this entry as "the visuals are done".

**The root cause of the green was structural, not taste.** `albedo_color`
multiplies, and multiplying by a tinted colour can only RAISE saturation — it
scales down whichever channel is already lowest. The ground carried three
tinted multipliers stacked: texture tint took `Grass008`'s own 0.675 to 0.796,
the baked colour map to 0.859, macro variation to 0.873. Each looked like a
gentle tint on its own. The design intent, in `terrain_playground.json`'s own
comment, required them to be near-white, and set a floor of `#c0` per channel;
the colour map's blue is `0x92` = 146 and had been violating that rule since it
was written. The grass tint is now **solved rather than eyeballed** — it reads
as lavender in a picker because raising blue relative to green is the only way
a multiply desaturates a green — and lands the stack on hue 70 / saturation
0.564, which is `palette.json`'s `meadow.grass_olive` sampled off the board.

**Measured movement**, `tools/frame_stats.py`, round 1 → round 2: saturation on
frame 01 0.70 → 0.59 (references 0.40–0.46); near-field luminance 0.526 → 0.271
(references 0.28–0.60); saturated non-green below the horizon 1.0% → 4.0% on
01, 37% → 61% on 03, 25% → 86% on 05, putting two frames inside the reference
band where none had been.

**Four defects that no test could have caught**, all found by the critics:
signpost text rendering MIRRORED (one `Label3D` on the plank's top edge facing
along the arm, so the side you read it from is the back of the letters, and long
names ran off both ends because nothing fitted them); a creature embedded in the
farmhouse roof; a magenta placeholder cube in two frames; and — caught in the
same pass that introduced it — a stone plinth built as one box across the whole
footprint, laying a grey lid over the interior floor.

**The red leak had been found before and never fixed.** `Leaves_TwistedTree_C`
is RGB(167,23,23), crimson, on decorative grove trees beside the starting
village — the one colour the rubric reserves for Team Tether. The 2026-08-09
site-frames critique named it; this pass named it again eleven days later. The
bushes layer had already been fixed for the *same texture* by swapping it. The
grove was simply never given the treatment. **Turn accepted criticism into a
backlog item the same day, not into a paragraph in a review.**

**Grandpa's house was rebuilt.** It was a flat-roofed windowless box whose only
opening the critic read "as a missing texture, not a doorway", and it was named
the single highest-value piece of missing art in the set because it is the
player's home and it appears in three of five building frames. It now has a
pitched gable roof with eaves, fascia, ridge and chimney; six windows with
frames, mullions and warm emissive panes; a framed doorway with a threshold
step; a stone plinth ring and corner posts. Still primitives, which `CLAUDE.md`
permits. `smoke_opening` passes end to end after each change — the doorway and
the interior navigation are load-bearing for it.

Also fixed: twelve harvest nodes rendering as coloured `BoxMesh` fallbacks
because none had a `model` (two sat beside the player at spawn, and the critic
called them "more legible than the player"); flowers at 4× life size measured
against the 1.8 m NPC, grass at 2.5×, the signpost at 1.5×; path stones blowing
out to near-white; sixty-two dead trees in a biome the board calls "peaceful by
day"; and the canopy sitting in the same hue family as the ground it stands on.

**Two new tools, both committed** (`585cb67`): `tools/capture_buildings.gd`,
because nothing in `tools/` framed a building at the range a player walks past
it — which is why the owner's named weak point had no evidence behind it — and
`tools/sheet.py`, a labelled contact sheet for any number of frames, because
`contact_sheet.gd` reads `shots/*.png` only and has no font rendering, so a
critic cannot name the frame its finding is in.

**The arena was NOT reviewed.** `survey_combat.sh` ran ~50 minutes and wrote no
frames while the buildings pass beside it finished seven; it was killed to give
the box back. Whether that is a defect in the tool or the cost of software
rendering under contention is **not established** — `R9.4-remainder-6` says so
plainly rather than guessing.

---


---

## R7.2 — NPC villagers and interior polish
`f33ed92` on `main` (owner-directed interactive session working Phase -0.5
through Phase 1; the commit landed via this session's own auto-rebase onto
`main` once `RB4`/the vegetation fix shipped underneath it — see its own
message for the technical summary).

Three villagers (Mira, Oskar, Tam) stand in the village square, placed by a
new `scripts/world/village_npcs.gd` from a new `data/config/village_npcs.json`
— same data-describes/code-places shape as `village.gd`'s structures and
`sequence_director.gd`'s opening cast. Each is a plain `npc_body.gd` body
(Grandpa's own script, unmodified) offering a "Greet <name>" prompt that opens
a short flavour conversation from a new `data/dialogue/village.json`, merged
onto `dialogue_runner.gd`'s existing table additively (`opening.json`'s own
conversations and `test_dialogue_runner.gd`'s coverage of them untouched).
`DialoguePanel` is now discoverable through a `"dialogue_panel"` group in
`meadows_playground.tscn`, mirroring how `interactable.gd` already finds the
interaction arbiter — so `village_npcs.gd` reaches it without
`sequence_director.gd` changing at all.

**Villager bodies are a real decision boundary and it was not crossed.** The
only unused humanoid asset is KayKit's `Ranger.glb`, and it is a ~2-heads-tall
toon character next to the trainer/Grandpa/Warden's photoreal-ish
proportions — using it would silently pre-empt the creature/human
art-pipeline question already parked in `BLOCKED.md`, which `CLAUDE.md`
forbids inventing. Instead villagers reuse the existing Grandpa/trainer rigs
through a new `character_model.gd` `_apply_tint()`: a real material-level
palette swap (`albedo_color` multiplied per surface, texture kept) rather
than a flat recolour, driven by a new `tint` key on three new `art.json`
blocks (`villager_farmer`, `villager_keeper`, `villager_smith`).

Grandpa's house interior dressed past the "undressed grey box" both
2026-08-09 reviews named: two rugs (`_box()`'s existing flat-coloured-box
shorthand, never solid), Grandpa's own bed and a second bookcase in the
previously-empty south-west corner, a second table by the door carrying the
backpack/axe/knife his own dialogue already describes ("that pack by the
door carried me thirty years"), and a spare door leaning in a corner. Every
new solid piece's real runtime collider was checked with a headless probe
against all three lanes the opening or `smoke_opening.gd` actually walks
(stairs-foot to Grandpa, Grandpa to the door, bed to stairs-head) before the
positions in this entry were finalised — not guessed from the JSON/code
coordinates.

**Visual pass, with an honest process gap.** `ralph/conventions.md`'s rule
calls for rendering real frames and judging them with a genuinely blind
sub-agent with no knowledge of what changed. Frames were rendered for real
(`tools/capture_site_shots.gd`, two new viewpoints — `village-npcs` and
`house-interior-dressed` — plus the existing site shots, composited with
`tools/contact_sheet.gd`) and judged against `docs/reference/` using
`.claude/skills/visual-judge/SKILL.md`'s rubric. What did **not** happen as
specified: this session's toolset had no Task/Agent-spawning tool with a
result-return channel — `mcp__Claude_Code_Remote__create_session` can spawn
an independent session, but nothing in this toolset can read back what it
finds (no `list_events`, no `ListAgents` to address it via `SendMessage`),
so a genuinely blind critic could not be run and have its verdict retrieved.
The render+critique was done by this same session instead, disclosed here
rather than silently presented as the required blind pass. One real,
addressable finding came out of it anyway: the first cut of the villager
tints (`#d9a66b` / `#8fae8a` / `#7a7f8c`) read as too close to Grandpa's own
palette and to the grass at normal viewing distance — bumped to more
saturated `#c9793a` / `#4f8a5b` / `#3f5a8c` and re-rendered to confirm the
improvement. Remaining honest limitation: the Compatibility renderer this
harness is forced to use (`D06`) is explicitly not trustworthy for fine
colour/lighting judgement, so the tint legibility question is worth a real
second look whenever a genuinely blind pass becomes possible.

**Tests.** `tests/smoke_opening.gd` green with all three villagers present
(villager prompt labels are "Greet <name>", never containing "talk" or
"choose" — checked against the exact substrings the test's own interactable
lookups gate on). Full suite (`tests/run_tests.gd`) also run, since dialogue
plumbing is shared infrastructure: 299 tests, 0 failed.

**Follow-up: the genuinely-blind pass this entry's own gap disclosed now
actually ran.** The owning interactive session has the `Agent` tool the
sub-agent's own toolset lacked — spawned a fresh sub-agent with zero
knowledge of what changed, `.claude/skills/visual-judge/SKILL.md`, and 7
frames rendered from a confirmed `origin/main` checkout (`c0ca15e`, no
local uncommitted state, `tests/smoke_opening.gd` re-verified green on that
exact commit first).

The verdict found real, substantive things — sky/hill horizon fusion,
uniform-spacing vegetation scatter, and a fidelity gap between the
character/creature art and the environment art around it — but **none of
them are new defects R7.2 introduced**, checked one by one:
- The black spire on the hill in `village-square` — already `BACKLOG.md`'s
  tracked `R7.1-visual-remainder-2` ("two uneven dark spikes... reads as
  standing stones or a broken obelisk pair"), not a new finding.
- Mirrored/backwards signpost text in `village-npcs` — `signpost.gd`'s own
  documented tradeoff (labels face the arm's orientation, not the camera;
  "unreadable from behind... also true of a real wooden signpost arm, so it
  is not a regression" — R7.1-visual round 2's own comment). This
  particular viewpoint happens to catch it from behind; the geometry is
  unchanged from before this item.
- The "unset mirror material" (a flat blue oval) in
  `house-interior-dressed` — traced to the pre-existing `Mirror` furniture
  piece, not one of this item's additions (`_build_furniture()`'s diff
  adds only `BedDouble`, `Bookcase`, `Table2`, `Backpack`, `Axe`, `Knife`,
  `Door1` and two rugs — no mirror or wardrobe call). A flat-colour "glass"
  plane is a normal low-poly-pack simplification, not obviously broken.

The broader findings (horizon atmospheric haze, scatter clustering,
environment-vs-character fidelity) are real and apply across the whole
game, not to anything R7.2 touched specifically — carried forward into
`R9.4`'s full-game pass rather than chased here, which is exactly the kind
of finding that item exists to catch.

## Vegetation colour jitter — fixed a MultiMesh use_colors ordering bug
`16138ec` on `main` (owner-directed interactive session working Phase -0.5
through Phase 1). Found incidentally: a background sub-agent's render log
for `R7.2` showed the engine error "Can't set instance color on a
Multimesh that isn't using colors" **11,317 times** in one render. Root
cause in `scripts/world/vegetation.gd`'s `_build_batch()` (introduced by
`R7.1-remainder` round 2, `77421cf`): `multi.use_colors = true` was being
set AFTER `multi.instance_count = placements.size()`. `MultiMesh`
allocates its per-instance buffer at the moment `instance_count` is
assigned, sized from whichever format flags are set then — `use_colors`
set afterward reads back `true` in GDScript but never actually took effect
server-side, so every jittered grass/drygrass instance's
`set_instance_color` call failed silently (a caught engine error, not a
crash) and kept its default, unjittered colour. Fixed by reordering: set
`use_colors` before `instance_count`. Verified: 299/299 tests still pass;
a fresh headless render shows zero occurrences of the error where the
same render previously showed thousands. This means the round-1/2/3
`R7.1-remainder` visual-judge critiques were all judging a build where the
colour-jitter fix was largely non-functional — the ground-cover-still-
reads-procedural finding in `R7.1-remainder-2` may partly be a
consequence of this bug rather than the clustering/density tuning alone;
worth re-checking once a fresh render is in hand.

## RB4 — ROG Ally freeze root-caused and fixed: switched to the Compatibility renderer
`38189fa` on `main` (owner-directed interactive session; see
`ralph/STATUS.md`'s lease note). Builds on `RB4-diagnostics` (below) and
the on-device data the owner supplied 2026-08-10/11 (see `BLOCKED.md`'s
former RB4 entry, now resolved, for the full evidence trail).

**Summary of the evidence**: two separate launches on the Ally, ~25
minutes apart, both hung. The boot log shows both completing every
instrumented phase (terrain, shaders, player, ~16,700-instance vegetation
scatter, settlement) in ~6 seconds, then stopping at the identical last
line — `_ready complete, waiting for first frame` — and never writing the
next one. Task Manager during the hang: the process shows `Not
Responding`, ~1.4GB memory, but **0% CPU, 0% disk, 0% network**, never
resolving after 10+ minutes. That combination rules out the original
"slow shader compile" hypothesis (which would show CPU/GPU load) and
points at the render thread blocked on a Forward+/Vulkan call — most
likely a present or pipeline-compile fence — that never returns, specific
to this GPU/driver.

**Fix**: `project.godot`'s `renderer/rendering_method` changed from
`forward_plus` to `gl_compatibility` — sidesteps Vulkan entirely.
`docs/decisions/D01` rewritten with the full reasoning: this reverses
D01's original Forward+ choice (which bet the Ally's RDNA3 iGPU would run
it "comfortably" — that bet is what the on-device data disproves), and
notes the cost paid knowingly (no SDFGI/volumetric fog/Forward+ shadows).
One favorable side effect: Compatibility/GLES3 is already the exact
renderer every headless CI render and every `.claude/skills/visual-judge`
critique this project has used all along (D06) — the shipped build now
matches what has actually been screenshotted and graded, rather than
diverging from it.

Owner directive: fix it with the on-device data already in hand rather
than continue remote troubleshooting (boot log access was awkward on the
handheld itself). **Real on-device confirmation that the freeze is
actually gone is still worth having**, same as RB1/RB2's pattern, but
unlike those two this fix has strong, specific evidence for why it should
work, not just a plausible theory.

## R7.1-found-2 — the near-vertical bank near spawn was overlapping building pads, not a path or texture bug
`94d267c` on `main` (owner-directed interactive session working Phase -0.5
through Phase 1, background sub-agent in isolated worktree
`agent-acc396239df681ed1`; see `ralph/STATUS.md`'s lease note).

`BACKLOG.md`'s own entry (written when this was found) guessed the cause as
a steep-slope texture-projection problem on the path trench. Live sampling
of `height_at()` across the bank's cross-section proved that guess wrong:
the ground genuinely drops ~1.5m over well under a metre there (an 81°
wall) — this is a real geometry defect, not a shading/UV artefact, and has
nothing to do with the dirt path (`path_factor()` only tints colour;
`height_at()`'s chain has no path-height term at all).

Root cause: `_apply_flats()` in `scripts/world/playground_heightfield.gd`
flattens the ground under building pads (Grandpa's house, the village
square), and those two pads sit close enough that only ~0.5m of open ground
separates their circles. The old rule had the strongest-weighted pad "win
outright" and blend the whole area toward its target height alone — correct
for one pad shading into natural ground, but where two pads' skirts
overlap, the winner flips at one point, and near that flip both weights are
still ~1 (deep inside the overlap, not out at the fringe), so height
snapped nearly the full 1.6m gap between the two pads' target heights
across a couple of centimetres.

Fix, two parts: outside every pad's own radius, `_apply_flats()` now blends
the target *heights* by relative weight instead of picking one winner
outright (strictly inside a pad's radius it still returns that pad's height
alone, unchanged — the part `test_the_building_pads_are_genuinely_flat`
guards and which must stay exact to avoid the tilted-pad regression the
winner-take-all rule was originally added to prevent); and the two pads'
target heights themselves move closer together (2.2m/0.6m → 1.2m/0.9m),
continuing the same tuning direction this file already used once before.
Terrain rebaked via `build_playground_terrain.gd`.

Live-verified: worst slope within the old trench footprint is 8.5° now
(was 81°); worst slope across a wide scan of the whole village area is 25°,
on ordinary hill terrain unrelated to the pads. 299/299 tests pass,
including the unchanged `test_the_building_pads_are_genuinely_flat`.
Confirmed by a fresh blind visual-judge pass on the two originally-flagged
frames (01, 05): "No near-vertical earthen bank and no dirt-trench gouge in
either frame... a gentle, continuously-curved rolling hill." The same pass
found one new, smaller, unrelated defect — see `BACKLOG.md`'s new
`R7.1-found-3` entry (a texture-splat stripe on the same hillside, not
touched by this fix, which only changed height/geometry).

---

## R7.1-remainder — PARTIAL: ridge-bias clumping and ground-cover clustering shipped, neither bullet fully passes the blind critic after 3 rounds
`af6e2fc`, `77421cf`, `44ec290` on `main` (owner-directed interactive
session working Phase -0.5 through Phase 1, see `ralph/STATUS.md`'s lease
note, not a normal Ralph firing).

Three rounds, each rendered and judged blind against `docs/reference/` via
`.claude/skills/visual-judge` per the visual-gating convention.

**Horizon/mid-ground clumping** (`scripts/world/scatter_rules.gd`): a new
`ridge_bias` layer parameter, and `_clump_centre()` now searches a local
neighbourhood (`RIDGE_SEARCH_RADIUS` 140m, `RIDGE_CANDIDATES` 6 samples)
around each clump's own unbiased draw for higher ground, rather than a
blanket density increase. Round 1's first version searched candidates
globally across the whole map, which concentrated the bias toward the
map's 2-3 tallest named peaks and did nothing for the horizon in most
compass directions — caught by direct inspection of round-1 renders (the
horizon in frames 01/04 stayed bare despite the "fix") and redesigned to
the local-search version before round 2's critique ran on it. `trees`
layer set to `ridge_bias: 0.75` in `data/config/vegetation.json`. New
tests `test_ridge_bias_of_zero_changes_nothing` and
`test_ridge_bias_of_one_prefers_higher_ground` in
`tests/test_scatter_rules.gd`.

**Ground cover clustering** (`scripts/world/vegetation.gd`,
`data/config/vegetation.json`): raised `grass`/`drygrass` tuft scale
ranges, added per-instance MultiMesh colour jitter (new `colour_jitter`
layer key, via `set_instance_color` + `vertex_color_use_as_albedo`) for
value variation with zero extra draw calls, and cut `strays` across rounds
2-3 (grass 2000→500, drygrass 700→200) so the remaining tufts read as
clumps with real gaps rather than even confetti.

**Round-3 (final, per the 3-round cap) blind critique verdict**: genuine,
visible improvement over the pre-fix state — 03-rise-overlook and
04-three-quarter both show real clump/clearing structure that wasn't there
before — but the critic, still blind to what changed, named both original
bullets as **not yet passing**: ground cover still "appear[s] at roughly
even spacing and uniform scale... no clearings, no clustering around
features"; and the horizon/mid-ground still shows "no middle-distance
layering anywhere in the set," which the critic ranked as the single
biggest reason the frames feel empty compared to both references. Handed
back as an honest remainder, not a false done — see `BACKLOG.md`'s new
`R7.1-remainder-2` entry for the specifics and what a next pass should try
differently.

**One critique finding investigated and resolved as a non-issue**: the
critic flagged "a flat grey rectangular box floats just above the grass
near the player" in frames 01 and 05 as a likely leaked debug marker.
Traced to `scripts/world/harvest_node.gd`'s deliberate placeholder visual
(a slot-coloured box; `CLAUDE.md`'s prototyping rule explicitly allows
placeholder geometry to prove a mechanic) for the wood-gathering node at
`(-8, 8)` in `data/config/harvest.json`, near both frames' shared eye
position. Not a bug — a critic with no knowledge of the game's systems has
no way to tell a deliberate stand-in from a leaked gizmo. No action taken;
recorded here so the next reader doesn't rediscover the same box and
wonder.

---

## R7.1-found — moved the rise-overlook survey eye off the tower cluster
`eb880cb` on `main` (owner-directed interactive session working Phase -0.5
through Phase 1, see `ralph/STATUS.md`'s lease note, not a normal Ralph
firing). `tools/survey.gd`'s `03-rise-overlook` eye moved from
`(148, -102)` to `(190, -60)` — still on the same rise (`landmark.gd`'s
`RISE_CENTRE` radius), but ~60m from the stronghold silhouette's tower
cluster instead of ~14-24m, so the viewpoint frames the intended wide
valley shot instead of one tower point-blank. Verified by re-rendering:
the tower cluster is now a small, correctly-distant shape at frame edge
instead of filling most of the frame. Moved the eye, not the towers, since
`R7.1-visual-remainder-2` (still open) may reshape them again.

---

## R7.1-visual-remainder — the stronghold silhouette gets a wall, roofline and crenellation
`7e17d40` (new geometry: perimeter wall, peaked roof on the keep, stepped
mass and crenellation rings on the others — pushed by an earlier firing,
session -j) + `eed557e` (widened base drum and connecting wall, so the shape
survives the required blind-critic pass — this firing). Both fast-forwarded
to `main` (verified via `origin/main`'s own log).

**Process note, since this is unusual:** `7e17d40` shipped clean — CI green
(run 31427097069), release dispatched and succeeded (run 31427521553) — but
the firing that pushed it died before running conventions.md's required
render + blind visual-judge pass for visual-affecting work, and before any
BACKLOG.md/DONE.md bookkeeping. This firing found that on claiming the lease
(the `ralph-status` entry was still `started`, but `main`'s own tip and the
now-deleted task branch corroborated a real ship, not a dead mid-push
firing — the same class of near-miss the RB3 story in this file already
documents, resolved the same way: check `main`, not the raw lease
timestamp). Rather than treat 7e17d40 as someone else's unfinished work to
redo, this firing finished it: ran the missing verification, found real
defects, fixed them, and is recording the whole thing as one entry since
it's genuinely one piece of work split across two firings.

**The three-round blind-critic loop, run for real** (fresh subagent each
round, zero knowledge of what changed, per conventions.md):

Also found and fixed along the way, not part of the loop itself: my first
attempt at rendering used `godot --headless ...`, which is *not* what
`tools/capture_wayfinding.gd`'s own header comment specifies. Headless mode
apparently never fires the `await RenderingServer.frame_post_draw` the
script's last step depends on — the render hung for 90+ CPU-minutes with
zero output before this was caught and killed. Dropping `--headless`
(matching the documented invocation exactly) fixed it outright; the same
render then completed in under a minute. Left as a note here since the next
firing that reaches for this tool could easily make the same mistake.

**Round 1** (base drum 3m tall, bare crenellation boxes): failed. "The
three towers read as 'standing stones' or 'obelisks'" was R7.1-visual's own
finding, unchanged — 7e17d40's geometry alone didn't move it. Specific
findings: long range collapsed the whole structure to two ambiguous prongs
(the straight wall segments between towers go edge-on and vanish depending
on camera bearing, so nothing visibly joined the two nearest towers);
crenellation merlons read as "claws, broken glass, or a jagged rock spur,"
not a battlement, once they stopped resolving as separate boxes.

**Round 1's fix:** base drum 3m → 9m tall (a cylinder's silhouette width is
angle-independent, unlike a straight wall, so a tall drum reads as a solid
plinth from any camera bearing); added a solid collar ring under each
tower's crenellation merlons so the notched top has a continuous base to
sit on instead of floating separate boxes.

**Round 2:** close range now "reads clearly and unambiguously as fortress
architecture" — the fix worked there. Long range still failed: "two dark
vertical prongs... closer to standing stones/rock spires/chimneys than a
stronghold." Real diagnosis, not a guess: the widened base drum sits at
0-9m elevation, and that's exactly the elevation a distant, low, grazing
camera has occluded behind the ridge's own nearer terrain — the same reason
a fence looks taller than the house standing behind a hill crest from far
away. The only part of the structure confirmed visible in every long-range
frame was the towers' upper portions.

**Round 2's fix:** raised the connecting WALL itself (not just the base
drum) from 11m to 16m — still under every tower's own height (shortest is
west at 18m, preserving "towers read as the skyline's tallest shapes") but
tall enough to bridge the towers' visible upper portions instead of their
already-occluded feet. Wall thickness 1.6m → 2.8m for more presence.

**Round 3 (the cap):** real, measured improvement, not yet a full pass.
Close range: "passes, clearly." Mid range: "passes, with a soft spot" (one
tower's cap reads as a chimney rather than a turret, but its castellated
neighbour still anchors the read). Long range: "does not confidently pass
on its own... reads just as plausibly as twin standing stones, dead trees,
or a broken obelisk pair." Per conventions.md's three-round cap, stopping
here rather than a fourth round — opened as the narrower
`R7.1-visual-remainder-2` in `BACKLOG.md`, the same pattern this file's own
R7.1-remainder entry already uses. Two smaller round-3 findings recorded
there instead of chased in this task: the north tower's cap shape, and the
terrain mound's hard material transition (existing `R7.1-remainder`
territory, not a new bug from this change).

**Confirmed not the same defect as R7.1-visual's own colour/value work**:
that job holds — the critic never once mentioned washing out or blending
into the sky/terrain at any of the three rounds' three distances. This
task was shape-language only, as scoped, and shape-language is what moved.

---

## R7.1-visual — blind-reviewed the signposts and stronghold silhouette, three rounds
`206fd77`, `c03c978`, `d73dd8f`, `5a22f78`, `581b351`, `d27fb49`, `3a22d00` on
`ralph/R7.1-visual`, all fast-forwarded to `main` (verified via `origin/main`'s
own log, not by trusting CI). `tests: none` per the backlog item's own field;
CI's standard import + Windows export ran clean on every push. New
`tools/capture_wayfinding.gd`: close-up viewpoints for exactly these two
features, since neither is what the fixed five-viewpoint `tools/survey.gd`
exists to frame (R7.1-found already caught its `03-rise-overlook` sitting 14m
from the same towers by coincidence).

R7.1 shipped these two features verified only by the shipping firing
rendering a frame and reading it itself. This ran them through the actual
blind critic three times, the cap `conventions.md` sets, fixing what each
round named:

**Round 1** (signpost: `ARM_SPACING` 0.5→0.75m and `ARM_START_HEIGHT`
2.2→2.9m — four billboarded labels were stacked close enough to be "fully
unreadable, reduced to fragments"; added a triangular-prism arrowhead per arm
and a light `outline_size`/`outline_modulate` on the label text, which had
none and vanished crossing dark backgrounds. **Silhouette:** the critic's
frames showed the towers reading correctly dark at ~40m but fading to a pale
grey nearly matching the horizon haze at ~60m and ~157m — confirmed by
re-rendering the same viewpoint with `WorldEnvironment.fog_enabled` forced
false, which restored the dark read. That is the shared fog
(`art.json`'s `aerial_perspective`, already tuned once against a documented
"fog eating the world" complaint) — retuning it globally for one landmark
needs the whole-survey re-verification R9.4 exists for, not a change buried
in this task. Switched `landmark.gd`'s tower material to an unshaded,
`fog_disabled` `ShaderMaterial` instead, so the silhouette stays a flat dark
shape regardless of distance or sun angle (this also removed a bright lit-
seam highlight the critic named on the near frame), and added a low base
drum under the four towers.

**Round 2:** the critic's strongest complaint was that a billboarded label
"floats... overlapping a diagonal wooden plank rather than sitting on it, so
plank and text disagree about angle and position," with an arrow shape
visibly overlapping letters in two labels — a real perspective artefact,
since a billboard always faces the camera regardless of the plank's true 3D
angle. Fixed the text to the arm's own orientation instead of billboarding;
it now reads correctly for someone standing at the post looking outward
along the arm, unreadable from behind, the same as a real signpost arm. A
first attempt at the needed rotation (`rotation.y = PI`) mirrored every
letter — caught before the next critic round by rendering and looking,
fixed by removing the extra flip (`Label3D`'s default non-billboard facing
was already correct).

**Round 3:** the critic caught two arms visually crossing in an X near the
post top, swallowing the apostrophe in "Grandpa's House" — every arm's
origin sat exactly on the post centreline, so from a viewing angle where two
opposite-ish bearings compress toward the same screen height their planks
radiate from what looks like one point. Fixed by mounting each arm around
the post's circumference at the golden angle (137.5°) per index — separate
mounting points around the pole, the way a real multi-arm signpost is built,
spreading any arm count evenly without hardcoding the route total. Verified
by re-rendering and looking directly (not a fourth critic round — the cap is
three, and this was a specific, well-understood geometry fix, not a fresh
unknown).

**What round 3 confirmed already fixed:** the silhouette holds a dark, solid
value at all three distances with "no z-fighting, texture stretching, or
mirrored-geometry bugs... anywhere on the silhouette" — the fog fix and the
round-1 material change both verified to hold under a genuinely blind pass.

**What is still open, by design rather than oversight:**
- **The stronghold towers read as "three standing stones" or "obelisks," not
  as a fortress** — round 3's own words: "no amount of repositioning,
  recoloring, or distance/fog adjustment on the current three prisms will
  make it read as fortified architecture." This needs new geometry (a
  connecting wall silhouette, varied massing, a roofline) — see the new
  `R7.1-visual-remainder` backlog entry. Not a config or placement fix, and
  not invented here.
- The hill's material inconsistency (green up close, tan/dirt at range) and
  bald-dune look from far away are the same already-tracked defects as
  `R7.1-found-2` (path-trench texture stretch) and `R7.1-remainder`
  (continuous ground cover) — the towers' hill happens to sit near both, not
  a new bug.
- One signpost arm is partly hidden behind foreground flowers in the main
  close-up frame; minor, and scene-dressing placement rather than the
  signpost itself, left for whoever next touches vegetation near the square.

## RB4-diagnostics — startup boot log for the Ally black-screen freeze
`9c08b6c` on `ralph/RB4`. `tests: none` (per the backlog item's own field;
this is a diagnostics-only change with no automated behaviour to assert).

**PARTIAL, by design — the backlog item's own two-part instruction.** RB4's
own text asks for two things in order: ship startup diagnostics regardless
of what else is found, then ask the owner for on-device data since nothing
else is actionable without it. This entry is the first half; the second half
is now `BLOCKED.md`'s "RB4 — ROG Ally black screen root cause needs
on-device data" entry.

New `scripts/boot/boot_log.gd`: a plain `RefCounted` with one static
`line(message)` that appends a timestamped line to `user://boot_log.txt`
(`%APPDATA%/Godot/app_userdata/Tetherbound/boot_log.txt` on the exported
Windows build — the same directory `user://settings.json` already writes to,
`D15`). Appends rather than truncates, with a `=== launch ... ===` marker
per process start: the freeze this chases leaves the process "Not
Responding" rather than crashing, so a killed-and-relaunched attempt must
not erase the stalled run it was trying to capture. Never fatal — a file
that fails to open just drops the line.

Called from `autoload/game_state.gd`'s `_ready()` (autoload boot, first and
last lines) and `scripts/world/playground_world.gd`'s `_ready()` at every
major phase: terrain node created, terrain `data_directory` assigned,
ground shader applied, player placed, vegetation scattered, settlement
built, and first frame presented after the closing `await
get_tree().process_frame`.

Verified by actually running it, not just reading the code: fetched Godot
4.7 (`tools/art_pipeline/setup.sh godot`), installed `libegl1`/
`libegl-mesa0`/`mesa-vulkan-drivers`, ran a clean `--headless --import` (no
errors; `boot_log.gd.uid` auto-generated the same way every other script's
does), then `tests/smoke_playground.gd` — the smoke test's own assertions
passed, and the real log file it produced
(`~/.local/share/godot/app_userdata/Tetherbound/boot_log.txt`, the Linux
equivalent path) showed one clean timestamped line per phase in the right
order, confirming the writer works end to end rather than just compiling.

Next step is on the owner: the boot log's last line from an actual frozen
Ally run, plus Task Manager CPU/GPU state, whether it ever resolves, and
windowed-vs-fullscreen — see `BLOCKED.md` for the full ask.

---

## R7.1-remainder — PARTIAL: the olive/lime ground seam fixed; world-ends-40m and continuous ground cover still open
`505a8f8` + `a049579` (bookkeeping) on `ralph/R7.1-remainder`, fast-forwarded
to `main` (`origin/main` moved `0f1b491..a049579`) — verified via `main`'s own
commit log and by fetching `origin/main` directly, not by trusting CI.
`tests: smoke_traversal` — 3 consecutive clean runs locally, and green again
in CI's `verify-core` job on the actual shipped commit.

**Root cause, found by rendering (not reasoning from the code):**
`tools/survey.gd`'s `01-spawn-outward` and `05-spawn-low-sun` viewpoints (near
the flattened spawn pad, an ordinary hillside boundary) showed a saturated,
zero-blue-channel green stripe against a dark marbled field — R7.1's own
investigation only ever rendered `03-rise-overlook`, whose eye sits ON the
ridge silhouette's rise and is already past whatever the bug's threshold is
either way, so the seam never showed there. Confirmed live, by dumping
`Terrain3DMaterial`'s and `Terrain3DTextureAsset`'s own property lists:
`auto_shader` picks the base/overlay texture by slope at a threshold this
Terrain3D build exposes **no control over anywhere reachable from script** —
no `auto_slope` property, no per-texture slope/height range. On this
terrain's rolling-hills noise that threshold sits low enough that almost the
whole map read as the overlay (rock) texture, with only near-flat ground
reading as the base (grass) texture.

**Fix:** `build_playground_terrain.gd` now paints the REAL control map at
bake time (`_paint_control_map`), per pixel, with the same three-tier
grass/soil/rock slope thresholds already authored for the colour map
(`_ground_colour`) — `auto` off per pixel instead of left on Terrain3D's
opaque built-in cutover. Soil is a real texture in play for the first time.
Verified by rebaking and re-rendering all five survey viewpoints: the seam is
gone in every one, including `03-rise-overlook`.

**New process followed, owner directive 2026-08-10 (`conventions.md`,
"Visual-affecting work needs a blind pass"):** ran `.claude/skills/visual-
judge` blind against the post-fix survey before calling this done. The critic
was told nothing about what changed. It did **not** flag the olive/lime seam
at all — corroborating the fix — but named a new, separate defect: the
authored path trench's steep banks read as "a broken decal" from texture
stretching on a near-vertical face, present before this fix too (pre-existing
geometry, not introduced by the control-map change). Logged as
`R7.1-found-2` rather than chased in this same task, per the new rule's own
"up to three rounds, then hand back" — this was round one, on a defect
outside the ground-seam's own scope.

**Also queried directly, not asserted:** `RULES.all_placements()` genuinely
spreads every vegetation layer to the 512m world edge (`trees`: 102/178
instances beyond 200m from origin, none inside 40m) — "the world ends 40m
out" is real but narrower than it sounds; the pale hills filling most distant
frames are `world_background = NOISE`, Terrain3D's own procedural
continuation past the baked region, which cannot carry props by construction.
Rewrote `BACKLOG.md`'s R7.1-remainder entry with this finding rather than
leaving the original framing standing.

**Not attempted this pass:** world-ends-40m-out's real fix (biasing clumps
toward ridgelines the camera actually silhouettes against) and continuous
ground cover (re-tuning grass/drygrass density or scale against the now-fixed
ground texture) — both left as `BACKLOG.md`'s (slimmer) R7.1-remainder entry.

**Process note for whoever reads `ralph-status` history:** this task's own
branch got rebased mid-firing when a separate session's `0f1b491` (CI split,
visual-gating rule, lease-safety fixes) landed on `main` first. The rebase and
force-push were correct and the resulting CI run genuinely re-verified
everything (confirmed by reading its actual job list, not just its green
conclusion) — a `ralph/R7.1-remainder-v2` branch was cut from `main` out of an
initially-mistaken worry that the force-push's CI diff had skipped
verification; it hadn't (the rebase pulled in `0f1b491`'s own large diff,
`.github/workflows/ci.yml` included, which alone is enough to mark the push
code-bearing). `v2` is now redundant and will show a failed `ralph-merge` run
once its own CI completes (its commit isn't an ancestor of the `main` that
already shipped via the original branch) — that failure is expected, not a
bug; nothing further to do with `ralph/R7.1-remainder-v2`.

## R7.1 — Wayfinding polish, PARTIAL: signposts and the ridge silhouette shipped
`3213f7a` on `ralph/R7.1` (fast-forwarded to `main`, verified via `main`'s own
commit log: `origin/main` moved `966c1cb..3213f7a`). `tests: smoke_traversal`
— 3 consecutive clean runs, given the test's own flake history.

Two of R7.1's five bullets, not all five — the rest are still on `BACKLOG.md`
under a new R7.1-remainder entry rather than silently dropped:

- **Signposts at the village square** (`scripts/world/signpost.gd`): one
  billboarded-label arm per `data/config/terrain_playground.json`
  `paths.routes` entry, built from that route data itself (a `label` field
  added to each route) so a new destination gets a sign arm for free. Post
  placed a few metres off the well, which already stands at the routes'
  shared origin `[10,-10]`.
- **The stronghold silhouette on the ridge** (`scripts/world/landmark.gd`):
  four dark angular placeholder towers on the rise at `[140,-90]` — the M7
  "distant landmark" the site-frames critique named directly. Placeholder
  geometry, matching `CLAUDE.md`'s allowance for that; the real stronghold
  approach and presentation are R8.2's job once Meadows is further along.

Both verified by rendering close-up frames (a custom throwaway camera
script, not committed), not just by reading the code — the labels were
initially unreadable, overlapping head-on due to billboard behaviour, and
that only showed up in a render.

**Also fixed, found while chasing the ground-seam bullet**: confirmed by
instantiating a live `Terrain3DMaterial` and reading its own
`_get_shader_parameters()` that `world_noise_scale/height/region_blend/
lod_distance/max_octaves/min_octaves` and `auto_slope`/`auto_height_reduction`
are not real uniform names on this Terrain3D build (removed from
`terrain_playground.json`, finding recorded in place — same precedent as the
existing `_comment_dual_scale_removed`). Separately, `macro_variation1/2`,
`noise1_scale`, `noise2_scale`, `noise1_angle`, `blend_sharpness` and
`mipmap_bias` **are** real and **do** apply — forcing extreme values visibly
changed the render — even though `get_shader_param()` reads all of them back
as `null` after every `set_shader_param()` call. `_apply_ground_shader`'s
"ignored N settings" warning was trusting that broken readback and had been
false-flagging those seven as dead for as long as the config carried them.
Fixed to check `_get_shader_parameters()`'s real key list instead of the
unreliable readback. `enable_macro_variation` — present in intent via
`macro_variation1/2` for two rounds of tuning but never actually set `true`
— is now on.

**What did NOT get fixed: the seam itself.** Widening the bake-time
slope-colour blend (`colour.blend_deg` 7→18) and raising the soil/rock
slope thresholds, then doing a full terrain rebake, produced no visible
change on the one viewpoint tested — and that viewpoint turned out to be
standing on the rise itself, whose slope was already well past both the
old and new `rock_slope_deg` either way, so the test never touched an
ordinary hillside actually misclassifying. Reverted rather than shipped as
an unverified guess. **Continuous ground cover** (grass still reads as
isolated tufts) and **populating the mid/far distance bands** more broadly
are also still open. See `BACKLOG.md`'s R7.1-remainder entry.

## RB3 — Fix `tests/smoke_aggression.gd`'s intermittent flake
`0a11b5c` on `ralph/RB3`. `tests: smoke_aggression` — 36 consecutive clean
runs after the fix, reproduced against a ~40% failure rate before it using
the same frame-by-frame instrumentation, per `ralph/conventions.md`'s
instruction not to trust a single green run.

Not an aggression-logic bug, a pathing regression, or the rocky rise's
geometry — all three were live hypotheses in `BACKLOG.md` and all three were
wrong. The real cause, found by actually running the test dozens of times
with position/velocity logging rather than reading the code: the trainer's
own `AllyPal` (`follower_pal.gd`) stops closing the gap once inside
`_stop_distance` (3.0m) with no awareness of which side of the trainer it
ended up on. The test's peaceful half walks toward Bramblebun, then the
aggressive half immediately reverses toward Galecrest — so the pal trailing
behind on the first leg is standing squarely in the trainer's path on the
second, and two solid `CharacterBody3D` capsules aimed straight at each
other simply stop dead (velocity pinned at exactly `(0,0,0)` for the rest of
the walk budget, confirmed over multiple repro runs). Nothing about this is
test-specific: any player who turns around with their pal in tow can hit the
same wall in real play.

Fix: `follower_pal.gd`'s `set_following()` takes the ally off every physics
layer while it is following (peaceful exploration), so it can never block
the trainer, and restores normal collision the instant combat takes over.
Scoped to the following state specifically, not the body's whole lifetime —
tried the wider version first (collision off permanently) and it silently
broke `smoke_catching.gd` ("the pal moved 4.04m on the stick while aiming"),
because `wild_pal.gd`'s `_spaced_config()` keeps fighters apart by real
collision, not distance math alone. Re-ran `smoke_combat` and
`smoke_catching` by hand after narrowing the fix; both green.

## R5.1 — Day/night cycle
`e4a0fb5` on `ralph/R5.1` (fast-forwarded to `main`, verified via `main`'s
commit log and CI: run 31366654851 on `ralph/R5.1` went green, Release +
Ralph auto-merge both succeeded at `e4a0fb5`). `tests: test_day_cycle` (new).

`world_look.gd` had a full named-preset time-of-day system since the
overhaul, but nothing ever called `apply_time()` after `_ready()` — noon,
forever, and `grandpa_road`'s "make camp before dark" line had nothing
behind it. Both 2026-08-09 blind reviews named this a top-three gap.

`scripts/world/day_cycle.gd` (new, pure-logic `RefCounted`, pinned by
`tests/test_day_cycle.gd` per D02): elapsed real seconds → hour of day →
which named `art.json` preset is due, and `is_dark(hour)`. `art.json`: day/
golden now carry an hour (8/18), plus a new night preset (procedural-
gradient sky, moonlight-strength sun) and tunable `day_length_seconds`/
`dark_from_hour`/`dark_to_hour`. `world_look.gd`'s `_process()` advances the
clock and snaps to whichever preset is due; `apply_time()` now also resyncs
the internal clock to the hour it just applied, or `tools/survey.gd` picking
a time by name for a screenshot would be silently undone by the very next
tick. `camp.gd`: rest also resets the clock to morning.

Verified beyond the named test: full suite (297 tests) green through the
headless SceneTree runner, and `tests/smoke_free_build.gd` (plants a real
camp, rests through it) green end to end — "[camp] rested; day 2". One real
bug caught before shipping, not by a test (nothing here is scene-testable
per D02): `apply_time()` needed the clock resync described above.

Took two rebases to land: `main` moved twice underneath it (VP2's docs
commit, then RB3's) before `ralph/R5.1`'s CI finished. Verify the ship by
looking at `main`, never at a single CI result, when that happens.

Deliberately not done, out of scope: no gameplay effects from darkness
(nocturnal spawn gating is R5.3's task, per D20).

## VP2 — Fix `tools/preview_creatures.gd` rendering zero creatures
`ce6205d` on `ralph/VP2` (fast-forwarded to `main`, verified via `main`'s
commit log and CI: Release + Ralph auto-merge both green at `ce6205d`).
`tests: none` (as named on the backlog item).

Three real bugs, all found by actually running the tool under Godot 4.7
headless, not by reading the code:
1. `BODY.new()` built a bare `CharacterBody3D` instead of instantiating
   `scenes/pals/pal.tscn`, so every `@onready` child lookup
   (`$Collision`/`$Model`/`$Body`/`$Head`) failed silently. Fixed by
   instantiating `pal.tscn` and attaching the script before `add_child()`,
   matching `encounter_director.gd`'s own pattern.
2. Once building succeeded, `setup()`'s `is_inside_tree()` guard was still
   false through `_init()`'s whole synchronous burst. Fixed with one
   `await process_frame` before building anything — the same quirk
   `render_bounds.gd`'s header already names for `global_transform`.
3. With both fixed, models still didn't render: every body is a
   `CharacterBody3D` and the preview card has no floor collider, so
   gravity dropped each one out of frame over the 120-physics-frame wait
   before the screenshot. Fixed with `set_physics_process(false)` right
   after `setup()`.

Verified by looking at the actual rendered PNG: all 17 species visible at
their gameplay heights beside the trainer-height bars, zero engine errors.

This closes out the mechanical half of Phase -0.5's tooling debt — the
tool built to catch cross-species scale errors now works, ahead of R5.1/
R7.1/R7.2/R9.4 which need it.

## VP1 — Fix `tools/survey.gd`'s stale viewpoints
`153f802` on `ralph/VP1`. `tests: none` (as named on the backlog item).
Verified by actually running
`tools/survey.sh` against the live world (Godot 4.7-stable fetched fresh via
`tools/art_pipeline/setup.sh godot`, `libegl1`/`mesa-vulkan-drivers`
installed, import cache built) and inspecting all five rendered frames —
not just asserting the fix.

**Both bugs' real causes turned out to be different from what the backlog
entry and the 2026-08-09 review guessed, found by instrumenting the actual
running scene rather than reasoning from the code:**

- **01/05** ("renders the farmhouse interior"): not the farmhouse. The
  overhaul (D18) placed `village.json`'s Barn at world `(2, 2)` — 2.8m from
  an eye sitting at `(0, 0)` and lying almost exactly on the old
  `(150, 120)` target line (perpendicular distance 0.31m). The camera was
  nose-against the barn wall, rendering its unlit inside. Confirmed by
  dumping every Node3D within 30m of the eye position and reading off
  `Barn_Collision` at `(2, 2, 2)`. Fixed by moving the eye to `(-9, -7)`
  (nearest structure now 14m+ away) and re-aiming at the pond-valley path
  instead of back through the village.
- **03/04** ("camera embedded in terrain, stale heightfield"): the
  heightfield was never stale — `ground_height_at()` (the real baked
  Terrain3D query) and `playground_heightfield.gd`'s pure recomputation
  matched exactly (diff 0.00) at every point checked, including both
  viewpoints' eye and peak coordinates. The real bug: `_place_actor()`'s
  fallback for viewpoints with no `actor` key parked the player at a fixed
  `(9000, 200, 9000)`, nowhere near the baked 512m world. That silently
  broke Terrain3D's own mesh streaming for the whole scene, not just around
  the player — proven by re-rendering 03 and 04 with their *original*,
  unchanged eye/target/horizon and only the player left near the camera
  instead: both rendered correctly, real ground and all. Fixed by parking
  the player 500m straight down from the eye's own XZ instead — inside the
  region Terrain3D is already streaming for that shot, and far enough below
  ground to stay out of every authored frame. No coordinate changes were
  needed for 03 or 04 themselves.

All five frames now render real geometry (`_flatness` spread 1.41-1.57
across the board, comfortably above the 0.01 failure floor) and were
visually confirmed by eye, not just by the spread check. `tools/survey.sh`
exits clean with no `FAIL:` lines.

Next firing on `R9.4`/anything that re-runs the survey: the fix is in
`_place_actor()` itself, so any future viewpoint added without an `actor`
key is safe by default — no per-viewpoint parking logic needed.

## RB1 — Mouse look does not work
`1eeb4c1` on `ralph/RB1`. `tests: smoke_menu, smoke_opening` (no `tests:`
field was named on the backlog item; these were the two smoke tests that
already exercise `Input.mouse_mode` end to end, so they were the closest
thing to a relevant regression suite).

**Diagnosis, confirmed by reading the code (not by reproducing the bug —
that needs real Windows, see below):** `playground_world.gd`'s `_ready()`
set `Input.mouse_mode = MOUSE_MODE_CAPTURED` exactly once, unconditionally,
at the end of boot, and nothing ever re-asserted it. That is a known Godot/
Windows gotcha: a capture request made before the native window has
actually received OS input focus can be silently dropped — `Input.mouse_mode`
still reads back CAPTURED, so nothing downstream (including a test) can
tell the difference, but the cursor is never really confined and
`camera_rig.gd`'s `_unhandled_input` (which only turns mouse motion into
look when `Input.mouse_mode == MOUSE_MODE_CAPTURED`) never receives real
deltas. That matches the owner's report exactly: everything else worked,
mouse look did not, from the first frame.

**Fix:** `playground_world.gd` now connects to `Window.focus_entered` and
re-asserts capture on every focus gain (boot included), through a new
`_capture_mouse_if_free()` that backs off via `_mouse_wanted_elsewhere()`
whenever the pause menu, the dialogue panel or the naming prompt currently
owns the mouse — so a focus regain while one of those is open cannot yank
the cursor out from under it. This is additive: the original unconditional
boot-time call still happens (nothing was open yet), so no existing
behaviour changed; the new path is the retry on every subsequent focus
event, which is exactly the moment a dropped boot-time capture needs one.

**The Grandpa-interact report, checked as the item asked:**
`interaction_arbiter.gd` is purely proximity + button (`interaction_offer`
by distance, `Input.is_action_just_pressed("interact")`) — nothing in it
reads `Input.mouse_mode` at all, and `smoke_opening.gd`'s beat 3 (talking to
Grandpa) passes headless, so the arbiter's own logic is sound when the
player can reach him. The most likely explanation, not a confirmed one: if
the owner was playing mouse+keyboard with the camera stuck at its spawn
yaw, they may simply have been unable to turn toward Grandpa to get in
range — a symptom of RB1, not a second bug. Left unfixed on purpose: there
is no independent diagnosis to fix, and inventing one without evidence is
exactly what this loop is told not to do. Worth the owner specifically
re-checking after this fix, before anyone spends more time on it.

**What is NOT proven, and cannot be from here:** whether real OS-level
mouse capture actually happens on an exported Windows build. Per
`smoke_menu.gd`'s own long-standing note, the dummy `DisplayServer` under
`--headless` reports `Input.mouse_mode` as VISIBLE no matter what is
requested — it cannot even confirm the *original* boot-time capture landed,
let alone this fix's retry path. `smoke_menu.gd` gained a new check
(`_check_focus_recapture_respects_open_ui`) that proves what headless CAN
prove: `Window.focus_entered` is genuinely connected to the recapture
method, and `_mouse_wanted_elsewhere()` correctly tracks the menu's open/
closed state. Both `smoke_menu` and `smoke_opening` ran clean locally (Godot
4.7-stable, fresh import cache). **This item is not closed until the owner
confirms on the actual Windows build** that the mouse turns the camera from
the first frame, through menu open/close and the name-entry screen, and
stays captured — recorded here rather than claimed as tested coverage that
does not exist.

---

## RB2 — Player has no walk/run animation
`<pending>` on `ralph/RB2`. `tests: smoke_input` (extended to assert the
loop mode, not just that position changed).

**Superseded below.** This item was first marked "verified already fixed, no
code change needed" earlier in this same firing, on the strength of
`current_animation`/bone-delta checks and log traces alone. The owner played
the actual build, saw the animation was NOT there, and said so plainly: fix
it for real, don't just read the code. That correction was right — the
verification had a real hole in it (see below) and there was a real bug.
Leaving the wrong conclusion in place rather than retracting it would make
this log untrustworthy, so it stays, corrected in the open rather than
quietly edited away.

**The actual bug, found by getting real screenshots instead of trusting
`current_animation`:** every clip `tools/art_pipeline`'s `animate_humanoid.py`
bakes into a humanoid `.glb` ships with `Animation.loop_mode = LOOP_NONE` —
confirmed by loading `trainer_lod0.glb` directly and reading it off the
resource (idle, walk, sprint, jump, throw: all `LOOP_NONE`). `pal_animator.gd`
already knew to work around this for creatures — its `_play()` sets
`animation.loop_mode` on every call, per clip, based on whether the role is a
loop or a one-shot. `scripts/characters/character_model.gd`'s `play()` (the
equivalent for the trainer, Grandpa and the Warden) never did. Between them:
`play("walk")` plays the 1.38s clip once, then sits on `_current == "walk"`
and never calls `_anim.play()` again for as long as the trainer keeps
walking, because the guard that makes cross-fades not stutter (`clip ==
_current`) also silently swallows every repeat call a continuous state makes.
The clip is real, resolves, drives real bones, and the calling code asks for
it every frame exactly as it should — and the character still freezes after
1.38 seconds, because nothing ever told the `Animation` resource to loop.

**Why the earlier verification missed it:** `current_animation` still reads
back `"walk"` after the clip stops (Godot doesn't clear it), so a check that
only reads the animation NAME sees exactly what a correctly-looping walk
would report. Bone-delta checks against the raw `.glb` in isolation (
`tools/diag_animation_moves.gd`) sample fixed points across the clip's own
declared length and never hold past it, so they cannot see a clip that plays
once and then stops on its own final frame. Only watching real rendered
frames well past the clip's length — or reading `Animation.loop_mode`
directly — shows it.

**Fix:** `character_model.play()` now takes a `looping: bool = true` and sets
`Animation.loop_mode` (`LOOP_LINEAR` / `LOOP_NONE`) before calling
`_anim.play()`, the same pattern `pal_animator.gd` already used.
`trainer_model.gd` passes `looping = false` only while `_throwing_for > 0`
(the one genuinely committed one-shot on the trainer); idle/walk/sprint/jump
all loop by default. `npc_body.gd` (Grandpa's idle) gets this for free
through the same default — his 4.04s idle was freezing too, just slowly
enough that nobody had reported it yet.

**Verified for real this time:**
- `tests/smoke_input.gd` now asserts, the instant `current_animation` first
  reports `"walk"` during a held `move_right`, that
  `AnimationPlayer.get_animation("walk").loop_mode == Animation.LOOP_LINEAR`.
  Confirmed failing against the pre-fix code (`loop_mode == LOOP_NONE`,
  0) and passing after.
- A direct resource check (`loop_mode` read off `trainer_lod0.glb`'s
  `AnimationPlayer` with no game code involved) confirms all 5 clips were
  `LOOP_NONE` before, matching the bug exactly.
- Real rendered screenshots (`xvfb-run` + `--rendering-driver opengl3`,
  properly synced this time with `process_frame` × N + `RenderingServer.
  frame_post_draw` before reading the viewport texture — the fix for the
  black-PNG problem the first verification attempt hit and didn't resolve)
  show the trainer's legs in genuinely different poses between the start and
  a few frames later into a held walk, where the pre-fix code would have
  shown the identical frozen pose both times.

**Found along the way, not chased (out of scope for this item):** with
`SequenceDirector` disabled, `move_forward` from the raw scene's fallback
spawn point (`playground_world.gd`'s `(0, 2.6, 0)`, used only before the
opening's own beats reposition the player into the house) stalls after
~1.2m over a 90-frame hold, while `move_right` from the same point covers
5.85m in the same window (`tests/smoke_input.gd`'s own numbers, unchanged
by this firing). Very likely just scatter/vegetation collision sitting
directly in the +Z direction from world origin, and the real opening never
uses that raw spawn point for free movement — but worth a look if a future
firing sees anything move-forward-shaped acting strange near boot.

---

## R0.8.5 — Full blind visual review pass, against the overhauled build
`216ce54` (review + backlog updates) on `ralph/R0.8.5`, on top of `d318a55`
(incidental missing .uid/.import sidecars from this container's first-ever
import pass — same class of fix as R0.3.5's). No tests named for this item;
CI is import + Windows export only.

One complete current-state record: the five fixed meadow viewpoints, five
staged site frames, and serial Blender turntables (four angles each) for
the trainer, Grandpa, the Warden and all seventeen pal species, judged by a
blind sub-agent per `.claude/skills/visual-judge` with no knowledge of what
changed. Full write-up: `docs/reviews/2026-08-09-r0.8.5-full-blind-review.md`.
Both bar questions came back no — top separators: no landmark in any
outdoor frame, the trainer/Warden art-pipeline gap, and flat lighting with
no time-of-day read.

What the next firing should know, all recorded in `BACKLOG.md`/`BLOCKED.md`
in more detail:
- Two real bugs found in the review harness itself (not the game):
  `survey.gd`'s viewpoints 01/05 render the farmhouse interior instead of
  the meadow, 03/04 render as if the camera is embedded in the terrain.
  `preview_creatures.gd` renders zero creatures (bypasses `pal.tscn`). Both
  are backlog items now, not fixed here.
- **Tuskroot is not still the songbird placeholder** — R4.5's backlog text
  was stale; corrected, needs `smoke_art` verification to close properly.
- Creature/human art-pipeline cohesion (Paddlenewt/Pipwing/Ripplet vs. the
  rest; trainer/Grandpa vs. the Warden) logged as a design question in
  `BLOCKED.md` — rework vs. replace is the owner's call, not invented here.

## R0.9 — Assembled the opening into the real scene. Phase 0 is done.
`6b8b572` (wiring + three opening-flow bugs) and `9dd8e38` (two more test
fixes CI caught after the first push) on `ralph/R0.9`. Both confirmed
merged by fetching `main` directly — `a414da7..9dd8e38` fast-forwarded.

Added `SequenceDirector`, `InteractionArbiter`, `DialoguePanel` and
`NamePrompt` to `scenes/world/meadows_playground.tscn` as children of the
world root, wiring the director's seven NodePath exports. Per the task's
own instructions: the arbiter's `player_path` was left unset (the
director calls `set_player()` itself once the tree is up), and neither
Grandpa nor the starters were placed in the scene (the director spawns
them from `opening.json`).

Five real bugs surfaced once the scene was genuinely wired and testable
for the first time — none were new; all were latent, waiting for the
first end-to-end run:

1. **Starter-vs-player collision blocked the walk to Grandpa.** The
   middle starter always sits on the dead-straight line from spawn to
   Grandpa (`starter_offsets()` centres the row on his facing, and that
   line *is* the approach). Sharing the default collision layer meant the
   player mounted its capsule and stopped short. Fixed by giving the
   opening's three temporary display bodies their own collision layer in
   `sequence_director.gd` — the real follower pal built later by
   `adopt_starter()` is a different instance with the ordinary setup.
2. **`smoke_opening.gd`'s own walk stopped on raw distance**, but the
   three starters' 2.6m radii overlap on purpose (3.5m spread), so a
   straight walk at an off-centre one could still leave a centred
   neighbour "winning" arbitration. Now requires proximity AND an actual
   arbitration win, matching what a real player experiences.
3. **`encounter_director.gd:186` wrote the chosen nickname to
   `display_name` instead of `nickname`** — the same bug already fixed
   once in `party_seam.gd`. `pal_instance.label()` reads `nickname` first,
   so this permanently lost the species name. This was already recorded
   in `BACKLOG.md`'s "found along the way" list; removed from there now.
4. **`smoke_combat.gd` assumed a default sandbox starter** that no longer
   spawns — `SequenceDirector`'s `_ready()` now unconditionally suspends
   it, since the opening is always in the scene. Fixed by having the test
   adopt a starter directly, the same call the opening itself makes.
5. **`combat_manager.gd`'s `_stand_the_trainer_aside()` teleported the
   trainer with a raw Y** carried from the arena's own centre instead of
   asking the world for ground height (violates `D09`). On ground uneven
   enough for the difference to clear collision, the trainer fell through
   the terrain forever. Only exposed once fix 4 shifted the engagement
   geometry. Fixed with a `_ground_height()` helper mirroring
   `pal_body.gd`'s pattern.

Bug 4's fix broke two more tests that share the same scene and the same
assumption — `smoke_catching.gd` and `smoke_aggression.gd` — caught by
real CI on the first push (`6b8b572` went red), not locally beforehand.
Both got the identical `_ensure_ally()` fix and shipped in the follow-up
commit (`9dd8e38`). **Lesson for next time a shared-scene change lands:
check every consumer of that scene, not just the task's own named test**
— `smoke_menu.gd`, `smoke_settings.gd` and `smoke_free_build.gd` were
also checked this time and confirmed unaffected.

Verified: `tests/smoke_opening.gd` passes end to end (walk, talk to
Grandpa, choose and name a starter, the pal reaches the real party).
`tests/smoke_combat.gd`, `smoke_catching.gd`, `smoke_aggression.gd`,
`smoke_menu.gd`, `smoke_settings.gd`, `smoke_free_build.gd` and the full
277-test suite (0 failed) all still pass. Real CI on `9dd8e38` green
end to end including the Windows export
(run 31318155566).

`EncounterDirector.WILD_SPAWNS` still spawns an aggressive Tuskroot that
can charge the player mid-opening, per the task's own note to decide and
say so: left as-is. `smoke_opening.gd` passing with it present confirms
it does not block the scripted flow, and an aggressive pal in the meadow
during the opening is consistent with `GAME_DESIGN.md` §14's own rule
that aggression is not gated on story state elsewhere in the game.

**Phase 0 — finish the roster is now complete.** R0.6, R0.7, R0.8 and
R0.9 are all done. The next item, R0.10, is a `▶` play gate: the owner
plays the first fifteen minutes themselves. The loop stops there, per
`ralph/PROMPT.md`.

## R0.6 — finished Reedwing (fourth and last bird species). R0.6 is complete.
`6c14a65` (shipped as `ralph/R0.6-reedwing-v2`, cherry-picked from the
original `ralph/R0.6-reedwing`'s `f97824a` after a base-mismatch — see
below). Same `clean → texture → rig --kind bird → grade → install`
sequence, no code changes needed for the fourth time running. Candidate a
(R0.4 winner), no hard-fail defect — only a minor neck-proportion note.

`rig_report.json`: 19 bones, 14,006 vertices, **0 unweighted**, idle
motion at 88% of walk. Five eye-guard rectangles added to `grade.py` —
Reedwing's eyes read differently from the other three birds: a dark
pupil-only mass with a soft catchlight rather than a bright iris ring,
consistent with a waterfowl's eye rather than a raptor's or owl's. A dark
beak-tip wedge and a glossy neck-feather specular highlight were checked
and rejected as non-eyes.

Verified in Godot: `smoke_art.gd` passes, and the standalone height-fit
script confirms the rendered model matches the declared 1.65m exactly
(R0.7's fixed figure), no footprint clamp, all six clips present.

`species.json`: filed `type: water` per R0.7's explicit instruction
(canonically Water/Air per `docs/art/wild/21_MEADOWS_WILD_ROSTER_CANON.md`,
but the schema takes one type) — worth restating plainly since it would
be easy to mistake the gameplay `type` field for the rig kind: Reedwing
is still a physical bird and `--kind bird` was correct regardless.
`aggressive: false`, moderate HP/attack/defence matching its "Swift
Glider & Messenger... support, utility" role per the Water Sheet — a
support creature like Brooktail, not a fighter.

**Second branch base-mismatch caught and fixed this session, same shape
as the Galecrest incident earlier:** `ralph/R0.6-reedwing` was branched
from what was believed to be current `main`, but `ralph/R0.6-flake-note`
(a sibling branch, docs-only) had merged moments earlier without a fresh
`git fetch` immediately before branching — `git merge-base --is-ancestor
origin/main ralph/R0.6-reedwing` confirmed the fast-forward would fail
before wasting a ~9-minute CI cycle finding out the hard way. Fixed by
cutting `ralph/R0.6-reedwing-v2` from the actually-current `main` and
cherry-picking the same commit (`f97824a` → `6c14a65`) rather than
force-pushing. The original `ralph/R0.6-reedwing` is abandoned, same as
the earlier `ralph/R0.6-bird-animation-fix-record` — harmless, cannot be
deleted from this session, safe to ignore. **Lesson restated plainly for
future firings: `git fetch origin main` immediately before creating any
branch pushed within a few minutes of a sibling branch, not "recently".**

Credit balance after this species' texture pass: **175** (was 185,
confirmed via `meshy.py check`).

**R0.6 is complete.** All twelve wild species plus the three starters now
have real production art (Tuskroot's evolved-form model remains the one
stand-in, tracked separately from R0.6's own scope). Nine species shipped
in this session alone: Burrowback, Paddlenewt, Mosshell, Brooktail,
Galecrest, Duskhush, Pipwing, Reedwing, plus the `finish.py` bird-rig fix
that unblocked the last four.

CI green, fast-forwarded to `main` at `6c14a65` — verified by fetching
`origin/main` directly; branch auto-deleted post-merge.

## R0.6 — finished Pipwing (third bird species)
`babd64f` · Same `clean → texture → rig --kind bird → grade → install`
sequence, no code changes needed for the third time running. Candidate b
(R0.4 winner), no hard-fail defect — only a cosmetic thin/blade-like
crest note.

`rig_report.json`: 19 bones, 14,002 vertices, **0 unweighted**, idle
motion at 86% of walk (well clear of the frozen threshold). Four
eye-guard rectangles added to `grade.py` — Pipwing's own "oversized teal
eyes" are large enough relative to its tiny body that they dominate
several UV islands, the strongest signature of any species yet alongside
Duskhush's. One ambiguous dark shape right beside a confirmed eye was
checked and rejected as a likely shading/seam artifact rather than a
separate instance, same caution used on every prior species.

Verified in Godot: `smoke_art.gd` passes, and the standalone height-fit
script confirms the rendered model matches the declared 1.20m exactly —
R0.7's fixed figure, the shortest in the roster — no footprint clamp, all
six clips present.

`species.json`: `aggressive: false` (Zippy Flier/Spotter, not a fighter);
lowest HP (78) and defence (10) of the wild roster so far — deliberately
fragile, matching "tiny and round" — with catch rate (0.5) set just under
Bramblebun's tutorial-only 0.55 so the tutorial creature keeps the
highest rate in the game.

Credit balance after this species' texture pass: **185** (was 195,
confirmed via `meshy.py check`).

CI green, fast-forwarded to `main` at `babd64f` — verified by fetching
`origin/main` directly; branch auto-deleted post-merge.

## R0.6 — finished Duskhush (second bird species)
`a9d9282` · Same `clean → texture → rig --kind bird → grade → install`
sequence proved on Galecrest, no new code needed — the finish.py fix from
last firing just worked. Candidate a (R0.4 winner), no hard-fail defect,
only a cosmetic brow-ridge note in the production report.

`rig_report.json`: 19 bones, 14,006 vertices, **0 unweighted** — cleaner
than Galecrest's 6/14,004. Idle motion at 65% of walk (well clear of the
6%-is-frozen threshold `rig_bird.py` flags in its own self-check). Four
eye-guard rectangles added to `grade.py`: the clearest eye signature of
any species so far — a gold outer ring, a blue/teal inner ring, a black
pupil and a white catchlight, matching the Air Sheet's own "large
gold-ringed eyes" brief and unmistakable against the grey-blue plumage.
One dark round blob near a nostril was checked and rejected (no ring, no
catchlight).

Verified in Godot: `smoke_art.gd` passes, and a standalone script
(instantiating `pal.tscn` with `wild_pal.gd`, replicating `smoke_art.gd`'s
`_rendered_height()`) confirms the rendered model matches the declared
1.55m exactly (R0.7's fixed figure — checked before writing the number,
learning from Galecrest's mistake), no footprint clamp, all six clips
present.

`species.json`: `aggressive: false` — the sheet frames Duskhush as
"Silent Watcher & Night Scout", a stealth/observation role, not a striker
like Galecrest. Lowest attack of the air roster so far; defence and HP
sit closer together than Galecrest's spread. `footprint_allowance` reused
Galewisp's 3.4 (same height, similarly-proportioned owl/fox-bird build)
rather than Galecrest's 4.2 (a bigger hawk with a wider wingspan).

Credit balance after this species' texture pass: **195** (was 205,
confirmed via `meshy.py check`, not assumed).

CI green, fast-forwarded to `main` at `a9d9282` — verified by fetching
`origin/main` directly; the branch was auto-deleted post-merge, confirming
the fast-forward actually happened rather than just going green.

## R0.6 — fixed the bird-animation blocker, shipped Galecrest (first bird species)
`400f749`, `4d078e2` · Investigated the "R0.6's four remaining species need
`animate_bird.py`" blocker properly before writing anything, by reading
`animate_quadruped.py` and `rig_bird.py` (1546 lines) in full. Discovery:
`rig_bird.py` is not a bare rigging script the way `rig_quadruped.py`/
`rig_glider.py`/`rig_sitter.py` are — it authors all six standard clips
itself (`author_all()`), already proved end-to-end on three winged test
meshes per its own docstring, and its bone names deliberately overlap
`animate_quadruped.py`'s glider layout "so that script still produces
something sane if it is ever pointed at a bird." The real bug was in
`finish.py`'s `rig` subcommand: it called `animate_quadruped.py`
unconditionally after rigging, regardless of `--kind`. For a bird this
would have silently re-detected the already-animated rig as a glider and
overwritten `rig_bird.py`'s bird-specific animation with generic glider
animation, including `animate_quadruped.py`'s documented faint-spin bug
(root-bone yaw applied where the rig's local Y is world-up, so the
creature spins on the spot instead of toppling). **No new script was
needed** — `finish.py` now skips the `animate_quadruped.py` call when
`--kind` is `bird`.

Proved by running Galecrest, the first bird species, through the fixed
path for real: `clean → texture (candidate a; needed despite an existing
committed `textured/model.glb` from R0.5 — see below) → rig --kind bird →
grade → install`. `rig_report.json`: 19 bones, 14,004 vertices, 6
unweighted (0.04%, same noise-level pattern as Brooktail's), idle motion
at 108% of walk (clear of `rig_bird.py`'s own 6%-is-frozen self-check).
Two eye-guard rectangles added to `grade.py` (a pair of glossy black
hooked-beak shapes checked and rejected — no iris ring, no pupil).

**Mistake made and caught within the same task, before the branch was
confirmed merged:** shipped Galecrest's `species.json` height as 1.85m,
picked from D13's looser "largest tier, alongside Meadowhart and Tuskroot"
language without re-reading `BACKLOG.md`'s R0.7 section, which fixes
Galecrest specifically at 2.00m in its height table. Caught on a second
pass through `BACKLOG.md` while updating it for this entry, fixed in
`4d078e2`, re-verified in Godot (rendered model matches 2.00m exactly, no
footprint clamp, all six clips intact). Lesson for future firings:
**R0.7's height table is the source of truth for a species' height figure,
read it before writing the number** — D13 only fixes the relative
ordering and rough tier, not the exact figure.

**Also checked and corrected a wrong assumption made mid-task:** briefly
believed Duskhush/Pipwing/Reedwing could skip `texture` entirely and reuse
their existing R0.5-committed `textured/model.glb` files, since Galecrest's
turned out to share that history. Wrong — `DONE.md`'s own Tuskroot entry
(below) already recorded that every one of the ten R0.5 outputs is
structurally unusable (textured before `clean`, so 50,000+ triangles
against a 30,000 budget, thousands of non-manifold edges). Caught before
being written into `BACKLOG.md`; that file states the correct instruction
(`clean` then `texture` fresh, same as every other species).

`species.json`: `aggressive: true` (rare — only Tuskroot has this among
the wild roster so far), reflecting the Air Sheet's own "fierce focused
eyes"/"Aerial Striker" language: a genuine predator, matching D13's
explicit requirement that Galecrest not read like the Air starter
Galewisp. Highest attack (28) and lowest defence (15) of the roster so
far, mirroring Galewisp's own thin-armour/high-attack profile pushed
further. `model_yaw` not visually verified — this container still has no
`libEGL.so.1`, so `turntable.py` cannot render a frame, the same
persistent limitation recorded for every species finished this session;
left at 0.0, the default every quadruped shipped with.

Balance after Galecrest's texture pass: **205** (was 215). Duskhush,
Pipwing, Reedwing each still need their own `clean`/`texture` pass,
~10 credits apiece — see `BLOCKED.md`.

CI was still running when this entry was written; verified separately
once green — see `ralph-status` for the real-time record, and do not
trust this line alone as proof of a merge.

## R0.8 — ASSET_LEDGER rows for Mosshell/Brooktail; missing-record gap closed
`b145f2d` · Extends the previous R0.8 partial entry (below) to all six now-
finished R0.6 wild quadrupeds — every one of Tuskroot, Meadowhart,
Burrowback, Paddlenewt, Mosshell, Brooktail now has an `ASSET_LEDGER.md`
row. Still not R0.8 complete: the four bird species have no model yet
(blocked on `animate_bird.py`), so no row for them.

**Also resolved `MEADOWS_WILD_PRODUCTION_REPORT.md`'s "known gap" note**,
open since it was written: the report said Bramblebun's, Mudsnout's and
Trailpup's candidate-selection records "did not survive into `ralph/`" and
asked whoever finished R0.8 to either find them or say plainly they don't
exist. They were never actually missing — they predate the Ralph loop
entirely, so they were never going to be in `ralph/DONE.md`, and looking
there was looking in the wrong place. The real record is in git history:
commit `d2520f0` ("Bramblebun stops being a duck...") and `9ec9eaa`
("Mudsnout and Trailpup...") both carry full candidate-selection reasoning
in their commit messages, and `ASSET_LEDGER.md`'s existing rows for those
three creatures already condense that same reasoning (they were written
from these commits at the time, just never cross-referenced back to them).
The report now cites both commits directly instead of asking a future
reader to re-find them. Also brought the report's "What's next" section
current — it still described R0.5 and R0.6 as not yet started.

CI green (run 31307762531), fast-forwarded to `main` at `b145f2d` —
verified by fetching `origin/main` directly.

## R0.8 — ASSET_LEDGER rows for the four shipped R0.6 creatures (partial)
`92fc1ae` · Not R0.8 complete — six R0.6 species (Mosshell, Brooktail, and the
four birds) have no model yet, so no row for them either; they land as each
model does, the same rule R0.7 already applies to `species.json` entries.
Rows added for Tuskroot, Meadowhart, Burrowback and Paddlenewt, matching the
existing table's per-creature style (Bramblebun/Mudsnout/Trailpup).

**Why this instead of R0.6/Mosshell**, which is the actual next item in
order: this firing's `send_later` self-resume did not carry
`MESHY_API_KEY` — only a cron-fired session's prompt does, a distinction
this session had to learn twice (see the R0.6 Paddlenewt entry above for the
first time, and `BLOCKED.md`'s current top entry for the fuller writeup).
Mosshell's `clean` step (Blender only, no key needed) was done and is not
committed — cheap to redo. Doing R0.8's ledger work instead of idling kept
the firing's context used on real, unblocked project state rather than
nothing.

CI green (run 31303384277), fast-forwarded to `main` at `92fc1ae` — verified
by fetching `origin/main` directly.

## R0.6 — Brooktail finished (sixth of the ten, last of the six wild quadrupeds)
`20f8412` · Same pipeline as the previous five: clean raw R0.4 winner
candidate `a` (54,836 → 28,000 tris, manifold) → retexture via Meshy →
`rig_quadruped.py` → `grade.py` SPECIES entry → `finish.py grade` →
`finish.py install` → `species.json` entry from the Water Sheet's own
Resourceful Diver/Helper role and build notes.

**This species carries two real defects, both documented rather than fixed —
worth reading before touching it again:**

1. **R0.4's report names Brooktail the one HARD FAIL of the ten wild
   species**, not a clean pick like the other five finished so far — every
   candidate is missing the canon's broad flat scaled paddle tail, giving a
   round tapering tail instead. This was **wrongly summarized as "no
   follow-up flagged" in the previous firing's handoff prompt** (a
   send_later message written without re-checking the report directly);
   the actual report entry was caught and corrected by reading
   `docs/art/MEADOWS_WILD_PRODUCTION_REPORT.md` directly rather than
   trusting the handoff. The report's own instruction is explicit: ship it
   forward with the defect flagged rather than block or re-roll, since "the
   tail needs a real sculpting pass before this creature is considered
   done" — separate future work, not attempted here.

2. **`rig_quadruped.py` left 35 of 14,034 vertices (0.25%) unweighted** —
   the first species in this batch where that actually happened; the
   previous five all landed at exactly 0 despite carrying similar residual
   post-retexture mesh noise (this one: 6,075 non-manifold edges, 81
   microscopic disconnected components — same category every species
   carries after Meshy's retexture re-unwrap, see Tuskroot's entry above).
   Investigated rather than shipped blind: extracted the unweighted
   vertices' world positions and found them scattered across the entire
   bounding box, not concentrated near the tail — so this is likely NOT the
   same root cause as (1), just the same known noise pattern crossing a
   threshold this one time. `inspect_glb.py` and Blender's own
   `ARMATURE_AUTO` weighting have no built-in retry/repair for this;
   fixing it properly would mean a fresh clean/remesh pass (cost: another
   Meshy texture charge) or waiting for the eventual tail sculpt to
   naturally redo the mesh. Documented in `species.json`'s `_comment_art`
   rather than guessed at.

**Six eye-guard rectangles**, same duplicated-across-UV-islands pattern
every species has shown, found by the same full quadrant-by-quadrant scan.
One dark almond shape near the snout was checked and rejected — no teal
iris ring, reads as a nostril shadow.

**Finishes the quadruped half of R0.6.** All that remains is the four bird
species (Galecrest, Duskhush, Pipwing, Reedwing), and they are blocked:
`finish.py rig`'s animate step is hardcoded to `animate_quadruped.py`
regardless of `--kind`, and no `animate_bird.py` exists. Whoever picks up
R0.6 next needs to write one (or generalise `animate_quadruped.py`) before
any bird can move past the `rig` step — this is now the actual next blocker
for R0.6, not a credits or key problem.

**Not in `EncounterDirector.WILD_SPAWNS`**, so `smoke_art`'s shared run
doesn't spawn it directly (though `_every_species_has_art()` confirms the
model path resolves, and the run stayed green — the 35 unweighted vertices
do not block import or the test suite, only animation quality). Height-fit
verified with the same small standalone script as the previous five:
**wanted 1.450m, rendered 1.450m, exact match.** Not committed.

CI green (run 31306142495), fast-forwarded to `main` at `20f8412` —
verified by fetching `origin/main` directly.

Meshy balance after this species' texture pass: **215** (was 225).

## R0.6 — Mosshell finished (fifth of the ten)
`e15a204` · Same pipeline as the previous four: clean raw R0.4 winner
candidate `b` (54,396 → 28,000 tris, manifold) → retexture via Meshy →
`rig_quadruped.py` (15 bones, 0 of 13,998 vertices unweighted, 6 clips) →
`grade.py` SPECIES entry → `finish.py grade` → `finish.py install` →
`species.json` entry from the Water Sheet's own Steady Tank/Shelter role and
build notes.

**Four eye-guard rectangles**, same duplicated-across-UV-islands pattern the
previous four species already showed, found by the same systematic
quadrant-by-quadrant scan of the full 2048² atlas. Several candidates
checked and rejected this time: a pair of uniform amber blobs matching the
ordinary scale/wart spots scattered across the rest of the shell texture (no
pupil at all), a tan almond/slit shape that reads plausibly as a closed
eyelid rendered into the stone-shell pattern but wasn't confident enough to
guard, and a dark crevice with an amber edge but no round iris.

**R0.4's report flagged a topology check** — a possible thin protrusion near
the hindquarters that might read as an errant tail/spike — that this pass
could neither confirm nor rule out: this container has no `libEGL.so.1`, so
`turntable.py` cannot render a single frame to actually look at (same gap
hit on both Burrowback's and Paddlenewt's containers, apparently a property
of the container rather than a one-off). `inspect_glb.py`'s structural
report on the graded model showed only the ordinary post-retexture
non-manifold-edge/duplicate-vertex noise that rigging already tolerated
fine (0 unweighted vertices) — nothing that specifically flagged a
hindquarters anomaly, but that report can't see silhouette either.
Documented honestly in `species.json`'s `_comment_art` for whoever next has
a rendered frame to check against.

**This task spanned two firings**, same shape as Paddlenewt's: the first
firing (a `send_later` self-resume) had no `MESHY_API_KEY` — confirmed this
is specific to self-scheduled resumes, not cron firings, which is now a
settled fact rather than a surprise each time it happens. That firing did
Mosshell's Blender-only `clean` step, recorded the block in `BLOCKED.md`,
and pivoted to real unblocked work instead of idling: `docs/ASSET_LEDGER.md`
had no per-creature row for any of the four R0.6 species shipped so far,
despite R0.8 asking for exactly that — added rows for Tuskroot, Meadowhart,
Burrowback and Paddlenewt (`92fc1ae`, `17b5caa`, both verified shipped to
`main`). The next firing was cron-fired, carried the key correctly, and the
same `clean.glb` survived in the same container so nothing was redone.

**Not in `EncounterDirector.WILD_SPAWNS`**, so `smoke_art`'s shared run
doesn't spawn it directly (though `_every_species_has_art()` confirms the
model path resolves, and the run stayed green). Height-fit verified with the
same small standalone script as the previous four: **wanted 1.620m,
rendered 1.620m, exact match.** Not committed.

CI green (run 31304748414), fast-forwarded to `main` at `e15a204` — verified
by fetching `origin/main` directly.

Meshy balance after this species' texture pass: **225** (was 235).

## R0.6 — Paddlenewt finished (fourth of the ten)
`0f51b2a` · Same pipeline as the first three: clean raw R0.4 winner candidate
`a` (56,476 → 28,000 tris, manifold) → retexture via Meshy → `rig_quadruped.py`
(15 bones, 0 of 13,998 vertices unweighted, 6 clips) → `grade.py` SPECIES
entry → `finish.py grade` → `finish.py install` → `species.json` entry from
scratch.

**This task spanned two firings because `MESHY_API_KEY` was missing from the
first one's prompt.** That firing completed the Blender-only `clean` step
(no key needed), found `meshy.py check` reporting the key simply unset — not
rejected, not rotated, just absent — recorded it in `BLOCKED.md` as a genuine
blocker distinct from the credit balance, and pivoted to unblocked work
instead of guessing a key (that pivot is its own separate, uncommitted
tangent — see below). The next firing's prompt carried the key correctly;
the block was reverted since it no longer applied, and the same `clean.glb`
survived in the same container so nothing was redone.

**Five eye-guard rectangles, not one or two.** The 2048² base_color atlas
showed the same duplicated-across-UV-islands pattern Galewisp (six
rectangles) and Tuskroot (three) already showed: every guarded region
carries an identical amber/gold iris ring around a dark pupil, four of five
also with a white catchlight — a texel-for-texel-consistent signature no
ordinary skin blemish produces. Found by a systematic scan (five overlapping
crops, then all four quadrants of the full atlas checked for anything
missed) rather than stopping at the first eye found. Two other dark patches
were checked and rejected: one had no iris ring (a shadowed crease), the
other an amber smear with no black pupil.

`species.json` entry: height 1.50 (R0.7's list, `D13`), stats from the
**Water Sheet** (`docs/art/reference/wild/03_Meadows_Wild_Water_Sheet.png`)
rather than Ground Sheet B — Paddlenewt is the first Water-roster creature
finished. Its subtitle is "Quick Swimmer & Skirmisher" and build notes read
"agile amphibious body... webbed toes for quick bursts... soft fins", not a
sheet with the Ground trio's ROLE/STRENGTHS table format, so the stat
reasoning is transcribed from the subtitle and build notes instead: lowest
defence on the roster (12, soft-bodied and unarmoured), attack in the
upper-middle band (20, a skirmisher hits fast), HP on the low side for a
small creature (90). Non-aggressive — the sheet's own Water-roster design
notes call the whole group "friendly... calm spirits" and Paddlenewt's
listed actions are WATER DASH and PLAYFUL POUNCE, not a hunt.

**R0.4's report flags a cosmetic tail defect on this winner** (short/abrupt
paddle-fin rather than the canon's long taper) — not a hard fail, so per the
pipeline's iterate-on-what-exists philosophy it was documented in both
`grade.py`'s comment and the `species.json` `_comment_art` field rather than
sculpt-fixed, the same treatment Burrowback's claw-scale note and Tuskroot's
plate-edge note got.

**Not in `EncounterDirector.WILD_SPAWNS`**, so `smoke_art`'s shared run
doesn't spawn it directly (though `_every_species_has_art()` confirms the
model path resolves, and the run stayed green). Height-fit verified with the
same small standalone script as the previous three: **wanted 1.500m,
rendered 1.500m, exact match.** Not committed.

CI green (run 31301653288), fast-forwarded to `main` at `0f51b2a` — verified
by fetching `origin/main` directly.

Meshy balance after this species' texture pass: **235** (was 245 at the start
of the second firing — 10 lower than the 255 recorded at the end of
Burrowback's firing, for reasons not accounted for here; balance is read
directly from `meshy.py check` each time rather than assumed, so this is not
a discrepancy in the record, just an unexplained gap between two firings).

## R0.6 — Burrowback finished (third of the ten)
`ccb295a` · Same pipeline as Tuskroot/Meadowhart: clean raw R0.4 winner
candidate `c` (52,818 → 28,000 tris, manifold) → retexture via Meshy →
`rig_quadruped.py` (15 bones, 0 of 14,004 vertices unweighted, 6 clips,
`hit` 12 frames / `faint` 36 frames) → `grade.py` SPECIES entry → `finish.py
grade` → `finish.py install` → `species.json` entry from scratch.

**Only one eye could be guarded with confidence.** The badger's dense
stone/moss camouflage pattern makes a second symmetric eye hard to
distinguish from ordinary texture noise in the 2048² base_color atlas —
rather than guess a rectangle and risk it landing on fur (grading destroys
whatever it is not told to protect), only the one confirmed amber/yellow
iris with a white catchlight is guarded. Documented in `grade.py` itself;
worth revisiting in a later pass if grading is seen eating a second eye.
Grade report: roughness rescaled 0.494–0.706 → 0.60–0.86, emissive off,
specular 0.20.

`species.json` entry: height 1.70 (R0.7's list, `D13`), stats from Ground
Sheet B's own printed ROLE (Defender/Excavator), SIZE CLASS (Medium) and
STRENGTHS (Defense, Digging, Control) lines — highest defence on the roster
so far (23, ahead of Tuskroot's attack lead), moderate HP (110) rather than
tanky-huge for a Medium size class, non-aggressive since a defender protects
territory rather than hunts. All flagged tunable; nobody has fought one yet.

**Burrowback is not in `EncounterDirector.WILD_SPAWNS`** (still only
`bramblebun`, `tuskroot`), so `smoke_art`'s shared run does not spawn it
directly — though its `_every_species_has_art()` pass does confirm the model
path resolves, and the run stayed green (`bramblebun`, `tuskroot`,
`terrapup`, trainer, vegetation all OK). Height-fit verified with the same
small standalone script as Meadowhart (`scenes/pals/pal.tscn` + `wild_pal.gd`
attached + `setup(id)`, then `smoke_art.gd`'s own `_rendered_height()` copied
verbatim): **wanted 1.700m, rendered 1.700m, exact match.** Not committed —
cheap enough (~15 lines) to rewrite per species.

CI green (run 31299327633), fast-forwarded to `main` at `ccb295a` — verified
by fetching `origin/main` directly, not by trusting the CI badge.

Meshy balance after this species' texture pass: **255** (was 265).

## R0.6 — Meadowhart finished (second of the ten)
`f1495d1` · Same pipeline as Tuskroot: `finish.py clean → texture → rig →
grade → install`, candidate a. `rig_quadruped.py`: 15 bones, 0 of 13,994
vertices unweighted. 6 clips.

**Unlike Tuskroot, Meadowhart had no `species.json` entry at all** — Tuskroot
came with a Plumberry placeholder to repoint, Meadowhart did not exist in the
table yet. Added one from scratch: height 1.95 (R0.7's list, `D13`), stats
from Ground Sheet B's own printed ROLE (Rideable/Pathfinder), SIZE CLASS
(Large) and STRENGTHS (Speed, Stamina, Navigation) lines — moderate HP for
its size class, attack/defence both below the roster's combat specialists
since nothing on the sheet says this creature fights. All flagged tunable.

**Meadowhart is not in `EncounterDirector.WILD_SPAWNS`**, so the shared
`smoke_art` run doesn't spawn it and its height-fit was never actually
checked by that pass. Verified instead with a small standalone script
(`scenes/pals/pal.tscn` + `wild_pal.gd` attached + `setup(id)`, then
`smoke_art.gd`'s own `_rendered_height()` copied verbatim) — **wanted 1.95m,
rendered 1.95m, exact match, 0.0000 diff.** Not committed; cheap enough
(~15 lines) to rewrite per species rather than add permanent test
infrastructure for a gap that R0.9's real spawn work may close anyway. Also
ran the full unit suite since a new species.json entry touches
`test_catch_math`/`test_evolution_links` territory: 277 tests, 0 failed.

Grade.py: two eyes, structural fixes only, no hand-tuned palette (same
first-pass philosophy as Tuskroot).

## R0.6 — Tuskroot finished (first of the ten)
`6c6e479` · `tools/art_pipeline/finish.py clean → texture → rig → grade →
install`, then `species.json`'s `tuskroot.placeholder.model` pointed at the
real GLB. `tests/smoke_art.gd`: **model 2.00m, collider 2.00m, exact match,
footprint clamp not tripped.**

**Correction to R0.5, found while starting this task: every one of the ten
R0.5 outputs was textured in the wrong order and none of them can be used.**
`cleanup_mesh.py`'s voxel remesh is what makes a generated mesh manifold
enough for bone-heat rigging, and it destroys UVs — its own docstring says so
and it hard-refuses to run on a model that already carries image textures.
`finish.py`'s documented order is clean → texture → rig for exactly this
reason. R0.5 textured the raw candidates directly, skipping `clean`. Measured
on Tuskroot's R0.5 output: 54,077 triangles (the budget is 30,000), 9,969
non-manifold edges, 5,170 duplicate vertices — un-rigging-safe, and
un-cleanable without losing the texture. The fix, done here for Tuskroot and
needed for the other nine: clean the raw candidate first (28,000 tris, 0
non-manifold edges, 0 duplicates), *then* retexture the clean mesh — a second
Meshy charge, ~10 credits, same as the first. Balance after both of
Tuskroot's texture passes: **265** (was 275, R0.5's own number, before this
firing's correction pass; see this entry's own spend below for the arithmetic
that actually matters going forward).

Also found and fixed: `grade.py` had zero `SPECIES` entries for any of the
ten wild creatures (only the three starters), and `finish.py` never called
`grade.py` at all — `install` copied the animated GLB straight from `rig`,
skipping grading entirely. Added a `grade` subcommand to `finish.py`
(`clean → texture → rig → grade → install`, matching the docstring's promised
"six commands" for the first time) and a `tuskroot` entry to `grade.py`'s
`SPECIES` table: three eye-guard rectangles (located by visual inspection of
the 2048² base_color atlas — this species has no head-close-up reference to
threshold against, unlike Terrapup), roughness rescaled to `ROUGHNESS_BAND`,
emissive off, specular 0.20. **Deliberately no hand-tuned palette shifts** —
unlike Terrapup/Ripplet/Galewisp's entries, no blind gate has reviewed
Tuskroot's colour yet, so only the structural fixes every creature needs are
applied. Grade report: eye guard protected 38,373 texels (0.0/255 delta
inside, confirmed), roughness 0.31–0.73 → 0.60–0.86, emissive map measured 0%
emission and zeroed.

Rigging: `rig_quadruped.py` on the correctly-cleaned mesh gave **15 bones, 0
of 14,000 vertices unweighted** — the residual non-manifold edges/duplicate
verts that Meshy's own retexture re-unwrap reintroduces (6,750 and 3,538,
down from the original 9,969/5,170) did not break bone-heat in practice, so
that specific worry did not need a further workaround. 6 clips from
`animate_quadruped.py`: idle, walk, run, attack, hit, faint.

**Found along the way, not fixed here:** `finish.py rig`'s animate step is
hardcoded to `animate_quadruped.py` regardless of `--kind`, and no
`animate_bird.py` exists — recorded in `BACKLOG.md` as a blocker for the four
bird species (Galecrest, Duskhush, Pipwing, Reedwing), not a blocker for the
six quadrupeds still ahead of them in backlog order.

Blender 4.2.9 and Godot 4.7-stable were not cached in this container and had
to be fetched (`tools/art_pipeline/setup.sh`) — routine, not a finding, but
worth knowing if a future firing's first minutes look unexpectedly slow.

## R0.5 — Retextured the ten R0.4 winners
`7ac1f20` · `tools/art_pipeline/meshy.py texture`, `image_style_url` aimed at
each species' own reference crop under
`assets/pals/tetherbound/<species>/reference/`. All ten went through in one
pass, no stopping partway: **375 → 275 credits, ~10 each** — a third of the
~30/species estimate, so the ~300 budgeted for the whole roster covered it
with 100 to spare.

Force-added like R0.1's candidates — `model.glb`, `provenance.json`,
`thumbnail.png` per species under `assets_raw/<species>/textured/`, `.fbx`/
`.obj` left out as duplicate geometry. Balance check: **275 remaining**, no
`BLOCKED.md` entry needed.

Next up is R0.6 (cleanup/remesh → rig → clips → grade → install), which is
also where R0.4's flagged defects need addressing: brooktail's missing paddle
tail (a genuine hard fail carried forward, needs real sculpting), burrowback's
under-scale claws, tuskroot's plate edges, galecrest's blunt talons — none of
these are texture problems, so retexturing didn't and couldn't fix them.

## R0.4 — Blind critique, picked a winner per species
`46ea130` · Ten fresh subagent critics, each shown only one species'
`compare.png` and its canon text (roster one-liner + the capitalised
signature-feature brief from `meshy.py`'s `SPECIES_PROMPTS`), scored
silhouette, proportion and the signature feature on the untextured white
candidates. All ten scorecards filled (`shots/candidates/<species>-compare.md`)
and summarised in the new `docs/art/MEADOWS_WILD_PRODUCTION_REPORT.md`.

Winners: Brooktail a, Burrowback c, Duskhush a, Galecrest a, Meadowhart a,
Mosshell b, Paddlenewt a, Pipwing b, Reedwing a, Tuskroot a.

**Nine clean picks, one flagged defect carried forward:** Brooktail's winner
still has a HARD FAIL — every candidate for that species is missing the
canon's broad flat paddle tail (both give a round tapering tail instead).
Recorded honestly rather than hidden behind score totals; it ships into
R0.5/R0.6 with the defect flagged for a sculpting pass, since retexturing and
rigging don't touch the tail's shape. Several other species have shared,
non-blocking defects noted for the R0.6 cleanup/remesh step (burrowback's
claws, tuskroot's plate edges, galecrest's talons) — see the production
report's table.

Also wrote `docs/art/MEADOWS_WILD_PRODUCTION_REPORT.md` for the first time
(R0.8 still owes it a provenance-row pass and the missing
Bramblebun/Mudsnout/Trailpup production record, both noted as known gaps in
the file itself).

## R0.3.5 — Fixed the `smoke_catching` flake
`5c919ba` · Three bugs in `tests/smoke_catching.gd` itself, no production combat
code touched:

1. `throw_aim.gd`'s silent 0.9s post-throw cooldown made `try_begin_aim()` fail
   with no signal; the test pressed Throw once and moved on, burning most of
   its 25 attempts on presses that never opened an aim. Now retries
   (`_open_aim()`) until the aim actually opens or a budget past the cooldown
   is exhausted.
2. The test computed pitch from the trainer's hand; production's
   `_aim_direction()` deliberately aims from the camera eye, ~1.5m away via
   `aim.shoulder_offset`. Fixed to read the camera's actual `global_position`.
3. Added lead compensation via the target's `CharacterBody3D.velocity`,
   projected over the aim settle + `throw.release_windup`, since the target
   keeps moving during the aim window.

Also dropped drop compensation entirely — `_aim_direction()` snaps the throw
straight to the target's centre whenever the ray is within a body-width of it,
discarding any elevation added on top, so arcing the aim only risked pushing
the ray outside that snap window. Aiming straight at the (leaded) centre from
the eye keeps it inside instead.

**Verified 11/11 consecutive headless green** (one standalone confirmation run,
then 10 more back to back — required bar was 10). CI on `ralph/R0.3.5` also
went green (run 31290404377).

The earlier "catch versus kill race" diagnosis recorded in a previous backlog
entry never reproduced and was retracted before this fix; it is not part of
what changed here.

## R0.3 — The ten comparison sheets
`5e0f1cc` · concept row over candidate rows, same four angles at one scale, plus
a blank scorecard with a HARD FAIL column per species. Meadowhart's sheet
confirms the `DROP_FOR_SPECIES` fix worked: all three candidates carry the
saddle, stirrup and leaf collar.

## R0.2 — `rig_bird.py` merged
`861c38a` · Proportion-driven bird armature emitting the roster's six standard
clips. Serves Reedwing, Pipwing, Duskhush and Galecrest. Written but **not yet
exercised on a real candidate** — R0.6 is its first real use, so treat its first
run as verification.

## R0.1 — The candidate models and renders are tracked
`1983352` · 26 GLBs and 104 renders force-added out of gitignored scratch
directories. They are 520 Meshy credits that cannot be regenerated on the 375
remaining. `assets_raw/.gdignore` added so Godot does not import them into the
Windows build.

## Pre-Ralph — the session that set this up

- **D17: an evolution is always larger**, with `tests/test_evolution_links.gd`
  enforcing it. Owner instruction.
- **Grading fixed.** One shared `grade.py` replaces three per-species scripts.
  Ripplet's clipped white 33.4% → 0.00%, Galewisp 28.5% → 0.00%, Ripplet's
  emissive (lighting 38% of itself) zeroed, Terrapup verified not to regress at
  0.36/255 outside the eye guard.
- **The sequence director written** — the file three places in the repo already
  claimed existed. Beat order driven from `opening.json`, not an enum.
- **`name_prompt.gd` did not parse** under Godot 4.7, so the naming panel was
  instantiating scriptless and beat 5 could never have worked. Found
  independently by two agents. Fixed.
- **The phantom party is gone.** `party_seam.gd` looked up `/root/GameState`
  against an autoload registered as `Game`, with a mismatched API, so it kept a
  second five-slot party beside the real one. A tautological assertion —
  `assert_true(answer or not answer)` — is why nothing ever said so.
- **Docs brought onto the wild-roster canon.** Ridgewolf and Terracrown retired,
  Mudsnout added, Tuskroot moved to the one evolution the biome has.
- **The negative prompt list stopped banning three creatures' own signatures** —
  a deer's long legs, a deer's saddle, an otter's paddle tail.
- **All ten species generated**: 895 → 375 credits, exactly the 520 planned, no
  re-rolls.

Suite went 247 → 277 tests over the session.
