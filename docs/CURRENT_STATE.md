# Current state — evidence-backed, 2026-09-07

**Slimmed 2026-09-07.** This file is the live status. Every dated checkpoint section
it used to carry is under `archive/docs/current-state-history/` (list at the end).
Findings go in §3, ranked by player impact; process traps in §4.

## 0. Where the project is (2026-09-09, playable build in progress)

**Takeover runtime checkpoint — 2026-09-10:** the first corrected earned road
run completed 10 training wins, paid camp/all-five rests and the tournament,
then produced 216 camera/travel/route-aligned Meadows samples over 3,716 m of
observed travel. It reached and challenged the real South Bridge guardian but
lost that fight, so no bridge-prefix or campaign pass is claimed. The 96
below-two samples resolve into 27 intervals: the sustained misses are primarily
real-frustum or Terrain3D line-of-sight failures, not evidence for a blanket
spawn rewrite; a short 225–236 m interval had no 15 px candidate after the
earned route had already depleted nearby wild stock.

The same trace found active night Duskhush bodies hundreds of kilometres below
the world. STREAM-D previously regrounded only on the inactive-to-active edge;
a collision tile arriving after that edge let a nearby active body fall forever.
Nearby active clusters now receive the same guarded reground check once per
second. The focused delayed-fall regression, real Terrain3D night-ecology smoke
(12/12 present and grounded), and corrected ROAD observer tests are green. No
spawn was added or moved. See
[`TAKEOVER-ROAD-RUNTIME02.md`](../ralph/reports/FOUR-BIOME-CONTINUATION-0910/TAKEOVER-ROAD-RUNTIME02.md).

**Takeover checkpoint — 2026-09-10:** work continues from `main` at
`5269a6d1c` on `codex/four-biome-continuation-0910`. The Meadows continuous
observer now preserves camera-visible telemetry while separately measuring the
actual approximately 10 m travel heading and nearest route tangent; only aligned
samples within 5 m of an authored route can count as ROAD failures. The canonical
driver uses ordinary look actions to align the real camera after the earned
tournament. Focused validation is green (31 tests / 231 assertions plus both
changed smoke parse checks). The unsharded full unit run reached 3,286 tests /
3,847,277 assertions with two isolated baseline Gate F harness failures: stale
S04/S05 row thresholds and an unavailable Bash child process on Windows. The
aligned-camera record and follow-up are summarized above. Copied-save quarry diagnostics
proved exact contact with a `Foundation_0` wall; two navigation guesses failed
their replay gate and were withdrawn. Departure errors were isolated to the later
host crossing and require a real receiver-generation handoff, not an unused pin
assertion. See
[`TAKEOVER-ROAD-MEASUREMENT01.md`](../ralph/reports/FOUR-BIOME-CONTINUATION-0910/TAKEOVER-ROAD-MEASUREMENT01.md).

**Owner-requested closing handoff — 2026-09-10:** read
[`HANDOFF_BROAD_VISUALS_2026-09-10.md`](HANDOFF_BROAD_VISUALS_2026-09-10.md) for
retained work, remaining goals, wasted effort, lessons and the next-session order.
The final game revision is `dbb229436b473cf5d53eb585331893ab54e3b4fa`.
Its exact Windows import/export/native packaged-world check passed; use
`.artifacts/broad-visual-0910/export-runs/windows-dbb-final/output/Tetherbound.exe`
with its adjacent PCK and libraries. Full runtime CI `34473442211` / 4670 passed
26 executed jobs (three skips), 3,206 tests / 490,813 assertions; log caveats remain
explicit in `ralph/reports/BROAD-VISUAL-0910/CI-DBB.md`.

The final fresh attempt ran 11:56:39–12:21:55 UTC with no engine errors and zero
drift across 2,052 selected source/configuration files. It earned five creatures,
training, paid camp/all-five rest, all tournament rounds, the bridge guardian/key
and physical crossing, then mined four quarry nodes. It failed the next approach
to `(393,-0.4977,1802)`, stopping at `(395.1783,-0.4992,1804.407)`. The Warrens
prefix and full campaign remain failed; the earlier HUD-provider error did not
recur. The retained checkpoint is before quarry mining, not at the failure pose.
See `CONTINUOUS-FRESH-WARRENS01.md` in the same report directory. The owner chose
this logical stopping point for handoff/main landing and pause; no new fix cycle
was started. Main's documentation cleanup PR118 is integrated; final handoff and
Circuit CI wiring land through PR117 after final-head checks, without changing
the DBB game code. No commercial visual, full four-biome fun/pacing, or Ally pass
is claimed.

**Previous validation — 2026-09-10 11:50 UTC:** the exact `8aad9c373` Windows
release executable passed native packaged-world verification, including loaded
Terrain3D, valid spawn ground and 383,004 scattered props. Import/export and
368 required packed paths passed; the console-wrapper assumption was corrected
without re-exporting. See `ralph/reports/BROAD-VISUAL-0910/WINDOWS-8AAD.md`.
Final independent review then identified and closed a Circuit client-ordering
bug: prior victories now replay after committed acceptance and on accepted-save
recovery. Its delayed-writer smoke passed cleanly, as did 13 related tests /
144 assertions. See `CIRCUIT-PENDING-ACCEPTANCE01.md` in the same report directory.
That fix postdates the verified package and requires an updated package and CI.
The `8aad9c373` CI run was superseded before completion by `5431a2fe3`; neither
an unfinished nor cancelled run is treated as a full green result.

**Previous validation — 2026-09-10 11:38 UTC:** full CI at `ba11f58d1` passed
all 26 executed jobs (three conditional skips), with 3,206 tests / 490,813
assertions and no actual script-error emissions in the complete logs. Known
negative-test, headless-renderer and shutdown diagnostics remain documented in
`ralph/reports/BROAD-VISUAL-0910/CI-BA11.md`. The two focused HUD-provider and
Bramblebun texture-binding smokes are now wired into existing CI shards, with
one attempt each. The later `8aad9c373` Windows import and release export both
passed, producing an executable and PCK; packaged-runtime verification remains
pending because the preset did not emit the console wrapper expected by the
packaging script. That script assumption is being repaired before any build-ready
claim. Runtime packaging remains pinned to `8aad9c373`; subsequent CI wiring and
report edits do not alter that package's game content.

**Previous checkpoint — 2026-09-10 11:25 UTC:** Bramblebun's redesigned model now
uses its matching texture source. Native ordinary/alpha/shiny resource-identity
checks, full art smoke, matched isolated captures and visible production-world
day/night captures support retention. Fresh independent judges prefer it in
both settings; the commercial visual bar still fails. The shared colour-rule
feathering experiment is held after Cloudfang baseline preference and Skyrill
tie. Source-texture alternatives for Skyrill/Torrentoad also remain held; their
faces need deeper art work. Windows packaging is next, followed by a longer
fresh progression attempt if the remaining run window permits.

**Previous checkpoint — 2026-09-10 10:59 UTC:** a fresh earned run reached the far
bank of South Bridge after five captures, training, paid camp/rest, the village
tournament and the real two-opponent guardian fight (29 landed hits, earned
key spent). This is a passed gameplay prefix, not clean campaign acceptance:
21 stale HUD-provider errors failed the runtime guard, and one of 1,631 source
snapshot files changed on disk after the running helper was preloaded. The
HUD now validates the cached provider before casting it; the actual provider
lifecycle and existing legend smokes pass cleanly. Full replacement CI is pending.
The depleted-stock pilot policy has 15 tests / 103 assertions, but this fresh
seed never exercised depleted stock; actual low-stock continuation remains open.
Native creature inspection confirmed Bramblebun's redesigned mesh was using
the old mesh's incompatible colour atlas. A matching-source candidate restores
its face and wins a fresh isolated blind comparison; world validation is in
progress. It is not a broad roster or commercial visual pass.

**Previous checkpoint — 2026-09-10 10:03 UTC:** shared grass grounding and curved
blades remain retained; an actual 19.941 m South Bridge walk confirms visible
blades and advancing wind across eleven native frames. This is not an Ally or
frame-pacing pass. Cloudreach's live multiplayer cover and minimap allocation
fix are covered by full CI at `d6cb7f0cb`: 26 executed jobs pass, three conditional
jobs skip, with 3,203 tests / 490,808 assertions. Departure Sync diagnostics remain.
The authoritative HUD recall deduplication is retained at `f64d1ece6` after
native controller checks and a fresh preference. Cloud grass arc transfer and
vitals outline changes were withdrawn after baseline preferences / a tie.
The third fresh continuous prefix failed on exhausted carried potions after
five earned creatures and ten real training wins. Its source snapshot had no
drift and its engine error list was empty. The copied guardian crossing remains
bounded evidence; fresh bridge and full campaign acceptance are still open.
A depleted-stock training-pilot policy is under validation, not yet proven.

**Owner-authorized broad visual run, 2026-09-10 UTC:** the owner resumed work for
twelve hours, prioritizing visible shared-system improvements over the previous
allocation. PR #115 and the domain acceptance directive are now on main
`5471c4deb`. Current branch: `codex/broad-visual-pass-0910`, PR #117. Water terrain
material refinement is committed at `ce6f5ccc8`; its bounded opening path and
26 executed CI jobs passed (three jobs intentionally skipped; log caveats in the
CI audit). Shared procedural grass and the Water profile are committed at
`325028e0b`, compact empty hotbar at `3a61c10b6`, and large-creature camera framing
plus the indigo Voltarach alpha at `306d3a67d`. Water's opening passed with grass
enabled; native camera entry/switch/aim/exit and headless Stronghold room limits
passed. Settlement pads, physical interiors and Fenn's doorway clearance are
committed at `4d1305cf1`: all nine production building approaches, entries,
floors and walls passed. This is a functional repair, not a claimed settlement
visual win; the extra timber lining was withdrawn after no visible progress.
Player-only night rim at `6794cb039` improves nighttime readability in two
independent location comparisons, with daylight equivalent. Creature platform
transfer is fixed at `176b17638`, and Stormheart's ordinary wildlife approach
clearance at `d4d69c762`. Cloudreach cover and the shared basal-leaf experiment
did not produce meaningful overall improvement and are withdrawn. Cloudreach
grass is deferred after four distinct no-progress mechanisms; the owner's grass
complaint remains open. Shared Meadows/Stormwood/Water grass height interpolation
and blade-local arc are retained after all three fresh blind location comparisons
preferred the combined result (14 candidate and 14 original-control frames, clean).
Grounding alone had mixed verdicts. Desktop Compatibility medians showed no
typical regression; noisy p95 hitches and Ally performance remain unproven.
Stormwood vegetation palette is retained at `44473241c`
after two location comparisons; shared thin-leaf lighting at `e986f6d42` has a
bounded Meadows canopy gain, with Water showing no preference. Stormheart's
material candidate was withdrawn after the baseline won its comparison;
full ramp ascent and three real-camera approach views passed separately.
The Cloudreach authored-ground-material binding candidate was also withdrawn:
Gate preferred the existing terrain, and the upper observatory tied.
Near-camera sapling obstruction is traced to actual CommonTree_5 leaf geometry
(nearest triangle 0.619 m from the eye, not proof of opaque intersection).
The shared near-camera fade was withdrawn after correct material binding and
matched captures produced no blind foliage preference. Its timing samples were
inconclusive; no further distance tuning is planned in this push.
CI at `adf8e4d97` ran 26 jobs: 25 passed, one failed the alpha texture's VRAM
import policy. That import is corrected at `fefd0f590`. CI at `176b17638` again
ran 26 jobs: 25 passed and one found four authored NPC/trainer Y coordinates
inconsistent with the new foundations. Their focused correction passes five
tests and 665 assertions. Replacement CI run `34439181372` completed against
pushed head `4d3a69b7f`: 25 jobs passed, one failed, three skipped. Unit shard 2
exposed two empty Deepwood road samples
after the cluster relocation. The revised Z position passes the full ROAD
oracle and physical seating, with terminal clearance preserved; complete
replacement CI remains required. The fresh opening-to-rest path passed once
in 742.83 seconds with five ready creatures and ordinary ThrowAim releases.
The older intermittent aim cancellation did not reproduce and remains open.
Water's explicit surface Fresnel bindings are retained at `340d7287c` after
Root Walk and genuine open-water comparisons preferred their integration;
the angular depth boundaries and pale grass remain open. The striped horizon
is now corrected separately at `8c1b0edcb`: Water disables the coplanar infinite
Terrain3D background and extends its visual sea beyond the camera far clip.
Matched day/night review prefers the fix; four factory tests, five native views
per pair and a clean 64.486 m physical opening swim support the bounded change.
Canonical Water rebake refreshed stale provenance with all 31 existing binary
files byte-identical. Earned Shellwatch/Deep Watch return-current reductions are
retained at `0dbbe5793`, with 8 unit tests / 52 assertions and a clean 47-check
production action/save/reload fixture. Neither proves earned realm transition.
Deepwood Circuit wiring is retained at `4e150c65a`: Rook accepts, any three
distinct authored trainers count, earlier wins remain useful, and returning
to Rook acknowledges completion. The real dialogue/trainer-result callback
smoke is clean, with scripted battle outcomes explicitly disclosed; this is
not a played Circuit or two-peer proof. Final combined checks passed 23 tests
and 678 assertions. Full replacement CI `34442439915` passed on `340d7287c`:
all 26 executed jobs passed, three known conditional jobs skipped, 3,198 unit
tests and 490,749 assertions passed. Raw-log caveats remain in `CI-340-AUDIT.md`.
The attempted fresh extension through tournament and bridge failed during
materials at 688.294 seconds after earning the team: its chosen tree lost the
interaction offer to a neighbour. Neither tournament nor bridge was reached.
Three copied-save helper revisions failed after one additional wood harvest.
Exact provider instrumentation then showed the apparently compatible nearby
`Chop` offers were stone, not wood. The unsuccessful compatibility/timing
changes are withdrawn. Truthful resource labels are retained at `f2dc2422b`;
the existing refused-stand route policy is applied in the Meadows material
segment at `b07971b71`. Copied-save physical gathering and paid campsite/one-bed
placement passed cleanly at 07:24 UTC. This is not fresh continuity: the original
full-prefix failure remains preserved, and a new opening-through-bridge run is
required.
The fresh `continuous-through-bridge-second` run now passes the actual Gate A
gathers, paid camp placement, five-creature rest sequence, and all three
tournament rounds, then reaches and admits the exact South Bridge guardian. It
still exits 1 on the generic assertion `Guardian did not yield the exact real
team victories, hits and durable defeat` at `tournament_won` after 1,207.545
seconds (`campaign_complete=false`, `requested_prefix_passed=false`). This is a
real passed prefix plus a bounded guardian failure; focused replay is pending and
no full continuity claim is made.
Shared grass-normal shading was also withdrawn (`7f1b48771`): a modest Water
daytime preference did not carry across locations; Meadows and Stormwood tied,
and Root Walk preferred the old night shading. Shared turf-albedo comparisons
are mixed (South Bridge improved, Glass Field tied, Grandpa's village preferred
the original), so that candidate is withdrawn. Cloudreach crown geology was
also withdrawn at `4b4809e0d` after all three location comparisons tied; its
corrected geometry and clean native captures did not produce a visible gain.
Replacement CI `34447522002` now passes on `c0a4d243b`: all 26 executed jobs,
3,202 unit tests / 490,800 assertions, three known conditionals skipped.
`CI-C0A-AUDIT.md` preserves all logs and caveats. The newer correct resource
prompt verbs at `f2dc2422b` pass their actual setup regression. Those changes are
now covered by replacement CI `34454848997` on `9fc53908f`: all 26 executed jobs
passed, three known conditionals skipped, 3,203 unit tests / 490,808 assertions.
`CI-9FC-AUDIT.md` preserves raw logs and diagnostic caveats. The newer shared
grass grounding/arc commit `8b04e32d9` requires new full CI.
See reports in
`ralph/reports/BROAD-VISUAL-0910/` for failures and exact evidence limits.
No four-biome or commercial visual acceptance is claimed. See
`docs/owner/OWNER_DIRECTIVE_2026-09-10_BROAD_VISUAL_IMPROVEMENT.md` and
`ralph/reports/BROAD-VISUAL-0910/checkpoints.md` for the active scope and evidence.

**Previous owner-requested exit and consolidation, 2026-09-10 UTC:** feature work was frozen.
Read `docs/HANDOFF_VISUALS_FIRST_2026-09-09_EXIT.md` before resuming. PR #115
consolidates the outstanding work; landing is pending corrected full CI. The first
run found two staff-related test assumptions and a genuine ROAD regression from
four Veilfall pair relocations. Those placements are withdrawn to the main
catalogue; the candidate is preserved in history. Gate crowding, rejected palettes,
buried houses, vigil presentation and remaining grass/finale work are still open.
Five Stormwood-transition multiplayer checks also failed. Two local repair
hypotheses failed and were withdrawn; the denser Stormwood scatter candidate is
held in history while the shipping tree restores main's generator/config/bake.
Grass-field binding and tree/shrine/alpha-clearance changes remain included.
The following visual checkpoints describe earlier candidates, not acceptance.

**Previous owner allocation (superseded above): visuals first, 30/30/30/10.** See
`docs/owner/OWNER_PLAYTEST_2026-09-09_VISUALS_FIRST.md`. Creature combat crowding,
missing facial readability and excessive colours are reopened. Stormwood and
Water terrain/vegetation and both finales fail the owner's visual bar. Allocate
30% to creatures, 30% Stormwood, 30% Water, and 10% other work (including biome
labels in teleport, loading feedback and saddle crafting). Fresh-route replay
work is paused for this priority. Existing visual experiments remain held.

**Visual checkpoint, 2026-09-09:** local commits `0cf8d8855` (Stormwood)
and `1e8c223e1` (Water) preserve the first production vegetation candidates.
Stormwood grass is bound to its actual terrain/camera and visible at Rodline Post
and Lantern Hollow; split-tree construction checks pass, but a useful finale
approach and independent judgment remain outstanding. Water vegetation appears
at Reedhaven, while Veilfall receives only seven shrubs and visibly fails: steep
bare terrain and overlapping creatures still dominate the approach. Authored
landforms and encounter spacing are next. These candidates are not on main and
do not establish a biome visual pass. See `STORMWOOD-FOREST-AND-STORMHEART-0909.md`
and `WATER-VEGETATION-FIRST-CAPTURE.md` in `ralph/reports/FOUR-BIOME-BUILD/`.
Teleport biome labels passed their focused test in local commit `d268e23c3`;
loading feedback and the owner's saddle availability report remain open.

**Owner follow-up on these captures:** pink spider and axolotl palettes rejected;
some houses are buried, legendary-piece shrines look poor, and grass gaps remain.
The owner recognizes improvement and directs continued work. Check actual house
floor/door seating and shrine presentation alongside the ongoing biome lanes;
preserve the earlier captures and rejected palettes as comparison evidence.

**Latest integration, 2026-09-09 22:45 UTC:** main is
`671e1b8bc5f52eeec527fa69e997faf226df9a4b`. PR111 reconnect-watchdog,
PR112 slope navigator and PR113 standing harvest height have landed with
independent review, complete first-attempt PR CI audits and exact tested-tree
verification. The Stone retained-copy check physically mined stock2 and gained
Stone4→6. Fresh continuity remains open: the next fresh run stopped at219.251s
in a later catch with an empty aim preview, before the rest lesson. A single
changed diagnostic run is tracing aim state/processing without weakening rules.

Main dc83's shared-fight CI failure is preserved and not credited as fixed.
Host-only action/verdict instrumentation is in independent review. Main20ef's
release is verified; newer main CI/release obligations remain pending.
Water Gull Rest's actual grid-substitution capture passed exact restoration
and indicates source-albedo character rather than anisotropic UV scale at this
one view. One generated grass candidate is held for rendering/seam checks and
blind judging. No new whole-biome visual pass or campaign gate is claimed.
See CI-PR112-f22a08105.md, CI-PR113-97f37d559.md, FRESH-REST-SLOPE-0909.md
and MAIN-dc83-SHARED-FIGHT-FAILURE.md in `ralph/reports/FOUR-BIOME-BUILD/`.
Earlier pending/paused status paragraphs below are historical.

**Latest validation, 2026-09-09 21:40 UTC:** the second-bed approach failure
has a tested navigator correction awaiting shipping. Its horizontal rays had
classified gentle Terrain3D slopes as walls, keeping a detour active. Supported
body-height paths now retain wall, crate, overhead-obstacle and cliff checks.
The native fixture passed; a copied-save reproduction from the original side
then reached within 1.132m of the 1.4m target and completed the real bed menu
assignment. This is retained-state evidence, not a fresh continuity pass.
The earlier fresh failure remains recorded. See
`NAVIGATOR-SLOPE-CLEARANCE-0909.md` in the four-biome reports.

PR109 evidence/probes and PR110 visual scorecard are on main. Release34405831259
published exact commit3192c268e5cbf073308a967bcfdab88dbd8b5f9f; the full logs,
rolling tag, ZIP digest and Pages deployment were verified. PR111's reconnect
watchdog correction is still awaiting its complete CI audit before landing.

**Earlier resume checkpoint, 2026-09-09 21:15 UTC:** PR109 evidence and standalone
probes landed at d67976bba0705276def96642b7c5a784c626e215 with matching source/CI/
landing tree and ancestry verified. Full source CI passed on its first attempt.
The preceding c3e main CI34401138071 has a failed reconnect smoke in multiplayer
shard4: peer heartbeat silence followed by cascading empty results. Investigation
is active; no retry has been requested and no data-loss conclusion is established.
Terrain main e231 CI passed all27 executed jobs with full logs reviewed. Release
c3e has verified ZIP/tag/Pages evidence; publication is not campaign acceptance.

The fresh c3e ordinary opening reached five creatures, nine training wins, full
materials, a paid camp and one rested creature. It failed on the second required
bed assignment after680.507s. A retained-save short approach passed but began at
a materially different position; a directional diagnostic is being prepared.
See FRESH-REST-C3E-0909.md and RETAINED-SECOND-BED-DIAGNOSTIC-0909.md.

[Visual progress by biome/category](VISUAL_PROGRESS_SCORECARD.md) records0/4 full
biome passes, not an overall completion percentage. Torrentoad's bounded CPU
proposal failed clearance and remains held; face attribution is unresolved.
Production round3 is unconsumed and no installed-rig ceiling is proved. Global
creature mipmaps and night contrast candidates remain held. The playable campaign
and broader visual acceptance remain open.

Earlier entries below are historical checkpoints.

**Current resume checkpoint, 2026-09-09 20:30 UTC:** Claude PR105 landed before
work resumed. PR103 equipment/portable worn saves, PR104 First Shore timber
barrier, PR106 title-flow portable reconnect, and PR107 shared terrain mipmaps
are on main, followed by PR108's bounded harness lifecycle correction at
`c3e198b81cd62c9d356b16de9c52b66d385c38bc`. Every source PR has a full
first-attempt CI/raw-log review and verified matching landing tree. Reconnect
main152 CI34396402668 also passed all 27 jobs; terrain main CI34397173524 is
running. Release34397173485 passed with complete raw-log review, exact latest
tag, ZIP digest and Pages deployment verified at e231. The downloadable build
contains all four corrections. See CI-PR106-5501523fc.md, CI-PR107-1cbe0e30e.md,
CI-MAIN-152b48d2b.md and RELEASE-MAIN-e231897f4.md in the four-biome reports.

Reconnect passed 81 checks on both native Windows and Linux: portable equipment,
visible trainers, normal movement and host convergence. Eight existing bare ENet
teardown errors remain in the native proof; no clean-teardown or cold-start
character-picker claim follows. Terrain's 12 initialized resources expose ten
mip levels on both platforms. Four fresh neutral location reviews still answer
No/No overall: distant ground/shore improvements are narrow, foreground stretching
and broader visual gaps remain. Held geometry and live creature rearrangements
receive no acceptance credit. Other 275 protected import bytes remain unchanged.

The creature mipmap experiment now has a valid 162-image fixture and four fresh
neutral reviews covering its fixed lineup and all 20 isolated species. Local
smoothing does not establish improved facial or small-size hierarchy. A fixed,
conservative rectangular contrast diagnostic found 21 ratios beyond the 5% loss
guard; the 32-creature import candidate is held. Full body-mask/temporal acceptance
remains unproved. Full verdicts and mapping: CREATURE-MIPMAP-DISPOSITION-0909.md.
Global night contrast remains 1.08; that candidate is also held. The visual lane
has measured Torrentoad's installed low attack pose: minimum textured vertex y
-0.88847m,4965 vertices below -1mm; rest minimum approximately0, none below.
The isolated bake confirms floor penetration, not every vertex's anatomical
identity. Face/eye attribution and a bounded clip correction are in preparation.

Clean detached d3 passed the fresh earned opening prefix. Its first through-rest
run ended at the 600-second guard during unlabeled movement near camp. A copied
save diagnostic completed materials and paid lesson camp without reproducing the
loop; it is not earned-continuity acceptance. An instrumented fresh run then lost
an earned-team fight after an impossible post-miss readiness wait while aim was
IDLE. The actual-coroutine regression fails the original inactive-aim case and
passes both states after a minimal harness guard; strict throw checks remain.
Independent source review found no issue. PR108 at687280bb5 contains that
fix, read-only stage/walk/assignment receipts and a CI regression; full CI34399026464
passed26 executed jobs on attempt1 with all full logs reviewed, then landed at
c3e198b81 with the identical reviewed tree. Main CI34401138071 and
release34401138059 are pending. The changed-code fresh run ended at the600-second external
guard after earning five creatures, eleven training wins and reaching materials.
Its last completed harvest left wood19/18 and fiber12/18; all recorded material
walks arrived within their local budgets. A failed catch followed by a successful
strike is not yet evidence that the physical-miss recovery branch ran. The
90%-commit and400-process guards did not trip. Camp/rest and the historical third-assignment failure
remain unclosed. One clean c3e fresh through-rest proof is being prepared with a
declared1200s outer allowance; local budgets/assertions and resource guards remain.
No chapter, full visual or Beta gate is newly accepted.

Earlier entries below are historical checkpoints.

**Latest integration, 2026-09-09 15:50 UTC:** realm lifecycle PR97 landed as
main `c3a7eac5a44ad36751249eeda97eb771fb3099d0`, with identical reviewed tree.
Its exact-head CI34369962476 passed all26 executed jobs on first invocation;
all full raw logs were reviewed. Main CI/release remain separate running checks.
This PR94 branch integrates that main with the held finalized-death/telemetry
repair; a new exact-head CI is required. Previous CI findings remain retained in
CI-PR94-f823de9a5.md and CI-PR94-e5056c65f.md. No earned Varga victory or
continuous campaign acceptance is claimed.


**PR92 continuation, 2026-09-09:** the user selected PR #92 as the resume point.
Its landed main `8c0bfb31a` passed first-attempt CI `34310983183` and Release
`34310983188`; see `CI-MAIN-8c0bfb31a.md` under
`ralph/reports/FOUR-BIOME-BUILD/`. PR92's reviewed head `8ff6939fc` also passed
CI `34309659360` on its first attempt; its receipt is `CI-PR92-8ff6939fc.md`.
PR #93's release-tag repair landed as `4830bf402a94d7d945119027a454d07dfee1dccc`,
with ancestry and identical reviewed tree verified. Its exact-head CI
`34311229393` passed all required jobs, seven helper tests and 37 network smokes
on the first attempt; see `CI-PR93-0a8934106.md`. The post-landing Release and
live tag alignment still require verification. The prior local branch and its
unmerged descendants remain preserved separately.

Varga's isolated reproduction now identifies a finalized-death lifecycle defect:
camp recovery left hosted combat active, producing 200 accepted misses roughly
968 m from the third opponent. Lightning is an inferred trigger. Local commits
`3384f2825` and `9fa41dc26` withdraw finalized deaths before recovery, retain
revivable players, preserve other participants, and handle late admission and
observer snapshots. Native lifecycle coverage passed 37 checks; the earlier
two-process expiry regression passed 28 checks. The named world boot passed with
only its known material-null error. Exact-head CI and landing remain pending;
this is no Varga victory, earned campaign completion, or Beta acceptance. Details:
`VARGA-FOCUSED-DIAGNOSIS.md` and `VARGA-FINALIZED-DEATH-NET.md` in the same reports
directory. PR #94 carries this repair; the dated prior status below remains
historical context.

**Current audit-resume status after PR #91 merge, 2026-09-09:** the owner resumed
the four-biome Beta Ready objective. This section supersedes the owner-stop instruction
below for current work; the older paragraphs remain as dated history. PR #91 landed as
`origin/main` `49da91d51953fb4b650f29b1399ae41218f68f86`, from exact reviewed head
`b5dd34b4b7cec5bafc76affdbf33af84192e84a5`. Exact-head PR CI `34306689396`
passed on attempt 1: 26 jobs succeeded, the three configured jobs skipped, every
executed step was terminal success, and all 37 network smokes ran once. The raw review
is `ralph/reports/FOUR-BIOME-BUILD/CI-PR91-b5dd34b4b.md`. Exact-main push CI
`34308309450` and Release `34308309474` are live; no result is claimed for either.
PR #91's parent main `57660e4feb81fcbf8de5b0fe065e0ac107287676` remains verified by
passed main CI `34305636072` and Release `34305636213`, including their Windows exports
and exported-runtime ground checks; see
`ralph/reports/FOUR-BIOME-BUILD/CI-MAIN-57660e4fe.md`. Main is now `49da91d51`.

Stage C6 has been pulled forward and is **in progress**, but the full Stage C audit is
not complete. The merged reports document 116 local corrected-camera catalogue frames,
post-pylon Cloudreach/Stormwood recaptures and combined sheets; the tree contains their
identity receipts, five fresh independent reports and informed disposition through
`8e2227b47`: Meadows A/B is Yes/Yes;
Cloudreach, Stormwood, Water and Combined A/B are No/Yes; every set remains No for
shipping-art readiness. B establishes recognizable creature-adventure intent, not
commercial-quality acceptance. The later three-image Water-gate blind report is local
descendant evidence and answers A/B No/No for that narrow view only; it does not replace
Water or Combined B Yes. Local Cloudreach commit `ac2e2462f` records the completed
Settings catalogue audit within Phase A, while its broader route, interior,
weather/motion and target-hardware sweep remains in progress. The inspected raw screens
remain local; only their identity receipts and audit text are committed. All visual
findings and the Beta gate remain open.

The fresh-campaign aim work remains unresolved with a named commit-race/control-phase
cause and handoff. Both bounded guard and phase proofs failed; no fourth fresh campaign
will run in this resume session. Water's authored return into Stormwood at `d769a93c5`
is now on main. The later `WATER-RETURN-RUNTIME.md` solo run proves ordinary interaction,
realm transfer and grounded destination arrival only from an isolated prerequisite
fixture; it is local descendant evidence, not earned campaign completion. Network
evidence now landed through PR #91 commit `b5dd34b4b` adds a 33-check two-peer run:
the connected client used ordinary movement and interaction, reached ready Stormwood
with no pending entry, and was grounded at the authored return point while the host
remained in Water and route authority stayed unchanged. Neither fixture is earned
campaign evidence. The known older avatar/proxy cached-packet teardown issue remains
open. Do not mark a stage passed from these bounded proofs.

The bounded ROAD heading reproduction at `618ff7ea1`, with informed disposition and
fresh blind report through `f50bf67ba`, produced only two 1280×720 sample-37 images.
The recorded heading observer count was zero and the travel-facing count was three,
but the critic could not independently recognize those distant bodies as creatures:
the narrow verdict is A Yes / B No / shipping readiness No. The fresh-reset walk then
stopped at the intentionally locked TrailGate because the historical campaign had
already earned its opening prerequisite; this is a fixture mismatch, not a new
production navigation defect. Clock metadata also failed in the capture helper, so
exact time/weather is unverified. No sample-43 pair, complete 65 m reproduction,
whole-ROAD pass, art pass or Beta credit is claimed. The full readable-creatures-ahead
requirement remains open. The post-run helper correction passed only the isolated
headless `--parse-only` early return (`ROAD HEADING PROBE PARSE OK`, exit 0); it loaded
no world and is not a second graphical validation.

The earlier playground chop smoke failure was observation lag: its process-frame
durability poll trailed a synchronous impact callback inside the unchanged timing band.
Test-only commit `7c11fce2a` is now on main and accepts callback time only after the
required tool's real identity-resolved durability decreases. Exact-head CI verified its
three regression cases and the full `smoke_playground.gd` on first invocation, with a
`0.389 / 0.625 = 0.6224` synchronous receipt and the later poll retained as diagnostic.

**Owner-requested stop, 2026-09-08:** see
`docs/HANDOFF_FOUR_BIOME_2026-09-08_OWNER_STOP.md` before resuming. Latest owner
scope is the complete Stage C6 all58 Settings destinations/day-night visual audit,
plus a separate ongoing earned-content lane. The audit is not implemented or run.
The bounded Cloudreach render crashed at ground-cover allocation before completion;
owner save fingerprints matched afterward. All agents stopped; no Godot remains.
Picker CI34288938433 is terminal success on8eb887bac, but the later exit work needs
its own CI/review. PR90 stays draft, main unchanged; goal remains incomplete.

**Owner priority update, 2026-09-08:** Ally Gamepad mode resolved the reported
inability to get out of bed (owner confirmation). The four-character picker is
rebuilt locally with portraits and Arlo/Lyra/Kael/Sera names; stable save IDs remain.
Actual UI controller/keyboard checks and a blind capture review passed. Combined
picker/device tests:13 tests/70 assertions, zero failures. Prompt tracking now
ignores old-device releases and stationary cursor refreshes; this is not claimed
as the hardware wake fix. The owner explicitly reopened region loading and the
non-Meadows terrain/cloud visual pass; these are the current work priorities.
See OWNER_PLAYTEST_2026-09-08_PICKER_LOADING_TERRAIN.md and
ralph/reports/FOUR-BIOME-BUILD/CHARACTER-PICKER-OWNER-FIX.md.

PR90 head10fb6f1dbcc4dd42fdf4fb532c7fee4101dac801 passed exact-head
CI34287024505 on attempt1:26 successful jobs/three expected skips,3060 unit
tests/487393 assertions,86 first-attempt wrapped smokes. This is PR evidence,
not a new main landing. Picker/input changes are subsequent local work.
The chapter-fixture Stormwood-through-Crown run was interrupted for the owner's
urgent Ally report after gathering six glass; no Crown completion is claimed.
The second genuine fresh run stopped before throwing because the production
reticle verdict was ineligible; no full fresh campaign pass exists. After two
failed fresh attempts, repeated opening runs stopped. An isolated proposed aim
timing change did not pass and was withdrawn.

Owner loading reproduction: the actual solo Game.enter_realm Meadows→Cloudreach
path completed in336.006s with44,347 destination nodes and cleared pending entry.
Diagnostic gate bypass was disclosed; this is transfer performance evidence, not
earned chapter entry. Construction took322.431s: routes82.878s, the later combined
ground-cover/chapter/look/encounter setup233.020s. CPU continued advancing during
the long quiet interval; no deadlock was observed. The baseline exited0 and owner
save fingerprints matched. Logs`.artifacts/realm-load-baseline-v2{,-engine}.log`;
the preceding instrumentation parse failure is retained separately. No loading
speedup or visual improvement is claimed yet. Picker head8eb887baced51b611abcf8dfadd630dfc1c5640c
is now pushed; its own CI34288938433 remains in progress.

**2026-09-08 Wave6 local gameplay work:** Lantern Hollow's four overlapping
NPCs now have separate nearby placements around the unchanged Spark shrine.
Actual grounded walking reached all four exact prompts, and Sable's ordinary
dialogue granted captive_truth_learned; zero navigation resets, owner saves
unchanged. No trainer fight or full campaign is claimed. Crown gathering now
requires the production arch's six glass, with full builder payment unchanged.
Focused progression/authority checks23 tests/115 assertions, Lantern data and
dialogue8/936, and the adjusted earned Dynamo helper5/49 passed.
These changes are local, awaiting PR CI and landing. Details: GAMEPLAY-WAVE6.md.

The changed genuine fresh run on526bb5aac stopped302.373s into the tutorial
fight before capture. Both throws committed outside the game's reticle radius;
the loss is preserved, not rerun away. Necessary driver changes match player
collision layers and recheck the final production throw verdict. Neither proves
the older third-bed failure fixed. Full opening-to-ending remains incomplete.

**2026-09-08 21:37 UTC: content Wave5 landed in PR #89.** Main is
`65267c4bd935d80b2e073799caeffc81b913952c`, identical in tree to verified PR
head`f4886bcb937e31a01276a2e5b7a42172b76be8d6`. Exact-head CI34279303451
passed on attempt1:26 successful jobs/three configured skips,3056 unit tests/
487375 assertions, all seven multiplayer shards. Every job, step and executed
log was reviewed;86 wrapped smokes used only attempt1 and18 direct checks passed.
Main's OWN push CI34281611197 passed on attempt1 at22:02:52UTC:27 successful
jobs/two existing manual-only skips. All executed logs and steps were reviewed;
Windows PE export and the Linux exported-runtime terrain check passed. Windows
artifact10078655466 is uploaded. No Windows/Ally or full-campaign pass is implied.

The shipped batch includes the all-five care rung, persistent swimmer preparation
instructions, actual Water combat HUD/shared Engage, and both Brine010/011
placements. Each site's three species passed native footing; ordinary grounded
walking and physical Interact started its exact encounter. No full fight win or
campaign is implied. The two stale content expectations from first head08b5b3d6
remain recorded in failed CI34277113851; corrected fixtures require all34 authored
objectives and the readiness transition. No retries or acceptance weakening.

**2026-09-08 20:03 UTC: first-camp and Tidewake content landed in PR #88.**
That landing's main was `2eb8d4b8681ce8224eaa58666b41be5164479c5b`, with the identical tree
to verified PR head `9cb6b1b42d4c5947842f72e2b8a57a1cd54e4593`.
Its PR CI34270467585 passed on attempt1:26 successful jobs/three configured
skips,3055 unit tests/487315 assertions and all seven multiplayer shards.
Every executed job/step/log was reviewed. Main's OWN push CI34272560821 passed
on attempt1 at20:31 UTC:27 successful jobs/two existing manual-only skips,
all seven multiplayer shards, Windows PE export and the actual Linux exported
runtime terrain/ground check. Artifact10075421254 is uploaded. This is not a
Windows/Ally playthrough; see MAIN-GREEN-20260908.md for receipts and diagnostics.

The village gathering placements and campsite dialogue, Salt Crown charting
instruction, Nerissa dialogue, reachable wood prompts and same-live Aquaryn
retirement are now on main. The failed fresh run's paid camp and two actual
rests remain partial evidence. A diagnostic reload reached the same bed and
did not reproduce the stall; it proves no fix and is not fresh acceptance.

The saved-camp image exposed an additional guidance gap: the HUD says to enter
the tournament while three creatures are still unrested. Shipped Wave5 adds a
care rung using the existing live tournament_condition_ready flag and retires
it after registration. It changes no eligibility rule. A new diagnostic-copy
capture renders the correct care instruction; original/owner saves are unchanged.
Existing quest/home checks pass54 tests/896 assertions. Full uninterrupted
campaign and full forward-view coverage remain open.

Shipped Wave5 also makes the post-Iona preparation explicit: craft at the actual
Tidal Cradle camp workbench, keep the saddle in the bag and use the companion's
Ride prompt. Otto explains ordinary swimmer capture, the five-creature choice
and pickaxe gathering for Reef Stone. Salt Crown's existing objective retains
these directions after the recipe is learned. Existing dialogue/dock/quest
checks pass47 tests/937 assertions with clean engine output. No new costs,
completion flags, equipment step or encounter rule was introduced.

Water's runtime builder also omitted the shipped CombatHUD and shared Engage
registration. Shipped Wave5 now mounts that existing HUD against the actual
manager/director and registers the director with the scene arbiter. The existing
scene smoke passes40 checks headless and41 rendered, including health/name/move
panels and Engage display. Owner saves match; no engine/script errors. The frame
proves HUD presence, not combat framing: the synthetic fixture's camera has not
settled onto the actors. Existing terrain/deprecation warnings remain recorded.

The existing isolated Water chapter run has now completed First Shore through
Iona's Swim Saddle recipe with the same five carried creatures, including all
Reedhaven/Brine/Shellwatch actions, actual camp care and Aquaryn victory. It
passed once in approximately18m24s within the unchanged20-minute watchdog,
with owner saves unchanged and no engine/script errors. This uses the disclosed
synthetic level44 chapter-entry team, not fresh campaign progress. Brine sites
010/011 emitted invalid-footing warnings in that run. Shipped011 now moves to
a supported nearby shelf: all three species passed native footing, and a
grounded approach plus physical Interact started combat with the exact Riptusk.
The first011 diagnostic wrongly required arbiter registration before Water's
HUD/registration fix; its failure is retained. The original010 high candidate
failed and was restored, then a different lower shoulder at
[320.4116,26.3276,637.8423] passed all-three-species footing and actual Engage
through the shared arbiter against its Mangrove Monitor:86 observed frames,
zero resets/errors and unchanged owner saves. Data/residency checks pass12 tests/
2213 assertions. Full fight completion was not proved by these placement checks.
See WATER-OPENING-CONTINUOUS.md and BRINE-ORDINARY-FOOTING.md for evidence.

**2026-09-08 19:10 UTC: Wave 3 landed; its own main CI is green.**
PR #87 exact `6c0f0e78046fbd15c3e1fe46de06fa154981be66` passed run
`34262351185` on attempt 1: 26 executed jobs passed, three existing conditional
skips, 3037 unit tests/487178 assertions, all seven multiplayer shards. Every
executed job/step/log was reviewed; five new strict native checks were clean.
Squash main `043cd1061ba8e1423d1681c7479d9ad36f6d4317` has the identical tree.
Its own push run34264602920 passed on attempt1: 27 successful jobs/two existing
manual-only skips, all seven multiplayer shards, Windows PE export, actual
Linux exported-runtime terrain/ground check, and artifact10072368637.
Every executed job, step and log was reviewed; this is not an Ally playthrough.

The owner's latest direction prioritizes actual game content. Shipped Wave 4
clarifies the Tam-to-Practice Meadow gathering walk with two existing resource
placements, NPC dialogue and camp instructions. Tidewake guidance now names
Salt Crown's required chart interaction and removes Nerissa's unsupported
conduit instruction. These edits landed in PR #88.

The latest genuine fresh run, `wave4-fresh-camp-lesson`, stopped at595.393s:
ordinary opening and revised village dialogue, five earned creatures, ten
training wins, actual camp materials gathered, paid tent/fire/bedroll/one
Creature Bed, and two successful actual rests. The next bed assignment could
not reach its prompt, stopping5.2m short at[31,0,-38]. Owner saves were unchanged;
there were no engine/script errors. The quest requires one bed; the explicit
lesson mode derives that count without weakening the five-creature readiness
check. Full care, tournament and opening-to-ending remain unproven.

Local wood prompt-height and same-live Aquaryn retirement fixes have native
runtime evidence. The earlier750.55s fresh run harvested the original failing
tree plus two more, then failed at a separate overlapping forest cluster. That
cluster is recorded as deferred, not fixed. The latest run's read-only observer
recorded123 samples over1364.57m, with92 below two visible creatures and one
undersampled interval; full forward-view coverage remains open.

Four first-camp day/night captures received one fresh blind review: key-art
belonging no, Palworld same-kind yes without quality parity. Named material,
ground-cover, path and lighting gaps are deferred. Existing content checks
passed29 tests/22302 assertions; village dialogue/quest110/1998; lesson helpers
and home/quest60/896; Tidewake dialogue/dock/quest113/2053. Expected dialogue
negative-control errors are disclosed. See the first-camp Wave4 report.

The local driver composes the full Water ending. A disclosed Guardian fixture
passed invitation, full-party farewell and saved ending receipts; it is not a
fresh campaign. These local results supersede the older statements below.
**2026-09-08 18:12 UTC: Wave 2 is landed and main's own CI is green.** PR #86
exact head `a62c81ae562714a59eb62ebcb2117e2649fa7e76` passed CI `34256323372`
on attempt1 (26 successful jobs, three existing conditional skips; 3013 unit
tests/486957 assertions, all seven multiplayer shards). Every executed job and
step was reviewed. Main is now `b3458eb1d0f54ceb2554a97e9b0fe0b2f88f5bfb`,
with the same tree; its own push CI `34258802654` passed on attempt1:
27 successful jobs, two existing conditional skips, 3013 unit tests/486957
assertions, all seven multiplayer shards. Windows PE export, actual exported
Linux runtime terrain/ground probe, and artifact10070087141 all passed.
Every executed job/step/log was reviewed; diagnostics remain disclosed in the
main-green report. This is not a Windows or Ally playthrough claim.

Landed runtime repair: the Relay ramp now meets its correctly oriented deck,
verified by an actual Player walk. Earned later-chapter helpers are composed
through Rootgate but remain unproved in the complete fresh path. Local Wave 3
on `codex/four-biome-wave3` repairs observed throw-preview occlusion, Iona and
Stormheart footing, and the earned driver's missed/double party-cycle input.
The latest completed genuine fresh run earned five and ten training wins,
all five at level5+, then gathered wood to31/42 before failing a vegetation
interaction at624.730s; owner saves unchanged. Actual cycling was correct.
Two material-null engine errors occurred during an earlier successful harvest;
neither those errors nor the failed swing are dismissed as cleanup. No paid
camp or full campaign completion is claimed by this update.
The material fallback-status approach and felled-wood destruction now have
clean native reproductions and fixes. A changed title-start run is active
under `wave3-fresh-harvest-campaign`, using a new isolated profile. Local source
composition reaches the earned Iona recipe, with the mounted ending suffix
still being extracted; source/focused checks do not prove that campaign path.
This supersedes the earlier Wave 2 pending-branch description below.

**2026-09-08 17:07 UTC: Wave 1 is landed and main's own CI is green.** PR #85
verified head `19d6ea8ecbc44ea479d5e49514359f6c116ba199` was squash-merged as
`bc26b21eec2b96a8fbd8295732007aa67f92198a`. Its own push run `34252353122`
passed on attempt 1: 27 successful jobs, two existing conditional skips,
2980 unit tests / 486685 assertions, all seven multiplayer shards, Windows
export and exported-runtime ground verification. Every job/step/log evidence
was reviewed; the fetched main tree matches the verified PR head. The prior
artifact-403 run remains a recorded failure, not a rerun pass.

The landed village gate route has genuine fresh-save proof: the same run earned
five creatures at level 5+ through ten training wins. It then gathered wood44/42
and fiber8/50 before repeatedly entering the closed SouthBridge trench; that
attempt was explicitly stopped, owner saves unchanged. Paid camp and the full
opening-to-Tidewake run remain unproved. The separate chapter fixture completed
Shellwatch's trainers, release, pump and departure gate, not a fresh campaign.
Wave 2 continues from this main on `codex/four-biome-wave2`; pending material,
Relay-deck, Alpha-clock and Aquaryn repairs and later composition are not claimed
landed. Detailed evidence: `ralph/reports/FOUR-BIOME-BUILD/WAVE1-FRESH-COMPOSITION.md`.
This update supersedes the earlier draft/head status entries below.

**2026-09-08 13:51 UTC: main is green; Wave 1 starts from it.** PR #80 was
squash-merged at `75aaccca0210a9bc1ac0f16bac687d8557f0aacf` after exact-head
`9cbec44fbbcf644bc2019cea8cab6c32aab32fd5` CI `34229513422` completed
26 successful jobs / three existing conditional skips, attempt 1. Main's OWN
push run `34231941105` completed 27 successful jobs / two existing conditional
skips, attempt 1, at 13:50:58 UTC. Every job/step and log evidence was reviewed,
including all seven multiplayer shards, Windows export and exported-runtime
terrain verification. The fetched handoff file is present and main's tree
matches the verified PR head. No assertions, ceilings, shards or retries were
loosened. Repair detail: `ralph/reports/FOUR-BIOME-BUILD/MAIN-GREEN-20260908.md`.

The repaired paths include scaled-body shared-wild diagnostics, Varga's existing
terrain clearance, completed asynchronous catch observation, Tamsin's real-body
staging with authoritative killing-hit checks, and atomic shared-boss HP/hit
observation. CI green does not erase the two local Gate F full-checkout issues
recorded in `SECOND_PASS_BACKLOG.md`; the local full suite is not claimed green.

Fresh branch `codex/four-biome-wave1` starts from that verified main. Stormwood's
Varga/Ondra/Crown continuation, Tidewake's Shellwatch-onward composition and the
actual uninterrupted fresh-save opening-to-ending run remain unproved. Existing
chapter fixtures carry synthetic starting state; they are not milestone proof.

**15:56 UTC update:** draft PR #85 head `0a91f9b39aa552e554b849b4eb57d8011e2c7589`
is not green. Run `34245691443` passed all runtime smoke steps and 2977 unit
tests / 486656 assertions, but MP4 artifact finalization failed with HTTP 403.
No rerun or merge requested. The latest genuine fresh path passed key consumption,
earned five creatures and one training win, then stopped on a terrain approach
at 293.92 seconds. Owner saves are unchanged. The Stormwood exact-Engage attempt
also failed admission; its underlying cause remains under bounded diagnosis.
These later observations supersede the pending-runtime descriptions below.

The changed Fenn placement now passes ordinary Ondra access: the serialized
Stormwood path collected the actual route-09 reward and learned the Stormglass
Arch recipe through dialogue. It next failed admission to Capacitor Alpha in
the Crown helper, before Crown construction. An exact-target ordinary Engage
repair has focused tests and awaits runtime; no Crown completion is claimed.

**Wave 1 progress, 2026-09-08:** the genuine fresh opening through village tools,
key consumption, Satchel assignments and three physical harvests now passes in
172.968 seconds with owner saves unchanged and no native/script errors. A prior
expanded attempt exposed shared-provider target confusion; the corrected helper
verifies the exact offered and admitted creature. The next fresh run earned all
five creatures and six real training wins, then failed ordinary navigation to
the next wild encounter after 519.745 seconds. Camp/care/tournament and bridge
continuations are prepared, not runtime-proven. See
`ralph/reports/FOUR-BIOME-BUILD/WAVE1-FRESH-COMPOSITION.md`.

Draft PR #85's first head `856534a7` completed CI `34236551038` with25 successful
jobs, one MP5 control-listener bind failure, and three conditional skips. The
local allocator fix reserves OS-assigned TCP listeners before spawning peers;
real socket tests and the full two-peer catch race (47 assertions) pass. The
changed code still awaits exact-head CI. This does not
change the verified main result above. See
`ralph/reports/FOUR-BIOME-BUILD/CI-CONTROL-PORT-20260908.md`.

That allocator batch now passes exact-head CI `34242634338` on
`8cd81b422e466a3918f471344750ee7edd15e883`: 26 successful jobs, three existing
conditional skips, attempt 1; all four unit shards total 2,963 tests / 486,540
assertions. Every job and its log evidence was reviewed. PR #85 remains draft
while the next observed-path repairs are prepared; this is not a main landing.
The next fresh camp attempt stopped at the inherited straight-line village-key
walk before team selection. Its obstacle-aware input replacement has focused
tests and awaits live proof. Water's full chapter fixture proved actual
Shellwatch recovery/selection, then stopped on the steep Solm approach; a
terrain-supported detour retains the existing stance and bounds. Full fresh
camp/tournament/Warrens and opening-to-ending completion remain unproved.

The active target is the **playable four-biome build**, as defined by
`docs/owner/OWNER_DIRECTIVE_2026-09-07_PLAYABLE_FIRST.md`: a fresh save completes
the opening through Tidewake without debug travel, console commands or a reload
to advance. Full visual, density, performance and multiplayer-depth criteria
remain in `docs/SECOND_PASS_BACKLOG.md`; they are not claimed passed.

PR #79 and PR #80 are on main. The following capability ledger is now landed;
its continuous-path and hardware limitations remain open. Superseded per-head
CI history is retained in the build checkpoints and named CI reports.

| Area | Verified progress and remaining boundary |
|---|---|
| Saves and second-bed freeze | Corrupt-canonical recovery and split-write rollback repaired; immutable fallback autosave runs on one worker. Ten two-bed cycles plus a 180-second soak pass, with the measured post-warmup maximum reduced from 536.7 ms to 107.6 ms. Save/load and recovery tests pass. This does not establish first-hour rendered performance on the Ally. See `ralph/reports/FOUR-BIOME-BUILD/save/REPORT.md` and `autosave/REPORT.md`. |
| Map/minimap | Compass overhaul rolled back; minimap restored. Real repeated map input and an independent blind inspection confirm both opens remain populated and the second is not corrupt. Existing label crowding remains deferred. See `ralph/reports/FOUR-BIOME-BUILD/hud-map/REPORT.md`. |
| Stormwood and ordinary Tidewake entry | Dynamo, release/aftermath and the Waterward reveal are implemented; the real Stormwood-to-Tidewake gate smoke passes. Hosted-trainer admission now resolves the race with local aggressive wild combat, with a passing two-peer Tamsin smoke. Livewire passes connected CI on its first attempt in run 34197701347. |
| Tidewake progression | Aquaryn's ordinary strike action IDs are repaired; the production defeat-to-Swim-Stone-to-saddle-to-mount path passes. Five authored named encounter sites now spawn in production. Long mounted crossings, Salt Crown/Sluice fights and controls, and the composed Veilfall/Guardian ending remain an open continuous-play proof. Isolated finale tests do not close that requirement. |
| Creatures and menu travel | All 32 later-biome species are assigned to encounter tables; creature sizes span 1.90–7.20 m. ROAD evidence and its visual limitations are in §3. Settings offers 58 destinations across all four biomes; production realm-crossing and physical menu checks passed. |

Exact current main validation is recorded above; older per-commit boundaries
remain in `ralph/reports/FOUR-BIOME-BUILD/checkpoints.md`. The following runtime
notes describe the inherited path evidence, not a four-biome completion claim.

**Solo Stormwood victory repair, 2026-09-08:** the continuous runtime re-earned
Ashfoot arrival/dialogues, sheltered Break, six Stormglass, arch pair A and the
route pickup, then resolved three Maren combat rounds through real input.
The durable trainer defeat flag did not arrive; that log does not separately
record each round's win/loss outcome. Independently, root confirmed
`StormwoodEncounterDirector.award_hosted_trainer()` had incorrectly used the base
live-session-only `_is_host()` guard, although the Stormwood hub also owns solo
fights. The same award method is called by Dynamo completion. The focused repair
allows the offline authority while continuing to refuse active clients;
`7a773b8b0` passes eight focused authority/real-ledger checks. In the
subsequent uninterrupted run, the production finished event explicitly reports
Maren won, the durable defeat flag arrives, and the ordinary Verge rod switch
succeeds. That run then failed to start Dace. The subsequent diagnostic records
an intervening wild loss, uses ordinary party cycling/recall, and wins all three
Dace rounds, receiving the durable victory and both lower-rod switch results.
It then reaches the eight-minute outer harness watchdog; this is neither
whole-chapter completion nor a demonstrated game freeze. A twenty-minute
scope-derived harness with per-leg telemetry is prepared for the extended route
through Varga and Ondra. The earlier unlogged challenge failure's exact cause
is not established merely by this successful recovery.
Log: `C:/Users/mattj/AppData/Local/Temp/stormwood-continuous-solo-award-final.log`.
New CI steps `7e2753721` cover the reward and lightning-cleanup regressions;
these commits are included in submitted batch `23b7d4acd`, along with a focused
detached-opponent teardown fix and a CI regression that scans native errors.

Latest `e78a76080` continuation has independently observed new prefix evidence:
all three Dace wins and both rod switches, then a Lantern Pools charged-window
wait ending after68.025 wall seconds with131.966 simulation seconds open. Both
Pools nodes036/037 yield their exact three-glass durable receipt and one pickaxe
wear each. This proves the bounded weather/receipt repair on this run; the
process is still continuing toward Rodline Post, not a chapter pass.
Log: `%TEMP%/stormwood-continuous-e78a76080-20260908.log`.

**Tidewake opening seam, 2026-09-08:** the uninterrupted diagnostic starts at
the production arrival, walks to Pell, completes his real dialogue, swims
64.488 m to earn the lesson, and crosses to Reedhaven through ordinary human
movement. Its first reed gather fails correctly because the fixture lacks the
canonical knife; the stale selected-node metadata says hand. Correction
`283897ed3` supplies disclosed knife/axe tools before world creation and uses
their real hotbar actions. The corrected uninterrupted run passes: 64.487 m
lesson swimming, ordinary crossing, four exact node receipts yielding six reed
and six driftwood, then the production repair flag with six reed and four
driftwood spent. No Water materials or progression are granted; its native
ERROR/SCRIPT ERROR scan is clean. This initial chapter fixture does not
establish earned Stormwood-to-Water campaign continuity or progression beyond
Reedhaven. Logs: `%TEMP%/water-opening-reedhaven-first.log` and
`%TEMP%/water-opening-reedhaven-corrected.log`.

**Tidewake Brine blocker repaired locally, 2026-09-08:** the optional level-44 carried-party
diagnostic repeats the opening/Reedhaven pass and physically crosses 107.088 m
to Brine Steps, but fails its Tovin approach. The player stalls at
`(408.952,43.667,733.921)` toward `(433,75.917,683)` with zero confined resets.
Tovin's mandatory fight is not yet reached or proven; his reused NPC position
is off the graded route near the summit. The same run rejects ordinary creature
sites `water_brine_steps_wild_010` and `_011`. Production footing and walked
approach diagnostics are required, not progression grants or relaxed checks.
Log: `%TEMP%/water-opening-brine-first.log`, terminal exit 1.
The local Tovin placement candidate `(395,809)` now passes physical approach:
ordinary p3/p4/p5 walking, zero resets, all nine Terrain support rays and
0/8 approach samples over24 degrees. The first candidate run still exits1:
the probe had not deployed its creature, so the trainer correctly refused its
live offer. Controller deployment is added to the next probe; no fight or
placement-completion claim yet. Brine010/011 fail the actual creature footprint
(steep/missing support), not raw JSON Y, which production already normalizes.
See `TOVIN-APPROACH.md` and `BRINE-ORDINARY-FOOTING.md` in the build reports.
Subsequent committed placement657fd49ef passes the uninterrupted opening-to-Brine
replay: Pell/64.488m lesson, four Reedhaven receipts and paid repair,107.088m
crossing, graded approach, both authored Tovin opponents, surviving ally294.5/358,
and both durable victory/trial flags. Root independently read failures[] and
terminal output; no native ERROR/SCRIPT ERROR. Log:
`%TEMP%/water-opening-brine-tovin-repaired.log`, exit0. This closes the local
Tovin blocker, not an earned Stormwood handoff or the whole Water chapter.
Original ordinary spawn010/011 warnings remain separately under repair.

**ROAD validation reopened, 2026-09-08:** the late-Tidewake traversal diagnostic
reached Salt Crown but production rejected footing at
`road_visibility_salt_crown_exploration_spine_01`, `_02` and `_03`, plus ordinary
sites `water_salt_crown_wild_011` and `_013`. The earlier 4,253-sample route model
and 12 representative frames do not establish continuous live coverage of these
sites. Measure the surviving creatures along this played route and repair any
coverage gap before treating the functional ROAD closure below as complete.

Salt Crown follow-up: a coordinate-only repair moves failing ROAD sites
01/02/03/05 from 5.44–5.47 m shoulders to 1 m route offsets. The production
probe now admits 2/2 creatures at all seven Salt Crown ROAD sites, and real-stick
24 m walks pass across all four repaired populated segments. Sluice's analogous
four-site repair also passes: all six ROAD sites admit 2/2 and four populated
24 m walks pass. Tidal Cradle's three-site repair (`09cd1c66c`) now passes all
nine ROAD sites at 2/2, plus populated 24 m walks at 02/03/08. Ordinary Salt
Crown wild sites 011/012/013 are now repaired in `1f6851a89`: coordinate-only
moves of 8/6/4 m produce one actual member at each site without admission
failures, and every legal table species passes its scaled-footprint support
check. This focused three-site proof is not continuous forward-view coverage.
See `ralph/reports/FOUR-BIOME-BUILD/SALT-ORDINARY-FOOTING.md`.
Veilfall's strict follow-up now admits
2/2 creatures at all 24 ROAD sites and passes all 15 populated 24 m walking
checks. The coordinate-only candidate had left site20 at 1/2 and blocked walks
19/20/22. Staggering site20 and restoring Water's missing ROAD-only trainer/wild
collision exception resolved those bounded checks without changing terrain or
combat collision rules. Full continuous forward-view coverage remains open.
See the footing reports under `road-visual-creatures/` and the Veilfall report.

**Late Tidewake follow-up:** Calder's approach repair is submitted (`ffb7916db`).
The synthetic-start route now proves ordinary Bex, camp/rest, Calder and both
sluice controls; a copied-save suffix also mounts through the actionable Ride
offer after physically approaching the follower. That suffix emitted two
diagnostic script errors, now corrected with a focused regression. It is not
a clean run or a fresh-save proof. Committed harness `9b5cd7315` retains those
boundaries in `ralph/reports/FOUR-BIOME-BUILD/WATER-LATE-CONTINUOUS.md`.
Venn's reused NPC body was hundreds of metres above the graded approach.
Coordinate-only repair `d251f735e` puts him on the spine; real-stick traversal
walks 349.49 m with zero resets and obtains an actionable production challenge
offer. The subsequent synthetic-start late-chapter continuation also defeated
all three Venn opponents after the physical hike, entered Veilfall, redeployed
and opened both interior controls without post-departure fixture writes.
It then lost to Nerissa: the single Aquaryn entered after Venn with
250.9/708.4 HP and fainted during the second opposing creature. This does not
prove a normal five-creature campaign is blocked; ordinary intervening recovery
is being prepared. The ending remains unproven. Exact terminal log:
`C:/Users/mattj/AppData/Local/Temp/water-continuous-full-20260908-0358.log`;
see `ralph/reports/FOUR-BIOME-BUILD/VENN-APPROACH.md`.

**Earlier late Tidewake attempts (superseded by follow-ups above):** the synthetic-start traversal
diagnostic completed Tidal Cradle -> Salt Crown, the Salt chart interaction,
and Salt Crown -> Sluice Isle with the same mount and no post-departure resource
or position injection. It then failed to reach Bex from the exploration spine:
player `(832.01, 74.63, 2870.74)`, challenge target `(872, 116.22, 2940)`.
The approximately 80 m horizontal / 42 m vertical separation requires a real
route-versus-placement diagnosis; a navigator failure alone does not prove
the terrain is impassable. That original run proved no Bex victory or later finale.

Follow-up on the working placement repair: the synthetic-start diagnostic has
now walked to Bex on the arrival spine, defeated both opponents (+442.6 s) and
activated the western control (+443.5 s), with no post-departure fixture writes.
The character-data change preserves his team, dialogue and progression flags.
The suffix then failed at Calder's crown approach: player (788.349,62.516,2870.969)
remained 92.7 m from his prompt (836,115.767,2930). A near-east-control placement
repair is under validation. Neither Calder nor the finale is proven, and the
synthetic starting state still prevents a continuous fresh-save claim.

The next diagnostic reached Calder's revised departure-road placement and
entered all three opponents, but ended without the victory flag. The east
control was correctly not attempted. Loss versus reward-delivery failure is
under diagnosis; no encounter weakening is justified by this result.

The exhaustive teleport check additionally caught Cliffhold returning to the
previous High Perches landing: Cloudreach's 100 m walking-fall safeguard saw the
old Fly anchor after the deliberate relocation. Local commit `894a48f21` clears
that anchor on successful menu travel and correlates host replies with unique
request IDs so delayed replies cannot restore it. Focused tests pass 15/996;
the full-world rerun now passes all 58 destinations with the no-input
displacement assertion, no script errors and no recovery messages. Connected
Fly validation is still pending. No ordinary fall rule or destination-grounding
check was relaxed. Log: `.artifacts/realm-teleport-anchor-reset58.log`.

### Consolidation baseline — historical, before PR #80 repairs

**Every branch that carried unique work is merged onto `codex/four-biome-push-0907`
and lands as PR #79**, on the owner's instruction to get everything onto `main`. The
project no longer has a branch backlog; it has one tree, and three things in it are
unproven by their own authors.

- **The next orchestration run is
  `docs/prompts/77-CODEX-GOAL-four-biome-push-2026-09-07.md`.** It carries the owner's
  2026-09-07 playtest items, the visual sweeps, the combat ladder, the biome tails, and
  the three lanes that exist to prove or revert what the merge just landed.
- **Owner playtest 2026-09-07** (`docs/owner/OWNER_PLAYTEST_2026-09-07.md`): P0 hard
  freeze placing a second creature bed, P0 repeated freezes in the first ten minutes,
  P1 bare road stretches with no creatures in view. Priority: stability, then looks and
  content, then performance (cheap wins only).
- **Owner directive 2026-09-07**
  (`docs/owner/OWNER_DIRECTIVE_2026-09-07_AGENT_GENERATED_REFERENCE_ART.md`): for one
  pilot subject, the agent may generate its own reference art, have a blind judge pick
  among three candidates, and run Meshy from the winner — Meadows included. Two
  `CLAUDE.md` art rules are lifted for that one subject only.

### What the merge landed, and how proven it is

| Area | State |
|---|---|
| **Water (Biome 4)** | Whole foundation now on `main`: twelve islands, human swimming and drowning, five mounted swim species, docks, camps, encounters, the Aquaryn host fight, the Veilfall interior, Nerissa, the Guardian ceremony. **35/100 and incomplete.** Cannot be entered by ordinary play — no production emitter for the `aftermath:waterward_view` reveal, no Water transition point. Late joiners can be permanently denied the Swim Stone. The Alpha fight is dry. Tail: `ralph/reports/WATER-PROGRESS/EXIT-HANDOFF-2026-09-07.md`. |
| **The save layer** | `scripts/save/atomic_save_file.gd` plus rewritten `world_save.gd`, `character_save.gd`, `save_game.gd` now govern **every save in every biome**. Arrived with Water; its own author says the diff "has not received complete independent review or the required full suite". **Highest-risk item in the tree** — prompt 77 lane SAVE. |
| **Stormwood hosted combat** | `stormwood_authoritative_fight.gd`, `stormwood_hosted_trainer.gd`, `stormwood_encounter_hub.gd` and a change to shared `scripts/net/session.gd` are on `main`. **Unproven**: `smoke_net_stormwood_hosted_trainers.gd` fails at trainer start and the last edits were never recompiled. Tail: `ralph/reports/STORMWOOD-PROGRESS/EXIT-HANDOFF-2026-09-07.md`. |
| **HUD compass / map** | The runtime minimap is **removed**, replaced by `scripts/ui/compass_bar.gd`; `tab_map.gd` and `quest_log.gd` reworked with objective destinations. **Known player-facing bug**: the second map open on the real Meadows world loses terrain and fog and fragments unrelated glyphs, confirmed in OS-composited pixels. The committed 30-frame deferred refresh is an unverified experiment. Tail: `docs/CODEX_EXIT_HANDOFF_2026-09-07.md`. |
| **Stormwood chapter** | PRs #68, #70, #74, #76, #77. Scorecard 12/100. Dynamo, legendary release, Spark/aftermath and the Waterward view are all "blocked by missing implementation" in its own table. Every blind judge rejects both visual bars. |
| **Roster and characters** | 57 species with installed meshes; the 32 new Cloudreach/Stormwood/Water species are in **no** spawn, encounter or trainer table. Four playable characters are offered, but the choice is not persisted and remote peers render the local body rather than their own. |
| **Multiplayer** | Implementation scope complete (PR #63); the 5-way shard completes in CI; the 3/4-peer workflow ran green 2026-09-07 08:27 UTC. No owner evidence row is signed — those are owner-only. |
| **Cloudreach** | Continuous acceptance replay clean (`docs/biomes/cloudreach/CONTINUOUS_ACCEPTANCE_0905.md`); visual bars "No, narrowly" / "No"; the owner's Phase A audit document does not exist; stand 05's ground still reads flat green. |
| **Performance** | First real Ally measurement: six of nine stands under 8 fps with grass on at 2053×1080 (`docs/PERF_ALLY_FIRST_MEASUREMENT_2026-09-07.md`). Draw calls do not predict frame time. The grass A/B is the owner's own twenty-minute run and is the only thing that settles it. |

## 1. Git truth

- `main` was `4acfb109` (PR #78, CI green in 18 minutes) before the consolidation.
  PR #79 (`codex/four-biome-push-0907`) merges Water, the Stormwood hosted-combat wave,
  the HUD compass work, the combat/perf/visual evidence, the owner kickoff run and the
  documentation pass. Verify with `git merge-base --is-ancestor` before trusting any
  claim that it landed.
- Merge conflicts resolved by hand, worth knowing: `tools/survey.sh` kept the Water
  branch's structure but **`main`'s Compatibility renderer for Stormwood** — the Water
  branch predates PR #77 and would have reintroduced the forced-Vulkan capture that the
  Stormwood lane itself withdrew as a false blocker; `tools/net/peer_runner.gd` kept
  both sides' match cases; `CURRENT_STATE.md` and `DEVELOPMENT_ROADMAP.md` kept the
  consolidated versions.
- After PR #79 lands, every other branch is fully contained in `main` and can be
  deleted.
- CI: `ci.yml` runs on `pull_request` and on pushes to `main` only — a branch without a
  PR is never verified. A full run is 18–25 minutes. `multiplayer-wide.yml` is
  scheduled. A run under five minutes verified nothing.
- Release: `release.yml` publishes from `main`. Check the release asset timestamp
  before telling the owner a fix is playable.
- **The 33-creature batch in PR #78 has no `docs/specs/ASSET_LEDGER.md` row**, so the
  repo cannot currently state the Meshy credit balance. Lane ART-PILOT must re-measure
  with `tools/art_pipeline/meshy.py balance` and write the row.

## 2. Verified system status

## 3. Known issues, ranked by player impact

Both sections as they stood before the four-biome push (2026-09-02 through 2026-09-05) are archived at `archive/docs/current-state-history/2026-09-05-verified-status-and-known-issues.md` -- individual rows were not re-verified after that date and several are now stale in either direction (marked open but since fixed, or marked closed but possibly regressed). For current status, use `ralph/reports/FOUR-BIOME-BUILD/`, `docs/SECOND_PASS_BACKLOG.md`, and the current dated files in `docs/owner/` rather than trusting old labels in the archive.

## 4. Process findings that changed how work is verified

- Two harnesses failed at the title screen on a profile that had a save, and both
  reported it as something else entirely. `title_screen.gd` interposes a "Start a fresh
  game?" confirmation whenever a slot is occupied; `smoke_title_new_game.gd` never
  answered it, and `gate_a_opening_drive.gd` sampled for it exactly once immediately
  after the press and missed it whenever the dialog landed a frame late. The messages
  were "Start New Game carried the old Warden victory into Meadows" and "Start New Game
  never reached the configured Meadows world" — neither of which names a modal. Both now
  watch for the confirmation across the wait rather than at one instant. **An assertion
  about a later step will happily describe an earlier step's failure.**

- Raising `OBJECTIVE_LINES` 2 -> 4 to stop long objective titles truncating also
  raised the block's FLOOR, because `OBJECTIVE_BLOCK_HEIGHT` was derived from the cap:
  168.8px -> 261.6px reserved permanently, a third of the 1280x800 handheld screen held
  open for a panel reading "Win the village tournament." No test caught it — the
  truncation check only asks whether text is clipped, never whether the panel is bigger
  than its contents. **A fix measured on the case that motivated it can still regress
  every other case.** Split into `OBJECTIVE_MIN_LINES` (floor) and `OBJECTIVE_LINES`
  (cap) on 2026-09-03; the panel still grows to four lines when the text needs them.

- `smoke_title_new_game.gd` passed in CI and failed on any machine that had run
  another smoke first, because `title_screen.gd` interposes a "Start a fresh game?"
  confirmation whenever a save slot is occupied and the test never answered it. CI
  runners start with an empty `user://`; developer machines and this container do not.
  The reported symptoms were spectacular and completely misleading — "Start New Game
  carried the old Warden victory into Meadows", about a game still sitting on the title
  screen. **A green CI job is not evidence a test is environment-independent.** Fixed
  2026-09-03 by answering the confirmation, the way `gate_a_opening_drive.gd` already
  did.

- CI showed green over red or unverified code by three mechanisms in one day: a
  docs-only commit after a red one; `[skip ci]` code followed by a report push (the
  `changes` job diffed against the previous push, not `main` — **fixed this session in
  `ci.yml`**); and `RETRIES: 3` rescuing a deterministic first-attempt failure.
- Three same-day "landed" fixes from the 2026-09-01 playtest were found still broken by
  the owner the next day. "Landed" and "confirmed by play" are tracked separately.
- The owner has playtested stale release builds; check the release asset time.
- 49 % of commits in the last three days were evidence dumps; 2.8 GB of screenshots and
  telemetry were tracked. Evidence hygiene is now in `docs/AGENT_WORKFLOW.md` §8 and
  `.gitignore`.
- Six harness failures in a day were the same bug: fixed-slot inventory lookups.
- CI-TRUTH-0903: `smoke_gate_b_continuous.gd` ran in no CI job at all, not gated and
  not even known-red — verified by grepping every workflow file, not assumed. Split
  into a gating CORE run (opening through tournament readiness, the part that has
  actually passed reliably) and a `--gate-b-full-chain` continuation that stays
  workflow_dispatch-only/`continue-on-error` until the gather route and tail are
  reliable. **Verified green for real**, not read off the YAML: run
  [33750739621](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/33750739621)
  on `ralph/CI-TRUTH-0903` @ `de2540b1`, push event, 34m14s wall clock (11:37:57 →
  12:12:11 UTC) — `verify-gate-b-core` genuinely executed (not skipped) and passed on
  its first attempt in 6m47s, every other required job green, and both
  `verify-continuous-core-known-red` and `verify-gate-b-full-known-red` correctly
  **skipped** (their `if` gates on `workflow_dispatch`, and this was a plain push) —
  the known-red split is not silently gating or silently vanishing, it is doing
  exactly what its `if` says.
- CI-TRUTH-0903's gather-route diagnosis (P2 row above) was double-checked against
  `origin/main` before being committed, because a same-day poke claimed
  `ralph/MID-LAYER-0903` and `ralph/BAND1-DISCOVERY-0903` had landed and could have
  moved the scatter the diagnosis depends on. They had not: `origin/main` was still
  `46cff79e` at check time, identical to this branch's own merge-base, and both named
  branches remain separate unmerged remote refs. The diagnosis stands as verified
  against the tree it was actually measured on. Worth a re-check whenever either lane
  does land, since both touch world content near the corridor spine.
- FENCE-CORNER-0903 landed its `stick_navigator.gd` fix in three shapes before the one
  that stuck, and each wrong shape was found by full-chain evidence, not reasoning --
  worth recording so nobody re-walks the same path. Shape 1 (retreat-and-retry a stalled
  side, no persistence/abandon logic) cleared the target corner but was quickly undone by
  `_begin_detour`'s own free-space check re-firing on every retry. Shape 2 (raise
  `DETOURS_PER_SIDE` 3→10 flat) cleared the corner but broke a shorter, previously-
  reliable leg near RoadGate (wood at (16,-28), 2 separate full-chain runs) whose travel
  budget cannot afford ten growing attempts down a wrong side. Shape 3 (a progress-based
  abandon check, uncapped growth, no exit-early check) cleared the corner AND the (16,-28)
  leg reliably in isolation, and 2 of 3 full-chain runs cleared the entire gather route --
  but the 3rd's own isolated repeat measured a real, if rare, failure mode: a walker that
  had already cleared the corner rode one long, uninterrupted detour 40m further and
  landed 122m off the straight line, because nothing told it "you have gone far enough,
  stop." A one-shot "is the way to the target clear" check fixed that but broke something
  else (measured, not assumed): near the tournament board's close-packed geometry, well
  before TrailGate, a single lucky-looking clear reading cancelled a detour still
  genuinely in progress, and the resulting cycle was worse than the original bug (678-686
  side flips, stuck before ever reaching the corner this file exists for). The shape that
  shipped requires that same clearance check to hold for `CLEAR_AHEAD_FRAMES` (20)
  consecutive frames, not one instant -- long enough that open terrain past a cleared
  corner reads clear the whole window, short enough that a momentary gap near the board
  does not fake it. Final verification: 8 consecutive green isolated corner runs, 4
  consecutive green (16,-28) runs, and 2 of 2 full `smoke_gate_b_continuous
  --gate-b-full-chain` runs attempted after this shape landed cleared the ENTIRE gather
  route with no per-node failure at all -- each then hit a DIFFERENT downstream finding
  (the two new tail/walk-back rows above), reached for the first time only because this
  fix gets the route that far. Both those downstream findings are recorded, not fixed --
  outside this lane's scope. Two earlier, unrelated flakes were also seen and are not
  regressions: the OPENING's tutorial catch camera line (the P1 row above, pre-dates this
  lane, reproduces identically on the unmodified navigator) and one single wood-node miss
  at (36.0, -16.0) under an intermediate (now-superseded) shape of this fix, not the
  shipped one.

## 5. Gate status

- **Gate 0 (reset):** this session; see `docs/CLEANUP_MANIFEST.md`.
- **Gate 1 (first session):** open, and much closer. `smoke_gate_b_continuous` now plays 22 minutes continuously — opening (orb floor held, correct two-creature party), village, tools, tournament readiness, gathering, tent/campfire/bedroll — against an opening that dead-ended this morning. Of the two failures it then reported, one was the harness (objective rungs asserted by prose that never existed; now asserted by id) and one is real and important: the interact-reliability game-breaker, reproduced in-container for the first time (see §3). Every other Gate 1 acceptance smoke is green on first attempt.
  combat, tournament, village. Red: opening orb floor (fix pending landing), objective
  chain after tournament readiness, gather route, South Bridge traversal on first attempt.
- **Gate 2 (core world complete):** **task list complete; the gate FAILS its acceptance, with
  scoped follow-ups.** 2.1 through 2.7 all landed (2.1 composition plan, 2.2 MID-LAYER, 2.3
  TREE-SILHOUETTE, 2.4 CREATURE-LEGIBILITY, 2.5 BAND1-ECOLOGY, 2.6 BAND1-DISCOVERY, 2.7
  NIGHT-LEGIBILITY; see §3 for 2.4's and 2.7's measured close-outs). **2.8, the evidence run, is
  now done** (`ralph/GATE2-EVIDENCE-0903`, from `main` `3c73aab5`); its full report, the four
  blockers it had to fix before the route could be played at all, the dead-travel list, the
  proposed correction to the gate's own acceptance bar and the follow-up task list are in
  `ralph/reports/GATE2-EVIDENCE-0903/REPORT.md`, with the code-blind judge in `JUDGE.md` beside
  it. Verdict and evidence template below.

  **The route was played continuously for the first time:** Gate F `S04` (tournament sign-up,
  three bracket rounds, champion line) and `S05` (village → band 1 spine → the Pond → the Old
  Bram detour and its fight → Trail Camp → South Bridge gatekeeper → gate opened → crossed),
  1,169 s of play clock, 2,360 m walked, **S04 82 P / 1 F and S05 106 P / 1 F**. Both remaining
  failures are one stale instrument threshold (`route_rows_at_least` describing segment
  durations neither segment has any more), not game defects. Entry state was seeded from the
  freshest *played* S03 exit save with its party levelled to `tournament.json`'s entry floor
  through the real level arithmetic — the same allowance `smoke_gate_b_continuous` makes in CI,
  recorded in `tools/gate_f/build_gate2_seed.gd`; everything from the sign-up onward is played.

  **Evidence template.**
  - *Player purpose:* win the tournament, then take the team south to the chapter's first
    physical gate. The visible challenge is Team Tether holding the South Bridge; the
    gatekeeper's own fight yields the key, and the player is never told a level requirement.
  - *Team progression:* in at 5 × L5 rested and fed; out of the tournament at L7/L6/L7/L6/L7
    with eight level-ups and **three of five on 0 HP**; across the bridge at L7/L7/L7/L8/L8.
    Mid-fight rotation happened at both fights, but **no catch and no keep-or-release decision
    occurred on the direct route**, so 2.5's "at least one roster decision in play" is only
    half met — scoped as 2.12.
  - *World interaction:* 4 fights, 5 resource stops, 3 landmark discoveries, 2 objective
    transitions, one optional detour taken and won, one care action, one build. The harness's
    POI meter reset ten times over 2.26 km — roughly one point of interest every 220 m.
  - *Empty travel:* **two intervals over 60 s, both marginal** — 63 s / 346 m from the village
    gate onto the band 1 spine (t 192–255), and 71 s / 427 m from the Trail Camp to the bridge
    approach (t 579–650). Nothing over 75 s anywhere. Both classified intentional breathing room
    at the top of their range; the second is the weaker, being the approach to the chapter's
    first gate. Listed with start/end coordinates in the report; computed by
    `tools/gate_f/dead_travel_intervals.py`, added because `chain_pacing.py` reports only the
    single worst gap per segment.
  - *Reliability:* no freezes, no input loss, no save/load failures, no bad collision on the
    played route. Both segments wrote and reloaded exit saves through the production Save tab.
  - *Presentation:* **both bar questions answered no** by a code-blind pass on 16 frames taken
    from the played route's own 2 Hz trace (gameplay camera, HUD on, real positions and
    headings) rather than posed stands —
    `ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md`, 16/16 frames non-degenerate. Same verdict as
    MID-LAYER's and TREE-SILHOUETTE's judges, reached from different frames, and it finds four
    things no posed set could: the **HUD is in frame and judged** (food bar outside a 5 % safe
    area, objective/action/interact hierarchy that does not separate, an interact pill covering
    the object it names); **the South Bridge is visually unbuilt** — a bare plank frame, no gate,
    no banner, no guard, for the chapter's first physical gate; **the oxblood reservation is
    broken**, leaked onto village roofs, tree trunks and friendly HUD icons while the Team Tether
    grunt wears unrelieved black; and **Bramblebun reads candy pink in daylight**, independently
    corroborating §3's open item that 2.4's `field_emission` 0.9 → 2.5 overshot — the ledger knew
    only about night. Trees measure ~2.3× the 1.80 m trainer on redwood-thick trunks with no
    branch structure below the canopy. Two of the judge's findings are **my instrument, not the
    game**, and are recorded as such in the report: the capture lane teleports to a traced
    position without restaging, so its two creature-forward stands show empty ground where
    telemetry proves both fights ran, and it never deploys a companion. The deeper point stands —
    four blind passes running have been unable to see the thing the game is named after, scoped
    as 2.15.
  - *Decision:* **FAIL.** Passes on dead travel, on the perf proxy, and on reliability of the
    played path; fails on presentation and on the roster-pressure clause.

  **Perf proxy re-confirmed:** `band1_open` **6,891 draws / 10,788,459 primitives / 5,922
  objects** against the ≤ 7,500 / ≤ 12.0 M budget — GRASS-CULL-0903's 6,897 / 10,803,803
  reproduced to within noise.

  **Four blockers were fixed to make the route playable, and three had been failing silently
  since 2026-08-30:** (1) `S04` walked to a marshal coordinate that was already satisfied from
  the bracket board, leaving the player 4.6 m from Halda — fourteen blind interact presses, no
  dialogue, `tournament_entered` never set; (2) the three rounds still used one greeting and a
  fixed press count against TOURNAMENT-FLOW-0903's two-greeting rounds; (3) the bracket board's
  own read-out was never closed, so the Save tab never opened and the segment wrote **no exit
  save**; (4) with a fully healthy party **both** route fights refused to start, because the
  active creature is deployed straight after the load while it is still on 0 HP from the
  tournament final, and `encounter_director.gd::can_challenge()` needs a live ally body —
  `south_bridge_open` could not be earned at all until a `creature_recall` press was added after
  the revives. Owner instruction 2026-09-03 ("give revives after the tournament") is implemented
  as a production-menu recovery block asserted by the satchel dropping 10 → 7 Revives.

- **S08's Ironwood freeze (CL-H14) is closed — root-caused and reproduced, W03-S08-FREEZE-0904 —
  and Gate 2's Pond stall (2.9) has the same signature but was NOT re-measured here.** S08-22 pinned
  at **(−164.12, −9.13, 4334.56)** for its whole 45,000-frame budget on two runs, which is why Band 4
  had no evidence. W03-S08-FREEZE reproduced it a third time and measured the mechanism: **the body walks head-on into a tree**. At frame 1474,
  travelling 5.00 m/s, the capsule contacts `CommonTree_2_Collision` with normal `(0.33, 0.00,
  −0.95)` — dot **−1.00** against its own travel, so `move_and_slide` has no tangential component to
  turn into a slide, and velocity goes to exactly zero and never changes again. The world is fine:
  ground 1 cm under the feet, `on_floor` true every frame, rays from +1 m and +3 m both hitting
  `Terrain` at the body's own height, the camera rig 1.7 m away throughout (collision is streamed),
  the ally 10.2 m off on layer 0, `unstick_count` 0 because `_entombed_at()` correctly answers
  "pressed against something, not sealed in it". What pinned it was the WALKER: `_detour_stalled()`
  flipped `_side` **and zeroed `_side_detours`**, so the counter never passed 1, `DETOURS_PER_SIDE`
  was never reached, `_back_off()` never fired, and the walk ran a closed 41-frame cycle at exactly
  zero displacement to the end of its budget. **The fix was already on `main`, and had been sitting
  in an unmerged pull request the whole time it was being investigated:** FENCE-CORNER-0903
  (`c64af25f`, landed as #30 / `65fc6625`) abandons a side on measured progress instead of a
  resettable attempt count. Proven by swapping only the walker on today's tree — the frozen
  pre-fix copy pins at the recorded coordinate to the centimetre and 747.6 m short, the live walker
  **arrives (839.5 m, 10,907 walking frames, 0 held)** and the segment runs 12 steps past S08-22.
  It also explains why the site's own probe said the world was clear: the trap is **dynamic**. Four
  teleported starts at the Ironwood site — the freeze coordinate itself included — all walk out. A
  *placed* body is never stuck; only one pressed into geometry by its own motion is.
  **About the Pond stall (2.9), stated as the inference it is:** it carries the identical signature
  (body pinned to the centimetre at (−328.7, −14.2, 505.3) for 543 play seconds over three runs,
  locomotion enabled, "0 held"), and `probe_pond_stranding.gd`'s "0 of 10 stands wedged" is exactly
  the placed-body result above — so the same mechanism very likely explains it, and the same landed
  fix would cover it. **This lane did not re-run the Pond leg**, so 2.9 stays open on its own
  evidence rather than being closed by analogy; re-running it against
  `probe_s08_freeze_legacy_navigator.gd` and the live walker is a cheap way to settle it. **Residual, not fixed:** `_free_space()`'s lowest
  probe ray sits 45 cm up and this geometry is below it, so the walker still cannot see what stops
  it and escapes only by noticing it made no progress — recorded for the walker's next owner in
  `ralph/reports/W03-S08-FREEZE-0904/REPORT.md` §7 with the measurement that would justify a
  foot-height ray. The Pond leg's own authored climb-out (`S05-32x`, 23 s instead of 543) stands.

- **Gate 3 / 4:** not started. Gate F S03 reached 6 failures outside its lane's scope;
  S04–S10 unverified as a chain.

## History

Dated checkpoint sections that used to live in this file are under
`archive/docs/current-state-history/`:

- `2026-09-06-stage-b-multiplayer-code-complete.md`
- `2026-09-06-stage-b-waves-1-3-superseded.md`
- `2026-09-05-stage-b-wave-0.md`
- `2026-09-05-06-owner-list-pass.md`
- `2026-09-05-active-cloudreach-branch.md`
- `2026-09-04-codex-exit-note.md`
- `2026-09-05-git-truth-as-recorded.md`
- `2026-09-03-04-reset-branch-lanes-4b-4c-4d.md`
- `2026-09-04-05-cloudreach-checkpoints-1-7.md`
- `2026-09-06-art-rounds-warrens-hall-machine-cloudreach.md`
- `2026-09-05-verified-status-and-known-issues.md`
