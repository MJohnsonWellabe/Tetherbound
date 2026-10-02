# Main integration repairs

Baseline: `f48a0ba1ea54bf39149e37695804fdc976a1f9e7` (PR519).

## Authored catalogue reuse

`Teaching.allowed_saved_moves` reparsed all species and rebuilt the Water adapters for each creature during every admitted-character validation. It now reads the existing `CreatureSpecies.table()` through a lazy load, retaining the established preload-cycle boundary. Character level, breakthrough history, ancestry, compatible TMs and allowed moves are still evaluated on each call. No character state, receipt, admission result or validation failure is cached.

Native Godot 4.7 measurement, five owned creatures, ten calls per operation, same machine and fixture (`tools/probe_admitted_character_cost.gd`):

| Operation | Baseline mean ms | Candidate mean ms |
|---|---:|---:|
| Validate portable character | 74.011 | 16.574 |
| Refresh host-local character | 75.726 | 17.520 |
| Recover durable vitals | 75.157 | 17.076 |
| Recover durable portals | 79.520 | 17.567 |

This is a scoped CPU measurement, not a frame-time or multiplayer acceptance claim. Empty journals isolate the repeated admission cost; populated journal/world performance remains to be checked by the selected CI jobs.

Affected regression command:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . --script tests/run_tests.gd -- --only=test_breakthrough_saved_move_history.gd,test_actor_vitals_authority.gd,test_combat_mastery_delivery.gd,test_guest_groom_passive_sync.gd
```

Result: 24 tests, 2,810 assertions, zero failures. Covers every authored tier's JSON-restored eligibility, malformed prefixes, authority identity/refused writes/replay, mastery persistence, and guest grooming save/ACK ordering. No gate or assertion was removed or relaxed. Independent static review approved the bounded change with no actionable findings: no preload cycle, shared-catalogue writes or cached personal state; equivalent authored catalogue and Water merge behavior. The reviewer did not rerun tests. Exact-head full CI remains required before landing.

Balance: game 1 / tests-tools 1 (one performance probe).

## F48 original source restoration

The producer adapter restores six hash-pinned original saved documents from two retained native shared-boss runs. Four original character identities and four owned creature UIDs remain distinct; the existing two-peer producer currently consumes the first pair. Both compressed and original bytes are checked before any carrier is written. The measured layout is independently pinned. Existing disclosed fixture tools supply the initial mechanics setup; actual caught cards, paid Altar journal, Master recipe, cooked feast and boss rewards must still come from the native producer. No ready-input or gameplay acceptance is claimed.

`python -m unittest discover -s tests -p 'test_f48_*py'`: 13 checks passed, including source byte integrity, archive corruption, duplicate identity and traversal refusal, complete four-peer start enforcement, and existing readiness/overlay checks. The adapter passes Godot4.7 `--check-only`; a prepare-only run succeeded. Independent review verified every archived file against its retained original, checked the layout hash and approved the bounded adapter. Native source generation and all four original smokes/24 interruption cases remain open.

F18 dependency `98ff2a89cc` integrated as `52f5a077bf`: durable waystone touch, ready-world mounts, personal portal view, dry-biome context and consumed-permit receiver guard. Reused the independently reviewed lane evidence (28 tests/240 assertions and112 tests/1241 assertions, plus synthetic mount lifecycle); this does not close F18 earned or live multiplayer acceptance. F19 `8ab9637e10` was held after independent review found guest-first settlement refusal and a premature Stormwood delivery marker. Follow-up `d8b18de716` resolves both, independently approved with33 tests/310 assertions. Both are integrated as `275cd8a7a6` and `4d3bf864f4`; full F19 acceptance remains open.

The four-player adapter retains four original admitted inputs then invokes unchanged `_boss(steps,4)`, including participant reward, world isolation and reconnect oracles. Four-peer prepare-only succeeded, both Godot adapters passed `--check-only`, and13 Python integrity checks passed. Independent review approved this bounded extension; native execution and final ready-input packaging remain required.

Two-player actual-source production dispatched at exact `4d3bf864f4`: GitHub run37072464192. The Stormwood Nysa CI smoke at41dfee timed out at420s after two real wild victories (138s and122s); unchanged native smoke has its own900s watchdog. Diagnostic run37072533977 lets that existing watchdog resolve instead of cutting it off early. No native assertions or time budgets have been relaxed.

Nysa diagnostic37072533977 passed in316s with no intervening wilds and no engine errors. CI's external timeout is now960s, allowing the existing900s native watchdog plus startup/exit margin; the test and five-minute trainer combat cap are unchanged. Independent review approved the boundary alignment; the35-minute shard still requires final CI confirmation.

F48 first native run37072464192 reached the paid-Altar assertion then returned1. Its manifest retained native output names, but upload-artifact omitted hidden `.tmp` evidence. `dd422104fa` moves complete native output to a visible report directory and prints a bounded final log tail, preserving exit status (independent review approved). Loop retry37073202538 and four-peer retry37073205567 dispatched on that exact candidate; the earlier four-peer37072996680 was cancelled because it shared the faulty retention path. No failed run is treated as acceptance.

Epoch-only F19 follow-up `5088678059` independently reviewed and integrated: current host-derived settlement flags no longer invalidate immutable retained boss-event matching. The original receipt identity, event/world/character/action/intent/verdict validation are unchanged. Focused actual Session/event test passed1 test/4 assertions. Broader world-scoped receipt changes remain held for migration review and are not part of this baseline dependency.
