# Shared visible progression feed

Implemented against prompt 73, with the orchestrator's explicit option-2 choice
recorded in `docs/decisions/D-progress-visible-ordered-bond.md`. Bond remains the
same ordered five-task ladder; every action now has immediate feedback, including
tasks completed before their turn. No XP curve, cap, battle reward, creature limit,
save field, evolution rule, or ownership rule changed.

## Mount once

The shared presenter is `res://scripts/ui/progression_feedback_hud.gd`, a
CanvasLayer. `playground_hud.gd` mounts it automatically, so ordinary exploration
uses the same path as combat. A realm using a different HUD mounts it directly:

```gdscript
var progression_hud = preload("res://scripts/ui/progression_feedback_hud.gd").new()
progression_hud.name = "ProgressionFeedback"
progression_hud.configure(Game) # Optional: _ready defaults to /root/Game.
add_child(progression_hud)
```

Do not mount an additional one alongside playground_hud. A tree-wide presenter
group also rejects duplicate mounts defensively. This package does not edit
`cloudreach_world.gd`; its integration lane owns that attachment.

## One source and one presentation queue

`Game.progression_feed` owns a transient queue and revision counter. Only current
party members can publish through `Game.push_progression_event(creature, event)`;
wild/trainer construction and save hydration do not masquerade as earned progress.

- `CreatureInstance.gain_xp` emits one `xp_gained` and, if needed, one `level_up`
  for a multi-level jump. Combat, trainer/Warrens bonuses, and rest automatically
  use that source without adding a second award or level detector.
- Owned-creature `set_level` emits the same kinds for candy, preserving its
  existing exact-level/reset-XP semantics. The XP payload reports the equivalent
  remaining XP required for that level jump. Starter/trainer construction before
  ownership emits no player feedback.
- The bond credit helpers emit `bond_credit`, threshold-crossing `bond_near`, and
  each newly reached ordered `bond_milestone`. Combat now calls that same helper
  instead of silently incrementing the battle counter. Existing feeding,
  exploration/landmark, distance and rest call sites already use these helpers.
- Game bumps party revision on a level transition so normal cached party-strip
  labels refresh after non-combat candy/rest as well as after combat.

Events identify the live creature by runtime instance id, not a potentially
duplicate nickname. They carry the current XP/target/level, real stat deltas,
task counters/target, benefit text and honest trait/evolution readiness. They are
not saved; new-game and load clear old queued presentations without replaying
hydrated levels. The one presenter drains events and distributes the same tick
data to existing PartyStrip instances, including non-active members. CombatHUD's
result XP line now reads the shared recent events, not an independent progression
detector. Its rendered-string tests run the actual builder and include a
disconnected-feed negative control; the old source-grep assertions are removed.

Companion reaction and flourish consumers can read
`Game.progression_feed.since(cursor)` without consuming the HUD queue, then set
their cursor to the current revision. The bounded recent journal contains the
last 256 events. These hooks do not implement a reaction or new shader here.

## Presentation and tuning

`data/config/progression_feedback.json` holds thresholds, durations, safe inset,
font sizes, sound cue ids and the route bonus. Existing installed one-shots are
mapped by two new cue ids in `data/config/audio.json`; no generated audio asset
is required.

The five existing party rows gain an explicitly labelled EXP value and sliver,
labelled Bond node count with small earned/next pips, independent XP/bond
near-progress pulses, and a <=0.9 second attributed
credit line. The overlay does not resize a row or take focus, retains portraits,
and restores ordinary row content when a slot becomes vacant. Ordinary fight proximity uses a tunable single-fight
XP estimate. Moments wait while the production CombatManager is fighting,
then name each affected creature and its real changes. Events within five seconds
combine into one per-creature summary without playing another cue. All five
members remain represented; the passive banner stays within 5% handheld safety.
The revised five-member fixture ends at y310 of an 800-pixel view, above the
central player. Bold names anchor compact gain rows, a team-wide footer avoids
misattributing group gains, and bond milestones state both the automatically
applied stat bonus and the next required shared action.

The existing Team detail scroll panel lists all five task counters, marks the
next required task, explains later completed tasks, gives the next benefit, and
shows species-specific evolution level/bond/catalyst requirements with XP.

## Cloudreach Fly-route credit

`cloudreach_physical_runtime.gd::_on_landed` calls the shared bond helper only
after its real grounded landing, observed-flight, ordered trial gate/duration,
authored destination/approach checks, and a **changed canonical completion event**.
The active owned companion receives the configured 25 m travel-task credit with
source `fly_route`. No new bond task is added. A repeated landing or reloaded
completed event awards nothing. There is no bonus for arbitrary flight or for
simply setting a dialogue flag.

## Verified and still outstanding

- Focused progression/announcement/bond/HUD/Cloudreach-physical/save suites:
  **140 tests, 819 assertions, zero failures**.
- `smoke_progression_feedback.gd`: **29 assertions, zero failures** with the real
  Compatibility renderer at 1280x800. It exercises the actual production combat
  reward method, candy level source, bed completion, bond helpers, shared party
  widgets, combat deferral, cooldown combination and full-five safe-area bounds.
  This is an **isolated UI fixture**, not a complete played wild battle or a
  continuous Meadows route. Its feeding/landmark credits invoke production helpers;
  they are not evidence of selecting a meal or reaching a landmark through input.
- Existing `smoke_cloudreach_physical_runtime.gd`: **36 assertions, zero failures**,
  including actual airborne input/ordered gates/landing, exactly one Fly-route
  bond event, configured bonus amount and refusal to farm a repeated landing.
- Existing `smoke_cloudreach_encounters.gd`: **PASS**, actual trainer interaction,
  production combat, test-only lethal resolution, production rewards/callback and
  reload, with trainer/wild catch permissions preserved.

Rendered captures: `shots/progression-feedback/level-up.png`, `bond-milestone.png`,
`full-party.png`, and `_sheet.png`. The fixture background is deliberately not a
biome acceptance candidate. The first independent UI critique was **Revise**;
the captures have been revised for earned-bond explanation, compact full-party
presentation, stable EXP/Bond labels, attribution and hierarchy. A second blind
UI check returned **Pass for the isolated static interface fixture** (see
`shots/progression-feedback/JUDGE.md`). Preserve its non-blocking follow-ups:
make ordinary bond tick wording more clearly retrospective, replace identical
fallback teal squares with actual production portraits, and confirm the smallest
party sublabels at normal handheld viewing distance. Final defensive checks added
non-intercepting text children, real level-only evolution-readiness presentation,
independent bond-near pips and next-action detail text; the layout/wording judged
in the three milestone captures remains the same. These final checks passed and
the captures/contact sheet were refreshed. Timing, controller access to Team and
moving-world readability still require real world evidence. Final external visual
acceptance and prompt 73's full continuous Meadows fight/feed/landmark/bed route,
Gate B and Gate F S01-S03 remain owning-program evidence, not claimed by these
bounded fixtures.
