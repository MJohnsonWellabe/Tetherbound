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

## B2: quarry leg to the fourth rootstone stalls west of the foundation

- Segment: `warrens`, loaded from the `bridge` save. Helper:
  `tests/helpers/meadows_earned_warrens_segment.gd` `_travel()`. Three rootstones were gathered
  (0→6); the direct stick leg (406,1800) → (401,1809) then timed out. No
  `walk_confined_recovery` fired: the player kept moving, but drifted west into the pocket
  south of the retained quarry foundation (397,1805, yaw 30) and the conduit pylon (404,1804).
- Seed 4. Log line (attempt 1, 19:00 UTC, 297 s): `EARNED WARRENS FAIL — Ordinary quarry/Warrens movement did not reach (401.0, -0.329741, 1809.0); player=(397.9701, -0.499921, 1801.116)`.
  Attempt 2 (19:06 UTC) ended the same way at player (395.62, -0.50, 1798.99).
- Last good save: `/tmp/claude-0/earned_chain/seed4/bridge/save/`. Failed attempts:
  `/tmp/claude-0/earned_chain/seed4_warrens_attempt{1,2}/`.
- Honest alternative (one try, own file): `tools/earned_saves/warrens_route.gd` walks two extra
  ordinary waypoints east of the pylon, (408.5,1803.5) and (406.5,1809.5), with the helper's
  own controller walk before its leg to the node. Disclosed as receipt `quarry_east_detour`.
  The direct route still stalls on main, which is a Meadows navigation/helper defect.
- Attempt 3 (with the east detour) reached the fourth stone (6→8). It then stalled on the helper's
  leg from its own clearance points to the fifth stone (393,1802), at player (396.60, -0.15, 1809.32).
  Attempt 4 walked the foundation's west end instead, but the cut face closes it: `walk_confined_recovery`
  fired, and the run failed short of (389.5,1807.5) at player (391.05, 0.67, 1809.61).
  Attempt 5 replaces the helper's two routing-only clearance waypoints, (394.1,1809) and
  (392.85,1806.82), with an ordinary walk back round the pylon's east side to the ruin's open
  south side, (406.5,1809.5) → (408.5,1803.5) → (403,1797.5) → (396,1797.5). The helper then
  takes its own leg to the node. Disclosed as receipt `quarry_south_detour`.
- Attempt 5 (19:38 UTC) reached (396,1797.5) south of the ruin by ordinary walking. The helper's
  own leg to the fifth stone then stalled in the same pocket:
  `EARNED WARRENS FAIL — Ordinary quarry/Warrens movement did not reach (393.0, -0.497714, 1802.0); player=(397.4855, -0.499157, 1801.353)`.
  Across attempts, the player gets no closer than about 4 m to (393,1802) from the north, west
  or south. Radius 2.2 is the harvest prompt distance.
- Status: **blocking.** Harvest node order 16 (rootstone at 393,1802 in
  `data/config/bands/band2_stone_and_root/harvest.json`) looks physically enclosed by the
  retained quarry foundation (`data/config/old_quarry.json`, 397,1805, yaw 30) and the cut face
  on main 10b635d38. This is a Meadows content/collision defect, or the node should move. The
  helper cannot collect all seven stops. Nothing was injected; the chain stops here.
  Receipt at stop: rootstone 8 carried (4 of 7 stops); flags gained `harvest_node:order:12..15`;
  party ripplet 9, bramblebun 8, mudsnout 8, mudsnout 7, bramblebun 6.
  Last good save: `/tmp/claude-0/earned_chain/seed4/bridge/save/`. Logs are in
  `/tmp/claude-0/earned_chain/seed4_warrens_attempt{1..4}/` and `seed4/warrens/`.
- **Coordinator ruling:** the route may skip order 16 only if nothing later needs the
  stone. No later earned helper (relay/hall/warden) and no gate cost uses rootstone, so
  `tools/earned_saves/warrens_route.gd` skips it with receipt `unreachable_node_skipped`
  (no replacement nodes needed) and keeps the east detour for the fourth stone. The south
  approach was dropped. **B2 remains an open Meadows defect:** order 16 cannot be reached by
  walking.

## B3: undertrail approach stalls against the Warrens mound

- Segment `warrens`, attempt 6 (seed 4, from `/tmp/claude-0/earned_chain/seed4/bridge/save/`).
  The quarry was completed with order 16 skipped (rootstone 12). On the helper's
  `warren_undertrail` leg (-420,2470) → (-380,2540), the player stalled at about (-406,2488),
  which is on the flank of `rises.peaks[5]` (centre -380,2488, r 30, the Warrens mound).
  Log: `EARNED WARRENS FAIL — Ordinary quarry/Warrens movement did not reach (-380.0, -3.984001, 2540.0); player=(-406.0465, -6.410811, 2488.072)`
  (one `walk_confined_recovery` first). Attempt log: `/tmp/claude-0/earned_chain/seed4_warrens_attempt6/`.
- Alternative 1 (own file, `warrens_route.gd`): walk ordinary ground west of the mound,
  (-432,2492) → (-418,2528), before the helper's leg. Disclosed as receipt `undertrail_mound_detour`.
- Alternative 1 **worked** (attempt 7, 19:55 UTC): Warrens entered, guardian won (20 hits), exited at (-353.1, 4.56, 2606.1). B3 remains an open Meadows route defect: the authored undertrail leg crosses the mound.

## B4: Relay prompt press activates a different provider

- Segment `relay`, attempt 1 (20:05 UTC, seed 4, from `/tmp/claude-0/earned_chain/seed4/warrens/save/`).
  After an ordinary wild win (14 hits), the helper reached the Relay site at (350.1, 4.36, 3759.8).
  At the captain's actionable prompt, its physical Interact did not activate the offered provider.
  The helper's `_activated_id` did not match, and no flag was gained.
  Log: `EARNED RELAY FAIL — Physical Interact activated a different provider than the exact offered target`.
  Wall time 541 s. Attempt log: `/tmp/claude-0/earned_chain/seed4_relay_attempt1/`.
- Alternative 1 (own file, `tools/earned_saves/relay_route.gd`): keep the exact-provider check,
  but when a press activated nothing, or activated something with no modal or fight side
  effect, re-approach and press again (up to 3). Each retry is recorded as a
  `prompt_press_retry` receipt naming what was activated.
- Attempt 2 (alternative 1): the first press at `Trainers/Captain Vance/Interactable` activated
  `<nothing>` through the arbiter signal, with no immediate side effect. During the re-approach a
  modal opened ("target or ordinary input disappeared"), so the press had reached the captain
  with a delay. Alternative 2 (attempt 3) waits up to 240 frames after an unsignalled press for
  the real dialogue panel. `_talk()` still requires the exact challenge conversation.
  Disclosed as `prompt_press_delayed_dialogue`.
- Alternative 2 **worked** (attempt 3): captain beaten (3 rounds, 45 hits), Sela freed, relay disabled (18 conduits to 0), Mill crossed. B4 remains an open Meadows/arbiter defect: the captain's prompt press does not emit the arbiter's `activated` signal.
