# F15#3 full attempt — DRY RUN, does not count (archived, branch discarded)

This archives the discarded scratch branch `tb/scratch-tidewake-b-f15-3-full` (head `d9ae0499995274571a8f88feb57368cbdedef136`). Under the one-branch rule of 2026-09-27, the branch was removed rather than folded. Its two commits are kept here as `f15_3_full_dryrun.patch` (`git format-patch --binary`; apply with `git am`).

**Status: DRY RUN — does not count.** The start state was a declared fixture save. The run failed at the Meadows crossing: `realm 'meadows' did not become ready within 120.0 seconds`, while machine load was about 18 on 4 cores. Grandpa's acknowledgement was never reached.

**Why it is not folded:** it includes unreviewed additive changes to shared net-proof tooling:
- `tools/net/proof_steps.gd`: `load_save {copy_only}`, `title_continue {any_realm, expect_character}`, `grandpa_homecoming {walk}` and `veilfall_press {walk}`
- `tools/net/peer_runner.gd`: `production_join {pick_saved}`

Those should land only with an F15#3 attempt that starts from an earned Tidewake-complete save.

**Useful findings recorded:**
- **Works:** the host loads a Tidewake save through the production title Continue. The guest restores its character through the returning route. The guest releases a companion in-run through the real Creatures-tab menu (PASS through step 16).
- **Open:** after the `enter_realm` crossing to the Meadows, the host's stick walk toward Grandpa moved the body 0 m, 31.5 m away from him. Plain `move_to` legs also moved less than 1 m. This is not diagnosed: it could be a harness problem or a Meadows arrival/readiness problem.

**Resume later:** once an earned Tidewake-complete checkpoint exists (see the four-biome checkpoint boundaries), apply the patch and repoint its start at that checkpoint.
