# CARD:M2 as chained pieces (owner rule: no long runs; WORKFLOW §8.1 rule 9): 3 pass, Warrens blocked (tb/ev-fights)
US Central, Tue 13 Oct 2026. Runner: `tools/earned_saves/earned_chain_runner.gd --segment=<id> --handoff-from=<previous>`. No seed is set, there are no injections, and each piece loads the previous piece's save through the production title. Commit 030640909 (tb/ev-fights with origin/main and origin/tb/ev-routes 20af7bbad merged). Saves: `tests/fixtures/earned_saves/meadows_chain_ev_fights/<piece>/` (save, receipt, PROVENANCE).

The committed `meadows_01_opening_team` (ebe1b2c7) cannot be reused: the resume refuses a cross-commit handoff without a reviewed compatibility manifest. So opening_team was re-run on this commit.

| Piece | Result | Notes |
|---|---|---|
| opening_team | PASS (8:52–9:25) | fresh title → first catch → road gate → village → team. An earlier attempt failed "source identity changed" because I committed mid-run; nothing was committed during the passing run. |
| camp_tournament | PASS (9:26–9:48) | quarter, semi and final won. After each round the helper reads the beaten trainer's lines, then Halda's next offer wins. **Root cause of Routes' r10 failure:** r10 ran on ebe1b2c7, before the after-round read (the fix cites 73cffa4d). The open victory panel kept the arbiter disabled, so her prompt showed ''. Nothing further to fix. |
| bridge | PASS on the second run (10:08–10:26) | Run 1 FAILED, "Unexpected modal interrupted the South Bridge road": the grunt's battle could not start. The rendered-radius admission was refused (ring 4.49 m, capped by the bank's `combat_arena_bounds_for_fighters_at`, against the ally's 5.3 m reach), and the "could not start" path left a modal (`pieces_bridge_run1_fail.txt`). Run 2 logged one refusal, re-admitted, and won. **Intermittent; product owner: the South Bridge arena seat near the bank lip.** |
| warrens | FAIL (10:27–11:06) | Routes' staging fix works: the walk reaches the mouth, enters, and the guardian is admitted. **New blocker:** in the guardian fight every player action comes back refused with an empty verdict (`[encounter]  refused:  ()` x167). That is 0 hits in the 7200-frame budget against the L14 guardian (party L6–9), still fighting. The admission succeeded first time, so the arena changes on this branch are not involved. This is a host-authority (encounter link) regression on the solo Warrens guardian. Log: `pieces_warrens_fail_tail.txt`. |

Earlier continuous evidence (seed 15, 13 Oct, before the no-long-runs rule): `run1_warrens_tail.txt`, `run2_warrens_tail.txt` (staging point; since fixed by Routes).

**Verdict: CARD:M2 not met.** Pieces 1–3 pass with committed saves. Warrens is blocked by the empty-verdict refusals in the guardian fight. Relay, sigils (Field), Hald and the Cloudreach crossing pieces wait on it.
