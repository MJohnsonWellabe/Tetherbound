# F10#0 close: six Stormwood chains satisfy §5

**Criterion:** ACCEPTANCE §6.1 F10, first clause: "All six selected Stormwood chains satisfy §5 with distinct lure/action/payoff/acknowledgement."

**Status:** CLOSES under the 2026-09-27 owner ruling (#356 comment 5853566761). Under that ruling, shortcuts are disclosed; they no longer make a claim partial.

**Row type:** not a visual row, so no code-blind judge is required. The visual/audio matrix is a separate F10 clause.

## Strict re-score (two independent read-only passes)

**Pass 1, on 9a1e1a23 (chain code identical to main 1ba253eb).**

| Chain | Verdict | Acknowledger | Evidence detail |
|---|---|---|---|
| Dark Arches | MET | Hesk | |
| Pim's Parcels | MET | Pim | |
| What the Crown Remembers | MET | Wen | |
| Glass for Bryn | MET | Bryn | |
| Raise a Road | MET | Ondra | |
| Deepwood Circuit | NOT MET | Rook | Two gaps, below |

All six chains have distinct lures, actions, payoffs and acknowledgers.

The two Deepwood Circuit gaps were not covered by the ruling:
1. **The lure misdirected.** The step-1 label sent players to Lantern Hollow, but Rook stands at the Fallen Giant. The progress line also misplaced the posts.
2. **Rook's TM payment had never run on the engine path.**

**Fix: 9c6290d8.**
- **Label:** now "Accept Rook's circuit at the Fallen Giant."
- **Progress line:** names the five real posts: Lantern Hollow, the Deepwood Rod Station, the Old Rodfolk Hall, the Blackwater edge, and the Fallen Giant.
- **Data test:** `test_the_circuit_lure_names_where_rook_and_his_posts_stand` fails on the old text.
- **Engine smoke:** `tests/smoke_stormwood_b_rook_tm_payment.gd` runs the production Game autoload, world ledger `reward_grant`, inventory, delivery journal and `save_game`/`load_game`, with the real `RookCircuitReward` node. It checks four things:
  - the return pays exactly one TM: Thunder Break and announces it once;
  - the thanks pays nothing more;
  - the TM and its receipt survive a save and reload;
  - a repeat claim after the reload pays nothing.
- **Product fix:** `RookCircuitReward.mount()` no longer calls `bool(null)` on a world without `simulation_only`.

**Pass 2, on 9c6290d8.** GAP 1 CLOSED, GAP 2 CLOSED, no regressions. Verdict: **F10#0 CLOSES.**

## Commands (Godot 4.7, headless)

| Command | Result |
|---|---|
| `tests/smoke_stormwood_b_rook_tm_payment.gd` | 16/16, PASS |
| `tests/smoke_stormwood_deepwood_circuit_wiring.gd` | OK |
| `run_tests.gd -- --only=stormwood` | 396 tests, 0 failed |

## Disclosed shortcuts

**Two-peer receipt proof (`STORMWOOD-PROGRESS/two_peer/stormwood_f10_side_chain_receipts/PROOF.md`):**
- Upstream flags were set as fixtures: `ashfoot_arch_relit`, `rootgate_released`, `lantern_pools_linked`, `crown_reached`, the crown guardian clear, `engine_truth_learned`, `bryn_met`, `arch_recipe_known` and `lantern_hollow_reached`.
- `explore_at` debug travel was used.
- Materials were granted: 12 Stormglass for the arches, and Bryn's Stormglass and Conductor Vine.
- Raise a Road ran under Free Build, so no material charge.
- Three circuit trainer wins were set as defeat facts rather than fought.
- A named host save was used.
- That proof predates Rook's TM, and it read 2 of the 3 return lines.

**Rook TM smoke:**
- The circuit flags were set through the ledger.
- The chapter is a stub that records Rook's story events, so the chapter's one-line routing is covered by the wiring smoke instead.
- The world is a bare Node3D.
- The conversation completion was called directly, without walking to Rook or opening the dialogue UI.
- It ran solo host only. Guest per-character payment is covered by the stubbed unit test.

**Wiring smoke:** trainer outcomes are scripted at the hub's post-battle callback on a fixture world.

**Unit tests:** the TM, ledger, guest and reload units use stubs.

**Other notes:**
- **Dark Arches map payoff:** the only rendered frame is the minimap, where the arch glyph is edge-clamped from Ashfoot. The Tab-map frame capture is still pending (recommended evidence, not blocking).
- **Pairs C and D:** read as the "Deepwood/Dynamo" pairs, per WORLD §5.1.
- **Second TM source:** `tm_thunder_break` also has a Deepwood world pickup. That is acceptable under the binding STATE ruling on Rook's reward.
