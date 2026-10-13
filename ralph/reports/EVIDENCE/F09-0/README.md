# F09#0 earned six-region traversal: NOT PROVEN (stopped at the wind-down cutoff)

**Command:** `tests/smoke_stormwood_continuous.gd -- --through-aftermath --witness-dir=user://swrun_f09 --checkpoint-dir=user://swcp_f09`, Godot 4.7 headless under `unshare -rn`. It starts from the smoke's own disclosed fixture router (an in-memory completed-Cloudreach party and entitlement). routes-east confirmed that no earned Stormwood checkpoint is committed.

**Disclosed:**
- Runs 2–3 use a scratch copy that scales only the three wall-clock watchdogs 3x (`scaled_watchdogs.diff`). Every step's frame budget and every assertion is unchanged.

**Runs (times from `date`, CDT):**
- **Run 1:** `f4829ae75f`, 2:30–3:00 PM, unscaled. FAIL on the 30 min prefix wall-clock watchdog while walking to the Hollows station (215 m left, can_walk true). Reached:
  - Ashfoot, Hesk, Tamsin, and a Break witnessed while sheltered;
  - the first charged Stormglass, the six-glass pair-A relight and travel, and a route pickup;
  - Maren won through controller input and the Verge rod disabled.
- **Run 2:** `f4829ae75f`, 3:03–4:30 PM, scaled. FAIL on the 90 min prefix watchdog, still walking: Lantern Pools to a glowmoss stance, 105 m left.
  - Added: Dace defeated, lower_rods_disabled, the Lantern Pools camp and the charged-window wait.
- **Run 3:** `7f68efec8b` (tb/ev-coordinator `1eef1b18bc` with the mastery-drain fixes, plus F17 flags OFF), scaled, 4:31 PM to the 5:50 PM wind-down stop. Added: the Rodline Post road and pair B relit entirely with harvested Stormglass. Still in the prefix; the Act-II Stormglass Arch recipe was not reached.

**Every gameplay step that ran passed:**
- 0 trainer deaths; all live fights won through controller input; no walker stuck.
- No run reached the Crown, Deepwood, Marrow or the aftermath, so the six regions are not all shown.

**Blocker: frame rate decays over the run.**
- Walk fps on identical early walks: run 3 110–164 against run 2 82–131 (the mastery-drain fixes help).
- Both decay: about 28 fps by b_pools, 11 on the Rodline road, 5.7 at the b_rodline relight (run 3). Run 2 was about 12 at Lantern Pools.
- It is a cost that accumulates, consistent with routes-east's retained combat_mastery backlog report (systems owns it). It was not profiled, per the wind-down.

**Open:**
- Profile the per-frame cost late in the run.
- Rerun on a base with systems' drain-spreading fix (7910ca114) and camp soft-lock fix (ba0ddc7e3).
- Then `--verify-reload`.
