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

F48 run37073202538 retained the native paid-Altar failure: owner disk versus complete immutable after carrier, accepted disk journal, and exact paid building differ. Detached JSON evidence rounded away numeric differences. A native Godot4.7 probe independently establishes that default JSON serialization changes doubles, and even full-precision serialization can reparse one ULP away for `100.0 - (1.0 / 60.0) * 0.2`. New read-only diagnostics preserve first differing paths and primitive Variant hex; the original strict oracle is unchanged. This is diagnosis, not a save fix or acceptance.

Four-peer run37073205567 admitted four original identities and retained exact starts, then stopped before combat because no original companion was deployed. Its preparation route now sends the ordinary recall input only when needed, verifies unchanged original party UIDs and an owned deployed UID, then runs the same approach and boss oracle. Both route validators register that bounded action. Independent review found the initially omitted registrations; both were corrected before dispatch. Focused native saved-edge/support checks:11 tests/33 assertions, no failures or engine errors. Python integrity checks:13 passed. No native replay pass claimed.

Salt Crown dependency `1c5baa6bda` integrated as `b25623fb45`: authored shrine pad moved from `[0,-7]` to `[3,-9]` while arrival offset and dry/support limits remain unchanged. Independent source review and the production-resolver analytic regression pass; actual baked-shell support and physical arrival remain pending F20's retained live replay.

## Exact numeric save persistence

Native run37075508544 on `c0c5843728` confirms the paid-Altar failure is real serialization loss. The first differing fields are `party/0/distance_m_together`, `intent/request/position/1`, and the placed building's `position/1`. Original diagnostic hashes, run/artifact identity and exact primitive bytes are retained in `f48-native-save-mismatch.json`. Four-peer run37075511053 is a separate native replay; no pass claimed here.

The candidate now stores character, world and mirrored slot documents through one lossless JSON codec. Finite float64 leaves use explicit eight-byte little-endian hex; large integers use canonical signed64 decimal strings. A versioned outer envelope keeps gameplay schema28 and makes older readers refuse the file. Existing plain JSON still reads unchanged, including reserved-looking gameplay keys. The codec escapes reserved-key dictionaries and refuses malformed tags, nonfinite numbers, unsupported values, unknown versions and excessive nesting. Interned Godot dictionary keys retain their original textual names. No immutable transaction carrier is rounded or normalized.

Atomic recovery validates the codec before preferring canonical over `.previous`. The existing slot ownership lookup also uses the codec-aware recoverable reader; otherwise an encoded slot could appear ownerless. Save-specific proof loaders, Python fixture tools and inspection tests now decode this envelope. Configuration/receipt readers and deliberately old-format negative fixtures remain plain JSON. Byte-copy captures and their original hashes are unchanged.

Scoped native evidence:

- `save-codec-writers.log.gz`:138 tests/1230 assertions pass, including actual pending Altar journal, owner BOOL write, complete exact reload, before/already-paid recovery and ACK, failed grouped-write rollback, malformed-envelope backup recovery, and refusal to mint over an encoded owned slot. Earlier candidate failed because runtime loadout mirrors contain StringName dictionary keys; the codec now handles textual keys explicitly. Original failed logs remain local.
- `save-codec-consumers.log.gz`:30 tests/666 assertions pass for authoritative split loading, map persistence, redesign old-save refusal and the shared native/Python wire fixture.
- `save-codec-legacy.log.gz`:34 tests/230 assertions pass for Alpha pins and legacy realm saves. No engine/script errors in these three passing logs; expected warnings exercise invalid/old-file refusal.
- Python codec3 checks and existing F48 integrity13 checks pass. `proof_peer_runner.gd --check-only` exits0. The shared fixture includes problematic gameplay floats, negative zero, a subnormal, int64 limits and reserved-key collision data.

These are scoped persistence proofs, not F48 gameplay or green-main acceptance. This shared save change still requires the full integration CI batch and real F48 producer/smoke/interruption runs.

Independent final source review approved the codec, ownership guard, textual interned keys, Python/native parity, audited readers and real-writer regressions. Its nonblocking malformed-huge-integer exception finding was corrected by checking bounds before float conversion, with a negative test. Both source producers successfully prepared fresh encoded fixtures without launching an engine; no native acceptance follows from preparation.

Native lossless-loop run37076878807 on `6405e9faca` passes the original exact paid-Altar oracle, original owner BOOL-save/accepted-ACK snapshot and exact input retention. It next fails the actual guest shared-Alpha catch: `alpha_resolution_write_pending`, then `finish_timeout`; no companion is granted. A dummy-renderer null-material error is also retained in the host log and remains unresolved. This run is not a clean-engine or complete F48 pass.

Four-peer run37075511053 passes original-owned deployment and authored-site approach for every peer, then finds no actual boss announcement. Source audit found the route sends `ui_accept` while the shipping dialogue panel consumes `interact` (different physical bindings). Both producer routes now require the actual named Warden conversation, send bounded ordinary interact inputs, observe its real completed signal and stop before any further combat input. Both route validators include this action. Independent source review approved; native parser exits0. Boss participant/reward/rejoin oracles remain unchanged; actual replay is required.
