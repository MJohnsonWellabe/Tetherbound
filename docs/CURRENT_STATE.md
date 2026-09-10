# Current state — evidence-backed, 2026-09-07

**Slimmed 2026-09-07.** This file is the live status. Every dated checkpoint section
it used to carry is under `archive/docs/current-state-history/` (list at the end).
Findings go in §3, ranked by player impact; process traps in §4.

## 0. Where the project is (2026-09-09, playable build in progress)

**Latest validation — 2026-09-10 11:38 UTC:** full CI at `ba11f58d1` passed
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

Method: 1728 unit tests (`tests/run_tests.gd`, 28.5 min, **0 failures**) and the
player-path smoke chain run one test at a time. Classification per the audit brief.

| System | Status | Evidence |
|---|---|---|
| Route strip / creature evidence (2.15, CL-H9) | **Working in-container; GPU strip not yet run** | `tools/_capture_route_strip.gd` summons the party's active creature through `CreatureSpecies.spawn` + `Game.party.add` + `EncounterDirector.summon_active_creature`, stands trainer and companion side by side on every road stand, enters one real `CombatManager` fight per band through the interact press, solves the fight camera against trainer, companion and opponent (`capture_check.fit_distance`), and refuses any frame `capture_check.readable_problems` faults (empty, behind, < 12 % of frame height, cropped, occluded, overlapped on screen, or a > 50 % close-up in a fight). Fight cleanup is unconditional, waits past `combat.json`'s 0.25 s input guard, and asserts `gate_f_probe.input_context() == "world"`. Bounded xvfb run `--bands=1 --max=3 --fast`: 3 road frames + 1 fight frame, 0 refused, exit 0 (`ralph/reports/W01-ROUTE-STRIP-0904/REPORT.md`, `_sheet_route_strip.png`, blind verdict there). `tests/test_capture_check.gd` 18 tests, the readable rules seen red when weakened. The refusal is also the finding: a refused frame is listed in `manifest.json` under `rejected` and the run exits 1. The GPU strip (owner kickoff) has not run since this landed. |
| Title / new game / load game | Working | `smoke_title_new_game`, `smoke_title_load_game` pass |
| Opening (wake → Grandpa → starter → first catch → exit house) | **Working but rough** | `smoke_opening` passes; `smoke_gate_a_opening_segment` **failed** on `main`: the tutorial orb floor was gated on the enemy being a Bramblebun, and the real interact press engaged a Mudsnout, so a player who throws their last orb before the first catch dead-ends. Fixed this session in `scripts/story/sequence_director.gd` (gate on the opening beat, not species); re-run pending at time of writing |
| Menus, modal stacking, post-modal control | Working | `smoke_post_modal_control`, `smoke_modal_stacking`, `smoke_menu` pass; the input-owner group contract is the mechanism (`scripts/ui/input_owner.gd`) |
| Building (house, camp split into tent/campfire/bedroll) | Working | `smoke_gate_a_build_house` passes; camp split verified by real placement probe on 2026-09-02 *(reported)* |
| Rest (creature bed, player bedroll, torch) | Working | `smoke_gate_a_rest_torch` passes; rest-progress indicator landed `c98998fa` |
| Catching (aim, throw, slow-mo on target) | Working | `smoke_catching`, `smoke_party_count_after_catches` pass |
| Combat (real-time piloted) | Working | `smoke_combat` passes; `test_combat_*` green |
| Combat and reward VFX (CL-A2, W09-VFX 2026-09-04) | **Landed (PR #45), judged twice; the two findings W09 routed are fixed on `ralph/N07-VFX-POLISH-0905` (D87)** | Hit spark tinted by element and sized by damage, per-instance body flash, KO puff, catch sparkle, 1.5 s level-up flourish (beam, rising rings, motes, rim) — `scripts/vfx/`, `data/config/vfx.json`, hooks in `combat_manager.gd::_flash_at`/`_finish_catch`. `test_combat_vfx.gd` 8/8 (seen red with the hook removed); `smoke_combat`, `smoke_boss`, `smoke_trainer_battle`, `smoke_catching`, `smoke_combat_camera` green, benign `ERROR:` set unchanged. Round-1 blind judge: effects invisible at thumbnail, no hot colour, ring read as a stun — retuned (saturated tint, white-hot birth, contrast halos, wide gold rings, real beam). Round-2 verdict, frames and the band1_open draw-call delta: `ralph/reports/W09-VFX-0904/REPORT.md`. Level-ups are found by polling `Game.party` until the progression feed lands (seam in place); bench level-ups have no world flourish (D80). **N07-VFX-POLISH (2026-09-05, D87):** the wind-up ring's `#ff5a3c` sat inside the reserved oxblood band and, drawn without a depth test, was painted through the ally's back — now magenta `#ff40e6` (hue 308°, the meadow's complement, 31°+ of hue from every reserved oxblood; a round-1 amber was read by the blind judge as the reward gold, "a dropped coin"), depth-tested and lifted 0.08 m in `telegraph_glow.gd`; measured reserved-band footprint over a control frame 11,208 px → 559 px, and the ring is the only magenta in the frame. `catching.json` `vfx.caught` was a 2.76 m disc in front of a camera 2.4 m from the orb (edge to edge, khaki) — now a 1.0 m gold bloom (radius 1.2×1.15 → 0.5×1.0, 0.55 → 0.45 s; a 0.75 s trial was judged to veil the orb and reverted); pale wash outside the ally 14.0 % → 0.9 % of the frame at the seal's peak. Both blind judges still want `impact_flash.gd`'s primitive replaced (camera-facing no-depth ring, hard spikes) — the ceiling for a config-only retune. `test_telegraph_glow.gd` 2/2 guards the band and the depth test (seen red with both reverted); `test_combat_vfx.gd` 8/8, `smoke_combat`/`smoke_catching`/`smoke_trainer_battle`/`smoke_boss` green (one `smoke_boss` red under a concurrent software render, the known "exploration never came back" race after a won Warden fight, green alone — see the report). Before/after sheets and the blind A/B verdict: `ralph/reports/N07-VFX-POLISH-0905/`. Still open there: `impact_flash.gd`'s nine hard spikes (shared by every attack; not softened), and `orb.gd`'s ground halo rendering as a hard-edged quad in the resolve close-up. |
| Combat (real-time piloted) | Working; **baseline retuned 2026-09-04 (W23-DIFFICULTY, D77)** | `smoke_combat` passes; `test_combat_*` green; `tests/smoke_combat_baseline.gd` measures the shipped danger at every band's entry and asserts `chapter_curve.json` `difficulty` |
| Tournament | Working | `smoke_tournament_bracket` passes: enter, lose, retry, three rounds fought, win (194 s) |
| Trainer rules (challenge prompt, no fleeing a trainer, level gate) | **Working** — `ralph/W10-TRAINER-RULES-0904`, the three 2026-09-04 owner amendments A-1/A-2/A-4 | **A-2, the confirmed defect, is fixed:** `trainer_npc.gd::_prompt_for()` was unconditional, so every beaten trainer in the chapter went on advertising "Challenge <name>" for a fight `can_challenge()` had already decided to refuse. It now reads `prompts.defeated` ("Greet %s" — never "talk"/"choose", the `smoke_opening` trap), and `_process()` relabels an already-placed body the frame its defeat flag flips, because the label is resolved at build time and stored. **A-1:** a trainer fight cannot be walked out of — both disengage bindings are refused with "You can't walk away from a challenge."; a WILD fight keeps its exit exactly as it had it, so no unwinnable encounter is sealed; total-party faint remains the only other way out (`test_combat_progression::test_trainer_fight_still_ends_once_the_whole_party_has_fainted`, 18/18) and the tournament's post-loss retry is untouched (`smoke_tournament_bracket` OK, all three rounds). **A-4:** an optional per-trainer `min_level` is a fifth reason `can_challenge()` is false, measured against the party's highest-level creature (D79); the trainer plays the shared `trainer_too_low` conversation with the owner's own taunt and the level named through `$level`, and a too-low player never hears the already-defeated line. **No shipped trainer carries a `min_level`** — density lands first. Verified 2026-09-05: `test_trainer_rules` 15/15 (214 assertions; every behaviour watched red first, in 12 separate breaks), `test_trainers_data` 50/50, `test_encounter_combat_override` 5/5, `smoke_trainer_battle` OK with the prompt read off the live `Interactable` before ("Challenge Bryn") and after ("Greet Bryn") the win, `smoke_opening` OK, `smoke_trainer_no_usable_ally` OK. **The brief's "hide the disengage glyph from the combat legend" is a no-op today:** `combat_hud.gd` draws four verb cells (quick/charged/throw/switch) and no disengage cell, and `playground_hud.gd`'s exploration legend is hidden for the whole fight — nothing advertises the button, so nothing was hidden |
| Village, NPC dialogue, trade | Working | `smoke_gate_b_continuous` reaches "visited the village and came away with tools" |
| Objective chain after tournament readiness | **Broken (harness-confirmed)** | `smoke_gate_b_continuous` fails: with `tournament_team_ready` and `tournament_training_ready` set, the tracked objective still reads "Gather supplies for your team's camp." instead of advancing to the "Gather wood" beat |
| Gather route navigation | **Working but rough** | same smoke: the controller could not reach authored wood at (16, −28), stopped 23 m short. Walker or authoring issue; the harness walker is known to fail on village walls |
| Traversal / South Bridge | **Sound; the entombment was the harness, not the crossing** | Re-opened and then explained on 2026-09-03. `smoke_traversal`'s new site guard (`_assert_south_bridge_site_sound`) was intermittent — 1 failure in 3 locally, 3 in 3 on CI — and once it printed coordinates the red run resolved to a body resting at (7.90, −3.60, 1319.0) against a `ground_height_at` of −2.90: sunk 0.7 m INTO the ground it was placed a metre above, which is why all eight compass probes were correctly sealed. The cause is the teleport. `playground_world.gd` runs Terrain3D in Dynamic/Game, so collision shapes exist only in a radius around the camera; the guard drops the body 1.3 km from the previous check and the camera rig follows the player rather than snapping to it, so for the frames while it catches up there is no terrain under the site and the body falls through before the shapes arrive around it. Slower hardware loses that race every time. No player reaches that state on the real path — they walk to the bridge and the collision radius travels with them — so the guard now holds the body at the placement until a downward `test_move` finds ground, then settles and asks the original question. 4 of 4 runs green after, 2 of 3 before. The crossing's geometry was never changed and never needed to be |
| Burrow Warrens | **Working; room re-lit and dressed (CL-O7 / CL-E8, W07-WARRENS-0904, 2026-09-05)** | Owner OP-0904-7 "looks terrible" reproduced on five walked-path stands at eye height by day with no torch (`tools/_capture_warrens_0904.gd`): a blind judge ranked eight room defects (`ralph/reports/W07-WARRENS-0904/JUDGE-before.md`), the first being no light structure at all — measured, `art.json`'s day sky ambient (1.9) lit every interior surface at one level under the Compatibility renderer and the authored pools were a few percent on top (frame 02 luminance p5/p50/p95 8/46/67). Also found: a full baked `CommonTree` standing in the guardian's den (the 30 m site clear is measured from the mouth; the den is 40 m in). Fix: a `ReflectionProbe` interior constant-colour ambient gated by `reflection_mask` to a cave-only visual layer (verified 133 → 17 wall luminance in isolation), pools re-authored with dark passages, DeadTree crowns as root masses, glowing Mushroom clusters as passage beacons, leaf litter, distant haze halos, deposit glow, per-chamber scatter clear, mouth reveal off under a root fringe. Round-2 frames on the same stands: frame 02 3/30/89 (value range 86 vs 59), den frame 04 with a shadowed warm key and no tree; blind after-verdict in `JUDGE-after2.md`. `smoke_warrens` green with new real-behaviour checks (180 leak rays, 0 leaks; probe/layer gating; body layer hand-off; dressing collision-free and above 1.9 m). CL-G7 root-caused (dangling per-body override material at `creature_body.gd:492`; patch in the lane report, not applied). Remaining, recorded in the report: the cave is still axis-aligned boxes (R2, needs cave modules), one granite photo (R3, needs a dug-earth material set), the mouth is a rectangular cut, and the torch is off by day inside the cave (`torch.gd` only lights on `is_dark()`). |
| Tether Relay (captain, captive, Gear, village follow-up) | Working | `smoke_relay` passes (402 s) |
| Stronghold and Gate E finale (Warden, legendary, ceremony) | Working (scripted); **restaged 2026-09-04 (W06-FINALE-0904)** | `smoke_stronghold`, `smoke_gate_e_finale`, `smoke_stronghold_reload`, `smoke_finale_persistence` pass on the branch (see §4d for the run record); the endgame dialogue is cut to a handheld budget, the legendary stands inside the machine and steps out of it, the Hall's garrison withdraws on `legendary_freed`. Never played as a continuous chapter (Gate F S04–S10 unverified) |
| World stand-up, riding, settings | Working | `smoke_playground` (334 s), `smoke_riding` (336 s), `smoke_settings` (358 s) pass |

Smoke chain total: 22 run, 20 pass, 2 fail (`gate_a_opening_segment` on `main`, fixed on
this branch and re-run green; `gate_b_continuous`, open).

Smoke isolation finding: `smoke_title_new_game` fails whenever an earlier smoke has left a
real `user://saves/slot_0.json`, because the title then shows the returning-player
confirmation and the test never answers it. It passed on a clean profile and again once
the other smokes' saves were moved aside. Smokes that write real saves should use their
own `user://` subdirectory (most already do) or the title smoke should answer the prompt.
| Save / load | Working | `test_save_format`, `smoke_save_persistence`, `test_autosave_fallback` green. **Correction 2026-09-05 (N01-SAVE-FORMAT):** five of `test_save_format`'s tests (the 26-RG19 tournament-across-a-save section and both condition tests) had read `ok` since 2026-08-22 without any assertion running — they called `saver.save_game()`/`load_game()`, which exist on `Game`, not on `save_game.gd`, so each method aborted on a SCRIPT ERROR the runner does not see. Repaired on the saver's real API, each seen red under a loader mutation, and the file is green with every assertion executing. The save format itself was sound throughout; the gap is that `run_tests.gd`/CI cannot tell an aborted test from a passing one, and the same grep over a full-suite log shows **five more such tests in `test_shiny.gd`** (its `_roll()` helper calls `_roll_wild_level` with the wrong arity; the shiny roll currently has no working coverage) — see `ralph/reports/N01-SAVE-FORMAT-0905/REPORT.md` |
| Day/night | Working in engine | three real-frame probes pass *(reported 2026-09-02)*; owner reported it stuck on hardware — see §3 |
| Save / load | Working | `test_save_format`, `smoke_save_persistence`, `test_autosave_fallback` green |
| Day/night | **Clock and night look both verified; night is still hard to reach** | N13-NIGHT-RESUME-0905. The clock is healthy on the **exported release binary** (`art.json` loads from the .pck, cycle live, config identical to the editor's) and midnight renders at **26% of midday's mean frame luma**, blind-confirmed as night. Two real defects fixed in data: `is_dark()` ran 225s of a 600s day across dusk AND dawn (now 125s, 22→3), and the `night` keyframe stood alone so the tuned night look was never held (now held 75s, hours 23→2). **Still open and routed:** nothing saves the clock, so every load, realm crossing and rest restarts it at 08:00 — see §3 |
| Bond and level progression, made visible (CL-W6) | **Working, exercised end to end** | W13-PROGRESSION-FEED-0904. One progression feed on `Game` (`scripts/creatures/progression_feed.gd`) carries `xp_gained`/`level_up` from `creature_instance.gain_xp`/`gain_levels` and `bond_credit`/`bond_near`/`bond_milestone` from `bond_milestones.credit()`, the only writer of a bond counter; the party strip ticks (xp sliver, bond pip, '+bond · fed'), the world HUD draws a Moment banner (queued behind a fight, collapsing two within 5 s, with a sound cue) and an 'N to Lv M' line, and the Team screen shows every bond task with one NEXT and the next node's benefit. **D76: the bond ladder is unordered** — any completed task is a node, so all five actions read immediately. Evidence: `tests/smoke_progression_feedback.gd` drives a real won fight, a Satchel meal, a landmark discovery and a night in a placed bed and reads the presenters back; `test_progression_feed`, `test_bond`, `test_level_up_announcement` (rewritten to RUN the builder), `test_candy_progression_safety`, all seen red first. |
| Party cycle, riding, map | Working (unit level) | unit tests green; not exercised by this session's smokes |
| World density and findables, bands 4–5 (CL-O4 density half; W18-DENSITY-B4-B5, `ralph/W18-DENSITY-B4-B5-0904`, 2026-09-04) | **Authored and measured; not yet played** | Measured with `tools/_probe_band_density.gd` (authored census per km of each band's own spine, plus every new site validated on the real world: Terrain3D ground, 2 m pad slope/spread, solid scatter, river, ≥4.5 m from every other prompt) against band 1's 28.3 spawn clusters/km and 16.6 harvest/km. **Band 4** (3436 m): 81→91 clusters (26.5/km, 309 creatures), 26→45 harvest (13.1/km; ironwood also at the Highfield fork and the watchtower spur; berries for the first time above the river), 40 one-time pickups (16 Good / 9 Great / 4 Rare candy + 3 revives, 5 potions, 3 mushrooms; 6 on the road, 34 off it — the band never had a spine-gap problem (worst authored gap 110 m, unchanged), it had a reasons-to-leave problem, which the off-road finds and the deep-branch Rares at Rue, Stormtrail, the herd bull and the spur corner answer). **Band 5** (651 m, D70 short on purpose): road untouched (P-5.3, D78); +1 off-road cluster, +2 off-road harvest, 15 pickups (7/3/1 + 4 recovery) at the outer watch, the alpha pack, the scorched pocket, the gate wing, the waystop dell and the doorstep alpha; nothing inside the waystop clearing (R-5). Every row carries a `why`; recovery sits before the two captains, the rest-free climb (P-4.1) and the seam, never after. Captains, Sigil gate, herd bull (P-4.3), Stormtrail, Rue, the R-3 alpha and Ness untouched. `test_band_pickups` 20/20 over all four authored bands (seen red first: a Rare moved to the road and a duplicated id both fail), plus the spawn/harvest/band-content suites and the world smokes listed in `ralph/reports/W18-DENSITY-B4-B5-0904/REPORT.md`. Bands 2–3 are W17's lane; band 1 is another lane. What this does not prove: that a player *feels* it — the addendum's §C route-evidence questions (do side routes pay better than the road, do potions/revives erase camping pressure) are Gate F evidence, not census output. |
| Bond milestones, level-up feedback, party cycle, riding, map | Working (unit level) | unit tests green; not exercised by this session's smokes |
| Companion presence (the deployed creature reacts to its situation) | **Working; judged in isolation, not yet over a continuous segment** | Landed 2026-09-04, lane W12-COMPANION-0904 (addendum section E / owner directive C section 5). `scripts/creatures/companion_presence.gd` + `data/config/companion_presence.json`, built and ticked by `follower_creature.gd`: acknowledgment of a still trainer, a post-victory reaction on the fight's result beat, a hurt/tired gait and flinch, a camp settle beside a lit fire or bed, a care response after feed/heal/revive, and a bond-milestone moment; bond warms delay, cooldown and hop count. Every reaction is cut by a fight, aim, ride, menu, live prompt, lockout or build ghost. `tests/test_companion_presence.gd` (26 tests, 132 assertions) drives a real rigged follower body and was seen red for the right reason on each behaviour. Evidence and the blind verdict: `ralph/reports/W12-COMPANION-0904/`. **Not yet evidenced:** addendum section E asks for *multiple* contextual moments arising naturally across a continuous segment; the captures stage one moment at a time, so the continuous claim is unproven. D83 records the design calls |
| Performance on the ROG Ally | Unable to verify | no container can measure it; perf proxy: band1_open 6897 draws / 10.80M prims (measured 2026-09-03, `tools/perf_render_stats.gd`; GRASS-CULL-0903: was 6947 / 11.79M after MID-LAYER-0903's vegetation additions — tile culling now actually excludes tiles; see §3) under provisional budget |

Content that exists: 25 species (1 evolution line with 2 branches, 1 legendary), 48
moves, 14 TMs, 56 items, 16 recipes, 11 buildables, 20 building prefabs, 152 harvest
nodes, 101 authored world pickups (bands 2–5), 19 village NPCs (13 present at once), 130 conversations / 339 lines, 29 field
trainers, 294 spawn-table entries across 5 bands, 12 landmarks, 33 objectives, 3
tournament rounds, 1 boss. Full tables: `docs/WORLD_AND_CONTENT.md`.

## 3. Known issues, ranked by player impact

**Reopened or added by the owner's 2026-09-07 playtest (`docs/owner/OWNER_PLAYTEST_2026-09-07.md`); these outrank every struck row below:**

| Rank | Item | Status |
|---|---|---|
| P0 | **Hard freeze placing a second creature bed** on the Ally, no return to menu. Strongest static lead: a re-entrant ledger loop from multiplayer lane 5.A (`f428ba02`): `build_placer._settle_placement` → `home_progress.maybe_set_creature_beds` (no `has()` guard) → `_grant_player_flag` (never refuses) → synchronous `delta_applied` → `sequence_director._share_the_camp` on every delta → again; branching factor equals beds standing. Full read: `docs/prompts/77-CODEX-GOAL-four-biome-push-2026-09-07.md` §STAB-LEADS. | OPEN — lane STAB |
| P0 | **Repeated freezes in the first ten minutes** of a fresh game on the Ally. Leads: `restore_all` on every world-flag delta, the 180 s same-frame autosave, first-sight GL shader compile and synchronous species GLB loads, the first map bake. | OPEN — lane STAB |
| ~~P1~~ | ~~**Bare road stretches with no creatures in view.** Owner bar: multiple creatures in the forward 180° at all times.~~ | **closed functionally 2026-09-07 — ROAD-VISUAL-CREATURES.** The production GDScript probe covers all 36 critical routes at 10 m intervals (4,253 samples) and reports zero samples below two creature bodies in the forward 180°; 12 production frames across all four biomes each contain at least two forward and camera-framed bodies. The fitted size ladder is 1.90–7.20 m, above the 1.80 m trainer. Independent visual judgment still rejects pileups, crops and individual palette/silhouette readability; that cosmetic work is recorded, not hidden, in `docs/SECOND_PASS_BACKLOG.md`. Evidence: `ralph/reports/FOUR-BIOME-BUILD/road-visual-creatures/REPORT.md`. |
| P1 | The 32 new Cloudreach/Stormwood/Water species are in no spawn, encounter or trainer table; the chosen playable character is not persisted and remote peers render the local body. | OPEN — lane ROSTER |
| P0 | **The save layer was rewritten and now governs every save in every biome**, arriving with Water and unproven by its own author. `scripts/save/atomic_save_file.gd` + `world_save.gd`/`character_save.gd`/`save_game.gd`. | OPEN — lane SAVE |
| P1 | **The minimap is gone and the map's second open is corrupt** on the real Meadows world — terrain and fog lost, unrelated glyphs fragmented, confirmed in OS-composited pixels. `scripts/ui/tab_map.gd`, `compass_bar.gd`. | OPEN — lane HUD-MAP |
| P1 | **Stormwood hosted combat is on `main` and does not work**; it also changed shared `scripts/net/session.gd` without the full suite its own handoff required. `smoke_net_stormwood_hosted_trainers.gd` fails at trainer start. | OPEN — lane STORMWOOD-HOSTED |
| P1 | **Water cannot be entered by ordinary play**: no production emitter for `aftermath:waterward_view`, no Water transition point, and a late joiner can be permanently denied the Swim Stone. | OPEN — lane WATER |


P0 blocks normal play. P1 major. P2 significant quality. P3 polish.

| Pri | Issue | Where | State |
|---|---|---|---|
| **P0** | **The released Windows build has no vegetation scatter at all.** The pack built 2026-09-02 22:12 contains `data/scatter/playground/manifest.json` (a `.json` is a Godot resource, so `all_resources` exported it) and **none of the 256 `region_*.bin` files** (not resources; `include_filter` was empty). `scatter_bake.gd::is_fresh()` saw the manifest and said fresh; `load_all()` failed to open every region and returned empty layers; the world built with no tree, bush or rock anywhere. This is the owner's "empty meadow in every direction" and very likely the earlier "no trees" and "grass didn't render" reports too. Every in-editor test passes because the editor tree has the files; `tools/verify_export.sh` checked the terrain bake and two JSON files were packed, not the scatter. Confirmed by downloading the release asset and reading its pack (`region_` strings: 0; `manifest.json`: 1). | `export_presets.cfg`, `scripts/world/scatter_bake.gd`, `tools/verify_export.sh` | fixed 2026-09-03: `include_filter="data/scatter/*.bin"` on both presets; `is_fresh()` now requires every region file the manifest names to exist (otherwise the live-compute path runs); `verify_export.sh` fails when the pack holds fewer region files than the manifest names or the build logs a missing region. Local `Linux Test` export after the fix packs 256 of 256 region files (the release had 0); `tools/verify_export.sh` passes on the fixed export: the exported binary reports `scattered 385191 props in 35 batches`, where the released build scattered none |
| P0 | Tutorial catch can dead-end with zero orbs if the first wild fight is not the Bramblebun | `scripts/story/sequence_director.gd` | fixed this session, pending re-run and landing |
| P0 *(owner)* | ~~Interact works "about half the time"~~ | `scripts/player/tool_hold.gd::swing_at()`, `scripts/world/harvest_logic.gd` | **root-caused and fixed 2026-09-03; needs an owner confirmation on hardware.** Reproduced in-container for the first time by `smoke_gate_b_continuous` run 2 of 3 (axe equipped and in hand, arbiter winner the node's own Interactable, `cooling=false`, no swing) while run 1 passed the same step. The mechanism: with a swing already running, `swing_answers_the_prompt()` claimed the press on the reasoning that "that swing resolves on its own and will gather something itself" — but `_resolve_swing()` resolves against the swing's own `_swing_target`, which is whatever the PREVIOUS press aimed it at, or a cone search for an unaimed `use_tool` swing. Neither is necessarily the node under the player's thumb, so the press was answered by a swing that hit something else or nothing. When the cone happened to pick the same node it looked fine — hence "about half the time". `swing_at()` now splits the case at the impact frame: before it, re-aim the running swing at the node just pressed; after it, refuse so `harvest_node.gd::_on_gathered()` answers the press with its direct yield. A press costing a swing animation is a far smaller thing than a press that does nothing. `tests/test_swing_press_is_never_lost.gd` pins all three cases and was verified failable (2 of 5 red against the old behaviour) |
| P0 *(owner, hardware)* | ~10 FPS with grass on | `grass_field.json` on at 75k tufts | needs an Ally measurement; perf proxy is under budget. **GRASS-CULL-0903**: first pass gave the untreated bush tier a `reach_m` cap (band1_open 11,789,608 → 11,619,782 primitives, −1.4%) and nearly stopped there — small next to the 22.5M-primitive game-breaker, but every *other* tier already had VP2's tile-culling/thinning/reach caps, so it read as the only primitive count left in this lane's scope. Pushed to check the tile-culling itself rather than assume it: a real `Camera3D.get_frustum()` plane test against the shipped tiles' actual `custom_aabb`s (not the design comment's claim) found 85–100% of tiles passing at band1_open, not the "roughly a third" `cull_tile_m`'s own comment asserted. Root cause: `_fill_lattice_tiles` bounds every tile `-400..+400` in world Y (the CPU never learns an instance's real height — it's placed by sampling Terrain3D in the vertex shader — so the AABB always had to guess wide across the whole corridor's elevation range), and an 800m-tall box almost never fails a frustum-plane test regardless of azimuth once the camera is tilted even slightly off level. Tiling was correct code that was still submitting nearly everything, because the box it culled by was never where the grass actually is. Fix: `grass_field.gd::_retighten_tile_aabbs`, run on the ring's own lattice-cell move (same cadence as the existing `_apply_built`), samples Terrain3D's real height under the ring on a coarse grid and replaces each tile's Y bound with that real range plus a safety pad, instead of the corridor-wide guess. Re-measured: the same frustum test now passes ~50–67% of tiles per system (grass 22/40, stones 8/12, bushes/flowers 16/32, litter 10/16) — not exactly a third, but a real fraction, not a fiction. `tools/perf_render_stats.gd` at band1_open: 11,619,782 → 10,803,803 primitives (−7.0%) from this alone; **11,789,608 → 10,803,803 total (−985,805, −8.4%)** from the untouched shipped config — the actual per-instance/tile distance culling the flag's history called for, not the earlier trim. `test_grass_field` (18/18) and `smoke_playground` green throughout. Ally A/B is still the only thing that can say whether 10.8M primitives is affordable, unchanged by this session — but the architecture behind that number now does what its own comments always claimed |
| P1 | **A full-satchel gather press said nothing.** `harvest_node.gd`/`key_pickup.gd`/`felled_resource.gd`/`farm_plot.gd` each refused their `has_room_for()` check with a bare `return` — the node stayed put and the prompt kept offering, which each file's own comment called "refused, visibly" even though nothing was drawn. A player pressing interact on a full 24-slot satchel saw exactly what a dropped press looks like. `item_cache_pickup.gd`/`tm_pickup.gd`'s own identical refusal already spoke ("Satchel is full."); `burrow_warrens.gd` too ("No room in the satchel for it."). INTERACT-SWEEP-0903, 2026-09-03 | `scripts/world/harvest_node.gd`, `key_pickup.gd`, `felled_resource.gd`, `farm_plot.gd` | **fixed**: all four now call `push_world_message("Satchel is full.")` on the same refusal. Smoke coverage added — `tests/smoke_playground.gd::_a_full_satchel_gather_still_says_so` fills the satchel by hand and gathers an authored bare-hands (berries) node, asserting the HUD shows "Satchel is full." and nothing was credited. Not run in this sandbox (no local Godot binary); CI on `ralph/INTERACT-SWEEP-0903` is the first real execution |
| P1 | **Four Team Tether NPCs drew a "Greet" prompt that answered a press with nothing.** `data/config/relay_site.json`'s "Relay Patrol"/"Sentry"/"Watch"/"Deckhand" are pure camera-composition set dressing with no `greeting` or `greeting_when` authored, but `village_npcs.gd::_spawn()` gave every spec an unconditional "Greet <name>" prompt. `_on_greeted()`'s own `conversation_id == ""` branch (when `greeting_for()` has nothing to return) is a silent `return` — no dialogue, no message. A player at the relay checkpoint could press an actionable prompt on any of the four and see nothing happen, indistinguishable from a dropped press. INTERACT-SWEEP-0903, 2026-09-03 | `scripts/world/village_npcs.gd` | **fixed**: new pure `has_anything_to_say(spec)` gates whether `_spawn()` ever builds the prompt at all — `interactable.gd`'s own rule applied to dialogue ("off means no offer at all... a visible prompt the button refuses is worse than no prompt"). Unit-tested in `tests/test_dialogue_runner.gd` (4 new cases); not run in this sandbox (no local Godot binary) |
| ~~P1~~ | ~~Objective chain stalls after the camp is built~~ | `tests/helpers/gate_b_tail_segment.gd`, not the chain | **closed 2026-09-03 — a stale assertion, not a stall.** Recorded earlier today as a real stall one rung further along; that was wrong and this corrects it. `gate_b_tail_segment.gd` asserted the tracked objective by matching label PROSE, and two of its five call sites pinned "Care for your team" and "Sleep until" — `git log -S` shows neither string has ever existed in `data/progression/objectives.json`. Those two could only ever fail, and because `smoke_gate_b_continuous` runs in the skipped `verify-continuous-core-known-red` job, they failed unnoticed and reported a stalled chain that was advancing exactly as authored. All five now assert the rung's own `id` through a new `quest_log.gd::tracked_id()`: an id is a contract, a label is a sentence someone will improve |
| P1 | South Bridge entombment at (7.9, −3.4, 1319) | `tests/smoke_traversal.gd`, not the terrain | **closed 2026-09-03 — a measurement defect, not a world defect.** The site guard teleported the body 1.3 km ahead of Terrain3D's camera-following Dynamic/Game collision and judged it before any ground existed under it; it now waits for the ground to arrive. See the §2 row for the measurement. Reopen on any reproduction from a real walked path |
| P1 | **The Gate F harness pressed combat verbs by action name while no fight was running, and LT in the `world` context is the Build shortcut — FIXED at the mechanism (CL-H13, W02-HARNESS-CONTEXT-0904, D74)** | `tools/gate_f/operator_harness.gd`, `tools/gate_f/probe_press_context_flip.gd`, `tests/test_gate_f_rig.gd` | **fixed 2026-09-05 (W02-HARNESS-CONTEXT-0904).** `input_context` never misresolved; the game's context router was right every time. Root cause, reproduced per frame by `tools/gate_f/probe_press_context_flip.gd`: a `press` step names an ACTION (`combat_charged`) but the harness injects its PHYSICAL binding (LT, `JoyAxis:4`), the engine marks every action on that axis pressed (`combat_charged`, `build_shortcut`, `map_zoom_out`, `build_rotate_left`) exactly as for hardware, and at all three sites the press landed with **no fight running** — so LT was `build_shortcut` in `world`, the catalogue opened by design (HUD-INPUT-0903), and the harness recorded PASS and pressed on behind a menu. Why no fight differs per site and none of it is the router: at Oreth the lead had fainted, `can_challenge()` refused and the 'no usable creature' line ran; at Vance the fight had ended (lost, `S07-60` flag NOT set) sixty-six blind `combat_quick` presses before `S07-57`; 'after Captain Riverwatch' IS Oreth (`captain_riverwatch` = Captain Oreth, the same `S08-93` step seen from a second run). The row's earlier premise that two sites press no charged attack was wrong: `S08-93` is a joypad `combat_charged` hold inside the Oreth block. The two shipped guards hold — the trace shows LT refused in `combat` and in the trainer send-out beat (`locked`). **The fix:** `press`, `press_until` and `hold` now resolve the control against the live `input_context` and `data/config/input_contexts.json` before EVERY repetition; a control not live in a mapped context is refused and the step FAILs naming the context, the binding and the live action it would have fired (`'combat_charged' is not live in input_context 'world'; its binding JoyAxis:4:1.0 would fire build_shortcut here`); unmapped contexts and unlisted actions pass through `[unchecked]`. No rebinding, no mouse routing, no segment edit, nothing under `scripts/` changed. **Evidence, same commit:** probe at Oreth with a 1 HP lead — blind: FLIPPED at `S08-93` frame 1665 (`world`, arbiter enabled, game reads `build_shortcut+map_zoom_out+build_rotate_left`); guarded: `S08-93` refused by name, final context `world`, CLEAN. Probe at Vance — blind: FLIPPED at `S07-57` frame 2039, same shape. `test_gate_f_rig.gd` 53/0 with four new real-behaviour tests, each seen red with the guard neutered. S08's first 30 steps through the fixed harness in logic mode: 26 PASS / 4 DELEGATED / 0 FAIL, contexts `title·world·menu_map` only. Full matrix in `ralph/reports/W02-HARNESS-CONTEXT-0904/REPORT.md`. **Consequence for other lanes:** blind fight blocks whose count outlives the fight now go red at the first press after it ends instead of green with the catalogue open — the honest reading, and CL-H1's `fight_until_resolved` re-scripting is the cure. Reopen only on a flip reproduced with the guard in place. |
| P1 *(owner)* | **At the game's opening the player is submerged IN the bed, not lying on it** | `scripts/story/` opening wake beat; the same rig `OPENING-BED-0903` last touched | **new, owner-reported 2026-09-04.** Reported alongside the loft bed: *"at the beginning of the game, you are submerged in the bed rather than on it."* **This reopens `OPENING-BED`, which §4 records as fixed.** That fix moved the wake beat from a floating backpack to a body in the bed — and nobody checked the body was *on* the mattress rather than sunk through it, because the evidence was one frame read by eye for a different defect. A fix verified against the defect it replaced, not against the result, is how this recurs. Cheap to settle: render the wake beat and look at the hips against the mattress plane. |
| P1 | **The Gate F harness's synthesised input may bypass the context router — a MEASUREMENT defect, not the player-facing controller bug it was reported as** | `tools/gate_f/operator_harness.gd`, `data/config/input_contexts.json` | **open, re-scoped 2026-09-04 (G3-LAND) from G3-BAND3's escalation.** That lane hit `S07-57`'s charged attack flipping `input_context` to `build_catalogue` mid-fight and never returning, reproduced it twice, and reported it as *"a real, player-facing bug (any controller player using a charged attack can be yanked into the Build catalogue mid-fight)"*. **The collision is real but the player-facing claim is not supported.** `project.godot` does bind `combat_charged` and `build_shortcut` to the same `JoyAxis:4` at `axis_value 1.0` — verified — but that is deliberate, documented dual-use with **two independent guards**: `data/config/input_contexts.json` puts `build_shortcut` in `world` only and `combat_charged` in `combat` only, which are mutually exclusive; and `playground_hud.gd`'s handler sits behind `_world_input_allowed()`, which returns false whenever `_combat_is_running()`. A real player in a fight is in the `combat` context, where `build_shortcut` is not read at all. So the escalation should not go to the owner as a shipped controller defect. **What is left is the more useful finding, and it is the harness's:** the operator harness synthesises input events directly, and something on that path reached an action the active context does not list. If that is general, then **every Gate F segment that presses `combat_charged` on the default joypad device may be mis-measuring**, which corrupts evidence rather than gameplay. G3-BAND3's own mitigation (route `S07-57` through `combat_charged`'s separate mouse binding) is the right scoped call and should not be read as fixing a game bug. Owner: the Gate F protocol lane. **Reopen as a game defect only on a reproduction from real input, not from the harness.** **CORROBORATED the same day, and this settles it:** G3-HARNESS then hit the identical `input_context=build_catalogue` misresolution on S08 — after **Captain Riverwatch**, with no charged attack involved — and G3-BAND4's original report had already hit it at **Oreth**. Three independent sites, three different segments, and only ONE of them (Vance) involved `combat_charged` at all. That kills the shared-binding hypothesis outright: a defect that appears where the implicated button is never pressed is not caused by that button. It is the harness's context resolution, and it has now cost three lanes real time each. Raise its priority accordingly — **it is corrupting Gate 3's evidence at three known points**, which is the reason S08 still has none. |
| ~~P1 *(owner)*~~ | ~~**At the game's opening the player is submerged IN the bed, not lying on it**~~ | `scripts/story/sequence_director.gd` wake staging + lift; `scripts/world/grandpa_house.gd::_bed_mattress_collider()` | **closed 2026-09-05 (W16-LOFT-BED-0904) — measured first, then blind-judged twice.** `tools/gate_f/probe_loft_bed_wake_pose.gd` reports the mattress plane, where the body settles, and the rendered AABB through the same `render_bounds.gd` the model's own `_fit()` measures with. Three causes. **(1) The pose pivots on the feet.** `character_model.gd::set_lying()` tips the art −90° about X and `_fit()` has already put the art's origin at the character's FEET, so a 1.8 m body becomes a 0.616 m-thick body CENTRED on the surface it rests on: the rendered AABB spanned world y 3.419 … 4.034 against a mattress plane at 3.750 — **0.331 m of the trainer under the sheet**. Independent of where on the bed the body is put, which is why `OPENING-BED-0903` did not catch it: that round fixed a collapsed skin and read one frame by eye for a different defect. **(2) `BED_LIE_REACH` was reasoned to, never measured** (1.5), putting the feet past the footboard. **(3) `_bed_mattress_collider()` stood 0.30 m off the bed it represents** — `BedTwin.obj`'s AABB is offset 0.601 from its own origin in Z and the collider was built from `aabb.size` alone and hung on the placement point, so open air past the footboard read solid and real mattress at the foot end read empty. Invisible until something tries to LIE on it. Fixed: the collider is centred on the mesh (x/z only — the height stays capped so a body lands at mattress, not headboard, height); `BED_LIE_REACH` 1.40, feet z 0.300 and head z −1.500; and the director lifts the `Model` node by `lying_lift_for()`, which measures this rig's underhang (0.308 m) and subtracts `LIE_KIT_SINK_M` — the pouch and bedroll slung at the hip are the rig's lowest point, not its back, so they sink into the bedding. Recomputed every frame from the model's own `is_lying()`, because `trainer_model.gd::_process()` clears the pose itself the moment the trainer moves. **Both numbers were chosen by a code-blind judge from shuffled ladders, not by the author.** On height it picked the 0.08 m rung alone (*"the only panel in the set with correct contact"*), calling 0.00 m sunk (*"both boot soles are gone... the forearm and gauntlet punch through the front face of the mattress"*) and 0.33 m flying (*"a body suspended from a bag, which is exactly backwards"*). On position it picked 0.20 m toward the footboard alone (*"the only panel with real clearance at both ends... the head is genuinely ON the pillow"*), calling the previous placement broken (*"the headboard's top-rail corner cuts a hard straight vertical edge across the character's face"*). The shipped tree re-renders that judged frame to a mean absolute difference of 1.76/255. The collision capsule is untouched, so the leave-the-bed radius and the Get-up prompt are where they were. **Still open, and named by the judge as the remaining work on this frame:** no bedding deformation, no contact shading, and a standing-idle pose rotated 90° rather than a slack sleeping pose — none of which a placement number can fix, and all of which need a rig/asset change rather than a code one. |
| P1 | **`verify-gate-b-core`'s red is a LEG, not a defect** — `gate_a_npc_gather_segment.gd`'s village-tools leg stops nondeterministically at more than one place | `tests/helpers/gate_a_npc_gather_segment.gd`, prompt arbitration; **not** any one NPC | **open, characterised 2026-09-04 (G3-LAND).** The known red was recorded as one failure, *Quarry Foreman cycle 1, arbiter winner=Prompt under Door*. It is not one failure. On `bf86c043`, across two workflow runs of two attempts each, it produced **three different failures and one pass**: (a) the Foreman with `arbiter winner=Prompt under Door`, exactly as recorded; (b) **past** the Foreman and then `Bram cycle 2 did not open dialogue` — the interact press accepted (`_walk_to_and_activate` returned true) and no dialogue inside the 90-frame budget; (c) the Foreman again but with `arbiter winner=**EncounterDirector** under MeadowsPlayground`; and (d) a clean run of the whole leg. **(c) is the one that names the defect properly:** the winner is not a particular door prompt, it is whatever happens to hold the interact line that run, so the label "Prompt under Door" has been describing one sample as if it were the mechanism. **And then it went green in CI.** The run on `661ff2d4` passed `verify-gate-b-core` outright — same code on the same leg, one commit later, no fix between them. That is the single most useful data point here and it is a warning, not relief: had the runs come back in a different order, this branch would have shown the "known red" green and the obvious reading would have been that something fixed it. Nothing did. Treat a green on this check as one sample, which is exactly what CL-H12's *fails if* is written to prevent. **Then PR #33 settled it beyond argument: two CI runs fired on the SAME head (`a5280d91`) at the same time, and one failed at the Foreman while the other passed the whole leg.** Identical commit, identical code, concurrent runs, opposite verdicts. Anyone still treating this check as a pass/fail signal about a branch is reading a coin. The Bram stop has never been seen before because the Foreman stop normally masks it. **Neither stop is reachable from this branch's diff:** `village_npcs.gd`, `inn_interior.gd`, `dialogue_panel.gd`, `interactable.gd`, `data/dialogue/village.json`, `data/config/village_npcs.json` and the helper and smoke themselves are all byte-identical to `main`. The same leg runs clean locally on this head, 2 runs for 2 — Foreman, Oskar and all three Bram cycles, through to "five NPC/modal exits and three equipped-tool gathers returned world control". Whoever picks this up should treat the whole leg as flaky under prompt arbitration rather than fixing the Foreman and declaring it closed — the next run will simply find the next stop, which is exactly what happened here. |
| P1 | The tutorial catch is unstable across KO/re-engage rounds | `tests/helpers/gate_a_opening_drive.gd`, `scripts/story/sequence_director.gd` | **open, found 2026-09-03 on the merged tree.** `smoke_gate_b_continuous` fails inside the opening in two different ways on two consecutive runs of the same commit: once with "catch returned to exploration with 3 party members, expected two", once with "launch 6 left the satchel empty during the tutorial catch ... catch_orb_floor did not apply". Both follow two Bramblebun knockouts and re-engagements, so the suspect is the gap between fights, where `_is_tutorial_catch()` reads `enemy() == null` and neither assist applies. `smoke_opening` and `smoke_gate_a_opening_segment` both pass, so the short path is unaffected and this is not gating CI (`verify-continuous-core-known-red` is a skipped job). Both failure messages now name the roster / the launch, so the next run says which. Not chased further this session — the PR's own red jobs came first |
| ~~P1 *(owner)*~~ | ~~**Player sleep: the loft bed does not work**~~ | `scripts/world/grandpa_house.gd` — the stair and the loft edge, not the prompt and not the arbiter | **closed 2026-09-05 (W16-LOFT-BED-0904) — a geometry defect, found by driving a real body where no test ever had.** The passing smoke was the finding: `smoke_home_sleep.gd::_stand_beside()` and `smoke_gate_b_continuous`'s sleep beat both **teleport** onto the loft (`global_position` = bed marker + 1.5 m, then drop), so nothing had ever walked up the stair. Driven from the ground floor on held stick input alone (`tools/gate_f/probe_loft_bed_climb.gd`), a real `CharacterBody3D` **froze on the top tread for 700 consecutive frames, `moved/30f=0.00m`, `on_floor` and `on_wall` both true.** The prompt, its 2.2 m radius, its beat gate and interact arbitration were all fine the whole time — the arbiter offers 'Sleep' the moment a body is beside the bed. What was wrong was that a body could not GET there. Two boxes, both `grandpa_house.gd`'s own: **(a)** the flight climbed `FLOOR_H`, the loft slab's UNDERSIDE, so the last 0.25 m onto the floor it serves was an unmarked lip only `player_controller.gd::_try_step_up` could cross; **(b)** the loft edge beam's top stood 0.15 m PROUD of the loft floor and reached to z −1.5, the stair's own south edge — and a capsule sweeps its 0.4 m radius past its centre, so `_try_step_up`'s second gate (advance 0.25 m raised `STEP_HEIGHT`) refused against that box. The wedge is the corner (a) and (b) make; the diagnosis names both colliders by size and centre. Fixed: the flight climbs to the loft's walking surface in **eleven** treads (0.314 m rise, shallower than the 0.32 m it had — ten to `LOFT_TOP` would be 0.345 m, five millimetres inside the step budget), the beam is dropped so its top is flush with the loft floor and its depth hangs BELOW the slab where an edge beam belongs, the loft rail's north end stops one capsule radius plus a margin clear of the stair opening (it began at z −1.5, exactly the edge a body steps off onto), and the rail's height is derived from the flight's own pitch so the raked handrail still arrives within 0.06 m of its cap — the 'one rail turning a corner' near-match `_build_stair_rail` documents. The `stairs_top` marker moves onto the loft: it named (0.5, `FLOOR_H`, …), 0.3 m east of the loft edge and a quarter-metre below the floor, which is precisely where a body wedges, so anything walking to it arrived and stopped there satisfied. Guarded by `tests/test_loft_bed_reachable.gd` (five checks, each watched going red on the geometry it guards) and by a real stick-driven climb-and-sleep leg in `tests/smoke_gate_a_rest_torch.gd`. **Reverses D73 §7's closure in the owner's favour.** |
| P1 *(owner)* | ~~Day counter stuck / night reads as dusk~~ **There is no night time** | in-engine probes pass; the owner's build does not | **reopened and sharpened 2026-09-04 by owner play, no longer an open question.** The owner's verbatim report is flat: *"There is no night time."* (`docs/owner/OWNER_PLAYTEST_2026-09-04.md`, OP-0904-2). Under `CLAUDE.md`'s precedence that outranks the probes, and it is more specific than the row it replaces — this is not "the counter is stuck", it is "night never arrives". The NIGHT-LEGIBILITY work below is not invalidated: it tuned real rendered night frames and those frames are real. It means the shipped build takes a different path to the clock than the harness does, and **that gap is the defect** — root-cause it there, not by re-running a probe that already passes. Scoped as CL-O2 in `docs/GATE2_GATE3_CLOSURE_PLAN.md` §2.G. `scripts/world/day_cycle.gd`, `world_look.gd` |
| P1 *(owner)* | **Player sleep: the loft bed does not work** | `scripts/world/` loft/bed interact path; **not** the smoke, which passes | **owner-confirmed 2026-09-04, no longer a question.** Asked directly: *"I've never been able to sleep in the loft bed."* This closes D73 §7 in the negative and that section is marked reopened. **The passing smoke is the finding, not a contradiction:** `smoke_gate_b_continuous` genuinely sleeps in that bed, so the harness reaches it by a path the player cannot, and the defect lives in the gap — the prompt, the reach, interact arbitration on the loft, or the bed's placement. Same shape as the day/night clock (CL-O2). Root-cause it against a real body driven up the loft stair, not by re-running a probe that already passes. |
| P1 *(owner)* | ~~Day counter stuck / night reads as dusk~~ ~~**There is no night time**~~ **Root-caused 2026-09-05; two halves fixed, the largest one routed** | `scripts/world/day_cycle.gd`, `world_look.gd`, `data/config/art.json`; **routed:** `scripts/save/save_game.gd`, `autoload/game_state.gd` | **N13-NIGHT-RESUME-0905 (`ralph/reports/N13-NIGHT-RESUME-0905/REPORT.md`). The hypothesis this row carried was wrong.** It said the shipped build reaches the clock by a different path than the harness. Measured on the **exported release binary** itself (`world_look.gd --verify-daynight`, `template=true debug_build=false editor_feature=false`): `art.json loaded=true keys=44 cycle=live`, `day_length_seconds=600.0` and the same keyframes as the editor. The clock is fine. Hypotheses 1 (a harness-only flag — there is not one anywhere in the project), 2 (a resource the export does not pack) and 5 (a release `project.godot` override — there are no feature-tagged keys at all) are all dead, on the shipped artefact. **The night look is fine too:** `tools/gate_f/probe_daynight_contrast.gd` shot one camera across seven hours of one day through the blend the running game uses — mean frame luma 114.5 at hour 8, 90.5 at 18, 77.0 at 20, 54.7 at 22, **29.5 at midnight (0.26 of midday)**, 43.2 at 3 — and a code-blind critic, given the sheet shuffled and lettered with no hour labels, ranked all seven in exactly that order, named midnight as night unprompted and matched its luma against the key art's own night panel. **Two real defects, both fixed here, both in data:** (a) `is_dark()` — the switch for every torch, camp fill light and creature emission floor — ran hour 20→5, **nine in-game hours, 225 real seconds of a 600-second day**, opening at an hour that renders at 67% of midday and closing after dawn, against `docs/prompts/07-RG21-...`'s explicit ~120s with "dawn and dusk … not part of" it; now 22→3, 125s. (b) the `night` keyframe stood **alone** at hour 0, and `_apply_blended()` lerps between bracketing keyframes, so the look NIGHT-LIGHT tuned over three judged rounds was drawn at full strength for one instant per 600s and the blind critic could name only that single frame as night; `night` now runs hour 23→2 via a `same_as` alias keyframe, **held 75 real seconds**, with no tuned value changed. **STILL OPEN, and the largest half — routed, not fixed:** the clock has no memory. `world_look.gd::_ready()` starts every world at 08:00, `save_game.gd` has no clock key at all, and `game_state.gd::enter_realm()` and Continue both rebuild the scene; a rest snaps to morning by design. Night begins 350 real seconds into an unbroken run in one scene, so anything that reloads or rests restarts that walk — which is exactly why every harness probe passes and a player can go a whole session without reaching hour 22. Fix is one persisted float in `save_game.gd`/`game_state.gd`, not this lane's files. **CL-O2 is not closed.** Regression: `tests/test_day_cycle_night_contrast.gd`, two of four red on the base tree. Decision: `docs/decisions/D87`. |
| P1 *(owner)* | ~~Day counter stuck / night reads as dusk~~ ~~**There is no night time**~~ **Root-caused 2026-09-05; two halves fixed, the largest one routed** | `scripts/world/day_cycle.gd`, `world_look.gd`, `data/config/art.json`; **routed:** `scripts/save/save_game.gd`, `autoload/game_state.gd` | **N13-NIGHT-RESUME-0905 (`ralph/reports/N13-NIGHT-RESUME-0905/REPORT.md`). The hypothesis this row carried was wrong.** It said the shipped build reaches the clock by a different path than the harness. Measured on the **exported release binary** itself (`world_look.gd --verify-daynight`, `template=true debug_build=false editor_feature=false`): `art.json loaded=true keys=44 cycle=live`, `day_length_seconds=600.0` and the same keyframes as the editor. The clock is fine. Hypotheses 1 (a harness-only flag — there is not one anywhere in the project), 2 (a resource the export does not pack) and 5 (a release `project.godot` override — there are no feature-tagged keys at all) are all dead, on the shipped artefact. **The night look is fine too:** `tools/gate_f/probe_daynight_contrast.gd` shot one camera across seven hours of one day through the blend the running game uses — mean frame luma 114.5 at hour 8, 90.5 at 18, 77.0 at 20, 54.7 at 22, **29.5 at midnight (0.26 of midday)**, 43.2 at 3 — and a code-blind critic, given the sheet shuffled and lettered with no hour labels, ranked all seven in exactly that order, named midnight as night unprompted and matched its luma against the key art's own night panel. **Two real defects, both fixed here, both in data:** (a) `is_dark()` — the switch for every torch, camp fill light and creature emission floor — ran hour 20→5, **nine in-game hours, 225 real seconds of a 600-second day**, opening at an hour that renders at 67% of midday and closing after dawn, against `docs/prompts/07-RG21-...`'s explicit ~120s with "dawn and dusk … not part of" it; now 22→3, 125s. (b) the `night` keyframe stood **alone** at hour 0, and `_apply_blended()` lerps between bracketing keyframes, so the look NIGHT-LIGHT tuned over three judged rounds was drawn at full strength for one instant per 600s and the blind critic could name only that single frame as night; `night` now runs hour 23→2 via a `same_as` alias keyframe, **held 75 real seconds**, with no tuned value changed. **STILL OPEN, and the largest half — routed, not fixed:** the clock has no memory. `world_look.gd::_ready()` starts every world at 08:00, `save_game.gd` has no clock key at all, and `game_state.gd::enter_realm()` and Continue both rebuild the scene; a rest snaps to morning by design. Night begins 350 real seconds into an unbroken run in one scene, so anything that reloads or rests restarts that walk — which is exactly why every harness probe passes and a player can go a whole session without reaching hour 22. Fix is one persisted float in `save_game.gd`/`game_state.gd`, not this lane's files. **That routed half is now CLOSED, 2026-09-05 (N14-ROUTED-FOLLOWUPS, D91).** The clock is persisted: `game_state.gd` carries `clock_elapsed_seconds` (`CLOCK_UNSET` = -1 meaning "open at the authored morning"), `save_game.gd` **VERSION 19** writes and reads it with `_migrate_v18` giving every older save the sentinel, `world_look.gd::_ready()` resumes from it through a new `resume_at_elapsed()` instead of the unconditional `apply_time(DEFAULT_TIME)`, `enter_realm()` syncs it off the outgoing world before `change_scene_to_file()`, a mid-session Load pushes it into the live clock, and `reset_for_new_game()` clears it so **New Game still opens at 08:00** — the exact distinction N13 refused to fake with a `static var`. A rest still snaps to morning by design and now clears the carried value too. One further defect found only by running it: `playground_world.gd::_reapply_look_after_ground_materials()` re-pushed the current look through `apply_time()`, which by its own R5.1 contract PINS the clock to the named preset's authored hour — so a world resumed at 19:40 was snapped back to `golden`'s 18:00 on every boot (measured, exactly 18.00). It now goes through a new `world_look.gd::reapply_current_look()`, which reads the clock instead of writing it. Proof: `tests/test_save_format.gd` (+3, format round-trip / v18 migration / corrupt fallback, all three seen red first) and `tests/smoke_clock_survives_a_reload.gd` (new — a REAL booted world set to 19:40, saved, torn down, and a SECOND world built from the file: seen red at hour 8.00 on the old `_ready()`, green at 19.67 after). **CL-O2 is closed.** Regression: `tests/test_day_cycle_night_contrast.gd`, two of four red on the base tree. Decisions: `docs/decisions/D87` (N13), `docs/decisions/D91` (N14). |
| P1 *(owner)* | **CL-O4, density half, bands 2–3: "not enough to do anywhere, nothing to take you off the path."** | `data/config/bands/band{2,3}*/{spawns,harvest,pickups}.json`, `scripts/world/band_pickups.gd`, `item_cache_pickup.gd` | **bands 2–3 done 2026-09-04 (W17-DENSITY-B2-B3, `ralph/W17-DENSITY-B2-B3-0904`); bands 4–5 are the W18 lane; the task-feed half is CL-W2's.** Band 2: 57 → 71 wild clusters, 26 → 46 harvest nodes, 22 authored pickups; band 3: 54 → 66, 31 → 49, 24 pickups. Per km, band 2 went 21.5 → 26.8 clusters and 9.8 → 17.3 harvest against band 1's 28.7 / 20.0; band 3 went 22.7 → 28.2 and 13.1 → 20.6. Runtime (`_probe_gate_f_corridor.gd`): band 2 met 100 → 133 things within 30 m of the spine, worst gap 165 → 141 m; band 3 117 → 127, worst gap 163 → 118 m; the chapter's worst gap is now band 4's 156 m. Every new entry carries a `_why`; no existing entry, order or identity moved (`test_band_content` mirror unchanged); no new alpha, so the region caps and the authored encounter identities in `GATE3_ENCOUNTER_CONTRACTS.md` §2/§6.2 are untouched. Pickups: 33 candy at 18 / 11 / 4 Good / Great / Rare plus 13 revives / potions / mushrooms, tiered per the addendum (critical path 2 Good per band; detours Great; Nightburrow, the far-west pocket, Stormtrail and Riftfrill guard the four Rare); every recovery item sits before the attrition it supports and none between Hess and the restored crossing (P-3.1). Persisted per placement: `item_cache_pickup.gd::setup()` gained an optional flag key so a placement's once-flag is its own id, not the item's — without it the second Good Candy taken would have deactivated every other on the next boot (seen red in `test_band_pickups.gd`). All 46 stood up on real ground in `smoke_playground` (9 nudged off solid scatter, 0 unclear, 0 without ground); boot `ERROR:` set unchanged. Census tool: `tools/_probe_band_density.gd`. Evidence and the blind-judge verdict on the candy tiers: `ralph/reports/W17-DENSITY-B2-B3-0904/`. **Still open:** bands 4–5 (W18), and whether the counts *feel* right is a played-route question the addendum §C reserves for route evidence. |
| P1 *(owner)* | **Beating creatures and other trainers is way too easy** (CL-O5, OP-0904-5) | `data/config/combat.json` `enemy`/`enemy_trainer`, `catching.json` `aggression`, `chapter_curve.json` `difficulty`, `scripts/creatures/wild_creature.gd` | **measured and retuned 2026-09-04 (W23-DIFFICULTY, `docs/decisions/D77`).** Measured first with a new headless harness (`tests/smoke_combat_baseline.gd`: the typical five at each band's entry level against the band's wild table and its weakest trainer, real AI/math/stats/teams, a scripted no-dodge pilot, 24 seeds a row): an ordinary wild cost the lead **7–10 %** of its health and died in seven seconds having landed two hits; the band's floor trainer cost **11–21 %**; the tournament final at L5 and the Warden at L19 each cost the five **17 %** and were never lost. Retuned: `enemy.damage_scale` 1.6 (applied after the G-2 merge so every authored profile keeps its ratio), `reposition_time` 1.0→0.7, `first_attack_delay` 1.5→1.0, a new `enemy_trainer` overlay for trainer-owned bodies, aggressor chase 3.4→5.6 (it was slower than a walk), band 4 wild ceiling 14→15 (CL-G8; band 2 stays, pinned by the Warrens). After: an ordinary wild costs **15–21 %** in every band, the floor trainer **29–62 %** of the lead, the band's top trainers knock the lead onto the bench, the tournament final costs the five **45 %** and the Warden **31 %** (elite 24 %, W-1 holds), everything still won by the five, fight length unchanged (pacing probe 2.37 h before and after). Targets live in `chapter_curve.json` `difficulty` and the smoke fails if the game is softened back under them. **Still a model plus the real-scene smokes, not a played run:** the first owner report after this lands decides whether `damage_scale` moves again, in either direction. The bonding half of CL-O5 is CL-W6, not this row. |
| P1 *(owner)* | ~~**Riding is unfinished in three ways** — the rider is invisible on the mount, sprint and jump are lost while mounted, and the saddle is worn before it is built~~ | `scripts/world/riding_controller.gd`, `scripts/player/trainer_model.gd`, `scripts/player/player_controller.gd`, `data/config/riding.json` | **closed, W14-RIDING-0904 (CL-O3 / OP-0904-3).** All three, each with a test seen red first. **(1) The rider.** `player_controller.set_carrier()` hid the trainer's art outright and said why in its own comment: no seated clip exists on the rig, so a visible trainer rode standing bolt upright. The clip still cannot be bought (`CLAUDE.md`: no Meshy generation without owner reference art), so the pose is authored on the skeleton, the way `character_model.set_lying()` authors the bed. **The axes were measured, not assumed:** `tools/_probe_ride_pose.gd` read the delta between the authored walk/jump extremes and each bone's rest pose and every joint came back on the bone's local X (`LeftLeg max 69.2 deg about (1.00, 0.00, 0.00)`), signs matching `animate_humanoid.py`'s Blender table — the glTF conversion preserves them, which was the open question. The art drops one hip height so the rider's hips, not their feet, land on the species' authored `mount_offset`. **(2) Sprint and jump.** Sprint multiplies the species' own ride speed (Meadowhart 10 → 14 m/s, verified live against a sprinting trainer's 8.6) and costs nothing — `D74` extends `D48` §3's no-stamina ruling to it rather than inventing a cost. Jump asks the new `creature_body.request_jump()` for metres of clearance (verified live: 1.68 m against a 1.60 m ask); that call had to live on the body because its grounded branch overwrites `velocity.y` with the slope-pinning bias every frame, so a launch written from outside is eaten whatever order the nodes tick in. Both gated on `input_owner` (RG5: `jump` and the build menu's `ui_accept` are one physical button). **The jump measurement itself cost most of this lane's time and is recorded in `D75`:** the smoke test's own relocation-to-open-ground helper was driving the mount into the workshop prefab's south-west-facing open arch bay — a real low roof a creature walks under at full unobstructed speed, so a horizontal-peak-speed check read clean while a vertical hop clamped at 0.89 m against every one of three different coordinates tried. `get_slide_collision()`'s own contact normal (`(0,-1,0)`, a ceiling) on the exact frame the rise stopped is what actually found it, not a location guess; `creature_body.gd`'s jump code was correct throughout, proven in complete isolation before the world-geometry cause was found. **(3) The saddle.** It used to be attached in `mount()` and torn off in `dismount()`, so the visible proof of the craft was invisible in every moment a player would look at their creature. `fit_saddle()` now records the fit in the saved flag store and the creature wears it from then on; never at spawn, never before the item is built, and never on the legendary, whose empty `requires_item` is the story point. Per-species rather than per-creature, recorded as a deliberate simplification in `D74`. Evidence, commands and the blind-judge verdict: `ralph/reports/W14-RIDING-0904/REPORT.md`. |
| P2 | ~~Bram's shop exit clips furniture~~ | `scripts/world/shop_interior.gd` | **closed (Gate 1.3), BRAM-EXIT-0903** — misfiled: Bram is the innkeeper in `scripts/world/inn_interior.gd`, a room `probe_shop_exit_clearance.gd` (Mira's cottage only) never covered. A real player driven by genuine single-direction stick input clears every furnished pocket in the inn (bar, both guest tables, bed nook, barrels, doorway — `tools/gate_f/probe_inn_exit_clearance.gd`, 6/6), and `gate_a_npc_gather_segment.gd::_exit_through`'s existing regain-door-axis shape reaches Oskar's leg from every realistic post-dialogue position. Confirmed live in `tests/smoke_gate_b_continuous.gd`: all three Bram cycles exit and resume movement in ~1s each (GATE A NPC/GATHER +53–58s), no clipping. **Still true for the exit clipping this row is about, but no longer true every run for the leg as a whole** — a 2026-09-04 CI attempt stopped at `Bram cycle 2 did not open dialogue`, which is dialogue opening rather than furniture, and is recorded as its own P1 row above. Read this closure as scoped to the clipping it names. The underlying fix (regain the door axis before departing) already existed from an earlier session; it was never verified against the real site. Closed by adding that verification, not by a code change. |
| ~~P2~~ | ~~Gather-route walker cannot reach authored fiber at (-5.0, 141.0)~~ | `tests/helpers/stick_navigator.gd` | **closed 2026-09-03 (FENCE-CORNER-0903) — a harness defect (b), not a world defect (a).** CI-TRUTH-0903 diagnosed the stall (79 flips in a ~10m band, x -1..-12, z 26-27, against `village_boundary.gd`'s `FenceCornerGuard_6`/`FencePanelCollision_10`/`_11`, the corner just past TrailGate) but left the (a)/(b) call open. Settled by driving a real player body at the corner with NO navigator (`tools/gate_f/probe_fence_corner_trailgate_0903.gd`, modelled on `probe_inn_exit_clearance.gd`'s question 2): from every start near the gate a plain stick-hold toward the far target, using nothing but ordinary `CharacterBody3D.move_and_slide`, cleared the corner in three of four cases (the fourth stalled 15m further on, at an unrelated obstacle, not this corner) — only the navigator's own logged trap coordinates, deep inside the reflex pocket a real approach never enters, stayed stuck for a plain hold too. **(b): the corner is round-able; `stick_navigator.gd`'s own stall/flip logic could not round it.** Root cause, found by instrumenting the live behaviour rather than reasoning from the code: on every stall the old code force-flipped `_side` in place and re-probed free space from a point still jammed against the post, so a genuinely-progressing side was abandoned before it had gone anywhere, and the free-space probe (fired at a right-angle post from point-blank range) read almost interchangeably blocked on both sides — the walker pin-balled between the two faces of the post forever. <br><br>Fixed in `stick_navigator.gd`, in the order the live evidence actually forced each piece (several candidates were tried and measured wrong before this shape, and the wrong ones are recorded in the file's own comments so nobody re-tries them blind): a stall now retreats straight back and retries the SAME committed side (was: flip immediately, discarding any progress); `_begin_detour`'s free-space sanity check only re-fires when a side is freshly picked, not on every continuing retry (its own docstring already said "decided once per side and then KEPT" — checking every retry is what broke that); a side is abandoned only once its cumulative net lateral progress since being committed stalls out (`SIDE_ABANDON_ATTEMPTS`/`SIDE_ABANDON_PROGRESS_M`), not on a flat attempt count (a flat count alone, `DETOURS_PER_SIDE` 3→10, regressed a shorter, previously-reliable leg near RoadGate — wood at (16,−28) — whose small travel budget cannot afford ten growing attempts down a wrong side); a detour ends the instant the way to the target has read clear for a SUSTAINED stretch (`CLEAR_AHEAD_FRAMES`, 20 consecutive frames), not on a frame-count/distance guess (needed because unlimited persistence, once safe against premature abandonment, could otherwise ride a single long detour 40m past an already-cleared corner — measured once, 122m off the straight line; a ONE-shot version of the same check was measured worse still, cancelling genuinely-needed detours near unrelated close-packed geometry, the tournament board, at 678-686 flips); and a stall during an already-in-progress stall-recovery falls back to a guaranteed-terminating flip rather than retrying an identical direction forever (measured freezing solid, `moved/1s 0.03`, against a closed gate leaf in a probe that does not open it — the real gather route always does). <br><br>Verified: `test_village_boundary` 7/7, `test_gate_f_rig` 49/49, `test_gate_a_material_route_contract`/`test_gate_a_build_segment_contract`/`test_gate_a_front_door_and_world`/`test_gate_a_world_extent` 20/20, `smoke_gate_a_opening_segment` OK twice, the (16,−28) wood leg green on 4 separate re-checks, the TrailGate corner leg (real gate-open state) green on 8 consecutive isolated runs after the final shape landed, and `smoke_gate_b_continuous --gate-b-full-chain` cleared the ENTIRE gather route (`GATE B — gathered the home materials`) on both full runs attempted after the final fix, continuing past it into two different downstream findings — see the two new rows below, reached for the first time only because this fix gets the route this far. Did not touch `village_boundary.gd`/`.json`: the (a) world-defect branch's remedy (re-siting the gate or corner geometry) was never invoked, per the diagnosis above |
| P2 | Gate B tail: creature-bed placement stalls; objective does not advance off 'Make camp for your team' | `tests/helpers/gate_b_tail_segment.gd` | **open, found 2026-09-03 (FENCE-CORNER-0903), reached for the first time because the gather-route fix above now gets `smoke_gate_b_continuous --gate-b-full-chain` this far.** One of the two clean full-chain runs after the fix cleared the entire gather route and reached the tail: `_place_the_creature_beds()` places 3 of 5 required beds, then `_select_piece("creature_bed")` reports the live pending selection as `''` and the tracked objective stays on `tournament_build_home` ("Make camp for your team") instead of advancing to `tournament_build_camp`. Reads as a build-menu selection / objective-progression defect, not a navigation one — `_select_piece` is a UI pick, not a walk — so out of this lane's scope (`tests/helpers/stick_navigator.gd`, `tools/`, `village_boundary.*`). Not investigated further; belongs with whoever owns `gate_b_tail_segment.gd` or the campsite build flow |
| P2 | Gate B: after gathering, walking back to the Practice Meadow clearing stalls ~27-32m short | `tests/smoke_gate_b_continuous.gd::_walk_back_to_the_square` | **open, found 2026-09-03 (FENCE-CORNER-0903), reached for the first time for the same reason as the tail-segment row above.** The other of the two clean full-chain runs cleared the whole gather route with no per-node failure at all, then failed three retried attempts to walk back to the Practice Meadow clearing, stopping 27-32m short each time near (2-7, 2, -55) -- nowhere near TrailGate or any geometry this lane touched. Not investigated: a different location, a different helper (`smoke_gate_b_continuous.gd` itself, not `gate_a_material_route.gd`), and outside this lane's scope. Belongs with whoever next drives `smoke_gate_b_continuous` past the tail segment |
| P2 | MAIN STORY objective label truncates at 1280×800 | `scripts/ui/playground_hud.gd` | open (Gate 1.4) |
| P2 | ~~Small creatures vanish into grass~~ | creature material value, contact shadow | **closed (Gate 2.4), CREATURE-LEGIBILITY-0903** — Bramblebun-vs-ground luminance measured off real rendered frames (`tools/_probe_grass_separation.gd`, Rec.709 luma, verified unchanged at 30% scale): shipped 1.331:1, raised to 1.568:1 by re-sweeping `field_emission` (already a per-species lever from an earlier pass, whose own 1.06-1.15 target was well under this gate's 1.5:1 bar) 0.9 → 2.5. Every creature body also now gets a flat, unshaded ground-contact ellipse (`shaders/creature_contact_shadow.gdshader`, `creature_body.gd::_apply_ground_contact_shadow()`) answering the Compatibility renderer's missing SSAO — verified headless (`tools/_probe_contact_shadow_check.gd`). Spawn siting away from shrubs was already implemented (`encounter_director.gd::_pick_clear_spot()` + `vegetation.gd::has_solid_scatter_near()`) and verified still wired into the one spawn path every `spawns.json` entry uses; left unmodified. Blind visual judge (code-blind, `.claude/skills/visual-judge/SKILL.md`): "reads clearly... real value separation now, unlike before... comparable to how Palworld's pale creatures separate from grass" — flagged the coat as reading a little flat/blown-out at this value push, a real note left for a future shading pass, not a blocker for this gate's own criterion. Full numbers, before/after contact sheet and judge transcript in `ralph/reports/CREATURE-LEGIBILITY-0903/REPORT.md`. Only Bramblebun was re-measured against the new 1.5:1 bar at the time; Mudsnout/Terrapup/Burrowback were re-measured in G3-CREATURE-COLOUR-0904 — Terrapup already cleared (1.66:1, unchanged), Mudsnout failed (1.35-1.43:1) and was raised to `field_emission` 2.2 (1.73:1), and Burrowback was found to be a design question rather than a straight fix: it is darker than the field by design (grey-olive "rock-nodule armour"), reaches only 1.18-1.19:1 as an absolute contrast ratio across a sweep, and pushing it brighter trades away that identity — left at 0.9, documented, unresolved. See `ralph/reports/G3-CREATURE-COLOUR-0904/REPORT.md`. |
| P2 | ~~Unlit camps and plain-PBR creatures crush to black at night~~ | `scripts/world/camp_fill_light.gd`, `creature_body.gd::_apply_night_floor`, `world_look.gd`, `data/config/art.json` | **closed (Gate 2.7), NIGHT-LEGIBILITY-0903** — measured with a real headless-rendered tent+bedroll and a real spawned Sparkit (`tools/_capture_night_legibility.gd` + `tools/_night_legibility_stats.py`). An unlit tent (no campfire built) rendered darker than the grass around it (subject/ground luma ratio 0.85, below 1.0) at night; a plain-PBR creature with no self-lit emission (Sparkit) rendered functionally invisible in real grass, while a self-lit species (Mudsnout) already read fine unaided and is measured byte-identical before/after. Fix: (1) every camp fixture (tent, bedroll, creature bed) carries a small, unflickering, night-only fill `OmniLight3D` (`camp_fill_energy`); (2) `creature_body.gd` gained the same additive, time-of-day-scaled emission floor humans already have (`character_emission_floor`), gated on `emission_enabled == false` so the self-lit majority of the roster is untouched. Both numbers were blind-judged to convergence, including a correction after a mid-session tent resize (CAMP-SHELTER-0903, a different lane, scaled the tent 2.2x taller) made the first accepted `camp_fill_energy` read as a null result against the new, much larger canvas: final values `camp_fill_energy: 2.4` (a full stop under the campfire's own 3.4) and `creature_emission_floor: 0.22`, both re-confirmed PASS on the actually-shipped numbers by a fresh blind pass that also flagged the creature floor as at the edge of its safe range — see art.json's own comments for the full round-by-round history and the exact judge language. `smoke_night_ecology`, `smoke_gate_a_rest_torch` and `smoke_art` all green on the landed tree. Frames/judge transcripts were session-local, not archived. |
| P2 | ~~Bramblebun reads as a glowing self-lit blob at night, and candy-pink by day~~ | `data/creatures/species.json`, `creature_body.gd`, `data/config/art.json` | **closed, G3-CREATURE-COLOUR-0904.** Both halves traced to the same mechanism: `field_emission`/`field_degreen` were a constant per-species multiply with no clock awareness. Night: new `CreatureBody.set_field_brightness_scale()` (mirrors the existing `set_emission_floor_scale()` night floor, same static-cache-plus-setter shape) rescales the live material off a new `art.json` key `creature_field_emission_scale` (base 1.0, night 0.2 — measured, `tools/_probe_grass_separation.gd --time=night --extra-field-scale=`: creature luma 0.388/8.83:1 unscaled down to 0.251/5.69:1 at the chosen value, monotonic). Day ("candy pink," independently flagged by GATE2-EVIDENCE-0903's judge): `field_degreen`'s green-suppression used to scale WITH `field_emission`'s own strength, so Gate 2.4 raising 0.9→2.5 nearly tripled a hue lever's own gap in lockstep; `FIELD_DEGREEN_GAP` now pegs that gap's size to what a real pass approved at the species' original 0.9, independent of the value push. Measured day ratio 1.263:1 (old formula, current lighting — a separate finding: the scene has drifted since 0903's own 1.568 measurement and the old code no longer clears the bar at all) → 1.618:1 (this fix). Blind judge on a real before/after contact sheet, fresh sub-agent, no source context: "[before] the body fur has a distinct salmon/blush cast... [after] noticeably whiter and cooler... the pink cast is not visible... Neither fix overcorrects into a new defect." Full numbers, contact sheet and judge transcript in `ralph/reports/G3-CREATURE-COLOUR-0904/REPORT.md`. Two real tooling bugs found and fixed while measuring this (an unfrozen world clock and the probe's own default overriding the config path being tested) are recorded in that report and in `tools/_probe_grass_separation.gd`'s own git history. |
| P2 | Villagers read too small in dialogue | camera depth at conversation distance, not a scale bug | owner decision pending on a dialogue camera |
| P1 | **Both committed bakes were stale on `main` — the scatter one is repaired here, the terrain one is not.** `f2dd20e4` (Codex, 2026-09-04) changed only the `config_fingerprint` line of `data/scatter/playground/manifest.json` and of `data/terrain/playground/manifest.json`, with no region files re-baked and every bake input (`vegetation.json`, the band `vegetation.json`s, `terrain_playground.json`) byte-identical to the last real bake `3c73aab5`. The fingerprint hashes the config files' text, so a checkout with different line endings computes a different number; the manifests were edited to that number and the Linux guards then read both bakes as stale: `test_scatter_perf_budget.gd::test_playground_bake_is_committed_and_fresh` and `test_terrain_bake_freshness.gd::test_playground_terrain_bake_is_committed_and_fresh` both **fail on `ef16544f`**, and `vegetation.gd` fell back to computing the corridor scatter on every boot (~4 min in a container). | `data/scatter/playground/manifest.json`, `data/terrain/playground/manifest.json` | **scatter: fixed by W05-TREELINE-0904's re-bake** (fingerprint `4984520267706256`, guard green). **Terrain: open** — `data/terrain/` is outside that lane's ownership; run `build_playground_terrain.gd` once in the coordinator's bake window and commit regions + manifest. The old P2 note here ("no freshness guard") was stale: the guard exists and is the thing that caught this. |
| P2 | ~~Every NPC speaks with the player's face~~ (owner 2026-09-04 #8b; CL-G11) | `assets/ui/portraits/`, `data/dialogue/*.json`, `tools/_capture_portraits.gd`, `tests/test_dialogue_portraits.gd` | **fixed on `ralph/W04-PORTRAITS-0904`, 2026-09-04.** Root cause was data: two plates on disk and 119 authored `portrait` fields naming `trainer.png`. Now 34 rendered plates (the eight-name contract plus the named cast and the Team Tether individuals, each rendered from the installed body it is drawn as, through `village_npcs.gd::model_config()`), every field outside `stronghold.json` re-pointed to its speaker, and `test_dialogue_portraits.gd` walking every line through the real runner (seen red 3-of-5 on the old data, green after). `stronghold.json` is re-pointed by its own lane against the same eight names; the test carves its ids out of the not-the-player rule until that lands. Finding, not fixed (D81): every villager on the shared `villager_female` rig renders the same face because the rig's only differentiator is a ponytail at the nape, invisible from the front in the world as well as the plate. |
| P2 | ~~Villagers read too small in dialogue~~ | `scripts/player/conversation_camera.gd`, `camera_rig.gd`, `data/config/camera.json` | **fixed 2026-09-05, W08-DIALOGUE-CAMERA-0904.** The decision (D73 §6 / CL-G10, owner #8) was a camera push-in rather than a change to villager scale, which has already been cut and re-cut. While a conversation is on screen the rig leaves the exploration orbit and blends over 0.45s to a two-shot: the speaker near the middle of frame at 3.5m with the lens narrowed 70° → 40°, the trainer's near shoulder on the opposite third, look input ignored for the duration, and the whole borrowed pose blended back on close. Measured through the game's own camera by pressing the real interaction button in the built village (`tools/_capture_dialogue_camera.gd`): the speaker goes from **33.8% to 58.6% of frame height** at Halda's stand outdoors and from an off-centre 115.8% to a framed **59.0%** at Bram's inn — the whole claim, in the one number that states it. Indoors, where there is no 3.5m of floor, the shot falls back to a closer over-shoulder (2.1m, fov 46) and, backed into a corner, swings round to whichever side has room. Three defects found by running it rather than reading it, all fixed and each covered by a test seen red first: the speaker was resolved from the interaction arbiter's `activated` signal, which the arbiter emits AFTER the provider has already opened the dialogue, so the push-in framed the previous conversation's speaker and none at all on the first; the blend was driven from `_process`, which `story/sequence_director.gd` switches off for the length of every conversation, freezing it 5% in; and the cramped fallback put the lens 0.36m off the trainer's own centre line with their hair filling a third of the frame, found by the blind judge. Tunables in `data/config/camera.json`. Blind judge on the shipped frames, code-blind, given only the sheet: "the camera delivers the speaker in every frame... none of the three speakers is too small, too far, or blocked" — **PASS** on speaker legibility, and no camera-caused intersection in any frame. Contact sheet, full numbers and the judge's own list of unrelated world defects it found in passing (fence-through-fence and a floating post in the village, a cloth flap clipping Halda's boot, the dialogue portrait showing the same face for every speaker) in `ralph/reports/W08-DIALOGUE-CAMERA-0904/REPORT.md` and `_sheet.png`. |
| P2 | ~~Every NPC speaks with the player's face~~ (owner 2026-09-04 #8b; CL-G11) | `assets/ui/portraits/`, `data/dialogue/*.json`, `scripts/ui/dialogue_panel.gd`, `scripts/world/trainer_npc.gd`, `scripts/characters/character_model.gd`, `tests/test_dialogue_portraits.gd` | **closed for wiring, 2026-09-05 (N04-DIALOGUE-PORTRAITS, D87), on top of W04-PORTRAITS (PR #45).** W04 fixed the data: 34 plates rendered from the installed bodies and 119 fields re-pointed. N04 closed what was left on `main`: Warden Aldis (three `stronghold.json` conversations) now wears `warden.png`; the shared generic trainer refusals wear the challenged trainer's own name and plate (`dialogue_panel.start(id, identity)`, `trainer_npc.speaker_identity()`), proven live by `smoke_trainer_refusal_portrait`; and the eight female-rig villagers no longer share one face — the per-NPC hair colour is laid on the painted fringe/cap through `villager_female_lod0_hair_mask.png` (baked by `tools/_bake_villager_female_hair_mask.py`) via the body material's detail layer, and the seven female-rig plates were re-rendered. `test_dialogue_portraits.gd` now opens the REAL panel on two villagers in sequence and asserts two different plates (seen red 6/16 with the fixes reverted); the only `trainer.png` carve-out is the three bodiless stronghold narration speakers, by name. Still shared, not defects of wiring: the male-rig villagers (Oskar, Bram, Kell, Quarry Foreman, Coll) all wear `villager_male.png`, the four plain rangers wear `villager_ranger.png`, and the cheek-wedge texture artefact (D81) is untouched. |
| P2 | `data/terrain/playground` has no freshness guard (scatter does) | tests/CI | open (Gate 1.5) |
| P2 | Harness fixed-slot inventory lookups | `tools/gate_f/`, `tests/helpers/` | open (Gate 1.6) |
| P3 | ~~Title screen `has_save` null-call at boot~~ | `autoload/game_state.gd` | **fixed 2026-09-03.** `save_system` is built in `Game._ready()` and `title_screen.gd` asks twice while building its menu, so a boot that reached it first logged `Cannot call method 'call' on a null value` every time. It self-healed on the next frame, which is why it survived: it never became visible, it just meant every boot log opened with an engine error and hid the real ones. `has_save()` and `save_slot_info()` now answer safely when asked too early — `false` and `{}` — with the window and the reasoning recorded at the call site |
| P3 | ~~`prop missing: Stool` on every world build~~ | `data/config/bands/band3_the_river_lock/props.json`, `band5_stronghold_approach/props.json` | **fixed 2026-09-03.** Not cosmetic and not in Grandpa's house: `props.gd::place()` takes an optional `dir` so a cluster can name a different installed pack, and `Stool` lives in `quaternius_furniture`. Four of the six authored entries set it; two did not, fell back to `quaternius_fantasy`, and silently failed to place — band 3's river-lock checkpoint and band 5's stronghold approach. Both clusters' own `_why` notes make that stool the point of the composition ("a picket sits here to watch the road, not the fire"; "turns the last stop before the climax toward what the player is about to walk into"), so two authored seats were missing from the world, not just from the log |
| P3 | Tournament banners are flat placeholder rectangles; signpost text unreadable; one near-black world site | see `docs/VISUAL_BIBLE.md` §4 | open for the banners and the dark site; the signpost half moved twice — BAND1-DISCOVERY-0903 raised the glyph atlas 3×, and W22-BRIDGE-SIGNPOST-0904 put cream lettering on board 18's dark plank (see that lane's row in §7 and its `JUDGE.md` for the legibility read) |
| P2 | ~~Village boundary fence: posts float over visible ground, a rail ends in mid-air, one run's post stabs through the next run's rails at the [30,11] corner behind Halda's stand~~ (W08-DIALOGUE-CAMERA-0904's blind judge, frame 1) | `scripts/world/village_boundary.gd` | **fixed 2026-09-05, N05-WORLD-DRESSING-0905.** Cause was how panels were laid, not the outline: each edge was rounded to whole 6.15 m panels spaced `length/count` apart (1.23 m of air between the two panels on the 14.76 m edge behind Halda, a 6.15 m panel across a 4.4 m edge crossing both neighbours), and every panel sat level at its centre's ground height. Panels are now fitted end to end along their edge (`panel_fit`, stretch kept as near x1 as whole panels allow) and pitched to the slope so both posts stand on the ground (`panel_pitch`). Measured live with `tools/_probe_village_fence.gd` within 40 m of Halda: floating posts 6 of 13 panels → 0 of 14, worst float 0.476 m → 0.000 m, worst buried post 1.063 m → 0.121 m (the authored `sink_m`), nearest panel ends median 0.705 m → 0.003 m apart, worst 1.536 m → 0.029 m. `smoke_traversal` passes on the new fence. `test_village_boundary.gd` 11/11 checks both against the real outline (seen red with the old laying). Collision boxes unchanged. |
| P3 | ~~Bram's inn is an undressed greybox behind the bar: "not one bottle, shelf, stool, tankard, barrel, sign or lamp" in the across-the-bar frame~~ (W08's two judge rounds, independently) | `scripts/world/inn_interior.gd` | **dressed 2026-09-05, N05-WORLD-DRESSING-0905.** Four wall shelves with bottles flanking Bram, a sign over him, a keg and bucket at the counter's east end, a stock shelf at the west end, three tankards and a jug on the counter, two bar stools clear of the door lane, and a lantern cage over each of the three existing lights. Installed prop family (furniture pack Stool/Bookcase, Fantasy kit Barrel/Bucket) plus the same primitives the counter is made of; nothing generated. Frame: `ralph/reports/N05-WORLD-DRESSING-0905/_sheet_dressing.png`. |
| P3 | ~~Courtyard gauntlet trainer stands in the same spot and pose after the garrison stands down~~ (W06-FINALE-0904's judge, courtyard frames) | `scripts/world/meadow_healing.gd`, `data/config/meadow_healing.json` | **verified working on `main` 2026-09-05, N05-WORLD-DRESSING-0905; no code change.** `patrols.withdraw` already names `stronghold_courtyard`, and the new `tests/smoke_stronghold_courtyard_withdrawal.gd` proves it live: with her defeat flag set and `legendary_freed`, Warder Solene is removed from the courtyard (`patrols_withdrawn: 1`) while the unbeaten patrol and elite stay (spec §9: no fight the player has not taken is deleted). Seen red with her id removed from the list. W06's capture set only the elite's and Warden's flags, so its "same NPC" frame shows an UNBEATEN trainer, which §9 keeps by design. Whether the Hall's own gauntlet should stand down even unbeaten is a design question routed in the lane report, not decided here. |
| P2 | ~~Legendary Chamber: cyan light-bars read as debug draws; no contact shadow under the machine or the creature; single-key lighting crushes blacks; wall slabs overlap with a black gap; at distance "you cannot tell there is a creature there at all"~~ (three independent blind judges, W06-FINALE-0904 rounds 1–3) | `scripts/world/stronghold.gd`, `data/config/stronghold.json` | **fixed 2026-09-05, N05-WORLD-DRESSING-0905; judged, see the lane report.** The bars were the two `lit` trim girders at 15 m (0.6×0.5 m boxes of the 1.4-energy live teal, the full room width) plus the two floor conduits; a lit girder is now an oxblood girder carrying a slim line at `site.interior_conduit_energy` 0.9 (W06 measured the teal clipping to white at 2.2, holding hue at 1.15), and roofed floor conduits take the same. The "overlapping slabs with a black gap" were the exterior HallMassing towers reaching up to 4.75 m into all four interior corners (`tools/_probe_legendary_chamber.gd`); they are enclosed in masonry piers of the wall's own stone (5.05/4.05/4.05/3.55 m, non-solid, floor to ceiling). Lights: a warm fill inside the doorway wall, a shadow-casting spot over the bound creature's stand (rim + contact shadow toward the reveal stand) and a second over the machine's base — the first shadowed lights in the building (`type: spot`, `shadow: true` in `lights`). `smoke_stronghold` passes on the changed room. |
| P3 | Tournament banners are flat placeholder rectangles; signpost text unreadable; one near-black world site | see `docs/VISUAL_BIBLE.md` §4 | open for the banners and the dark site. The signpost half has now moved three times and is **split**: BAND1-DISCOVERY-0903 raised the glyph atlas 3×, W22-BRIDGE-SIGNPOST-0904 put cream lettering on board 18's dark plank, and N09-BRIDGE-CHECKPOINT-0905 fixed the two halves that are material — the clipped last character (a label fitted to a fixed `0..ARM_LENGTH` board while each arm's post falls at its own `z`, which is why the landing judge read "Relay Statio"; now pinned by `test_no_label_runs_under_the_post`) and the cream/edge cancellation that put in-world contrast at 1.3:1 (`outline_size` 12 → 18, so the dark edge's own 4.79:1 carries the word at distance instead of averaging into the board). **What remains is not material and is Bucket-B**: a 5–7 px glyph cap height at `south-bridge-trailhead` is a 0.24 m board read from 10–15 m, and no `Label3D` property reaches it — it needs a bigger board (R9.4 cut this assembly down for being ~1.5× oversized) or shorter destination names |
| ~~P3~~ | ~~Ralph sweep workflow failed on 2026-09-02 and is dispatch-only~~ | `.github/workflows/ralph-sweep.yml` | **removed 2026-09-03 (CI-TRUTH-0903)**, not fixed. Its 2026-09-02 "failure" was not a bug: the run correctly refused two branches with genuine merge conflicts and exited 1 to say so (`ship_branch.sh`'s own MERGE1 comment explains that exit code is deliberate). The workflow was already `workflow_dispatch`-only — both it and `ralph-merge.yml` say "manual consolidation is now the sole path to main" in their own headers — so it was never running silently. It was deleted anyway: dispatching it lands every green `ralph/**` branch AT ONCE by fast-forward, bypassing the pull-request review every other landing on this project goes through (`docs/AGENT_WORKFLOW.md` §5), and dispatches a release. Checked the 20 `ralph/**` branches live on 2026-09-03: several are mid-flight lanes already being collected into a PR by fast-forward-merging into `claude/do-this-2t7fny`; a sweep dispatch today would have raced that consolidation and shipped some of them straight past review. A workflow whose only safe operator action is "read the full log before ever running it" is worse than no workflow. `tools/ci/ship_branch.sh` (still used by `ralph-merge.yml` for audit/recovery) keeps the sweep's own reasoning in a comment rather than losing it. Pull requests are the landing path |
| P2 | ~~A creature sleeping in a creature bed sinks most of a body-height under it (terrapup, trailpup)~~ | `scripts/creatures/creature_body.gd::play_rest()` | **fixed 2026-09-05 (N03-CREATURE-BODY-0905).** The bed pose's grounding term was `radius * sin(roll)`, signed, so the two species whose `rest_roll_deg` is negative (terrapup and trailpup, both -45) were pushed DOWN by the amount every other species is lifted: measured on the real GLBs, terrapup's low side sat 1.24 m and trailpup's 0.61 m under the bed line. Now `radius * abs(sin(roll))`, the same form W12 already fixed in `companion_presence.gd`'s camp roll and reported here for routing. Positive-roll species are byte-identical (`abs(sin)` is `sin` for them); the zero-roll opt-outs never reach the term. Pinned by `tests/test_creature_rest_pose.gd`, seen red first at exactly those depths; `tools/_measure_bed_roster_fit.gd` still reports every species inside the rim. Not rendered: this container has no GPU, and the geometry is asserted directly. |
| P3 | ~~`ERROR: Parameter "material" is null.` at `material_get_instance_shader_parameters` opens every world boot's log~~ (CL-G7) | `scripts/creatures/creature_body.gd::_build_model()`, reached from `apply_size_multiplier()` by `burrow_warrens.gd::_dress_the_guardian()` | **fixed 2026-09-05 (N03-CREATURE-BODY-0905).** Chased for the first time, with `tools/_probe_null_material_rebuild.gd`: a body dressed (rim duplicate on each surface) and re-sized in one frame reproduces the error in isolation, one per rebuild; holding a reference to the dressed art's materials across the rebuild removes it, which pins the cause. The old art's MeshInstance3D was the only holder of its override material, and a MeshInstance3D's members die before its VisualInstance3D base does, so the material's RID was freed first and the rendering server's own `free(instance)` then flushed a pending update against a material that no longer existed. A frame between dressing and resizing does not help. Fix: `_release_art()` clears every surface override (and `material_override`) before freeing the old art, so the pending update falls back to the shipped mesh material. Probe clean in every mode and for a second species; `smoke_warrens`, `smoke_art` and `smoke_combat` now boot with **zero** `^ERROR:` lines (each used to log this once per boot). **Open cousin, not this lane's file:** the full unit-suite log still carries 22 of the same message, all from tests freeing `scripts/world/felled_resource.gd` nodes directly (`test_felled_resource.gd` `after_each`, `test_harvest_permanence.gd` `veg.free()`); same mechanism (a freed MeshInstance3D was the only holder of its `material_override` / surface-override duplicate), unit-suite only, and the game frees gathered pickups through `queue_free()`. The fix has the same shape: clear the overrides in `_notification(NOTIFICATION_PREDELETE)`. |

Two questions put to the owner and not answered: whether the grass clump-card blade
redesign proceeds; whether Grandpa's loft bed was ever tried. **Both are answered in
`docs/owner/OWNER_DIRECTIVES_2026-09-04.md`** — procedural grass is enough, and the loft
bed is owner-reproduced as broken (scoped as CL-G11/CL-G12 in the closure plan §4.4).
Left standing here as a pointer rather than rewritten in place, because the row above it
is the one this session witnessed the owner say directly.

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
