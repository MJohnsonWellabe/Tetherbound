# Broad visual and four-biome handoff — 2026-09-10

This is the candid stopping-point handoff for the owner-authorized broad visual run.
It records what is retained, what is still open, what the evidence actually proves,
and how the next session should proceed. It deliberately does not assign a
percentage complete: the remaining work is uneven across visual quality, route
continuity, content, stability, multiplayer, and hardware validation.

The owner's target is a four-biome Valheim/Palworld-style game with Pokémon
elements, at a visual standard informed by Valheim, Breath of the Wild, Once Human
and Enshrouded. Broad visible improvement comes first; shared changes should solve
multiple problems. Practical breadth is preferred over repeatedly chasing the last
hard increment. The owner explicitly rejected the old time allocation and wanted
Sol/Luna doing most implementation, with Astra reserved for hard diagnosis and
independent judgment. This run made improvements but did not reach that overall
visual or continuous-play target.

## Stopping point

- The final frozen runtime source is `dbb229436b473cf5d53eb585331893ab54e3b4fa`.
- It includes the Deepwood Circuit pending-client acceptance repair.
- The exact detached Windows checkout imported, exported, and launched the package
  successfully from 11:51:44 through 11:56:25 UTC.
- Native packaged verification passed all phases with no script, parse, or load-error
  signature in the guarded logs.
- The shipped executable reported `terrain=yes`, `ground_at_spawn=0.90`, and
  `props=383004`; the package check found 368 required packed paths.
- The final package is at
  `.artifacts/broad-visual-0910/export-runs/windows-dbb-final/output/`.
- Launch the adjacent `Tetherbound.exe` with `Tetherbound.pck` and its libraries;
  the executable alone is not a complete game package.
- This proves native exported boot/content/ground integrity. It does not prove a
  full exported campaign, multiplayer completion, Ally performance, installer
  publication, or commercial visual acceptance.
- `ralph/reports/BROAD-VISUAL-0910/WINDOWS-DBB.md` is the package receipt.

The final fresh run, `continuous-through-warrens-first`, ended at a logical
blocker after 1,505.385 engine seconds (11:56:39–12:21:55 UTC). It completed five
captures, nine training wins, paid camp/all-five rest, the three-round tournament,
the real bridge guardian/key/crossing, and four quarry nodes yielding eight
rootstone. It then failed to approach the next quarry waypoint `(393,-0.4977,1802)`;
the player stopped at `(395.1783,-0.4992,1804.407)`. Exit 1 is preserved. Engine
errors were empty and all 2,052 selected source/configuration hashes were unchanged.
The bridge prefix is stronger clean-source evidence; the Warrens/campaign remain
failed. See `ralph/reports/BROAD-VISUAL-0910/CONTINUOUS-FRESH-WARRENS01.md`.

The retained save is an earned checkpoint after the bridge, at
`(124.9395,5.6861,1491.0294)`, before quarry mining—not at the failing waypoint.
Its exact location and reproduction guidance are in that report. The owner asked
to stop at a logical point, write this handoff, land the retained work on main and
pause. No new repair cycle was started after the quarry failure.

The final owner-facing result is therefore: the build is packaged and reviewable,
several bounded improvements are safely retained, and the four-biome visual,
functional, and fun goal is still open.

## Retained player-visible work

The following changes earned enough evidence to keep.

- Shared procedural grass now grounds against terrain and bends on a blade-local arc.
  A real 19.941 m South Bridge walk showed motion during movement. This is not an
  Ally frame-pacing result or a commercial grass pass.
- Retain the fuller shared clump coverage and Water cover profile. The clump tests
  and native Meadows, Stormwood, and Water captures support a bounded fullness gain;
  stiff blades, uneven dressing, and Cloudreach's separate cover remain open.
- Water's horizon was extended and the coplanar infinite Terrain3D background was
  removed. The deep-opacity correction removed the conspicuous angular underwater
  boundary in matched day/night views. Water still lacks enough authored surface
  description in judged scenes.
- Stormwood's vegetation palette is retained after fresh blind preferences at Glass
  Crown and Lantern Hollow. Both locations still fail the broader world-quality bar.
- The player-only night rim improves trainer readability at Gull Rest and is a
  daylight no-op. Settlement foundation and entry repairs provide usable floors and
  sidewalls; they are functional repairs, not a finished settlement art pass.
- Large-creature camera framing was retained after measured maximum-body fits at
  5 m and 11 m, with no behind-camera bounds corners.
- Moving-platform carry was corrected: the focused negative case moved a creature
  128.062 m, while the fixed case moved it 0 m.
- Cloudreach authored grass now exists during actual multiplayer entry, and the
  minimap texture-size error is corrected. Two peer crossings passed allocation
  checks; departure synchronization remains open.
- The compact empty action strip, authoritative recall deduplication, and stale
  provider lifecycle guard are retained. Focused HUD checks pass, although the
  narrow objective still wraps.
- Bramblebun's redesigned model now uses its matching atlas. Native ordinary,
  alpha, and shiny identity checks pass, and fresh matched judgments prefer the
  corrected subject. It remains one repaired creature, not roster acceptance.
- No new Meadows meshes were added. The five-creature total remains intact.
- Shared leaf backlighting, nine building entries with physical floors/walls, and
  Fenn's doorway clearance are retained as bounded functional/presentation work.
- Critical wildlife placement and the Stormwood Deepwood Circuit's three-of-five
  trainer-win path are retained as functional integrations; clean earned route
  evidence for the complete chapter is still required.
- Voltarach's indigo alpha palette is retained as a bounded subject result.
- Water's Shellwatch and Deep Watch return-current reductions are retained. The
  clean 47-check production action/save/reload smoke confirms paid delivery flags
  and reduced currents; the earned realm transition remains unproved.
- Harvest interaction verbs and their real resource receipts are retained.

## Closed integration finding

The final independent review found a P1 Deepwood Circuit client-ordering defect.
The Rook offer could replay earlier victories before a multiplayer client's pending
write had become locally committed. With three or more prior wins, later trainers
could not supply the required three credits without forbidden rematches.

The repair waits for committed acceptance, replays missing historical count credits
when progression changes, latches the revision to prevent per-frame resubmission, and
recovers accepted saves containing old wins but missing Circuit credits. It does not
invent a trainer win, reward, or quest acceptance.

The delayed-writer production-style smoke and accepted-save fixture passed. The
focused runtime passed, followed by 13 Circuit/realm tests and 144 assertions with
no engine errors. The independent reviewer closed the blocker. See
`ralph/reports/BROAD-VISUAL-0910/CIRCUIT-PENDING-ACCEPTANCE01.md`.

The earlier `8aad9c373` package predates this repair. It must not be described as
containing the Circuit fix. The `dbb` package is the correct local playtest pin.

## What actual play proved

The final DBB run is the strongest receipt: the earned bridge path completed with
no engine errors and no source drift, then the longer route failed at a quarry
approach. It recorded 51 tournament hits and 29 bridge-guardian hits. The same five
creature instances physically crossed after spending the earned key. The later
quarry failure is a navigation/placement investigation, not a demonstrated cave
combat failure or full-campaign pass.

The earlier fourth through-bridge run recorded the real South Bridge grunt, two guardian
wins, 29 hits, the key changing from 1 to 0, physical bridge depth movement from
`-11.5953` to `9.4471`, and stable party instance IDs across the crossing.

That run is not a clean current-source receipt. Its wrapper found 21 repeated freed
HUD-provider errors, and `tests/helpers/meadows_earned_team_segment.gd` changed on
disk during the run. The engine had preloaded the earlier helper, so it cannot prove
the current on-disk selector implementation. The later focused selector run passed
15 tests and 103 assertions, but it is separate evidence.

The older fresh attempts stopped earlier: one failed on a wood swing selecting the
wrong nearby vegetation node; others stopped around care supplies or guardian
victory. Those failures are useful route evidence, not campaign completion.

That earlier road observer saw 4,565 m over 437 samples, with 294 samples showing fewer than
two visible creatures and one undersampled interval. A separate audit found that the
driver faced against travel in 223 of 231 usable on-road pairs. Nearby creatures
were often behind the camera or outside the narrow frustum. This identifies a real
player-view concern but does not justify a spawn-table rewrite by itself.
The final DBB observer recorded 4,800.154 m / 458 samples, with 320 below two visible
creatures and one undersampled interval; the same camera-direction caveat remains.

Fixtures, catalogues, isolated variant portraits, material comparisons, and posed
stands establish binding or pairwise appearance only. They do not prove route
coverage, combat spectacle, world density, campaign pacing, or fun.

## What remains for the four-biome goal

The commercial visual bar remains open for Meadows, Cloudreach, Stormwood, and
Water. Every biome still needs a gameplay-camera audit that shows its authored route,
creatures, landmarks, settlements, interface, and combat context together.

Meadows still needs the inviting layered pastoral composition promised by the key art:
the ground carries too much chroma, distant hills are visually empty, and several
camera views obscure creature bodies with the HUD. The South Bridge reads as a bare
plank frame rather than a chapter gate with authored presence.

Cloudreach still has flat-green areas, especially the former stand 05 region. The
retained grass entry fix proves allocation, not visual belonging, traversal quality,
or a finished cliff composition. Its cover, footprint planting, far turf, upland
material, and crown-geology candidates were held after fresh comparisons.

Stormwood's palette is more coherent, but Stormheart and parts of the forest still
read as debug geometry. The main route, Dynamo, conduits, captive legendary release,
and roster choice need a continuous earned run. Five side-chain interaction paths
remain incomplete; the concrete missing producers are listed in
`ralph/reports/BROAD-VISUAL-0910/STORMWOOD-SIDE-CHAIN-REMAINDER.md`.

Water has a better horizon, terrain/Fresnel treatment, and water-depth transition.
Deep alpha 1 removed the angular underwater boundary in matched views. The opening
smoke starts in Water and proves 64.487 m of physical swimming; it does not prove
the earned Stormwood-to-Water transition. The broader optional-island reward mapping
still needs a current code/content audit. The Reedhaven maintenance ramp and other
authored reward pockets still need physical route and footing proof.

The creature roster remains the largest shared visual gap. Bramblebun is a concrete
binding correction. Skyrill and Torrentoad still need face and surface organization;
the shared soft-match treatment did not beat controls. The broad cast shows coarse
surface breakup, weak facial focal structure, and incomplete comparable framing.
Voltarach's indigo alpha palette is retained from the anatomy-scoped round. Do
subject-specific work with installed assets and the one-subject Meshy
carve-out only if its reference-art rules are actually met.

The game also needs more visible reasons to travel: authored creature encounters in
the player's forward view, meaningful optional trainers, route-specific rewards,
clear landmarks, and combat moments that connect preparation to progression. The
current evidence demonstrates systems and prefixes, not a satisfying 3–4 hour first
clear.

## Stability and integration still open

- Ally hardware performance remains unproven. The September 7 freeze reports should
  be rechecked against current code and a fresh owner reproduction before being
  carried forward as active defects; save/recovery and second-bed fixes already have
  ten-cycle plus 180-second soak evidence.
- Multiplayer departure synchronization still logs 304 stale cached-node errors on
  peer 0 during a Cloudreach crossing. The log proves the missing path and ordering
  hypothesis, not packet causality. The follow-up should respect the existing drain/
  commit boundary and add a zero-stale-cache assertion.
- The combat prompt/HUD provider error from the fourth run did not recur in the
  final frozen-source earned bridge/quarry run. Full later-chapter coverage is open.
- Continuous Stormwood and Water tails remain unverified, as do the complete
  legendary, Warden, final-roster, and world-response beats.
- Runtime CI `34473442211` / 4670 passed all 26 executed jobs, with three conditional
  skips and 3,206 unit tests / 490,813 assertions. All complete logs were inspected;
  no actual script errors appeared. Known negative-test, dummy-renderer, teardown
  and story catch-up diagnostics remain in `CI-DBB.md`. Final integration adds the
  direct delayed-Circuit smoke to CI; its final-head checks are recorded on PR117.

Before the final Warrens run, the snapshot counted 270 completed runtime checks:
206 clean and 64 non-clean.
That inventory includes expected negative cases and failed fixtures; it is not 270
completed features or a campaign score.

## What cost time without enough return

Too many narrow grass, Cloudreach, and material experiments were run for modest
visual wins. The repeated knob and shape rounds did not identify a new cause, yet
they consumed attention that should have gone to route play and content continuity.
I am not assigning hours or percentages because the run log does not support a
reliable allocation; the measurable cost is the withdrawn/held candidate rounds and
the delayed clean route evidence.

Creature work arrived late and stayed narrow. Bramblebun had a real atlas-binding
defect and rewarded the effort; several shared recolour and soft-match experiments
did not improve faces or the commercial bar.

Camera and fixture iterations also cost time. Some stands were too close, cropped
subjects, or lacked a trainer scale anchor. Several isolated fixtures gave clean
technical answers while leaving the actual gameplay question unanswered.

A Python/native overlap caused a memory kill. That was my coordination mistake:
the lease covered Godot, but should also have covered heavy image processing that
competed for the same memory. A helper was edited during a fresh-run freeze,
invalidating the clean provenance claim.
CI pushes also cancelled in-flight runs and made status harder to interpret.

No verified multi-hour execution gap or overnight application cause exists in this
run. The UI becoming quiet was not diagnosed; do not invent an explanation for it.

## What worked and lessons for the next session

Independent Astra review was valuable for catching the Circuit ordering defect and
for rejecting attractive but weak visual candidates. Sol and Luna were effective on
bounded code, data, export, and native-validation lanes when ownership was explicit.

The best experiments changed one concrete variable, used matched controls, and
reported a blind preference with its evidence limit. The best gameplay receipts used
earned state, real interaction, and stable source hashes.

Specific lessons:

- Bramblebun's unreadable face was principally a wrong-atlas binding, not a problem
  that more global recoloring would solve. Inspect actual runtime mesh/texture
  provenance before spending rounds on an art-treatment hypothesis.
- Grass allocation, instance counts and shader existence do not establish the
  owner's intended grass appearance. Ground attachment, blade silhouette, visible
  density, distance coverage and motion must be judged together from the play camera.
  Grounding alone had mixed preferences; the retained grounding-plus-arc treatment
  performed better. It still looks sparse and strip-like in some real views.
- Water's finite horizon and angular deep-water boundary had different causes.
  Extending the water/background setup and correcting deep opacity each addressed
  a specific artifact; generic material tuning would not distinguish them.
- A subject can pass bounds/frustum checks while terrain or vegetation hides most
  of it. One clean Bramblebun capture run was rejected for exactly that reason.
  The SpringArm also continued native child-camera placement after script-level
  disabling; the fixed diagnostic camera needed explicit reparenting.
- Pending ledger writes are not committed local flags. The Circuit needed replay
  after a revision/delta, and its fixture needed the same aggregate reconciliation
  as the actual event adapter. A synchronous happy-path smoke concealed that gap.
- Full green CI still contained known non-script diagnostics. Read the logs and
  preserve the distinction between deliberate negative cases, dummy-renderer noise,
  shutdown leaks and an actual story catch-up error. Do not call all of them harmless
  merely because the process returned zero.
- For a local progression failure, first use its retained save for a quick,
  explicitly limited reproduction. Run one fresh prefix after the fix is supported;
  repeatedly replaying the opening before diagnosing the blocked step wastes time.

The orchestration should have established a broad visible baseline and texture
binding inventory earlier, then protected more time for changes with clear whole-
scene payoff. I spent too much effort validating small differences and correcting
capture tools, and began the creature-wide investigation too late. The independent
judges prevented unsupported wins from being counted, but that alone did not satisfy
the owner's request for broad visual improvement.

Next time, freeze the exact source before every fresh run, reserve one native process
at a time, and keep fixture evidence visibly separate from earned route evidence.
Push fewer, larger checkpoints; wait for the full CI conclusion before starting a
replacement run. Use Astra for hard diagnosis and blind judging, Sol for substantial
coding, and Luna for bounded coding and guarded native capture.

Keep the five-creature rule and existing asset constraints visible in every brief.
Do not add new meshes, a hidden sixth slot, or broad recolours because a fixture looks
weak. First measure the player route with the camera aligned to travel; then repair
only authored gaps that remain after that measurement.

## Next-session order

1. Keep visual work first: audit all four biomes in gameplay-camera views and improve
   creature/habitat coherence while clean earned route play continues in parallel.
2. Reproduce the quarry approach from the retained earned checkpoint. Distinguish
   authored collision/footing and target placement from a navigator error; use
   native inspection and contact telemetry, then one fresh confirmation after a fix.
3. Start from main containing PR117. Use the DBB Windows package for the unchanged
   runtime code; check PR117's final CI/landing state and do not replay its completed
   boot check without a changed input or new concern.
4. Measure visibility with camera-forward and travel-heading metrics, then repair
   only authored gaps that remain after aligned-camera evidence.
5. Resolve departure sync with protocol-order evidence and a clean two-process smoke.
6. Continue Stormwood and Water earned tails, optional rewards, shortcuts, legendary
   release, and final roster choice; then rejudge visual quality and fun/pacing.

## Retained versus held

Retain the fixes and evidence named above, the `dbb` package, the Circuit repair, the
Stormwood palette, Water horizon/deep-opacity work, grass grounding/arc, camera fit,
platform carry, compact hotbar, HUD lifecycle fixes, Cloudreach grass allocation,
settlement grounding, and Bramblebun atlas binding.

Hold the shared colour feathering, Skyrill/Torrentoad source-texture alternatives,
Cloudreach cover and footprint candidates, basal leaves, far turf, upland variants,
shared grass normal shading, meadow albedo, grass tips, settlement lighting, vitals
outline, Cloudreach arc transfer, Stormheart material treatment, and Stormwood
detiling. Their fresh comparisons did not establish enough overall improvement.

Do not delete held reports or their patches. They explain why the next session should
start from measurement and authored content rather than repeating the same visual
knobs.

## Evidence index and integration state

- Package: `ralph/reports/BROAD-VISUAL-0910/WINDOWS-DBB.md`.
- Final fresh run and exact next blocker: `CONTINUOUS-FRESH-WARRENS01.md`.
- Full runtime CI: `CI-DBB.md`; final integration checks are on PR117.
- Circuit: `CIRCUIT-PENDING-ACCEPTANCE01.md`.
- Through-bridge provenance failure: `CONTINUOUS-FRESH-FOURTH.md`.
- Earlier materials failure: `CONTINUOUS-THROUGH-BRIDGE01-FAILED.md`.
- Road-view measurement: `CONTINUOUS-ROAD-VISIBILITY01.md`.
- Departure sync: `NET-DEPARTURE-SYNC-DIAGNOSTIC01.md`.
- Broad retained/held summary: `.artifacts/broad-visual-0910/final-handoff-draft.md`.

The integration includes docs-only PR118 (`eef22abac`) archiving stale planning
docs. Final handoff/CI wiring commits do not change the frozen DBB game code or
assets. Landing is through [PR117](https://github.com/MJohnsonWellabe/Tetherbound/pull/117)
after full final-head CI, with ancestry verified on `origin/main`; that PR records
the final integration commit and checks without confusing them with the package pin.

The native engine is Godot 4.7 at
`C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe`.
The local machine is an 8 GB RAM desktop/laptop environment with an RTX 3050 Laptop
6 GB GPU, not the Ally. `.artifacts/broad-visual-0910/validate.ps1` provides isolated
profiles, process receipts and the 90% memory guard. Reserve the same runtime lease
for heavy image processing; do not raise the guard to make a capture pass.

Large captures, coverage telemetry, held patches and exact-build worktrees remain
local under `.artifacts/` and `shots/`; source, decisions and concise evidence reports
are the Git deliverables. Existing unrelated attachments and untracked extracted
texture files were preserved, not swept into the release. No background gameplay
or implementation lane should remain running when this session is handed off.
Eleven untracked diagnostic scripts/UID companions from held experiments were
moved out of `tools/` to `.artifacts/broad-visual-0910/held-untracked-tools/` after
the fresh run ended. They are preserved for inspection and are not production
changes to import or ship accidentally.
