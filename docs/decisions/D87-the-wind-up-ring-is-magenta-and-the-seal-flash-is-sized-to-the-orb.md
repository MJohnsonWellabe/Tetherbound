# D87 — The wind-up ring is magenta, the one colour the meadow and the reward layer do not use, and the seal flash is sized to the orb

**Date:** 2026-09-05 · **Decided by:** lane N07-VFX-POLISH (0905 follow-up wave), inside the
two items W09-VFX's blind judge named and routed. Small calls the brief left open, recorded
here rather than asked, per `docs/00_START_HERE.md`.

## 1. The telegraph ring is magenta, not the reserved red and not the reward gold

`combat.json`'s `telegraph.colour` was `#ff5a3c` — hue 9°, saturation 0.76 — inside the
band this project reserves for Team Tether (`#6b2a20` hue 8° / `#7a2430` hue 352°, both at
saturation 0.70; `data/config/palette.json` `_reserved`, and the ~5–17° / 0.7+ band
`building_prefabs.json`'s own roof retint measured against). Drawn at partial opacity over
tan fur and green grass it rendered as the "dull oxblood torus" W09's round-1 judge saw, on
the wrong creature. The brief offered "a neutral or move-type-appropriate colour".

**Round 1 tried the HUD's own warning amber** (`#ffbe47`, the `UITokens.WARNING` family that
paints the "!  incoming — move" line for the same beat). A code-blind judge, not told which
sheet was newer, found it three degrees of hue from the board's gold swatch, the orb's band,
the catch sparkle and the level-up rings — "the game uses that exact gold for 'you got the
thing'" — at a value inside the sunlit-grass band, and read the ring as "a dropped coin", a
buff circle, not a warning. That is the right criticism: a warning in the reward colour
teaches the player nothing by colour.

**The ring is now `#ff40e6` — hue 308°, saturation 0.75.** Magenta is the complement of the
meadow's green, so it is the most findable hue the frame can hold; nothing in the world
(tan fur, gold reward, violet-blue flowers at ~270°, the reserved teal at 165°) or the element
sparks (psychic lilac at 262°) carries it; and it is 44° of hue from the nearest painted
oxblood and 31° from the palette's near-black `tether_oxblood` (339°). It is also the genre's
established colour for an attack that cannot be blocked and must be moved off — and this
game has no shields, so that is every wind-up. `tests/test_telegraph_glow.gd` holds the ring
at least 25° of hue from every reserved oxblood.

**Not a move-type colour**, although the brief allowed one: `telegraph_glow.gd::begin()`
is handed a colour by `combat_manager.gd::_on_enemy_telegraph()`, which knows only the
beat's length; the wild creature's pending move type never reaches either. Wiring it would
edit `combat_manager.gd`, outside this lane's ownership, and would make the wind-up ring
the third thing on screen (after the hit spark and the projectile) that carries element
colour, for a mark whose one job is "move now". Left as a documented option.

**And it is depth-tested.** The other half of "on a friendly creature" was `telegraph_glow.gd`
drawing with `no_depth_test = true`: the ring spawns at the foe's feet, the foe stands beyond
the ally from the combat camera, and the ring was painted straight through the ally's back.
It is a ground mark, lifted 0.08 m, that the body in front of it occludes — the same
treatment `alpha_aura.gd` and W09's round-3 level-up rings use, and the fix the round-1
judge asked for unprompted.

## 2. The seal flash is sized to the orb it plays on, and is gold rather than pale

`catching.json`'s `vfx.caught` (`#ffe9a8`, radius 1.2, strength 1.15, 0.55 s) is an
`impact_flash.gd` burst whose ring expands to 1.38 m — a 2.76 m disc at a camera parked
2.4 m from the orb with a 50° field of view (2.24 m of frame height), so it covered the
frame edge to edge and, at saturation 0.34 mixed over grass, read as the "flat khaki disc"
W09's judge described. It is now `#ffc94a` (hue 42°, saturation 0.71 — the same gold
family as the `catch_burst` sparkle W09 layered on top), radius 0.5, strength 1.0, 0.75 s:
a 1.0 m bloom, 45 % of the frame height, around a 0.42 m orb. It lasts longer than the
original, not shorter: the round-1 judge found a 0.45 s cut buried under the sparkle's
dark-haloed motes at birth and faded to 12 % by the time they had flown clear, leaving the
orb "unsupported"; at 0.75 s the ring is still at 38 % opacity and 0.55 m sixteen ticks in,
around a clean orb, and never reaches the frame edge. Only the `caught` block moved; `strike`
and `breakout` are sized for their own moments and are not this lane's.

**The spikes stay spikes.** `impact_flash.gd` draws nine hard-edged radial triangles in its
core colour and exposes no softness or streak key; softening them is an edit to a script
every attack in the game shares, and is routed rather than made. At the new radius they
reach 0.68 m instead of 1.86 m.

## 3. Tunables, and the revert

Both are config-only: `combat.json` `telegraph.colour` and `catching.json` `vfx.caught`.
`telegraph_glow.gd`'s own default colour follows the config so a missing key cannot fall
back to the reserved red; its depth test and lift are constants in that file. Reverting the
colours is one value each; `tests/test_telegraph_glow.gd` will object to a revert into the
reserved band, which is the point of it.
