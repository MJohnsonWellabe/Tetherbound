# Backlog

Ordered. Work top-down. **This file is the state of the project.**

Legend — `▶` owner play checkpoint. **Gates no longer stop the loop** (owner
directive 2026-08-09, D21): the loop lists them in `BLOCKED.md`'s play-gate
section for the owner and keeps building past them. `🔒` needs Meshy credits.
`model:` the cheapest tier that can do the job. `tests:` exactly what to run.

**`model: fable` (owner directive, 2026-08-12) is not "the cheapest tier that
can do the job" — it is a hard floor.** These items are ceiling-setting
narrative or aesthetic authorship (world-building, story beats, dialogue, or
"does this actually look right" visual-direction judgment calls) where a
weaker first pass becomes the ceiling a later pass can't rescue — `R9.4`'s own
history is the proof: an uncapped multi-round critique loop against an
already-built scene still hit a wall neither critic could tune past. **Any
firing that reaches a `model: fable` item must not do the creative work in its
own session, regardless of which lane it is** — see `ralph/PROMPT.md`'s
"Fable-tagged items" section for the dispatch rule.

**Standing task, every visual milestone:** re-shoot the website's screenshots
after any milestone that changes how the game looks (this rewrite, D18/D19's
overhaul, is the precedent — the site had claimed "sourced stand-ins" months
after the roster was real). `model: haiku` when it is just screenshots.

---

**`R6-village-notification-freed-instance` (the freed-instance SCRIPT ERROR in `building_prefabs.gd`'s teardown handler) fixed — see `DONE.md`.** A boolean-order bug (`is Node` ran before `is_instance_valid`, and Godot's `is` throws rather than returning false on an already-freed reference), not the genuine double-free the symptom suggested.

## Phase 0 — the owner played. This is the response.

**R0.10's play gate fired on 2026-08-09: the owner played the first build,
and the overhaul session that followed absorbed the entire feedback loop.**
What shipped (see `docs/HANDOFF.md` §3 and `docs/decisions/D18`–`D20` for the
full record): the giant-player fix with render-space measurement
(`render_bounds.gd`, `smoke_art`'s new [0.1,10] fit-factor trip), the combat
feel pass (auto-face on windup, lunge at windup start, 0.3s input buffer, new
speeds), orbs and potions as real items granted by Grandpa's `give:` dialogue
effects, the throw trajectory preview and the finally-wired aim profile, the
D19 roster resize, `spawns.json` replacing `WILD_SPAWNS` (D20), the indoor
opening in Grandpa's farmhouse (D18), the village and baked dirt paths, and
the website redesign.

**It also absorbed much of Phase 2's first-day scope**: ~10 authored harvest
nodes for wood/stone/fiber/berries (part of old R2.1), camp placement with
ghost preview and real material costs (old R2.4's core, proving the
`build_cost_for` path D16 demanded), campfire + bedroll (part of old R2.6),
and rest-until-morning advancing the day counter and healing (old R2.8's
core). What those items still owe is listed under Phase 2 below.

### R0.11 ▶ Play gate — the owner plays the NEW first day, end to end
Wake in bed upstairs → downstairs to Grandpa, the belt, orbs and potions →
out the door to the three starters → choose and name → the village square and
the paths → harvest along the tutorial route → a fight and a catch → make
camp before dark → rest to morning, day counter ticks. `GAME_DESIGN.md` §33
criteria 1, 3, 6 and 11 — plus the two things D19 flagged for exactly this
playtest: does the combat camera crowd at the new sizes, and does the arena
still feel roomy.

---

## Phase -1 — urgent PC bugs (owner-reported, 2026-08-10)

The owner played the published Windows build. One bug left, ahead of
everything else in this file — **do this first, then Phase -0.5, then
Phase 1 onward.**

**RB1 (mouse look) — the first fix was WRONG. The real cause is found and fixed;
see `RB1-actual` in `DONE.md`.** The owner reported on 2026-08-11 that mouse look
*still* did not work after RB1 shipped, which is the on-device confirmation that
entry was waiting for and it came back negative.

RB1 blamed a mouse capture dropped before the window had OS focus and
re-asserted capture on `focus_entered`. That was diagnosed by reading code and
never reproduced, and it was the wrong cause. The real one:
`scenes/ui/playground_hud.tscn`'s `Root` is a **full-rect `Control` with no
`mouse_filter` line**, so it took Godot's default of `MOUSE_FILTER_STOP` and
consumed every `InputEventMouseMotion` during GUI handling — which runs *before*
`_unhandled_input`, where `camera_rig.gd` accumulates look. Every other UI scene
in the project already sets `mouse_filter = 2`; this one missed it.

**RB1's fix is kept.** Re-asserting capture on focus gain is correct behaviour
and `SH53` still wants it. It simply was not this bug.

Note also that RB1's entry contains a **disproven guess**: it suggested the
owner could not reach Grandpa because they could not turn toward him, "a symptom
of RB1, not a second bug." That was wrong — `SA0` later root-caused the Grandpa
report to a one-way beat machine. Two separate real bugs, and the guess linking
them cost time.

**RB2 (walk/run animation) fixed — see `DONE.md`.** Real bug, found after
the owner corrected an earlier wrong "already fixed" pass this same firing:
every baked humanoid clip shipped `Animation.loop_mode = LOOP_NONE`, so
`character_model.play()` played walk/sprint once and froze for as long as
the state held — creatures already avoided this (`pal_animator.gd`), humans
never did. Fixed in `character_model.gd`/`trainer_model.gd`, verified by
`tests/smoke_input.gd` reading `loop_mode` directly and by real rendered
screenshots. Real on-device confirmation by the owner is still worth having,
same as RB1, but this one no longer needs it to know the bug was real.

---

**RB3 (smoke_aggression flake) fixed — see `DONE.md`.**

**RB4-diagnostics (startup boot log) shipped — see `DONE.md`.** **RB4
(Ally freeze root cause + fix: switched to the Compatibility renderer)
shipped — see `DONE.md`.** Real on-device confirmation that the freeze is
actually gone on the Ally is still worth having, same as RB1/RB2, but the
diagnosis and fix no longer need it to know the bug was real.

---

## Phase -0.95 — the loop itself (`D25`)

One item, above everything, because it is upstream of everything: a flaky test
does not fail *its own* task, it fails whatever healthy branch happens to be in
flight when it flakes, and `ralph-merge.yml` only ships green.

**`LP1` (the `smoke_traversal`/`smoke_combat` flakes) fixed — see `DONE.md`.**

**`LP2` (the `smoke_opening` beat-3 press-count flake) — a pattern-matched fix
shipped, the underlying race not directly reproduced. See `DONE.md` for the
full elimination trail and what would still confirm it.**

**`LP4` (green branches silently never merging) fixed — see `DONE.md` and
`D26`.** A lane reported `EV4-textures-remainder` green but unmerged. Four
branches were stranded, and the mechanism was not what the report guessed:
`ralph-merge.yml` rebases with the default `GITHUB_TOKEN`, and GitHub raises no
`workflow_run` event when a run initiated by that token completes — so the
rebase path could never merge anything. Every branch whose green run came from a
`push` had shipped; every branch whose green run came from a
`workflow_dispatch` was stuck. Fixed with `ralph-sweep.yml`, a ten-minute
reconciler that does not depend on an event arriving.

**Standing note for every firing:** if your branch is green and has not merged
within ~15 minutes, do NOT assume it is lost or start a second attempt. The
sweep lands it. If it is still there after two sweeps, read the sweep run's log
— a conflict or the rebase cap will name your branch explicitly.

**`LP3` (`release.yml`'s `cancel-in-progress` starving the download build)
fixed — see `DONE.md`.** The concrete case the note above is written for:
`ralph/LP3` had already burned 15 rebase cycles to the exact bug `LP4` fixed
before that fix landed, so it arrived at the new cap already over the limit.
`tools/ci/ship_branch.sh` stopped and named it explicitly, per design, and
this firing landed it by hand the way the script's own message says to.

**`LP5` (`ralph-sweep.yml`'s loop didn't return to a clean ref after a stuck
branch) fixed — see `DONE.md`.** Found and filed here after landing `EV3` by
hand; independently re-found and fixed the same hour by a different firing
sitting on `SA2-flake`, which was itself one of the branches stranded by this
exact bug — its own `DONE.md` entry (`LP5`) has the full root-cause trail and
an isolated scratch-repo reproduction. One correction to this entry's own
"done when": only the CONFLICT path actually needed the fix.
`ship_branch.sh`'s rebase-cap path fails and exits before its own
`git checkout -B "$BRANCH" "$SHA"` ever runs, so HEAD never leaves `__ship` —
that path was already safe and needed no change.

**`LP6` (a script-based mechanism so `STATUS.md` leases can't drift past
`## END LEASES` again) shipped — see `DONE.md`.**

**`LP7` (the `smoke_aggression` flake) root-caused and fixed — see `DONE.md`.**

---

## Phase -0.9 — the two blockers from the published build (owner, 2026-08-11)

**`SA0` (the opening soft-lock) shipped — see `DONE.md`.** The owner could not
interact with Grandpa at all and left the house with no starter. Root cause was
not the interaction system: the beat machine started at `wake`, `wake` had
exactly one exit (pressing the bed), and nothing forced it — so walking off the
bed pinned the beat forever, which keeps Grandpa's interactable disabled by
design. Fixed, plus the second route in (a houseless world had no exit at all),
plus a falsifying test (`tests/smoke_wake_softlock.gd`).

**`SA1` (Ally VRAM) shipped — see `DONE.md`.** ~630 MB reclaimed: 91 textures
moved off Lossless RGBA8 to S3TC, twelve 2048² all-black emissive maps shrunk to
4×4, foliage mipmaps enabled, both shadow atlases off the 4096 desktop default,
MSAA 4×→2×. **On-device confirmation is still open** — CI cannot measure VRAM,
same as `RB4`.

**`SA0-orbs` (starter choice moves into Grandpa's conversation) shipped — see
`DONE.md`.**

**`SA0-orbs-remainder` (lighting depth, UI chrome ownership, creature appeal)
shipped/resolved — see `DONE.md`.** All three sub-questions closed: a rim light
plus a selected-label treatment shipped (round 5 and 6 of the blind-judge pass,
five rounds total), `EV9`'s own scope note now names the narrative panels
explicitly, and the roster-wide creature-appeal question moved to `BLOCKED.md`
for the owner rather than staying stranded in a backlog item nobody could
execute.

**`SA1-lod` (vegetation discarding the importer's LOD chain) shipped — see
`DONE.md`.**

---

## Phase -0.6 — the look (owner's art bible, `D24`)

`docs/ENVIRONMENT_AND_UI_BIBLE.md`, made canon by `docs/decisions/D24`. This is
the answer to *"the visuals is the most important part… and it's not getting
fixed"* — and R9.4's own evidence agrees: both blind critics ranked **"needs art
that is not in the build"** first, and scene tuning had genuinely run out of
road. The repo has 42 of 116 nature models, **no** village kit, **no** props
kit and **no** UI assets beyond two portraits.

**Free Standard tiers only** — the owner declined the Source editions, so their
foliage shaders and optimised collisions are not available and nothing may
assume them. Ledger every pack **before** its commit; the ledger's own rules
require it.

**`EV1-remainder` (the two Quaternius MegaKits) shipped — see `DONE.md`.** The
owner supplied both zips directly on 2026-08-11, clearing the itch.io block
this item was originally opened for. Staged under `assets_raw/vendor/` and
ledgered, same as the Kenney four. This unblocks `EV6`, `EV7` and
`EV2-landmark-ceiling`.

**`EV2` (an approved Meadows nature subset) shipped — see `DONE.md`.** Hero
trees and standard canopy curated to the bible's counts with controlled
material variants; wetland forms and a distinct rock large-tier are honest
remainders, not done. Two new findings opened below: `EV2-trunk-colour` and
`EV2-landmark-ceiling`.

**`EV2-trunk-colour` (pale salmon/pink bark) fixed — see `DONE.md`.**

### EV2-landmark-ceiling — Hero trees don't read as landmark specimens even at the best 3-of-5 subset
`model: sonnet` · `tests: none` · `area: vegetation`
`EV2` curated `grove` to the 3 TwistedTree forms with the widest footprint,
tallest height and most asymmetric silhouette (measured, not guessed). A
blind critic still ranked this the #1 gap against the key art: "nothing in
these five frames comes close to the key art's oaks, whose canopies are
wider than they are tall and whose trunks visibly fork and lean... the
current asset's silhouette ceiling won't get there just by rescaling."
This is a real asset ceiling, not a placement/curation problem `EV2`'s own
lever (which models, what tint) can solve — the fuller Stylized Nature
MegaKit that might carry a genuinely broader-canopy hero form is itch.io-
blocked (`EV1-remainder`), and `CLAUDE.md`/`D24` forbid a Meshy generation
for a routine nature asset regardless. Not a `BLOCKED.md` design question —
there's no decision to make, just an asset gap with a known unblock path.
Done when: the Stylized Nature MegaKit's itch.io block clears and the fuller
pack is searched for a broader-canopy hero form, or the owner accepts the
current ceiling.

**Checked twice, 2026-08-12 — still blocked, unchanged, and worth stating
plainly since two different firings have now independently gotten this
wrong.** `EV1-remainder`'s own note that it "unblocks... `EV2-landmark-
ceiling`" is incorrect: the two zips the owner supplied and `EV1-remainder`
staged are the Quaternius **Village** and **Fantasy Props** MegaKits (176 +
94 `.gltf` files, verified by listing every one: zero tree or foliage
assets, purely architecture and props). **The Stylized Nature MegaKit this
item actually needs is NOT staged anywhere in `assets_raw/vendor/`** — a
second, separate firing's edit to this same paragraph assumed otherwise
("staged, `assets_raw/vendor/`... someone actually searching") without
checking, which would have sent the next firing searching for a pack that
was never downloaded. It remains itch.io-blocked exactly as `EV1` originally
found it.

**`EV3` (a first, narrower slice) shipped — see `DONE.md`.** Fixed the one
concrete, already-diagnosed defect (`path_stones` clumps disconnected from the
real paths) and applied R7.1-remainder-2's own named density lever
(tighter `clump_radius`, same instance count) to `grass`/`drygrass`. Did
**not** reach the item's full bar — "seven layered bands... driven by slope,
elevation, path distance AND landmark distance" is broader than this slice,
and a fresh blind critic still ranked two other things first (both already
owned by concurrent lanes: `EV4-textures-lighting`'s shadow artefact,
`EV4-textures-remainder`'s decal-like path texture). A narrower remainder is
opened below for what a future pass should try next.

**`EV3-remainder` (round 1 of 2, the flowers-along-a-path half) shipped a real
but partial improvement — see `DONE.md`.** `path_bias` (0.35) plus a new
`path_bias_jitter` (4.0, so biased clump centres stop landing exactly
collinear on the centreline) genuinely improved one of three judged frames
(`the-rise-route.png`, called "a real step toward it" by a second blind
critic) with no regression on the other two. Did not reach the done-when —
`square-convergence.png` still shows a visibly row-planted flower patch and
`grandpas-house-route.png` is still under-clustered. Stopped after two rounds
rather than continuing indefinitely (owner checked in mid-session on the
combination of a long infra-blocked wait and slow iteration; conventions.md's
own budget guard applies here too). A narrower remainder is opened below.
**The elevation/landmark-distance placement-bias half was not attempted this
round either** — still open, still needs new mechanisms bible §7C names, and
`EV5` (water) still has to exist before "distance to water" means anything.

**`EV3-remainder-2`'s `square-convergence.png` half (row-planted flowers at
the well) fixed — see `DONE.md`.** Root cause was not clump placement at
all: `terrain_playground.json`'s four routes all share one endpoint at the
well, so every ground-cover layer's path-exclusion isoline forms a straight
four-way wedge there, not a per-layer artefact. Confirmed by two independent
blind critics; the second called it "the exception... doesn't show the hedge
pattern."

**`EV3-remainder-3`'s grass/drygrass mechanism fix shipped — see `DONE.md`.**
Confirmed against real placement data both before AND after the fix (not
just a rendered PNG): grandpas-house-route and the-rise-route's remaining
grass/drygrass clump centres near a path dropped from 2.35-4.26m (three
offending clumps found) to 9.46-11.16m (nearest survivor) after `EV3-
remainder-3`'s own `path_avoid_radius` shipped — the grass/drygrass half of
the mechanism genuinely works and is verified, not asserted. **Did not
close the item**: a third blind critic on the fixed state still named the
same hedge pattern on both frames. Root cause turned out to be different
from what either this entry or `EV3-remainder-2` diagnosed — see
`EV3-remainder-4` below for what a fourth diagnostic pass actually found
once grass/drygrass stopped being the dominant signal.

**`EV3-remainder-4` (grass/drygrass strays fixed structurally; flowers'
path-biased clumps stop straddling the road) shipped, partial — see
`DONE.md`.** Two real, verified mechanism fixes across two rounds. Did not
close the item — a fresh blind critic on the round-2 render still named
`grandpas-house-route.png` for the same pattern, but a whole-map placement
dump of the *real* seed (not a guess) found neither `flowers` (0 clumps,
biased or unbiased, within 15m of any path in that frame's actual region)
nor `bushes` (1 instance within 20m of the house) present there in any
meaningful quantity — ruling out further `path_bias`/`path_avoid_radius`
tuning as the lever for that specific frame. Narrower remainder opened
below.

**`EV3-remainder-5` round 1 (the `path_stones` clump_radius fix) shipped, partial — see `DONE.md`.** Found and fixed a real, verified mechanism the
prior round's diagnosis chain hadn't reached yet: `path_stones`' own
`clump_radius` (8.0, unchanged since before real paths existed) was more
than twice the path's actual visible width, spreading stones out to 7-8m
off centreline in a near-perfectly symmetric 7-left/7-right pattern near
Grandpa's house — exactly the "matched clusters... flanking both sides"
shape two critics had already named. Cut to 3.5m, verified before/after
with real placement data (18→6 in-region instances, worst-case offset
8m→2.8m). **Did not close the item** — a fresh critic on the re-rendered
frame still named the same frame for a flanking pattern, but attributed it
to flowers/grass rather than stones, which a frustum-projection check
(exact camera, not a guessed region) doesn't support: real near-field
flowers there are heavily left-skewed, not symmetric. Narrower remainder
opened below.

**`EV3-remainder-6` tried the item's own named lever (denser ground cover,
an `extra_clumps` placement-authoring mechanism, not a path-proximity
tweak) and got a real result: worse, not better — see `DONE.md`.** The new
off-path clump paired with the pre-existing left-side flower concentration
`EV3-remainder-5` found and produced exactly the mirrored flanking read
this whole line exists to eliminate. Reverted cleanly. Five real,
evidence-first rounds (`EV3-remainder` through `-6`) have each found and
fixed a genuine mechanism, and the mechanism side of this investigation now
reads as exhausted — moved to `BLOCKED.md` for the owner rather than
leaving it in `BACKLOG.md` for a future firing to guess a sixth coordinate
blind.

**EV4's mechanism (paths as a real control-map material, not a colour-map
tint) shipped — see `DONE.md`.** Five blind-judge rounds; the first four
tuned the wrong texture, round 5 wired in `Ground030` (sourced independently
by another lane specifically for this, credited in `DONE.md`) as a dedicated
`path` texture and the material genuinely improved — a fresh critic called it
"real progress... works as a navigational read." Two narrower remainders
opened below from round 5's own honest read of what is still wrong.

**`EV4-textures` (moss-blotch saturation, and the slope-specific edge stepping) shipped — see `DONE.md`.** Three local blind-judge rounds, both original complaints converged: edge-stepping never reproduced past a mild, ambiguous waviness and a third critic called it "largely resolved... no rectangular notches"; moss saturation measurably dropped (0.36 -> 0.09, at/below the texture's own baseline) via a direct, feathered-mask edit to the CC0 source photo rather than fighting it through a tint multiply. **Two new findings from round 3, out of this item's scope, opened below**: the path reads paler than the references even where moss is fully resolved, and an unmotivated hard-edged shadow crosses sunlit path frames.

**The `path_stones`-disconnected-from-the-real-paths finding (found
independently while blind-judging `EV4`'s paths, 2026-08-11) is fixed by
`EV3` — see `DONE.md`.**

**`EV4-textures-remainder` (moss blobs reshaped from circular stamps to
varied streaks) shipped, partial — see `DONE.md`.** Two blind-judge rounds.
Round 1 fixed the hard-edge/circular-outline complaint outright — a fresh
critic confirmed "no perfect geometric circles... edges consistently soft,
not stamped," genuinely closing the original "stamped decal" framing. Round
2 (added a per-blob asymmetric taper) only partially closed the follow-on
complaint it surfaced — limited shape variety, "one repeated template,
resized" — and a second, separate, deliberately out-of-scope class of grey
fibrous "tuft" blobs (texture/luminance-driven, not colour, so not caught by
this fix) still reads as repeating. Stopped after two rounds of real,
measured movement rather than pushing a third: the residual gap matches
what the original item predicted — genuine shape *variety* (not just
irregularity) needs hand-authored moss silhouette variants, which a
procedural per-blob warp on one source photo structurally can't produce.
Accepted as the item's own "low priority... finish question" framing said
to expect. No further remainder opened; `docs/ASSET_LEDGER.md`'s `Ground030`
row has the full before/after account if anyone revisits it.

**`EV4-textures-lighting` (blown-highlight/shadow-contrast on sunlit ground)
shipped — see `DONE.md`.** `SA1`'s shadow-atlas cut, the lead-off hypothesis,
is now ruled out (raising the atlas back to 4096 at runtime changed the
`square-convergence.png` shadow edge not at all). What actually explained the
"unmotivated shadow" complaint turned out to be two different things:
`square-convergence.png`'s dark diagonal is a real occlusion shadow from the
Barn, and `grandpas-house-route.png`'s flanking bands aren't a shadow at all
— ordinary grass reading dark purely by contrast against a path blown to
near-white. Fixed the shared cause (day `exposure` 1.22 → 0.6, `ambient_energy`
1.02 → 1.5). **Did not fully clear the bar — narrower remainder opened below.**

**`EV4-textures-lighting-remainder` (the unmotivated dark near-camera patch
at `square-convergence`/`the-rise-route`) closed 2026-08-12 — identified, not
just ruled out — see `DONE.md`'s `EV4-textures-lighting-remainder-3` entry.**
Ten mechanisms tested and ruled out across this item's full history (shadow
toggle, SSAO, normal-map depth/AO, ambient energy, vertex colour, photo
content, PSSM cascade splits, shadow bias); the actual cause is ordinary
grass/path luma contrast at the deliberately-feathered path edge
(`build_playground_terrain.gd::_path_control()`'s own documented design),
the exact same phenomenon `BLOCKED.md`'s open `grandpas-house-route.png`
"flanking" question already names and has spent five rounds on without a
fix. Folded into that existing `BLOCKED.md` entry rather than opened as a
duplicate. `tools/diag_control_texture.gd`, `tools/diag_shadow_cascade.gd`,
`tools/diag_shadow_bias.gd` and `tools/diag_path_factor_grid.gd` are kept as
reusable diagnostics. History below kept for the record.

`EV4-textures-lighting`'s own self-administered rubric pass (see its
`DONE.md` entry for why this wasn't a true blind sub-agent read — no
`Agent`/`Task`-equivalent tool was available in that checkout) still named
the Barn's shadow in `square-convergence.png`, and found a second,
previously-undiagnosed instance in `the-rise-route.png` — confirmed by the
same instrumentation to be genuine terrain self-shadowing off the Rise's own
nearby crest, not an artifact. Both are physically motivated (toggling
`sun.shadow_enabled` removes them cleanly) and both got less severe once the
highlight stopped blowing out (less contrast to read the shadow against),
but neither went away. Two levers were tried and both went flat —
`shadow_blur` 1→3 plus a further `ambient_energy` bump moved the sampled
shadow edge by single-digit luma, and `light_angular_distance` 0.6→4.0 on
top of that changed nothing visible — consistent with the Compatibility
renderer (`D06`) not implementing the soft-shadow machinery those properties
drive under Forward+; worth re-testing on real hardware before writing the
levers off entirely. Reaching further than that needs either a sun-angle
change (trades against the terrain-form-vs-shadow-length balance `R9.4`
already negotiated) or a scene-level change (the Barn's placement relative
to that viewpoint, or the Rise's crest shape) — neither is a `lighting`-scope
config edit, which is why this is a narrower remainder rather than more work
on the same item. Whoever takes this should also re-run a genuine blind
`visual-judge` pass first (a real sub-agent, not a self-review) in case the
verdict changes with fresh eyes. Done when: a blind critic given
`square-convergence.png` or `the-rise-route.png` either stops naming the
shadow, or explicitly agrees it reads as motivated (traces it to the Barn /
the Rise itself without being told).

**Root-caused 2026-08-12 by `RENDER-PERF-DIAG` (see `DONE.md`) — the earlier
"100+ minutes, no progress" attempt above was not measuring a real render
wall.** `tools/capture_paths.gd`, run with its own documented invocation
(no `--headless`), produced all four real PNGs in **4m34s**. The prior
attempt's mistake was adding `--headless`, which silently swaps in Godot's
no-op "Dummy" rendering driver regardless of `--rendering-driver` and makes
`await RenderingServer.frame_post_draw` hang forever on a signal that
structurally cannot fire — the main loop spins at high frequency the whole
time it's stuck there, which is consistent with the "CPU pinned near 100%,
not hung" symptom this entry originally recorded. `tools/diag_scene_perf.gd`
now exists specifically to re-diagnose this class of problem in minutes
instead of another open-ended wait; its own header has the full mechanism.

**The real blind pass ran 2026-08-12 (this entry's own missing step) — verdict
unchanged.** Re-rendered `square-convergence.png`/`the-rise-route.png` with
the documented invocation, then dispatched a genuine `Agent`-tool sub-agent
(not a self-review) against `docs/reference/` with no hint of what to look
for. It independently named both blobs unprompted — "the two large soft-edged
shadow blobs… Neither has a silhouette that matches any object visible in
frame… nothing in either shot gives the eye a caster to anchor them to, so
they read as unmotivated dark patches" — the exact opposite of this entry's
done-when (stop naming it, or trace it to the Barn/Rise unprompted). So the
earlier self-administered read was not the false positive a fresh look might
have overturned; a genuinely blind critic reaches the same place.

**Not chased further this pass, and not a `lighting`-scope task.** This
entry's own prior analysis already named the only two remaining levers as
outside `lighting`: a sun-angle change (risks the terrain-form-vs-shadow
balance `R9.4` negotiated across many other frames) or a scene-level change
(the Barn's placement — `data/config/village.json`, `area: village` — or the
Rise's crest shape — terrain heightfield, `area: terrain`). Checked both
before writing this off as someone else's problem rather than assuming it:
`EV6` (rebuild the settlement on the Medieval Village MegaKit) is live on
`area: village` right now and is explicitly repositioning/replacing the farm
buildings the current Barn shadow is cast by, so diagnosing or fixing that
caster's exact placement today would very likely be thrown away the moment
`EV6` lands. The Rise's crest half has no such conflict but is squarely
`EV4-hillside-seam-remainder`'s own territory (terrain-area slope/placement
work on the same landform), not a second unrelated terrain task. Given
neither remaining lever fits `area: lighting` and one actively collides with
a live lane, this stops here rather than reaching across areas. Whoever picks
up the Barn half: wait for `EV6` to land first, then re-render and re-judge
against the new settlement geometry before touching anything — the caster
this entry diagnosed may not exist in its current form afterward.

**`EV6` landed 2026-08-12 (see `DONE.md`) — the Barn is gone, the patch is
not.** Re-rendered fresh and re-ran a genuine blind pass exactly as instructed
above: the same defect is still named, independently, in **all four**
viewpoints now (not just the two named in this item's original done-when).
Five mechanisms were tested directly with real before/after renders —
`sun.shadow_enabled`, `env.ssao_enabled`, `normal_depth`/`ao_strength` on
both the `grass` and `path` textures, `ambient_energy` (up to 4x), and
Terrain3D's `show_colormap` debug override (rules out the baked vertex
colour map entirely — with textures off, no patch anywhere) — see
`DONE.md`'s full entry for the numbers. **None of them meaningfully move
it.** This also retroactively corrects this entry's own `square-convergence`
diagnosis: that shadow WAS real and WAS the Barn (confirmed at the time by
toggling `shadow_enabled`), but the Barn is gone now and disabling
`shadow_enabled` today changes nothing — a different, still-unidentified
mechanism produces the same-looking defect on the geometry that replaced it.
No code shipped this round (every experiment reverted, config files
byte-identical to before). Two real levers remained genuinely untested by
direct render rather than by inspection at the time — see
`EV4-textures-lighting-remainder-2` below for both.

**`EV4-textures-lighting-remainder-2` (both remaining levers tested: photo
content ruled out, blend-zone narrowed to a specific mechanism) shipped, no
code — see `DONE.md`.** Photo content is cleanly ruled out (neither source
JPG has a pixel dark enough anywhere). The control map genuinely does show
grass "holes" punched into the path where the patch appears (real signal,
confirmed via `tools/diag_control_texture.gd`'s new `show_control_texture`
debug view), but a direct experiment ruled out the dominant/dither blend
logic as the specific cause. Narrowed to `path_factor`'s own route-geometry
coverage as the next thing to instrument directly. Done when: a blind
critic given any of the four `tools/capture_paths.gd` frames stops naming
an unmotivated dark patch, or explicitly traces it to a visible object.

**`EV4-hillside-seam` (blotchy hillside slope material) rounds 1-4 shipped —
see `DONE.md`.** Rock went from mathematically unreachable (round 2's wider
blend pushed its threshold past this landform's own max slope) to a
proportionate accent, verified by three independent blind-critic rounds.
**Did not fully clear the bar — narrower remainder opened below.**

**`EV4-hillside-seam-remainder` (rock near-black, ring-like placement) fixed;
soil band still not visible — see `DONE.md`.** Two of round 4's three named
defects are genuinely resolved, each confirmed by an independent blind
critic on the re-rendered frames: rock's `ao_strength`/`normal_depth` cut
(0.4/0.6 → 0.15/0.3) stopped it reading as a cast shadow — a fresh critic
called the close-range patch "granite... visible directional streaking/
veining" — and a new coarse noise field (`outcrop_jitter_deg`,
`playground_heightfield.gd`) added to the slope sample before the band
lookup broke the uniform ring into separated blobs at different positions,
confirmed by two independent critics ("not one continuous collar," "blob-
shaped rather than a continuous ring"). **The third defect — no visible
soil band — was NOT fixed after two real attempts** (widening the pure-soil
plateau; then pushing `soil`'s tint/relief further) and the second attempt
was reverted as a regression (see `EV4-hillside-seam-remainder-2` below for
why, and for the root cause both attempts ran into).

**`EV4-hillside-seam-remainder-2` (the two lever-2 fixes: photo saturation, then the tint/colour-map compounding it hid) shipped, partial — see `DONE.md`.** Two more rounds after the two documented above (widened plateau, reverted stronger tint). Round 3 finally executed lever 2 from this item's own list — a feathered pixel-level correction on `Ground003_Color.jpg` itself — and found why both prior tint-only rounds failed: the raw photo's own saturation (mean 0.45) measured ~4.5x every sibling ground texture already in the project (Ground030 0.099, Rock030 0.126), oversaturated across nearly its whole area rather than a narrow green patch, so no tint multiply could ever fully tame it without either undershooting or overshooting. Fixed the photo directly (`tools/art_pipeline/desaturate_soil_texture.py`, same local-luminance-blend technique as `Ground030`'s own moss fix); real, measured, verified movement (0.45 → 0.17). A fresh blind critic on the re-render still found no visible third material, but round 4 found a *second* real bug the first render exposed: `colour.soil` (`#e0cea4`) — a separate multiply layer meant to be "near white, modulates rather than paints" per this file's own top comment — was itself saturated (0.27) and compounding with the texture's own `tint`, landing rendered soil saturation at 0.65–0.76 even after the photo fix, the same multiplicative-saturation bug `R9.4` already diagnosed and fixed for grass elsewhere in this exact file. Fixed both together (`tint` → `#fafafa`, matching rock's own near-white convention now that the photo carries the real colour; `colour.soil` → `#f3ebdb`, now honestly above this file's own `#c0` floor) and reverified by direct pixel sampling of the actual rendered frame, not just the offline texture: transition-zone saturation dropped from 0.65–0.76 to 0.18–0.43, with a real, visible brighter warm band now present above the darker rock in the re-rendered frames. **Did not close the item**: a third blind critic still reported no clearly legible third material — not because the colour is wrong now, but because soil and rock differ mainly in *value* (bright vs. dark) rather than hue, so rock's own low native brightness (`Rock030_Color.jpg` mean value 0.31, further darkened by its `normal_depth`/`ao_strength` under a grazing sun) reads as "a shadow hole" rather than a second material, which eats the contrast budget that would otherwise sell the soil band as distinct. Two real, root-caused, verified bugs fixed this round with no regression (no critic named a new worse defect the way the round-2 tint push once did) — genuine progress, just not enough to clear the bar on its own. Narrower remainder opened below for the value/contrast half specifically, since colour-only levers on `soil` are now close to exhausted.

**`EV4-hillside-seam-remainder-3` (both named levers tried: rock's floor brightness, soil's hue pushed away from rock) shipped, partial — see `DONE.md`.** Three real rounds. Round 1 (rock photo brightness lift + a further AO/relief cut) got the first critic-confirmed positive on rock specifically: a fresh critic described real internal texture/veining where the previous round's critic saw none. Rounds 2-3 chased the soil half and found the round-2 diagnosis above was reasoning from the wrong data — the *offline* photo×tint×colour-map chain, not the actual lit render. Direct pixel sampling of the real rendered frame (sky masked out) found ~87% of all visible ground pixels landing in one narrow hue band (50–60°) regardless of what the offline chain predicted for soil — pushing soil's hue further from rock's (round 2) was landing on top of grass's own real rendered hue, not separating from it. Round 3 pushed the opposite direction instead — true tan/dirt (hue ~30–40°), which an earlier round had tried and reverted as "burnt orange" but on the OLD, oversaturated soil photo; retried on `remainder-2`'s already-fixed photo, it moved measurably (ground hue mass shifted from centred at 50–60° to centred at 30–50°, confirmed by direct pixel histogram) with no rust regression. **Did not close the item**: the blind critic's core verdict did not move across any of the three rounds — no third material, rock still read as a stain/AO artefact rather than stone, in all three. Colour/value levers on this specific soil/rock pair now read as genuinely exhausted rather than merely "close" — both of this item's own named levers were tried, plus the hue-direction reversal a fresh diagnosis motivated, and none produced a critic-visible third material despite real, verified, measured movement on every axis tried. Narrower remainder opened below, aimed at a different kind of lever entirely.

**`EV4-hillside-seam-remainder-4` (real height relief, gated to each rise's flank, tried at two amplitudes) shipped, did not clear the bar — see `DONE.md`.** A genuinely different lever from every colour round above; still didn't move the critic's core verdict even at 2.5m amplitude. Moved to `BLOCKED.md` per this item's own pre-authorized fallback — the hillside's rock/soil read is now an owner-facing question, not an open backlog item.

Also named by this item's rounds, explicitly out of scope (pre-existing,
unrelated to the slope-material bands specifically): the sun/moon disc
reading as a flat blurred sprite; the tower/spire on the hilltop rendering
as a flat unlit silhouette with no surface shading; a white, faceted,
crystalline-looking shape (very likely the known stronghold landmark
silhouette, `landmark.gd`) partially visible at the edge of two frames from
these specific camera angles.

**`Ground037` (mossy forest floor, ambientCG, also pre-sourced and ledgered
alongside `Ground030`) is still unused.** Bible sec8 item 5, Deep Grass/
Forest Floor, painted near the valley basin or under tree canopy once `EV3`
gives the bake real tree-placement data to key off. Whoever picks up that
layer should reach for it directly rather than re-sourcing.

### EV5 — Water
`model: fable` · `tests: smoke_traversal` · `area: terrain`
Bible §15. A pond and stream: readable stylised surface, shallow-edge colour
shift, reeds at the banks, no expensive simulation. Answers the open question in
`R7.1-remainder-2` and gives Band 3's river somewhere to start.

**`EV6` (settlement rebuilt on the Medieval Village MegaKit) shipped — see
`DONE.md`.** Workshop, two cottages, composed well, kit fences, two authored
square oaks; the windmill removed rather than left as a second family. The
mill, the ranger station, the bridges and Grandpa's-house-as-modules are
carried forward below.

### EV6-remainder — The building types the kit rebuild deliberately left
`model: fable` · `tests: smoke_opening, smoke_traversal` · `area: village`
Bible §12's list is six types; `EV6` shipped the square (workshop, village
house ×2, the well as the square's marker) and stopped.

**`EV6-remainder-well-rocktrim` fixed a settlement-wide invisible-buildings
regression, found while chasing the RockTrim leftover below — see `DONE.md`.**
`fdbfc1d6`'s template-leak fix (~06:36Z this session) accidentally made every
placed structure (`village.gd`'s all ten, plus `grandpa_house.gd`'s
`farmhouse_shell` exterior and `road_gate.gd`'s gate leaf) invisible while
keeping full collision — a player would walk into solid, unseen walls.
Fixed at the source in `building_prefabs.gd::instantiate()`. **If any visual
judgement of the settlement happened between `fdbfc1d6` and this fix landing,
treat it as invalid** — it was judging an empty field with real walls in it.

Still open:
- **Mill / crossing, and the bridges** — both are water/bridge architecture
  and there is no water (`EV5`, unshipped). The windmill's removal also cost
  the settlement its tall landmark; the mill at a real crossing is the
  in-family replacement, built when `EV5` gives it a stream to stand on.
  `data/dialogue/village.json`'s Oskar is a Bridgehand with no bridge for the
  same reason.
- **Ranger station** — compact functional building; no site for it exists in
  the slice's geography yet, and inventing one mid-rebuild would have been a
  site-plan decision made for silhouette's sake.
- ~~**Grandpa's house as modules.**~~ **Shipped by the EV6 follow-up pass**
  (see `DONE.md` §EV6): the exterior is now the `farmhouse_shell` prefab —
  brick ground course, timber-grid upper course, kit windows, `6x10`
  round-tile roof — through the same composer as every other building, with
  every marker contract kept (the kit's 4m/6m roof spans fixed the footprint
  at 10×6, so the interior went from 9×7 to ~9.4×5.4; `smoke_opening` walks
  the new lanes green).
- **Judge-harness note for whoever runs the next visual pass on this area:**
  a genuinely blind critique of the settlement (external, no Agent tool in
  either EV6 firing's environment) confirmed the pre-follow-up farmhouse as
  a family split and has NOT yet re-judged the rebuilt one — the follow-up
  pass's own strict-rubric read is recorded in `DONE.md`, but treat the next
  real blind pass's findings as round 1.
- ~~**The furniture pack renders near-black indoors.**~~ **Fixed** — see
  `DONE.md` §EV6-remainder-furniture. `assets/props/quaternius_furniture/*.mtl`
  carried Blender's LINEAR-space `Kd` values, and Godot's OBJ importer takes
  `Kd` as literal sRGB albedo with no gamma handling of its own; every piece
  read as an unlit silhouette. Gamma-corrected all 48 `Kd` triplets across
  the pack's 13 `.mtl` files. Confirmed by two independent genuinely blind
  critiques (before/after) that the black-silhouette defect is gone; a
  separate, real local caching trap is also documented there — Godot's
  `.import` dependency tracker does not watch an OBJ's referenced `.mtl`
  sidecar, so a local dev checkout needs its cached `.godot/imported/`
  entries force-regenerated to see a `.mtl`-only edit (CI is unaffected,
  since it always imports from a clean checkout with no stale cache to
  reuse).
- Small named leftovers, cheap once someone is in the area: ~~the well's
  RockTrim dressing still reads cool in shadow after a warm multiply~~
  **real fix shipped (a wrong `metallic` value), accepted as the honest
  ceiling — see `EV6-remainder-well-rocktrim-shadow` in `DONE.md`**;
  `cottage_b`'s downhill
  border skirt still shows a shelf-shadow on the flat's smoothstep skirt (a
  small terrain flat at [21,-14] would end it); every building's border
  skirt meets the grass as a hard grey edge rather than a soil transition
  (the blind pass named it settlement-wide; needs a ground-blend treatment,
  not a per-building fix); a plain `ShortCloset` piece (and possibly other
  simple box-shaped furniture) reads as a featureless flat slab even with
  the colour now correct — a geometry/detail limit of the source mesh, not
  a colour bug, named by the furniture fix's own confirming blind pass. The
  blind pass also flagged village NPCs reading flat-black in exterior
  frames — partly the same class (dark palette tints under `NP2`'s
  emission-tint pipeline); `lane: npc`, not
  village work.

**`EV6-remainder-well-rocktrim-shadow` (root cause found: `MI_RockTrim` imported with `metallic=1.0`, fixed) shipped, real improvement, not fully closed — see `DONE.md`.** The `ao_light_affect` lever this item originally named turned out to be moot (`ao_enabled=false` on the material — checked with a new probe tool before implementing it blind) — the real defect was a wrong PBR value, not a missing hook. A genuine blind critic on the fixed render still names a colour-temperature mismatch, but a visibly softer and more specific one than before, most likely the Compatibility renderer's own lack of ambient bounce/GI (`D06`) rather than a further material property — `roughness` is already maxed and `ao_light_affect` is confirmed inert. Accepted as the honest ceiling; no further remainder opened.

**`EV7` (a first slice: work area and farmhouse yard) shipped — see `DONE.md`.**
Two of the bible's five named clusters. `bridge repair site`, `quarry station`
and `trainer camp` need geography that doesn't exist yet (no bridge, no built
quarry — `SA4`/`EV5` territory) and are carried forward below.

### EV7-remainder — The three prop clusters that need geography built first
`model: sonnet` · `tests: none` · `area: village`
Bible §2 P3, absorbing the rest of `R9.4-remainder-5`. `bridge repair site`
needs a bridge (none exists — `SA4`'s river-gorge spoke or `EV5`'s water
feature); `quarry station` needs a built quarry (`village_npcs.json`'s own
comment: the Quarry Foreman stands in the square today because "No built
quarry to stand him at yet"); `trainer camp` could go along an existing route
(the practice meadow, `R7.1`'s waypoints) without waiting on new geography, so
it is the one of the three that is realistically startable now. Done when: a
blind critic given close and in-context frames of each site names it as
implying a purpose, the same bar `EV7`'s first two clusters cleared.

**`EV8` (lighting and atmosphere) shipped — see `DONE.md`.** Two rounds of the
blind pass. Warm sun and cool fill were already correct and are unchanged;
the pale-horizon and sky-inconsistency defects (`R9.4-remainder-2`) are fixed.
A parallel lane independently fixed a narrower instance of the same
sky-inconsistency class in `tools/capture_site_shots.gd` (a website capture
tool, not the exploration survey) — see `DONE.md`'s follow-on entry.

### EV9 — Rebuild the HUD
`model: opus` · `tests: smoke_menu` · `area: ui`
Bible §16–§18. Native `Control` nodes over Kenney UI + Input Prompts. Dark
translucent panels, teal accent, warm gold for progression, no fantasy scroll
frames. **Tested at physical 7-inch scale, not on a desktop monitor** — §17 is
explicit.

**First slice shipped 2026-08-11 (`eea16a9`): the exploration HUD only.**
`scripts/ui/playground_hud.gd`/`scenes/ui/playground_hud.tscn` rebuilt —
styled health/stamina bars (dark translucent panel, teal border, rounded
corners, labeled "HP"/"STA") that fade to a low-emphasis state when full and
idle, a party/orb count panel, and the contextual interact prompt read live
from `InteractionArbiter`. The old always-on debug telemetry dump still
exists but is now F3-toggled instead of covering a third of the screen.
Blind visual-judge (3 rounds, `tools/capture_exploration_hud.gd`) converged
on "coherent, intentional HUD"; remaining gaps were named explicitly as
needing new assets rather than more scene tuning.

**Second slice shipped 2026-08-11: real icon glyphs on five of the prompts
the paragraph below flags, before `HD1` was found — see `DONE.md`.** Built
independently and in parallel with the owner's `HD1` report landing on
`main`; the overlap is real and is reconciled in `HD1`'s own entry below
rather than here. `dialogue_panel.gd`, `name_prompt.gd`, `starter_picker.gd`,
`prompt_arbiter.gd` (the actual exploration-HUD prompt `format()`) and
`encounter_director.gd`'s matching combat-engage prompt all draw a real
Kenney Input Prompts icon now, through new `scripts/ui/input_glyph.gd`,
instead of literal bracket text. **Does not close `HD1`**: device selection
is "a joypad is connected," not the last-input-used tracker `HD1` actually
asks for (so a mouse-and-keyboard player with a pad merely plugged in would
still see gamepad glyphs), and `combat_hud.gd`'s Actions row — the owner's
own reproduction case, the F/RB throw button — was left untouched on
purpose, a separate five-verb glyph set from the four ids this slice built.
Four local blind-judge rounds, three real legibility fixes (two Kenney
source icons' baked-in text turned to mush at the size this renders at;
swapped for symbol-only alternatives and a larger base size).

**Third slice landed: `tab_backpack.gd` quantity-clipping bugfix — see
`DONE.md`.** A round-3 blind-judge finding (item quantity vanishing off
longer item names, e.g. "Small Potion" showing no held-count at all) found
stranded on an abandoned, never-merged branch and finished/shipped by a
later firing. Does not touch the re-skin itself — see `EV9-panel-reskin`
below.

**`EV9-panel-reskin` (inventory grid + crafting panel re-skin, plus the
crafting screen's missing primary-action button) shipped — see `DONE.md`.**
This entry's own "still open" bullet below was stale: `tab_backpack.gd` and
`tab_build.gd` were already wrapped in `menu_tab.gd`'s shared dark/teal
`_panel()`/`_style_slot()` language by the time this was picked up — the
reskin itself had shipped without ever being recorded here or getting the
required blind-judge pass. Ran that pass for real; it confirmed the panel
language and found one genuine gap the fix above closes.

**Still open — do NOT re-scope these as a separate item, they are this
item's remainder:**
- ~~The "[X] / [E]" input-glyph replacement...~~ **Tracked as `HD1`,
  Phase -0.85 — narrowed, not closed, by this item's second slice above.**
  Still needs the last-used-input-device tracker (no "joypad merely
  connected" shortcut) and still needs `combat_hud.gd`'s Actions row wired
  through it — see `HD1`'s own entry for the current, accurate scope.
- The "one tracked objective" line has nothing to read yet — `SB9`/`SB11`
  (progression-state system, quest log) are still open. Wire the label once
  that state exists; a label bound to nothing is a permanent blank box, the
  opposite of §16's "hide/fade what's not relevant."
- Compass — bible says "if it exists"; it doesn't yet, not this item's job to
  invent one.
- Icon glyphs for HP/STA/Pals/Orbs, a branded display font matching the
  "TETHERBOUND" key-art logotype, and gradient/beveled bar fills — all named
  explicitly by the round-3 blind critic as needing new assets, not scene
  tuning. No board exists for a display font; flag to the owner before
  picking one, per `CLAUDE.md`'s asset-generation rule.

**`EV9-double-prompt` (CombatHUD silently mirrored the exploration prompt outside a fight) fixed — see `DONE.md`.**

### EV10 ▶ — Cohesion pass
`model: fable` · `tests: none` · `area: visual`
Bible §22 Phase G and §23's metrics. Re-shoot the same viewpoints, blind-judge
against both reference sets, fix the three biggest gaps, repeat until further
improvement is asset-quality-limited rather than composition-limited.

---

## Phase -0.55 — the cast (owner's NPC board)

`docs/art/reference/12_NPC_Bases_Reusable.png`, and spec §21/§22/§35/§36.
The board specifies **three** base bodies at player height — Female Villager,
Male Villager, Team Tether Grunt — each with hair/head variants, outfit
variants, palette rows and accessories, and it **supersedes §22's "one or two"**.

Its own implementation notes are the technical brief: *material/texture swap for
colour variants, hide/show accessories via separate mesh parts, hair variants
sharing head topology, keep colour calls low by using shared materials.*

**`NP1` (the modular NPC variant system: per-material palette, hair,
accessories, all data) shipped — see `DONE.md`.** The hair/accessory shapes
are placeholder primitives, not real geometry — none of the three rigs has a
separable hair or accessory mesh yet.

**`NP1-geometry` checked and moved to `BLOCKED.md` (2026-08-12) — its own
premise didn't hold.** It read as blocked-then-unblocked once `NP4`/`NP4-rig`
shipped three new humanoid bases; checked directly (parsed each `.glb`'s glTF
JSON the same way `NP1` did for the original three rigs) rather than trusting
the premise, and `villager_female`/`villager_male`/`grunt` are each **one
fused mesh, one material, no separate hair or accessory node** — identical to
trainer/Grandpa/Warden's own limitation. `NP4`'s Meshy image-to-3D pipeline
never was going to produce the board's own "hide/show accessories via
separate mesh parts, hair variants sharing head topology" brief; it generates
one manifold body. `EV1-remainder`'s two Quaternius kits (checked directly,
`assets_raw/vendor/`) are village architecture and props, nothing
character-shaped. So there is still no real modular hair/accessory geometry
anywhere in the project, and `D23`/`D24` foreclose generating one — humans are
rework-only, permanently, at any credit balance. See `BLOCKED.md` for the
full entry. **Trap for whoever eventually takes it:** `_attach_part()` sets a
placeholder's `offset`/mesh size as a *local* child of a `BoneAttachment3D`
inside the same 0.01-scale Armature chain `docs/HANDOFF.md` §6 documents for
the giant-player bug — `NP2` measured it directly, a "size 13" primitive
renders as 0.13m, a factor of 100. `_apply_hair()`'s own `0.08` offset is
almost certainly landing at ~0.0008m in the live game, effectively at the
bone origin rather than actually offset. Real geometry from a modular mesh
may sidestep this by not needing a manual offset at all — but if this item
still calls `_attach_part()` for anything, budget time to fix the scale
compensation there rather than rediscovering the same trap `NP2` did.

**Correction, found by `NP2`: the palette mechanism itself was invisible.**
All three human rigs' materials carry `emission_enabled = true` with
`emission_texture` set to the same painted albedo texture at a full-white
multiplier. Emission is additive and independent of lighting, so it swamped
any `_apply_palette()` tint completely — proven with a diagnostic that
tinted the Warden pure red and rendered him fully green, unchanged.
`character_model.gd`'s `_shared_variant_material()` now tints emission the
same way, so this is fixed for every caller, not just `NP2`'s — but it means
R7.2's three villagers, believed visibly tinted since `NP1` shipped, have
never actually looked different from each other in a rendered frame. Worth
a look next time anyone is near `village_npcs.gd`.

**`NP2` (Team Tether rank palettes) shipped — see `DONE.md`.** Grunt,
officer, captain and Warden, all on the Warden's rig (the only faction-
appropriate body installed; `NP4`'s Grunt has no game path yet, see
`NP4-rig`). A body-tint-only ladder failed blind review outright ("a
lighting gradient, not a rank system"); the real rank marker that shipped
is a chest badge using `NP1`'s own accessory mechanism, escalating in both
colour and size, converged after 3 rounds.

**`NP3` (the named Meadows cast) shipped — see `DONE.md`.** Mira, Oskar and
Tam got identity lines (Meadow Keeper, Bridgehand, Field Scout); the Quarry
Foreman and Rescued Ranger were added as two new reused-rig villagers. Real
trainer battles stay out of scope — that's `R8.1` and `SC12`–`SC15`, not §35.

**`NP4` (generate the three bases) shipped — see `DONE.md`.** Two of three
(villager_female, grunt) passed a two-round blind critique; villager_male's
trousers render darker/colder than the reference after three texture
attempts and villager_female has a persistent UV-seam texture blotch on one
shin — both recorded there as an honest remainder, not chased further after
two flat attempts each per `conventions.md`'s stopping rule.

**`NP4-rig` (rig, animate and install the three NP4 bases) shipped — see
`DONE.md`.**

**`NP5` (swap village NPCs onto the NP4 bases instead of recolored hero
rigs) shipped — see `DONE.md`.** One judgment call flagged there rather than
made silently: no source in the repo names a canonical gender for any of
the five villagers, so the female/male base split went by name convention
and roster balance.

**`NP6` (village NPCs reading flat-black in exterior frames) fixed — see
`DONE.md`.** Three real local blind-judge rounds; the darkest two villager
tints were brightened until a genuinely blind critic stopped calling any of
them unlit/silhouetted.

---

## Phase -0.75 — the owner's Meadows spec, P0 (owner directive, 2026-08-11)

`docs/MEADOWS_PROGRESSION_SPEC.md` §1 and §38 Phase A, made canon by
`docs/decisions/D23-the-meadows-is-the-first-game.md`. Owner-reported from a
real playtest of the published build, the same way Phase -1 was — **above the
rest of Phase -0.5**, because three of the five change what a survey frame
contains and judging a build that is about to change wastes a render pass.

Step 1 of the spec's Phase A — the PC mouse-capture lifecycle (spec §1C) —
**already shipped as `RB1`; do not rebuild it.** `playground_world.gd`
re-asserts capture on `Window.focus_entered` and backs off through
`_mouse_wanted_elsewhere()` for menu, dialogue and the name prompt, which is
the same mechanism §1C's Escape / menu-restore / Alt-Tab clauses describe. The
spec's ten-minute acceptance test is on-device work and is tracked as `SH53`,
not as a reopening of RB1.

**`SA2` (Grandpa's door gated until the opening beat is done) shipped — see
`DONE.md`.** One new finding opened below: `SA2-flake`, a pre-existing
`smoke_opening` beat-4 intermittent failure, unrelated to `SA2` itself.

**`SA2-flake` (`smoke_opening` beat 4 intermittent failure) fixed — see
`DONE.md`.** A pattern fix, same shape as `LP2` — the race itself was not
directly forced to reproduce locally, but it did reproduce for real on
`main`'s own CI moments before this was picked up, with the exact documented
signature.

**`SA3` (physical perimeter + below-world failsafe) shipped — see `DONE.md`.**

### SA4 — Seven outward spokes, each believably severed
`model: fable` · `tests: smoke_traversal`
Spec §1E and §29. Seven routes leave the perimeter — river gorge (Water), old
storm road (Electric), mountain trail (Fire), high pass (Ice), cliff road
(Air), ancient stone gate (Psychic), sealed blighted road (Dark) — each blocked
by something physical: collapsed bridge, rockslide, flood, damaged lift, Tether
blockade, sealed gate. **No "Biome Locked" messaging, ever** (spec §19, and
`GAME_DESIGN.md`'s traversal pillar). §29 is what gives them meaning: these are
severed old roads, not seven dead ends someone built — broken roadbed, old
signage, abandoned trade infrastructure, land visible on the far side. This is
the seed `R8.6` pays off and the geometry `SF33` later dresses. Done when: all
seven are reachable on foot from the village, each is visibly and physically
impassable, and none of them explains itself with UI text.

**`SA5` (recolour Burrowback away from Terrapup) shipped — see `DONE.md`.**

**`SA6` (separate the five birds by palette) shipped — see `DONE.md`.**

---

## Phase -0.85 — HUD and item access (owner's third pass, 2026-08-11)

The owner played again and reported a long list of usability gaps. Checked
against the actual code before touching the backlog, because several of them
turned out to already be built:

**Already shipped, not backlog items — verify on-device before anyone rebuilds
them.** The active pal already follows the player automatically once adopted
(`follower_pal.gd` + `encounter_director.gd::adopt_starter()`, wired into the
live `meadows_playground.tscn`). The orb throw already shows a glowing sphere
with a halo and a trail, plus a trajectory arc while aiming (`orb.gd`,
`throw_preview.gd`) — the code comments describe this as a deliberate fix from
an earlier visual pass for this exact symptom. If either is still missing on
the owner's device, that's a bug report against a specific build, not a gap to
plan for here — check the build timestamp first.

**Genuinely new work below.** `HD1`/`HD2` are new; `R7.4` (minimap) is
promoted from Phase 7 by pointer, not duplicated; `CO1` extends the existing
follow system rather than replacing it; `SA7`/`SA8` are explicit owner
directives (`CLAUDE.md`'s carve-out applies — implementing these is not a
firing inventing a story beat).

**`HD1` (device-aware input glyphs) shipped — see `DONE.md`.** Both real gaps
closed: `combat_hud.gd`'s Actions row now draws real device-aware icons
instead of hardcoded Xbox letters, and `input_glyph.gd` reads a real
last-used-input-device tracker (new, on the `Game` autoload) instead of "is a
pad connected." Two blind-judge rounds found and fixed a size regression and
a dimming bug; one narrower remainder opened below. Deliberately did **not**
build UI for `combat_switch_left`/`combat_switch_right` — traced them and
confirmed no code anywhere reads those bindings (mid-combat pal switching
isn't an implemented mechanic; `CO1`'s swap is exploration-only), so building
icons for them would be inventing combat UI for a feature that doesn't exist
rather than wiring up a real one.

### HD1-remainder — Quick and Charged render the same mouse-button icon, mirrored
`model: sonnet` · `tests: none (visual)` · `area: ui`
A second blind-judge round on `HD1`'s combat Actions row confirmed the
dimming and sizing fixes but named one persisting defect both rounds agreed
on: `mouse_left.png`/`mouse_right.png` (Kenney Input Prompts) are the same
mouse-body silhouette with only the highlighted button-half mirrored, and at
~36px on-screen that reads as "one icon, two colours" rather than two
distinct buttons — the label text is what actually disambiguates them, not
the icon. Checked the staged pack (`assets_raw/vendor/kenney_input-prompts/
Keyboard & Mouse/Default/`) for a better-differentiated pair (an "LMB"/"RMB"
text variant, say) and none exists; this is a real asset-ceiling, not an
unexplored lever. Low severity — the adjacent label always disambiguates in
practice — so left open rather than blocked. Done when: either a
better-differentiated CC0 mouse-button glyph pair is sourced, or the owner
accepts the current ceiling.

### HD2 — A real quick-access item hotbar
`model: sonnet` · `tests: none` · `area: ui`
Five slots, usable directly without opening the full backpack — berries,
potions, orbs. `menu.json`'s own `_comment_backpack` used to claim a
`hotbar_columns` key already existed for this; it never has (checked directly
— see the "Found along the way" fix below), so this item builds the key as
well as the feature, not just repurposes one. `R2.1`, §19 scoped tool cycling
separately; this is the first item asking for a general consumable band.
Wires into the use verb that already exists in
`tab_backpack.gd::_read_use()` rather than building a second one — see the
correction on `R2.5` and the "Found along the way" entry above for what that
verb already does. Done when: a potion can be used without opening a menu,
with the correct `HD1` prompt shown next to the slot.

**`CO1` (manual pal summon, dismiss and swap) shipped — see `DONE.md`.**

**`SA7` (a gated road out of the village, with a key nearby) shipped — see
`DONE.md`.** One narrower remainder opened below.

**`SA7-remainder` (the gate's lock and the key both read clearly to a blind
critic now) shipped — see `DONE.md`.** The "shape-resolution ceiling" this
item's own prior rounds diagnosed was not real; a debug render caught two
actual bugs (a facing-direction sign error, and a metallic material with no
environment reflection to show under this renderer) that had kept both
objects effectively invisible or dark regardless of shape/colour tuning.

**`SA8` (Grandpa's opening dialogue: the Team Tether urgency beat) shipped — see `DONE.md`.**

---

## Phase -0.5 — Visual pass (owner directive: finish this before R1–R8)

Everything the two 2026-08-09 blind reviews (`docs/reviews/2026-08-09-site-
frames-blind-critique.md`, `docs/reviews/2026-08-09-r0.8.5-full-blind-
review.md`) found that is fixable by changing the scene, gathered here and
worked in this order. The one finding that is NOT here on purpose: the
creature/human art-pipeline style mismatch is a design decision (rework vs.
replace assets) parked in `BLOCKED.md` for the owner — `CLAUDE.md` forbids
inventing that call, gate or no gate.

**VP2 (preview_creatures.gd rendering zero creatures) fixed — see `DONE.md`.**

**R5.1 (day/night cycle) shipped — see `DONE.md`.**

**R7.1's signposts and stronghold silhouette shipped — see `DONE.md`.** Three
bullets of the original five are still open:

**R7.1-visual (blind-reviewed the signposts and stronghold silhouette, three
rounds) shipped — see `DONE.md`.** One remainder opened below.

**R7.1-visual-remainder (new wall/roofline/crenellation geometry, blind-
reviewed over three rounds) shipped — see `DONE.md`.** Close and mid range
now genuinely read as fortified architecture; a narrower long-range
remainder is opened below.

**R7.1-visual-remainder-2 (long-range fortress read) CLOSED by R9.4 — see
`docs/reviews/2026-08-11-r9.4-full-visual-pass.md`.** The shape was never the
problem. Its own third round had suspected as much ("a placeholder-primitive
fortress cannot clinch this distance") and it was wrong: R9.4 rendered the same
geometry at all three ranges with a corrected material and it reads as a
fortified silhouette at every one, crenellations and varied massing included.
What was actually wrong was the COLOUR — `unshaded` at `#2a2630` is so dark a
fresh critic called it "a hole punched in the image rather than a stone ruin".
Now `unshaded` at a dark slate stone value. The two smaller findings that entry
carried are still live: the north tower's cap reads as a chimney, and the
ridge's hard-edged tan mound cap is terrain material, which `R7.1-remainder-2`
below already owns.

**The olive/lime ground seam is fixed — see `DONE.md`.**

**R7.1-remainder (ridge-bias clump placement + ground-cover clustering, three
rounds) shipped — see `DONE.md`.** Genuine, visible improvement over the
pre-fix state, but neither bullet fully passes the blind critic yet; a
narrower remainder is opened below.

**R7.1-remainder-2 COLLAPSED into `EV3` (ground cover) and `EV5` (the water
question it raised).** Not closed — superseded. It spent three rounds
redistributing a fixed instance count and the critic kept saying the same
thing, which is the signal that the lever was wrong: `EV3` rebuilds placement
around clusters, clearings and seven layered bands instead of tuning noise, and
`EV5` answers the "would water do more for depth than more vegetation?"
question it ended on by just building the pond. Its evidence is kept below
because `EV3` inherits it as the bar to clear.

Original entry — Ground cover still reads procedural, horizon mid-ground still sparse:

R7.1-remainder's third and final blind-critic round, on the post-fix survey
(owner-directed interactive session, 2026-08-10/11): the field still "reads
underpopulated" against both references (its #2 ranked gap, right behind
sky/fog consistency), and names both original bullets specifically —

- **Continuous ground cover, still not clearing.** Despite three rounds of
  tuning (bigger tufts, per-instance colour jitter, cut `strays` grass
  2000→500 / drygrass 700→200 for tighter clumping — see `DONE.md`), the
  critic still calls the scatter "roughly even spacing and uniform scale in
  02, 03, and the open ground of 01 and 05... no clearings, no clustering
  around features, and no scale variety within a prop type." The clump
  structure that IS there (visible in 03, 04) isn't enough density to read
  as continuous cover rather than isolated groups. Next attempt should try
  a genuine density lever inside the clumps themselves (more `per_clump`,
  smaller `clump_radius` for tighter packing) rather than further
  redistributing the same instance count, and re-judge against Palworld's
  own field shots specifically for how many blades are actually on screen
  at once.
- **Horizon/mid-ground, partly the known unfixable limit, partly not.**
  "No middle-distance layering anywhere in the set (no tree lines,
  ridgelines, or water)... the single biggest reason these frames feel
  empty." Some of this is `world_background = NOISE` (Terrain3D's
  procedural continuation past the 512m bake, genuinely can't hold props —
  see the original `R7.1-remainder` entry in `DONE.md`), but the finding
  reads as broader than just the unreachable far band — the near/mid
  ground inside the bake is also thin. Worth investigating whether a
  water feature (a pond/stream, named as a biome pillar in `GAME_DESIGN.md`
  but absent from every survey frame) would do more for depth-reading than
  further vegetation tuning.

Two smaller findings from the same round, not chased further to stay
inside the three-round cap **that no longer exists** — it was replaced on
2026-08-11 by a convergence test, so whoever takes `EV3`/`EV8` should not
inherit this entry's reason for stopping: sky/fog treatment is inconsistent between
frames (01/05 show a blue gradient sky, 02 a dark navy sky with hard-edged
cloud shapes, 03/04 a flat cream band) — likely a lighting/environment
config difference between survey viewpoints rather than a scatter issue,
worth its own investigation; and a small aliased red-maroon shape in 03
that the critic couldn't resolve into a legible object, possibly a
retint/LOD edge case on a single tree instance.

**R7.1-found (rise-overlook eye moved off the tower cluster) fixed — see `DONE.md`.**

**R7.1-found-2 (near-vertical bank near spawn, root-caused to overlapping
building-pad flattening, not a path or texture bug) fixed — see `DONE.md`.**

**R7.1-found-3 COLLAPSED into `EV4`.** The stripe is a colour/blend-map
artefact, and `EV4` replaces that whole painting approach with the control map
and eight authored layers — fixing it under the old scheme would be work thrown
away. Evidence kept:

Original entry — a flat texture-splat stripe on the hillside behind the spawn crate:

Found running the confirmation visual-judge pass for R7.1-found-2 (frames
01, 05): a diagonal tan/khaki stripe on the hillside behind the wooden
crate, "crisp and uniform-width rather than irregular or grass-feathered,"
and not picking up raking-light shading in the low-sun frame the way real
terrain relief would — reads as an unintentional texture-blend artefact,
not an authored dirt trail or any part of R7.1-found-2's fix (that fix
touched height/geometry only, not the colour/blend map). Needs its own
look at whatever paints dirt/soil blends onto slope near the spawn pad in
`build_playground_terrain.gd`. Not chased here — out of scope for the
near-vertical-bank defect this pass was confirming.

**R7.2 (NPC villagers and interior polish) shipped — see `DONE.md`.** The
sub-agent that built it disclosed a real process gap (no way to spawn a
genuinely blind critic and read back its verdict from its own toolset) and
self-graded instead. The owning interactive session had that capability and
used it afterward — a real blind critique ran against a confirmed-on-`main`
render; see `DONE.md` for the verdict and why none of its findings needed
an R7.2-specific fix.

**R9.4 (full visual pass) ran — see `DONE.md` and
`docs/reviews/2026-08-11-r9.4-full-visual-pass.md`.** Two blind critics, three
render rounds, real measured movement on every axis, and a lot fixed —
including four defects no test could see (mirrored signpost text, a creature
embedded in a roof, a magenta placeholder cube, and a plinth regression the
same pass introduced and caught). It did **not** reach the bar, and the
remainders below are the honest split rather than a pass. The original item is
kept beneath them because its instruction — re-run and compare sheets, never
assert the fix landed — is the standing rule.

**R9.4-remainder-1 COLLAPSED into `EV4`.** Same file, same bake, same command.
`EV4` rewrites `terrain_playground.json`'s material set and re-runs
`build_playground_terrain.gd`; re-solving `colour.grass_low` / `grass_high`
toward neutral is one field of that edit, and doing it first would mean baking
the `.res` files twice for one large binary diff each. **`EV4` inherits the
acceptance number**: `frame_stats` mean saturation inside 0.40–0.50 on frame 01
without the ground going grey. The diagnosis below is why, and it is the part
worth carrying forward:

Original entry — Ground saturation still above the bar, and the rest of it is baked:

`tools/frame_stats.py` after three rounds: mean saturation 0.59 on frame 01
against 0.40–0.46 for the Palworld references and 0.39 for the key art. Round 1
found the cause and it is structural, not taste — `albedo_color` multiplies, so
every tinted multiplier RAISES saturation, and the ground had three stacked
(texture tint 0.675→0.796, baked colour map →0.859, macro variation →0.873).
Two of the three are now solved or neutralised. **The third is the baked colour
map** (`terrain_playground.json` `colour.grass_low` `#c2d492` / `grass_high`
`#d8dc9c`), and it cannot be changed at runtime: it is written into
`data/terrain/playground/*.res` at bake time. That file's own comment sets a
floor of `#c0` on every channel so the map "modulates rather than paints", and
`#c2d492`'s blue is `0x92` = 146 — it has been violating its own stated rule
since it was written. Done when: the map is re-solved toward neutral, the
terrain rebaked (`godot --headless --path . --script
scripts/world/build_playground_terrain.gd`), and `frame_stats` puts mean
saturation inside 0.40–0.50 without the ground going grey. Expect a large
binary diff on the `.res` files; that is the cost of the fix, not a mistake.

**R9.4-remainder-2 CLOSED by `EV8` — see `DONE.md`.** Neither of the costed
options fired: not a bigger bake, not authored distant geometry. The actual
fix was a third Terrain3D setting nobody had tried — `world_background = 0`
(NONE) draws nothing past the bake instead of NOISE's dune-shaped continuation
or FLAT's hard seam — paired with dropping the photographic sky panoramas,
whose baked-in sun position doesn't track this file's own sun angle and was
the real cause of the sky-treatment inconsistency. Evidence kept:

Original entry — The world past 512m draws pale and colourless:

The single largest contributor to the compressed value range, and it appears in
every outdoor frame as a near-white band along the horizon. Past the baked
512 m, `shader.world_background = 2` (NOISE) continues the terrain
procedurally — and that continuation has no colour map and no texture control,
so it draws in a flat pale default. Two critics independently read it as fog
"eating the world" and as distant hills "washed to 219,226,205, nearly white,
so the far ground has no form left"; both are describing this. It is the same
limit `R7.1-remainder` hit from the other side (the continuation cannot hold
props either), and `world_background = 1` (FLAT) was already tried and produced
a measured 0.146 luminance step across the whole frame. Options worth costing
before picking one: grow the bake (which `R7.3` has to do anyway for the
chapter), fake the far band with authored distant geometry, or lean into it
with a deliberate haze that reads as atmosphere rather than as absence. Done
when: a critic given the frames stops naming the horizon as the reason they
feel empty.

**R9.4-remainder-3 COLLAPSED into `EV6`**, which already names it. Building a
`retint` hook for the Quaternius structures that `EV6` then replaces wholesale
is the definition of wasted work — but the *requirement* survives the swap and
`EV6` owns it: `village.json` must be able to lift a structure's roof the way a
vegetation layer retints a leaf, whatever kit is underneath. Acceptance carries
over too: roofs in the reference's warm 35–65% band, not the 11–16% measured
here. Evidence kept:

Original entry — The pack buildings have no material override path:

Every roof in the settlement measures 11–16% luminance in direct midday sun
against a reference board that keeps its roofs in the warm 35–65% band and
spends its darks on tree canopy. The windmill's tower reads as a black cutout
in two frames, taking its own modelled mullions, gallery and arch down with it,
and the fences are solid black with no rail-vs-post break. `village.gd` places
Quaternius structures and never touches their materials — there is no `retint`
hook at all, unlike `vegetation.gd`, which has had one since the crimson-bush
fix. Done when: `village.json` can lift a structure's roof the way a vegetation
layer can retint a leaf, and the settlement's roofs sit in the reference band.

**R9.4-remainder-4 COLLAPSED into `EV4`**, which already names it and states the
same fix — the control map, not the colour map. Evidence kept, including the one
fact worth knowing before anyone re-tunes it: round 3 made the existing tint
visible for the first time, because desaturating the grass stopped drowning it.

Original entry — Paths are a colour-map tint, not a material:

`build_playground_terrain.gd` paints paths by lerping the COLOUR map toward
`#c8a874`, and its own comment already calls a real material "queued as
polish". Because the colour map multiplies the grass albedo, a path is
grass-coloured grass with a tan cast rather than bare earth — which is why both
critics reported "no worked ground anywhere in the settlement" and "stepping
stones scattered in loose clumps that don't form a path". The fix is the
CONTROL map, not the colour map: paint the soil texture along the route so a
path is a different material. Round 3 made the existing tint visible for the
first time (desaturating the grass stopped drowning it), which is worth knowing
before anyone re-tunes it. Done when: a path reads as trodden earth from
standing height, and the path stones sit in it rather than on grass.

**R9.4-remainder-5 COLLAPSED, split across `EV6` (the site plan and the trees)
and `EV7` (the props).** Both already name it. This is the item that most
justifies the whole of Phase -0.6: it is the one both critics ranked first or
second independently, and it was never fixable by tuning — the props it asks for
are in a pack the repo does not have. `EV1` acquires them, `EV7` places them in
authored clusters rather than scattering them. Evidence kept, especially the
critic's own shopping list:

Original entry — The settlement has no trees, no props and no site plan:

Both blind critics ranked this first or second, independently. The key art's
own STARTING SETTLEMENT panel is organised around oak canopy framing a worn
dirt square, rail fences leading the eye in, and garden beds against the walls;
the build has buildings standing on open ground, fence stubs that enclose
nothing, and **not one tree anywhere in the settlement** (`vegetation.json`'s
`clearings` hold vegetation off the square by design, and nothing was ever
authored back in). The critic's list of what would fix it: woodpile, barrels,
crates, a cart, a hand-pump, hitching rail, garden beds, a washing line.
Content, not tuning — and it belongs with `R7.3`'s authored-space work rather
than in a palette pass. Done when: the square reads as a place people use.

**R9.4-remainder-7 COLLAPSED into `SA1-lod` (the mechanism) and `EV3` (the
judgement).** Read the entry below knowing it names the wrong cause. It blames
the hard alpha scissor and R9.4 shipped alpha-to-coverage against that theory;
`SA1` then measured the actual problem, which is that the foliage pack imports
with `mipmaps/generate=false` on all 14 textures **and** `vegetation.gd`
rebuilds an `ArrayMesh` that discards the importer's LOD chain. So 28,732
instances draw at LOD0 at every distance, sampling un-mipmapped 512² textures at
roughly 50:1 minification — which is aliasing by construction, and also the best
explanation of the owner's "high memory, 25% GPU" profile. The mipmap half
shipped in `28af489`; `SA1-lod` is the LOD half. Alpha-to-coverage stays and is
still unverified on the Ally, but it was never going to be sufficient. Evidence
kept — the entry's *observation* was right even though its diagnosis was not:

Original entry — Foliage aliases into confetti at distance:

**Two independent blind critics, on different frame sets, both named this the
most bug-like thing in the build** — "blue, magenta and cyan speckle… reads as
compression noise, not foliage" and "blue/green/white confetti speckle".
Confirmed by crop: a distant tree resolves to a scatter of unrelated pixels.
Root cause is a hard alpha scissor, which has no partial coverage — every texel
is fully in or fully out, so a ten-pixel tree is a handful of disconnected leaf
texels with background between them. R9.4 turned on alpha-to-coverage in
`vegetation.gd`'s `_retint()` so the project's existing 4× MSAA
(`project.godot` `anti_aliasing/quality/msaa_3d=2`) can finally act on foliage
edges — **but that is unverified**: llvmpipe's MSAA is not something these
survey frames can honestly test, so this needs judging on the Ally. And it is
only half the problem: a ten-pixel tree carries almost no information whatever
the sampling, which is an LOD or impostor question this item does not answer.
Done when: a critic looking at the mid-distance stops calling the trees noise.

**R9.4-remainder-8 (three of its findings) fixed — see `DONE.md`.** The other
five did not reproduce, were out of this item's scope, or were not chased —
see the remainder below.

**R9.4-remainder-8-followup (both findings checked) closed — see `DONE.md`.**
One real, one a false alarm on the same pattern as the windmill rock. A
narrower open item, `R9.4-remainder-8-rocks-repeat`, is below it.

**`R9.4-remainder-8-rocks-repeat` (the colour half — the rocks layer now reads as varied stone) shipped — see `DONE.md`.** Three rounds: hue-only in one
value band was crushed flat by scene lighting; value-only (same hue, spread
dark/light) got real pixel movement but a fresh blind critic correctly called
it out as indistinguishable from lit-face-vs-shadow-face on one mesh; three
genuinely different HUE families (warm tan, cool blue-grey slate, rust-brown
ironstone) survive that confound because a single directional light changes
value with face angle but not hue, and a third blind critic confirmed it
directly — "real material variety, not a repeated instance." **What is NOT
fixed, and is not this item's scope**: every rock is still the same faceted
low-poly silhouette at the same rough scale in a loose evenly-spaced row, not
a jumbled quarry pile — real shape/size variety needs the itch.io-blocked
fuller Stylized Nature MegaKit (`EV1-remainder`), same ceiling
`EV2-landmark-ceiling` already hit for hero trees.

**`R9.4-remainder-6` (root-caused why `survey_combat.sh` never completed) shipped — see `DONE.md`.** Not a hang: real per-phase timing (added to the
script itself) shows `SETTLE_FRAMES` alone costs ~278s running completely
alone on this box's software renderer, ~1.16s per physics frame against a
scene with 24,314 scattered props — at that rate `_approach()`'s own
1200-frame cap could cost another ~23 minutes on top, before any combat
logic runs at all. One real bug found and fixed along the way (the
charged-attack energy wait had no iteration cap, unlike every other wait
in the file). **The arena still has not been visually reviewed** — a
narrower remainder for that is opened below with the timing evidence a
future attempt needs.

**`R9.4-remainder-9` (get real combat frames) shipped — see `DONE.md`.** All
eight frames, for the first time — but getting there needed three separate,
real bug fixes in the survey harness itself, not just render-time patience:
the D18/SA0 indoor-opening redesign moved the scene's default player spawn
into Grandpa's farmhouse, which cascaded into the player never reaching the
wild pal, never having an ally pal to fight with, and never having orbs to
throw. All three fixed. The required blind pass on the real frames then found
genuine combat-presentation defects — narrower remainder opened below.

### R9.4-remainder-9-combat — The fight itself doesn't read as an event yet
`model: sonnet` · `tests: none (visual)` · `area: combat`
A genuine blind critic reviewing `R9.4-remainder-9`'s real, working combat
frames (not placeholder-scene artefacts this time) named several concrete
presentation gaps, none of them about creature model appeal:

- **No visual impact cue on the quick attack.** Only the health bar moving
  says a hit landed; the frame itself shows nothing.
- **The charged attack's impact effect reads as a flat decal** pasted onto
  the grass rather than something that emanates from the point of contact.
- **The wind-up telegraph has no visual cue independent of its own banner
  text** (`! incoming — move`) — cover the text and the frame is
  indistinguishable from ordinary standing.
- **The thrown orb in flight reads as a stray lens-flare crossing the sun**,
  not a projectile arcing at a target a few metres away.
- **Two visually identical rabbits on screen at once** (the wild pal being
  fought and an ambient decorative Bramblebun from the same 3-count spawn
  cluster, `data/config/spawns.json`) with no marker distinguishing which one
  is actually the opponent.
- **The arena boundary glow is visible in some frames and absent in others**,
  with the backdrop also changing between them — reads as two fights spliced
  together. Not confirmed as a bug: the boundary may be edge-proximity-only
  by design (matches its own "slides you along it" description), in which
  case this is a false alarm from frames taken at different points relative
  to the edge. Check before treating it as a defect.

What already works and should not be re-litigated: HUD element placement and
hierarchy (enemy bar top-centre, own pal bars bottom-left, orb count
bottom-right, action prompts bottom-centre) closely matches the Palworld
reference's own layout; the boundary glow, where present, reads clearly as a
line; relative scale (trainer > Terrapup > Bramblebun) is correct. Re-render
with `tools/survey_combat.sh` (now fixed and working, no changes needed to
reach the arena) and re-run the required blind pass after any fix. Done when:
a fresh blind critic given the eight frames no longer names impact
readability, the telegraph, the orb-in-flight or the lookalike-target
confusion as defects.

**The original R9.4 brief is NOT repeated here as an open item** — it ran, and
an identical heading below its own remainders is how a task gets done twice.
Its standing instruction outlives it and is quoted here because every
`-remainder` above inherits it: *confirm the findings actually moved, the way
`docs/reviews/2026-08-09-site-frames-blind-critique.md`'s own "after judging"
section requires — re-running and comparing sheets, not just asserting the fix
landed.* The one part of the original brief the 2026-08-11 pass did NOT
discharge is the **full-roster creature sheet**: `preview_creatures.gd` ran,
but the sheet was destroyed before any critic saw it, and the roster has not
been blind-judged since R0.8.5. `SA5` and `SA6` in Phase -0.75 both need that
sheet as their starting evidence, so whoever takes them should re-run it first
and can close this gap in passing.

---

## Phase 1 — vocabulary, before the codebase grows

### R1.1 — Rename `pal` → `creature` everywhere
`model: haiku` · `tests: FULL SUITE`

~446 occurrences across 52 code files at last count (the overhaul will have
moved it — recount, don't trust it), plus `scripts/pals/` →
`scripts/creatures/`, `assets/pals/` → `assets/creatures/`, `data/pals/` →
`data/creatures/`, scene node names, class names, signals, UI strings,
dialogue, and every doc including `CLAUDE.md` and `GAME_DESIGN.md`.

Mechanical but wide. Godot resource paths (`res://`) live in `.tscn`, `.tres`
and `.import` files as well as `.gd` — a rename that misses those breaks the
project silently at load. Do it in one commit so no intermediate state is half
renamed.

Leave `docs/decisions/D01`–`D20` on the old vocabulary: they are a historical
record of decisions made when the word was "pal", and rewriting history to
match present vocabulary is how a decision log stops being trustworthy. Add
one line to each affected decision noting the rename instead.

Done when: no `\bpals?\b` outside `docs/decisions/`, full suite green, Windows
export succeeds.

### R1.2 — Vocabulary sweep of the handoff and decision index
`model: haiku` · `tests: none`

---

## Phase 2 — the first day, remainder

The session shipped harvest nodes, camp placement, campfire/bedroll and rest
(see Phase 0's note). What is left is the part that makes them an *economy*
rather than a scripted route.

**`R2.1` (Tools) shipped — see `DONE.md`.**

**Bookkeeping note, 2026-08-12: `R1.1`'s codebase-wide `pal`→`creature`
rename is nominally topmost/unheld but was skipped as unsafe to start while
7 lanes hold `story`/`terrain`/`vegetation`/`village`/`ui`/`lighting`/`perf`
— it touches ~446 occurrences across every `.gd`/`.tscn`/`.tres` file, which
collides with every one of those in-flight branches at once rather than
zero of them. `R1.2` depends on `R1.1` having happened, so it is not
independently takeable either. Neither is blocked in the `BLOCKED.md`
sense — both are simply not safe to start with this many concurrent
lanes live; a future firing with the areas quiet is the right one to
take them.

**`R2.2` (Tool durability and free repair) shipped — see `DONE.md`.** Repair
is free, from the backpack menu rather than a physical workbench — `R2.7`
(Workbench and storage container, below) hasn't built a placed station yet
for GAME_DESIGN.md §19's "at appropriate station" to gate against.

### R2.3 — Real tree/rock harvesting on the vegetation
`model: sonnet` · `tests: test_harvest`
The ~10 authored nodes were the tutorial route; this makes the *world*
harvestable — the scattered Terrain3D trees and rock outcrops themselves,
reusing `interactable.gd` and the nearest-wins arbitration, respecting the
path keep-clear. Done when: walking up to any ordinary tree and holding the
button puts wood in the satchel.

**Owner feedback, 2026-08-11: gathering "seems to randomly pop up."** Checked
against the code — it isn't random. The ~10 nodes are real placed props with
real models (`harvest_node.gd`, `data/config/harvest.json`), not invisible
triggers. The actual cause is that they're visually **identical** to the
hundreds of decorative trees/rocks scattered by `vegetation.gd` around them —
nothing distinguishes a gatherable stump from an inert one until the prompt
appears at close range, which is what reads as arbitrary. **Add to this
item's done-when**: a harvestable prop must read as harvestable from a
distance a player would actually approach from — a distinct material, a
glint, a marker, whatever `EV`'s art pass makes available — not just a prompt
on arrival.

**`R2.4` (Orb and potion crafting) shipped — see `DONE.md`.**

**`R2.5` (REMOVE the post-fight auto-heal) shipped — see `DONE.md`.**

**`R2.6` (floor/wall/door/roof/fence as a real, generalized build-piece
catalogue) shipped — see `DONE.md`.** Two real rounds of the required blind
pass, real movement both times; did not fully clear the bar. The residual
gaps (door not in a cut wall opening, wall/roof palette mismatch) are
`EV6`-shared, not R2.6-specific — see `DONE.md` for the full account and
the concrete next lever (`Wall_Plaster_Door_Flat`) for whoever picks this
back up.

### R2.7 — Workbench and storage container
`model: sonnet` · `tests: test_storage` (new)
Storage holds **items**. It is never creature storage. Five, ever.
The workbench upgrade is a Rootstone sink (spec §3 Band 2, `SD18`).

### R2.8 — Creature bed
`model: sonnet` · `tests: test_build_catalogue`

### R2.9 ▶ Play gate — does building a small home feel useful and enjoyable?
§33 criteria 6 and 7.

---

## Phase 3 — art debt and persistence

**`R3.0` (re-process the three humanoid GLBs through the fixed pipeline)
shipped — see `DONE.md`.** The literal Meshy-refetch path was unavailable
(the pre-animation rig output was never committed and this ran in a fresh
container with no Meshy key); fixed `animate_humanoid.py` to work from the
currently-installed GLBs instead, by stripping any pre-existing animation
before authoring fresh clips. Verified structurally (the `Armature` node's
malformed `0.01` scale is gone from the exported file) as well as by
`smoke_art`. The trainer's undersized backpack (HANDOFF §6) is unchanged,
same as before — a mesh-volume edit outside this item's scope.

**`R3.1` (save and load) shipped — see `DONE.md`.** `SB9` did not exist yet
to carry (Phase 3.5 is still ahead of this in the file), so version 1 has no
progression-flag section; whoever ships `SB9` owns the version bump this
item's own brief anticipated. One narrower gap opened below.

### R3.1-remainder — A placed storage chest's own contents do not survive save/load
`model: sonnet` · `tests: test_save_format` · `area: save`
`R3.1` made `GameState.placed_buildings` the canonical record of what the
player has built, and a placed storage chest (`R2.7`) round-trips as an
entry in it like anything else — but the chest's own independent
`Inventory` (`storage_state.gd`) is never read at save time or restored at
load time, so a chest that comes back after a reload is real and in the
right place, just empty. The registry entry would need an optional `state`
payload (the chest's own `slot_count()` stacks, same shape the player's
satchel already uses) captured at save time by walking the live
`placed_building` group rather than trusting a snapshot taken once at
placement, since a chest's contents change long after it is planted.
`camp`, the only other stateful piece, carries nothing worth persisting
beyond its position, so this is scoped to storage specifically rather than
a generic "every building might have state" mechanism. Done when: depositing
items in a chest, saving, reloading, and opening the same chest shows the
same items.

### R3.2 — Death satchels persist across save/load
`model: sonnet` · `tests: test_satchel` (new)

### R3.3 — Player death and respawn
`model: sonnet` · `tests: test_player_death` (new) · §22

---

## Phase 3.5 — reusable progression infrastructure (spec Phase B)

`docs/MEADOWS_PROGRESSION_SPEC.md` §15, §16, §35. Everything in the Meadows
chapter (Phase 8) stands on what this phase builds.

**The two NPC items that used to live here moved.** `SB7` and `SB8` are now
`NP1` and `NP2` in Phase -0.55, because the owner's NPC board arrived and made
them art-direction work that the whole cast waits on, not progression plumbing.
Their headings below are collapsed, not open. What is left here is state:
`SB9`, `SB10`, `SB11`.

Placed *after* Phase 3 on purpose: `R3.1` writes the first save format and it
is "versioned from the first write". `SB9`'s flags belong in version 1, or
adding them later costs a format bump for nothing.

**SB7 COLLAPSED into `NP1`, which supersedes it and now runs far earlier
(Phase -0.55).** They are the same work, but the owner's NPC board asks for more
than this entry did: per-material overrides are necessary and not sufficient,
because the board specifies **hair variants sharing head topology and
accessories as separate toggleable mesh parts**. Colours alone cannot express
that. `NP1` carries this entry's acceptance test forward unchanged and adds
visible accessories to it. Evidence kept:

Original entry — Per-material NPC variants, not one global tint:

Spec §21. R7.2 already proved the idea — Mira, Oskar and Tam in the square are
Grandpa's and the trainer's rigs with a `tint` in `art.json` — but `tint` is a
single multiply over every surface (`character_model.gd::_apply_tint`), and §21
names that exact failure: "do not recolor everything with one global tint if it
destroys material separation." Grow the `art.json` block into per-material
overrides (hair, jacket, trousers, boots, belt, pack visibility) keyed by
surface or material name, with the existing single `tint` still honoured so
nothing already placed breaks. Done when: two NPCs on the same rig differ in
jacket and hair colour independently, and neither is a flat wash of one hue.

**SB8 COLLAPSED into `NP2`.** Identical work, moved to Phase -0.55 with `NP1`
underneath it. One thing changed since this was written and `NP2` records it:
the board's Team Tether Grunt base means the "keep the main-character base for
civilians until §22's optional grunt base exists" hedge below now has an end
date — `NP4` generates that base. Until then this entry's advice stands, and
`NP2` repeats it. Evidence kept:

Original entry — Team Tether rank palettes on the Warden rig:

Spec §21, §35, §36. The Warden's rig is the faction's base body. Four rank
tiers as data on top of `SB7`: grunt (charcoal, muted forest green, minimal
gold), relay/field officer (deeper green, bronze trim), captain (dark green,
brass, one regional accent), Warden (richest materials, cream fur mantle,
strongest gold — unchanged). Rank has to be readable at gameplay distance
without a nameplate, because the geometry repeats. One caution the spec hedges
on and this item should not: §21 offers the **main-character** base for "junior
Team Tether personnel", but that rig is the player's own body and enemies
wearing it will read as clones of the player. Prefer the Warden base for every
faction NPC; keep the main-character base for civilians until §22's optional
grunt base exists. Done when: the relay captain, a regional captain and the
Warden stand in one frame and a blind critic ranks them correctly by seniority.

### SB9 — The smallest progression-state system that survives the chapter
`model: opus` · `tests: test_progression_state` (new), FULL SUITE
Spec §15. Objective flags, completion flags, trainer-defeated state, keys and
tokens, bridge-unlocked, dungeon-cleared, captive-rescued, Sigils 0/3,
stronghold-unlocked, Warden-defeated, post-Warden world state. Lives on the
`Game` autoload beside the party and the satchel — D14 is explicit that one
autoload is the design and a second is not. Objectives are data
(`data/progression/`); the code is a flag store plus a has/set/completed API.
**Spec §19 bans a "giant generic quest engine" and §15 says the same thing
twice; this is the item on the whole backlog most likely to become one.** If it
starts wanting branching, timers, prerequisites-of-prerequisites or a scripting
language, stop and split it. Done when: a flag set in one scene is readable in
another, survives save/load (R3.1), and no gameplay script hardcodes a story
boolean.

### SB10 — Physical keys, gears and Sigils that open real things
`model: sonnet` · `tests: test_progression_state`
Spec §3 Gate 1, §15, §19. A gate is a mechanism in the world that a carried
item operates — the South Bridge Key, the Mill Bridge Gear, three Sigils —
never a level check and never a UI lock. The player may walk to a closed gate
at any level and be refused by the gate, not by a dialog. Done when: holding
the right item and interacting opens the crossing, and not holding it produces
an in-world response.

### SB11 — One tracked objective, and a two-list quest log
`model: sonnet` · `tests: smoke_menu`
Spec §16. One concise line on the HUD ("Earn access to the South Bridge",
"Defeat the Upper Meadows captains. 2/3") and a log with exactly two lists,
Main Story and Local Requests. `playground_hud.gd` owns the line, `game_menu.gd`
gains the tab. Reads `SB9` and invents no state of its own. Done when:
completing an objective changes the HUD line without a scene reload.

---

## Phase 4 — combat, progression, the team

### R4.1 — Levels and XP · `model: sonnet` · `tests: test_progression` (new) · §11
### R4.2 — Core stats and per-instance individuality · `model: sonnet` · `tests: test_progression` · §11
### R4.3 — Moves · `model: sonnet` · `tests: test_moves` (new) · §13. `data/moves/` is **empty**.
### R4.4 — TMs and teaching moves · `model: sonnet` · `tests: test_moves` · §13

### R4.5 — Tuskroot's REAL model 🔒 — LIKELY ALREADY DONE, needs verification
`model: sonnet` · `tests: smoke_art`
**R0.8.5's full blind review (2026-08-09) found this is probably no longer
true.** `assets/pals/tetherbound/tuskroot/models/pal_tuskroot_lod0.glb` has
a different file hash from `ollie-the-songbird.glb`, and a fresh turntable
render (`docs/reviews/2026-08-09-r0.8.5-full-blind-review.md`) shows a real
tusked boar carrying the same moss-and-stone material language as Mudsnout —
exactly the "must read as Mudsnout grown up" brief below. `species.json`
already has it at height 2.15 against Mudsnout's 1.55, matching D17/D19's
numbers. What that review did NOT do: run `smoke_art` or check the rig/clip
wiring, which is what this item's own `tests:` field names. Next firing on
this item: run `smoke_art`, confirm the model is properly rigged and
animated (not just present), and if it passes, close this as done instead
of doing the generation work described below — do not silently invent a
replacement model over a real one already installed.

**Constraint change, spec §20 / D23: the "fresh generation from the sheet"
fallback below is now illegal.** No new creature Meshy generations for the
Meadows, at all. The remaining paths are (1) verify the installed model, which
R0.8.5's review suggests will pass, or (2) graft off Mudsnout's finished model,
which costs no credits either way. If both fail this becomes a `BLOCKED.md`
question for the owner — **not** a credit spend. The `🔒` marker above is
therefore misleading and should go when this item is next touched.

Original brief, kept for whoever verifies: the last stand-in was
`ollie-the-songbird.glb`. Since D20 it never spawns wild, so the only place
it will ever be seen is the evolution ceremony: the single most emotionally
loaded reveal a creature model gets. `CLAUDE.md`'s prototyping rule applies
with full force — the ceremony may not be judged with a songbird wearing a
boar's name. If verification finds it's NOT actually done: needs its own
call first, fresh generation from the sheet, or a graft off Mudsnout's
finished model (try the graft first, it costs no credits). Height 2.15 per
D19; strictly larger than Mudsnout per D17.

### R4.6 — Evolution mechanic and ceremony
`model: opus` · `tests: test_evolution_links, smoke_evolution` (new)
Mudsnout → Tuskroot gets a rope pulled at last. D20 fixed the intent: the
first evolution the owner sees will be a creature they caught as a piglet and
have carried since — build the ceremony knowing that. Honour D17 (the evolved
form is always larger — at D19 scale that is 1.55 → 2.15). Blocked on R4.5:
no ceremony with the stand-in.

**Spec §4 (D23) fixes the shape.** Mudsnout → Tuskroot is **the** Meadows
evolution line and no other normal species evolves — it exists to teach the
limited evolution system. Recommended: a level requirement (~15), a bond
requirement, and one Heartstone-type item from the Burrow Warrens' optional
deep branch (`SD17`). All three numbers and the item name are tunable per
`CLAUDE.md`; do not let a working name become a permanent mechanic.

### R4.7 — Bond and best creature · `model: sonnet` · `tests: test_bond` (new) · §12
### R4.8 — Fainting and home recovery · `model: sonnet` · `tests: test_fainting` (new) · M6

### R4.9 — Orb economy and tiers · `model: sonnet` · `tests: test_catch_math` · §15
Spec §3 Band 2: the improved orb tier is the **first** thing Rootstone
(`SD18`) buys. Build the tier ladder here; `SD18` supplies the material.
Note: the old "rework orb aiming" item that sat beside this was **absorbed by
the overhaul** — trajectory preview sharing `_release()`'s math, wired
sensitivity, fine-aim exponent, piecewise snap assist, cancel during windup.
Whether it now *feels* satisfying (§33 criterion 3) is R0.11's and R4.12's
question, not a build task.

### R4.10 — The release ceremony · `model: fable` · `tests: test_party, smoke_release` (new)
`party.add()` refuses a sixth creature and there is no ritual. The slice
warns it must not be "a generic delete dialog" — it is the emotional payload
of the five-creature rule, and since D18 the five-cap has a physical body in
the world: the belt Grandpa gave you has five holders.

**Spec §5 states the precondition, and it is not work on this item.** The
ceremony only lands if the Meadows has already produced more creatures worth
keeping than five slots — a Ground tank, a Water counter, an Air attacker, a
rideable Meadowhart, a rare-trait catch, the Mudsnout line, a favourite first
catch. That is a content requirement on Phase 8's bands, not on R4.10, and the
first biome must not be allowed to dodge the tension.

### R4.11 — Combat animation bug · `model: sonnet` · `tests: smoke_combat`
Owner-reported: creatures "static posed and sliding around". Ruled out by
measurement — clips exist, drive real bone motion, the animator is ticked
every physics frame with real velocity, loops are set at runtime. Best
remaining lead: Terrapup's idle moves bones by 0.088 against 1.53 for walk,
and a creature in combat is in idle almost always. **Next step is a recorded
fight logging the clip playing against the body's speed — not more
reasoning.** Re-check against the owner's R0.11 impressions first; the feel
pass (auto-face, lunge timing) may have changed the report.

### R4.12 ▶ Play gate — is repeated combat enjoyable, not merely functional? §33 criterion 2.

---

## Phase 5 — the living world

**R5.1 (day/night cycle) relocated to Phase -0.5** — owner directive,
2026-08-10: visual-pass work runs before Phase 1 onward.

### R5.2 — Rain, fog and cloud variants · `model: sonnet` · `tests: none`

### R5.3 — Spawn conditions · `model: sonnet` · `tests: test_spawns`
At least one nocturnal (Duskhush) and one weather-gated, per M10. Extend
`spawns.json`'s schema per D20 — this is the task that decision deliberately
deferred the fields for. Tests keep addressing species through the `roles`
block, never ids.

**Spec §13 supplies the area table**, which is what makes deeper regions change
the team you can build: lower fields Bramblebun / Mudsnout / Pipwing; grove
Trailpup / Duskhush at night / Burrowback; quarry and warrens Burrowback /
Mudsnout / strong Ground spawns; river Paddlenewt / Mosshell / Brooktail /
Reedwing; upper ridge Galecrest / Meadowhart / stronger Trailpup. Duskhush is
already the nocturnal example above. No random battle screens, ever (§13).

---

## Phase 6 — riding

**R6.1 and R6.2 are worked inside Phase 8's section 8d** — spec §3 Band 4 (D23)
makes riding a Band 3 / early Band 4 unlock gated on a Riding Saddle whose
components cost Rootstone and Ironwood, which is a progression step rather than
a free-standing milestone. Their briefs are kept here; the ordering is there.
R6.3's play gate stays where it is.

### R6.1 — Riding · `model: opus` · `tests: smoke_riding` (new) · M12
Mount/dismount, generic saddle, riding stamina, a clear advantage over
running, and no species-specific saddle clutter.

### R6.2 — Meadowhart as the rideable creature; craftable generic saddle
`model: sonnet` · `tests: test_build_catalogue`
Spec §3 Band 4 confirms Meadowhart as the rideable Meadows creature and prices
the saddle in Rootstone/Ironwood components (`SD18`, `SF31`). Riding should
dramatically improve *revisiting* known areas — that is the value it is being
sold on, not raw speed.

### R6.3 ▶ Play gate — does riding make exploring better?

---

## Phase 7 — the village lives, the meadow reads

**R7.1 (wayfinding polish) and R7.2 (villagers and interior polish)
relocated to Phase -0.5** — owner directive, 2026-08-10: visual-pass work
runs before Phase 1 onward.

### R7.3 — Grow the authored space toward the 4–8 hour arc · `model: opus` · `tests: smoke_traversal` · M7, §30
The village and paths were the seed; §30 is explicit — dense rather than
empty, and do not pick a kilometre count before movement is fun (R0.11 and
R6.3 answer that).

**This is now the chapter's capacity item, and the single largest unpriced
piece of D23.** `terrain_playground.json`'s own first line says it is *a test
area, not the Meadows*, and 512 m on a side cannot hold spec §3's five bands, a
quarry, a dungeon, a major river, a mini-stronghold, an upper region and seven
perimeter spokes. Growing it costs a terrain rebake, more Terrain3D regions and
a real performance question on the Ally — none of which is budgeted anywhere.
R7.3 owns the *space and the bake*; the individual areas belong to `SD16`,
`SD17`, `SE21`, `SE23` and `SF31`. §30's rule still governs the number: prove
movement and riding are fun first, then size it.

### R7.4 — Map and minimap · `model: sonnet` · `tests: smoke_menu` · §23
The `map` action is bound, labelled and rebindable, and **read by nobody**.
Spec §16 adds the rule: the map reveals explored areas and landmarks and never
reveals everything automatically. The tracked-objective line and the two-list
quest log are `SB11`, not this item — R7.4 owns the map itself.

**Promoted, 2026-08-11 — see Phase -0.85 for why.** This item's text stays
here; Phase -0.85 only points at it. The minimap is unblocked and can be
picked up from either location.

### R7.5 — Food buffs · `model: sonnet` · `tests: test_food` (new)
Buffs only. No starvation meter, ever.

### R7.6 — Berry plot and simple fishing · `model: sonnet` · `tests: test_farming` (new)
Deliberately shallow — §32 excludes deep farming.

### R7.7 — Player HP and armour slot architecture · `model: sonnet` · `tests: test_player_hp` (new)

---

## Phase 8 — the Meadows chapter (spec Phases C–G)

This was five items called "Team Tether and the culmination". `D23` turns it
into the chapter: five bands, two material tiers, physical gates, roughly
12–17 trainer battles, a dungeon, a mini-stronghold, a rescue, and a world
event. The `S<letter><number>` ids trace straight back to a numbered step in
`docs/MEADOWS_PROGRESSION_SPEC.md` §38, so a branch name carries its own
provenance.

**Why the whole chapter sits this late:** it consumes levels and XP (R4.1),
moves (R4.3), riding (R6.1) and trainer combat (R8.1). That is build order, not
play order. The honest cost is that the owner will not play a Band 1 trainer
battle for a long time — if that is the wrong trade, the cheap thing to hoist
is `R8.1` + `SC12` + `SC13` once R4.1/R4.3 exist. **That is an owner call, not
a firing's.**

### 8a — Lower Meadows (spec Phase C)

### R8.1 — World trainer encounter and team combat · `model: sonnet` · `tests: smoke_trainer_battle` (new)
Trainer-owned creatures **cannot** be caught. Spec §12 sizes what this has to
carry: 12–17 battles across the chapter, spread over meaningful locations
rather than one long trainer tunnel. It is the substrate for everything in 8a
through 8e, not a single encounter.

### SC12 — Mira, Oskar and Tam become the three Band 1 trainers
`model: fable` · `tests: test_dialogue_runner`
Spec §3 Band 1 and §35. **These three already exist** —
`data/config/village_npcs.json` places Mira, Oskar and Tam around the well with
greetings in `data/dialogue/village.json`, and the spec names the same three
("possible existing village NPCs can fill these roles if their existing
characterization fits"). Do not add three more people to the square. Mira
becomes the Meadow Keeper, Oskar the Bridgehand who holds the South Bridge
mechanism (he is already `villager_keeper`), Tam the Field Scout. Repalette
through `SB7`, extend their conversations, give each a battle offer. Done when:
all three are challengeable and none of them is a newly-placed body.

### SC13 — The three Band 1 trainer battles, each with a distinct lesson
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §3 Band 1, §12. Mira is the introduction, Oskar is the gate, Tam teaches
switching and type awareness. Uses R8.1's system, `SB9`'s defeated flags and
`SC15`'s rewards. Recommended natural team level by the time the bridge opens
is roughly 5–8 — **guidance for tuning, never a check the game performs**
(§3, §19). Done when: each can be beaten once, sets its flag, and cannot be
re-fought into an XP faucet.

### SC14 — The South Bridge, and the key that opens it
`model: sonnet` · `tests: smoke_traversal`
Spec §3 Gate 1. The deeper Meadows is visible across an old bridge the player
can walk to at any level and cannot cross. Beating Oskar yields the South
Bridge Key (`SB10`); the bridge is a mechanism, not a message. Done when: the
crossing is visible from the village, blocked without the key, open with it,
and never explains itself with UI text.

### SC15 — Trainer battles pay out
`model: sonnet` · `tests: test_progression_state`
Spec §17 P1 step 9. A defeated trainer grants XP plus one authored reward — an
item, a TM, a recipe or a key — recorded against `SB9`'s flag so it cannot be
farmed. Done when: beating a trainer twice pays once.

### 8b — Rootstone (spec Phase D)

### SD16 — The Old Quarry
`model: sonnet` · `tests: smoke_traversal`
Spec §3 Band 2, §32. Rootstone deposits, old foundations, and the first
physical evidence Team Tether is routing something beneath the region —
conduits, excavation, energy-routing hardware, material moving toward the
stronghold. Evidence, not an explanation: §32's reveal ladder is explicit that
nobody here knows about the legendary. Done when: the quarry is reachable past
the South Bridge and yields Rootstone.

### SD17 — Burrow Warrens, the required dungeon
`model: fable` · `tests: smoke_traversal, smoke_combat`
Spec §3 Band 2. A compact cave: aggressive Ground creatures, Rootstone
deposits, chamber navigation, a guardian fight, one rare side branch. **The
guardian is a strong normal species — the spec says outright not to invent
another legendary**, and §20 forbids the model anyway. The optional deep branch
is where the Mudsnout evolution item lives (R4.6). Done when: it can be
entered, cleared, and cleared only once for its story reward.

### SD18 — Rootstone, the first progression tier material
`model: sonnet` · `tests: test_recipes`
Spec §10. Two tier materials in the entire biome — Rootstone then Ironwood — on
top of wood, stone, fiber and berries. Rootstone **upgrades what already
exists** rather than opening ten new systems: better orb tier (R4.9), workbench
upgrade (R2.7), better gathering tool (R2.1), the saddle component (R6.2), a TM
component, a modest camp/storage improvement. §32's ban on a large crafting
tree is the boundary. Done when: every recipe that consumes Rootstone improves
something the player already owns.

### 8c — the river and the relay (spec Phase E)

### SE21 — A real river divides the deeper Meadows
`model: fable` · `tests: smoke_traversal`
Spec §3 Band 3. Also closes a question the visual pass left open:
`R7.1-remainder-2`'s second bullet found "no middle-distance layering anywhere
in the set (no tree lines, ridgelines, or water)" and asked outright whether a
water feature would do more for depth-reading than more vegetation tuning. This
is that feature, and it is load-bearing for the story too. Done when: the river
reads as a landmark from the ridge and cannot be crossed except at authored
points.

### SE22 — Old Mill Crossing, seized and then restored
`model: sonnet` · `tests: smoke_traversal`
Spec §3 Band 3. Team Tether has disabled the crossing and taken the person who
knows the mechanism. Freeing them (`SE27`) yields the Mill Bridge Gear
(`SB10`) and the crossing opens for good. Done when: the same bridge is
impassable before the rescue and passable after, with no menu in between.

### SE23 — The Tether Relay Station
`model: fable` · `tests: smoke_traversal`
Spec §3 Band 3. The first mini-stronghold: a natural site partly
industrialised, a compact traversal and environment challenge, and the moment
Team Tether stops being something Grandpa described and becomes a threat the
player has personally confronted. R8.2's visual-language brief is used here
first, at small scale. Done when: it can be entered, fought through, and its
local tether/control equipment disabled.

**The "local tether/control equipment" now has a board** —
`docs/art/reference/14_Relay_Apparatus.png`, owner-supplied 2026-08-11 and
labelled Band 3, so it is drawn for exactly this item. It is one of the three
hero objects D24 reserves Meshy for, and it is `lane: art`. Its artist note is
the build spec rather than flavour: *modular construction, core and rings
serviceable, conductor arms and manifolds replaceable*, with five labelled
subassemblies (tether core, conductor ring, control console, output manifolds,
grounding base). The console is the thing the player disables, and the board
details it down to individual routing levers.

### SE25 — Relay trainers and the relay captain
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §3 Band 3, §12: two or three Team Tether trainers and a relay captain, all
on `SB8`'s rank palettes — the captain visibly outranking the trainers and
visibly below the Warden. Done when: the captain's defeat sets the flag `SE27`
waits on.

### SE27 — Free the captive
`model: sonnet` · `tests: test_dialogue_runner`
Spec §3 Band 3, §35. The captive ranger/researcher is built on the civilian or
main-character base — **not a new model** (§20/§21 apply to the whole cast).
Rescue scene, the Gear, and the first testimony that the region's isolation is
made rather than natural. They return to the settlement afterward (`SG46`,
§14). Done when: rescued, the NPC exists in the village and their dialogue has
changed.

### SE30 — The reveal ladder, laid in
`model: fable` · `tests: test_dialogue_runner`
Spec §32. Villagers know travel is controlled and trade restricted, and no
more. The quarry shows conduits. The relay shows energy routing and a captured
investigator. The captive knows the separation is artificial but **not** that a
legendary is the source. Grandpa's opening must not spoil any of it — §32 and
§1's "do not dump the entire plot in one speech" are the same instruction.
Done when: no line of dialogue before the stronghold names the legendary as the
power source.

### 8d — Upper Meadows (spec Phase F)

**R6.1 and R6.2 (riding, Meadowhart, the generic saddle) are worked here** —
spec §3 makes riding a Band 3 / early Band 4 unlock priced in Rootstone and
Ironwood. Their briefs stay in Phase 6; the ordering is this.

### SF31 — Ironwood, the second preparation tier
`model: sonnet` · `tests: test_recipes`
Spec §3 Band 4, §10. Supports stronger crafting, riding equipment, better
utility and final-stronghold preparation. It does not need to literally be
iron. Keep the economy small and readable. Done when: nothing needed for the
stronghold requires a third new material.

### SF33 — Standing at a Rift and seeing the next region
`model: fable` · `tests: none`
Spec §29, §34 Act V. `SA4` built the seven spokes; this makes the Upper Meadows
ones legible as **severed roads**: major conduits and pylons, roadbed
continuing on the far side of an unnatural seam, land visible across it, old
trade infrastructure abandoned mid-use. **The far side is a view, never a
place** — `CLAUDE.md`'s Biome 2 rule stands, and D23 says so explicitly.
Visual-affecting: blind pass required. Done when: a blind critic looking at the
seam says the two sides used to be joined.

**The pylons have a board** — `docs/art/reference/13_Tether_Energy_Pylon.png`,
owner-supplied 2026-08-11, and it is the cheapest of the three hero objects to
build: a **2K–3K triangle** target and a five-part modular kit (base + core
module + supports ×4 + top frame + tether crystal) that is meant to be
repeated along a line. That repetition is what sells "severed road" — one
pylon is a prop, a receding row of them is infrastructure. `lane: art`.

### SF34 — Three regional captains, three Sigils
`model: fable` · `tests: smoke_trainer_battle`
Spec §3 Band 4. Field Captain (Ground team, Field Sigil), Ridge Captain (Air,
Ridge Sigil), Riverwatch Captain (Water/balanced, River Sigil), all on `SB8`'s
captain palette with one regional accent each. The three physical Sigils open
the Hall approach through `SB10`. This is what gives trainer battles direct
progression meaning. Natural team expectation entering this band is roughly
10–16 — **tunable, and never player-scaled** (§3). Done when: the approach is
sealed at 2/3 and open at 3/3, and the count is visible on `SB11`'s tracker.

### 8e — the stronghold and the first reconnection (spec Phase G)

**The Tether Chamber's centrepiece has a board.**
`docs/art/reference/15_Legendary_Tether_Machine.png`, owner-supplied
2026-08-11, headed WARDEN STRONGHOLD — it is drawn for this section. ~15 m
against its own 0–20 m scale bar, so it is architecture rather than a prop and
the chamber has to be built around it. It is `lane: art` and one of the three
hero objects D24 reserves Meshy for.

**Read this before generating it.** The board shows a legendary bound inside
the containment ring, because that is what the machine does to legendaries —
it is the D23 macro-story drawn. **The board licenses the machine, not its
occupant.** `D23` §20 forbids new creature meshes at any credit balance, so
the bound creature is an existing roster asset or VFX. Generating the whole
board as one asset breaks a hard rule while appearing to follow one.

### R8.2 — Authored stronghold route · `model: sonnet` · `tests: smoke_traversal`
Visual language: a sacred natural site industrialised by Tether. R7.1's ridge
silhouette is the promise this pays off. Spec §8 gives the interior: Outer
Works → Courtyard / Hall Approach → Tether Chamber Approach → Warden Arena →
Legendary Chamber, target first clear 30–60 minutes. **Not a giant puzzle
dungeon** — §8 rules that out unless separately decided. Note the same
industrialised-sacred-site language is used twice: first at `SE23`, then here at
full scale.

### SG38 — The stronghold trainer gauntlet
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §8, §12: a patrol trainer at the Outer Works, a courtyard fight, an elite
before the Tether Chamber, and a recovery opportunity before the Warden. Two to
four battles across the five named spaces. Done when: a prepared team clears it
inside an hour and an unprepared one does not.

### R8.3 — The Warden boss fight · `model: fable` · `tests: smoke_boss` (new) · M14
His face is still painted, not modelled — needs a real sheet before this is
judged (HANDOFF §6). Note §20 covers *creatures*; a Warden face pass is still
legal under §22's budget. Spec §33 gives the character: he sincerely believes
separation prevents chaos and that ordinary people do not understand the risks.
Not a moustache-twirler. His line is closer to "You don't understand what these
barriers are holding apart" than "You cannot stop me."

### SG40 — The reveal: the legendary is the power source
`model: fable` · `tests: test_dialogue_runner`
Spec §28, §32, §33. Inside the stronghold and nowhere earlier — `SE30` holds
the rest of the ladder. The Warden warns rather than gloats, and genuinely
believes freeing it is reckless. Done when: the reveal happens in the
stronghold and the player makes the choice knowing what it costs.

### R8.4 — Free the legendary; it offers to join; triggers the release ceremony if full · `model: fable` · `tests: smoke_boss`
Spec §28's order, which is not optional: reach the chamber → the legendary is
freed → it **voluntarily** offers to join → the five-creature decision if the
roster is full (R4.10) → the tether machinery fails → `SG44`'s world event.

### SG44 — The first Tether Rift collapses and the world gets bigger
`model: fable` · `tests: smoke_boss`
Spec §27, §28, §30. The machinery fails, the exterior event runs, and one
severed spoke visibly reconnects — a distant landmass moving closer, a ravine
contracting, roots bridging a gap, a storm wall dissipating. **The carve-out is
not negotiable: this is a distant, non-enterable view.** `CLAUDE.md` forbids
Biome 2 work until the Meadows exit gate and D23 holds that rule over this
step; the spec's own §19 non-goals ("all seven future biomes") agree. No second
biome's terrain, spawns or species — the reconnected road still ends at a
believable barrier. If that reads as an unsatisfying payoff, it is a
`BLOCKED.md` question for the owner, not a licence. Done when: standing where
`SF33` put the seam, before and after the Warden, gives two visibly different
horizons — and the player still cannot walk into the next region.

### SG46 — The Meadows answers
`model: fable` · `tests: test_progression_state`
Spec §9. Barriers deactivate, patrol density drops, the rescued NPC is back in
the settlement, villagers acknowledge the victory, stronghold effects change,
the legendary is no longer tethered, and at least one outward spoke gains new
dialogue. Done when: no part of the region is visually or conversationally
identical to how it was before the Warden.

### R8.5 — The legendary's superior ride ability · `model: sonnet` · `tests: smoke_riding`
The tier above Meadowhart's (R6.2), not a parallel system.

### R8.6 — The larger mystery and future-biome hook · `model: fable` · `tests: test_dialogue_runner`
No longer open-ended: the mystery is spec §23–§31, and `SA4`'s seven spokes are
its physical hook. `GAME_DESIGN.md` §3's "the exact endgame motive remains
intentionally open" is false as of D23 and is amended there.

---

## Phase 8.5 — pacing and the chapter's own gate (spec Phase H)

### SH47 — Tune the chapter to 4–7 hours
`model: sonnet` · `tests: none`
Spec §17 P7, §38 Phase H. XP curve, trainer levels, material costs, travel
time, spawn density, and the specific instruction to **remove dead walking**.
Distinct from R9.1 (input feel and combat cadence) and R9.3 (performance on
hardware): this is arc pacing, and it can only be judged once 8a–8e exist.
§11's test of a good grind is the standard — "I know a harder challenge is
ahead, so I am deliberately improving my five", never walking in circles
killing identical weak enemies to inflate a number. Done when: a full run is
timed end to end and lands inside 4–7 hours.

### SH53 ▶ Play gate — the P0 fixes are actually gone on real hardware
`model: haiku`
Spec §38 step 53, §18. Ten minutes of a fresh Windows launch with mouse and
keyboard, never once having to think about cursor capture — through a menu
open and close, the name-entry screen, and an Alt-Tab. Then: the door cannot be
crossed before Grandpa, and no bearing walked from spawn falls off the world.
**This is the on-device confirmation `RB1`, `RB2` and `RB4` all still owe** —
each is closed on diagnosis and a real fix, none on the owner's own hands.

### SH54 — Audit: nothing in the chapter assumed new creature credits
`model: haiku` · `tests: none`
Spec §38 step 54, §20. Walk every item shipped for this chapter and confirm
none of them installed, requested or planned a new creature mesh. Cheap, and
worth doing once at the end, because the constraint is a budget the owner holds
and a single quiet violation spends it.

---

## Phase 9 — polish gate (M15)

### R9.1 — Input feel, combat cadence, catch feel, camera · `model: sonnet` ▶
### R9.2 — Controller UI readability on the Ally · `model: sonnet` ▶
### R9.3 — Performance on target hardware · `model: sonnet` ▶

**R9.4 (visual cohesion pass) relocated to Phase -0.5** — owner directive,
2026-08-10: it now serves as that phase's own checkpoint, run before
Phase 1 onward rather than at the end.

### R9.5 ▶ **The exit gate.** All twelve of `GAME_DESIGN.md` §33. Only the owner can call it.

---

## Found along the way — small, unscheduled

- `docs/ASSET_LEDGER.md` claims "everything currently in the build is CC0
  1.0". False (Meshy creatures, Plumberry pack). **Blocked on the owner** for
  the correct wording. The website's parallel stale claim was fixed in the
  overhaul; the ledger's was not.
- ~~Backpack has no use/consume/equip/drop/split verb; the only action is
  moving an item.~~ **Corrected 2026-08-11: this was stale.** A use verb
  already exists (`tab_backpack.gd::_read_use()`) and already heals from
  `heal`-tagged items — `potion_small` (`heal: 35`) is usable today. The real
  remaining gaps are narrower: `berries` carries no `heal` value (`R7.5`
  owns giving it one), the verb has no equip/drop/split siblings (still
  genuinely missing, small, `model: sonnet` if anyone wants it), and using
  any of it requires the full backpack menu with no quick path (`HD2`,
  Phase -0.85, fixes that).
- **`menu.json`'s stray `test_menu_config.gd` references and phantom
  `hotbar_columns` comment fixed — see `DONE.md`.**
- ~~Opening the menu mid-fight is silently refused with no on-screen
  explanation.~~ **Fixed 2026-08-12 — see `DONE.md` (`menu-mid-fight-refusal-
  hint`).**
- **`smoke_traversal` / `smoke_combat` flakes — PROMOTED to `LP1` in
  Phase -0.95.** Batched pushes make a random red cost up to four finished
  items instead of one, so this stopped being a small item.
- **Spec §6 — 6–10 optional activities, not forty shallow quests.** Lost Pal,
  Broken Cart, Night Watch, The Old Champion, Deep Warren, River Nest, Team
  Tether patrols, Meadowhart Herd. Each wants a home in Phase 8's bands rather
  than a list of its own; promote individually when the band it belongs to is
  built. `model: sonnet`
- **Spec §14 — home must stay relevant.** Grandpa's dialogue evolves per band,
  creature beds and recovery, storage and crafting, villagers updating what
  they know, the rescued NPC returning, story check-ins. The farmhouse should
  not become a room you never re-enter after the first twenty minutes.
  `model: sonnet`
- **`tools/survey.gd` and `tools/preview_creatures.gd`, both found broken by
  R0.8.5, relocated to Phase -0.5 as VP1/VP2** — owner directive,
  2026-08-10: visual-pass work runs before Phase 1 onward, and both tools
  are needed to verify that phase's own work.
