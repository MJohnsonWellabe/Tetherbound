# F11#1 Eligible peers accept/refuse independently at space and capacity: PASS

Lane coop-chapters, branch tb/ev-coop-chapters. Godot 4.7-stable headless, two real processes. Each folder holds its PROOF.md (exit 0, 0 FAIL).
- `mirror_host_refuses_guest_accepts/`: free slots on both. The host says No and keeps nothing; the guest says Yes and keeps one Stormheart. Each answer is its own world and character receipt, a second press grants nothing, and the saves agree. Run 12:20 PM CT at 00d4a639.
- `capacity_guest_full_releases_belt/`: the guest is at five and says Yes. The Team tab ceremony lets bramblebun go, and the Stormheart takes that slot (still five). The host with space keeps its own. Run 2:09 PM CT at 6caa680b7.
- `capacity_host_full_lets_stormheart_go/`: the host is at five and lets the Stormheart go. It keeps all five, and that is recorded as its refusal. The guest with space accepts its own. Run 2:25 PM CT at 6caa680b7.

Disclosed (all coordinator-approved / PROOF RULES v2; no assertion changed):
- Fixtures: the named host save, the initial Crossing Hall portal fixture, the Dynamo contributors fixture, and the five belt members via `party_grant`.
- 617f53293:
  - the real portal crossing runs guest first;
  - `proof_steps._tap` flushes each edge with `process_frame`, as `press_inject.tap()` does. Without it, one tap read as two on this slow host: the host's offer skipped its Yes/No line, and a stray press hit the Waterward view.
- 6caa680b7: the five-belt `party_grant` runs before host/join. Granted after the join, the host's admitted roster stayed empty, so the claim's `party_uids` mismatched and the release quote refused (`stormwood_roster_changed`, found by temporary prints, reverted).
- Scratch copies, wall-clock only: every step's step-level `budget_frames` is max(4×, 12000), `build_allowance_s` is 600 and `budget_s` is 4×. The mirror run also carried `args.budget_frames=18000` on its two setup portal crossings; about 800 frames were used.

OPEN FINDING (for routing): when the host crosses the Crossing Hall Stormwood portal first and the guest follows, the guest's portal completion never correlates (2 runs).
- Run 1: the guest built Stormwood, but `portal_action_result` never arrived.
- Run 2: the host built a 96 s Meadows shell for the guest and the guest never crossed.
- No CI smoke covers a guest's portal crossing after the host leaves (`session_host_first_realm` uses the retired crossing).
`diagnostic_double_press/` holds the `_tap` diagnosis.
