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
