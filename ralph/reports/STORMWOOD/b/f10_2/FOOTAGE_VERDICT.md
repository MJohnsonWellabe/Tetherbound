# F10#2 footage: Stormwood named wilds at the normal fight camera (ACCEPTANCE C3 framing/readability)

Scope: the six BOSSES §7 named wilds (hollows_alpha, capacitor_alpha, crown_guardian,
old_rodfolk_hall_guardian, blackwater_elder, glass_field_alpha). Captain Marrow/Dynamo is out of scope.
This file covers only the footage half of C3. The numeric C2 and the C3 hit-budget are measured separately by the lead.

**Status: frames captured for all six. All six fights started on the production path. The CODE-BLIND JUDGE HAS NOT RUN.**
This worker has no subagent tool. The neutral-named packet is ready at `judge_packet/` for the lead to run.
The per-question table below is the **capturing agent's own provisional read**. It is not the judge's verdict and cannot close C3.

## How it was captured

- Baseline: branch `tb/stormwood-b-f10-2-footage` from origin/main `025a09d9`. No game code was changed.
- Tool: `capture_named_fights.gd`. It uses the production Game autoload and `scenes/world/stormwood.tscn` with its own Player, CameraRig, HUD, EncounterDirector and CombatManager.
  It captures frames at a fixed 1 s game-time interval (`iNN`). It also captures at the exact enemy state moments:
  - `telegraph_started` gives `tellN-a-start`, then mid-tell (`b-mid`) and 85% of the tell (`c-late`)
  - `strike_ready`/`lunge_started` gives `d-strike`, then +0.2 s (`e-impact`) and +0.55 s (`f-recovery`)
- Run 1 (hollows_alpha only, partial: stopped at t≈8.5 s of 16 s because the machine was contended; its frames and log are kept):
  ```
  XDG_DATA_HOME=<tmp> xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
    --resolution 1280x720 --fixed-fps 20 --script res://ralph/reports/STORMWOOD/b/f10_2/capture_named_fights.gd \
    -- --out=<scratch>/raw --seconds=16 --interval=1.0
  ```
- Run 2 (the other five, 10 s of game time each, exit 0):
  ```
  ... --fixed-fps 10 ... -- --out=<scratch>/raw --ids=capacitor_alpha,crown_guardian,old_rodfolk_hall_guardian,blackwater_elder,glass_field_alpha --seconds=10 --interval=1.0
  ```
- Post-process: `python3 make_sheets.py <raw> frames` produced 960x540 JPGs (<150 KB each) and `frames/sheet-<id>.jpg`. The raw PNGs were deleted afterwards.
- Logs: `capture_log_run1_hollows.txt`, `capture_log_run2.txt`, `capture_log_run2.json` (per-fight summary: tells, hits, misses).

### Disclosed fixtures
1. The party is five level-42 creatures (sparkit, mudsnout, bramblebun, terrapup, brooktail). The five-creature cap holds. Sparkit leads every fight.
2. Debug placement. The player is teleported 4.5 m from each named body's live position, on the side away from its nearest neighbour, and the rig's yaw is turned toward it. Gated regions (Crown island, Deepwood) are reached by placement, not through their gates.
3. Other wild bodies within 25 m of the named body are hidden and process-disabled, so that the Engage nearest-body rule offers the named wild. Counts per fight: hollows 1, capacitor 2, crown 2 (one at 1.2 m), hall 0, blackwater 1, glass field 0.
4. The storm clock is pinned inside Calm every frame (`realm_environment.stormwood.elapsed = 5`). Lightning, Break and Building do not appear in any fight frame.
5. The capture runs with `--fixed-fps` (20 in run 1, 10 in run 2). Each rendered frame advances a fixed game time, so frames are exact game-time samples. Process and physics stay in lockstep. State-moment frames are quantized to 0.05 s (run 1) or 0.1 s (run 2).
6. The ally is steered with the ordinary move stick and `combat_quick` taps (this is not the lead's pilot). The game has no dodge verb. On tells 2 and 3 of each group of three, the stick backs the ally out of the lane from 25% of the tell (run 2; run 1 used a weaker 40% sidestep). Every third tell stands still to show a hit.
7. The fight is cut at the time cap through `combat_manager._begin_resolve("fled")`. The "You backed off." toast in the next fight's `00-before`/`i00` frames comes from this cut, not from the fight being judged.
8. The HUD is visible in every frame. It is the real fight view: enemy name/level/HP, the tell text "! incoming — move" and "it's open — hit it", the team list, the ally card and the move buttons.

## Per-fight results

Engage: every fight started against the exact named body (`enemy_is_named=true`). Four started through the ordinary Engage offer and a physical `interact` edge. The arbiter's winner was the director with actionable label "Engage <Species>". The hall guardian and glass field alpha initiated the fight themselves (aggressive `wants_to_engage`) before the press.

Tell timing is measured in game time from `telegraph_started` to `strike_ready`. Nothing is shorter than authored. The +0.05 s is frame quantization.

| Fight | Body | Authored tell | Measured tells (s) | Enemy hits on ally | Enemy misses (avoidance) | Frames |
|---|---|---|---|---|---|---|
| hollows_alpha | Voltarach L38 | 0.8 | 0.85, 0.85, 0.85 | 3 (t 1.72, 4.32, 7.55) | 0 (run-1 sidestep too weak) | 28 |
| capacitor_alpha | Voltarach L40 | 0.8 (+1.1 route cue per BOSSES) | 0.85, 0.85, 0.85 | 1 | 2 (t 4.83, 7.92) | 30 |
| crown_guardian | Staticub L41 | 0.85 | 0.90, 0.85, 0.90 | 2 | 1 | 31 |
| old_rodfolk_hall_guardian | Tanglevolt L43 | 1.1 (heavy) | 1.10, 1.15 (tell 1 interrupted by stagger) | 0 | 2 | 27 |
| blackwater_elder | Mosshock L43 | 0.8 | 0.85, 0.85, 0.85 (tell 2 interrupted by stagger) | 3 | 0 | 33 |
| glass_field_alpha | Voltarach L42 | 0.8 | 0.85, 0.80, 0.85 | 2 | 1 | 32 |

The authored enemy was on screen in every state-moment frame except `capacitor_alpha-tell3-f-recovery`. There the DIVER's 7 m reposition carried it to the frame edge (`enemy_on_screen=false` in the log). It is back in frame at `i09`.

### Provisional per-question read (capturing agent, NOT code-blind; replace with JUDGE_ANSWERS.txt)

Questions (a)–(e) are those in `judge_packet/JUDGE_PROMPT.txt`.

| Fight | (a) tell visible | (b) where it hits / where to go | (c) both readable at scale | (d) hit or avoidance | (e) distinct |
|---|---|---|---|---|---|
| hollows_alpha | PASS: a magenta ground ring plus "! incoming — move" (`tell1-b-mid`) | FAIL: a ring under the enemy only; no lane, although BOSSES asks for a "full-body lane cue" | PASS (marginal): the Voltarach fills a third of the frame; the Sparkit is small and at bottom-left | PASS (hit): impact flash on the ally (`tell1-e-impact`) | FAIL: reads the same as glass_field_alpha and capacitor_alpha |
| capacitor_alpha | PASS (ring + text) | FAIL: no route-line cue before the dive; the ring only | PASS: the conductor road current lines help place it | PASS (avoid): "it missed you", with the ally clear of the ring (`tell2-e-impact`) | PARTIAL: the road current backdrop differs; the body and tell match hollows/glass |
| crown_guardian | PASS (ring + text) | FAIL: a ring only; no frontal guard stance or facing cue; it chases | FAIL: the ally is partly behind the TEAM 5/5 panel (`tell3-c-late`) | PASS (hit and miss) | FAIL for identity: a plain flower meadow with no Crown glass in frame |
| old_rodfolk_hall_guardian | PASS: a 1.1 s ring + text; "STAGGERED — punish now" also shows (`tell1-c-late`) | FAIL: a ring only; BOSSES asks for a "lit lane telegraph" | PASS | PASS (avoid) (`tell2-e-impact`, `tell3-e-impact`) | FAIL for identity: an open meadow with no hall architecture in frame |
| blackwater_elder | PASS (ring + text) | FAIL: a ring only; no pool edge or dry-ground exit visible | PASS: the Mosshock silhouette is distinct | PASS (hit) | PARTIAL: a distinct body; the environment is not the pool |
| glass_field_alpha | PASS (ring + text) | FAIL: a ring only; BOSSES asks for "a projected lane across glass" | PASS | PASS (hit and avoid) | FAIL: no glass visible and the same Voltarach/ring as hollows |

## Defects

### TIMING/LOGIC (evidence with file:line)
1. **The named CHARGER lunges do not travel and show no lane** (hollows_alpha, glass_field_alpha; BOSSES §7 asks for a 7 m lunge with a "full-body lane cue" or "projected lane").
   - Every CHARGER strike fired `strike_ready`, never `lunge_started` (`capture_log_run1_hollows.txt`, `capture_log_run2.txt`).
   - The lane and the travel exist only when the attack row sets `lunge_travels` (`scripts/creatures/wild_creature.gd:766-767`, lane at `:732`). The Stormwood CHARGER profile (`scripts/combat/stormwood_encounter_catalogue.gd:27`) and the named rows (`data/config/stormwood_encounters.json:5755`, `:5841`) author `lunge: 7.0` without `lunge_travels`.
   - Proposed fix: F10 lane. Add `"lunge_travels": true` to the named CHARGER rows or to the profile, then re-capture.
2. **The DIVER's 1.1 s route-line cue is absent** (capacitor_alpha). BOSSES §7 specifies "1.1 s visible route-line cue + .8 s strike tell".
   - Each attack emitted exactly one `telegraph_started(0.8)` followed by `strike_ready`, with no earlier cue.
   - The DIVER row (`stormwood_encounters.json:5772`, profile `stormwood_encounter_catalogue.gd:29`) has no key for a pre-cue, and the named row also has no `lunge_travels`.
   - Needs an implementation decision within the F10 lane; the numbers are already settled in BOSSES.
3. **The WALL's "stationary frontal guard stance" is not visible** (crown_guardian). The Staticub chases and repositions like an ordinary wild, and the tell is the same radial ring (`crown_guardian-i02…tell3`). There is no frontal/facing cue.
4. Not a defect, recorded for completeness: every measured tell meets C3 (≥0.8 s; the heavy ACE ≥1.1 s). Two tells were interrupted by the ally's stagger (hall tell 1, blackwater tell 2); that is the intended punish window ("STAGGERED — punish now").
5. To check (not established): the hall guardian's live body stood at y=32.36 while the authored row says y=57.85 (`stormwood_encounters.json`, old_rodfolk_hall_guardian). This may be ordinary grounding, but its frames show open meadow and no hall. Verify that the body is where BOSSES/WORLD place the hall.

### LOOK (proposed Codex-queue rows; ralph/reports/VISUAL/AUDIT.md not edited)
- **SW-NAMED-TELL-01**: All six named fights use the identical magenta radial ground ring as their only world-space tell (all `tell*-b-mid` frames). It shows *when* but not *where*: no lane, facing or cone. Proposed: route the lane/route-line cues from BOSSES §7 (depends on LOGIC 1–2) and give the WALL and ACE a frontal/lane shape. The magenta sits close to the reserved oxblood/red; confirm with ART_DIRECTION.
- **SW-NAMED-ID-01**: Three fights share the Voltarach placeholder with the same size, colour and tell (hollows/capacitor/glass_field sheets), so without the HUD level they cannot be told apart. BOSSES allows the placeholder body, so the distinction has to come from the arena: glowmoss, road current and glass.
- **SW-NAMED-ARENA-01**: The fight camera frames only a meadow of grass and flowers for crown_guardian (no Crown glass), old_rodfolk_hall_guardian (no hall architecture), blackwater_elder (no pool edge or dry-ground exit) and glass_field_alpha (no glass). The identity cues BOSSES §7 names are not in frame at the normal fight camera. Proposed: reposition the named bodies or arenas so the named feature sits behind or beside the fight.
- **SW-HUD-OCCLUDE-01**: The TEAM 5/5 list (left-centre) covers the ally when the ally stands left of the enemy (`crown_guardian-tell3-c-late`, `hollows_alpha-tell1-e-impact`). Proposed: collapse the team list during combat, or keep the ally out of the left third.
- **SW-WILD-HOTPINK-01**: A saturated hot-pink/red creature silhouette stands in the Glowmoss Hollows background (`hollows_alpha-tell2-c-late`, top-left). It reads as a missing material or as reserved Team-Tether red. Identify the body and material.

## What remains
- Run the code-blind judge on `judge_packet/` (the prompt is included; the mapping below must not be shown to the judge). Record its answers verbatim in `JUDGE_ANSWERS.txt` and replace the provisional table.
  Mapping: A=blackwater_elder, B=hollows_alpha, C=old_rodfolk_hall_guardian, D=glass_field_alpha, E=crown_guardian, F=capacitor_alpha.
- Hollows was captured for 8.5 s with no avoidance frame. A re-run with `--ids=hollows_alpha` would add one; the tool's current dodge policy produced misses in the other fights.
- After LOGIC 1–3 land, re-capture the CHARGER, DIVER and WALL fights. On this evidence F10#2's footage half should not be called passing: the where-to-avoid question (b) fails for all six by the capturing agent's own read.
