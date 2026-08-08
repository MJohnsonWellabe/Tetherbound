# D24 — Riding is the party pal carrying you

**Status:** accepted
**Decided during:** M12
**Scope:** `GAME_DESIGN.md` §17, `MEADOWS_VERTICAL_SLICE.md` M12

## The decision

There is no mount entity. The creature you ride is the party's **active pal** —
the same one a fight would deploy — summoned under you when you press the mount
button and put away when you get off. The trainer stops being a physics body for
as long as he is on it: `pal_body` walks, and he is carried.

Four consequences fall out of that and all four are the point:

- **A mount cannot be a sixth thing you own.** There is no vehicle slot, no
  stable, and nowhere in `mount.gd` for a creature to be stored. CLAUDE.md's
  five-pal cap is not restated here; it is simply unreachable from here.
- **Riding does not need a second locomotion system.** Gravity, slopes, the
  world's own ground query and a `Gallop` clip already exist on `pal_body`. The
  ride drives them.
- **A fight that starts while you are riding just puts you down.** See below.
- **The trainer's own stamina is untouched.** His legs are not doing anything.

## What happens if a fight starts while mounted

**You get off, and the fight runs exactly as it always has.** No mounted combat,
no new mode, and nothing added to `scripts/combat/`.

The creature carrying you *is* the active pal, so dismounting hands the fight the
creature it was going to deploy anyway. You can still be ambushed while riding —
`encounter_director._on_wild_wants_to_engage` has no idea riding exists and none
of its conditions changed — it simply ends with your feet on the grass.

It is wired through `player_controller.set_locomotion_enabled(false)`, which was
already the one door in and out of exploration. A menu opening and a death come
through the same door, so all three got the behaviour without knowing about it.

## The mount's stamina is not the trainer's

M12 says "riding stamina if needed". It is needed, and it belongs to the animal.

The trainer's meter means *what my body can still do*. Spend it on a creature's
legs and travelling starts competing with jumping and climbing, so arriving
somewhere leaves you unable to do anything there. So: the mount has its own pool,
it is spent only by the **gallop**, and the base pace is free forever. Running
out slows you to something still faster than a sprint rather than stranding you.

A limit exists at all because §17 promises legendary mounts "exceptional
stamina", which is worth nothing unless ordinary ones tire.

## The rideable rule, and what actually set it

A species is rideable when the top of its back clears the trainer's own hip by
15cm. Measured from **bone poses and rest-pose vertices under the idle clip** —
never `Mesh.get_aabb()`, which on a skinned mesh is padded to cover every pose in
every clip and reports a 1.4m alpaca as 5.40m.

Two of eight qualify: the Thornback at 1.87m and the Palehorn at 1.21m.

The 15cm is not arithmetic. The hip alone is 1.05m, and by that rule the
Gloamfang (1.15m) qualifies — until you render it, at which point the rider's
boot is on the grass and it reads as a man standing inside a wolf. The frames are
in `shots/riding/`. **The threshold is really about the trainer, not the
creatures:** his animation library has no seated clip, so he rides in a borrowed
bent-legged pose that hangs lower than a real seat would. A seated clip would
lower the bar, and that is the thing to fix before adding a smaller mount.

## The borrowed pose, which is the honest weak point

All 25 clips merged onto the trainer were listed: idles, walks, runs, jumps, a
throw, a pick-up, hits, deaths. **There is no sit, no mount and no ride.** Left
alone, a mounted trainer stands bolt upright on the animal's back.

So `mount.gd` pins him to one frame of one clip, named in
`data/config/movement.json`. `Jump_Idle` was the obvious pick and was wrong: a
second into its loop the arms spread wide for balance, which from the game's own
camera — which is *behind* the player — is a trainer riding in a T-pose. Twelve
clips were rendered from behind and from the side, mounted, at several times
each; `Jump_Start` at t=0 is the only frame in the library where the arms hang at
the sides **and** the knee is bent with the boot tucked under the belly.

This is a pose, not an animation. It does not bend to the mount and it does not
move. The real fix is a seated clip in the library plus a `ride` role in
`data/config/art.json` — both outside M12.

## One saddle, and the schema that keeps it that way

§17: "Riding saddle is generic across compatible rideable pals." M12: "no
species-specific saddle clutter."

There is one `riding_saddle` in `items.json`, one recipe for it, one constant
naming it in `mount.gd`, and **no field anywhere in which a species could name
its own tack**. `tests/test_mount.gd` fails the build if a second item whose id
contains "saddle" appears, or if a `ride` block grows a saddle key. The bullet is
enforced by there being nowhere to break it.

## The button

A new action, `mount` — keyboard G, gamepad D-pad down, the only face, shoulder
or D-pad button nothing else binds.

`interact` was the obvious candidate and is the wrong one: three systems read it,
and one of them (`encounter_director._read_engage_input`) engages a wild pal
within 6m — a condition that can be true at the same instant as "you have a
rideable pal and a saddle". One press would mount you and start a fight, in the
same frame, forever. That is the `party_menu` collision recorded in
`project.godot` — two actions on gamepad Y, one press firing both — and it was
resolved there in the input map rather than papered over in the code. So was
this.
