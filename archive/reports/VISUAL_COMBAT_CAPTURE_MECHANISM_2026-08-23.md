# The combat capture's missing moments: mechanism, established from source

VIS-MAKE lane, 2026-08-23. Written **before any fix**, because the round-1
report explicitly refused to record its own headline as a game defect until
somebody established which of two opposite things was true.

## The claim under investigation

> *"02-move-firing-clean is titled as the firing moment, and there is no firing
> in it. No projectile, no launch effect, no dust, no attack pose... Put 01, 02
> and 03 clean side by side and they are the same still life three times."*

Either the fight has no visual event in it (devastating), or the camera opened
its shutter after every visual event had finished (a harness failure, and this
sweep's seventh). These need opposite work.

## Verdict

**Harness failure. The seventh.** Every element the critic looked for is built,
wired, and fires in a real fight. None of them can survive to this harness's
shutter, and the reason is arithmetic rather than timing luck: **the harness
cannot photograph any sub-second event at all**, and every visual event in a
Tetherbound fight is sub-second by design.

Nothing in the round-1 combat critique's headline should be actioned as art or
gameplay work. The frames were honest; the labels on them were not.

## What was searched, and what is there

Searched `scripts/combat/`, `scripts/creatures/`, `data/moves/moves.json`,
`data/config/combat.json`. Found, all present and all referenced from the live
fight:

| Element the critic missed | Where it lives | Wired at |
|---|---|---|
| Projectile / bolt travel | `scripts/combat/move_projectile.gd` | `combat_manager.gd:33` (`PROJECTILE`) |
| Impact burst | `scripts/combat/impact_flash.gd` | `combat_manager.gd:28` (`FLASH`) |
| Wind-up telegraph ring | `scripts/combat/telegraph_glow.gd` | `combat_manager.gd:29` |
| Attack pose | `creature_body.gd:841 play_attack()` | `combat_manager.gd:912, 981` |
| Hit reaction / flinch | `creature_body.gd:846 play_hit()` | `combat_manager.gd:666, 1001` |

These are not stubs. `impact_flash.gd`'s header records the pixel measurement
that caused it to be built (10 warm pixels at contact versus `palworld-01`'s
24,623) and `telegraph_glow.gd` was built against an earlier critic's "the
wind-up frame is indistinguishable from standing". **The combat presentation
work a critic would ask for has already been done.** This capture photographed
the world after it finished.

## The mechanism

`project.godot` sets no physics overrides, so Godot's defaults hold: physics at
**60 Hz**, `max_physics_steps_per_frame` **8**. Under llvmpipe at 1280x800 one
rendered frame costs **~2.4 s** (the corridor survey's measured number, which
this tool's own header quotes).

That gives the two clocks wildly different exchange rates:

- **One rendered frame = 2.4 s of `_process` time** — `_process(delta)` is
  handed the real frame delta.
- **One rendered frame = at most 8 physics ticks = 0.133 s of simulated time** —
  physics is capped, so simulated time runs ~18x slower than wall clock.

Now the shutter. `_shoot_pair()` waits `RENDER_SETTLE_FRAMES = 2` **process**
frames before it takes the HUD shot, and two more before the clean shot. So the
earliest any shot can land is **~2 rendered frames after the moment**, which is
**~4.8 s of `_process` time**. That is the floor, and it applies to every shot
this tool takes.

Against that floor:

**The projectile — dead before frame 1.** `move_projectile.gd` runs on
`_process` (line 103) and clamps its whole flight to `MAX_TRAVEL = 0.42 s`. Its
first `_process` tick adds ~2.4 s, so `t = 2.4 / 0.42 = 5.7`, clamped to 1.0 —
it emits `arrived`, calls `queue_free()`, and is gone on the first rendered
frame after launch. The capture then waits `PROJECTILE_INFLIGHT_FRAMES = 6`
physics ticks and two process frames on top. **The node has been freed for
roughly two rendered frames before the shutter opens.** No wait value could
have saved it; `_shoot_pair`'s own two-frame settle already outlives it.

**The attack pose and the flinch — same clock, same outcome.** No
`callback_mode_process` is set on any creature `AnimationPlayer`, so Godot's
default applies: animation advances on the **idle/render** clock. Any attack or
hit clip shorter than 2.4 s therefore runs start to finish inside one rendered
frame. `creature_animator.gd` resolves real clips (`Armature|Frog_Attack`), and
they are ordinary length. The pose is real; it is over before the frame it
started in is presented.

**The impact flash — dead by a narrower margin, but dead.** This one is already
on the right clock: `impact_flash.gd:145` is `_physics_process`, for exactly
this reason, and its own line 136 says so ("a 0.26-second effect driven by
`_process` is gone inside a single frame"). Its duration is 0.34 s = ~20 physics
ticks. But the capture waits `IMPACT_SETTLE_FRAMES = 20` physics ticks before
shooting — landing precisely at the end of the burst's life — and then
`_shoot_pair` adds two process frames (~16 more ticks) on top. **The flash
expires during the settle wait it was supposed to be caught in.**

So: three different reasons in the source, one shared cause in the harness. The
critic's "same still life three times" is exactly right as an observation and
exactly wrong as a conclusion.

## The empty TEAM panel

Also a capture artifact, and a separate one. The tool grants its creature with
`encounter_director.adopt_starter()` (`_ensure_ally()`, line 271), because
`sequence_director.gd` suspends the sandbox's automatic starter. But
`adopt_starter` → `_spawn_ally_body()` only builds `_ally` and `_ally_body`; it
**never calls `Game.party.add()`**. The real opening does, at
`sequence_director.gd:1209`.

So the captured state genuinely has a pilotable creature and a genuinely empty
party roster, and the HUD's five OPEN SLOT rows are the HUD telling the truth
about a state no player can ever be in. Not a defect; the frame is just not of
the game.

## The one real source finding

`move_projectile.gd` is the **only** one of the three effect scripts still on
`_process`. Its two siblings were both deliberately moved to `_physics_process`
and both left comments explaining why. The projectile was left behind, and this
tool's own header (lines 64-77) already predicted the consequence and called it
"a source fix, not something this photographer can wait or re-aim its way
around."

On real hardware this is invisible — 0.42 s at 60 fps is ~25 frames of bolt, and
physics runs at 60 Hz there too, so moving it changes nothing a player sees. It
is a consistency fix that makes the effect survivable under software rendering,
which is where every visual verdict on this project is actually made.

## What this changes about the work

- **Do not** add projectile VFX, impact VFX, attack animation or hit reactions.
  They exist. Building them again would be the second time this sweep spent
  findings on a photograph of the wrong instant.
- **Do** fix the harness so it can answer its own question, and fix the
  projectile's clock so it is consistent with its siblings.
- The remaining round-1 combat findings — the camera framing the piloted
  creature's rear while the enemy is a 40px speck, the danger telegraph stamped
  on the player creature's own occluded back shell, the keyboard glyphs on a
  controller-first title — **stand**. None of them depend on catching a
  sub-second moment, and all of them are visible in a still of a settled fight.

## Still open

`05-trainer-battle` needs an empirical answer rather than a derived one. The
tool returns before shooting if `is_fighting()` is false (line 481), so a frame
existing means a fight was open — but the critic saw an idle NPC and a stale
"You backed off." toast. That is not explained by the clock arithmetic above and
is being resolved by re-running the capture and reading its own FAIL lines.

---

# Empirical confirmation — re-run with the harness fixed

The capture was re-run after the two fixes above (`_shoot_pair` pauses the tree;
`move_projectile.gd` moved to the physics clock). **418 frames, 8 shots written,
0 shots failed.** The derived mechanism holds, and the frames now settle three
of the four open questions outright.

## 1. The impact flash: harness failure, PROVEN

`03-hit-landing-clean.png` now shows the burst — a warm gold ring with radial
streaks at the exact point of contact between the piloted creature's head and
the bramblebun. Same scene, same move, same renderer as round 1, which reported
this frame as an identical still life to 01 and 02.

Nothing about the game's impact VFX changed. Only the shutter did. **Round 1's
"no impact" was a photograph of the wrong instant**, exactly as the arithmetic
predicted, and `impact_flash.gd` has been doing its job the whole time.

The tool now also prints `03-hit-landing: impact flash present after 1 ticks`
before it fires, so no future round has to take this on trust.

## 2. The projectile: still not photographed, and the tool now says so

The new self-check fired on the first run:

    FAIL: 02-move-firing is being shot with NO projectile alive in the arena

Moving it to the physics clock was necessary but not sufficient. The reason is
visible in the same log: the impact flash appeared **one tick later**, so the
bolt had already ARRIVED before the shutter. `MIN_TRAVEL` is 0.06s = 3.6 physics
ticks, and the tool was waiting `PROJECTILE_INFLIGHT_FRAMES = 6` — the fight was
simply at close quarters, and six ticks overshot a flight that took four.

Lowered to 2, which lands between a tenth and half way across at every distance
the arena allows. Worth stating plainly: **this frame is not yet verified.** The
FAIL line is the harness working, not the harness fixed.

## 3. The empty TEAM panel: confirmed a capture artifact, and closed

`adopt_starter()` never calls `Game.party.add()`; the real opening does, at
`sequence_director.gd:1209`. The capture now registers the starter it grants, so
the HUD frames stop showing five OPEN SLOT rows in a fight the player is
winning. Round 1's critic read that panel correctly — it was reporting a state
no player can reach.

## 4. `04-catching` never opened, and it was not the aim's fault

    FAIL: the capture reticle never opened; 04-catching was not captured

`throw_aim.gd` refuses to open the reticle with an empty satchel, and the
capture had never given the player an orb. The real opening hands over fifteen
(`give:orb_basic:15`). The tool now seeds them the same way every catching smoke
test in the repo already does.

## The finding this run turned from a taste call into a mechanism

Round 1 said the camera "frames the wrong participant... the fight happens
between a large rump and a distant dot." That stands, and this run explains it.
The harness printed the same line in BOTH encounters:

    note: every camera nudge tried toward this target was still blocked by the
    ally's own body

`05-trainer-battle-clean.png` is what that produces. The fight is genuinely open
(`is_fighting()` true, and `enemy_body()` returned non-null — the tool FAILs
loudly when it does not, and did not). **The opponent exists. The camera simply
never gets a view of it**, and the frame is filled instead by the piloted
creature's rear, an idle villager, and the target chevron hanging over empty
ground.

So round 1's "05-trainer-battle names an opponent that is nowhere in the frame"
is **correct as an observation and correct as a defect** — but it is a camera
defect, not a missing opponent and not a battle that failed to start. That is
`scripts/combat/` work, and it is the highest-value thing this lane found:
it is the same root cause as the "large rump and a distant dot" framing, and it
is the reason a Tetherbound fight does not read as an event.

## Still not captured

`06-elite-encounter` was skipped, bounded and loudly, as designed:

    FAIL: nearest wild creature to the elder's spawn is 13m away; likely the
    wrong creature; encounter C skipped

The 13m tolerance is the tool refusing to photograph a creature it cannot prove
is the elder — the correct behaviour given this sweep's history, and a tuning
item rather than a game finding.
