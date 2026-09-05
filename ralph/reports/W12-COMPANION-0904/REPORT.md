# W12-COMPANION-0904 — companion presence

Lane brief: `ralph/briefs/0904/W12-COMPANION.md` (on
`origin/claude/codex-merge-meadows-finish-dq12jj`). Source requirements:
`docs/FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md` §E and
`docs/owner/OWNER_DIRECTIVES_2026-09-04-C.md` §5.

Branch: `ralph/W12-COMPANION-0904`, from `origin/main` at `ef16544f`.
Final commit: *(filled in at the end of this report)*.

---

## 1. What a player now sees

The creature walking behind the trainer reacts to what is happening to it
instead of looping one idle. Six situations, each with a cooldown, and every
one of them yields instantly to the game:

- **It notices you.** Stand still for a few seconds and your creature turns,
  walks up to you and dips its head. It also greets you when you send it out.
- **It celebrates a win.** On the beat a fight is won — before the arena is
  torn down — it hops on the spot with a small swell. Past bond node 3 it
  roars with it, and past node 2 it comes to you first.
- **It shows when it is hurt or hungry.** Under 30 % health, or with an empty
  nourishment meter, it trails you at a slower gait with its head low, its
  idle slowed, and flinches every few seconds.
- **It settles at camp.** Standing with you near a lit campfire or a bed, it
  rolls partway onto its side, sinks into the ground a little and idles at
  half speed. It stands straight back up the moment you walk on.
- **It thanks you for care.** Feed, heal or revive it from the satchel and,
  the instant the satchel closes, it comes over: two quick hops for food, a
  slow stretch for a potion, a head shake for a revive.
- **It marks a bond milestone.** Completing a bond node is the biggest
  reaction it has — it comes right up to you, four rising hops and a roar.

Higher bond makes it notice you sooner and more often, and hop higher and
more times, but never unlocks a reaction a new creature does not have.

**None of it can interrupt play.** A fight, an aim, a ride, any menu or
dialogue, a live interact prompt, a cutscene lockout or an armed build ghost
cuts a running reaction on the same frame and restores the pose exactly.

---

## 2. Files changed

New:

| File | What it is |
|---|---|
| `scripts/creatures/companion_presence.gd` | The layer: states, cooldowns, the context guard, bond scaling, procedural pose composition, the head-turn modifier. |
| `data/config/companion_presence.json` | Every threshold, cooldown, distance, duration and amplitude, with the reasoning in comments. |
| `tests/test_companion_presence.gd` | 26 tests over a real rigged follower body. |
| `tools/_capture_companion_rig_inventory.gd` | What clips and bones the installed rigs actually carry. |
| `tools/_capture_companion_moments.gd` | Photographs the three moments in the real Meadows as paired frames. |
| `docs/decisions/D74-companion-reactions-are-procedural-over-the-model-pivot.md` | The three design calls this lane made. |
| `ralph/reports/W12-COMPANION-0904/` | This report, the rig inventory, the contact sheet, the blind verdict. |

Modified (all diffs deliberately small):

| File | Change |
|---|---|
| `scripts/creatures/follower_creature.gd` | Builds the layer as a `Presence` child, ticks it between the follow logic and integration, fires `deploy`, exposes `is_closing()`/`presence()`, multiplies its gait by `gait_scale()`. |
| `scripts/creatures/creature_animator.gd` | Adds `play_if_exists(role)` — play a clip if the rig has one, and say whether it did. |
| `scripts/combat/combat_manager.gd` | **One line** in `_begin_resolve()`: a won fight calls the group at the result beat. |
| `scripts/ui/tab_backpack.gd` | **Three lines**, one in each of the feed, revive and heal branches. |
| `docs/CURRENT_STATE.md` | A companion-presence row, including what is *not* yet evidenced. |
| `docs/GAMEPLAY_SYSTEMS.md` | A companion-presence section under creature care. |
| `.gitignore` | Per-frame `W12-*` captures stay local; the sheet and the verdict are committed. |

Nothing in `creature_body.gd`, `combat_hud.gd` or `party_strip.gd` was
touched, per the brief's ownership list.

---

## 3. The rigs decided the implementation

`tools/_capture_companion_rig_inventory.gd` loaded every model
`data/creatures/species.json` names and printed its clips and bones
(`rig_inventory.txt`, committed beside this report):

> **All 21 unique creature GLBs carry exactly six clips — `attack` (0.96 s),
> `faint` (1.54 s), `hit` (0.54 s), `idle` (3.04 s), `run` (0.79 s),
> `walk` (1.38 s) — and 14–20 bones including `neck` and `head`.**
> The remaining 4 of the 25 species share another species' model.

There is no happy loop, no bounce, no lie-down and no look-around anywhere in
the roster, and every species shares one vocabulary. A clip-driven reaction
layer would therefore have had one usable state for the six the directive
asks for. So the reactions are procedural motion on
`creature_body.model_pivot()` — the pivot the body's own header reserves for
exactly this — composed over the two clips that are reusable (`hit` as a
flinch, `attack` as a roar) with a `LookAtModifier3D` on the `head` bone for
the gaze. Every species gets every state; no new mesh, no Meshy generation.
D74 records this and the two other calls in full.

---

## 4. Tests

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_companion_presence.gd
```

**26 tests, 132 assertions, 0 failed.**

The fixture is real, not a mock of the layer: `scenes/creatures/creature.tscn`
with `follower_creature.gd` on it and the actual terrapup GLB, its
AnimationPlayer and its skeleton built under the pivot; a leader three metres
away; and the layer's own `tick(delta)` driven at a fixed delta, which is the
call the follower makes every physics frame. The guard's witnesses are small
stub nodes read through the real `blocked_reason()` and the real
`input_owner.gd` group, so what is exercised is the shipped guard.

It is detached from any `SceneTree` because `tests/run_tests.gd` has none for
its whole life (the same constraint `tests/test_party_seam.gd` documents).
That forced one change in the layer itself and it is a good one: position
maths, the camp scan and the input-owner lookup now go through helpers that
work with or without a tree, and `_resolve_context()` finds the world by
walking up from the body rather than reading `tree.current_scene` — which is
**null in every `--script` smoke and capture run**, so the guard would have
been unable to see a fight in exactly the runs that verify it.

### Seen red for the right reason

Each behaviour was broken in the shipped file, the suite re-run, and the file
restored. A test that did not go red would have been passing for the wrong
reason.

| Break | Went red |
|---|---|
| `blocked_reason()` returns `""` always (guard disabled) | 8 tests: combat, aiming/riding/prompt/lockout/build, the dialogue release, the satchel wait, both victory tests, the teardown greeting |
| Cooldowns armed to `0.0` | `test_acknowledgment_respects_its_cooldown`, `test_care_respects_its_cooldown` |
| `_hurt` never set | the hurt test, the hunger test, the dialogue-release test |
| Camp sources never count as near | the campfire test, the `companion_camp` group test |
| Bond removed from the acknowledgment delay | `test_higher_bond_acknowledges_sooner` |
| The teardown queues no greeting | `test_a_victory_cut_by_the_teardown_turns_into_a_greeting_on_redeploy` |
| `on_care` accepts any creature | `test_care_for_a_different_creature_is_not_this_creatures_moment` |
| The flinch never plays | `test_low_hp_slows_the_gait_lowers_the_head_and_flinches` |

Three of those breaks initially failed **only one test each when they should
have failed more**, which exposed three tests passing for the wrong reason:
the delay test was measuring the deploy cooldown rather than the still-delay,
the bond comparison never actually crossed a milestone on the creature it
swapped in, and the flinch window could be eaten by an acknowledgment
starting first. All three were rewritten to pace the trainer first and assert
the configured delay and its floor directly (commit `78397003`), and the
break table above is the result after that fix.

---

## 5. Smokes

*(filled in below when the runs complete)*

---

## 6. Frames and the blind verdict

*(filled in below)*

---

## 7. Known limitations and what was deliberately not done

*(filled in below)*
