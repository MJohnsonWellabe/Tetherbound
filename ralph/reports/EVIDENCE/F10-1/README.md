# F10#1 Persistent receipts for each Stormwood chain: PASS

Lane coop-chapters, branch tb/ev-coop-chapters @ c6e041b00. Run Sun 11 Oct 2026, 1:29–1:40 PM CT, Godot 4.7-stable headless.
Command: `GODOT_BIN=<godot> tools/net/run_two_peer_proof.sh <scratch>/stormwood_f10_side_chain_receipts.json` → exit 0, 0 FAIL (`PROOF.md`).

Two real processes play all six side chains through their production prompts and NPCs. The chains are Dark Arches, Pim's Parcels, What the Crown Remembers, Glass for Bryn, Raise a Road, and Deepwood Circuit (including Rook's Thunder Break TM).
- Each completion flag reaches both peers.
- Both peers `save_reload_here`; every completion and each character's reward holds in memory and in the saved world/character files.
- A second visit to each completing NPC or prompt grants nothing again.

Disclosed, beyond the scenario's own fixtures (named host save; debug travel to each NPC; main-route facts as flags; materials granted; Free Build arches; three circuit-trainer defeat facts):
- Scenario edits on this branch (coordinator-approved / PROOF RULES v2):
  - 617f53293: RD-17 portal migration as in bc150ca5, with the guest crossing first, plus the `_tap` process_frame flush.
  - a9081dfca: stale literal, Rook's circuit return is now 3 lines (TM line).
  - c6e041b00: stale literal, Rook's repeat-visit thanks is 2 lines.
  - No expectation or assertion changed.
- Scratch copy (`scenario_as_run.json`), wall-clock only:
  - every step's step-level `budget_frames` is max(4×, 12000) (the coordinator's wall deadline);
  - `build_allowance_s` is 600;
  - `budget_s` is 4×.
- Earlier failed runs on this branch: 1 at setup (pre-migration), and 2 at the Rook press counts fixed above.
