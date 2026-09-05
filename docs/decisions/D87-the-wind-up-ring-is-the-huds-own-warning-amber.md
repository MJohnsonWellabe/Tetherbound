# D87 — The wind-up ring is the HUD's own warning amber, and the seal flash is sized to the orb

**Date:** 2026-09-05 · **Decided by:** lane N07-VFX-POLISH (0905 follow-up wave), inside the
two items W09-VFX's blind judge named and routed. Small calls the brief left open, recorded
here rather than asked, per `docs/00_START_HERE.md`.

## 1. The telegraph ring joins the "! incoming" line's colour, not a move type

`combat.json`'s `telegraph.colour` was `#ff5a3c` — hue 9°, saturation 0.76 — inside the
band this project reserves for Team Tether (`#6b2a20` hue 8° / `#7a2430` hue 352°, both at
saturation 0.70; `data/config/palette.json` `_reserved`). Drawn at partial opacity over tan
fur and green grass it rendered as the "dull oxblood torus" W09's round-1 judge saw, on the
wrong creature. The brief offered "a neutral or move-type-appropriate colour".

The ring now uses `#ffbe47` — hue 39°, saturation 0.72 — the same family as
`UITokens.WARNING` (`#e8b74a`, hue 41°), which is the colour `combat_hud.gd` already paints
the "!  incoming — move" line in for the very same beat. One event, one colour, in the HUD
and on the ground. It sits 30° of hue away from the reserved band and 15° from the fire
element's orange, and it is the game's own established warning token on friendly UI, so the
reservation rule cannot be read as touching it.

**Not a move-type colour**, although the brief allowed one: `telegraph_glow.gd::begin()`
is handed a colour by `combat_manager.gd::_on_enemy_telegraph()`, which knows only the
beat's length; the wild creature's pending move type never reaches either. Wiring it would
edit `combat_manager.gd`, outside this lane's ownership, and would make the wind-up ring
the third thing on screen (after the hit spark and the projectile) that carries element
colour, for a mark whose one job is "move now". Left as a documented option.

## 2. The seal flash is sized to the orb it plays on, and is gold rather than pale

`catching.json`'s `vfx.caught` (`#ffe9a8`, radius 1.2, strength 1.15, 0.55 s) is an
`impact_flash.gd` burst whose ring expands to 1.38 m — a 2.76 m disc at a camera parked
2.4 m from the orb with a 50° field of view (2.24 m of frame height), so it covered the
frame edge to edge and, at saturation 0.34 mixed over grass, read as the "flat khaki disc"
W09's judge described. It is now `#ffc94a` (hue 42°, saturation 0.71 — the same gold
family as the `catch_burst` sparkle W09 layered on top), radius 0.5, strength 1.0, 0.45 s:
a 1.0 m bloom, 45 % of the frame height, around a 0.42 m orb, and gone a fifth of a second
sooner so the sparkle owns the rest of the second. Only the `caught` block moved; `strike`
and `breakout` are sized for their own moments and are not this lane's.

**The spikes stay spikes.** `impact_flash.gd` draws nine hard-edged radial triangles in its
core colour and exposes no softness or streak key; softening them is an edit to a script
every attack in the game shares, and is routed rather than made. At the new radius they
reach 0.68 m instead of 1.86 m.

## 3. Tunables, and the revert

Both are config-only: `combat.json` `telegraph.colour` and `catching.json` `vfx.caught`.
`telegraph_glow.gd`'s own default colour follows the config so a missing key cannot fall
back to the reserved red. Reverting either is one value.
