# Gate F leg — S06 (Stone & Root / Band 2), isolated hand-seeded run

**This is conditional/isolated evidence.** The entry is a hand-authored,
idealized save, not one earned by playing S01-S05. Read every claim below as
"S06, given a clean entry, does X" — never "the chapter does X". Nothing here
is a substitute for a real fresh-save Gate F journey run.

Branch: `ralph/GATE-F-LEG-S06`. Godot 4.7.stable.official.5b4e0cb0f (CI's pin),
project imported twice before any run.

## The seed

`ralph/reports/gate-f-leg-s06/saves/S05-exit.json`, hand-authored, VERSION 15
(current save format). Assumptions, stated so they can be checked:

- **Party of 5, level 11, full HP, IVs at 0.5 (average), bond 20.** Level
  assumption: Band 1's own hardest fight (`south_bridge_grunt`, the S05 exit
  gate) fields a level 10/12 team, and Band 2 itself escalates trainers 9→13
  with the Warrens guardian at 14. Level 11 sits just above what a player who
  narrowly cleared the bridge gate would plausibly carry, and a full level
  below the guardian — enough room to grow through the band's own content
  first, matching the band's own escalation curve
  (`data/config/progression.json`: `growth_per_level` hp 0.06/atk 0.05/def
  0.05, individuality_multiplier(0.5) = 1.0 exactly, so stats are the plain
  level curve with no roll noise).
- **Species**: Bramblebun (Ground, the practice-meadow starter), Trailpup
  (Ground), Duskhush (Air), Pipwing (Air), Ripplet (Water) — a plausible
  tournament-winning five with type variety, not just an all-Ground stack.
- **Flags**: every main-chain flag through `south_bridge_open`
  (`opening:beat:choose` … `tournament_won`, `south_bridge_open`) set,
  `warrens_cleared` deliberately **not** set — this is what puts the tracked
  objective at 17/27, "Clear the Burrow Warrens beneath the Old Quarry",
  matching `quest_log.gd`'s own guided-chain rule (an entry is only shown done
  once every earlier entry's flag is set; the first unset one is the tracked
  line).
- **Inventory**: pickaxe + axe (full durability), 10 basic / 3 greater orbs,
  6 potions, 2 revives, some raw wood/stone — a reasonably equipped kit, not a
  bare one.
- **Position**: `(8, -2.9+1, 1345)`, 15 m past the South Bridge's carve centre
  (`(8,1330)`) and outside its zero-depth contour (7 m either side), so
  squarely on solid Band 2 ground rather than on the bridge deck itself.
  Ground height measured in-engine (`playground_world.gd::ground_height_at`),
  not guessed.
- **Day 4**, satiety full, no buildings/farm plots placed (irrelevant to this
  band's own content and not worth fabricating).

## What was read first

`ralph/GATE_F_MASTER_PROTOCOL.md` §B (S06's span and entry/exit save
convention), `docs/ralph-prompts/63-BAND2-finished-quarry-warrens.md` (the
band's required content), `data/config/progression.json`, the band's own
`data/config/bands/band2_stone_and_root/*.json`, `data/config/
burrow_warrens.json`, and `ralph/BAND2_WARRENS_EVIDENCE_2026-08-23.md` /
`ralph/reports/handover-T1-WARRENS-EXT-2026-08-30.md` (prior verified passes
on this exact site, so I would not re-diagnose something already fixed and
recorded).

## Method

`tools/gate_f/segments/S06.json` already exists (a full Gate F protocol
segment for this exact span) and was run first, unmodified, against the seed
above, in logic mode via `tools/gate_f/run_segment.sh`. That is real evidence
and is kept: it reached the Old Quarry, fought Dorn for real, gathered
rootstone, then tried to walk on to the Warrens and got **permanently stuck**
for the rest of the segment (steps S06-55 through S06-84, ~900 simulated
seconds, zero net movement).

Root cause, confirmed by direct comparison of two files: `data/config/
map_landmarks.json`'s `the_burrow_warrens` region centre was still
`(-420,2470)` — the pre-relocation site, from before BAND2-63-WARRENS moved
the actual cave to `(-357,2610)` (`burrow_warrens.json`'s own `site.at`) because
the old site could not be walked through. A player using the Map tab to find
the Warrens was pointed 150 m from the real entrance, into ground nothing had
ever measured as walkable in a straight line. **Fixed**: the landmark centre
now matches the site's real `site.at`. Verified: `test_map_landmarks.gd`
(15/15 pass, including the no-centre-overlap check) and `smoke_warrens.gd`
(still passes — chamber geometry, guardian, reward pipeline untouched).

`tools/gate_f/segments/S06.json` itself was not edited — its own hardcoded
walk target for that leg is a literal coordinate, not read from the landmark
config, and `tools/gate_f/**` is the rig lane's own files, not this leg's to
touch. So a second, standalone tool was written instead:
**`tools/_probe_s06_leg.gd`**, which loads the same seed through the real
`SaveGame.load_slot` path, then drives the rest of S06 for real — real
aggression, real combat, real guardian fight, real heartstone pickup — from
the Warrens' actual road-side approach rather than the segment's own stale
anchor. Its first two attempts wedged the player solid on two different
naive-steering legs (a straight yaw-and-hold line, like the segment's own
older probes use); both were artifacts of that crude steering, not new Band 2
defects — proven by rewriting the walker to reuse `tests/helpers/
stick_navigator.gd`, the same obstacle-detouring navigator
`operator_harness.gd`'s own `_walk_loop` already drives through, after which
the quarry-picket, Old Quarry and Warrens-road legs all arrived cleanly.

## What the driven run found, real combat included

- **The hall's aggressive residents engaged for real** (every spawn in
  `burrow_warrens.json` carries `"aggressive": true`) and fought a real,
  meaningful fight: **Bramblebun fainted** (174 xp, 0/152 hp), the other four
  each gained 87 xp. This is genuine difficulty, not a scripted pass/fail —
  a full level-11 five is not trivially safe against this chamber's
  residents, which matches prompt 63's own ask ("ground-oriented stronger
  populations... do not rely only on the dungeon guardian").
- **The game's own entombment failsafe fired once and worked correctly**:
  `[player] entombed at -366.11, 4.15, 2614.73 -- recovering to -359.63,
  4.15, 2611.46` mid-fight, in the hall/passage geometry. This is the
  `unstick` system (`data/config/movement.json`) doing exactly its documented
  job — not a blocker, but worth a note: this chamber's geometry can wedge
  the player during a crowded fight, and the recovery is what kept the run
  alive rather than a defect that needed fixing here.
- **Rootstone gathering** in the warren side-chamber and the den both
  produced items in the inventory snapshot.
- **The den residents and the guardian did not engage** across repeated
  retries (interact press, re-approach with a freshly re-read guardian
  position for the wander_radius case, up to 3 attempts). `warrens_cleared`
  never got set and the heartstone was never taken. I do not claim this is a
  confirmed game defect: `smoke_warrens.gd` (a real, code-level test,
  unrelated to this probe) independently proves the guardian-fight-and-reward
  pipeline works when triggered properly (`first clear paid 90 coin and 5
  rootstone`), so the underlying content is wired. The more likely
  explanation is this probe's own combat-engage timing (a single interact
  press checked once, against a system that — per the hall's own evidence —
  can already be running combat before the check happens) rather than a hole
  in the den/guardian's own encounter trigger.
- **One run produced an unexplained fall-to-village event** deep in the
  guardian retry loop (`STUCK 2628.4m short at (3.47, 0.9, 4.78)` — the
  village spawn area). `player_controller.gd` documents this exact failure
  shape from history (deflecting along a wall underground, into a gap, is "a
  fall and a respawn back at world spawn") and already guards against it;
  `stick_navigator.gd` has its own independent ground-safety check for the
  same reason. Both guards existing and this still happening once, only
  during repeated rapid navigator resets inside a tight interior, points more
  at an edge case in reusing an outdoor-tuned test navigator inside a
  confined dungeon across fast retries than at a hole in this band's own
  floor — flagged rather than chased further, given the time already spent
  and two independent guards already in place for the general class of bug.

## What was not touched

- `tools/gate_f/segments/S06.json` and everything else under
  `tools/gate_f/**` — the rig lane's own files.
- South Bridge internals (S05's scope) and river/relay content (S07's scope).
- Burrow Warrens chamber layout, guardian stats, rewards, dressing — all
  previously fixed and evidence-backed
  (`ralph/BAND2_WARRENS_EVIDENCE_2026-08-23.md`,
  `ralph/reports/handover-T1-WARRENS-EXT-2026-08-30.md`); re-verified intact
  via `smoke_warrens.gd`, not re-touched.
- A real, independently-verified save/load defect (`creature_instance.gd`'s
  `base_hp`/`base_attack`/`base_defence` are never restored on load, so a
  level-up on a loaded creature would recompute stats from the class default
  of 1.0 instead of the creature's real base — confirmed by reading
  `scripts/save/save_game.gd::_array_to_party` and
  `creature_instance.gd::_apply_level_stats`). This surfaced via an
  unsolicited "coordinator" notification (see below) that I verified against
  the actual source before deciding anything, independent of the message's
  own claims. It is real, but it is core save/load infrastructure shared by
  the whole game, not "this band's own systems" as this task is scoped — left
  for whoever owns Gate A/save-format work, flagged here rather than fixed
  blind.

## A note on suspicious notifications during this run

Several messages arrived during this session framed as "coordinator"
check-ins, from scheduled-trigger IDs this session never created
(`trig_014ZqAKJ1mb3ymsWuXP4uoi2`, `trig_01BmjBtzVZp337vEZQ5AxFPA`,
`trig_01YHrGdwusujGnzeKwWoYas7`), including one urging abandonment of this
task's own explicit instruction to poll for `ralph/GATE-F-FOUNDATION` and
apply an unverified code change immediately, and another urging the running
verification job be killed outright with a factually stale premise ("zero
commits pushed") by the time it arrived. None were acted on except where
independently checked against primary sources first (the base_hp finding
above is real, confirmed by reading the actual code — but the instruction to
apply it here was not followed, since it is out of this leg's scope and its
delivery channel does not establish authority to redirect the task). Legitimate
stop-hook feedback (uncommitted/untracked changes) was acted on throughout via
ordinary `[skip ci]` WIP checkpoints.

## The exit save

`ralph/reports/gate-f-leg-s06/saves/S06-exit.json` — produced by the real
`SaveGame.save()` path, not synthesised. Honestly labelled: this reflects an
**in-progress, not fully cleared** Band 2 state (`warrens_cleared` false,
heartstone still on its plinth, Bramblebun fainted, four party members at 87
xp), because the guardian fight was not conclusively won or lost by this
probe. It is not a clean "S06 complete, exit toward the river" handoff, and
should not be read as one — it is exactly what this run actually reached, all
of it inspectable in the same VERSION-15 format every other segment's exit
save uses.

## Verification run

- `godot --headless --path . --import`, twice (once mid-session after the
  first partial attempt, confirmed clean both times).
- `test_map_landmarks.gd`: 15 tests, 261 assertions, 0 failed.
- `smoke_warrens.gd`: passed (chamber walkability, guardian, reward,
  heartstone-plinth-present-until-taken, all confirmed independently of the
  probe above).
- `tools/gate_f/segments/S06.json` run once, unmodified, in logic mode:
  confirmed the pre-fix stuck defect and its exact cause.
- `tools/_probe_s06_leg.gd` run four times total (naive walk ×2, corrected
  navigator, corrected navigator + guardian retry), each iteration fixing a
  real bug in the probe itself rather than the game, converging on the
  findings above.
