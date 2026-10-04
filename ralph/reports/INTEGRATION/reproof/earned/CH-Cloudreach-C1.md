# CH-Cloudreach#C1: From M4 save: six regions, Fly/remount, Veyra, earned key to Stormwood (re-proof)

**Verdict: ERROR, blocked on fixture regeneration.** The named earned start is a save-version-27 fixture. RD-35 (owner, 2026-09-29) refuses v27 and older saves by design: `scripts/save/save_game.gd` `RESET_MAX_VERSION := 27`. Per the coordinator (17:49Z), this is not counted as a product FAIL. No v27-to-v28 conversion was attempted, since that would breach RD-35. A fresh v28 earned chain (the F49 run, once F18 enables the portal runtime) has to regenerate the checkpoint.

- **Commit:** 826d273c3dbdcb1002034812041b1dfb59d84120
- **Command:**
  ```
  godot --headless --path . --script tests/smoke_cloudreach_continuous.gd -- --from-save=res://tests/fixtures/earned_saves/c1_arrival --leg=opening
  ```
- **Wall:** 13 s, exit 1. Log: `logs/c1_v27_probe.log.txt`.
- **Output:** `CLOUDREACH CONTINUOUS earned slot is not a Cloudreach save: {... "code": "incompatible_old_version" ...}`, then `CLOUDREACH CONTINUOUS FAIL stage=boot from_save=res://tests/fixtures/earned_saves/c1_arrival`.
- `smoke_cloudreach_continuous.gd` exists. The action says to share runs with F06 where they are identical. The foot (F06#1), Fly (F06#2), loaner (F06#3) and Veyra (F08#0) earned runs all stopped at this same refusal. `--leg=opening` was used only as a probe, because the load refusal comes before any leg logic.
- **Bad-landing leg:** not reached, for the same reason.
