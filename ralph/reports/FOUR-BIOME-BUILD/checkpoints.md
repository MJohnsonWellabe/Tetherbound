# Four-biome build checkpoints

## Checkpoint 0 — 2026-09-07

- Player-visible capability added: none in this checkpoint; the integration base
  was stabilized and landed before new content work.
- Paths newly reachable: none yet.
- Systems newly working in real play: hosted Stormwood combat now keeps the
  client's opponent stand-in synchronized to the host before each real attack,
  and the hosted multiplayer proof passes.
- Content added: none.
- Merged SHA: `7ab4a12647a377a400c43335b64aff8b03ca6d43` (PR #79).
- Evidence: final PR #79 CI run `34151037848` completed all 26 executable jobs
  successfully; the three non-executed jobs were intentional known-red/export
  skips. All seven multiplayer shards and solo regression passed.
- Blockers: the save rewrite, HUD map second-open behavior, and second-bed freeze
  still require their contract proofs before new biome content. Meshy spend is
  blocked because the supplied API key and credit ceiling are placeholders.
- Next highest-value task: run the SAVE, HUD-MAP, and STAB proof lanes in parallel,
  then integrate only evidence-backed results.

## Checkpoint 1 — 2026-09-07 14:32 CDT

- Player-visible capability added: the Settings debug-teleport catalogue now offers
  Meadows, Cloudreach Cliffs, Stormwood, and Water Archipelago, with two authored
  destinations in every named band, region, or island.
- Paths newly reachable: the menu can request no-key debug crossings among all four
  implemented realm scenes. The production smoke completed Meadows -> Cloudreach ->
  Stormwood -> Water -> Meadows through real scene changes and grounded the live
  player at each selected destination.
- Systems newly working in real play: the PR #80 scatter-freshness failure was fixed
  by rebaking the committed Meadows manifest after the vegetation change. The bake
  retained 825,979 placements and the focused freshness check passes 1/1.
- Content added: 58 curated test destinations across 5 Meadows bands, 6 Cloudreach
  regions, 6 Stormwood regions, and 12 Water islands. The fast catalogue/anchor
  contract passes 3 tests and 394 assertions.
- Integration head: `160c598f7`; pushed CI head: `9d4712497` on draft PR #80.
- Evidence: PR #79 is merged after all executable jobs passed. PR #80 rerun
  `34155697795` has entered its full matrix. Settings' physical controller smoke
  reaches all 58 destinations at 1280x800 and passes. HUD-MAP's automated rollback
  checks and clean first-open/close/minimap/second-open captures prove the rollback
  exit; the blind judge confirmed capture integrity and no second-open corruption,
  while rejecting the full map's pre-existing label crowding for the repair pass.
  STAB removed the reproduced infinite second-bed recursion (10/10 two-bed cycles),
  but its 180-second proof remains red on a 536.7ms synchronous fallback-autosave
  frame; SAVE owns the coordinated follow-up.
- Blockers: Meshy spend remains blocked by placeholder API key/credit ceiling. SAVE
  proof and the synchronous autosave hitch remain open Phase 0/1 blockers.
- Next highest-value task: finish and integrate SAVE/STAB/HUD-MAP proof, execute the
  four-realm teleport smoke, then start ROAD and build-size lanes in parallel with
  the Stormwood/Water completion work.

## Checkpoint 2 — 2026-09-07 16:25 CDT

- Player-visible capability added: Stormwood's six authored named encounters now
  mount as real once-only/catchable alphas, the Crown Guardian durably gates Wen
  and the Rootgate heartstone, and all 32 installed Cloudreach/Stormwood/Water
  species are assigned to their intended wild, trainer, named, alpha or legendary
  tables. The Marrow/Dynamo controller is implemented locally and awaiting its
  exclusive-engine validation before commit.
- Paths newly reachable: the four-realm Settings teleport proof remains green.
  Stormwood's ordinary-play path now reaches the guarded Crown truth/Rootgate seam;
  the Dynamo climax and the Water handoff are not yet claimed continuously proven.
- Systems newly working in real play: the 180-second fallback autosave now writes
  an immutable snapshot on one worker. The production two-bed soak completed ten
  cycles and one save with a 107.6 ms post-warmup maximum, down from 536.7 ms and
  below the unchanged 250 ms hitch threshold. Atomic recovery (18/114), the save
  matrix (157/926), and a real persistence reload all pass. The full suite remains
  only on the same two known Gate-F methods (2,877 tests / 3,835,113 assertions).
- Content added: named Stormwood encounters/Crown gating; later-biome roster table
  substitutions; a five-creature Marrow roster; and the host-owned three-phase
  Dynamo implementation in the working tree. ROAD-VISUAL is authoring a 1.90–7.20m
  creature-height ladder, four-biome road anchors and color/material-first species
  presentation. WATER-SWIMSTONE has a static host-validated Iona late-join
  attunement ready for engine proof.
- Art/credit ledger: Meshy balance was 1,190 before spending. The Galecrest pilot
  preview spent 20 credits (`01a07d7d-0714-704f-a434-c3801bab75da`), leaving 1,170.
  Its first independent preview judge rejected the head/beak/chest read, so no
  refine or rig credits were spent. Four-angle in-engine rendering is queued after
  BUILD-SIZE releases the Godot lock; no self-judging will be used.
- Build-size: exact baseline was 610 texture sidecars, 497 Lossless and 113 VRAM.
  The lane reduced its intentional runtime set from 263 to 255 after proving eight
  unsuffixed generator inputs are duplicate JFIF bytes under invalid `.png` names,
  not runtime textures. Export size/hash evidence remains in progress.
- Integration head pushed: `54c74f6b6` on draft PR #80. CI run `34162302349`
  exposed two real contract failures before a follow-up push cancelled the rest:
  Cloudreach's test still expected the old placeholder art status, and the recipe
  writer census omitted the production Crown Guardian flag required to reach Ember.
  Both were repaired without loosening their contracts. That run also showed the
  expected interim ROAD baseline drift after the roster swap; ROAD-VISUAL owns the
  zero-failure replacement. Follow-up run `34162873951` is in progress.
- Blockers: only one Godot/import/export process may run at a time; BUILD-SIZE owns
  it now. Dynamo, WATER-SWIMSTONE, ROAD-VISUAL runtime checks and the Galecrest
  render are queued behind that lock. ROG Ally first-hour and rendered frame-rate
  proof remains owner hardware evidence.
- Next highest-value task: finish BUILD-SIZE and release the lock; validate/commit
  Dynamo, render and independently judge the Galecrest pilot, validate the
  Swim-Stone late-join fix, then land ROAD-VISUAL's zero-sample four-biome pass and
  push one material CI wave.

## Checkpoint 3 — 2026-09-07 18:38 CDT

- Player-visible capability added since checkpoint 2: a 1.90–7.20 m creature ladder,
  vivid authored colourways for all 32 later-biome species, host-owned named
  Stormwood/Crown encounters, the Dynamo-to-Waterward ending, late-join Swim Stone
  entitlement, and persisted/replicated selection for all four trainer bodies are on
  the branch. Runtime acceptance remains listed below rather than inferred from code.
- Paths newly reachable: Stormwood's implemented route reaches the Waterward reveal
  and grants the Water key. A post-merge static audit corrected the prior handoff:
  there is still no production Water RealmGate or ordinary `enter_realm("water")`
  caller, so ordinary Stormwood-to-Water travel remains a P0 rather than being claimed
  reachable. Settings retains 58 debug destinations for testing but debug travel does
  not count toward the playable milestone.
- Systems newly working in evidence: the save rewrite and two-bed autosave soak pass;
  the map/minimap rollback passes repeated-open checks; all 36 statically sampled road
  routes report at least two forward creatures. The first 12-frame production road
  capture passed 9 and exposed three real footing/framing misses now under repair.
- Content added: 32 later-biome roster mappings; 69 creature presentations above the
  1.80 m trainer; deterministic ROAD pairs across all four biomes; Stormwood named,
  Crown, Dynamo, release, aftermath and Waterward content; Water late-join entitlement.
- Main merge: `296f7aa1d2ab48990ecdfb3ced7c2a69e4699545`, whose second parent is current fetched
  `origin/main` at `22fe512af9702009c2c4d77e7fb18e6dc8143fcc` (PRs #81–#83 included).
- Corrected scheduler: the Godot lock now covers import/re-import/export/render writes
  only. Unit tests, cache-reading probes and headless smokes may run beside a render;
  full-world Terrain3D smokes remain mutually serialized for RAM. Player-path work
  preempts build-size work.
- Deferred and recorded: BUILD-SIZE's Compatibility A/B, deep split-realm liveness,
  and the blocked two-peer Livewire smoke are in `docs/SECOND_PASS_BACKLOG.md` with
  existing evidence. Galecrest is not declared deferred or finished: round 1 was
  rejected and the owner amendment leaves up to two further mesh rounds.
- CI: run `34169556676` completed on the old batched head `13946f297`: 16 jobs passed,
  eight failed, shard 5 was cancelled at its 30-minute ceiling, and four downstream
  jobs were skipped. Every failure was read as a diagnostic, not as proof. The next
  push batches the three failures called out by the owner and the scale-regression
  cluster they exposed, then that full run will be allowed to finish.
- New focused evidence after merging main: four-biome Settings teleport coverage is
  green (3 tests / 394 assertions); save migration/corrupt-load/autosave/map-fog is
  green (70 / 398); Stronghold is green after growing the smaller machine and chamber
  around the enlarged bound Veridian (21.5 x 19.5 x 15.6m machine, 7.67m cage,
  7.08m creature, 0.59m internal headroom).
- Blockers: ROAD's real Windscar/Water captures; the three owner-named CI defects
  (direction-aware improved baseline, measured shard-5 split/orphan cleanup, and the
  real shard-7 failure); the missing ordinary Stormwood-to-Water gate; continuous solo
  Dynamo, Swim Stone and four-biome path proofs.
- Next highest-value task: fix those three CI defects without weakening tests, push
  once, read every completed job, then validate Dynamo, Swim Stone and ROAD in that
  player-path order.

## Checkpoint 4 — 2026-09-07 19:20 CDT

- Player-visible capability added since checkpoint 3: the ROAD runtime pass now
  shows at least two fully framed forward creatures at all 12 authored four-biome
  stands; enlarged creatures can stage at their full 7.60 m combat formation in the
  Warden Arena; large mounts use body-surface reach; throw assist no longer turns a
  clear 50-degree miss into a lock; and the Spark's 0.75 cooldown power is resolved
  from a host-validated relic identity rather than a client-supplied number.
- Three owner-named CI repairs are ready in one batch. ROAD's historical failure
  baseline is direction-aware (`<=`) while route/sample identity stays exact and a
  deliberately worse fixture still fails. Multiplayer shards now use measured-cost
  deterministic LPT packing, isolate split-realms, prove exact coverage, and kill
  each smoke's entire process group on every exit. Hosted Stormwood readiness now
  separates the real 12 m trainer challenge radius from 1.5 m actor replication.
- Focused combined proof is green: 153 tests, 12,001 assertions, 0 failures across
  ROAD/spawns/Cloudreach, scale-sensitive gameplay, Livewire, rideable/route boxes,
  Stormwood catalogue and ending, Water relic/map state, save/autosave/map fog, and
  all four Settings teleport destinations. The full-world Warden Arena smoke is
  green with 22 assertions at open and after 120 frames.
- ROAD production evidence is green at all 12 stands (minimum two forward and two
  framed creatures per stand). A code-blind judge recorded, but did not iterate,
  four visual rejections; the worst pileups/crops are listed in
  `docs/SECOND_PASS_BACKLOG.md` as required by playable-first.
- Hosted multiplayer boundary: the local two-peer Stormwood run is not claimed as a
  pass. It reached its own 300-second cold-world startup deadline before either
  runtime became ready, so the semantic checks did not execute. Both scripts pass
  static check-only, all child Godot processes exited, and the batched CI run owns
  the connected verdict.
- Main merge remains `296f7aa1d2ab48990ecdfb3ced7c2a69e4699545` with merged-main
  parent `22fe512af9702009c2c4d77e7fb18e6dc8143fcc`. No post-merge push has been made
  yet; the next action is a single coherent push and a complete job-by-job verdict.
- Still blocking the playable milestone after this CI batch: implement the missing
  ordinary Stormwood-to-Water gate and atomic Water entitlement transition, then
  execute the production realm-transition and continuous solo path smokes through
  the Water ending. Build-size A/B, visual polish, full density/performance, and
  multiplayer depth remain recorded second-pass work.

## Checkpoint 5 — 2026-09-07 20:35 CDT

- CI run `34175257602` completed on batched head `b7bd8c143`: 15 executable jobs
  passed, three failed, and three were skipped. The two explicitly known-red aggregate
  jobs were expected skips; the multiplayer matrix was skipped only because its
  discovery prerequisite failed. Every completed job was read before this repair
  batch.
- The old eight-failure cluster is closed: all four unit shards, owner regressions,
  regions, Gate A, Gate B core, gate evidence, harvest, scatter/terrain freshness,
  scatter rules, and the vegetation corridor passed. No unit, region, owner, bake,
  or gate-evidence job failed on this head.
- `discover-net-smokes` failed because new preloads pushed
  `smoke_net_shared_wild_fight.gd`'s `# peers: 2` marker from line 3 to line 6 while
  discovery intentionally scans only the first five lines. The marker is restored to
  line 3; local discovery finds 36 smokes, and the count floor/named registration now
  covers all 36 rather than the stale 29-file roster.
- `smoke_combat.gd` exposed a test self-conflict, not production healing: below 40%
  HP the smoke itself restored the ally to 100%, then sometimes won before another
  enemy hit and accused production of auto-healing. It now restores only to 70%.
  Focused runtime passed with 5 enemy hits, 6 ally hits, type-chart damage 112.2
  observed versus 114.5 predicted, and post-fight HP held at 55.9.
- `smoke_riding.gd` was born overlapping the workshop after Meadowhart's radius grew
  to 1.245 m. Its speed/jump fixture now uses the established open-meadow stand and
  proves grounded placement plus pre-input stability. Focused runtime passed at
  10.00 m/s mounted, 14.00 m/s sprinting, and 1.68 m jump rise; the production riding
  controller did not change.
- `smoke_catching.gd` had walked the trainer to 1.878 m from the enlarged Bramblebun,
  where the supposedly 50-degree-off reticle was honestly still inside its body. The
  fixture now walks away, proves at least 5 m target range and an outside-body live
  reticle, then keeps the same unlocked assertion. Focused runtime passed; production
  lock/trajectory behavior did not change.
- Next action: commit and push this one small repair batch, then allow the full CI
  rerun—including all seven measured multiplayer shards—to finish before any further
  push. The ordinary Stormwood-to-Water gate remains the next player-path code lane.

## Checkpoint 6 — 2026-09-07 22:20 CDT

- PR #80 run `34177060785` completed rather than being cancelled: 22 jobs passed,
  four multiplayer shards failed, and three downstream/known-red jobs were skipped.
  Shards 2 and 4 shared one hosted-trainer result-serialization defect; shard 5 had
  a stale pre-action health baseline plus a quick-cooldown timing race; shard 7 was
  the split-realm world-build failure. Ordinary unit, owner-regression, region,
  Gate A/B, evidence, harvest, scatter and discovery jobs were green.
- Shards 2/4 now transmit prepared actor/trainer/body positions under the control
  protocol's structured `data` field. Their focused contract remains exact: client
  within 12 m of trainer, host replica within 1.5 m of client, and host within 12 m
  of trainer. Shard 5 now captures the no-friendly-damage baseline immediately
  before that phase and uses a host-resolved 1.2-second charged cooldown so ordered
  action 9002 deterministically exercises refusal rather than wall-clock luck.
- Shard 7 is locally green end to end under its unchanged 15-second heartbeat and
  6,000 nominal-frame entry budget. Sliced multiplayer Cloudreach uses functional
  route/landmark placeholders while solo retains full presentation; realm shells
  now defer standing the just-vacated realm up until the host's destination scene
  reports ready. Run `net-local-transition-guard-2-1788837965` passed every check:
  first crossing 4,000 ms, Cloudreach shell ready in 3,629 ms, reverse host crossing
  17,423 ms without silence, and the expected final Meadows shell.
- The ordinary Stormwood→Water path is implemented: the Spark-gated Waterward view
  grants the key; a named physical gate 14 m farther on the same platform asks the
  host to atomically consume that key and create the reusable Water unlock; the next
  interaction routes to Water's authored First Shore anchor. Focused proof is 11
  tests / 70 assertions, zero failures. Independent review found no authority or
  atomic-save defect; the actual two-press world crossing remains to be smoked.
- Every Settings menu row is now pinned: all 58 destinations resolve their exact
  biome/entry anchor and each real Button callback forwards x/z/realm/entry then
  closes on success. Combined readiness/teleport proof is 8 tests / 929 assertions.
  The loading overlay now waits for destination readiness; an independent review
  found immediate scene-change failure and never-ready rollback still need a bounded
  abort before this batch is committed.
- Build-size is no longer an active defect. Current truth is 400 runtime 3D textures,
  all VRAM Compressed and fully generated, zero policy violations. The measured PCK
  fell 184,924,584 bytes (16.31%); remaining Lossless files are intentional UI,
  reference or duplicate generator inputs. Water's 12 vivid texture folders were
  separately found unreachable from namespaced runtime IDs; the static repair is
  10 tests / 512 assertions green and awaits production capture plus blind verdict.
- No push has been made since `15a09f0bf819a4554ad75074ba41d83ce8eec7e5`.
  Finish the bounded realm-entry rollback, render/judge the Water colourway repair,
  run the focused shard-5 connected smoke, then review and push this coherent batch
  once; allow the resulting CI run to complete before any later push.

## Checkpoint 7 — 2026-09-08 00:25 CDT

- Main integration remains verifiable at merge commit
  `296f7aa1d2ab48990ecdfb3ced7c2a69e4699545`, whose merged-main parent is
  `22fe512af9702009c2c4d77e7fb18e6dc8143fcc`. The branch head before this batch is
  still `15a09f0bf819a4554ad75074ba41d83ce8eec7e5`; no push has interrupted CI.
- The four PR #80 multiplayer failures are locally closed. Shards 2/4 carry their
  structured position payload under `data`; shard 5's unchanged connected smoke is
  green; and shard 7 now passes twice end to end. Its final runs are
  `net-local-split-integrated3-1788843045` and
  `net-local-split-confirm-1788843300`, both **ALL CHECKS PASSED** under the unchanged
  15-second heartbeat and literal 6,000-physics-frame transition cap.
- The shard-7 confirmation exposed and fixed ENet's 5-second reliable-ACK timeout,
  which was shorter than the simultaneous live/shell build. A cold Meadows return
  measured 65.026 and 69.491 seconds, proving the new candidate 60-second scene-ready
  cutoff was too short; readiness and rollback are now bounded at 120 seconds, and a
  rollback keeps its blocking overlay until the prior realm is itself ready.
- Cloudreach multiplayer retains the bounded visual path, but its placeholder
  collision no longer changes named chapter surfaces: settlement, observatory and
  both sloped Waterward crowns use the full build's exact footprints. Full live
  geological/dressing work remains recorded visual second-pass work after a measured
  >15-second heartbeat failure.
- The ordinary production Stormwood-to-Water smoke is green after the scatter
  fingerprint repair: reveal, first-press atomic key consumption/unlock, second-press
  travel, destination shell readiness and authored Water arrival all passed. It is
  now registered in `verify-regions-shard`. Stormwood's official scatter bake reports
  108 regions and 33,773 placements; only the source fingerprint changed.
- A parallel fresh-save route audit found a real solo dead edge: crown-grade
  stormglass had authored sites but no `harvest:crown_grade` production emitter.
  The existing host-authoritative harvest/chapter seam now emits it from durable
  authored crown claims after the arch recipe is known. Focused regression: 2 tests,
  4 assertions, zero failures. The same audit found Water's unmounted ordinary return
  to Stormwood; it is non-forward-path work and is explicitly recorded in
  `docs/SECOND_PASS_BACKLOG.md`.
- Fast integrated evidence: production script check is green; realm readiness,
  rollback, exact teleport rows, Stormwood gate/scatter/progression, Water colourways
  and creature scale are green at 40 tests / 1,637 assertions; the follow-up
  readiness/collision/crown-harvest set is green at 12 tests / 55 assertions.
- Next: run the final consolidated fast suite and diff review, create reviewable local
  commits, push once, then read every CI job before any further branch update.

## Checkpoint 8 — 2026-09-08 00:15 CDT

- Main was fetched and merged again before continuing. The verifiable merge commit is
  `01f85b2b356de72689eb90e42242e42ae64d5dfb`; its merged-main parent is
  `f6b79a6b3` (PR #84, D100: the fourth realm's player-facing name is Tidewake).
- The prior coherent gameplay batch is present on PR #80 at `085d49a57`: its first
  new CI run (`34189428258`) dispatched every ordinary job and all seven multiplayer
  shards. That run predates the mandatory D100 merge, so it is useful intermediate
  evidence but will not be treated as the final branch verdict.
- D100 is integrated at the player seams the owner decision names: the Waterward
  reveal introduces Tidewake, the physical realm gate and authority refusals use
  Tidewake, the map header derives the display name from `realm_hearts.json`, and the
  Settings teleport catalogue labels the fourth realm Tidewake while preserving the
  internal `water` id and authored arrival key.
- A parallel naming audit found the reveal omission; the production
  Stormwood-to-Water smoke now pins the presence of `Tidewake` in that conversation.
  Final post-merge validation passed at 20 tests / 1,023 assertions, zero failures;
  the complete production Stormwood-to-Tidewake smoke also passed in 28.2 seconds,
  and production script check plus `git diff --check` are clean.

## Checkpoint 9 — 2026-09-08 00:36 CDT

- Exact-head PR #80 CI run `34190049594` on `7f28b5ed23a98432badb92e1dbc6e1b341247ab2`
  completed: 22 jobs succeeded, three failed, and four were skipped. The two expected
  known-red jobs were skipped; `export` and `verify-solo-regression` skipped only
  because required jobs failed upstream. Every job conclusion was read individually.
- The split-realm repair is now confirmed in CI: multiplayer shard 7 passed. Shards
  1, 3, 5 and 6 also passed. Shard 4's hosted-Tamsin smoke starts the authoritative
  fight but the client never binds its hosted trainer; shard 2's Livewire smoke reaches
  the same binding failure and then cannot prove three strike/deadline assertions.
  These are content failures, not timeouts. A focused CI repair lane owns them.
- `verify-gate-b-core` failed both CI attempts at Bram dialogue cycle 3. A same-head
  local production run then completed Bram cycles 1/2/3 and the whole Gate-B core in
  156.25 seconds. This matches the previously recorded nondeterministic village-tools
  leg, but it is not being waived: a diagnosis lane is looking for the arbitration
  mechanism rather than increasing retries or weakening the assertion.
- Work continued beside CI. A production Alpha-to-saddle smoke found Aquaryn refusing
  every ordinary strike as `malformed` because its special transport bypassed the
  shared action-ID stamping seam. The Water-only parity repair is green at 9 tests /
  84 assertions and 33 production checks through defeat, Swim Stone, recipe, craft and
  mount; independent review found no P0/P1 issue. A second lane wired all five authored
  Water named encounters into production and passed 21 tests / 2,233 assertions.

## Checkpoint 10 — 2026-09-08 01:06 CDT

- The Gate-B cycle-3 failure was a harness arbitration race, not a missing retry. The
  helper now observes the activation arbiter's real post-input winner: the requested
  provider succeeds, no winner stays inside the existing bounded approach, and a
  competing provider fails with its exact identity. The focused contract is green at
  4 tests / 14 assertions; the production Gate-B core was already green through all
  three Bram cycles and tournament readiness in 156.25 seconds.
- The two Stormwood CI failures shared one product race. An aggressive local wild could
  engage during the hosted-trainer round trip, leaving a valid authoritative trainer
  record pending forever. Host admission now yields only a fleeable wild through normal
  combat cleanup; trainer fights remain protected. The full two-peer Tamsin smoke is
  green through both rounds, hostile-input rejection, rewards, retry refusal and final
  state hash. Its focused regression is green at 5 tests / 14 assertions, and an
  independent code review found no P0/P1 issue.
- Livewire then passed trainer binding and every host deadline/cooldown assertion except
  one expected hit whose opponent had moved while the smoke waited on deadlines. The
  smoke now refreshes the existing real client/host strike geometry immediately before
  expected hits without changing action ids, deadlines, HP or acceptance assertions.
  The follow-up local run lost its host heartbeat during Stormwood entry before reaching
  any Livewire assertion; neither peer exited or crashed. CI is the next meaningful
  connected verdict rather than weakening the smoke around local full-world startup.
- ROAD-VISUAL-CREATURES is closed for the playable contract: 36 critical routes and
  4,253 ten-metre samples have at least two creature bodies in the forward 180 degrees,
  12 representative production frames each contain at least two forward/framed bodies,
  and fitted creature heights span 1.90-7.20 m against the 1.80 m trainer. The blind
  visual judge still rejects pileups, crops and palette/silhouette clarity; that cosmetic
  work remains explicitly deferred in `docs/SECOND_PASS_BACKLOG.md`.
- Reviewable local commits since the last push are `046beff74` (Aquaryn and named
  Tidewake encounters), `531647a9e` (Gate-B prompt arbitration), and `9a6ff4e5e`
  (hosted Stormwood trainer admission). The next action is one batched push, then a
  job-by-job exact-head CI read before another branch update.

## Checkpoint 11 — 2026-09-08 01:18 CDT

- The previous turn made concrete progress: four reviewed commits were pushed as
  `968ae810780ad9fd8189adc38ba5523c4a668f16`. CI run `34193395389` is live and
  an independent lane is reading its jobs. No follow-up push has interrupted it.
- The combined local repair contracts pass on this tree: 27 tests / 2,309
  assertions, zero failures (Aquaryn, named Water spawns, hosted Stormwood and
  Gate-B arbitration). The named-spawn negative fixture emits its expected warning.
- The production four-realm teleport smoke was rerun after the realm-loading rewrite
  and Tidewake naming merge. It exits 0, reports Meadows -> Cloudreach -> Stormwood ->
  Water -> Meadows, checks grounded arrivals and loading-overlay lifetime, and emits
  no `ERROR:` or `SCRIPT ERROR` lines. Log: `.artifacts/realm-teleport-current.log`.
  This samples one crossing destination per realm. All 58 Settings callbacks have
  unit and physical focus coverage; exhaustive physical landing at all 58 spots is
  still a narrower outstanding navigation check.
- A read-only late-Tidewake audit found no second static flag dead-end, but exposed
  missing continuous evidence for the three long mounted crossings and Salt Crown /
  Sluice control chain. The new traversal diagnostic is being implemented and run by
  a separate lane. Its synthetic starting creature and prerequisite fixtures must not
  be represented as the earned state from the Alpha-to-Mosshell smoke; ordinary
  earned-state composition remains required before milestone acceptance.
- `docs/CURRENT_STATE.md` now distinguishes PR #80 branch repairs from the historical
  PR #79 baseline. Reconciliation commit `ffbbaf375` is local until CI finishes.

## Checkpoint 12 — 2026-09-08 01:36 CDT

- CI run `34193395389` completed with 25 passing jobs, one failure and three
  skips. All seven multiplayer job conclusions were read: only shard 2 failed.
  Gate-B core passed first attempt, all unit shards and solo regression passed;
  export and the two known-red optional jobs were skipped.
- The remaining Livewire failure is an accepted miss, not a cooldown refusal:
  action 805 advanced the host's accepted-action ID without reducing HP. Its
  staging helper had waited 60 physics frames and only checked the follower
  against the old target position. The timing-only health fixture now opts into
  a stationary host target. Production hit, damage, action-ID and deadline checks
  remain unchanged; the ordinary hosted-trainer smoke retains moving enemy AI.
  Independent review found no P0/P1 issue. Both changed scripts parse, and focused
  Livewire/hosted tests pass 8 tests / 34 assertions. CI owns the next two-peer
  runtime verdict while the local full-world slot serves Tidewake progression.
- The late-Tidewake synthetic-start diagnostic completed both first crossings,
  grounded landings and the actual Salt Crown chart interaction. It failed on
  the Bex approach. A follow-up is testing the omitted Twin Pumps route waypoint
  before changing production placement; no claim of impassable terrain is made.
- A production footing probe measured the Salt Crown ROAD failure: sites 01/02/03/05
  are 5.44-5.465 m from the route centre, outside the graded three-metre half-width,
  with steep footprint height changes and normals below the support threshold.
  The initial 57-74 m report used a faulty nearest-vertex calculation and was
  corrected during integration review. A coordinate-only repair is underway.
  No footprint, slope, ray or creature-size contract is weakened.
- The teleport smoke now covers all 58 curated destinations in its working-tree
  extension. It passes parser checks but awaits its full-world runtime slot; the
  previously recorded four-realm crossing run remains the last completed proof.

## Checkpoint 13 — 2026-09-08, parallel playable-path validation

- Main remains integrated through merge `01f85b2b356de72689eb90e42242e42ae64d5dfb`
  (main `f6b79a6b32983d3b60f7333d8b44706736701474`). No push interrupts the
  current CI run `34195296547` on `7415602f5`; its terminal verdict is pending.
- Salt Crown coordinate-only footing repair committed locally as `4e459e604`.
  All seven ROAD sites admit 2/2 production creatures; four repaired populated
  segments pass 24 m real-stick walks. Ordinary Salt wild sites 011/012/013 remain
  open. Details: `road-visual-creatures/SALT-FOOTING-REPAIR.md`.
- Expanded `smoke_realm_teleport.gd` exits 0: all 58 curated Settings destinations
  land through production teleport, all four realm crossings complete with overlay
  checks, and one second of resumed physics leaves the player above terrain.
  Log `.artifacts/realm-teleport-all58.log` has no ERROR or SCRIPT ERROR lines.
  It does log three severed-spoke recoveries near South Bridge (0,1330) and Old
  Mill Crossing (-152,4203). Those landings need further inspection: a recovery
  can satisfy the final height assertion without remaining at the requested spot.
- Teleport traversal additionally exposes ROAD footing warnings at Tidal Cradle
  02/03, Sluice 02/03/05 and Veilfall 03. Functional coverage is not deferred or
  claimed closed. The backlog wording now distinguishes the 12 representative
  frames from this broader open coverage requirement.
- Bex's arrival-spine placement repair awaits actual fight/control validation;
  Sluice's short production footing probe runs first. CI monitoring, Bex analysis,
  ROAD analysis and root integration run in parallel; full-world smokes serialize
  for RAM only. No continuous fresh-save completion is claimed.

### Follow-up — teleport recovery and current CI failures

- The two Meadows menu coordinates were bridge/channel landmark centres; the
  terrain-height teleport seam therefore places the player below the elevated
  deck. The working repair uses existing near-side approach road vertices:
  South Bridge (9,1300), Old Mill (-152,4170). The smoke now also requires no-input
  horizontal displacement to remain within 3 m after its physics settle, so
  road recovery cannot silently pass the final height check. Focused menu tests
  pass 5 tests / 921 assertions and the smoke parses; the strengthened runtime
  verdict is pending behind Bex's full-world run.
- Run `34195296547` is still active but has two confirmed failures, not timeouts:
  multiplayer shard 2 Livewire accepted-without-damage again, and shard 5 shared
  wild friendly-fire proof read `replayed_action` instead of `friendly_target`.
  Root independently read all 27 currently visible job states: five other
  multiplayer shards, Gate-B and all four unit shards have passed; gate-evidence
  remains active and two optional jobs are skipped.
- Livewire's stationary-opponent fixture did not eliminate the miss. Its lane
  is inspecting host-facing/hit geometry before another repair. Shared wild's
  friendly-refusal poll exits on any nonempty snapshot, although the immediately
  preceding replay proof intentionally leaves `replayed_action` there and a
  submitted client request does not clear it. A bounded expected-code poll
  repair parses; peer-log confirmation and connected validation remain pending.

## Checkpoint 14 — 2026-09-08, Bex and Sluice integrated

- `42f0b6558` commits Bex's arrival-spine placement with actual two-opponent
  defeat and west-control activation evidence. The same synthetic-start run
  subsequently failed Calder's crown approach, not the repaired Bex path.
  Calder's data repair is still uncommitted and awaiting runtime validation.
- `786cd913b` commits the four Sluice ROAD coordinate repairs. The strict
  production probe admits 2/2 at all six sites and passes all four populated
  24 m walks, exit 0. No size/count/species/tolerance relaxation was made.
- `68688d174` moves the two bridge debug destinations onto authored approach
  roads and adds a no-input displacement assertion. Its all-58 runtime rerun
  is active; the older exit-0 run did not detect bridge-channel recovery.
- CI `34195296547` finished 24 pass / 2 fail / 3 skip, with every job conclusion
  read and no hidden multiplayer retries. New Livewire diagnostics read the
  host's exact charged-move profile/centres/facing and wait for its actual hit
  predicate before submitting. The prior stationary fixture was effectively
  redundant: hosted opponents already disable physics when invisible.
- Shared-wild polling now waits for this phase's expected friendly refusal
  rather than the previous replay response; a new submitted-action diagnostic
  asserts the automatically allocated id is 9003. The failed CI peer logs never
  recorded a later friendly response before shutdown, so this remains a repair
  hypothesis needing connected validation, not a claimed fix.
- Local host-friendly tests pass 18/62 and Livewire/hosted tests pass 8/34.
  Both changed diagnostic scripts parse. Production combat code and authority
  checks remain unchanged. Independent review precedes the next single CI batch.

## Checkpoint 15 — 2026-09-08, post-push teleport recovery diagnosis

- Reviewed batch `de4fc499fb0aa441561351169dd5cd895ab069b3` was pushed once,
  after the preceding CI was terminal. New CI `34197701347` is active. No
  unvalidated Calder placement was included in that batch.
- The strengthened all-58 teleport smoke completed with exactly one failure:
  Cliffhold (-340,3970) relocated to the previous High Perches (900,2700).
  Both Meadows bridge approach fixes passed without their old recovery messages.
  Log `.artifacts/realm-teleport-safe58.log`, exit 1.
- Source diagnosis: `cloudreach_physical_runtime.gd` returns an unflying player
  to the last Fly landing whenever its height is over 100 m above the player's
  current height. The 1020 m High Perches anchor survived a deliberate teleport
  to approximately 830 m Cliffhold, so this ordinary walking-fall safeguard
  interpreted the menu action as a fall. No terrain/landing coordinate repair
  is warranted for Cliffhold from this evidence.
- Working fix clears the previous recovery anchor after a successful debug
  relocation, without granting a new anchor or changing ordinary fall rules.
  Independent review caught pending network replies restoring that old anchor;
  opaque monotonic request IDs now cross the existing host request/verdict path,
  and stale replies are ignored. IDs are allocated across controller instances
  to prevent old-scene replies matching a new controller's first request.
- Focused Fly/menu regression tests pass 15 tests / 996 assertions, including
  stale accepted/refused replies, current replies, and replacement controllers.
  Initial new test-fixture API/setup errors were corrected; only the clean
  final run is counted. Runtime and connected Fly validation remain pending.
- Calder's synthetic-start route run is still active; it has repeated Bex and
  west-control success and reached the departure road. It has not yet established
  a Calder/east-control or finale verdict.

### Runtime follow-up

- Anchor-reset all-58 teleport run completed exit 0 on `894a48f21`.
  `.artifacts/realm-teleport-anchor-reset58.log` reports all 58 destinations,
  retains exact immediate grounding and <=3 m no-input displacement checks,
  and contains no ERROR/SCRIPT ERROR or recovery messages. This proves the
  two bridge approaches and Cliffhold repair through actual production scenes.
- CI `34197701347` has passed both formerly failing smokes on attempt 1/1.
  Livewire action 805's host geometry was 1.250 m / 7.500 m range and
  16.89 degrees / 20-degree half-cone before sending; the accepted attack
  reduced HP. Shared-wild's automatic friendly action was 9003, returned
  `friendly_target`, and damaged neither creature. Remaining CI jobs were
  still active when this evidence was recorded; no full-run green is claimed.
- Calder's route test reached and entered his three-opponent fight but did
  not obtain the victory flag. The next diagnostic uses the authored creature
  bed and overnight rest between Bex and Calder, with health/outcome telemetry,
  rather than injecting healing or reducing the trainer's difficulty.

### Completed CI verdict — 2026-09-08 07:32 UTC

- Root verified the run and every job through GitHub REST: run `34197701347`
  on `de4fc499fb0aa441561351169dd5cd895ab069b3` is terminal success, with
  26 passing jobs and three intentional skips (export and two known-red optional
  jobs). All seven multiplayer shards, Gate-B, unit shards and solo regression pass.
- This does not verify local `894a48f21` Fly-anchor protocol changes, the pending
  Calder placement, or Tidal Cradle ROAD repairs. They require the next batch.
- Parallel lanes remain distinct: real-input camp/Calder path, measured Tidal
  footing repair (including newly reproduced ROAD08), and fresh-save composition
  audit. Only full-world runs serialize for RAM. The camp diagnostic's first bed
  attempt changed polled Input state without dispatching a GUI event; the harness
  now sends parsed action events and checks actual panel focus before pressing.
  Its rerun is live; no camp/Calder success is claimed yet.

### Next batch validation — 2026-09-08

- Tidal Cradle repair `09cd1c66c` passes strict production admission at all nine
  ROAD sites (2/2 each) and three populated 24 m controller walks. Root read the
  actual repaired log and reviewed the coordinate-only changes. Main remains
  `f6b79a6b32983d3b60f7333d8b44706736701474` by remote ref check.
- Named pre-push `smoke_playground.gd` exited 1: gather impact was observed at
  0.82 of the 0.625-second swing, versus the expected 0.60 (upper bound 0.80).
  The only native error was the documented dummy-renderer null-material error.
  Log: `C:/Users/mattj/AppData/Local/Temp/four-biome-next-batch-playground.log`.
  This is not counted as a pass or assumed to be harmless timing noise.
- Added synchronous production `swing_connected` diagnostics (wall time, swing
  elapsed time and animation position) beside the existing durability poll.
  Assertions and tolerances are unchanged; parser check passes. The next run
  must distinguish late gameplay resolution from late observation before a fix.
- The camp/Calder diagnostic ended earlier on a Salt Crown waypoint, 2.1 m from
  its target with the unchanged 1.3 m tolerance. A new run records collision,
  input-owner and navigator state on failure; no Calder success is claimed.

### Checkpoint — 2026-09-08 08:20 UTC

- Branch still contains main `f6b79a6b32983d3b60f7333d8b44706736701474`
  through merge `01f85b2b356de72689eb90e42242e42ae64d5dfb`. No further push
  since c5012fff0; CI 34201147829 is terminal, 25 pass / three skip / one fail.
  Root retrieved failed MP4 job 101981005779 and its artifact: hosted Tamsin
  round 0 fails to advance, followed by a secondary smoke watchdog. This is
  not a shard timeout. Diagnostic strengthening is local, not a claimed fix;
  see `TAMSIN-CI-34201147829.md`.
- Local Calder repair ffb7916db is backed by the synthetic-start late-water
  run: ordinary camp/rest, three Calder opponents, east control and combined
  sluice barrier flag pass. Departure mount fails; no finale closure claimed.
  A copied pre-Calder save diagnostic is next to measure every mount predicate,
  explicitly not a fresh-save or uninterrupted chapter proof.
- Local lightning fix 112220071 removes a freed warning-ring lambda capture.
  Minimal real receiver regression reproduces baseline error and passes repaired;
  Stormwood continuous rerun reaches Break, six glass and arch pair A without
  that error. Maren activation remains a harness evidence gap: prompt focus
  alone did not prove an interaction. Agent now observes arbiter activation.
- Veilfall strict candidate exits 1: 23/24 ROAD sites admit 2/2; site20 admits
  only 1/2. Twelve of 15 populated walks pass; walks19/20/22 fail. Root read
  the actual terminal summary. Repair is uncommitted and not declared complete.
- All three agents are active with independent file ownership. Veil released
  its completed full-world run to Water saved-suffix; Stormwood and root's
  instrumented hosted Tamsin run follow. Unit/source work continues beside
  full-world runs; each Godot invocation uses its own log file.
- Harvest broad-phase optimization 767d3350a has bounded cost/selection tests,
  not full-world proof yet. c501's core CI smoke passes its unchanged chop
  assertion on attempt1; timing telemetry alone does not prove the optimization.
  Fresh-save opening-to-ending composition and full forward-view coverage
  remain open. The playable-first target and backlog are unchanged.

## 2026-09-08 11:25 UTC — owner-requested session wrap

- Handoff: `docs/HANDOFF_FOUR_BIOME_2026-09-08_SESSION_WRAP.md`.
- Main included through merge `01f85b2b356de72689eb90e42242e42ae64d5dfb`
  (main `f6b79a6b32983d3b60f7333d8b44706736701474`). Last remote push remains
  `c3cd1ac827655c765dd66f0a0d811b861d51f63a`; CI34218809408 terminal26success/
  3skip, all successful logs reviewed, all smoke first attempts pass. No wrap push.
- Water opening→Tovin exit0 proves ordinary lesson, harvest/payment, travel,
  two opponents and durable flags. Varga overlap repaired locally but runtime
  pending. Full-world map menu cycle exits0 with three frames and no native
  errors; visual verdict remains pending and root did not judge frames.
- Brine candidates pass all-species support and road walks; two admission probes
  remain red from original site's sticky failure before candidate installation.
  Next session must wait for actual population_ready, not repeat a guessed wait.
- All three agents stopped; no local Godot process. Preserve the two dirty Water
  composition files and untracked candidate smoke listed in handoff. No new run,
  fresh task, automation, milestone pass or goal-blocked claim was made.

## 2026-09-08 11:00 UTC — CI green, continuous paths still open

- Previous turn was progress: terminal CI evidence recorded and Dace interaction
  repair committed locally. Main remains `f6b79a6b32983d3b60f7333d8b44706736701474`,
  included through merge `01f85b2b356de72689eb90e42242e42ae64d5dfb`; root fetched
  and verified this ancestry this checkpoint interval.
- Submitted head `5fc68033750f2cf5e2c0eed391561fb306ccbf82`, CI `34216463559`:
  terminal 26 successes / three skips. All successful job logs reviewed, all
  smoke first attempts pass. Livewire samples 296/186 ms within unchanged bounds;
  released-window maximum sampling gap379 ms means timing sensitivity is not
  eliminated. Native fixture/teardown errors remain documented, not hidden.
- Meadows player build hold passes local fresh/repeated boot and ordinary return
  with grounded movement and no runaway warning. Map's actual drawing contract
  and fail-closed tests are repaired; isolated two-open captures exist, but full
  world second-open proof and fresh blind verdict remain pending. Agent-tree cap
  prevents a new zero-context critic; cosmetic deferral is explicit in backlog.
- Local detached dialogue camera guard removes reproducible script errors:
  unchanged portrait 13/2697 and camera 24/104 tests pass with clean native logs.
  It and later changes are outside this CI head. No subsequent push yet.
- Stormwood continuous last run stopped at a real wild winning Dace's button
  edge. Repair `e78a76080` resolves only that exact live fight then reapproaches;
  it never counts the wild as trainer activation. Focused8/89 pass, runtime
  continuation pending. Obsolete initial test processes32352/20512 were verified
  and terminated; malformed test base had aborted the runner before quit.
- Water opening/Reedhaven/107m Brine crossing pass, but Tovin's old summit
  approach is blocked. Baseline ordinary p3/p4/p5 approach established a usable
  neighborhood. Small NPC-placement repair is now in runtime probe, confirmed
  live21232/13456 with unique `water-tovin-approach-final.log`; no victory claimed.
- Third agent independently measured Brine010/011 physical-footprint rejection;
  current production normalizes JSON Y, so stale raw Y is NOT the live mechanism.
  All-species common-coordinate candidates are next, no production spawn edit yet.
- Full-world runs alone serialize for RAM; lightweight work continues in all
  three lanes. Next: Tovin decisive proof, Stormwood continuation, Brine candidate
  admission/clearance, then Water opening-to-Tovin replay and Shellwatch. Crown,
  Tidewake finale and opening-to-ending fresh-save composition remain unproved.

## 2026-09-08 09:08 UTC — coherent repair batch submitted

- Previous turn classified progress: Venn's real traversal/offer proof completed
  and its repair was committed. Root then independently passed the real-body
  detached-opponent cleanup regression and added native-error-scanning CI coverage.
- Main remains `f6b79a6b32983d3b60f7333d8b44706736701474`, included through merge
  `01f85b2b356de72689eb90e42242e42ae64d5dfb`; remote checked before pushing.
- Run `34205399274` is terminal: 25 passing jobs, three skips, only MP2 failing.
  Its Livewire observation window failed while hit/refusal/action checks passed.
  Host-local window sampling repair `12c7d76e0` passes a Windows two-peer run
  at unchanged 180–350 ms bounds (316 and 331 ms). New CI remains necessary.
  MP4 Tamsin passes first attempt and exposes position-only versus actual-cone gap.
- Pushed once: `23b7d4acd935b508d53769a71e434857de1de41c`; remote SHA verified.
  CI `34208280455` is queued. No new push until its terminal verdict.
  Batch includes solo Stormwood reward authority, focused cleanup regressions,
  Livewire measurement, Venn placement and continuous-route diagnostics.
- Venn probe exits 0: 349.49 m ordinary movement, zero resets, actionable
  Challenge Officer Venn at 2.021 m. Not victory or fresh-save proof.
- Water continuous session `15526` / live Godot PID `32548` owns the full-world
  slot. It reached Salt Crown; ordinary wild sites 011/012/013 are rejected.
  A separate agent investigates those data/footing failures without a world run.
- Stormwood agent's Dace continuation is queued behind Water, with the named
  playground regression first. Its teardown repair passed root's unique-log
  smoke with no errors. All agents have independent ownership; lightweight work
  continues alongside the world run. No cache writer is monopolizing the queue.
- Fresh-save opening-to-ending composition, Dace onward and Tidewake finale
  remain unproved. No milestone or deferred visual/performance closure claimed.

## 2026-09-08 13:51 UTC — main repaired and verified; Wave 1 begins

- Owner's main-green-first interruption is complete. PR #80 exact head
  `9cbec44fbbcf644bc2019cea8cab6c32aab32fd5` passed CI `34229513422`,
  attempt 1, 26 success / three existing conditional skips at 13:21:22 UTC.
  Squash landing is `75aaccca0210a9bc1ac0f16bac687d8557f0aacf`.
- Main's OWN push CI `34231941105` finished at 13:50:58 UTC, attempt 1:
  27 success / two existing conditional skips. All seven multiplayer shards,
  all four unit shards (2921 tests / 486218 assertions), all runtime shards,
  Windows export and exported-runtime terrain verification pass. Every job and
  step/log evidence was reviewed. Local raw ledgers: `.artifacts/ci-34229513422/`
  and `.artifacts/ci-34231941105/`. No rerun or cancellation was requested.
- Main shard 7's original unidentified failure was hosted Tamsin completion,
  separate from shard 3's stale 4 m shared-wild diagnostic. The preserved WIP
  also exposed Varga clearance and asynchronous catch observation failures;
  follow-up CI exposed contradictory Varga expectations and torn shared-boss
  HP/counter sampling. Fixes preserve production dimensions and exact criteria.
  Detail, negative controls and logs: `MAIN-GREEN-20260908.md` beside this file.
- Local repaired first runs: catch47 checks, Tamsin59, shared boss85, all zero
  failures. Focused boss snapshot3/9, Varga5/517, catch18/58 and Tamsin7/22 pass.
  Independent astra reviews found no actionable findings. Existing native-error
  caveats and the two local Gate F full-checkout failures remain explicit;
  neither a clean local full suite nor a campaign milestone is claimed.
- Fetched main contains the required session handoff and has the same tree as
  the verified PR head. New `codex/four-biome-wave1` branches from main. No
  Wave 1 code ran before main's complete post-merge verdict.
- Player-visible delta: accumulated Wave 0 work is now on verified main;
  runtime-backed CI repairs make hosted combat completion and shared combat
  refusal checks reliable under scaled fixtures. No new continuous campaign
  reach is credited this checkpoint. Stormwood Varga/Ondra/Crown and Tidewake
  Shellwatch/ending remain open; actual fresh opening-to-ending composition is
  the deliverable, and synthetic chapter fixtures cannot substitute.
- Next lanes: Stormwood continuation owns the first full-world RAM slot;
  Tidewake reviews/tests its Shellwatch composition in parallel; independent
  astra audit identifies reusable earned-state opening/Cloudreach seams. Root
  owns end-to-end composition and integration. No cosmetic backlog is reopened.

## 2026-09-08 15:51 UTC — checkpoint recorded 15:56; first zero merged delta

- Main remains `75aaccca0210a9bc1ac0f16bac687d8557f0aacf`, own push CI
  `34231941105` green. No Wave 1 runtime change has merged since 13:51.
  This is the first consecutive checkpoint with zero credited merged delta;
  the late record does not extend the cadence. Next checkpoint: 17:51 UTC.
- Draft PR #85 head `0a91f9b39aa552e554b849b4eb57d8011e2c7589` finished
  CI `34245691443` at 15:52:33 UTC, attempt 1: 25 success, one failure,
  three existing conditional skips. Every job/step and log evidence reviewed.
  All four unit shards passed: 2977 tests / 486656 assertions. All seven
  multiplayer Run net smokes steps passed. MP4 failed artifact finalization
  after uploading 9381576 bytes: non-retryable intermediary HTTP 403.
  This remains a red run, not merge verification; no rerun requested.
  Logs: `.artifacts/ci-34245691443/`; review `wave1-ci-0a91-1554.txt`.
  Existing cleanup/material/cache messages and deliberate peer-death negative
  control remain disclosed. Previous head 8cd81b422e466a3918f471344750ee7edd15e883
  passed complete run 34242634338, 2963 tests / 486540 assertions.
- Actual fresh-save run `four_biome_fresh_29284_1784` passed the changed physical
  key/gate navigation at 111.73 seconds, earned five creatures and one real
  training victory. It failed at 293.92 seconds on a 3600-frame wild approach:
  player (-37.72714, 2.680571, 4.499945), Mudsnout (-54.17064, 5.498205,
  23.00343), remaining distance 24.914 m, Terrain colliders, no input owner.
  Exit 1; owner fingerprints unchanged; no ERROR/SCRIPT ERROR lines.
  Logs: `.artifacts/wave1-fresh-key-nav-camp{,-engine}.log` and matching
  owner-before/after.json. No camp completion or full team training claimed.
  Two failed team approaches trigger bounded geometry/source diagnosis,
  not another blind prefix or an expanded frame allowance.
- Stormwood again earned Ondra's recipe but exact Alpha Engage did not enter
  combat. A small actual arbiter/director/manager probe reproduces refusal for
  a resting ally and success for a healthy ally. The campaign fixture does not
  set resting: that control is NOT the campaign diagnosis. Added activation
  telemetry passes focused 6 tests / 74 assertions. Next is a focused scene
  diagnostic, not a third full-prefix replay. See STORMWOOD-WAVE1-20260908.md.
- Tidewake's previous path proved paid Shellwatch rest/redeployment but stopped
  on the Solm approach. Production-height sampling found the direct line exceeds
  the player's 45-degree limit; a physical detour has a measured 39.85-degree
  maximum and focused 8 tests / 58 assertions. Changed full-world continuation
  now owns RAM, session 92218, `.artifacts/wave1-water-solm-detour` logs/profile.
- Prepared Warrens, camp/rest/tournament/bridge and later chapter helpers remain
  unproved as a continuous fresh path. Opening-to-Tidewake ending and full forward
  coverage are still open. No new deferrals or milestone closure credited.

## 2026-09-08 17:51 UTC — merged runtime delta; zero-delta streak reset

- Credited merged runtime progress since15:51: PR #85 landed as
  `bc26b21eec2b96a8fbd8295732007aa67f92198a`; its own push CI `34252353122`
  passed attempt1,27 jobs/2 existing conditional skips,2980 unit tests/486685
  assertions, all7 multiplayer shards and actual Windows exported-runtime check.
  The village-boundary route then supported genuine fresh acquisition of five
  creatures and ten ordinary training wins to level5+. Production Fenn/Ondra
  access repairs also have chapter-runtime evidence. This is a material merged
  delta; the previous single zero checkpoint does not become a second zero.
- PR #86 exact head `a62c81ae562714a59eb62ebcb2117e2649fa7e76` passed
  CI `34256323372` at17:37:05, attempt1,26 jobs/3 expected skips. Units3013
  tests/486957 assertions; all explicit unit/dedicated summaries3092/3843401,
  zero failures. All7 multiplayer shards and all new native region checks pass.
  Every job/step/log reviewed; original negative controls, renderer cleanup and
  Water transition diagnostics are disclosed, not rerun away. Evidence:
  `.artifacts/wave2-pr86-ci-34256323372-{01..06,FINAL,alljobs-final}.txt` and
  `.artifacts/ci-34256323372/`. Main squash `b3458eb1d0f54ceb2554a97e9b0fe0b2f88f5bfb`
  has the identical tree and bc26 ancestry. Its OWN push CI `34258802654` is
  pending, last snapshot still checking out; no new main-green claim.
- Landed Relay ramp/deck orientation repair has actual Player traversal proof.
  Prepared earned Relay/Hall/Warden/Rift/Cloudreach/Stormward/Crown/Rootgate
  composition is source-checked, not a completed fresh route. The separately
  isolated Water chapter earned Shellwatch completion and Aquaryn/Swim Stone,
  then hit its unchanged20-minute watchdog approaching Iona; recipe unproved.
- Latest completed genuine fresh run `four_biome_fresh_35532_2265` ended at
  316.881s: real opening/key/village, five earned creatures, three training wins,
  then party-cycle selection failed. Owner fingerprints match; no engine/script
  errors. `.artifacts/wave2-fresh-clear-throw-campaign{,-engine}.log`. Native
  diagnosis reproduced missed/doubled synthetic cycle taps; changed physical
  process-frame input passes16 assertions, existing team tests11/85. New fresh
  session46271 is running with that changed driver, unique
  `.artifacts/wave3-fresh-cycle-campaign*` profile/logs/source hashes. No camp
  or material selector runtime completion is claimed.
- Unmerged Wave3 production repairs: physical throw preview/HUD obstruction
  (native24 assertions; existing10 tests/32 assertions), reachable Iona footing
  (actual Player/NPC/prompt on shipped height patch), and Stormheart approach lip
  (actual Player reaches core2826/6000 frames, grounded, zero unsticks). Original
  failed probes and fixture errors are retained in their reports. New earned
  Dynamo/Marrow/Waterward helpers remain runtime-unproved; focused checks5/49,
  5/36 and6/45 respectively. These unmerged results receive no checkpoint credit.
- Deferred ~23km Meadows acknowledgement backtracking and stale Kell aftermath
  text were recorded in SECOND_PASS_BACKLOG with source evidence. Full uninterrupted
  opening-to-Tidewake ending and forward-view coverage remain open. Next priority:
  complete main's own CI review, then the actual fresh camp/training path and its
  observed blockers. Next checkpoint19:51 UTC.

## 2026-09-08 19:51 UTC — merged gameplay repairs; first-camp content prepared

- Material merged delta since17:51: PR87 landed as
  `043cd1061ba8e1423d1681c7479d9ad36f6d4317`; exact PR head
  `6c0f0e78046fbd15c3e1fe46de06fa154981be66` passed CI34262351185.
  Main's OWN push CI34264602920 passed attempt1 at19:10:32:27 successful
  jobs/two existing manual-only skips,3037 unit tests/487178 assertions,
  all seven multiplayer shards, Windows PE export and actual Linux exported
  runtime terrain/ground validation. All jobs, steps, attempts and logs were
  reviewed. This is not a Windows/Ally full playthrough.
- Landed gameplay capability includes reachable Iona conversation footing and
  a traversable Stormheart approach lip, with actual Player/native terrain
  proof; corrected physical throw previews and controller party cycling also
  have actual fresh capture/training receipts. PR86 main's own34258802654
  was confirmed green at18:12; that validation is not double-counted as a new
  feature. The checkpoint has a positive merged runtime delta; zero streak0.
- Owner redirected effort toward actual content. Local content commit
  `d30e0e62b` authors the Tam-to-Practice Meadow gathering walk, moves two
  existing resource stops out of conflicting/less useful positions, explains
  the actual one-bed camp lesson, and corrects Salt Crown and Nerissa guidance.
  Draft PR88 head`9cb6b1b42d4c5947842f72e2b8a57a1cd54e4593` includes this
  content and already-prepared harvest/Aquaryn repairs plus earned ending
  composition. Its CI34270467585 is pending; no unmerged credit is counted.
- Genuine fresh scratch35664_2471 ended at595.393s: normal opening and revised
  dialogue, five earned creatures, ten training wins, actual18wood/18fiber/8stone
  camp bill gathered, four paid pieces placed and two real creature rests.
  The third bed assignment failed during the walk,5.2m short at[31,0,-38].
  Owner fingerprints match; zero engine/script errors. Full care, tournament
  and opening-to-ending remain open. Logs .artifacts/wave4-fresh-camp-lesson*.
- One labelled copy-save diagnostic reached the same bed in269frames and did
  NOT reproduce the failure. It observed contacts with the bed, a wild
  Bramblebun and terrain. No cause/fix is established and no unchanged rerun
  is accepted as fresh proof. Original scratch and owner saves remained intact.
  No further guessed detour is planned from these data.
- Existing content checks passed29/22302, village dialogue/quest110/1998,
  lesson helpers/home60/896 and Tidewake guidance113/2053. Four actual-world
  day/night captures received one fresh blind judge: key-art no, Palworld
  same-kind yes without quality parity. Named visual gaps are deferred.
- Travel observer recorded123 samples over1364.57m,92 below two visible
  creatures and one undersampled interval. Read-only review found the clearest
  ~50m empty-camera stretch was real road travel with the camera looking
  backward; three Mudsnouts were12–18m ahead of movement. No120m dead-content
  gap or placement change is justified by that record. Full coverage remains
  open. Next priority is ship the prepared content after exact-head CI, then
  progress actual play without reopening an unsupported navigation grind.
  Next checkpoint21:51UTC.

## 2026-09-08 21:40 UTC — actual content landed, Wave5 main verification pending

- Written before the21:51 deadline. Main is
  `65267c4bd935d80b2e073799caeffc81b913952c` after PR89, identical in tree to
  verified head`f4886bcb937e31a01276a2e5b7a42172b76be8d6`. Fresh integration
  branch is`codex/four-biome-wave6`; no new gameplay code is being built while
  main's OWN CI34281611197 is pending. PR success does not stand in for it.
- Material merged delta since19:51: PR88's authored village resource stops,
  camp instructions and Tidewake guidance; PR89's all-five care objective,
  persistent saddle preparation directions, installed Water combat HUD/shared
  Engage registration, and both recovered Brine ordinary encounters. Positive
  merged player-facing delta; zero streak0. No CI workflow improvement was added.
- PR88 main`2eb8d4b8681ce8224eaa58666b41be5164479c5b` passed its OWN
  CI34272560821 at20:31,27 successful jobs/two existing manual-only skips,
  Windows PE/exported Linux runtime checks and artifact10075421254. That green
  belongs to the previous main. Evidence`.artifacts/wave4-main-ci-34272560821-*`.
- PR89 first head08b5b3d6 failed CI34277113851 on two stale objective fixtures:
  inventory count33 after the new34th authored row, and the ordered chain missing
  condition_ready. Both fixtures now require the new content; every scope and
  transition assertion is retained. The old run ended24success/2failure/3skips
  and remains red. No rerun/cancellation/raised ceiling or softened acceptance.
- Corrected PR CI34279303451 passed at21:32:26 on attempt1:26 successful jobs,
  three configured skips,3056 units/487375 assertions, all seven multiplayer
  shards,86 wrapped smokes on attempt1 and18 direct checks. All jobs, steps and
  executed logs reviewed. Raw metadata/logs`.artifacts/ci-34279303451/`; verdict,
  strict and corrected-test receipts`.artifacts/wave5-pr-ci-34279303451-*`.
- Brine011's supported shelf and010's lower road shoulder each passed all three
  table species' native footing. Ordinary grounded approaches and physical
  Interact started their exact Riptusk/Mangrove Monitor encounters,85/86 observed
  frames, zero navigator resets. Original010 high ledge and011's invalid arbiter
  diagnostic remain recorded. No full fight win or full-road coverage claim.
  Logs`.artifacts/wave5-brine011-direct-*` and`wave5-brine010-low-*`;
  scoped data/residency checks12 tests/2213 assertions. Owner saves unchanged.
- Water's missing combat HUD now reuses the shipped panels and move controls.
  Existing scene smoke40headless/41rendered checks passed, zero engine/script
  errors, seven existing warnings. These are LOCAL receipts, not a new CI
  invocation. Render proves HUD presence; synthetic camera had not settled onto
  the fighters. Evidence`.artifacts/wave5-water-combat-hud*`.
- Saved paid-camp capture now visibly says to rest/feed all five before signup,
  superseding the misleading entry instruction. `.artifacts/wave5-paid-camp-guidance.png`
  is a diagnostic-copy frame, not resumed fresh play. Capture exit0, zero errors,
  fourteen explicit terrain/deprecation/staged-camera warnings; original scratch
  and owner fingerprints unchanged. Scope/chain/quest checks59/1223, quest/home
  54/896, Water dialogue/dock/quest47/937 are separate overlapping scoped suites.
- Isolated First Shore through Iona passed once in about18m24 within its existing
  20-minute watchdog, same synthetic carried five, no post-arrival state repair.
  Logs`.artifacts/wave5-water-through-iona*`. Its saved files do not preserve the
  final live Iona endpoint and its five species are unique; no copied-save
  workaround or new farewell policy was introduced to force a later segment.
- The genuine fresh frontier remains595.393s at the third bed-assignment walk,
  after paid camp and two real rests. The earlier copy diagnostic did not
  reproduce that stall. No camp-navigation fix, full care/tournament pass,
  uninterrupted opening-to-ending run or full forward-view coverage is claimed.
  Finish main's own shipping review, then continue actual player-path work from
  these limits. Next checkpoint23:40UTC.

### 22:08 UTC shipping addendum

Main65267c4bd935d80b2e073799caeffc81b913952c OWN CI34281611197 passed at22:02:52,
attempt1,27 jobs/two existing manual-only skips. All27 executed logs/every step
reviewed;3056 unit tests/487375 assertions,86 first-attempt wrapped smokes and
18 direct checks passed. Windows artifact10078655466 uploaded; exact export
receipts in MAIN-GREEN-20260908.md and `.artifacts/wave5-main-ci-34281611197-*`.
The fresh camp stall remains unresolved. Read-only preserved evidence does not
establish input ownership, sleep fade or a wild fight as its cause: the final
observer sample approximately1.4s before termination still records grounded
movement; the observer suppresses combat/paused/input-owned samples. Nearby
Bramblebun and Mudsnout are non-aggressive. Terminal locomotion is unrecorded.
No speculative fix or repeated fresh run was performed. Next checkpoint23:40UTC.

## 2026-09-08 23:48 UTC — owner-requested exit

- Owner asked to write/push the handoff and stop. All agents interrupted and no
  Godot processes remain. Resume only on owner instruction. Full handoff:
  docs/HANDOFF_FOUR_BIOME_2026-09-08_OWNER_STOP.md.
- Main remains65267c4bd935d80b2e073799caeffc81b913952c, own green CI34281611197.
  PR90 draft gameplay head10fb6f1dbcc4dd42fdf4fb532c7fee4101dac801 passed
  CI34287024505 with exhaustive review. Picker/input head
  8eb887baced51b611abcf8dfadd630dfc1c5640c passed CI34288938433 at23:21:44UTC,
  attempt1,26 successful jobs/three expected skips. Units3062/487412; all logs
  downloaded, final exhaustive review of this head still open. Exit work is a
  subsequent unverified head, not covered by those green runs. No new landing.
- Picker: Arlo/Lyra/Kael/Sera portrait cards, preserved save IDs; actual UI
  controller/keyboard checks and blind capture passed; combined unit13/70.
  ROG bed issue resolved by owner using Gamepad mode; no hardware code-fix claim.
- Actual solo realm-load baseline336.006s, routes82.878s and later mount233.020s;
  exit0, owner fingerprints matched. One native ridge cache comparison reduced
  267896us to212454us with identical mesh/collision SHA and49812 vertices. No
  optimized full-transition proof. Named logs: realm-load-baseline-v2* and
  route-cost-{original-v3,cached}* under.artifacts.
- Supplemental Cloudreach render crashed during _plant_tufts with a null memory
  allocation and signal11; no complete sheet. Owner fingerprints matched after.
  Logs.artifacts/wave6-cloudreach-before*. Earlier parse/fixture failures remain.
- New owner directive explicitly pulls forward StageC6: all58 Settings destinations
  across four biomes, day/night; full blind rubric; local/systemic classification;
  all-affected-biome before/after proof; separate earned-content agent. No complete
  audit implementation, full sheets, blind biome verdict or visual repair yet.
- Original uninterrupted fresh opening-to-Tidewake remains incomplete. Two failed
  Wave6 fresh attempts and the withdrawn native aim hook remain failures. The
  isolated Stormwood Crown run was interrupted for ROG after six gathered glass;
  no Crown/full campaign completion. Do not copy a save or inject progress to advance.
- Diagnostic source snapshots preserved in exit-20260908-diagnostics; raw captures,
  profiles and logs remain local. No new tests or gameplay work after owner stop.

## 2026-09-09 00:01:09 UTC — resume checkpoint 0

- The owner explicitly resumed the full prompt 78 §7 four-biome Beta Ready objective.
  Resume branch `codex/four-biome-audit-resume-0908` starts from the Wave 6 exit;
  main remains `65267c4bd935d80b2e073799caeffc81b913952c`. No resumed work is claimed merged.
  First required two-hour checkpoint is 02:01:09 UTC.
- Exit-head PR #90 CI `34292244664` verifies exact head
  `452a4d63cc33030703612d71d7a2e390d4d8a995`: attempt 1, 26 successful jobs and
  three configured skips, terminal at 00:09:50 UTC after 21m44s. Units passed
  3,062 tests/487,412 assertions. Eighty-six distinct wrapped smokes completed, but
  traversal failed its first invocation at the open Sigil Gate and passed attempt 2/3;
  this is a disclosed retry finding, not first-attempt-clean evidence. Full verdict:
  `EXIT-CI-34292244664.md`. This green is PR-head verification only, not merged credit.
- Astra diagnosis `68ef32feb`, Sol helper fix `cd8f87038`, and receipts `3b44f9960`
  identify and repair the test driver's stale camera-follow readiness without a
  production aim change. Focused checks pass, including a legacy negative control.
  The one authorized changed fresh campaign then crashed before aim in minimap baking
  with `Parameter "mem" is null`/`mem_new is null`/signal 11. No campaign milestone.
- Cloudreach Lane 0 report `b680b3968` preserves one exclusive successful entry-code
  arrival frame (stand 01 only). The three stands 01/04/05 were produced by a temporary
  batching candidate with changed culling and are auxiliary/unaccepted, not entry-
  equivalent. Production is restored byte-for-byte and the original allocation crash
  remains unresolved; resource pressure is a hypothesis, not an allocator cause.
- Stage C6 audit status: no biome has a valid complete sheet and none has been judged.
  Meadows round C wrote 20 files but every X coordinate was zero because the survey
  converted a numeric Array through string splitting (`float('[6,') == 0`); those files
  are invalid coverage and are preserved only as failed evidence. Typed Array parsing,
  a pure 58-coordinate plan check, then a fresh capture are required. All 58 catalogue
  locations by day/night across Meadows, Cloudreach, Stormwood and Water remain in
  scope, with content/campaign progress kept parallel and full-world processes
  serialized for RAM.
- Latest user audit-first directive, summarized rather than quoted: prove the complete
  catalogue and blind full-rubric visual audit before claiming fixes; preserve exact
  failed attempts; continue earned content in parallel; do not convert debug travel or
  synthetic fixtures into campaign credit.
- Next highest-value work: correct and validate all 58 planned coordinates, run fresh
  full-world day/night campaigns one biome at a time under the RAM lease, assemble four
  biome sheets plus the combined sheet, obtain a fresh code-blind rubric verdict, and
  triage accepted local/systemic findings while the independent earned-content lane
  continues toward the genuine opening-to-Tidewake ending.

## 2026-09-09 02:01:20 UTC — resume checkpoint 1

- Player-visible capability added: none merged during this two-hour interval.
- Paths newly reachable: none merged during this two-hour interval.
- Systems newly working in real play: none merged during this two-hour interval.
- Content added: none merged during this two-hour interval.
- Merged SHA: `65267c4bd935d80b2e073799caeffc81b913952c`; a read-only
  `origin/main` check at 02:01:20 UTC confirmed that main is unchanged. The interval's
  merged, runtime-evidenced delta is zero.
- Evidence in progress is deliberately excluded from merged credit. All 116 baseline
  catalogue frames have a completed blind judgment and triage at `732c889ad`; 116
  corrected-camera frames and audit sheets exist through `e93a9f341`, with fresh
  judgment pending. The pylon material change `2a5f291f3` has focused native tests and
  post-material Cloudreach/Stormwood captures in progress, but no blind verdict or CI
  coverage. CI run `34296093682` is first-attempt clean for exact head `812ab87eafd87f2bd54074def488730f27dd56a5`
  only. None of these unmerged heads establishes a landing.
- Blockers: no resumed work has landed; the final post-material visual round and fresh
  blind verdict are incomplete; later integration heads still need exact-head CI and
  landing. Bounded aim-guard and phase proofs failed, and no fourth fresh campaign was
  run. The latest actual campaign reached a catch plus 102.09 seconds of standing and
  was stopped before completion. Current Water-return and Stormwood-arrival work is
  uncommitted and unproven.
- Next highest-value task: finish the post-material recapture and fresh blind visual
  verification, obtain green CI for the resulting exact integration head, land through
  the PR, then continue the standing Beta goal from the remaining earned-play frontier.

## 2026-09-09 04:01:24 UTC — resume checkpoint 2

- Player-visible capability added: the merged new-game picker presents four named,
  portrait-backed choices with controller/keyboard selection, and the merged Water
  return gate provides an ordinary interaction back to Stormwood. Focused physical UI
  evidence and the bounded solo return run passed; neither is a full campaign claim.
- Regions or paths newly reachable: PR #90 mounts the Water-to-Stormwood return and
  preserves the elevated authored Stormheart arrival. The solo full-scene fixture and
  PR #91's two-peer 33-check fixture both reached ready Stormwood, cleared pending entry
  and observed a grounded player at the authored point. Their prerequisites were
  disclosed fixture state, not earned campaign progress.
- Systems newly working in real play: the return route preserves WORLD authority and
  route facts in solo and two-peer evidence, with host/client realm and shell ownership
  checked. Team Tether pylon consumers now apply their installed live/drained finishes;
  Cloudreach and Stormwood were recaptured, but independent visual closure covers only
  the visible Verge material portion. Other repaired consumers remain context-unverified,
  and no shipping-art or whole-biome acceptance is claimed. The older avatar/proxy
  cached-packet teardown issue remains open.
- Content added: Arlo, Lyra, Kael and Sera now have distinct installed picker
  portrait/name cards, and five previously unfinished Cloudreach/Stormwood pylon
  consumers now use the shared installed material treatment. The corrected 116-frame
  audit and independent reviews are evidence of the build, not new gameplay content or
  a Stage C pass.
- Merged SHA (`origin/main`):
  `49da91d51953fb4b650f29b1399ae41218f68f86`. PR #90 landed as
  `57660e4feb81fcbf8de5b0fe065e0ac107287676` with exact-head and main push CI,
  Windows debug/release exported-runtime ground checks and public asset `551867266`.
  PR #91 head `b5dd34b4b7cec5bafc76affdbf33af84192e84a5` is an ancestor with an identical
  merge tree and passed exact-head CI `34306689396` on attempt 1. Its new main CI
  `34308309450` remains under separate review.
- Blockers: the genuine title-start path remains stopped at the documented aim commit
  race and has never reached Stormwood. Stage C and shipping-art acceptance remain
  open. Release `34308309474` exported and published asset `551927103`, but literal
  `tags/latest` still resolves to old commit
  `a8423f00fc0245af166222383b9c24dc7beb603e`; release identity hygiene is therefore
  not closed. The active chapter-entry Crown regression is local, synthetic-seam
  evidence and remains uncredited while running.
- Next highest-value task: finish the single bounded same-live Stormwood
  `--through-crown` regression and stop at its first result, then use that evidence to
  choose the smallest substantive Crown/player-path repair. In parallel, finish exact
  main CI/release review and the diagnosed rolling-tag workflow repair; do not restart
  the blocked fresh aim campaign or mark a stage complete.

## 2026-09-09 10:41 UTC — PR92 continuation after disconnect

The owner explicitly instructed continuation across the connection loss as if no
time had been missed. The disconnected interval is not counted as repeated
zero-delta checkpoints. The standing Beta goal remains active.

- Player-visible capability added on main: PR93 repairs the rolling download
  identity. Its published Windows ZIP and literal latest tag now identify the
  same verified main commit. The actual downloaded Windows executable loads its
  packaged terrain and reports the correct spawn ground in a bounded headless
  runtime check. Rendering and campaign completion are not inferred.
- Regions or paths newly reachable: none newly established by this continuation.
- Systems newly working: release publication updates and verifies the rolling
  tag after asset upload. Exact-head and main CI plus Release passed first
  attempts. The downloaded ZIP digest matches the publication metadata.
- Content added: none. Existing visual audit evidence is retained. At the owner's
  latest direction, a dedicated visual review/fix lane stays active; its current
  bounded investigation is Veilfall's day/night waterfall overlay, pending
  attribution renders and independent blind verification.
- Merged SHA: `4830bf402a94d7d945119027a454d07dfee1dccc` (PR93), verified against
  reviewed tree and ancestry. See `CI-MAIN-4830bf402.md`,
  `RELEASE-MAIN-4830bf402.md`, and `WINDOWS-RELEASE-4830-PROOF.md`.
- Unmerged evidence excluded from capability credit: PR94 finalized-death repair
  has 37 native and 28 two-peer checks. Its first full CI failed the omitted
  telemetry output environment setting; corrected head `e5056c65f` is in new CI.
  Local aim commit cancellation has 19 native plus 8 real-HUD checks and driver
  integration at `0ccefb674`; a single real-manager encounter proof is pending.
  No fourth fresh campaign or through-crown replay has run.
- Blockers: continuous earned-path, shipping-art, broader Stage C and Beta gates
  remain open. Neither an isolated encounter nor publication proves those gates.
- Next highest-value tasks: complete PR94 exact-head raw-log review and landing;
  execute the bounded real-manager catch-loop proof; attribute and repair the
  confirmed Veilfall visual defect, then obtain a fresh code-blind verdict.

## 2026-09-09 12:41 UTC — visual waves and verified PR95 validation tooling

- Player-visible capability or content newly added on main: none in this
  interval. PR95 changes earned-input validation helpers and probes, not the
  production free-aim implementation. Gameplay/content delta is zero; the
  merged validation work below is not relabeled as a new player capability.
- Merged runtime evidence: PR95 landed as
  `ab5314e1b081b018decc17d070fba85ee3afd210`, ancestry and reviewed tree verified.
  Its earned-input helper now cancels stale commits and completes a bounded
  real-manager catch (one orb, one natural catch, party 1 to 2). Exact-head and
  main CI passed on attempt 1; all executed raw logs were inspected. Main export
  and Release passed packaged-ground checks, and independent live read-back
  verifies the published asset and literal latest tag target ab5314.
- Newly reachable earned campaign paths: none established. No fourth campaign
  or through-crown replay has run. PR94 remains held, not merged.
- Unmerged visual work, excluded from capability credit: Cloudreach High Perches
  first candidate is held after its narrow-view blind rejection. Crown Arch now
  has split-surface materials, corrected rear-detail placement, four final real
  views including ordinary walks/orbits, and 4 tests/31 assertions. Two creature
  repaints are imported and shown in a corrected 1280x800 static production-body
  comparison; ordinary-world species/facing limitations remain. Arlo's selective
  texture has a verified runtime binding and isolated material cache. Water's
  installed masonry finish passed existing gate mechanics and the ordinary
  return into Stormwood. Its first integrated run exposed an unimported character
  asset; the corrected run at 12:40:02–12:40:58 exited 0 with no native/script
  errors. Meadows' local flower composition passed 19 tests/87,822 assertions
  and is entering its first production capture. Independent visual verdicts and
  shipping PRs remain pending for this wave.
- Multiplayer mechanism progress, unmerged: an observation-only run located the
  client drain stall at Godot's peer-zero public visibility fast path. Scoped
  aggregate public checks plus actual-peer refresh preserve native automatic
  cadence. Corrected three-peer component proof passed 81 checks, all processes
  exit 0 and all raw logs clear; actual receiver inventory drains before detach.
  Game connection, cancellation/rollback, late join and full traversal remain
  unproven. Earlier failures are preserved, not retries credited as first passes.
- Resource/process hygiene: one full-world renderer at a time; the original 287
  dirty import files remain preserved. One intentional new Arlo texture sidecar
  is separate. Root restored only three unrelated editor-touched Bark sidecars.
- Blockers: broad Stage C, earned Stormwood/Water completion, shipping-art and
  Beta gates remain open. Fresh critic creation is rejected by the session's
  agent thread limit. A reused reviewer who has not read visual implementations
  is reserved for image-only review, with operational naming exposure disclosed.
- Next highest-value work: finish Meadows capture and independent visual review,
  integrate only reviewable verified fixes through exact-head PR CI, then connect
  the proven client receiver protocol to Game with its required cancellation,
  rollback and compatibility checks. Keep the two visual assignments active
  across biome/cast waves rather than returning to exhausted material tuning.
