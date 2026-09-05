# W13-PROGRESSION-FEED — report

**Branch:** `ralph/W13-PROGRESSION-FEED-0904` (from `origin/main` at `ef16544f`)
**Brief:** `ralph/briefs/0904/W13-PROGRESSION-FEED.md`; contract
`docs/prompts/73-PROGRESSION-VISIBLE-bond-and-level-feedback.md`
**Owner sentence answered:** *"Bonding and leveling creatures is basically invisible. It
needs to be a big thing. Not just when the bond goes up but also while trying to bond."*
(`docs/owner/OWNER_DIRECTIVES_2026-09-04-C.md` §1)

---

## 1. The decision, recorded before the code

`docs/decisions/D74-bond-ladder-is-unordered-and-progression-has-one-feed.md`, committed
first (`36381450`), per prompt 73 §2.4 and `docs/00_START_HERE.md`'s rule that open design
questions are decided by the orchestrator rather than queued for the owner.

- **§2.4 option 1, the unordered ladder.** A bond node is earned when *any* task completes,
  not the next one in the list. Same five tasks, same targets, same 0–5 tier count; only
  `tier()` and `current()` changed. The "next" task the UI points at is the incomplete one
  **closest to done** (fraction, list order breaking ties). Under the old ordered rule a
  creature fed ten meals before its fiftieth battle showed **no bond progress at all** from
  those meals — four of five actions were invisible until their turn, which is exactly what
  the owner calls invisible. No save migration: the five counters are the persisted state
  and none of them changed, and no creature can lose a node on load.
  `progression.json`'s `evolution.mudsnout.bond_tier: 3` now means "any three".
- Two smaller calls also recorded there: the feed is a **polled queue, not a signal**
  (`project.godot` declares zero signals and the repo's idiom is revision polling), and
  **`set_level()` stays silent** — every caller of it is a spawn/story/trade path, so candy
  goes through the new `gain_levels()`, which announces.

## 2. Files changed

**New**

| File | What it is |
|---|---|
| `scripts/creatures/progression_feed.gd` | The feed: a bounded, sequence-numbered event log with a revision counter, plus the derived readouts (`xp_near`, `xp_remaining`, `xp_fraction`) and the one place every progression sentence is built (`tick_label`, `moment_text`, `level_up_changes`) |
| `data/config/progression_feedback.json` | Every tunable: per-task near thresholds and the XP one, the distance tick step, tick/near/moment durations, the collapse window and cooldown, the banner slot and safe-area fraction, the two cue ids, the tick verbs |
| `tests/test_progression_feed.gd` | 24 tests over the feed |
| `tests/test_candy_progression_safety.gd` | 11 tests over candy and the level cap |
| `tests/smoke_progression_feedback.gd` | The runtime proof (§4) |
| `tools/_capture_progression_feedback_0904.gd` | The four visual frames |
| `docs/decisions/D74-…md` | The decision above |

**Changed**

| File | Change |
|---|---|
| `scripts/creatures/creature_instance.gd` | `gain_xp()` pushes `xp_gained` and, on a level, **one** `level_up` carrying stat deltas, `trait_unlocked`, `evolution_ready`/`evolution_level_reached`; new `gain_levels()` is the candy path through the same event; new `credit_battle_fought()` so the manager's diff stays one line |
| `scripts/creatures/bond_milestones.gd` | `tier()` unordered (D74); `current()` is now nearest-to-done; new `task_rows`, `remaining_text`, `benefit_text`, `next_benefit_text`, `is_near`, `strip_fields`; **`credit()` is the only writer of a bond counter** and pushes `bond_credit` / `bond_near` / `bond_milestone` |
| `autoload/game_state.gd` | `push_progression_event` / `peek_progression_events` / `take_progression_events` / `progression_feed_revision` beside `push_world_message`; the feed is cleared on a new game |
| `scripts/combat/combat_manager.gd` | **One line** — the `battles_fought` increment routes through `credit_battle_fought()` |
| `scripts/ui/tab_backpack.gd` | Candy uses `gain_levels()`; new static `candy_result_line()` says "+1 of +3 — that's the level cap, 50" instead of silently wasting the item |
| `scripts/ui/party_strip.gd` | XP sliver under the HP bar, a `bond n/5` pip, floating `+12 XP` / `+bond · fed` tick labels, the slow near pulse, and its own feed polling (so both mounts tick without either HUD routing anything) |
| `scripts/ui/playground_hud.gd` | The Moment banner (build, placement, queueing, collapse, cue), the `N to Lv M` line in the creature block, feed-revision-aware strip refresh, and evidence accessors |
| `scripts/ui/combat_hud.gd` | `_set_xp_line()` reads the feed instead of `last_xp_award`, with a per-fight cursor; strip entries carry the progression fields |
| `scripts/ui/tab_creatures.gd` | Every bond task against its target with one `NEXT` and the rest `DONE`/plain, the next node's benefit, and `N EXP to Lv M · evolves at Lv 15` |
| `scripts/ui/bond_meter.gd` | The node being worked toward draws a warm arc for its task's progress |
| `tools/audio/gen_sfx.py`, `data/config/audio.json` | Two generated cues (`level_up`, `bond_milestone`) and the `progression` block mapping the cue ids to them on the UI bus |
| `tests/test_bond.gd` | Tier assertions rewritten for D74; new coverage of `bond_near`, `bond_milestone` benefit text, task rows, and the evolution gate reading "any three" |
| `tests/test_level_up_announcement.gd` | **Rewritten**: every test now runs `_set_xp_line()` against a stub manager with a real creature really awarded through `gain_xp`, and reads the rendered Label back. The old file asserted on the *source text* of the function — prompt 33's false-positive shape |
| `tests/test_hud_widgets.gd` | The strip now has a third fixed child (the tick-label holder) |
| `docs/CURRENT_STATE.md` | The CL-W6 row rewritten in place |

## 3. What the player now sees

- **While trying to bond.** Every bond-earning action ticks the party strip the moment it
  happens: a win, a meal, a landmark, a night, and distance (once per 250 m, not on every
  half-second poll). The row flicks `+bond · won` / `+bond · fed` / `+bond · discovered` /
  `+bond · rested` / `+bond · travelled` beside the creature it belongs to, and the strip
  reveals itself for it, so an award earned while walking is seen.
- **How close.** The strip carries a `bond n/5` pip and an XP sliver that fills toward the
  next level; both breathe slowly when a milestone or a level is within its configured
  threshold. The world HUD's creature block says `141 to Lv 4`, warming to amber when a
  level is one fight away — the prompt's "from the world HUD, not only the Team screen".
- **The moment.** A level-up or a bond node draws a banner naming the creature, the new
  level or node, and **what changed** (`+6 HP · +1 ATK · +1 DEF`, `second trait revealed`,
  `evolution ready`), with a sound cue. It queues during a fight and flushes at the result
  beat, so it can never cover the combat controls; it is a passive layer that cannot take
  focus, and it holds while a dialogue or menu is up. Two moments within five seconds share
  one plate.
- **What it is for.** The Team screen lists **all five** bond tasks with their counters,
  marks the finished ones `DONE` and the nearest one `NEXT` with what is left
  ("2 more landmarks"), and names the next node's benefit
  ("+1% attack and defence (now +3%) · unlocks evolution"). The bond meter's next node
  draws a partial arc for that task's progress.
- **Candy** (`level_up` item effect, PR #39) now goes through the same event as a fight, so
  a Rare Candy is one banner reading `+3 levels`, not silence. It keeps the creature's HP
  fraction and banked XP (unlike the spawn jump), refuses a fainted creature with a reason
  in the row, and when it cannot grant its full amount it says so. No candy was placed in
  the world — that is the density lanes'.

## 4. Verification

Godot 4.7 installed per COMMON.md. Every command was run from the repo root with
`export PATH=$HOME/godot-bin:$PATH`.

### Unit

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_progression_feed.gd,test_bond.gd,test_level_up_announcement.gd,test_candy_progression_safety.gd
  → 80 tests, 249 assertions, 0 failed

godot --headless --path . --script tests/run_tests.gd -- --only=test_save_format.gd,test_progression.gd,test_combat_progression.gd,test_progression_state.gd,test_creature_history.gd,test_hud_widgets.gd,test_bond.gd,test_progression_feed.gd,test_level_up_announcement.gd,test_candy_progression_safety.gd,test_evolution.gd,test_tournament.gd
  → 336 tests, 1290 assertions, 0 failed
```

`test_save_format` is in the second run and passes: no persisted field changed, so no
migration was needed (D74 §1).

### Seen red first

Three separate probes, each reverted immediately afterward with `git checkout`:

| Probe | Result |
|---|---|
| `progression_feed.push()` stubbed to `return {}` (the feed disconnected, everything else intact) | **19 of 80 failed** — 11 in `test_progression_feed`, 5 in `test_level_up_announcement`, 2 in `test_bond`, 1 in `test_candy_progression_safety` |
| `tier()` restored to the old ordered `break` rule, feed intact | **4 of 43 failed** in `test_bond`: `test_a_later_task_alone_earns_a_node_d74`, `test_tier_counts_every_completed_task_in_any_order`, `test_evolution_gate_reads_any_three_nodes`, `test_bond_milestone_carries_the_correct_benefit_text` |
| Both at once, plus the whole file reverted to `origin/main` | 9 failed / 2 files failed to parse |

The middle probe is the one that matters for the rewritten `test_level_up_announcement`:
with the feed disconnected it goes red on the *rendered text* being empty, which is the
failure the old source-grep version could not see.

### Smoke

```
godot --headless --path . --script tests/smoke_progression_feedback.gd     → exit 0, "Progression feedback: OK"  (twice: before and after the round-2 banner move)
godot --headless --path . --script tests/smoke_combat.gd                   → exit 0, "combat: OK"
godot --headless --path . --script tests/smoke_tournament_bracket.gd       → exit 0, "smoke: OK"
godot --headless --path . --script tests/smoke_creatures_tab_controller.gd → exit 0, "Creatures tab controller isolation: OK"
godot --headless --path . --script tests/smoke_backpack_player_eats.gd     → exit 0
```

`smoke_progression_feedback` is the runtime validation the acceptance rests on. On a real
Meadows boot at the handheld's own canvas it:

1. walks to a wild creature on the stick, engages and fights it to a win on the buttons —
   then asserts `xp_gained` **and** `bond_credit` reached the feed for the ally and that the
   strip row ticked twice, last label `+bond · won`;
2. pushes a level-up to the **bench** creature mid-fight and asserts the banner is **not**
   visible and the moment is queued — then that it flushes after the fight, naming the bench
   creature;
3. feeds a creature through the Satchel's own target picker on pad input → `+bond · fed`;
4. stands inside a landmark's `discover_radius` until `Game`'s discovery poll credits the
   party → `+bond · discovered`;
5. places a creature bed, a tent and a bedroll through controller build placement, assigns a
   creature in the bed panel and sleeps on the bedroll's own Rest interaction →
   `+bond · rested`, plus the rest-bonus XP on the feed;
6. forces a level-up outside a fight and measures the banner's rect against the 5% safe area;
7. fires two level-ups inside the collapse window and asserts one plate lists both;
8. opens the Team screen and asserts one row per bond task, exactly one `NEXT`, every row
   carrying its counter, the EXP line and the benefit line.

Sample output:

```
ok    a mid-fight level-up is held (queued 1, banner hidden)
ok    the strip ticked 2 times for the win; last '+bond · won'
ok    the queued level-up flushed at the result beat: 'Bench reached Lv 2 | +6 HP  ·  +1 ATK  ·  +1 DEF | '
ok    a Satchel meal ticked the strip: '+bond · fed'
ok    discovering 'village' ticked the strip: '+bond · discovered'
ok    a night in the bed ticked the strip: '+bond · rested'
ok    banner 'Ripplet reached Lv 4 | +6 HP  ·  +1 ATK  ·  +1 DEF | ' at [P: (510.0, 184.0), S: (900.0, 111.0)] inside the safe area of the (1920.0, 1920.0) canvas
ok    world HUD creature block reads '196 to Lv 5'
ok    two moments within the window share one plate: 'Ripplet reached Lv 5 | … | Bench reached Lv 3'
ok    Team screen bond rows: ["          1/50 wild creatures defeated together", "NEXT   1/3 landmarks discovered together   ·   2 more landmarks", …]
ok    Team screen xp line: '254 EXP to Lv 6'
ok    Team screen next benefit: 'Next node:  +1% attack and defence (now +1%)'
```

**Engine error set.** Grepped for `^ERROR:` and `SCRIPT ERROR` (not `SCRIPT ERROR` alone,
per AGENT_WORKFLOW §6), and read rather than counted. `smoke_progression_feedback`,
`smoke_tournament_bracket` and `smoke_creatures_tab_controller` show only the known-benign
`ERROR: Parameter "material" is null.` off alpha creature builds; `smoke_combat` and
`smoke_backpack_player_eats` show none.

**One line did appear that is not on `main`, and it does not reproduce.** The first
`smoke_creatures_tab_controller` run on this branch printed
`ERROR: 4 resources still in use at exit.` — a shutdown-time diagnostic, after the smoke's
own `OK`. It is worth writing down rather than averaging away, so it was chased:

| Run | Result |
|---|---|
| `origin/main` in a clean worktree, same smoke, same box | 0 occurrences |
| this branch, run 1 | **1 occurrence** |
| this branch, run 2 | 0 occurrences |
| this branch, run 3 | 0 occurrences |

It also appears in **none** of the other four smokes on this branch, including
`smoke_progression_feedback`, which exercises far more of the new code (the full world, the
menu, the Team screen, the banner and its audio cue) than the tab smoke does. So: one
occurrence in three, at exit, in the smoke that touches the least of this diff. That is the
same shape AGENT_WORKFLOW §6 warns about with the `material is null` count ("not stable and
must not be the bar"), and it is not evidence of a leak in the feed — but it is a line that
was not there before, so the coordinator should know it exists rather than find it in CI.

### Visual

`tools/_capture_progression_feedback_0904.gd` under
`xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver opengl3
--resolution 1280x800`, four frames at 1280×800 over the lightweight HUD scaffold
(`tools/capture_hud_lightweight_0904.gd`'s own approach, for its own reason: the full world
build is 20–50 minutes under software GL and every question here is about the interface's
geometry and colour, not how it composites against grass). Events are pushed through the
real producers, so the frames show what the shipped code draws.

Contact sheets: `shots/_sheet_round1.png`, `_sheet_round2.png` and `_sheet_round3.png`
(level-up banner, bond-milestone banner, strip mid bond-tick, Team screen).

Measured before the render: the banner plate's crop median luminance **31.6** against the
world band's **103.3** behind it (a 0.31 ratio — a firmly dark plate on a light ground),
with text peaking at **243**. The banner's measured rect is `(510, 184) 900×111` on the
1920-wide canvas, inside the 5% safe area on every edge; the smoke asserts this
independently at runtime.

Two rounds, each judged by a **fresh** code-blind sub-agent given only the frames,
`docs/reference/` and the visual-judge skill — told nothing about what changed, what was
hoped for, or what the previous round said. Both were asked the same six questions
(legibility at 1280x800, the plates' internal hierarchy, clipping and the 5% safe-area
margin, whether the roster's labels and bars are distinguishable, whether the Team screen's
progress list is scannable at a glance, and whether any overlay would obscure something
during action).

**Round 1** — `JUDGE.md`, sheet `shots/_sheet_round1.png`. It found three defects of mine
worth the round, and they were real:

1. **The banner drew straight through the objective hint card.** `_position_moment_banner()`
   cleared only the region banner's slot, and `_build_objective_hint_card()` places itself
   directly under that and *grows downward with its wrapped text* — so a Moment landing while
   a hint was up put two strings on the same pixels, on the headline. The judge called it the
   worst thing in the set and it was right; nothing in my own smoke could have caught it,
   because the smoke asserts the banner's rect against the safe area, not against its
   neighbours.
2. **The strip's new bond pip overflowed the row.** At `ROW_SIZE.x` 336 there was no width
   left to take: the name truncated mid-word to `Biscui` (too narrow even to draw its
   ellipsis), `Lv 7` and `bond 2/5` ran together as `Lv 7bond 2/5`, and the HP bar was
   crushed into the row's rounded border.
3. **The tick tag was unplated** — the judge measured the amber `+bond · discovered` at
   ~1.3:1 against the backdrop and noted it is the feature's whole payload, and that it
   would vanish outright over sunlit grass. It was the one HUD element landing over open
   ground rather than over a plate.

It also, fairly, called the strip unreadable at ~25% opacity in the tick frame — that one was
a **capture defect**, not a shipped one: the frame was shot 3 frames after the credit, inside
the strip's own 0.14 s reveal tween.

**Fixed in round 2** (`_sheet_round2.png`, judged fresh as `JUDGE_ROUND2.md`): the banner now
measures the hint card's live bottom edge and sits below it, re-checked every frame while it
is up, so a hint appearing mid-banner pushes the banner down instead of colliding; the row
widened to 420 with a floor under the name and a minimum width for the bond pip; the tick got
its own `BG_DEEP` plate; the capture waits for the reveal to land. Measured after: the tick
core reads **(224, 177, 72) on a (9, 12, 15) plate — 9.85:1**, against ~1.3:1 unplated in
round 1.

**Round 2** — `JUDGE_ROUND2.md`, sheet `_sheet_round2.png`, judged by a **fresh** agent with
no knowledge of round 1. It confirmed the three fixes held, in its own words: *"Not
truncated, no run-together. Biscuit, Moss, Ridge, Pip, Kite all fit"*; the only overlapping
pairs it could find were *"both in the bottom-left HUD"* (the pre-existing HP/FOOD chips, not
the banner); and the tick tag dropped off its illegibility list entirely. It then found three
more things that are mine, all fixed in a third pass:

4. **The two banner types were the same picture** — it pixel-diffed them at 1.07% differing,
   *"none of them in the plate's border, headline or second line"*. A level-up now takes a
   **teal** plate and title (the colour levelling already wears on the XP sliver and the
   combat HUD's line); a bond node keeps **amber**. Re-measured: 9.33% of the frame differs,
   and the plate border samples 1,814 teal / 0 amber pixels on the level-up against 84 amber
   / 0 teal on the milestone.
5. **A level-up collapsed into an existing plate was demoted to the smallest, dimmest line**
   (*"the level-up should not be the thing hidden in tier three"* — raised in both rounds). A
   `level_up` now takes the headline from a non-level-up when it joins, and the displaced
   moment moves to the also-line rather than being dropped. That line also moved up from
   `FONT_TINY` to `FONT_LABEL`, which the judge measured at 11 px.
6. **The bond pip sat immediately left of the HP pill**, so the judge read the (full,
   because healthy) pill as the bond meter and called it a contradiction of the number beside
   it. The pip moved to the text side of the row, next to the name.

It also caught a second **capture** defect rather than a code one: with only 40 frames between
the two banner shots, the second event landed inside the 5 s collapse window and *joined the
first plate*, so both frames photographed the same banner. The capture now waits past
`moment_collapse_seconds + moment_seconds` between events. That is why the round-2 sheet's
two banners looked identical even where the code already differed.

**The ceiling, recorded.** The round-3 frames (`_sheet_round3.png`) were **not** put to a
fourth judge — the brief's stop rule is two rounds, and rounds 1 and 2 each moved real things.
Everything still open on round 2's list is outside this lane's ownership and is HUD-wide
rather than progression-specific: body type across the whole HUD running at 10–14 px against
a ~20 px handheld floor, the persistent HUD breaching the 5% safe area on all four edges, the
HP/FOOD readout plates drawn on top of the bars they label, `Tired · Fed · Restless` lit
identically on every roster card, the roster's uninformative rings glyph and level bars, and
the keyboard-only HUD hints on a controller-first target. Those want a HUD-wide pass (CL-B4's
territory), not more edits from here.

**One judge finding checked and rejected.** Round 2 reported that in `strip_bond_tick.png`
the `+bond · fed` toast sits level with Ridge while "the creature that ticked to 2/5 is
Moss". The toast is on the right row: Moss's tick was the *previous* frame's event (her meal
completed her feeding task, which is why she reads 2/5), and the frame's own credit goes to
Ridge. `smoke_progression_feedback` asserts this behaviourally, per creature index, and
passes — the judge inferred the actor from the bond numbers rather than from what ticked.

**Not mine, left alone and reported up** (the judge found these too, and they are outside
this lane's ownership): the whole HUD is anchored to roughly a 1% margin rather than 5% (the
HP/FOOD plates 53 px inside the left edge, the minimap 3 px past the top) — that is CL-B4's
standing item and it predates this branch; the HP/FOOD value chips cover the bar fill they
annotate; roster portraits are duplicated across creatures and disagree with the 3D preview;
`Tired · Fed · Restless` renders identically on every roster row; the keycap glyphs are ~6 px.
None of those are touched by this diff.

## 5. Acceptance (prompt 73 §5)

| Bar | Evidence |
|---|---|
| During a continuous segment a player can identify **at least two real actions** that increased bond, inspect progress toward the next milestone, and recognise a milestone without debug data | `smoke_progression_feedback` drives **four** real bond actions (win, meal, landmark, night) and asserts the strip ticked with a distinct, named label for each; the Team screen shows all five counters with one `NEXT` and what is left; a milestone draws the banner with its benefit and a cue |
| Normal combat and candy produce clear, consistent level feedback, and the player can tell how close a creature is to the next level **from the world HUD** | Both go through `gain_xp`/`gain_levels` into the same `level_up` event and the same banner (`test_candy_progression_safety`, `test_progression_feed`); the world HUD creature block reads `196 to Lv 5`, asserted in the smoke, and the strip carries the XP sliver |
| The evidence template for the segment records the two bond actions and the level-up by name | The smoke prints them by name and label; the block is quoted above |
| **Fails if** only the final bond-up becomes visible | Every credit ticks; `bond_near` fires at the configured remaining count |
| **Fails if** a level changes in data and the player must open a menu | The banner is on the world HUD, plus the combat HUD's own line |
| **Fails if** the banner covers combat controls or steals focus | Asserted: hidden and queued during a fight, flushed after; a passive `PanelContainer` on `LAYER_HUD` with `MOUSE_FILTER_IGNORE`, held while any story modal is open, and now placed below the objective hint card's live bottom edge |
| **Fails if** any new test passes by reading a script's source | No new test opens a `.gd` file; the one that used to (`test_level_up_announcement`) was rewritten to run the builder, and was seen red for the right reason |

## 6. Known limitations and what was deliberately not done

- **`smoke_gate_b_continuous` was not run.** The command was declined in this session before
  it started. Nothing in this lane's diff touches the objective chain, dialogue or the
  build path, and `smoke_creatures_tab_controller`, `smoke_backpack_player_eats`,
  `smoke_combat` and `smoke_tournament_bracket` all pass, but the Gate B core prefix is
  **unverified on this branch** and the coordinator should run it before landing.
- **The Gate F S01–S03 segments were not run** (not requested by the brief; they are the
  harness's own long chain).
- **Visual frames are over a grey stand-in world**, not real Meadows terrain, for the
  timing reason above. Composition against grass at the real route stands is not answered
  here; that belongs to the route-strip capture lane (CL-H9).
- **Not built, by scope:** the CL-A2 level-up flourish shader and the addendum §E companion
  reaction. Both are consumers of this feed — the hook is `peek_since()` filtered to
  `level_up` / `bond_milestone`, exactly as the banner does it.
- **Not touched:** candy placement in the world (density lanes), XP awards, the curve, the
  cap, or what a level grants. No new award source was needed.
- **`creature_body.gd`, `follower_creature.gd`, `minimap.gd`** untouched, per the brief.
  The `combat_manager.gd` diff is the single crediting line, so the VFX-hook, companion-
  reaction and `_flee_pressed()` lanes merge cleanly.
- The **distance** tick fires once per 250 m rather than on every credit; without that the
  strip would flicker continuously, since distance is credited in fractions of a metre on a
  half-second poll. Tunable in `progression_feedback.json`.

## 7. Commits

Branch `ralph/W13-PROGRESSION-FEED-0904`, pushed.

```
36381450  docs: D74 — unordered bond ladder and one progression feed
9f573f13  feat: progression feed core — xp/level/bond events from one source each
14919605  audio: level_up and bond_milestone cues for the progression feed
17795e4f  feat: progression presenters — strip ticks, moment banner, Team screen tasks
a64d4144  test: smoke_progression_feedback — the four bond actions and the banner
7ebc4608  docs: CURRENT_STATE CL-W6 rewritten; progression capture tool
94a84c5f  docs: W13-PROGRESSION-FEED report and round-1 contact sheet
aea5887b  fix: round-2 blind-judge defects — banner collision, strip overflow, tick plate
14f4c84c  fix: round-2 judge — banner chrome per kind, level-up headline, bond pip
```

**Head of branch: `14f4c84c`.** Pushed to `origin/ralph/W13-PROGRESSION-FEED-0904`.
