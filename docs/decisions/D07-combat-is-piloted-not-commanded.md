# D07 — Combat is piloted, not commanded

**Status:** accepted
**Decided by:** owner, during M2
**Supersedes:** the command-menu reading of `GAME_DESIGN.md` §14

## The decision

When Combat Mode opens, the player takes over their pal. Camera and controls
transfer from the trainer to the deployed creature. Both fighters move freely
inside a bounded arena centred on where the fight started. Attacks are aimed:
they connect on what is in front of you, within range.

This replaces the original M2 model, in which neither fighter moved and the
player pressed one of five buttons.

## Why

`GAME_DESIGN.md` §14 lists five commands — Quick, Charged, Throw, Run, Switch —
with "no dodge in initial design unless playtest demands it". Implemented
literally that is Pokémon GO's input model in a 3D world, and the M2 plan said
so out loud: *"the live risk is that it plays as a menu with extra steps."*

Building the static version far enough to look at it produced three specific
pieces of evidence, all visible in `shots/combat/`:

1. **The telegraph was fake information.** The enemy winds up, `! incoming`
   appears, and there is nothing the player can do about it. A warning you
   cannot act on is decoration, not a mechanic. Movement is what makes a
   telegraph mean something.

2. **Quick versus Charged was a banking decision, not a tactical one.** The
   charged attack's long wind-up cost only time. Once both fighters move, that
   wind-up is a window in which you are rooted and the opponent can close on
   you — the cost becomes spatial, and the choice becomes real.

3. **The left stick did nothing.** Entering combat called
   `set_locomotion_enabled(false)`, deliberately switching off the movement
   controller, camera rig, stamina and terrain collision that M1 spent its
   entire budget making feel good. Turning off the best-built system in the
   project during its most important moment is a bad sign.

Movement also removes the need for the dodge that §14 left the door open for.
Dodge is not added; **movement is the dodge**. That is one fewer verb, not one
more.

## What it does not change

- The trainer still does not fight. The player pilots the *pal*, so the hard
  rule "human cannot fight" holds exactly as written.
- Combat is still a state in the physical world, not a separate scene. Nothing
  is unloaded, the terrain stays under the fight, and the trainer stays visible.
- Real time, no shields, trainer-owned pals cannot be caught, switching has a
  cooldown. All unchanged.

## Sub-decisions taken at the same time

**Aiming: directional melee with a forgiving cone.** An attack hits what is in
front of you, within range, inside a generous arc. You can miss by facing the
wrong way or being out of range, so spacing and facing are real skills — but a
narrow arc on a 7-inch handheld makes "I missed" the dominant feeling of every
early fight, and this is a game about creatures, not about aim.

**Arena edge: a soft wall with a visible boundary.** The fighters slide along
the edge rather than stopping dead, and the boundary is drawn. Leaving is not
how you flee; Run is. Walking out by accident must never end a fight.

**The trainer: stands where they engaged, and cannot be targeted.** Their body
stays in the arena and in frame. Nothing puppets them and nothing can hit them.

## What this costs

The enemy stops being a timer and needs behaviour: close, commit, recover, back
off, reposition. That is where action combat succeeds or fails and it is the
part most likely to feel bad first.

It also reaches forward. M3's orb is now thrown at a moving target, and M4's
switch has positional consequence. Both are arguably better; both are different
from what those milestones assumed.

Roughly two thirds of the combat code written before this decision survives:
the damage and energy maths, species data, pal instances, the HUD, the encounter
director, the camera handover and the tests. What is replaced is the player
input loop and the enemy tick.

## Risk, and how it is bounded

The failure mode is building a large action-combat system quickly and getting a
mediocre one. The mitigation is the same as the original plan's: ship the
thinnest version that can be played — move, one melee attack, one charged
attack, an opponent that closes and backs off — and add nothing else until it
has been played on the Ally.

Specifically **not** in the first pass: dodge roll, invulnerability frames,
combos, blocking, stamina cost on attacks, knockback chains, or a second
opponent.

## Amendment — the trainer moves during aim (owner, playtest pass)

"The trainer: stands where they engaged" above did not anticipate
`throw_aim.gd`: pressing Throw already swapped the camera to a real-time
over-the-shoulder shot on the trainer (that file's own header called this
"hands camera and control back to the TRAINER"), but the trainer's actual
locomotion stayed switched off for the whole fight regardless, so "control"
only ever meant look direction. A blind playtest pass named this directly:
"when you go to throw should fully control the character again so you can
move him and throw."

`throw_aim.gd::try_begin_aim()` now re-enables the trainer's movement for
exactly the aim/throw window (`_set_trainer_movable`), and every exit path
(`_leave_aim()`, `disarm()`) turns it back off. The trainer is stationary
everywhere else in a fight — engaging, being attacked, switching pals — this
is scoped to the one state that was always meant to be a repositionable
shot, not a menu with a camera cut.
