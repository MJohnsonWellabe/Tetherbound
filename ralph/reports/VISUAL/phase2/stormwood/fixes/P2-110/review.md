# P2-110 exploration roster cache candidate

The exploration HUD caches party rows by selection, roster revision, deployment
and progression-feed revision. Creature damage changes HP and fainted state
without changing those inputs. A headless probe using the production Party,
CreatureInstance and HUD reproduced a full-health, available row after the
underlying creature reached zero HP and fainted. Both reads retained party
revision 1 and the strip received only its original update.

`hud.json` now has a default-off `party_vitals_refresh_candidate` flag. When
enabled, the HUD also compares HP fraction, fainted and resting values for all
five possible members. A vitals-only change updates rows without reopening
the roster or firing the selection-cycle effect. This changes no combat,
recovery, save, ownership or party-selection state. TEAM 5/5 still counts owned
creatures; it is not a count of available fighters.

Before the fix, two of three new regression tests failed. After the fix,
`test_hud_party_vitals.gd` and `test_hud_widgets.gd` passed: 42 tests,
261 assertions, zero failures. Coverage includes benched damage, fainting,
healing, bed assignment, unchanged-state caching, no extra reveal, and the
disabled path. Independent read-only reviewer `stormwood_dialogue_review`
found no actionable defects.

The original Hollows loss sightings still require native replay and blind
before/after review. Duplicate out-of-fight messages and result hierarchy
remain with Tidewake's shared P2-103 pass. This candidate addresses the stale
green bars only; P2-110 remains open and the flag remains off.
