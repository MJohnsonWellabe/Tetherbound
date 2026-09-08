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
