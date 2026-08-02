# D60. The opening scene owns a catch guarantee and an AI pin, both scoped to one pal

Kind: implementation

Building the first fifteen minutes (GAME_DESIGN.md section 3) needed two
mechanisms that do not exist anywhere else in the game, and both are written
to affect exactly one scripted pal rather than becoming a general rule.

**The guaranteed catch.** `Throw.ts` gains `ThrowInput.guaranteed`, which
bypasses the whole catch formula the same way `collared` already does at the
other end: `orbs.json`'s new `guaranteedChance` (1.0) is returned outright,
clamp and all. Nothing sets this field except `SpawnManager.spawnScripted`,
and only when its caller (`main.ts`, driven by `Objectives.currentId ===
'catch_tuftmoth'`) asks for it, which it does only while `Story.has('first_
catch')` is false. A player who talks to Orin, wanders off, and comes back
after somehow catching something else first does not get a second free catch.

**The docile pin.** `PalAI.stepAi` gains a `docile` parameter that skips the
aggro and flee branches entirely, tested against species that would otherwise
trigger both (ashmane, sparrowick) rather than against tuftmoth, which has
neither field set and would have passed a lazier test by coincidence. Pinned
at the `WildPal` level (`SpawnManager`'s new `docile` field), not at the
species level, because tuftmoth is also an ordinary wild spawn everywhere else
in the Meadows and this must not change how it behaves for anyone else who
runs into one later.

**Why one pal and not a general "story pal" flag.** Both mechanisms could have
been generalised into a `scripted: true` bit that also disabled catch failure
and AI reactivity for every future scripted encounter. That was cut: the Hall
grunts and Bracken are the only other scripted fights today, and they are
explicitly collared and explicitly meant to be a real fight, so a shared flag
would have been a footgun (see D55's own "docile" AI never being asked for
before this). `guaranteedCatch` and `docile` stay pal-instance fields set by
whoever spawns a pal, not modes a system can flip on for a category of fight.

**Where the prompt and the fight-you-can't-start meet.** `Story.update` used
to own `hud.setPrompt` unconditionally, overwriting anything else every frame.
`Objectives` needed a fallback line to show whenever nobody is in interact
range, so `Story.update` now takes `fallbackPrompt` and `extraMarkers`
parameters and only overrides them when an NPC actually is in range.
Objectives itself never touches `HUD.setPrompt` or `updateCompass`; it hands
Story its intent and Story arbitrates, because two direct callers of
`hud.updateCompass` in the same frame would have silently clobbered each
other's marker list (the second call clears the strip and redraws from
scratch).
