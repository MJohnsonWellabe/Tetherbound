# F04#1 Captain Vance: recapture at routes-west `437d771b`

Captured Sun 11 Oct 2026, finished about 4:40 PM CT, by the captures lane. This lane captures; it does not judge.

- **Source:** detached worktree at tb/ev-meadows-fights `437d771b`, exactly as handed over (CAPTURE-READY). Its own `tools/capture_f04_strike_beats.gd` was used, `--policies=stand,stand,dodge,dodge`, once for the lead and once with `--live-member=relay_captain:4`. Low/Compatibility (llvmpipe), 1280x720, real time.
- **Witness results** (`witness_rows.log`):
  - Galecrest lead: **FAIL**, 0 of 4 dodges avoided. On the step-out strikes the ally moved only 0.2–2.3 m (the earlier run at `a8899257` moved 4–5 m), and the log shows "dodge: blocked" steering four times.
  - Tuskroot ace: PASS, 2 of 4 avoided.
- **Observed in frames 01–02:** Galecrest's storm_strike tell still draws as a ring around the attacker, not a disc on the deck at the target. The brief asked for the disc at the target, wider than the target's footprint.
- **Observed in frame 09:** Tuskroot's charge lane lies on the deck from its feet.
- **Not shown:** a leap miss after a step-out; none occurred in this run.
- **Harness artifact:** the HUD names the ally "Camera", because this commit predates my nickname fix (`8aebc60b`).
