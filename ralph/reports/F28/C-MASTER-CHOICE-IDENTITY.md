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

## Existing producer expectation

`209e3c33a3042b5e2d9d93eabb4c8a6176bcf7c8` updates only the original
`tools/net/f48_prepare_profile.py` Master button expectation to the approved
numbered/species/nickname label. It still derives the challenger from each
original saved card, requires the existing single level-9 Terrapup setup and
uses ordinary `f48_button` input. The actual input controls, fixture disclosure,
wait/fight budgets and outcome guards are unchanged. Cross-lane NOTICE:
`6065672171`, before the edit.

The existing `tools/net/f48_produce_actual.py --prepare-only --producer loop`
completed once, without an engine/native run, in the fresh preserved directory
`D:/tetherbound/.tmp/c-master-choice-prepared-763-r1`. Its generated
`producer-profile/profile.json` SHA256 is
`359ad1d8ceeb7c51134cb07443e46df983f90606e75e810983179d71e63bfdcb`;
`source.json` records that digest and the input profile digest. It is explicitly
`acceptance_credit=false`, `ready_ci_bundle=false`, `native_run=false`.

Original reviewer `01a1165d-703f-7073-809d-343d2e86961e` gave SOURCE +
PREPARATION APPROVE for exact `209e3c33a3042b5e2d9d93eabb4c8a6176bcf7c8`.
Verdict: `D:/tetherbound/.tmp/c-f28-2-209-profile-original-verdict.txt`.
The 16-test/442-assertion UI evidence above remains applicable: neither its
production source nor its existing test file changed in this producer update.

**This does not close F28#2.** Its real five-Master duel/loss/retry/chest routes
and required native blind proof remain open. This packet creates no accepted
campaign boundary and promotes no failed save. Native GPU remains ROOT-scheduled
D/E only. The earlier whole F28#1 approvals and actor-vitals flags are unchanged.

## Owned-UID input and retained opening failure

`bf8b701f4a8a7af3c71dee4ab47915115f917f8f` replaces the producer's mutable
level-label lookup with the existing `f48_button` action's exact owned UID.
The chooser binds its ordinary `_duel(uid)` callback and marks only its actual
challenger buttons. `4f655201ef66f9d2d599d64b002adaeda84faa1a` additionally
requires the original mounted Master site, service and current chooser to agree.
Original physical input, conscious ownership, single-button census, deadlines,
duel/retry/chest/save/ACK guards and disclosed fixtures remain. No new harness
or shipping flag. Original SOURCE + COMMAND + PREPARATION APPROVE is retained
in `D:/tetherbound/.tmp/c-f28-2-uid-service-original-verdict.txt`.

The original selected chooser case passed on exact `4f655201ef` in
[run 37827842756](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/37827842756),
job `113485178303`, artifact `11572696095`: **1 test / 36 assertions / 0 failures,
exit 0**. Actual job checkout and argv were verified; the artifact itself contains
no checkout receipt. ZIP `D:/tetherbound/.tmp/c-f28-2-uid-37827842756.zip` SHA256
`20651dbabbb2efad82a5fe0e32af8ea16bf27e15ccb0207872be637c901b8a94`.
Original `kitchen_review` gave BOUNDED ARTIFACT APPROVE in
`D:/tetherbound/.tmp/c-f28-2-uid-affected-original-verdict.txt`. The earlier passing
16-test batch was not repeated.

`b25cead828a52e0d5513b608b47a4443bf7a90df` exposes the existing process-local
seed pin through a strictly validated `earned_chain_runner --world-seed` argument
before fresh Title input. Original review approved this bounded adapter and
original `--segment=opening_team` command. It changes no encounter or save rules.
The director used effective seed 15; the separately rolled saved seed is expected
by `Game.reset_for_new_game`'s explicit environment-override contract.

[Run 37824120305](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/37824120305),
job `113472399026`, artifact `11571236871`, exact source `b25cead828`, is retained
as **FAIL**: opening, road gate and village passed, but ordinary team training
lost its fourth fight after the unchanged three-loss allowance. Final fight
lost at frame 1786, without timeout or script error; potions were exhausted.
Receipt: `tree/ralph/reports/F28/earned-master-start-15/receipt.json` inside ZIP
`D:/tetherbound/.tmp/c-f28-2-earned-37824120305.zip`, SHA256
`df126d9cf1c3f5983b34e3a999d77d6b712fb785d14d02b9078778e171c4d7e2`.
Seed-16 run `37824125844` was cancelled when the one-hosted-run-per-lane cap
was announced; its partial ZIP remains, with no passing receipt or boundary.
Neither save is accepted or promoted. The retained solo five-card travel
fixtures also supply no canonical paired earned Master admission.

F28#2 is **parked, not closed**, pending an admitted paired five-card source
and the original all-five loss/retry/chest routes plus native blind proof.
No unchanged combat retry, allowance increase or actor-vitals flag change follows.
