# Stormwood original-run tail and resumed priorities

The Stormwood is **not complete**. Original-run merged main is `4562268dee581d2f2ce167a4670bbf752f139310` (PR #76), with root-confirmed ancestry of head `adea7467fc746e45f0d83123035d0123e2a282d2`. PRs #68, #70, #74 and #76 landed. PR #77 preserves the Crown/building/TM wave from `ralph/stormwood-dynamo-0907`, head `69ac802852cecc31f8ac79a5bfa8c4d6d66f02d2`; it is open pending real code CI, not merged. Do not land unrelated origin lanes or the Water draft. The scratch backup remains `a92faa8bd`.

The score history is 0 → 0 → 5.25 → 12.00. Missed 05:54 and 07:54 UTC windows retrospectively add zero and trigger the original run's stop rule. There was no verified overnight work after approximately 04:06 UTC. The owner's explicit 12:10 UTC continuation starts a resumed segment with the same objective and frozen 100-point weights; next checkpoint is 14:10 UTC. See `scorecard.md`; do not relabel elapsed time as productive work.

## System status

“Proven” below identifies only its explicitly named scope; no entire exit criterion is closed.

| System | Classification | Actual state / missing acceptance |
|---|---|---|
| Cloudreach handoff | Proven partial | Real locked production gate enters Stormwood and returns; two-peer realm seam passed on main/CI. Completed-Cloudreach saved-player continuous path remains unproven. |
| World | Implemented but unproven | Six Terrain3D regions, baked scatter, 15 settlement structures, 19 NPCs, 26 trainers, 330 wild clusters (660 mounted instances in a prior startup), 210 harvest sites and 229 configured pickups. Full route, forest visual acceptance, Crown exploit audit and Ally performance remain missing. |
| Surge | Proven partial | Host weather clock, phase-gated live harvest, rod duration rules. Blind phase recognition, changed encounters and full multiplayer field play unproven. |
| Hazard | Proven partial | Host warning/impact fixture and duplicate suppression. Gear/creature effects and actual multi-peer forest strikes unproven. PR #77 adds all-phase Sink eligibility; the corrected Compatibility survey renders, but it is not hazard-play evidence. |
| Arches | Proven partial | Main ancient relight/passage fixture; PR #77 actual built-arch costs, Crown return, dismantle and destination-clearance fixture. Full ENet construction/late-join and real forest journey missing. |
| Crown | Implemented but unproven | PR #77 heartstone and built-twin access have isolated live proofs. Guardian is not mounted and does not gate Wen; no continuous Crown truth journey. |
| Story/objectives | Implemented but unproven | 28 authored main objectives and six side chains. Real opening advances Ashfoot → Hesk → Tamsin. Acts II/III and side-chain completion not demonstrated. |
| NPCs | Implemented but unproven | 19 mounted characters, 57 conversations. Most states, regional resident counts and full dialogue cadence need review. |
| Trainers | Implemented but unproven | 26 mounted. Guard-to-rod sequence not played; client-originated trainer fights inherit a local-only start limitation. |
| Encounters | Implemented but unproven | 330 ordinary clusters mounted as 660 wild instances in prior successful startup. Six named rows and Surge/night tables are not integrated. Remote-originated wild combat is a known authority gap. |
| Resources | Proven partial | Actual Stormglass harvest and durable site claim. Broad collection/crafting cadence unproven. |
| Gear | Implemented but unproven | Inventory items and eight live recipes exist. Insulation's actual strike mitigation is not connected. |
| Pickups | Proven partial | 229 configured records: main mounts 222 ordinary pickups; PR #77's item definitions raise mounted ordinary pickups to 226 with four working electric TMs; three story-owned rewards remain withheld. No complete walked pickup route. |
| Camps | Implemented but unproven | Six placed/rest-recovery camp anchors and shelter rules. Built rods and intended overnight pressure missing. |
| Dynamo | Blocked main path | Phase rules, kitbashed arena parts and host/field-control adapters exist in PR #77, but no mounted encounter/controller. Needs real host-owned Marrow roster, replicated phases, conduits, co-op loss/retry and late join. |
| Legendary | Blocked main path | Captive placeholder specified; no release/accept-decline/five-slot ceremony. |
| Spark / aftermath | Blocked main path | Authored objective data only; no earned placement, Livewire or observed world response. |
| Waterward setup | Blocked main path | Authored ending intention; no played non-enterable Water vista ending. Water is Stage B after Stormwood acceptance. |

No missing gameplay system is intentionally deferred. Creature replacement art is intentionally deferred under the owner directive. The sole permitted Stormheart Meshy hero generation has not been spent; its prerequisite playable kitbashed arena does not yet hold.

## Preserved evidence

- `runtime-wave-evidence-0907.md` records main's field/opening proofs and their limits.
- `crown-wave-evidence-0907.md` records PR #77 proof commands and the historical failed Vulkan-forced capture attempts; the corrected Compatibility capture is recorded below.
- `census-and-placeholders-0907.md` lists §13 actual configured counts beside requirements and all explicit replacement points; configured counts are not route evidence.
- The corrected production Compatibility survey emitted eight frames at `D:/CodexWork/stormwood-crown-compatibility` on the GTX 1060; a separate compositor made `_sheet.png`. `crown-visual-judge-0907.md` rejects both visual bars. This is real rendered evidence, not a playthrough or visual acceptance.
- PR #76 CI run `34078735577` passed required jobs after one isolated catch-race retry. PR #77 CI run `34121356609` is live at this report's creation; do not infer its final result.
- PR #77 also carries the corrected source-map tests: Stormwood ordinary mounted pickup specs now supply the four TM records, and the build-cost test follows the Thunderwood Frame recipe to actual Stormwood harvest sources. CI remains pending; the test correction is not merge evidence.
- Local full unit wave for PR #77: `D:/CodexWork/stormwood-crown-full-unit-wave.log`, still running at report creation. Earlier narrow run passed 31 tests/309 assertions; actual heartstone passed 10 assertions; built-arch journey passed with shutdown resource warnings.
- There is no continuous chapter playthrough, accepted current frame set, or measured Ally performance result.

## Blockers and strongest next hypotheses

1. **P0/visual acceptance:** the old renderer/startup blocker is closed. The project is Compatibility and the corrected production survey emitted all eight frames. The remaining blocker is the judge's substantive rejection: sparse repeated forest, unreadable Stormheart silhouette/core, weak event/creature staging, flat horizon/ground, and visible Crown artefacts. Fix the largest visual mechanisms before recapturing; do not relabel a frame set as accepted because it rendered.
2. **P0/multiplayer encounters:** a remote peer challenging a trainer builds its local queue; `_open_encounter_if_networked()` returns on non-host. A remote wild start likewise lacks a host-owned wild identity. Joining a host-started fight is not proof of remote initiation. Strongest next approach: host-owned realm encounter coordinator with stable opponent identity, sender-derived admission and existing EncounterHost/CombatManager damage rules; reuse for Marrow and named progression. Preserve `D:/CodexWork/stormwood-dynamo-combat-adapter.md` and `stormwood-named-runtime-adapter.md`.
3. **P0/Crown order:** named `crown_guardian` exists only as data; Wen can currently tell the truth after Crown arrival. Mount the real encounter with a durable host defeat/catch outcome before changing Wen's gate, then play travel → guardian → Wen → heartstone → Rootgate continuously.
4. **P0/climax:** Marrow challenge deliberately refuses until `StormwoodDynamo.arena_ready()` exists. Mount all four capacitor banks/three plates on the actual tree arena and connect host roster/phase/conduit state. Verify a remote initiator with host in a different realm, stale actions, wipe/retry and late join.
5. **P0/ending:** no release/relic/Waterward runtime yet. Use the existing five-creature roster ceremony and exclusive relic system; do not invent a sixth slot or enter Water. Then play the whole chapter and close density/save/visual tails from evidence.

## Next bounded tasks, in order

1. Land PR #77 only after its actual code jobs pass; record merge SHA/ancestry. The two source-map test corrections are present, but pending CI is not a pass.
2. Implement and prove host-owned Stormwood encounter starts, retaining existing combat math and player control.
3. Integrate the six named encounters and finish the Crown guardian/truth/Rootgate path.
4. Mount and finish co-op Marrow/Dynamo phases, conduits and captive release.
5. Complete Spark/Livewire, aftermath and non-enterable Waterward view, then full chapter evidence and remaining §13/visual/performance closure. The known configured content gaps include 57 rather than 160 dialogue conversations and 8 live rather than 12 required recipes.
