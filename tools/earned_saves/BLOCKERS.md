# Earned C1 chain blockers

Chain: `tools/earned_saves/run_chain.sh 4 /tmp/claude-0/earned_chain/seed4` on
`ralph/cloudreach-earned-c1-save` (base origin/main 10b635d38), `TB_WORLD_SEED=4`
(a 14-body practice-meadow class seed from `tools/earned_saves/seed_scan.gd`).

## B1: South Bridge gate does not own the interact offer after the guardian win

- Segment: `bridge` (loaded from the `camp_tournament` save). Helper:
  `tests/helpers/meadows_earned_bridge_segment.gd`, after the guardian victory, in the
  `if not bridge.is_open` branch: walk back to `near_point(gate_offset + 2.5)` and
  `_press_gate(prompt)`.
- Step: `_press_gate` waits 30 process frames for the arbiter's winning provider to be the
  bridge's `Interactable`; it is not. The log shows the defeated guardian still competing:
  `[village] 'south_bridge_grunt' offered a battle that could not start`.
- Log excerpt (attempt 1, 18:07–18:18 UTC):

      EARNED BRIDGE — { "trainer": "south_bridge_grunt", "depth": -11.55908203125, "beat": "guardian_admitted" }
      [village] 'south_bridge_grunt' offered a battle that could not start
      EARNED BRIDGE FAIL — The exact South Bridge gate does not own the actionable interact offer

- Receipt at failure: flags gained `defeated_south_bridge_grunt`, `south_bridge_open`,
  `alpha_pin_intro_seen`. The bridge did open (the durable flag is set), so the guardian fight
  and the key spend were earned. The helper's arbiter check still fails, and the segment did
  not save. Party: ripplet L9, bramblebun L8 (7 HP), mudsnout L8, mudsnout L6/7, bramblebun L7.
  Player (7.997, -2.899, 1319.06). Wall time 699 s.
- Last good save: `/tmp/claude-0/earned_chain/seed4/camp_tournament/save/` (slot 1).
  Failed attempt kept at `/tmp/claude-0/earned_chain/seed4_bridge_attempt1/`.
- Classification: the gate's interaction offer races the defeated guardian's leftover
  challenge provider (Meadows NPC/arbiter, or the bridge helper's 30-frame window). Not
  patched here: both are shared or Meadows files.
- Attempt 2 (confirming rerun from the same save, 18:19–18:31 UTC) reproduced it exactly:

      EARNED BRIDGE — { "trainer": "south_bridge_grunt", "depth": -11.5479736328125, "beat": "guardian_admitted" }
      [village] 'south_bridge_grunt' offered a battle that could not start
      EARNED BRIDGE FAIL — The exact South Bridge gate does not own the actionable interact offer

  It gained the same three flags. `south_bridge_key` count ended at 0 (spent), and wall time
  was 698.6 s, matching attempt 1. Player (7.903, -2.899, 1318.95). Party: ripplet 9,
  bramblebun 8, mudsnout 8, mudsnout 7, bramblebun 6. Log:
  `/tmp/claude-0/earned_chain/seed4/bridge/log.txt`.
- Status: **blocking, reproducible 2/2.** RESULT.md run 4 passed this step on an older base, so
  this looks like a regression on main in the post-victory offer or auto-open ordering. Needs
  the Meadows owner to fix one of two things: the leftover guardian offer, or the helper's
  post-victory gate press, which should accept an already-opened gate. No work-around with
  injection was attempted.
- **Resolution (coordinator ruling, attempt 3, 18:47 UTC):** `tools/earned_saves/bridge_crossing.gd`
  reuses the helper read-only and replaces only the post-victory gate press. After the win,
  ordinary play had already opened the bridge (`south_bridge_open`, key 0; the arbiter winner at
  that moment was `<null>`). So the Meadows helper's "gate must own the interact prompt"
  assertion was **bypassed** and disclosed in the receipt (`gate_prompt_assertion_bypassed`).
  The helper then walked the opened bridge to the far bank with stick input
  (`south_bridge_crossed`, depth -11.57 → 9.43, 2 wins, 40 hits). **The stale
  `'south_bridge_grunt' offered a battle that could not start` offer remains an open Meadows
  defect.**
