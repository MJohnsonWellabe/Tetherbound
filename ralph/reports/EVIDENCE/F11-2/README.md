# F11#2 Through disconnect/reload without duplicated grants: PASS

Lane coop-chapters, branch tb/ev-coop-chapters @ cfb316380 (game code unchanged from tb/ev-coordinator). Godot 4.7-stable headless, two real processes, each exit 0, 0 FAIL.
- `drop_at_ack/` (f11_stormheart_drop_at_ack, run Sun 11 Oct ~2:40 PM CT):
  - The guest says Yes, and its link is closed in the physics step that accepted it. The receipt is on its saved character, and the host holds no world receipt yet.
  - The guest rejoins as the same character. The host settles that one claim from the resent claim and the saved receipt; the guest has exactly one Stormheart.
  - Replays are refused before and after both peers reload, and the saved files agree.
- `refuse_drop_at_ack/` (f11_stormheart_refuse_drop_at_ack, run 3:04–3:15 PM CT): the mirror case. The guest's No is cut at its `declined` signal, and the host settles the refusal after the rejoin. The guest never holds a Stormheart, and replays are refused before and after reload.

Disclosed (PROOF RULES v2; no assertion changed):
- Fixtures: the named host save, the initial Crossing Hall portal fixture, and the Dynamo contributors fixture.
- 617f53293: RD-17 portal migration (bc150ca5 pattern) with the guest crossing first, plus the `_tap` process_frame flush.
- cfb316380: peers launch at the title, as the other Stormwood proofs do. Launching into the world scene built the Meadows before hello and missed the 180 s hello budget.
- Scratch copies, wall-clock only: every step's step-level `budget_frames` is max(4×, 12000), `build_allowance_s` is 600 and `budget_s` is 4×.
- Earlier refuse runs:
  - One timed out at #27, the host settling the refusal. It passed in the next two runs at 203 frames.
  - One was invalidated: an accidental duplicate launch into the same output folder deleted the live peers' user data, so the host save failed at #38.
  - Diagnostic prints from those runs were reverted.
