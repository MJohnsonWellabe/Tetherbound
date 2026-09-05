# W10-TRAINER-RULES — report

Branch: `ralph/W10-TRAINER-RULES-0904`, from `origin/main` at `ef16544f`.
Scope: CL-W5(a), CL-W5(b), CL-W4 — the owner's 2026-09-04-B amendments A-2,
A-1 and A-4.

## What a player sees differently

**A beaten trainer stops advertising a fight (A-2, the confirmed defect).**
Before this branch every trainer in the chapter went on offering
`Challenge <name>` forever. The fight was already refused —
`encounter_director.gd::can_challenge()` returns false once the defeat flag is
set — so the prompt was advertising a button that would not work, which is the
thing `interactable.gd`'s own header calls worse than no prompt at all. A
beaten trainer now reads `Greet <name>`: still a person you can walk up to and
get a word out of, no longer an offer of a fight that will not happen.

The defect lived in a gap, not in a function. `interactable.gd` resolves its
label once, at build time, and stores the string — so a `prompt_for()` that
returns the right answer proves nothing about what the player sees. The fix is
therefore in two halves: `prompt_for()` reads `prompts.defeated`, and
`trainer_npc.gd::_process()` relabels an already-placed body on the frame the
defeat flag flips, gated on `progression.revision` so an ordinary frame costs
one integer compare. A world built from a loaded save (trainers beaten before
any body was placed) shows the right labels on its first frame.

Neither wording contains "talk" or "choose". `tests/smoke_opening.gd` finds
Grandpa by exactly `_find_interactable_matching(["grandpa", "talk"])` over
**every interactable in the world**, so the obvious wording — "Talk to
<name>" — would let a beaten trainer anywhere in the Meadows win that match
and make the opening smoke fail for a reason nothing about the opening
changed. Proved, not assumed: see BREAK 2 below.

**You cannot walk out of a trainer fight (A-1).** Both disengage bindings
(`combat_run` on Escape, `creature_recall` on RB) are refused during a fight
against somebody else's creature, and the player is told why —
*"You can't walk away from a challenge."* — through the same one-shot toast
`_refuse_combat_input()` already answers a dead combat button with. A **wild**
fight keeps its exit exactly as it had it, so no player is ever sealed into an
encounter they did not accept. Total-party faint remains the only other way
out and is unchanged. `_enemy_owned` (R8.1) is the flag, so "whose creature is
this" is still asked once, in one place.

**A trainer can refuse in character on level (A-4) — mechanism only.** A
trainer row may carry an optional `min_level` (`challenge_level` is accepted as
an alias). While the party's highest-level creature is under it,
`can_challenge()` is false for a **fifth** reason, and the trainer opens the
shared `trainer_too_low` conversation carrying the owner's own wording —
*"You're too low level. I'll crush you and send you crying to Grandpa."* —
with the required level filled into `$level` so the refusal names what would
change it. There is no menu error and no greyed button. A too-low player hears
the taunt, never the already-defeated line: that branch is ordered above the
other refusals for exactly the collapse the dark-features T1 note warns about.

**No shipped trainer carries a `min_level`.** Deliberate, and pinned by a test:
`docs/FINISH_THE_MEADOWS.md`'s own stated dependency is that wild density lands
before a level gate goes on the route, or the gate becomes the wall D-0904B-4
says it must not be.

## Files changed

| File | Change |
| --- | --- |
| `scripts/world/trainer_npc.gd` | `prompt_for()`, `required_level()`, `party_high_level()`, `below_challenge_level()`, `TOO_LOW_CONVERSATION`; `_process()`/`_refresh_prompts()` relabel placed bodies on a progression revision bump; `_on_challenged()` reordered so "already beaten" is checked before the two refusals |
| `scripts/combat/combat_manager.gd` | `FLEE_REFUSED_MESSAGE`, `can_flee()`, `try_flee()`, `flee_refusal()`, `_refuse_flee()`; `_read_player_input()` routes the disengage press through `try_flee()` |
| `scripts/combat/encounter_director.gd` | `can_challenge()` gains the fifth reason; `too_low_to_challenge()` sibling query |
| `data/config/trainers.json` | `prompts.defeated` is now read; the `min_level` schema documented |
| `data/dialogue/trainers.json` | shared `trainer_too_low` conversation |
| `docs/decisions/D79-…-highest-creature.md` | the gate measures the party's highest level, and why not the deployed one or an average |
| `docs/specs/MEADOWS_PROGRESSION_SPEC.md` | one paragraph under **Gate 1 — South Bridge** |
| `docs/CURRENT_STATE.md` | the trainer-rules row, rewritten with verified counts |
| `tests/test_trainer_rules.gd` | new, 15 tests |
| `tests/smoke_trainer_battle.gd` | the three rules checked against a real world |

## Tests and smokes — exact commands and counts

Godot 4.7-stable, installed per COMMON.md. Every command prefixed
`export PATH=$HOME/godot-bin:$PATH`.

| Command | Result |
| --- | --- |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_trainer_rules.gd` | **15 tests, 214 assertions, 0 failed** |
| `… --only=test_trainers_data.gd` | **50 tests, 1386 assertions, 0 failed** |
| `… --only=test_encounter_combat_override.gd` | **5 tests, 22 assertions, 0 failed** |
| `… --only=test_combat_progression.gd` | **18 tests, 45 assertions, 0 failed** |
| `… --only=test_fainting.gd` | **12 tests, 34 assertions, 0 failed** |
| `… --only=test_player_death.gd` | **7 tests, 11 assertions, 0 failed** |
| `godot --headless --path . --script tests/smoke_trainer_battle.gd` | **exit 0** — OK |
| `godot --headless --path . --script tests/smoke_opening.gd` | **exit 0** — "talked, chose, named, and the creature is in the party" |
| `godot --headless --path . --script tests/smoke_trainer_no_usable_ally.gd` | **exit 0** — OK |
| `godot --headless --path . --script tests/smoke_tournament_bracket.gd` | **exit 0** — entered, lost, retried, three rounds fought, won |

`test_trainers_data`, `test_encounter_combat_override`, `smoke_opening`,
`smoke_trainer_no_usable_ally` and `smoke_tournament_bracket` were green first
attempt. `smoke_trainer_battle` was not — see the finding below.

Error grep on every smoke log (`^ERROR:` **and** `SCRIPT ERROR`, per
AGENT_WORKFLOW §"a narrower grep silently passes those"):

| Log | `SCRIPT ERROR` | distinct `^ERROR:` |
| --- | --- | --- |
| `smoke_trainer_battle` | 0 | `Parameter "material" is null.` ×1 |
| `smoke_opening` | 0 | `Parameter "material" is null.` ×2 |
| `smoke_trainer_no_usable_ally` | 0 | none |
| `smoke_tournament_bracket` | 0 | none |

That line is the documented known-benign one (`docs/AGENT_WORKFLOW.md` lines
125–133: it comes off alpha creature builds, and its **count** is explicitly
not the bar — 1, 2, 2 and 3 were observed across four runs of near-identical
trees). The distinct set did not grow.

## Runtime validation — what was actually driven

`smoke_trainer_battle` on the real `meadows_playground` scene, not a fixture:

```
prompt before the fight: 'Challenge Bryn'
challenge took 3 presses; conversation opened and closed
disengage refused on both bindings: 'You can't walk away from a challenge.'
throw refused: 'You can't catch a trained creature'
battle over after 879 action frames; 2 of the trainer's 2 creatures felled
defeat flag 'trainer_defeated_practice' set
prompt after the fight: 'Greet Bryn'
re-challenge refused; the trainer greets instead
re-challenge granted nothing; the reward paid exactly once
```

Both prompt reads come off the **live `Interactable`** (`prompt_node().label`),
not off the static reader — the whole defect lived in the gap between the two.
Both disengage presses are real `Input.action_press()` presses delivered
mid-fight; the fight is still running and `trainer_battle_active` still true
after each.

The faint-out exit A-1 leaves in place is verified by
`test_combat_progression.gd::test_trainer_fight_still_ends_once_the_whole_party_has_fainted`
(green above), which drives `_handle_active_faint()` against a bare manager
with `_enemy_owned` set and asserts the fight reaches `RESOLVING` with outcome
`"lost"`. The tournament's post-loss retry is verified by
`smoke_tournament_bracket`'s own lose-and-retry beat.

## Every new behaviour seen red

Twelve separate breaks, each restored immediately, each failing for the right
reason. Nothing here passes by reading a script's source text.

| # | Break | Went red |
| --- | --- | --- |
| 1 | `prompt_for()`: `beaten := false` (the original defect, restored) | `test_a_beaten_trainer_stops_offering_the_challenge` |
| 2 | `prompts.defeated` = `"Talk to %s"` | `test_no_trainer_prompt_can_be_mistaken_for_grandpa_or_a_starter` — *"trainer 'practice_trainer' offers 'talk to bryn'"*, and again for `trainer_mira` |
| 3 | `can_flee()` → `true` | `test_a_trainer_fight_cannot_be_left`, `test_a_refused_disengage_says_why` |
| 4 | `can_flee()` → `false` (the over-correction that would seal a wild fight) | `test_a_wild_fight_can_still_be_left` |
| 5 | `below_challenge_level()` → `false` | `test_a_level_condition_refuses_a_party_below_it` |
| 6 | `party_high_level()` reads the **first** party slot | `test_the_gate_reads_the_highest_creature_not_the_first_or_the_average`, `test_a_level_condition_refuses_a_party_below_it` |
| 7 | `required_level()` drops the `challenge_level` alias | `test_challenge_level_is_accepted_as_an_alias` |
| 8 | the taunt loses `$level` | `test_the_too_low_line_exists_and_says_what_the_owner_asked_for` |
| 9 | `prompt_for()` returns `""` | `test_a_beaten_trainer_still_offers_something`, `test_an_unbeaten_trainer_still_offers_the_challenge`, `test_a_beaten_trainer_stops_offering_the_challenge` |
| 10 | `min_level: 7` authored on a shipped row (`practice_trainer`) | `test_no_shipped_trainer_carries_a_level_condition_yet` |
| 11 | the null-party guard removed from `below_challenge_level()` | `test_a_scene_with_no_party_invents_no_gate` |
| 12 | `TOO_LOW_CONVERSATION` = a shipped trainer's `defeated` id | `test_the_too_low_line_is_not_the_already_beaten_line`, `test_the_too_low_line_exists_…` |

All fifteen tests in the file appear in that table. `git status` was clean of
every break before the green run above.

## The one real finding this verification pass exposed

`smoke_trainer_battle` **failed on its first run here**, reporting both
disengage bindings *"refused silently"* — the fight survived, but the HUD said
nothing. That is exactly the shape a broken rule would take, so it was
instrumented rather than retried: a temporary print in
`combat_manager.gd::_tick_active()` produced

```
[DIAG] disengage pressed INSIDE the input guard, guard=0.08333333333333
[DIAG] disengage pressed INSIDE the input guard, guard=0.06666666666667
```

`_tick_active()` skips `_read_player_input()` entirely for
`combat.json::flow.input_guard` (0.25 s) at the start of a fight — engage and
charged attack are the same physical button, and without that guard the press
that *opens* a fight is read as the first attack of it. The check ran
microseconds after the challenge, so `Input.action_press()` was released again
before `_flee_pressed()` was ever called. **No button was ever delivered**, and
the smoke read "no message" as a silent refusal.

The fix is in the smoke, not the product: wait the guard out before pressing,
with the duration read from the same config the manager reads rather than a
hard-coded frame count, so retuning the guard cannot leave it waiting too
little. The previous commit on this branch (clearing the toast before reading
it — `_throw_pressed()` also reads `interact`, so the challenge's own presses
left a stale sentence on a label `playground_hud.gd` hides on a timer without
clearing) was necessary too, and stays; it was simply not sufficient, and was
pushed without a passing run behind it. Both together are what makes the
in-world half of A-1 real evidence.

A retry would have turned this green by accident on some runs and hidden a
smoke that pressed nothing. It is recorded here as a finding, per COMMON.md.

## Deliberately not done

- **The brief's "hide the disengage glyph from the combat legend for trainer
  fights" is a no-op against today's code, and no legend was invented for it.**
  `combat_hud.gd` draws four verb cells — quick, charged, throw, switch
  (`_draw_quick_cell`/`_draw_charged_cell`/`_draw_throw_cell`/`_draw_switch_cell`)
  — and no disengage cell; the only other glyphs it draws are throw/cancel
  inside the orb cluster during an aim. `playground_hud.gd`'s persistent
  exploration legend, which *does* carry a `creature_recall` entry, is hidden
  for the entire fight (`_exploration_legend_should_show()` returns false while
  `_combat_is_running()`). Nothing on screen advertises the disengage button
  during a fight, so there was nothing to hide. **If a later lane adds a fifth
  verb cell for disengage**, the guard belongs in `_draw_cells()` beside the
  existing `switch_ready` pattern, reading `_manager.call("can_flee")` — the
  accessor exists and is public for that reason.
- **No `min_level` authored on any trainer**, per the brief and
  `docs/FINISH_THE_MEADOWS.md`'s dependency. `test_no_shipped_trainer_carries_a_level_condition_yet`
  fails the moment one appears, which is the intended tripwire for the density
  lane, not a permanent rule.
- **No `quest_log.gd` hint.** The brief made it conditional ("if `quest_log.gd`
  can carry a hint cheaply … otherwise put the level in the taunt"). The taunt
  names the level through `$level`, which satisfies the remedy half of
  D-0904B-4, and `quest_log.gd` is outside this lane's ownership list.
- **`tests/test_trainer_rules.gd.uid` is not committed.** Godot generates it on
  import; nine other recently-added test scripts in the tree have no tracked
  `.uid` either (231 tracked `.uid` against 240 `tests/*.gd`), so this matches
  the repo as it stands rather than adding a file the landing lane would have
  to reconcile.
- **`git add -A` was not used.** `godot --import` regenerates `.import`
  sidecars and extracts ~20 MB of GLB textures for assets belonging to other
  lanes; those paths are in `.git/info/exclude` locally and none of them are on
  this branch.
- The full 134-file unit suite (~28 min) was not run: the brief names its
  tests, and the coordinator's CI runs the suite on push.

## Known limitations

- The level gate ships **unexercised in a real world** — nothing authors a
  `min_level`, so no smoke walks a too-low player up to a trainer and hears the
  taunt. The unit tests cover the decision and the conversation's contents; the
  in-world path (`_on_challenged()` → `too_low_to_challenge()` → panel
  `set_value("level", …)`) is exercised only when the density lane turns a row
  on. That is the ordering the brief and `FINISH_THE_MEADOWS.md` both asked
  for, but it means the first authored `min_level` is the first real test of
  that branch.
- `_process()` polling `progression.revision` is one integer compare per frame
  per placer instance with a body (`_placed == 0` returns immediately). It is
  the same polling idiom `playground_hud.gd` already uses, but it is polling.
- `smoke_opening`'s Grandpa matcher is `["grandpa", "talk"]`; the "choose"
  half of the trap the brief names is **not** in that file today (starters are
  matched by provider identity, not by label substring). The guard test checks
  both words anyway — cheap, and it stops the trap coming back.

## Landing

Branch `ralph/W10-TRAINER-RULES-0904`.

Last commit carrying code or data: **`8264cc9d`** (`smoke_trainer_battle`: wait
out the input guard) — that is the tree every count above was measured against.
The two commits after it are documentation only: `f5ec355e` (this report and the
status row) and the amendment stamping this line, which is the branch head.
Verify with `git log --oneline origin/main..origin/ralph/W10-TRAINER-RULES-0904`.

Full branch, oldest first:

```
1983309f  trainers: the three rules
9bbf1935  trainers: runtime checks, spec paragraph, decision record, status row
2449216e  chore: drop import artefacts this lane never owned
20f05182  docs: report skeleton
505ae5e4  smoke_trainer_battle: clear the toast before reading it
7b710d05  docs: renumber the lane's decision record D74 -> D79
8264cc9d  smoke_trainer_battle: wait out the input guard before pressing disengage
f5ec355e  docs: report, and the status row rewritten with verified counts
```

No PR opened; the landing lane owns that.
