# Water runtime wave 2 — branch evidence

2026-09-07. Work remains on `ralph/water-foundation-0906`, draft PR69, now in the owner's requested separate `D:\Tetherbound-Water` folder. No Water change is merged. Rebase onto Stormwood main `84125fcd008d93c0fefdfff51a2752b94b4faada` completed and ancestry was verified. The integrated wave is `33b3c9ef9`; tested portrait/save-contract corrections were pushed as `05a272f8961ca122a23063adc763202d2a853906`. This is an integration checkpoint, not phase closure or a complete fourth chapter.

## Player paths exercised

- Human swimming: the production 60.143m lesson, stamina/gradual drowning, combat pause and dry safe-anchor rules. A fresh Water world/character-file reconstruction retains health, exhaustion and landing and resumes drowning (21 checks). Midwater mounted reconstruction is still missing: it currently restores the rider as a human.
- Dock repairs: 32 real-world checks activate the Reedhaven prompt, spend exactly six reed and four driftwood, remove its physical barrier, weaken its current, and restore closed/open states through slot saves. Shellwatch requires both trainer prerequisites and both physical actions. These use setup flags; no complete island-to-island chain has been played.
- Eight camps: 129 real-world checks cover installed components, dry baked grounding, unique creature-bed indices, accessible rest/craft offers, two driftwood converted into six wood, day 1→2 through the rest interaction, and save restoration. Tests teleport between camps; no continuous route or multiplayer sleep-vote proof is claimed by this smoke.
- NPCs, pickups and encounters use the installed production systems. The independent [density census](density-census-wave2.md) distinguishes catalogue counts, tested instances and actual travel. The roster now exposes existing role-compatible Best Creature abilities; root reran 50 tests/425 assertions successfully.

## Recovery and multiplayer

Death bags now use world-authoritative satchel transactions and inaccessible character escrow. Scene teardown, lost acknowledgements, inventory capacity changes, stale deltas and failed world journals were independently reviewed. Final production recovery smoke: 36 checks. Escrow regression: 62 tests/322 assertions. Actual ENet peer run: host 6/client 8, including discarded committed reply and freed presentation node. Existing human-swimming ENet proof is a separate earlier run; it does not prove mounted reconstruction, Alpha authority or the finale.

An uncommitted creation retried after the trainer moved over five metres is placed at the host's current trusted trainer position, keeping recovery accessible without trusting arbitrary client coordinates. Already committed bags retain their positions. No disconnect refund creates a second copy.

## Mounted traversal findings

The production all-five smoke passed 91 checks after a real remount defect was fixed. Aquaryn, Mosshell, Sirenseal, Riverdrake and Cannonback each exercise movement, separate swim stamina, unchanged combat energy/human stamina, settled seat position, gradual exhaustion damage, deep human dismount, remount without refill, and input-driven dry exit. The earlier spontaneous sideways kick and shore stall disappear with an opt-in modifier axis mask: replaced vertical buoyancy is no longer treated as additive-current carryover. Seven environment/replication tests passed 29 assertions; existing additive wind remains the default. The smoke explicitly supplies the Stone, saddle, owned creatures and restoration of stamina for the separate exit test, so it proves neither Alpha rewards nor crossing budgets. Land recovery packets now advance revision when stamina changes. Non-unit body-scale fitting and mounted reconnect remain unresolved; a real two-peer mounted slice is next.

## Terrain and visual limits

Thirty Terrain3D regions and the water-height texture were rebaked after grading. The four-route composition correction reduced analytic over-35° samples from 38 to three; those remaining samples are on Drowned Garden around (1086–1087,2206). These are analytic centreline checks, not a completed walking census. The six captured views failed blind visual review: sparse shore composition, unreadable Veilfall silhouette, angular shore/water transitions and missing recognizable stronghold/Alpha staging. No final Water mesh and no Meshy generation has landed.

## Verification still open

The unsharded full suite terminated during harvest tests without a completion summary. Its preceding new Best Creature failure was fixed and independently rerun; an Alpha-save JSON read failure did not reproduce in isolation (1 test/5 assertions), and is not dismissed as a pass. A complete sharded run and current-commit CI remain required. Earlier wave CI failed the hidden Skills menu expectation, now corrected in source; previous green jobs are not current-wave evidence.

The Alpha, Swim Stone award, named deep encounters, Water-specific combat surfaces, Veilfall interior/captain/Guardian release, Tidal Guard, named relic and world response are incomplete. Existing EncounterDirector explicitly leaves client-started local wild fights unarbitrated (`_open_encounter_if_networked`); reusing that path alone cannot satisfy Water's shared Alpha authority. A host-owned named-encounter request/representation must be completed before claiming multiplayer-native Alpha behavior.

### Rebase verification and current work, 01:54 UTC

The combined flight, player state, realm maps, Skills and aquatic save run passes 48 tests/448 assertions after correcting the expected character key list to include escrow. CI run 34073362639 on `33b3c9ef9` exposed missing Water HUD portraits and the historical five-Meadows-only mount test; the shared HUD/menu placeholder resolver and exact five-Water additions pass root's 63-test/359-assertion check. Unit shards 2 and 3 and several scene jobs completed successfully on that CI run, but the two failing shards prevent a full-pass claim. The subsequent pushed commit needs its own CI verdict.

Mounted save reconstruction now stores the existing party slot/species/body position and uses normal deployment/mount attachment; it compiles and its payload checks pass, but the independent actual scene/disk reconstruction smoke has not run. The prepared two-process mounted swimming test has not run either. Neither earns extra progress credit yet.

The moved-folder import terminated with actual memory-allocation errors. A second strategy limits the temporary local worker pool to two, retaining serial imports, and remains active. The local shard-2 attempt reached 758 tests/317340 assertions with two failures: Windows shell-dependent gate-F setup and a missing imported Bag mesh; its additional null-resource errors make it unsuitable for scene regression evidence before imports finish. Do not call this a full suite pass or a new gameplay regression without reproducing after import completion. The temporary `override.cfg` and generated cache metadata are not shipping changes.

### After the fixed second checkpoint

The two-worker import completed with exit zero and no engine errors. The subsequent actual two-peer mounted run (`water-mounted-network1.log`, isolated peers in `water-net-local-2105540`) passed 30 checks with clean peer logs. The client-owned Aquaryn travelled35.817m by real input; the host applied matching mount/rider ownership and MOUNTED snapshots, changing swim stamina, saddle/seat alignment, drowning, HUMAN dismount and exhausted remount without refill. Positive combat energy20 and human stamina were preserved. Root inspected the test and Water-only peer-runner changes against the output. This proves transport of mounted traversal, not earned Alpha rewards, crafting or reconnect.

Twenty-two additional harvest nodes bring the configured total to182 and meet the per-island BUILD minima. Root's pure terrain rerun passes1test9678assertions, including dry approach slopes, spacing and landing clearance. Original160harvest and200pickup records remain unchanged; the density-census appendix names all additions and explicitly withholds baked scene/walking/visual credit. These results occurred after01:55:38 and do not retroactively increase that checkpoint's18/100.
