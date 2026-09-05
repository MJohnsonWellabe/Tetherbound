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
| `docs/decisions/D83-companion-reactions-are-procedural-over-the-model-pivot.md` | The three design calls this lane made. |
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
D83 records this and the two other calls in full.

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

All five the brief names, each run whole, one at a time:

```
godot --headless --path . --script tests/smoke_creature_control.gd
godot --headless --path . --script tests/smoke_combat.gd
godot --headless --path . --script tests/smoke_catching.gd
godot --headless --path . --script tests/smoke_gate_a_rest_torch.gd
godot --headless --path . --script tests/smoke_riding.gd
```

| Smoke | Exit | What it reported | Distinct `ERROR:` lines |
|---|---|---|---|
| `smoke_creature_control` | 0 | "dismissed, recalled, swapped, and refused mid-fight" | `Parameter "material" is null` x1 |
| `smoke_combat` | 0 | "a fight can be entered, piloted, won and left" | none |
| `smoke_catching` | 0 | "a throw can be aimed, missed, and landed" | `Parameter "material" is null` x1; `4 resources still in use at exit` x1 |
| `smoke_gate_a_rest_torch` | 0 | "Gate A rest/torch smoke passed", including a real creature-bed rest, which is the camp state's own fixture | `Parameter "material" is null` x1 |
| `smoke_riding` | 0 | "saddled, mounted, ridden, dismounted, and refused when it had to be" | `Parameter "material" is null` x2 |

`Parameter "material" is null` is the known-benign line
`docs/AGENT_WORKFLOW.md` section 6 documents by name, together with the warning
that its *count* varies with how many alpha creatures streamed in and must not
be the bar. The distinct set did not grow.

`4 resources still in use at exit` in `smoke_catching` is an exit-time message
printed after the smoke had already reported its pass. **It is pre-existing
noise, not this lane's**, and that was established rather than assumed: a
`git worktree` at `ef16544f` was imported and the same smoke run twice on each
side.

| Run | `material is null` | `4 resources still in use` | `No vertices were added` |
|---|---|---|---|
| branch, run 1 | 1 | **1** | 0 |
| branch, run 2 | 1 | **0** | 4 |
| `main` `ef16544f`, run 1 | 0 | **0** | 0 |
| `main` `ef16544f`, run 2 | 0 | **1** | 2 |

The message appears once on each side and is absent once on each side. Every
one of these lines varies run to run on unmodified `main`, which is exactly
what `docs/AGENT_WORKFLOW.md` section 6 warns about when it says the count is
not the bar and the distinct set is. All four runs reported
`catching: OK — a throw can be aimed, missed, and landed.`

`smoke_combat` is the one that matters most of the five. The victory hook is a
call inside `_begin_resolve()`, on the path every won fight takes, and that run
produced **no `ERROR:` lines at all**.

---

## 6. Frames and the blind verdicts

Three moments, each shot as a **pair** from one fixed camera a fixed interval
of reaction apart, in the real Meadows with the real deployed follower, by
`tools/_capture_companion_moments.gd` under xvfb at 1280x720 on the
Compatibility renderer. A pair rather than a single still because that is the
one thing a still cannot answer on its own: a creature mid-idle and a creature
mid-reaction photograph identically. The tool prints the measured pixel
difference between each pair's halves, so "it is moving" is a number.

Both rounds were judged by a **code-blind** sub-agent given only the frames,
`docs/reference/` and the visual-judge skill, and told nothing about what had
changed or what the answer should be. Both verdicts are worth reading; the
second is harsher than the first and is the more useful of the two.

### Round 1 (`_sheet.png`)

| Pair | Pixels differing across 0.35 s |
|---|---|
| acknowledgment | 8.97 % |
| hurt | **0.00 %** |
| camp | **0.00 %** |

The verdict, in its own words: **acknowledgment was "the only pair where the
creature is doing something situational"** — a legible head turn onto the
trainer — and the acceptance criterion asks for exactly one such moment. It
then named two defects and one instrument defect, all three real:

1. **hurt read as "lying down, resting, or nosing at something on the
   ground", not injured.** An 11 degree pitch on the model pivot tips the
   whole animal nose-down, which is a crouch.
2. **camp read as "companion following player, standing still".** 0.45 of the
   species rest roll is a 20 degree tilt, not a lying pose. The campfire was
   also behind the camera, "a two-centimetre sliver of orange... cropped by
   the HUD".
3. **the hurt and camp pairs were pixel-identical.** The pause that makes a
   sub-second pose photographable also stops the idle, so the instrument could
   only ever show life in the states that move the pivot. "A 2.5m animal held
   perfectly rigid while the grass in front of it animates reads as a prop."

### Round 2 (`_sheet_round2.png`), after acting on all three

| Pair | Pixels differing across 0.35 s | Round 1 |
|---|---|---|
| acknowledgment | 9.67 % | 8.97 % |
| hurt | **13.18 %** | 0.00 % |
| camp | 7.29 % | 0.00 % |

The instrument defect is fixed and measured: the idle now advances between
exposures at the layer's own speed scale, which the log records as `x1.00`
walking, `x0.78` hurt and `x0.50` at camp. The campfire is in the shot.

**And the round 2 critic found a real bug my round 2 change introduced**,
which is the single most valuable thing either judge produced:

> "the creature is half inside the hillside... what is on screen is a head and
> a paw lying detached in a meadow"

Deepening the camp roll exposed a sign error in how a rolled pose is grounded.
Rolling a body either way dips its lower corner by about a radius, so the
correction is a **lift in both directions** — `+radius * |sin(roll)|`. Written
signed, a negative roll turns that lift into a dip, and terrapup's own
`rest_roll_deg` is **-45**, so at 0.85 of it the pivot fell **0.75 m of a
2.3 m animal**. Fixed in commit `5eaa4e07`, pinned by a test that was seen red
at exactly that 0.75 m.

**`creature_body.gd::play_rest()` carries the same signed form** for the
creature-bed pose, so the two negative-roll species (terrapup, trailpup) have
the same latent dip when they sleep in a bed. That file is outside this lane's
ownership list and was not touched. **Routing note for the coordinator.**

### What the judges say is still not solved

Round 2, on the hurt state: it reads **alert, not injured** — ears erect, eye
wide and bright, head level with the shoulder line, no limb favoured, and the
party strip still showing a full green health bar in the same frame. This is
an honest ceiling and the rig inventory explains it: there is no wince, no
limp, no pant, no closed-eye clip and no facial rig anywhere in the roster, so
the hurt state is carried by a slower gait and a periodic flinch — **both of
which are motion, and a still frame cannot show either.** The 13.18 % pair
difference is the only evidence of them available in this medium.

Round 2 also lists a long tail of environment findings that are **not this
lane's** and are not claimed as such: no cast shadows under creature or
trainer, no landmark on any horizon, one repeated sapling for a tree line,
a non-animating campfire flame that emits no light, a flat-lying flower
instance, a terrain splat seam, and a party-strip panel too transparent to
read against grass. Those belong to the world, lighting and HUD lanes; they
are recorded here because the frames are the evidence for them.

---

## 7. Known limitations and what was deliberately not done

### Untracked files this lane deliberately did not commit

`godot --headless --path . --import` (which COMMON.md instructs every lane to
run once) generates 58 import artifacts that are untracked on `main`:
34 `.import` sidecars, 7 extracted textures and 17 `.uid` files. They belong
to the pickup-art lane's assets (candy, mushroom, potion, revive flower,
saddle, bridge, signpost) and to other lanes' new scripts. **None are this
lane's work**, and committing them would put another lane's binaries on this
branch and hand its owner a conflict. Left untracked; the coordinator should
expect them from any lane that imports, and they regenerate on demand. This
is the "a file outside your ownership list" case COMMON.md says to report
rather than touch.

### Limitations of the feature itself

**The continuous claim is not evidenced.** Addendum section E asks that "a
continuous play segment with one creature produces multiple contextual
companion moments naturally". Every capture here **stages one moment at a
time** — it stands the trainer still, sets HP, builds a fire. That proves each
state fires on its real trigger, and proves nothing about frequency or feel
across twenty-five minutes of actual play. `smoke_gate_b_continuous` drives
that segment and does not look at the companion. Closing this honestly needs
the layer's own counters read at the end of a continuous run, which is a
follow-up, not a claim to make now. `docs/CURRENT_STATE.md` says so in its row.

**Hurt cannot be made unambiguous in a still with this roster.** See section 6:
no wince, limp, pant or facial rig exists on any of the 21 rigs. What is left
is a slower gait and a periodic flinch, both of which are motion.

**The reactions are not tuned by anyone who has played the game.** Every
number in `data/config/companion_presence.json` is a first estimate, chosen
conservatively so reactions stay rare. An owner note that the creature reacts
too often, or too rarely, is a config edit and needs no code.

**No audio.** The rigs have no vocal cues wired to these states and
`data/config/audio.json` was not touched. The owner directive mentions
reactions, not barks, and explicitly warns against constant barking, so this
was left alone deliberately rather than guessed at.

**Bond milestones are polled, not pushed.** Until the progression feed lands,
the layer compares `bond_nodes()` against the last value it read, keyed to the
creature it read it from. That catches a milestone within a frame of it
happening and cannot celebrate a party swap or a loaded save, but it is a poll.
`on_event("bond_milestone")` is the hook to call instead; the poll becomes
redundant and deletable the day it does.

**Only the deployed creature reacts.** The four benched party members have no
body in the world, so there is nothing to animate. This matches the directive,
which is about "the active/deployed creature".

### What was deliberately not done

- **No progression feed.** Prompt 73 assigns it to another lane on
  `autoload/game_state.gd` and says explicitly: "Provide the hook; do not build
  them here." A hook is provided; nothing on `Game` was touched.
- **No new meshes, no Meshy generation, no new clips.** `CLAUDE.md` forbids all
  three for the Meadows, which is why the layer is procedural. See D83.
- **`creature_body.gd`, `combat_hud.gd` and `party_strip.gd` untouched**, per
  the brief's ownership list — including the latent `play_rest()` sign issue in
  section 6, which is reported for routing rather than fixed here.
- **The environment findings in round 2's verdict were not acted on.** Cast
  shadows, tree variety, horizon landmarks, campfire light emission, terrain
  seams and HUD panel opacity are other lanes' files.
- **No second creature or NPC staged in the capture frames.** Round 2 notes the
  world reads empty next to the Palworld bar. True, and it is a world-density
  finding, not a companion-presence one; staging extras to flatter the frames
  would have made the evidence worse, not better.
