# F28#2 — Master challenger identity, bounded evidence

Production source: `0f07a3f0c6fb55465027b68a981070ed82cedf8d` on `tb/codex-c`.

The ordinary Master chooser previously rendered a saved empty nickname as a
blank companion name. It now displays the numbered party slot and authored
species name, with the nickname alongside the species when present. Duplicate
unnamed species retain distinct visible slots. Zero-HP companions are disabled
under the existing conscious-challenger admission rule. Selection still submits
the original owned UID; no transaction, reward, durable schema, or flag changed.

The existing `DetachedDuelChooser` records the ordinary rebuild buttons from
the same canonical five saved companions used by the existing
`test_master_selection_deploys_the_chosen_owned_companion_and_fences_context`.
All original deployment, identity and rejoin checks remain. The added assertions
cover empty nicknames, duplicate species, nickname plus species, unavailable
companions and an unchanged saved projection. The detached fixture proves no
native layout/focus, combat result, network delivery, disk settlement or ACK.

Original reviewer `01a1165d-703f-7073-809d-343d2e86961e` gave SOURCE APPROVE
for the exact production source, then AFFECTED ARTIFACT APPROVE for:

- [Run 37817228957](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/37817228957),
  job `113448850104`, artifact `11567612388`.
- Verified checkout `0f07a3f0c6fb55465027b68a981070ed82cedf8d`;
  `tests/run_tests.gd -- --only=test_f28_training_boundaries.gd`, headless.
- **16 existing tests, 442 assertions, 0 failures; exact exit_code 0.**
- ZIP SHA256 `20ff628f91d207cf9add251a66b3507ba77a19032e755b071515668df4510618`.
- Preserved ZIP: `D:/tetherbound/.tmp/c-f28-2-37817228957.zip`.
- Original source verdict:
  `D:/tetherbound/.tmp/c-f28-2-revised-source-original-verdict.txt`.
- Original artifact verdict:
  `D:/tetherbound/.tmp/c-f28-2-0f07-affected-original-verdict.txt`.

The initial new fixture/test structure at `64849ba9d41e6a35e8a90b25e4ffdba6ec0d3c72`
received REQUEST_CHANGES for its test-scope expansion. That structure was removed
and folded into the original fixture and test. Its superseded passing artifact
is preserved: run `37816902866`, artifact `11566934441`, 17 tests/442 assertions,
ZIP SHA256 `39797f575a2cfa550640f2a3c7efdf5908bf3491795c5c7d38abbf130bab776d`.
No rerun of that passing source is requested or counted.

**This does not close F28#2.** Its real five-Master duel/loss/retry/chest routes
and required native blind proof remain open. This packet creates no accepted
campaign boundary and promotes no failed save. Native GPU remains ROOT-scheduled
D/E only. The earlier whole F28#1 approvals and actor-vitals flags are unchanged.
