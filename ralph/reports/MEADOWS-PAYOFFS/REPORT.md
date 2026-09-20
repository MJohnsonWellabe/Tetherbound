# Meadows payoff and co-op admission evidence

## Compact retained-team growth receipts

`ralph/compact-team-rewards` follows PR155/e8bd5fb42. The rejected reunion capture below exposed a separate ordinary-play problem: two trainer rounds produced two level-up entries for each companion, making the reward card nearly the full720p height. This change combines repeated `level_up` entries by nonzero creature identity within the current displayed moment group. It preserves first/last levels, summed stat/level gains, latest identity and trait/evolution notices. Homonymous creatures remain separate; missing identities never merge. Exact payout text, non-level moments, XP attachment, the source feed and queue remain intact. No award, party, save, combat or network semantics change.

Sol implemented `progression_feed.gd::coalesce_moment_level_ups` and its sole consumer in `playground_hud.gd::_render_moment_events`, with three focused regressions. Senior review checked identity, copy/aggregation and receipt boundaries. Focused existing selectors pass67tests/396assertions: progression_feed28/154, hud_widgets36/217, hud_presentation_lifecycle3/25. Root-run existing `smoke_hud_presentation_lifecycle.gd` passes70checks, including combat/modal deferral, reading-time pause/resume and same-sequence feed reset.

Root rendered the production HUD at1280×720 using the existing lifecycle-fixture approach. Five explicitly seeded owned companions each receive two real `gain_xp` calls and one synthetic trainer receipt; there is no battle or earned-economy claim. Nine checks pass: one growth summary per member, exact50Coin/one Revive receipt, +542XP once and +262XP four times, card height and saved capture. The resulting right-hand card measures396.8×306.7raster pixels. `_sheet_rewards.png` shows the result. The isolated fixture freezes unrelated HUD polling (its party rail is stale); only the reward card is under visual review. This is bounded duplication/readability acceptance, not a world-composition, controller, Ally or commercial visual pass. Existing text sizes are unchanged; arbitrary long names/mixed moments can still exceed the desired notification footprint.

Local logs: `%TEMP%/tetherbound-compact-rewards-capture.log` and `tetherbound-compact-rewards-lifecycle.log`. Neither contains script/engine errors; the isolated HUD has its expected missing-player warning. No new capture framework, production menu, pagination or truncation was added. UX§3.3 records the bounded rule and remaining limits.

Required root-run Playground exits0 with `smoke: OK`; its eight normalized engine-error categories equal the preceding reunion baseline (including null material and shutdown leaks), with no script errors. Log: `%TEMP%/tetherbound-compact-rewards-playground.log`. Scoped whitespace checks pass and STATE remains below25KB. No fresh CI, package or full-campaign pass is claimed.

**Next chapter-path finding (read-only Terra audit, root source-confirmed):** `PROGRESSION.md`§7's explicit tournament resolution requires five owned/L5 once, then an ordered three selected for each round. `tournament.json::entry.min_party_size=5` still determines `tournament.gd::entrants`, which in turn feeds `condition_ready`/`team_fed`; no declared selection exists. A hungry/tired fifth therefore participates in the entry refusal even though the target field is three. The next substantive slice must implement selection, persisted identity and actual round enforcement together, preserving sticky readiness and bracket wins. Merely setting the config to3would erase the separately specified ownership/training milestone. This source finding is not a replayed tournament failure and is not fixed by the reward-card change.

## Lost-companion reunion — expedition priority correction

Branch `ralph/lost-companion-reunion`, based on PR154/cf6388625. The owner challenged the disproportionate time spent on multiplayer. New guest-wild implementation was stopped before edits. This slice returns to an existing Meadows detour; it does not expand networking or revisit cart polish. Sol implemented the presentation/config/mount; senior review integrated dialogue, corrected transform typing/rotation and animation handling, and owns acceptance.

The formerly unnamed owner is deliberately identified as existing high-pasture drover Juno. `data/dialogue/trainers.json` supplies her missing-companion lead and post-rescue thanks; her optional battle and First Ironwood lead remain. `trainer_npc.gd::conversation_for` reads her optional `dialogue_after` mapping from the existing Band4 trainer config. `data/progression/objectives.json::band4_lost_creature` names her and supplies directions. No new cast member was invented.

`scripts/world/lost_companion_reunion.gd`, mounted immediately after Trainers in the production Meadows world, displays one ordinary Meadowhart at the patrol, then beside Juno when the existing world flag `defeated_lost_creature_rue` changes. Configured local offsets are[3.6,2.8] and[3.1,1.9], with relative yaw−35°/38°; placement uses actual trainer transforms and terrain height. The same body remains at the standard species scale. It has no interaction, ownership, capture, battle membership or reward. Its physics/collision stay disabled, including after visibility changes; the existing model animator supplies idle motion. The presentation reads the merged progression view and refreshes on revision, replacement or the existing restore hook. Simulation-only shells omit the body.

This is a discrete world-state consequence, not a simulated escort or walk home. Existing patrol reward remains50coins/one Revive through the existing trainer pipeline; no new save flag, receipt, schema or payment is introduced. Ordinary route discovery, tracking gameplay, co-op reward acceptance, full save/reconnect witness and activity-quota qualification remain open. No claim of an earned chapter or extra authored hours follows.

Focused root-run `tests/run_tests.gd -- --only=test_trainers_data.gd,test_quest_log.gd`:97tests,2409assertions,0failed; no script/engine errors in the unit log. The new test checks Juno's independent battle state, both reunion greetings and return to the old greeting when the rescue flag is false. The scoped scripts parse. Logs are OS-temporary evidence, not committed payload.

Two initial rendered witness attempts were rejected. The first reached the actual patrol victory, world-flag consequence and restore seam, but its camera grounding/framing was invalid and a dialogue closure assertion failed. Review also found that the inherited smoke's `adopt_starter` deployed an ally without adding it to `Game.party`, making an empty-to-empty membership comparison inadequate. The second attempt dismissed that unowned fixture ally for the screenshot and consequently could not resummon or start the fight. These are not passing capture/ownership receipts. The changed approach uses the established catalogue-survey grounding/camera path and an explicitly owned fixture party; production party code is unchanged.

**Corrected bounded runtime:** exit0 in148.3seconds, no smoke failures. The reused local-request smoke seeds Terrapup plus ordinary Trailpup/Bramblebun/Burrowback/Meadowhart through `Game.make_creature`/`party.add`, then summons the owned active creature. Actual patrol combat runs with the inherited opponent6HP floor and ally healing allowance. Five nonempty owned identities remain unchanged; the same rescued display moves to Juno, remains visible/nonblocking and reconstructs its position through the restore hook. This is wiring evidence, not earned team acquisition or fight balance. Juno is marked already beaten only afterward to select the acknowledgement; her production `_on_challenged` callback and `panel.advance` open/finish it. This does not prove ordinary proximity/controller interaction or a disk roundtrip. Retained local log: `%TEMP%/tetherbound-reunion-witness.log`; isolated profile `reunion-appdata-yvrdcxzc`.

**Visual verdict: not accepted.** `_sheet_reunion.png` retains the corrected attempt as rejected evidence. The first frame shows the missing Meadowhart at its source site; the second is materially obscured by the deployed Terrapup and the result panel. Senior inspection agrees with Sol's reported obstruction. This cannot certify reunion composition, normal approach or either commercial visual bar. No further capture loop was run. Source integration is a draft checkpoint with presentation qualification still open, not a completed activity.

Required root-run `tests/smoke_playground.gd` exits0 with `smoke: OK`, no script errors. Its eight distinct engine-error categories match `%TEMP%/tetherbound-regional-return-playground.log` after normalizing numeric counts; these include the inherited null-material error and shutdown leaks. The rendered witness likewise adds no normalized error category against `tetherbound-regional-credits-final-witness.log`. Neither is a clean engine log. Current Playground log is `%TEMP%/tetherbound-reunion-playground.log`. Changed JSON and scoped whitespace checks pass; STATE remains below25KB. All world/render workloads were serialized with isolated profiles. The bounded witness ran only the lost-companion portion of the existing local-request smoke, not a fresh sweep of all five activities. CI and packaged-device acceptance are not claimed.

## Scope and provenance

Branch `ralph/meadows-payoffs`, stacked on PR134 (`ralph/first-expedition`) and the design PR132. Base before this slice: `1009f1345`. Runtime: Windows Godot4.7.stable.official.5b4e0cb0f; Compatibility captures used NVIDIA GTX1060 3GB,1280×800. This is bounded implementation evidence, not Meadows/chapter acceptance, Ally performance, invitation transport or a finished activity quota.

## Co-op admission

Commit `780d295b7`: `peer_registry.gd::admission_verdict` checks the actual host-inclusive capacity and a nonempty, edge-trimmed String identity before registry insertion, realm preparation or snapshot. A live identity cannot evict its current holder, including peer1. The character can rejoin once the previous peer row is removed. The existing ID format is preserved; there is no fabricated Steam/GUID requirement.

ENet admits one extra transport handshake socket so a full game can deliver its reason; the registry remains capped at the host's configured total. `session.gd` sends a specific rejection on the ledger channel and uses the existing six-frame close-flush lifecycle. JoinDriver surfaces that reason while preserving cold-host transport retries. Already-rejected senders cannot restart the timer or become admitted during its flush window.

Validation:

- Root-run existing unit runner, selectors `peer_registry,join_driver,multiplayer_identity`:16tests,81assertions,0failed. Agent's final targeted registry/retry checks also pass.
- `tests/smoke_net_identity_admission.gd`, two actual processes and shipping Session RPCs: final run exits0, all checks pass, neither peer log contains `ERROR:` or `SCRIPT ERROR`.
- A host with admitted cap1 refuses the spare socket in9frames with `This session is full (1/1).`; no snapshot applies and host registry/world hash remain unchanged. This is a compact capacity-boundary test, not a five-machine trial.
- Rehost at cap4; a joiner claiming the host's identity receives the readable conflict in9frames; no snapshot, inactive rejected client, unchanged host registry/world. A distinct legal identity then joins and applies its snapshot in10frames.
- First attempt exited1 because the smoke looked for a top-level field that the existing harness wraps away. The returned detail and peer logs already contained the correct refusal. The assertion was corrected, transient-retry handling reviewed, and the full scenario rerun successfully.
- The final repeated-hello guard was added after the successful world run, reviewed and parsed; its specific adversarial sequence was not replayed.

Local raw run: `%TEMP%/identity-admission-final-1789869559/`. Retained `admission-run.json` and peer logs identify the precommit HEAD865025cfd plus the working-tree admission diff. They must not be described as a clean865025cfd run.

Limits: no lossy-network acknowledgement guarantee, authenticated platform identity, build/protocol/content compatibility,120s reservation, Steam binding, lobby, invite UI or cross-router witness. Those remain required future work. This closes a concrete admission defect; it does not deliver invitation co-op.

## Cart presentation

Commit `fbb709c4e`: `cart_repair.gd` now uses one WagonAssembly for the existing wagon mesh and its solid collision. Cart-only metadata in `building_prefabs.json::prefabs.cart_repair_patch.presentation` specifies an11° broken lean,0.19m lift, repaired local offset[-0.9,0,2.3], repaired yaw−25°, and1.1s transition. The source site remains[80,1240], yaw40°. The terminal wagon sits farther onto the shoulder at world yaw15°, with installed timber/rope repair pieces; small stone chocks remain at the old seat. Existing village wagons and shared materials are unaffected. Coll's completion line now describes a completed repair.

Restoration applies the saved flag's terminal pose without replaying the animation; false state resets the broken pose. Collision moves/rotates with the assembly. No new NPC, currency, item reward, road gate, mesh or purchase was added.

`tools/capture_cart_repair.gd` reuses the production catalogue survey, world, trainer, HUD and camera. It debug-travels to fixed stands and deliberately injects the cart flag for before/after views. Its manifest discloses this. These captures cannot prove an earned turn-in, walkable approach, save roundtrip or late join.

Initial production baseline showed a pristine wagon before completion. First changed capture showed the damaged lean, but the repaired5m displacement made the wagon smaller and harder to read. A code-blind lower-tier review rejected the payoff readability and both broad visual bars. The final correction halves that displacement, turns the wagon into a three-quarter view, and makes the chocks smaller/darker. The initial critique remains valid evidence of the broader road/foliage/depth gaps; a local prop change cannot close those bars.

Final capture:6/6 frames complete. Senior inspection accepts the bounded presentation correction: the repaired cart remains identifiable at comparable near-view scale, the close view shows a contained wheel repair, and the smaller darker chocks read as work traces. `_sheet-final.png` pairs all three stands before/after; `_sheet-first.png` preserves the rejected first round. `cart-capture.json` records actual body/camera poses. No `SCRIPT ERROR`; the normalized distinct engine-error set matches the baseline's GLES shutdown leaks. This is not a second independent BarA/B pass.

The blind first-round review's three largest gaps were: (1) ambiguous small/end-on repaired-cart silhouette, (2) disconnected-looking dirt patches and uniform grass obscuring road/contact, and (3) repeated tree wall/weak depth and subject hierarchy. It answered BarA **No**, BarB **No**. The later pose correction addresses the first local issue; road, ground, foliage, depth and broader activity staging remain open. Still frames do not establish movement, collision feel, repair timing, normal approach, companion behavior or handheld performance.

`tests/smoke_local_requests.gd` exits0 and all five activities pass, including the real cart's empty-hand refusal, exact one wood/stone/fiber cost, bounded animated terminal pose, attached collision, visible parts, restore and disabled prompt. This cart fixture calls the existing `_on_tried` directly and supplies materials; it is not a controller approach or earned-gathering witness. The first invocation caught a SceneTree test typo (`get_node_or_null` belonged on `root`); corrected before the runtime rerun. No shipped code parse failure was involved. The successful run has no `SCRIPT ERROR` and retains the baseline dummy-renderer shutdown leak types. A passing restore-seam assertion is not a disk or network witness.

**Inherited transaction defect remains open:** `_on_tried` requests a world flag, then spends local wood/stone/fiber even when the request is only pending. Concurrent peers can both pay for one world fact; refusal/disconnect can strand the payment. The visual work does not make this atomic. A focused turn-in transaction must replace this split before co-op activity acceptance. Coll is a dialogue speaker without a world body; WORLD's former visible-Coll wording was corrected explicitly, not silently implemented with a new NPC.

## Integrated local verification

`tests/smoke_playground.gd` exits0 with `smoke: OK` after both changes. No `SCRIPT ERROR`; normalized distinct `ERROR:` set equals the previous first-expedition world baseline, including its null-material/dummy shutdown errors. No claim of a clean engine log. JSON parsing and scoped `git diff --check` pass; STATE remains under25KB. Root ran smokes serially with isolated APPDATA profiles; renders used the free shared render lock and no headless/driver combination. All engine processes exited and the render lock was released.

Commands, from the repository with the installed Godot4.7 executable:

```text
godot --headless --path . --script tests/run_tests.gd -- --only=peer_registry,join_driver,multiplayer_identity
godot --headless --path . --script tests/smoke_net_identity_admission.gd
godot --path . --rendering-driver opengl3 --resolution 1280x800 --script tools/capture_cart_repair.gd -- --biome=meadows --output=<fresh-output-dir>
godot --headless --path . --script tests/smoke_local_requests.gd
godot --headless --path . --script tests/smoke_playground.gd
```

The two-peer run sets a unique `TB_NET_RUN_ID`/`TB_NET_OUT_DIR`; the existing harness isolates peer profiles. Retained logs: `local-requests.log`, `playground.log`, `units.log`, `admission-host.log`, `admission-client.log`. Renders/logic ran on the relevant working-tree source before its commit, not an exported package. No full campaign, owner fun check, device test or packaged-build claim follows.

## CI and next blocker

PR134 run35481978049 unit shard3 failed because the sparse CI checkout omitted eight committed Meadows review receipts read by `test_meadows_named_location_ledger_0912.gd`. All four manifest blobs parse with `complete=true`; all four review blobs exist and contain their historical PASS. Commit `865025cfd` materializes exactly those tracked text blobs, leaving the test and historical evidence unchanged. Its workflow blob equals the previously unmerged fix at `a2d2f9d12`; both that commit and `db67c2d6c` were absent from main. The fix is pushed to PR134 as well as included in this branch. Historical PASS text is not new visual acceptance.

The same CI's region job106001595537 reports Warrens egress stopping15.53m short at local[0,0.35,-25], four haze cards against a six-card assertion, and Root_5/Root_6 at1.11m/1.58m above floor. `scripts/world/burrow_warrens.gd`, its config and `tests/smoke_warrens.gd` are unchanged from origin/main in this stack. Classify/reproduce those failures next; do not waive the egress failure or assume every visual count is still the right contract. The checkout repair does not fix them. CI/package acceptance remains open.

Read-only follow-up establishes one stale expectation: `burrow_warrens.json::haze` deliberately contains four pool cards. Its R29 comment says the doorway card was removed because it intersected the production threshold camera; the R17 comment removes rejected crossed shaft cards. The latest config commit is44056970f. Do not add rejected planar haze back merely to satisfy the smoke's old minimum-six count. This finding does not resolve egress or establish whether Root_5/6 intrude on a traversable lane.


## Tournament three-of-five registration

Branch `ralph/tournament-three-entrants`, based on `e7a9efb29` (PR156). This implements PROGRESSION section7/UX's explicit distinction between the permanent five and the three entered in a tournament round. No collection cap, chapter pacing, creature stats or combat verbs change.

Player path: Halda opens the five-card picker once the five-companion training milestone is met. A selects/removes, left/right moves focus, X registers exactly three, B cancels. Choosing order does not reorder or remove the owned party. Current readiness and the combat field use only those three; the first pick opens the round. The ordinary separate dialogue consent remains. A loss restores the registered three's HP and pre-round rest/food/happiness, with no award/bracket advance; the final victory's existing whole-party heal remains. Three taught physical beds and supply/readiness integration remain open.

Identity/save implementation: every creature receives a durable UID; selection saves in merged27 and portable character6 (world2 unchanged). Missing/invalid legacy IDs are minted; duplicate loaded IDs are all reminted so a selection referencing the ambiguous identity fails closed. Older saves start unregistered while retaining readiness/bracket flags. Release of a selected member invalidates the entire choice; rename/reorder preserve it. Existing five-only capacity is unchanged.

Network boundary: host freezes an announced ordered three and prevents outside deploy/strike/burst. Guest presentation waits for a correlated verdict and revalidates current local readiness; timeout/stale-state/presentation-failure paths cancel admission. Final lifecycle review corrected leftover frozen roster cleanup and guest loss recovery. This is protocol consistency over owner-held metadata, not independent host verification of remote ownership/care. Legacy guest trainer stand-in architecture remains; no new shared-tournament/internet acceptance is claimed.

Evidence is Godot4.7 on Windows, existing working tree plus this diff, not an exported package or a new-game earned route. Root readiness selector:62tests/358assertions/0failed (`%TEMP%/tetherbound-tournament-readiness.log`). Agent core selector:146tests/862assertions/0failed (`tetherbound-tournament-core-tests-final.log`). Agent network lifecycle selector:8tests/34assertions/0failed before its final terminal-cleanup adjustment; the final full-suite result below supersedes this narrow run. These are separate batches, not a unique combined test census.

Root extended existing `smoke_tournament_consent.gd` with physical InputEventJoypadButton events: fewer than three refused, non-roster order preserved, fourth pick refused, cancellation leaves registration unchanged, reopen/confirmation return exactly three while five stay owned; existing B-decline/X-consent dialogue behavior remains. Both headless and Compatibility1280x720 runs exited0 without ERROR/SCRIPT ERROR. `_sheet_tournament_selection.png` is the production picker at720p. Root visual review: five cards and all actions/readiness text fit and are readable. The isolated capture displays keyboard glyphs because no physical pad is connected; injected controller inputs exercise mappings but do not prove Ally hardware. No creature/world visual-bar acceptance follows.

Final root runtime receipts:

- `smoke_tournament_bracket.gd` exits0: actual registrar callback plus pad selection, refused unready entrants, sign-up, deliberate real loss, selected-three recovery without fixture healing, retry, and three wins. Quarter/semi/final take1866/2038/3629 action frames, defeat2/2/3opponents and pay20/25/40coins. Each admission asserts only the selected three can enter and all five stay owned. Saddle recipe unlocks; champion greeting starts no fight and pays nothing twice. The source fixture stages levels/care, positions at the practice ground and advances dialogue; it is not earned chapter/pacing proof. Log:`tetherbound-tournament-bracket-final.log`.
- First bracket attempt failed registration after reusing the down event as an up event on the same engine frame. The test now duplicates releases and waits across process frames; final run passes. Original log retained as`tetherbound-tournament-bracket-first.log`. This is a fixture correction, not evidence of a product regression fixed by a rerun.
- Required `smoke_playground.gd` exits0. Its eight normalized ERROR categories exactly match PR156's`tetherbound-compact-rewards-playground.log` (all digits normalized): dummy renderer resource/instance leaks, PagedAllocator shutdown, resources still in use and intermittent null material. No SCRIPT ERROR. Final bracket contains seven of those same categories. These are baseline-equivalent boots, not error-free engine runs.
- Corrected disk/save/network batch:100tests/664assertions/0failed (`tetherbound-tournament-disk-final.log`). Portable character retains personal readiness/selection, and deliberately does NOT carry world-scoped bracket wins into another world; merged/world load preserves those wins.

The first full-suite pass found a missing preload in the added character-disk test (fixed and the entire character/save/network batch passes above), an outdated implicit strongest-five expectation in the earned-rest test, Juno's previous PR155 dialogue exceeding the existing three-line/110-character budget, and a route-row predicate driven by pre-existing untracked telemetry. Juno's lines are shortened without removing either the missing Meadowhart lead or the First Ironwood/Halder story. Final suite/focused dispositions follow. No CI, internet tournament, device, earned chapter or merged-main acceptance is claimed.


Next preparation audit (source only, no new implementation): `home_progress.gd::CREATURE_BED_FLAGS` already tracks bed1/2/3, while `progression.json::home.required_pieces` and objective wording still teach one bed. `buildables.json` makes camp+three beds30wood/8stone/34fiber. The authored material helper route enumerates28wood/9stone/40fiber but retains a69/42/34 obsolete house-inclusive stock target; actual reachability/supply must be checked before adjustment. This does not establish a world-wide material shortage. The next gameplay slice should teach the registered three's beds and make that short preparation route solvent, preserving the unentered two and existing one-bed milestone saves.


Final focused corrections: `--only=test_meadows_earned_rest_segment.gd,test_ironwood_story_0912.gd,test_lost_companion_reunion.gd,test_quest_log.gd,test_tournament.gd` passes119tests/1455assertions (`tetherbound-tournament-regressions.log`). The rest test now checks declared UID order after party reorder instead of silently picking the strongest five. Existing earned route helpers use Halda's production picker before care/consent; their input flow is source-updated but no full earned campaign was rerun or accepted. Root corrected the helper's care dialogue handling: ordinary lines advance with X, a confirmation is declined with B. The fixture GateB helper explicitly declares its first three and builds three beds; it remains a fixture.

`smoke_tournament_heal.gd` exits0 on the real Meadows scene: three fainted/two hurt become zero fainted/zero short of full after the existing final dialogue. That run is a staged damage/dialogue-effect witness, not a second earned tournament. Required world smokes were serialized; read-only units used isolated profiles alongside them.

The route-row failure uses local untracked `ralph/reports/gate-f-run-20260915T193953Z-owner/{S02,S04,S05}/telemetry/route.csv`:368/362/491 rows against unchanged450/420/970 thresholds. `tests/test_gate_f_harness_predicates.gd` and `tools/gate_f/segments/` are identical to base e7a9efb29. The predicate scans report directories without restricting them to tracked successful runs. No source threshold, report file, assertion or skip was altered to hide that failure.

## Three-bed preparation

`ralph/three-bed-preparation` follows PR157/4b17d7e2a. This completes the source connection between the selected three and the existing physical-bed lesson, without adding a new care system. `home_built` still means tent/fire/bedroll/one bed. `progression.json::home.preparation_creature_beds=3` expands the recipe-derived gather target to30wood/8stone/34fiber. The existing journal bed row counts1/3–3/3 and completes on `creature_bed_built_3`; `tournament_entered` retires it for existing entrants. Halda's first signup checks all three bed flags. Her fallback now handles partial preparation: the old all-clear `unless_flag` array missed players who had already built some camp pieces. Sleep/food instructions refer to the selected three. Existing scope/grant semantics and merged27/world2/character6 remain unchanged.

This deliberately replaces the earlier one-bed-only qualification in the opening config, following the recovered three-entrant care requirement in PROGRESSION section7. The first camp remains a useful save-compatible primitive. Extra beds are not a new party-cap rule, and future companions are not sent back through a completed tutorial.

Source audit corrected the old helper census: `band1_lower_meadows/harvest.json` gives4stone per cited stop, not3; seven nearby wood stops give28wood, three stone stops12stone, eight village fiber stops32fiber plus order1000 at(-5,141) gives36fiber. The live-scatter fallback can supply the additional wood; audit found current `trees#318` at(36.342,0.845,-62.648), worth3wood. No payout, placement or depletion rule was changed. This is a source supply finding, not an earned gathering run or proof of the150% reserve/four-player budget. Shared nodes remain one-winner resources.

The old helper's mandatory-house stock69/42/34 is replaced by the current camp bill, calculated from catalogue recipes; its legacy fixture constant is pinned to the same30/8/34. Authored coordinates/stone yields are corrected and the distant(-168,312) fiber stop is removed. The earned camp helper previously confused the five-owned threshold with three entrants; its full plan now agrees with actual three-bed placement. The continuous composition requests full preparation rather than one-bed lesson mode; that source change does not certify a fresh campaign.

Validation on Windows/Godot4.7, working-tree source, isolated profiles:

- Lower-tier focused production batch, root-read log/source:187tests/2611assertions/0failed, `--only=test_home_progress.gd,test_quest_log.gd,test_tournament.gd,test_dialogue_runner.gd`; log `%TEMP%/tetherbound-three-bed-focused.log`. It checks recipe costs, unchanged first-camp meaning, journal progression/legacy retirement and partial-bed signup refusal.
- Helper batch18tests/134assertions/0failed (`tetherbound-three-bed-helper-units.log`); reduced direct camp tests2/4/0 (`tetherbound-three-bed-camp-unit-reduced.log`) inspect actual one-bed versus three-bed plans and live recipe totals. These are separate batches, not unique total coverage.
- Root `smoke_gateb_flags.gd` exits0: real construction registration/restore grants second and third flags only at their thresholds; real bedroll rest and harvest completion still grant progression. Staged inventory/flat-world method calls, not controller or earned-route proof. Existing resource-in-use shutdown error remains (`tetherbound-three-beds-flags.log`).
- First `smoke_gate_b_tail.gd` exits1. From staged five-at-L5/tools/30W8S34F, controller construction places tent/fire/three beds, spends the full bill, assigns Terrapup/Bramblebun/Mudsnout, rests once and reaches signup. The bedroll is placed by the existing paid fixture method. It then reports an obsolete `tournament_build_camp` expectation and no quarter-final start. Log `tetherbound-three-beds-tail.log` preserves both failures; neither a full tail nor an earned opening passes on this attempt.

Required `smoke_playground.gd` exits0 with `smoke: OK`, no SCRIPT ERROR and the same eight normalized distinct ERROR categories as PR157's world boot (`tetherbound-three-beds-playground.log` versus `tetherbound-tournament-playground.log`). Null-material/dummy-renderer shutdown errors remain; this is baseline-equivalent, not error-free.

Initial PR157 full suite is terminal:3839tests/3857078assertions/4failed, exit1 (`tetherbound-tournament-full-units.log`). It began before the PR157 corrections above; character-test preload, Juno text budget and explicit-selection rest expectation were fixed and their complete affected focused batches passed. The fourth failure is the unchanged GateF predicate against historical untracked telemetry, documented above. No full-suite-green claim follows from combining these results. No suite restart was performed.

The tail's obsolete campsite objective was corrected. Its battle driver had accepted any deployed follower, whereas the current director requires the first registered entrant. The fixture now makes that entrant active, then uses the actual recall button to deploy it and checks identity/body; it does not bypass the battle refusal.

Final `smoke_gate_b_tail.gd` on the source committed as36c6ce705 exits0 in279.87s (`tetherbound-three-beds-tail-final.log`). It spends exactly30W8S34F on tent/fire/paid fixture bedroll/three controller-placed beds, recovers all three entrants in one night, signs up, deploys Terrapup through recall input and completes quarter/semi/final in1607/2625/4065 action frames. Saddle is known and the objective names South Bridge. Its legacy terminal wording still says “house”; no house was built or required. The starting team/tools/materials, registrar selection/arena position and bedroll are staged; combat HP is restored by this existing fixture. This proves the preparation-to-bracket connection, not earned gathering, difficulty, controller registrar selection or a novice clear. Seven normalized ERROR categories are contained in the eight-category world baseline; no SCRIPT ERROR. The first failed run remains recorded above.

PR158 contains this slice and its evidence. All engine runs are terminal. No owner play, Ally, render, shared camp,150% supply reserve or chapter acceptance follows from these checks. No third tail attempt or new campaign run was performed.


## Herd landmark and bond payoff

`ralph/herd-landmark-payoff`, based on PR158/9722282ba, connects WORLD section11's herd detour to the existing retained-team progression. No new catch, bond thresholds, ownership slot, task system or saddle unlock is introduced. Rae already supplies the Oskar/saddle lead.

The manual personal landmark `meadowhart_grazing_ground` resolves merged spawn order1005. Walking through its radius alone never discovers it. The existing watch interaction requires the human and active companion within12m; its first successful map discovery synchronously credits every currently owned companion through `BOND.credit_landmark_visit`. The map ID is the saved once-only key. This deliberately follows current whole-party discovery semantics, not CREATURES' unimplemented per-creature revisit candidate. It marks a fixed grazing ground, not a moving wild radar; tracks remain truthful after the wild pair is caught or defeated.

Discovery and the existing three-Basic-Orb ledger reward are independent. Full inventory leaves the item claim pending; legacy completed flags grant nothing on load but allow an actual first revisit for the new landmark without more Orbs. No save schema or world flag is added. Ordinary personal map and creature counters use existing character persistence.

Focused Windows/Godot4.7 results, isolated profiles:

- Map and opening-chain batch: `--only=test_map_state.gd,test_map_landmarks.gd,test_gateb_objective_chain.gd`,50tests/469assertions/0failed; `D:/tetherbound/tetherbound-herd-landmark-map-chain.log`. Root reviewed source and terminal output. Includes manual versus ordinary proximity discovery, explicit one-shot discovery, map serialization and actual configured position versus the merged spawn.
- Herd batch: `test_meadowhart_herd_visit.gd`,5tests/35assertions/0failed, agent-run and root-read terminal log `%TEMP%/tetherbound-herd-focused-units.log`; no world or disk proof follows from these unit results. A requested extra story-budget selector did not exist and was not exercised; no coverage is claimed for it.

Parent PR158 CI35515187150 job106090074956 exposed one stale `test_gateb_objective_chain.gd` failure: the fixture set only the first bed and expected care for all five. This branch corrects the sequence to exercise bed1/2/3 and three-entrant care. Assertions still require each flag to advance the tracked text. No production rule or test threshold is relaxed. Other parent jobs are not evidence for this branch; final full-suite and runtime verdicts follow below.

The existing `smoke_local_requests.gd` now accepts `--herd-only` to select this activity; its default still runs all original activities. The selected mode stages positions, inventory and legacy flags, exercises the production interaction path and saves/loads through the production disk writer/reader. It is not an earned approach, owner fun test, shared visit, renderer/device verdict or chapter acceptance. The activity remains unqualified toward the six-activity floor until those relevant experience criteria are met.

First herd-only world run exits1 (`%TEMP%/tetherbound-herd-runtime.log`). Discovery, full-bag, legacy revisit and disk assertions did not fail, but the parsed interact press did not complete/pay the Orb claim, causing three failures (flag, item count, journal done). This is not a passing activity run. No SCRIPT ERROR; dummy-renderer teardown errors remain. Investigating the input/provider path before a bounded retry; direct activation is not a substitute for the failed input assertion.

Required `smoke_playground.gd` is terminal exit0 with `smoke: OK` (`%TEMP%/tetherbound-herd-playground.log`). It has no SCRIPT ERROR and the same eight normalized distinct ERROR categories as parent PR158's `tetherbound-three-beds-playground.log`; dummy-renderer/material/resource teardown defects remain. No creature data or model changed. No new broad campaign was run. Full unit coverage for the map autoload change will be checked in this branch's actual CI (four ordinary shards plus the separately run harvest, scatter and vegetation tests), not inferred from parent results.

Next-slice audit found a design/source discrepancy, not an authorized quick gate fix: WORLD section3.2 and PROGRESSION section7 target the Bridge grunt before Oskar's final, and FINDINGS line373 attributes that to the owner. The original `b8eda885:archive/owner/OWNER_DIRECTIVES_2026-08-22.md` section2 instead says the tournament happens before Oskar, replaces the bridge gatekeeper with a grunt to free Oskar for a tournament round, and explicitly makes the saddle recipe a promise before Rootstone beyond the bridge. It does not explicitly require the grunt before the tournament final. Current data comments deliberately place the grunt above the final's level and describe the herd as tempting after seeing the tournament mount. The recovered attribution therefore overstates its source. The rewrite's ordering target still needs deliberate reconciliation with this evidence and the out-and-back travel cost; no gate, reward, named-fight order or owner rule was changed in this slice. Do not implement a final-round gate solely from that incorrect attribution.

Second herd-only run exits1 with the same three reward/completion failures (`%TEMP%/tetherbound-herd-final.log`). Added observation proves `input_owner=none` and the actual herd Interactable wins at the original stance. The proposed LOS explanation was therefore wrong; changing nearby stance did not fix it. No further placement tuning is justified. Investigation changes to deterministic reward delivery/fixture state; both failed runs remain evidence rather than being counted as retries that passed.

Source diagnosis: the focused mode mounts Meadows directly and skips title-screen `_set_fresh_player_identity()`. `PlayerState.character_id` remains empty; `ledger_rpc.gd::_reward_recipients()` excludes it and `world_ledger.gd::_reward_grant()` refuses an empty recipient array. The focused fixture now calls the existing fresh-game/save path before mounting the world; `save_game.gd::_character_id_for()` mints the real portable identity. No production authority is bypassed, forged or relaxed. The speculative stance search was removed. A rerun with this specific fixture correction is pending at the initial draft checkpoint.

The first attempt to initialize before world mount stopped immediately because SceneTree `_init()` precedes autoload attachment (`tetherbound-herd-identity.log`, no world boot). Root changed the existing entry point to `_run.call_deferred()` so initialization runs after autoload readiness. The corrected full world attempt writes `tetherbound-herd-identity-final.log`; this is a lifecycle correction, not another stance retry.

Final corrected herd-only run on7c06d1e79 exits0: `Meadowhart herd-only smoke test passed` (`%TEMP%/tetherbound-herd-identity-final.log`). The original stance has no input owner, an enabled arbiter and the correct winning Interactable. The parsed interact earns exactly three Orbs and the personal completion/journal state; missing companion, full bag, once-only discovery, legacy revisit without repayment and duplicate activation assertions pass. Production SAVE_GAME writes slot4; the fixture explicitly destroys the landmark and all party bond counters in memory, verifies the destruction, loads from disk and checks all restored values plus no repeat credit. Seven normalized distinct ERROR categories are a subset of the eight-category Playground baseline; no SCRIPT ERROR.

This confirms the standalone fixture's missing portable identity was the reward failure, rather than LOS. No production reward safety rule changed. Staged roster/positions/inventory/legacy flags remain disclosed; the proof does not establish ordinary approach, shared play, visual quality or an earned chapter. PR159 holds source and evidence. Actual CI35516744797 started on7c06d1e79; it was still in progress before the final evidence update, so no full-suite-green claim is made. The final head's CI must be checked separately.

PR159 final-head CI35516860694 exposed three unit2 failures (job106094503977): the new `landmark` icon had no vendored PNG, causing two texture checks to fail, and the historical named-place census still asserted9landmarks/23places. Root corrected the config to the installed `objective` destination diamond and updated the census to10landmarks/24places, explicitly requiring the grazing-ground name and preserving duplicate-name/external-place checks. This is not new visual acceptance. Focused map/icon/census batch passes54tests/470assertions (`%TEMP%/tetherbound-herd-icons.log`); no SCRIPT ERROR. Other completed unit shards were green, but full-suite acceptance remains pending on the corrected head. The original icon mistake was real and was missed by the earlier focused selector.

## Sela's full-satchel handoff

`ralph/relay-gear-handoff` follows PR159/71dff3cf1. The concrete chapter blocker is in `data/dialogue/relay.json::relay_captive_freed`: its second line gives one `mill_bridge_gear` and sets `captive_rescued`. Previously `sequence_director.gd::_give_items` warned when inventory rejected the item, then `_drain_effects` still set the flag. Sela relocated and the only authored Gear source disappeared, leaving MillCrossing locked. No dialogue, gate, reward amount or story order is changed.

The director now preflights the entire drained effects batch against a scratch production Inventory, copied through public slot methods. It simulates all gifts together, including existing stack capacity. A malformed/unknown/nonpositive gift or insufficient space applies none of that batch's effects, closes the conversation and reports “Make room in your satchel, then speak again.” Freeing space permits the ordinary dialogue retry. Successful batches retain existing effect order and flag authority.

This is capacity protection within one synchronous effect drain, not a durable gift/flag transaction or co-op delivery acceptance. No ledger, schema, flag, effect language or inventory framework is added. SYSTEMS previously stated paired atomicity without distinguishing its target from implementation; that claim is now scoped accurately. Already-corrupted saves are not automatically repaired: item absence cannot distinguish loss from storage, a death bag or another player's possession.

Focused Godot4.7/Windows evidence: `test_dialogue_gift_capacity.gd` passes5tests/21assertions, exercising the actual drain with real Inventory rules and a test flag sink. Cases cover Sela retry, aggregate gifts competing for one slot, existing stack room, flags preceding a refused gift and invalid gift definitions. This is not a host-authority proof. Root also ran `--only=test_dialogue_gift_capacity.gd,test_dialogue_runner.gd,test_inventory.gd`:114tests/1616assertions/0failed, exit0 (`%TEMP%/tetherbound-dialogue-regressions.log`). These batches overlap and must not be summed.

The existing relay smoke gains an optional rescue-only path; its captain battle remains the default. The focused path stages captain defeat and inventory/positions, then checks the actual conversation, refused-state disk round-trip, one-slot retry, relocation, duplicate refusal and existing MillCrossing interaction. This fixture does not establish an earned captain battle, normal approach, chapter pacing or shared rescue.

Runtime failures remain visible. The agent first encountered a Variant-inference parse error, corrected locally, then launched the default captain path because `get_cmdline_args()` excludes arguments after `--`. That run was interrupted (`%TEMP%/tetherbound-relay-rescue-only.log`), with no passing verdict. The selector now uses `get_cmdline_user_args()`. Root's corrected-selector run exits1 on the old fresh-boot assertion that captain defeat must be absent (`tetherbound-relay-rescue-corrected.log`); that precondition now checks the explicitly selected fixture instead.

The next run (`tetherbound-relay-rescue-final.log`) exits1 with two later interaction failures. Actual Sela dialogue refuses the full24-axe satchel without Gear or rescue flag; production Game.save_game writes the refusal state, the fixture removes and checks all axes in memory, Game.load_game restores them, and freeing one slot grants exactly one Gear plus rescue and removes Sela from the relay. Those assertions pass. However, greeting relocated Sela opens no dialogue, and the MillCrossing interact press does not open the gate. The subsequent “did not repeat” print is not duplicate-reward proof because that conversation never opened. Neither the complete rescue-only smoke nor the gate route is accepted. These are unresolved interaction/fixture findings, not grounds to weaken assertions or retune stance repeatedly. No further rescue rerun was performed in this checkpoint. No SCRIPT ERROR; seven normalized distinct ERROR categories match a subset of the inherited eight-category Playground baseline. Required Playground verification follows separately.

The combined unit batch's unknown-conversation ERROR is the existing negative-case test; no SCRIPT ERROR was emitted. No new multiplayer work was added while closing this bounded chapter blocker.

Parent PR159/71dff3cf1 now has complete unit coverage in CI35517435634: all four ordinary unit shards plus the separate harvest, scatter-rules and vegetation-corridor jobs are terminal success. This closes the map-autoload suite requirement on that exact parent head. Region, gate-evidence and core-verb jobs were still running at inspection; this is not a whole-CI-green claim or evidence for the unpushed Sela changes.

Sela slice's required `smoke_playground.gd` exits0 with `smoke: OK` (`%TEMP%/tetherbound-relay-playground.log`), no SCRIPT ERROR and exactly the same eight normalized distinct ERROR categories as `tetherbound-herd-playground.log`. Existing dummy-renderer/material/resource shutdown defects remain. All local engine processes are terminal; no new render, asset, broad campaign or network smoke was run for this slice. The rescue-only smoke remains red as described above.

Source checkpoint:2dea870ec on `ralph/relay-gear-handoff`, stacked on PR159. No merge or release is claimed.


## Current integration CI inspection

Baseline: fetched origin/main `00b55712e6bfd9def625bd80bebaf43a1bdc1db0`; the new
`ralph/warrens-camera-expedition` worktree preserves the old dirty checkouts.
Authenticated GitHub inspection of CI35520003064 on `6cf8f8510` found all four
unit shards successful and no failed job, with several engine/multiplayer
shards still running. Main CI35520273506 remained pending. Parent35518525531
was successful for active jobs; the two known-red campaign lanes were skipped.
These are nonterminal current checks, not a green integration claim.

A subsequent inspection found two terminal failures: multiplayer shard1
`smoke_net_shared_wild_fight.gd` expected `friendly_target` but observed
`replayed_action` after40polls, and shard5 `smoke_net_stormwood_livewire.gd`
failed the released-baseline pre-deadline-window assertion. Both are under
focused parent/source/log comparison; no production-regression or fixture-only
verdict follows from the job badge. Gameplay fixes pause for this triage.

Main Release35520100743 (`8e190646c`) failed `Verify the exported build actually
runs`. It reported `EXPORT-CHECK terrain=yes ground_at_spawn=0.90
player_y=2.90 props=383315`, then exit139. Earlier main runs35478661613 and
35473466833 failed the same check after the same setup receipt with exit134.
The changed signal is unresolved; it does not identify a gameplay regression.
All three failed runs have zero artifacts. `tools/verify_export.sh` redirects
runtime output to `build/linux/run.log` but prints only its first five matching
error lines, which in these jobs are ALSA device warnings. No actual crash
stack can be recovered from the retained jobs. Export acceptance stays red.

Source review also found main pushes automatically published the rolling
release/tag and Pages when build succeeded, conflicting with the owner's
explicit no-publication instruction. The bounded workflow correction retains
main build checks but requires manual dispatch with `publish=true` for those
three mutations; the default is false. Failed export runtime logs are retained
for three days as CI artifacts. No publication or workflow dispatch is run as
validation; this guard changes no gameplay and does not repair the crash.
Sol implemented the isolated workflow diff; Luna reviewed the complete
release/tag/Pages mutation paths and found no gate blocker. YAML lint and
scoped whitespace checks pass. Root inspected the exact diff and conditions.

## Guardian signature and integration handoff

The owner authorized main integration and a successor plan. ROADMAP now owns the entire remaining sequence; STATE owns the integration receipt. This closes out current work, not the persistent four-chapter game goal. PR160 head7c580b641 has terminal-success CI35518525531; known-red campaign jobs and export were skipped. Earlier wording withholding merge authority is historical and superseded by the current owner request.

The guardian previously equipped Earth Fist but the shared enemy damage path always read move_quick. `burrow_warrens.json::guardian.combat` now opts into charged_every2, charged_telegraph1.1, charged_recovery1.2 and charged_face_lock_fraction0.5. Quick attacks return to generic90degree/3.4lunge geometry; Earth Fist supplies72degree/6.5lunge/minimum3.8range. The body snapshots one spaced profile at tell start, including quick IDs, and preserves it through recovery. Stagger consumes that attempt and clears the selected profile; fresh engagement resets to quick. Heavy direction commits for the latter half of its tell through recovery. Lazy MoveDB allocation avoids parsing moves on ordinary body creation. The solo and host-participant resolvers use the selected ID for type, power multiplier, VFX and hit payload. The inherited authoritative path uses the same helper; no wire schema, enemy energy meter, player move, trainer rollout or Water bespoke boss change is included.

Root review caught and corrected initial overreach: snapshots had affected ordinary wilds, the quick ID was not frozen, and MoveDB was allocated for every body. The final production code keeps the cadence-off legacy path. Bounded fixed-RNG tests distinguish a Ground charged move from an Air quick move and exercise actual solo and host damage resolution; the focused set is test_enemy_named_attack, test_encounter_combat_override, test_combat_stagger and test_creature_attack_telegraph_animation.

Rendered real-world witness: Godot4.7 Compatibility/OpenGL3, GTX1060,1280x720, existing `smoke_warrens.gd -- --guardian-attacks --capture-dir=<absolute>`. It initializes through deferred autoload readiness and production save identity, stages TerrapupL12/guardian position, pins HP and uses the real encounter director/CombatManager. Terminal exit0, Q/C/Q/C, one hit and three misses; timing, geometry and committed heading assertions pass. This is staged state behavior, not an earned fight, legitimate player dodge, defeat/reward, difficulty or co-op acceptance. First draft parse/type and identity initialization corrections preceded this run; no failed rendered verdict was discarded.

**Both rendered frames are REJECTED:** trainer hair and near geometry obscure the guardian and its response space. `guardian_quick_tell.png` and `guardian_charged_tell.png` preserve the actual normal active-camera captures. Do not infer visual acceptance from the mechanics pass. The successor first diagnoses ordinary camera/placement ownership against this fixture and natural engagement, repairs the originating live defect if reproduced, then recaptures. No camera/code polish is added during handoff. Existing generic tell animation does not satisfy the planned bespoke foreleg/armored-front/active-hitbox target.

Damage ceiling calculation at the declared L12 starter versus L14 guardian entry uses current stat growth, IV±12%, enemy12*1.6, EarthFist1.4, global damage2, max variance1.1 and current type chart. Average-IV peak hit as percent of maximum HP: Terrapup13.18%, Ripplet13.15%, Galewisp25.79%. Enemy-max/ally-min IV peak:17.00%,16.79%,32.57%; with the existing stagger critical1.5:25.50%,25.19%,48.85%. Formula is `12*1.6*1.4*2*ATK/(ATK+DEF)*type*1.1`, with optional1.5. No bond/food buffs assumed. This is below50% at that declared entry only; it is not a lower-level/all-roster balance or fun verdict.

Required Playground is terminal exit0 with `smoke: OK`, no SCRIPT ERROR, exactly the same eight normalized distinct ERROR categories as PR160 parent. Compare numbers normalized within ERROR lines, not counts alone; added/removed sets are empty. Existing headless dummy-renderer/material/resource teardown errors persist. The rendered witness separately emits OpenGL RID/buffer/resource exit leaks and an interpolation deprecation warning; neither is presented as an error-free engine run.

Unrelated older PR127,129,130 are not implicitly accepted or merged by this integration. Selected Warrens egress work was ported explicitly in503ed3de5; older whole-branch combat/Cloudreach verdicts require source reachability and fresh review. No new publication, spending, package acceptance or full-game completion is authorized or claimed.

Root independently reran the frozen focused unit set:23 tests/119 assertions/0failed, exit0; no SCRIPT ERROR, one3-ObjectDB cleanup warning. Raw logs are preserved beside the captures under guardian-signature. This independently confirms the delegated result.

## Guardian camera: staging and ordinary-approach diagnosis

Two rendered controls on main d1a79eb19 (Godot4.7 Compatibility, GTX1060,
1280x720) separate the old fixture from normal encounter admission. The opt-in
`--guardian-camera-diagnose` records target, pivot/lens, requested/hit arm depth
and lens overlap; `--guardian-settled-approach` seeds the supported hall floor,
settles the player camera, then uses movement input until guardian admission.
It is not a fresh earned Warrens route; HP pinning and the heavy lateral
position write remain explicit staging.

Original immediate teleport/engage: formation targets AllyCreature, but both
tells target Player with the exploration profile. The deferred GrandpaHouse
exit unconditionally retargets Player after combat has taken the rig. Both
frames remain rejected; Q/C/Q/C and one hit/three misses pass. Local evidence:
`D:/tetherbound/expedition-guardian-baseline.log` and matching capture directory.

Settled hall control: guardian admits after18.7m of input walking; both tells
correctly target AllyCreature. Both frames still fail: the ally and nearby
roots obscure guardian tells/response space. Quick arm requested/hit2.67m;
heavy2.02m, no lens overlap. CombatManager caps requested depth using the
minimum nearest-wall radius around any combat actor, regardless of camera
direction. Formation had requested/hit5.20m before this cap converged. This
reproduces a normal-play framing defect independently of the staging target
overwrite. Local evidence: `D:/tetherbound/expedition-guardian-approach.log`
and matching capture directory. Q/C/Q/C, timing and heading assertions pass,
but zero hits/four misses fail the unchanged hit-and-miss assertion. This is
diagnostic evidence, not a passing mechanics or player-acceptance result.

The first uncapped-depth control is also REJECTED, not an accepted fix.
`expedition-guardian-depth` captures show cave geometry across the foreground.
Quick requested7.05m/hit4.35m; heavy7.80m/4.30m; lens probes now overlap named
Warrens static bodies. Target remains AllyCreature. Q/C/Q/C timing/heading
pass but0hits/4misses still fail the unchanged resolution witness. Follow-up
is the authored room/admission placement, not further blind distance tuning.

Postguard Release35521074818 now retains artifact10609115962,
`exported-build-failure-log`. Root downloaded and read `run.log`: world setup
succeeds, then GLES leaks, a nonexistent Trainer_1 tree_exiting disconnect and
`corrupted size vs. prev_size in fastbins` precede `Aborted (core dumped)`.
This supplies the previously missing shutdown tail; it does not identify the
native root cause or close export acceptance. Current main CI35521573708 was
pending at inspection. No reruns or publications were requested.

The depth22 room trial is also REJECTED. The full7.06m/7.78m arm clears all
structural collision boxes, yet both frames show opaque cave earth across the
whole fight. The visible `_excavated_chamber_shell` is separate from those
hidden boxes: its walls slope inward to0.73radius and0.72authored height, and
its crown reaches only0.80height. Thus the nominal7m roof is not7m of visible
room. Stop box-dimension guessing; correct the actual shell/camera envelope
before claiming the room works. This run also reports four heading-lock
failures and0hits/4misses; those failures are preserved. All four controls and
unaltered captures are saved under `guardian-camera/` beside this report.

Stronghold regression passes with the cap removed: real cardinal orbit
samples contract against authored walls to6.32m,2.34m and9.34m with requested
arm around12m; camera depth follows the hit, interior shoulder remains0,
and controller orbit/exit restoration pass. The first draft's assumption that
the initial bearing must hit a wall was false and was corrected to sample
existing room bearings. This is collision/orbit evidence, not visual chapter
acceptance. A review follow-up reads current requested distance at each sample
instead of reusing the pre-sample snapshot.

The den-only shell profile uses0.90wall/1.0crown height and0.96upper radius,
with original defaults for other rooms. The actual generated-mesh regression
first failed both recorded pivot-to-lens segments and actual roof headroom,
then passed9tests/141assertions. Root review caught an initial all-room roof
formula change; the corrected empty-profile path reproduces parent hall,
warren and vault vertex/index arrays exactly. See shell-red-summary.log
(agent transcript), shell-green.log and shell-default-equality.log.

The `shell` rendered control clears the cave foreground: both bodies and
surrounding floor are visible. It is not yet encounter acceptance. Real quick
strikes still miss at3.03m within8.49m reach, with facing precisely45degrees
away from the target. Source confirms `creature_body.face_towards` converts a
world-space target into LOCAL yaw beneath the rotated Warrens parent. This
explains the quick cone's borderline refusal and uncommitted heavy mis-aim;
no range increase is justified. A rotated-parent regression and coordinate
correction are next. Engine physics-clock timing replaces observer-loop
counts, so screenshot waits no longer extend the heading window; this control
has no timing/heading failures. Diagnostic boolean inference was corrected
before this rendered run and the script passed check-only parsing.

The world-to-parent yaw correction passes the natural guardian witness:
Q/C/Q/C,2real hits/2staged misses, quick aim0degrees and committed heavy
side-step90degrees. Focused named-attack/override/stagger/animation checks:
24tests/123assertions pass. Luna reviewed both world-direction callers and
identity/top-level behavior. The attempted live-node unit fixture was invalid
under this runner's pre-tree initialization and is not reported as valid RED;
the final pure test invokes the actual production conversion helper, while
`facing.log` proves the live path.

Both `facing` frames remain REJECTED for tell readability: cave foreground is
clear, but the now-correctly aligned ally hides most of the guardian. The
blanket interior zero-shoulder workaround recreates the original body-occlusion
problem. Next correction is collision-safe lateral pivot movement using the
existing rig sphere-cast helper, preserving directional depth collision and
controller orbit. No attack range, cone, damage or body size was changed.

Swept-shoulder witness: ordinary input admission after 19.0m, Q/C/Q/C, two quick hits and two staged heavy misses. Both shoulder-quick.png and shoulder-heavy.png remain REJECTED: cave obstruction is cleared but the ally obscures too much of the guardian. This does not close visual acceptance. Latest weekly remaining26%.

Live shoulder follow-up: max_shoulder_offset4.5 plus smoothed per-frame gap/depth refresh still fails image-only review (quick and heavy): guardian stance/feet/attack line remain behind Terrapup. Raw live-shoulder captures/log retained. Full Warrens geometry smoke PASSED (geometry.log), including walked52m route and one-time reward/rebuild. Stronghold swept-shoulder cardinal orbit/collision/entry/exit PASSED (stronghold-shoulder.log); existing Dummy renderer exit leaks remain. Next isolated framing change biases neutral tracking35degrees off the ally-enemy axis, preserving manual grace and wall collision. This is under rendered verification, not acceptance. Weekly remaining25%.

Oblique tracking witness: mechanics2hits/2misses PASS, both oblique captures FAIL because the lens is outside the visible den skin despite remaining inside hidden structural collision. The shell profile alone only proved the earlier bearings. Added den-only VisibleDenBoundary from the generated shell triangles with backface collision so inside-to-outside camera casts meet the actual visible surface. Guardian rendered verification and affected geometry rerun pending; no acceptance claimed.

Visible-den-boundary witness: Q/C/Q/C,2quick hits/2staged heavy misses PASS. Image-only Terra review of accepted-quick.png and accepted-heavy.png: both PASS for ordinary tell/attack-direction/lateral response-space readability; head/shoulder/forward claw distinguish Guardian from Terrapup, heavy ring visible. Root concurs at this bounded scope. Fixture still seeds hall approach and stages sidesteps; no earned whole-fight/chapter acceptance. Final geometry/camera/Playground regressions pending.

Final geometry caught a real regression with layer1 den skin: walked vault approach stopped6.5m short. Preserved den-gameplay-collider-route-red.log. Restricting VisibleDenBoundary to shared CameraRig.OCCLUSION_ONLY_LAYER (bit32), included by camera arm/probes but excluded from ordinary layer1 player/creature movement, preserves original traversal collision. Previous accepted frames are now superseded pending camera-only recapture and geometry rerun. The focused blanket noncolliding source assertion was replaced with generated triangle/alignment/backface and den-only checks; initial updated suite9tests/156assertions passed before layer refinement.

Final camera-only recapture: accepted-quick.png/accepted-heavy.png and accepted-witness.log now refer to the final layer32 surface; earlier full-gameplay-collider files are preserved as gameplay-boundary-*. Image-only Terra review PASS/PASS; quick crowded but head/shoulder/forward claws and direction remain distinct, heavy head/extended claws communicate commitment, right-side floor is readable response space. Mechanics2quick hits/2staged heavy misses PASS. Updated den geometry unit9tests/158assertions PASS. Final serialized regression batch is running.

Final camera-only geometry regression PASSED, including52m walked cave/vault route, enclosure, grounding and one-time reward/rebuild (final-warrens.log). Final Stronghold collision/orbit/entry/exit PASSED (final-stronghold.log). Playground smokeOK; normalized distinct ERROR set exactly matches8parent categories, no new category (playground-error-set-comparison.json). Existing resource/RID/PagedAllocator/null-material shutdown errors are retained, not called clean. Open-field first run failed a monotonic-distance assertion: near3m13.67 versusfar9m10.67 because shoulder clearance now varies. Replaced that assumption with actual Camera3D projection of both live render-bound corner sets at each requested pose, preserving base/cap and controls; current rendered smoke pending.

Final open-field rendered camera smoke PASSED: requested render-bound corners fit at3m/9m; physical movement/orbit, neutral tracking, switch, aim/cancel and repeated exploration/combat transitions pass (final-combat-camera.log). Open-field-entry.png is a production camera after physical engage and90physics frames; existing small-creature/vegetation contrast is not claimed fixed. Guardian acceptance remains the accepted quick/heavy pair plus scoped mechanics, route, camera and Playground regressions; no chapter/campaign claim. Source reviewed by Sol; root reviewed source/test diffs and all capture pairs. No new distinct Playground ERROR category versus parent.

### Main combat smoke correction

Main CI [35526931266](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35526931266) passed all four unit shards and all seven multiplayer shards. Its combat job 106120868041 failed the old nearest-pivot camera assertion on both attempts (trainer 3.6m, creature 3.8m). The wider shoulder makes that comparison invalid. The open-field smoke now subtracts the configured height and shoulder from the measured live pivot before comparing followed anchors; a camera actually following the trainer still fails. Sol reviewed this as valid for the settled, unobstructed fixture only. Live camera line-of-sight and minimum-distance checks remain.

The first local replay passed the camera checks but exposed an existing damage-estimator omission: its ordinary type-chart prediction does not include poise critical damage. The smoke now neutralizes only `poise.crit_scale` in its process-local config cache, leaving authored production tuning and stagger/interrupt behavior intact. This is a chart-isolation fixture, not a combat-balance claim. The separate authored stagger suite passes 9 tests / 40 assertions at the production 1.5 multiplier.

Final smoke passes: camera 6.4m with clear line of sight; 4.3m input movement; arena containment; misses and enemy retaliation; five landed blows, win, and retained post-fight HP. Damage 120.7 versus typed expectation 114.5 (neutral 91.6). No SCRIPT ERROR. Existing dummy-renderer RID shutdown errors remain. Evidence: `combat-follow-check.log`, `combat-follow-check.stderr.log`, `combat-stagger-units.log` in this directory. This check ran with uncommitted Meadows activity content present; it exercised the ordinary practice fight, not those activities. No release/export repair or new visual acceptance is claimed here.

### Six Meadows activities: content qualification

Evidence is in `six-activities/`. This slice repairs existing content; it does not claim chapter progression, co-op or the region presentation gate.

| Region / activity | Lure and action | Useful retained-team payoff and acknowledgement |
|---|---|---|
| Lower Meadows / herd | Visible grazing group and Rae's lead; walk off the trail with the active companion and visit together | Three Basic Orbs, personal landmark and bond credit for the owned team; visited-together message |
| Lower Meadows / Old Bram | Named field trainer and conversation; optional two-creature battle | 60 coins, five Greater Orbs, three Small Potions and battle XP; defeated conversation |
| Stone and Root / Warrens vault | Side passage, visible Elder and Heartstone; choose the Elder fight, then take the stone | Two Large Potions from the Elder, independent of species; Heartstone additionally supports Mudsnout evolution; receipt and pickup messages |
| River Lock / Doss | Ranger beside visibly buckled bank boards; provide one wood and one fiber | 45 coins, one Large Potion, repaired platform and repeat thanks |
| Upper Meadows / Juno | Missing-companion lead toward the Tether patrol; defeat Rue and return | 50 coins, one Revive, reunited world-owned Meadowhart and thanks; optional friendly bout can be declined |
| Hall approach / Alpha Galecrest | Visible west-shoulder alpha beside the approach; engage and defeat it | Two Large Potions and one Revive; west-shoulder acknowledgement and once completion |

All five principal regions are covered; none of these six ends in a generic chest. No new owned creature is required. The Heartstone alone was insufficient for a retained team without Mudsnout, so the Elder now has its own recovery receipt; the required guardian's earlier reward is not counted as optional-vault payoff.

Doss now stands at (72,4187.4), beside the actual river rather than roughly 220m south of it. The rotated perch centre (70.036,4191.998) is outside the carved bank rim; a 2.3m ground probe found 0.15m relief and 4.4-degree maximum slope. Existing flags remain compatible. Inventory preflight checks the entire reward after spending materials. Cleared greetings remain available without repayment. The existing pending-client claim/spend seam is not fixed or accepted as co-op here.

Juno's reunited greeting owns an explicit battle confirmation. TrainerNPC suppresses its automatic battle scheduling only when that exact trainer's terminal confirmation owns the battle effect. Declining now closes without combat. The rendered witness exposed a missing menu_cancel glyph; the subsequent glyph-only correction maps the existing Escape/B art, with focused coverage. The retained Juno image precedes that glyph correction.

The vault is 14x14m under a 7m roof, with the den shell profile and a camera-only visible-surface boundary. Its centre, Elder and Heartstone anchors remain fixed. Room expansion alone did not prevent the Elder's global 14m aggression radius pulling combat into the doorway. This optional Elder now uses the existing manual engage action inside the room. No capture was edited. Hall and Elder recovery receipts reuse existing per-item/per-participant durable delivery; only wins/catches pay, and full bags retain pending delivery.

Runtime qualification: `meadows-local-qualified.log` passes Doss, herd and Bram; its sole failure was the old Juno witness accepting Yes before attempting Later. The corrected `meadows-juno-qualified.log` passes the rescue, visible reunion, parsed decline and disk roundtrip. `meadows-vault-prompt.log` passes ordinary entrance-to-vault walking, manual Elder admission, input-piloted victory, exactly two Large Potions, Heartstone pickup and disk reload without repayment. `meadows-hall-retained-final.log` passes road approach, actual alpha victory, exact recovery receipt and disk reload. Five owned UIDs remain unchanged in the combat/reward witnesses. Fixtures seed one starter and four ordinary companions; local trainer fights retain the existing 6HP opponent/healing allowance, while Elder/Hall use the normal combat pilot. This proves bounded activity wiring and reachability, not earned acquisition or balance. The guardian-clear prerequisite and disabled non-Elder aggression are declared vault fixtures.

Rejected witness attempts are not acceptance: early vault captures were obstructed, a one-tick engage press was unreliable, and walking beyond the visible Engage prompt selected nearby Gather instead (`meadows-vault-final-receipt.log`). The final route engages from the ordinary room marker. Final root checks pass 156 tests / 2034 assertions. Required Playground smoke exits 0 with `smoke: OK`; its eight normalized engine ERROR categories exactly match the parent baseline, with no SCRIPT ERROR (`playground-error-set-comparison.json`). Existing renderer/resource shutdown failures remain.

Sol's single code-blind batch verdict is **limited activity evidence**, not a presentation pass: vault route, subject, engage prompt and payoff are readable, with no solid foreground wall/ceiling hiding the room action; the large companion still obstructs substantial fight/reward space. Doss's acknowledgement is clear but the platform is cropped and world-body overlap remains. Juno and the returned companion are visible and the choice is explicit, but followers crowd both sides. Root retains those limits. Terra/Sol reviewed implementation; Luna independently reviewed the final Warrens receipt handoff and terminal semantics.

Parent main CI35529469139 passed gameplay, regions, all four unit shards and all seven multiplayer shards. Export failed and the two explicitly known-red extended jobs were skipped; neither is claimed accepted by this slice.

### Doss co-op repair witness

The Doss atomic unit run passed **53 tests / 299 assertions**, including the sparse `{}` request failure canonicalized to `null`. Exact source logs are retained in `doss-coop-repair/doss-units.log`.

The first runtime witness is retained as `doss-coop-repair/runtime-fail01.log`; it failed when the parsed interaction did not clear the bank perch. The corrected second witness is retained as `doss-coop-repair/runtime-pass02.log` and exited 0: Doss is at the authored position `(72, 4187.4)`, the normal parsed prompt interaction paid the authored reward, left the five owned IDs unchanged, survived production save/load, and a repeat interaction did not repay. The production request now represents empty inventory slots as `null`, matching the existing host validator.

This is a local single-player runtime witness. There is no two-peer runtime acceptance yet. The known world-journal/personal-save crash window remains outside this witness, and the existing renderer shutdown errors are retained in the exact logs rather than treated as Doss failures.
`tests/smoke_playground.gd` also exited 0 with `smoke: OK`; its eight engine ERROR categories match the preceding accepted activity baseline, with no SCRIPT ERROR (`doss-coop-repair/playground.log`).

### Warrens guardian payoff witness

The focused unit evidence passes **43 tests / 164 assertions** for `wild_once` and `encounter_rewards`; the flag scope check passes **11 tests / 293 assertions**. Exact logs are retained in `guardian-payoff/guardian-payoff-units.log` and `guardian-payoff/guardian-flag-scopes.log`.

The first runtime witness is retained as `guardian-payoff/guardian-reward-01-rejected.log`. It reached the guardian reward path and passed the gameplay assertions, but emitted the unscoped `reward:trainer:warrens_cleared:xp:1` error during the save/reload path, so it is rejected. The corrected second witness is `guardian-payoff/guardian-reward-02.log`; it exits 0, passes with no SCRIPT ERROR, and retains only the known renderer/resource shutdown errors.

The accepted witness is a real input victory after walking from the entrance into the den and ordinary guardian aggression. It records the exact configured payoff: 90 coins, five Rootstone, two Greater Orbs, one Revive, one Hide Vest, +140 XP plus normal combat XP; the same five owned UIDs remain. The physical vault collider opens, production save/rebuild retains the clear, and a repeat attempt does not repay. Previously the clear flag suppressed the old payout and door poll; now durable participant journals precede a victory clear, and XP has its own receipt. A failed win can retry without duplicate payment.

This is a solo runtime witness; there is no two-peer Warrens acceptance yet. If a payout save fails after a catch, the caught state remains consumed; an uncommitted reward component can remain unpaid, which is a known bounded limitation. Existing renderer exit errors remain in the retained log and are not treated as gameplay failures.

Required Playground smoke exits 0 with `smoke: OK` and no SCRIPT ERROR; its eight engine ERROR categories match the preceding baseline (`guardian-payoff/playground.log`).

### South Bridge authoritative automatic opening

The two-peer earned bridge witness defeated the actual two-creature guard (2644 frames / 59 swings), but the host spent its key while the guest's bridge stayed shut. The automatic path called ItemGate directly against merged progression, bypassing the world ledger. Automatic opening now uses the inherited ledger-aware interaction, retries delayed key delivery and approaching after earning the key, and suppresses repeated pending requests. This retains the existing manual interaction's pending-spend limitation; it does not claim a new atomic key transaction.

Focused checks pass 20 tests / 58 assertions (`bridge-authority/units.log`). The existing real-world challenge smoke exits 0 and proves the guard approaches, opens the challenge dialogue, and the earned-key fixture automatically opens the gate and consumes one key (`solo-challenge.log`). Its late-arrival/adopt-starter error is retained; it is not a clean opening acceptance. Required Playground exits 0 with `smoke: OK`, no SCRIPT ERROR, and the eight preceding engine error categories (`playground.log`). Root reviewed Sol's change and strengthened the pending test with a second held key.

`two-peer-rejected.log` remains rejected: the guest also stayed in combat controls after the shared trainer victory, so its physical crossing and subsequent Doss interaction were not accepted. The host discarded the terminal trainer record before broadcasting it. That separate completion defect is not fixed or claimed by this bridge change. Two-peer corrected automatic opening remains unverified at this checkpoint.

### Shared Meadows trainer completion returns control

A host's final trainer victory closed and immediately forgot its encounter record without publishing the terminal state. The guest therefore stayed in combat input with trainer locomotion disabled. Final closure now broadcasts the existing terminal record between close and forget; the guest resolves through its ordinary combat exit. This does not change between-creature rounds or the preceding reward publication.

The existing two-peer Bryn reward smoke passes after an actual two-creature fight (1849 frames / 33 swings). Both peers report world input and enabled locomotion afterward; each receives 20 coins and one Small Potion, with matching durable journals and accepted deliveries to two stable character IDs (`trainer-coop-exit/two-peer.log`). Focused encounter host/reward checks pass 53 tests / 228 assertions (`units.log`). Terra implemented; root and Sol independently reviewed final-only closure and reward ordering.

Exact peer logs retain the fresh-fixture late-arrival/adopt-starter error and the guest's already-over encounter disengage refusal. There are no SCRIPT ERRORs. This is a trainer completion/reward witness, not acceptance of the opening, the entire Meadows chapter or a four-peer session.
Required Playground exits 0 with smoke: OK, no SCRIPT ERROR, and the same eight engine ERROR categories as the preceding checkpoint (trainer-coop-exit/playground.log).

### Earned two-peer bridge and Doss crossing witness

`coop-crossings/two-peer-pass06.log` passes the actual two-creature South Bridge guard (2644 frames / 59 swings), both peers returning to normal controls, replicated automatic opening, exactly one key consumed from two participant rewards, and both players walking the authored deck. The first team walks beyond the far landing before the second follows. `landing-blocked05.log` retains the rejected previous attempt: the first team stopped on that landing and obstructed the second team's last metres. The accepted run uses five declared level-12 companions per peer and near-site placement; no enemy HP ceiling or completion flag injection is used. The explicit client interact follows automatic opening and is an already-open no-op, not evidence of a client gate request.

The client then uses Doss's actual prompt with one wood and one fiber: both peers receive the repaired-bank world flag, only the client pays the exact costs and receives 45 coins plus one Large Potion, and repeating the interaction pays nothing. Both production save/load arms preserve the five companion UIDs; the guest reloads its character without replacing the hosted world, while the host reloads its own slot. The final live world hashes agree. Exact peer logs contain no SCRIPT ERROR or ERROR entries.

The additional read-only disk check (`saved-state-check.json`) verifies the saved host world retains the guard defeat, open bridge and Doss repair; saved host/client inventories hold the exact 25/70 coins, 0/1 keys and 0/1 Large Potions; both saved parties contain five companions; accepted reward recipients match those character files. It records hashes of the source saves. These are in-place load and persisted-file checks, not a cold two-peer reconnect or a complete Meadows chapter acceptance.

Sol reviewed the staged witness and root checked its selected runner functions independently. The runner changes expose only the live crossing position and the existing owner-appropriate save/load operations needed by this witness; untested opening/tournament setup changes remain excluded. Existing default gate replication behavior is retained.

### Co-op opening replica collision

The fresh two-peer opening reproduced a real collision failure: both trainers occupied the bed spawn, the host became entombed at y=6.40, and normal player recovery lifted it to y=12.00 on the roof. Subsequent input walking stayed at y=12.35 while Grandpa's prompt was at y=2.35, correctly offering no greeting. Exact pre-fix evidence is retained in `coop-opening-collision/roof-failure05.log` and `roof-host05.log`.

Remote trainer replicas now bind reciprocal collision exceptions with the current local player, including late arrival and local rig replacement. Their authored world collision layers/masks remain unchanged. This prevents replicated trainers pushing the player while preserving terrain, building and NPC collision. It changes no authority, realm transition or traversal state. Sol implemented; root and Luna reviewed.

The corrected two-peer run walks the host down the actual stairs to y=1.70, reaches Grandpa at y=1.32, opens/advances his real greeting, opens the starter picker and selects a starter into the naming dialog (`floor-greeting06.log`). Neither peer log contains an entombed recovery, SCRIPT ERROR or ERROR. The whole opening test is still rejected: its hardcoded naming-grid navigation stopped at row 6/column 3 instead of Done. That later fixture failure is retained; this checkpoint accepts only collision recovery and the reached greeting/picker path, not a finished opening.

Eight focused visibility/collision/velocity tests pass (23 assertions). Required Playground passes with smoke: OK, no SCRIPT ERROR, and the same eight engine ERROR categories as the preceding checkpoint. Current guardian-payoff main CI35536192381 passed every gameplay, unit and multiplayer job; its existing export failure and two explicitly skipped known-red jobs remain unaccepted.
