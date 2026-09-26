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

## B5: Hall route loses a road wild fight with a drained active creature

- Segment `hall`, attempt 1 (20:29 UTC, seed 4, from `/tmp/claude-0/earned_chain/seed4/relay/save/`).
  `captain_riverwatch` was beaten (3 rounds, 47 hits, `river_sigil` 1). The helper then walked
  on without care, and the next ordinary wild fight failed:
  `EARNED HALL FAIL — Real wild combat did not win with landed strikes inside its unchanged physics budget`.
  Party at stop: ripplet 12 (49 HP), bramblebun 11 (0 HP), mudsnout 11 (37), mudsnout 10 (100),
  bramblebun 10 (81). It carried 3 small potions and 12 revives. Wall time 333 s.
  Log: `/tmp/claude-0/earned_chain/seed4_hall_attempt1/`.
- Classification: a helper pacing gap. `_prepare()` runs only before each captain, not after a
  win.
- Alternative 1 (own file, `tools/earned_saves/hall_route.gd`): before each road leg, when the
  active creature is fainted or under 35% HP, run the helper's own `_prepare()` (real Satchel
  revive/potion and party-cycle input). Disclosed as `between_fight_care`. The file also carries
  B4's disclosed prompt-press handling for the Hall and gauntlet trainers.
- Attempt 2 (alternative 1) failed straight away, 145 s in and about 7 m from the start. `_prepare()`
  had put the ripplet (117 HP) up, but the live pilot's voluntary `party_cycle` switched to the
  22 HP bramblebun. That fainted and the fight ran out its budget, so benched members matter too.
  Alternative 2 (attempt 3): before each road leg, revive fainted members and give a small potion
  to anyone under 40% HP while stock lasts. Each dose goes through the team helper's real Satchel
  seam (`care_existing`), then `_prepare()`. Disclosed as `between_fight_care` with per-dose
  receipts.
- Attempt 3 (alternative 2, 20:39 UTC) got further. Bench care dosed bramblebun (22→72) and
  mudsnout (36→86), then two ordinary wild fights were won (15 and 10 hits). The next bench dose
  (bramblebun 18→68) was followed by the helper's `_prepare()`. Its real `party_cycle` input then
  stopped moving the active slot, three presses in a row (`before 3, after 3, wanted 0`):
  `EARNED HALL FAIL — Earned Satchel preparation failed: ["Party-cycle input did not select the available training creature"]`.
  Player (-152.26, -4.95, 4233.56). Wall time 181 s. Potions 0, revives 12, no flags gained.
  Log: `/tmp/claude-0/earned_chain/seed4/hall/log.txt`.
- Status: **blocking after the 3-attempt cap.** Last good save:
  `/tmp/claude-0/earned_chain/seed4/relay/save/`. The Hall helper leaves the active creature
  drained between fights, and small potions run out after about 3 doses. A production
  `party_cycle` refusal outside combat (cause not identified; possibly a nearby wild's
  engagement or ally state) then blocks the helper's own pilot selection. Suggested next honest
  step, not taken because of the cap: drop the `_prepare()` call after bench care and rely on the
  helper's own pre-captain `_prepare()`. Or rest at an earned camp before the Sigil loop.

### B5a: possible Meadows core input defect: `party_cycle` does not move the active slot outside combat

- Seen in `hall` attempt 3 (seed 4, from `/tmp/claude-0/earned_chain/seed4/relay/save/`). The
  helper chain `meadows_earned_team_segment.gd::_prepare_pilot()` → `_tap_party_cycle()` pressed the
  real `party_cycle` action three times in world input (no fight, no modal). The active index
  stayed at 3 each time:

      [meadows_earned_team] {"after":3,"beat":"party_cycle","before":3,"wanted":0}
      [meadows_earned_team] {"after":3,"beat":"party_cycle","before":3,"wanted":0}
      [meadows_earned_team] {"after":3,"beat":"party_cycle","before":3,"wanted":0}
      [meadows_earned_team] FAIL: Party-cycle input did not select the available training creature

- Active/bench state at that moment: active slot 3 = mudsnout L9 96/…; wanted slot 0 = ripplet L11
  117 HP. Bench: bramblebun L10 68 HP (just given a potion through the Satchel), mudsnout L10
  86 HP, bramblebun L9 78 HP. None fainted. Player (-152.26, -4.95, 4233.56), right after two
  ordinary wild wins on the Mill's far bank.
- Not fixed here (Meadows core owns it). Possible causes to check: a deployed ally's recall or
  cooldown blocking the cycle, or the Satchel menu's close leaving `party_cycle` swallowed.

### B5 ruling applied (attempt 4)

- Step 1: `hall_route.gd` now walks back over the open Mill to the authored `riverwatch_rest`
  (211,3700). Up to 3 nights, it beds the most drained member (under 80% HP) through the production
  creature-bed panel and uses "Rest until morning" (`gate_b_tail_segment.gd`
  `_assign_to_bed`/`_sleep_at_camp`). It then walks back and runs the helper's Sigil loop.
  Receipts: `pre_sigil_camp_route`, `pre_sigil_camp_night`, `pre_sigil_camp_done`. Bench care
  from alternative 2 is unchanged for this attempt; step 2 (`BENCH_CARE_PREPARES := false`) is
  held for a recurrence.

### B5 ruling, attempts 4 to 6 (2026-09-26, seed 4, from `/tmp/claude-0/earned_chain/seed4/relay/save/`)

- Attempt 4 never ran. main's `meadows_earned_bridge_segment.gd` now has
  `_press_gate(prompt, accept_open = false)`, so the `bridge_crossing.gd` override failed to parse
  (`SCRIPT ERROR: Parse Error: The function signature doesn't match the parent`) and the runner
  would not compile. Fixed by matching the signature and passing `accept_open` through. The bridge
  segment has already passed, so it was not re-run.
- Attempt 5 (312 s) failed on the pre-Sigil walk back to riverwatch:
  `Ordinary quarry/Warrens movement did not reach (230.0, -4.124298, 3670.0); player=(334.0885, 6.815587, 3756.698)`.
  band3's own trail points (350,3760)→(230,3670) run through the Relay apparatus. The relay
  helper goes around it on `relay_approach_loop`. This was an error in my route, not a game
  defect. Log: `/tmp/claude-0/earned_chain/seed4_hall_attempt5/`.
- Attempt 6: the walk back is now the relay helper's own forward road (`mill_path`) reversed:
  band3 from the Mill road to (130,3980), then relay_approach_loop to (230,3670) beside the camp.
- Attempt 6 got back to the camp (231,3670) by the new road, but the camp driver's walk to the
  bed was aimed at `the creature bed 2 target=(422.7656, -8.533861, 7401.596)`: twice the camp's
  (211,3700), roughly 3.7 km north. The straight-line walker then looped on
  `[severed_spokes] player went over the edge at 227, -8, 4201 -- back to the road` 263 times,
  and I killed it (PID I started) after about 20 min. Log: `/tmp/claude-0/earned_chain/seed4_hall_attempt6/`.

## B6: Meadows defect: authored camp creature beds are placed at twice their authored coordinates

- `scripts/world/rest_point.gd` sets `position = Vector3(x, ground, z)` on the rest point itself
  (line ~88). `_build_creature_bed()` then adds `CampCreatureBed` as a CHILD with
  `_bed.position = Vector3(x, ground, z)` (line ~152), which is the world `at` used as a local
  offset. So the bed's global position is about 2×(x, ground, z). For riverwatch_rest (211,3700)
  that gives (422.77, -8.53, 7401.60). The same pattern applies to every authored camp bed.
  `night_rest.gd` heals only bedded creatures, so an authored camp cannot heal the party by
  ordinary play. Not fixed here (Meadows file).
- Alternatives considered: another authored camp (same defect); building a bed with the hammer
  (only 1 wood carried); B5 ruling step 2. Taken: step 2. `PRE_SIGIL_CAMP := false` keeps the
  camp code but switches it off, and `BENCH_CARE_PREPARES := false` means bench care
  (Satchel revive/potion) no longer calls the helper's `_prepare()` / party-cycle. The helper's
  own pre-captain `_prepare()` is unchanged. Attempt 7.
- Attempt 7 **passed** `hall` (2142 s wall time, 12:52 to 13:28 UTC). It beat all three Sigil captains,
  opened the Hall approach (3 Sigils spent), and cleared patrol, courtyard and elite, with repeated
  `between_fight_care` receipts. 9 flags gained. Party at the Warden boundary: ripplet L16 0 HP,
  bramblebun L18 8, mudsnout L16 87, mudsnout L17 0, bramblebun L15 37. Potions 7, revives 10.
  0 SCRIPT ERROR.

## B7: Warden lost with a drained belt (helper pacing gap, not a game defect)

- `warden` attempt 1 (13:28 UTC, seed 4, from `/tmp/claude-0/earned_chain/seed4/hall/save/`, 226 s):
  the reveal was delivered (`learned_legendary_is_the_source`). The helper's `_prepare()` revived
  two members and cycled the pilot. Then
  `EARNED WARDEN_ACCEPT FAIL — The actual captain encounter ended without victory: lost`, and the
  whole belt was at 0 HP (L16–18). 7 small potions and 8 revives were left unused.
  Log: `/tmp/claude-0/earned_chain/seed4_warden_attempt1/`.
- Alternative 1 (own file, `warden_accept.gd`): before the helper's `_prepare()`, revive every
  fainted member, then give up to two small potions to anyone under 60% HP, through the same real
  Satchel seam (`care_existing`). Disclosed as `pre_warden_bench_care`. Attempt 2.
- Attempt 2 (alternative 1) **won the Warden**: 9 `pre_warden_bench_care` doses, then 5 rounds and
  91 hits, with `defeated_warden`, `realm_key_cloudreach` and `realm_heart_meadows_earned` gained.
  It then failed on B8. Log: `/tmp/claude-0/earned_chain/seed4_warden_attempt2/`.

## B8: the Warden victory's dialogue outlasts the helper's 120-frame input-return wait

- Attempts 2 and 3: `EARNED WARDEN_ACCEPT FAIL — The actual trainer victory did not return ordinary world input: warden_aldis`.
  An input-owner trace (attempt 3, `warden_accept.gd` diagnostic; the attempt-3 log dir was overwritten by attempt 4) shows
  `<none> -> /root/MeadowsPlayground/DialoguePanel (dialogue_panel.gd) frame=7373` right after the
  victory, still open when the helper's wait
  (`meadows_earned_hall_segment.gd::_fight_named`, 120 frames of no input) runs out. The
  helper expects an ordinary player to be able to act. Nothing presses Interact to read the
  production dialogue.
- Alternative 1 (own file): on the helper's own `trainer_defeated` receipt for the Warden, press
  the real Interact action while that panel stays open (at most 12 taps). This is the same way
  `_drive_machine_to_ceremony` reads the machine dialogues. It logs `post_victory_dialogue_read`
  with the conversation ids. Attempt 4.
- Attempt 4 read `stronghold_warden_realm_reward` (2 taps). `defeated_warden` and the realm
  key/heart flags were set. It then stopped at the machine:
  `An unexpected live dialogue interrupted the machine sequence` (a DialoguePanel was open at
  frames 7942–8007, before or at the machine press). Log: `/tmp/claude-0/earned_chain/seed4_warden_attempt4/`.
  Attempt 5 adds conversation ids to the input-owner trace and a `dialogue_finished` trace.

## B9: machine-sequence helper reads the DialoguePanel's hand-over frame as an interruption

- Attempt 5 trace: `stronghold_chamber` finished at frame 8088, `stronghold_free_legendary` at 8111,
  `stronghold_legendary_joins` at 8127, all in the authored order. Between conversations the
  production panel stays open with an empty conversation id (frames 8089–8096, 8128–8132). The
  helper `_drive_machine_to_ceremony` fails on any open panel whose id is not the next expected
  one, so it reported `An unexpected live dialogue interrupted the machine sequence`. This is a race
  in the Meadows helper, not in the game. Log: `/tmp/claude-0/earned_chain/seed4_warden_attempt5/`.
- Alternative 1 (own file, `warden_accept.gd`): a copy of that function that waits one frame on
  an open panel with an empty id. Everything else is unchanged, including the exact order check
  and the failure message, which now names the conversation. Attempt 6.
- Attempt 6 got past the hand-over frames. It then stopped on
  `An unexpected live dialogue interrupted the machine sequence: veridian_choice`.

## B10: the Warden helper predates the F05 spatial accept/refuse choice

- Production (`stronghold_climax.gd::_open_choice`, `stronghold_climax.json` `choice`) now follows
  `stronghold_legendary_joins` with the `veridian_choice` read-out and two spatial prompts,
  `VeridianAcceptPrompt` and `VeridianRefusePrompt`. The pending catch only appears after one of
  them is pressed. The read-only Warden helper expects the pending catch straight after the join.
  Log: `/tmp/claude-0/earned_chain/seed4_warden_attempt6/`.
- Alternative 1 (own file): the `_drive_machine_to_ceremony` copy (B9) reads `veridian_choice`,
  then answers ACCEPT as `tests/smoke_gate_e_finale.gd` does: it steps to `VeridianAcceptPrompt`
  and presses the real Interact through the exact-provider `_press_prompt`. Receipt:
  `veridian_accept_prompt`. The five-slot farewell (lowest-level member released) is unchanged.
  Attempt 7.
- Attempt 7 (13:56 UTC, 1536 s) **passed the whole ending with ACCEPT**. Receipts: 9 care doses, Warden beaten,
  `stronghold_warden_realm_reward` read, chamber, free, join and `veridian_choice` in order,
  `veridian_accept_prompt` (2.56 m), and `veridian_accepted`. The five-slot farewell released the
  lowest-level earned member (bramblebun L1x, uid creature-3fd01011…) and seated Veridian L23.
  Then came `meadows_ending_settled` and the start of the acknowledgement backtrack
  (`road_metres_one_way` 11416). Log: `/tmp/claude-0/earned_chain/seed4_warden_attempt7/`.

## B11: the acknowledgement road wears the belt down (helper pacing gap, like B5)

- Attempt 7 then failed on the 11.4 km walk back to the village:
  `Real wild combat did not win with landed strikes inside its unchanged physics budget` at
  (164.1,-0.2,4564.9), after 5+ wild wins. At that point ripplet and bramblebun L23 were at 0 HP,
  both mudsnouts were up, and Veridian was at 974 HP.
- Alternative 1 (own file): the B5 `between_fight_care` remedy (revive the fainted, small potions
  under 40%, then the helper's own `_prepare()` pilot selection), before each walk leg, only after
  `meadows_ending_settled`. Attempt 8, from the hall save, so the Warden is replayed.
- Attempt 8 had road care working: `between_fight_care` revived ripplet, then 22 wild wins, later
  ones in 5 hits. I stopped it (PID I started) at about 33 min. The acknowledgement road is 11.4 km
  to Kell, and then the route returns to the storm road, all at 1x walking. At the rate measured
  in attempt 7 (about 3 km per 12 min) the segment would pass run_chain.sh's fixed 5400 s
  `timeout` before the Rift. Log: `/tmp/claude-0/earned_chain/seed4_warden_attempt8/`.
  `run_chain.sh` now takes `CHAIN_TIMEOUT` (default unchanged at 5400). Attempt 9 runs with
  `CHAIN_TIMEOUT=12600`. No acceleration.

## B12: the trainer dies on the acknowledgement road and respawns at home (open, blocking)

- Warden attempt 9 (14:26 UTC, `CHAIN_TIMEOUT=12600`, 2107 s): the ACCEPT ending passed again,
  with Veridian L25 on the belt. Road care worked: 2 `between_fight_care`, 20 wild wins. Then:
  `Ordinary quarry/Warrens movement did not reach (-420.0, -4.161824, 2470.0); player=(-30.45036, -2.109686, 67.91363)`.
  The inventory at the stop is `{}` (the hall save carried 7 potions, 10 revives, tools and
  725 coin). The player stands at the home spawn. So the trainer died on the leg towards
  (-420,2470), everything carried went into a death satchel (`player_death.gd`), and the player
  respawned at home, which is not a helper action. Per `player_death.gd` the only lethal paths are
  a fall (`player_controller.gd::_resolve_landing`) and drowning (`water.gd`). The log has no death
  line, so which one it was is not identified. The helper's `aftermath_road` walks the band1–5
  spines in straight lines. The forward chain never walked band2/band3 that way (it took the
  quarry/Warrens undertrail and the relay loop), so a cliff or water crossing on that spine is
  likely. The only earlier warning is `[player] entombed at 107.61, -0.47, 4513.34 -- recovering`.
  Log: `/tmp/claude-0/earned_chain/seed4_warden_attempt9/`.
- Status: blocking; not retried. Each warden attempt replays the Warden (about 35 min before the
  road). Suggested next step: (1) trace the player's y and HP per walk leg on the return road to
  find the lethal leg. (2) In `warden_accept.gd`, walk the return by the same roads the forward
  segments used (the reverse of warrens/relay/hall routes) instead of the spine. That is a route
  choice, not a teleport. (3) Split `warden` so the settled ending is saved before the walk, which
  needs the aftermath mode's `_climax._stage == "done"` to survive a load.

### B12 ruling (coordinator): return along the forward roads, reversed; care first; death watch

- `warden_accept.gd` overrides `_acknowledge_and_cross`. The return road is the helper's
  `aftermath_road` with its band2 leg (-420,2470)→(-330,2630)→(-180,2730), which crosses the
  Warrens mound, replaced by the roads the warrens and relay segments walked: `warren_undertrail`
  plus the B3 west-of-mound detour (-432,2492),(-418,2528). Band5/4/3 plus the relay loop were
  already the forward hall/relay road. Whole-belt care (`_prepare()`) runs before the walk.
- The death watch logs `EARNED DEATHWATCH` lines: every health drop, with position, cause
  (fall = damaging `landed` in the same frame; combat; otherwise hazard (water/other)), floor state
  and the leg being walked. On `died` it logs cause, position, last floor y and last landing, and
  fails the segment with that cause. B12 attempt 1 = warden attempt 10.
