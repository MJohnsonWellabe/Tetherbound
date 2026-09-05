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
godot --headless --path . --script tests/smoke_progression_feedback.gd     → exit 0, "Progression feedback: OK"
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
per AGENT_WORKFLOW §6). The distinct set did not grow: `smoke_progression_feedback` and
`smoke_tournament_bracket` each show only the known-benign
`ERROR: Parameter "material" is null.` off alpha creature builds; `smoke_combat` shows none.

### Visual

`tools/_capture_progression_feedback_0904.gd` under
`xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver opengl3
--resolution 1280x800`, four frames at 1280×800 over the lightweight HUD scaffold
(`tools/capture_hud_lightweight_0904.gd`'s own approach, for its own reason: the full world
build is 20–50 minutes under software GL and every question here is about the interface's
geometry and colour, not how it composites against grass). Events are pushed through the
real producers, so the frames show what the shipped code draws.

Contact sheet: `ralph/reports/W13-PROGRESSION-FEED-0904/shots/_sheet_round1.png`
(level-up banner, bond-milestone banner, strip mid bond-tick, Team screen).

Measured before the render: the banner plate's crop median luminance **31.6** against the
world band's **103.3** behind it (a 0.31 ratio — a firmly dark plate on a light ground),
with text peaking at **243**. The banner's measured rect is `(510, 184) 900×111` on the
1920-wide canvas, inside the 5% safe area on every edge; the smoke asserts this
independently at runtime.

Blind judge: verdict at `ralph/reports/W13-PROGRESSION-FEED-0904/JUDGE.md`, produced by a
code-blind sub-agent given only the frames, `docs/reference/` and the visual-judge skill,
and told nothing about what changed or what was hoped for.

## 5. Acceptance (prompt 73 §5)

| Bar | Evidence |
|---|---|
| During a continuous segment a player can identify **at least two real actions** that increased bond, inspect progress toward the next milestone, and recognise a milestone without debug data | `smoke_progression_feedback` drives **four** real bond actions (win, meal, landmark, night) and asserts the strip ticked with a distinct, named label for each; the Team screen shows all five counters with one `NEXT` and what is left; a milestone draws the banner with its benefit and a cue |
| Normal combat and candy produce clear, consistent level feedback, and the player can tell how close a creature is to the next level **from the world HUD** | Both go through `gain_xp`/`gain_levels` into the same `level_up` event and the same banner (`test_candy_progression_safety`, `test_progression_feed`); the world HUD creature block reads `196 to Lv 5`, asserted in the smoke, and the strip carries the XP sliver |
| The evidence template for the segment records the two bond actions and the level-up by name | The smoke prints them by name and label; the block is quoted above |
| **Fails if** only the final bond-up becomes visible | Every credit ticks; `bond_near` fires at the configured remaining count |
| **Fails if** a level changes in data and the player must open a menu | The banner is on the world HUD, plus the combat HUD's own line |
| **Fails if** the banner covers combat controls or steals focus | Asserted: hidden and queued during a fight, flushed after; a passive `PanelContainer` on `LAYER_HUD` with `MOUSE_FILTER_IGNORE`, held while any story modal is open |
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
```
