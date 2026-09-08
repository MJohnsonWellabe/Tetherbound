# Bex approach repair — 2026-09-08

The original late-Tidewake diagnostic reached the Sluice arrival and graded
spine but failed to reach Bex's central-crown challenge point. Adding the missing
Twin Pumps waypoint reached (904.075,93.163,2864.589) by ordinary input, but the
subsequent approach still ended approximately 40 m below Bex. The lane's
heightfield audit found a roughly 660 m loop to reach the crown; this was not
evidence of an entirely impassable island.

`data/config/water_characters.json` moves only Bex's island-local X/Z offset
from (18,-20) to (-179,-155), placing him at (671,2805) on the arrival spine,
approximately 11 m from the western control gated by his defeat. His team,
dialogue, level, challenge behaviour and victory flags are unchanged. No terrain
or combat rule changed.

Runtime evidence inspected by the integration agent:

- Log: `C:/Users/mattj/AppData/Local/Temp/water-continuous-bex-repaired.log`.
- +383.3 s: ordinary Sluice arrival-spine waypoint reached.
- +442.6 s: both Bex opponents defeated through the diagnostic's real combat input.
- +443.5 s: western control physically activated after the victory.
- Focused encounter runtime-data suite: 9 tests passed; JSON/diff checks clean.

This is a synthetic-start late-route diagnostic: its initial owned Aquaryn and
prerequisite state were explicitly supplied before departure. After departure it
uses ordinary movement, mounted crossings, fights and interactions, without
resource/position injections. The report proves this encounter/control repair,
not an earned fresh-save journey. At recording time the same run continues
toward Calder; no terminal suffix or finale pass is asserted here.
