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
