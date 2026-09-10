# Stormwood Deepwood Circuit 01

## Retained behavior

The documented **Deepwood Circuit** side chain now has a complete production path:

- Finishing Rook's real offer conversation accepts the circuit.
- The existing five trainer rows tagged `deepwood_circuit` are the sole membership source.
- Any three distinct trainer wins complete the battle step. Each win maps to one durable namespaced world flag, so a repeat cannot count twice.
- Wins earned before acceptance are recovered from the existing authoritative trainer defeat flags when Rook's offer finishes.
- Three wins do not finish the chain. The player must return and finish Rook's acknowledgment conversation.
- The quest text explicitly says “any three of five” and advances through acceptance, battle, and return states.
- Rook retains his prior chapter dialogue after the circuit is complete and his existing post-storm conversation after the Long Storm ends.

The chapter adapter's existing realm-ledger writer owns these world facts. A count-aware side step accepts only its declared trainer-win flags and reaches its authored threshold; sending the aggregate step event cannot bypass the wins. No trainer, reward, item, geometry, or major story beat was added. The other five Stormwood side chains remain unconnected for the concrete reasons recorded in `.artifacts/broad-visual-0910/STORMWOOD-SIDE-CHAIN-PRODUCER-AUDIT.md`.

## Owned files

- `data/config/stormwood_chapter.json`
- `data/dialogue/stormwood.json`
- `scripts/combat/stormwood_encounter_catalogue.gd`
- `scripts/world/realm_chapter_progression.gd`
- `scripts/world/stormwood_chapter.gd`
- `scripts/world/stormwood_encounter_hub.gd`
- `tests/test_stormwood_deepwood_circuit.gd`
- `tests/smoke_stormwood_deepwood_circuit_wiring.gd`

## Validation record

1. **05:31:38–05:31:46 — meaningful failure.** The initial focused run found one failed assertion followed by two bounds errors: the production encounter catalogue discarded the authored trainer `group`, so the runtime-facing query returned zero Circuit members instead of five. The catalogue adapter was corrected to preserve that field.
2. **Intervening selector mistake — no evidence.** A rerun passed `tests/...` to `--only`; the runner expects selectors without that prefix and selected no files. This invocation is not counted as validation.
3. **05:39:55–05:40:01 — behavior passed, cleanup failed.** The first production-wiring smoke passed every callback assertion, but its wrapper reported two resources still in use. The fixture was corrected to free its unparented encounter hub and owned world, then wait two frames before exit.
4. **05:40:45–05:40:51 — focused contracts clean.** The corrected focused selection passed **20 tests and 662 assertions**.
5. **05:43:04–05:43:09 — production-wiring smoke clean.** Rook dialogue completion, pre-earned defeat recovery, unrelated/repeat rejection, a distinct third trainer win, and Rook return all passed through the actual production callbacks with **zero engine errors and clean resource exit**.
6. **05:43:45–05:43:50 — final focused set clean.** Circuit, realm progression, trainers, hosted encounter, and Water material coverage passed **23 tests and 678 assertions**; the Circuit-focused portion covered **21 tests**. This includes the Rook in-progress and post-storm fallback regression.

The focused runner's selector omits the `tests/` prefix:

```text
godot --headless --path . --script res://tests/run_tests.gd -- --only=test_stormwood_deepwood_circuit.gd
```

The integration smoke command is:

```text
godot --headless --path . --script res://tests/smoke_stormwood_deepwood_circuit_wiring.gd
```

## Evidence limits

The wiring smoke uses a deliberately scripted `won=true` outcome at the production encounter hub's post-battle callback. It proves callback-to-ledger-to-quest wiring and idempotence; it is not a played battle. The existing realm-chapter tests cover pending-client refusal to advance world facts, but this work did not run a full two-peer Circuit session. It does not establish combat feel, route pacing, dialogue presentation quality, or multiplayer end-to-end play.
