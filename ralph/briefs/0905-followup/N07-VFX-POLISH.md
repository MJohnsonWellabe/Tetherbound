# N07-VFX-POLISH

**Source:** W09-VFX-0904's report.

## Why
Two concrete visual-tuning issues named by W09's own blind judge that its lane correctly left
because they're pre-existing config, not new VFX work.

## Owns
`data/config/combat.json` (telegraph colour only), `data/config/catching.json` (the `vfx.caught`
block only), `scripts/vfx/telegraph_glow.gd` if the colour is computed rather than pure config.

## Do

**1. Telegraph glow uses the reserved Team Tether colour on friendly creatures.** An
oxblood/Team-Tether-reserved hue appears as the attack-telegraph glow on a friendly creature.
Per `docs/VISUAL_BIBLE.md`, that hue is reserved for danger/Team Tether. Find
`telegraph.colour` (or equivalent key) in `data/config/combat.json` and retint it to something
outside that reserved range — a neutral or move-type-appropriate colour instead.

**2. Catch VFX burst reads poorly at its current scale.** The existing catch-success burst
(a flat khaki disc with hard white spikes) was sized/styled for a different, closer camera
framing than what's actually shipped and reads poorly now. Retune `vfx.caught` in
`data/config/catching.json` — size, colour value range, spike softness — to read cleanly at
the actual in-game camera distance. This is retuning existing config values, not authoring a
new effect.

## Verify
- Capture the same combat/catch moments W09's own capture tool used (check
  `ralph/reports/W09-VFX-0904/REPORT.md` for the tool name, likely
  `tools/_capture_vfx_moments.gd`) before and after each retune.
- Run a code-blind judge round on both, telling it nothing about what changed, asking
  specifically: does the telegraph colour read as belonging to a friendly creature, and does
  the catch burst read clearly at this camera distance.
- Confirm no existing VFX/combat test regresses (`test_combat_vfx.gd` or equivalent, if one
  exists — check the file W09 added).

## Acceptance
Telegraph glow no longer uses the Team-Tether-reserved hue on a friendly creature, confirmed
by a blind judge against the visual bible's own colour rule. Catch burst reads clearly at
actual camera distance per a fresh blind judge, without becoming a new/different effect.
