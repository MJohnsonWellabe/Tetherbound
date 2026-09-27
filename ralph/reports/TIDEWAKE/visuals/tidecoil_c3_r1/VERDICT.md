# Tidecoil, the Abyss Serpent — C3 visual verdict

## Framing: 16/18 (88.9%)

Fails:
- **t-024.02** — Ripplet (ally) is not visible at all. Tidecoil renders as a pale, semi-transparent/x-ray silhouette (only a ghost outline of head and neck), unlike its solid painted look everywhere else. Reads as a broken material swap, not a readable creature.
- **t-032.02** — void frame. Camera looks across open water with neither creature nor any landmark on screen; only HUD text tells you a fight is happening.

All other 16 frames show both Ripplet and Tidecoil legibly, unoccluded by terrain, HUD or water.

## Tells: 0/4 tell-start frames fully readable

The four tell-start frames (000.60, 001.27, 002.77, 004.05) all show the same cue: an orange "! incoming — move" text banner in the boss panel. That text is legible every time. But none of the four show any ground ring, arc or lane — nothing marks where the strike will land. Per the bar's own definition ("telegraph... **and** where the strike lands are readable"), a text-only banner with no spatial marker does not meet it. tell-ended frames (000.92, 001.50, 002.87, 004.37) correctly show the resolved "it's open — hit it" / "STAGGERED" / "it missed you" states and are not penalized.

Separately, **tell-ended-002.87** renders Tidecoil's head as a blurred, desaturated grey blob with a faint ring pattern — looks like a broken texture/LOD pop during the stagger transition, not an intentional VFX.

## Presentation breaks

- t-032.02: void frame (listed above).
- t-024.02: x-ray/transparent boss render, ally missing (listed above).
- tell-ended-002.87: greyscale blur glitch on the boss head.
- A flat, solid-cyan triangular shape sits in the water beside Ripplet in several frames (t-000.00, hit-001.07, tell-start-002.77) — reads as a disconnected geometry piece or unlit VFX plane, not a shaded fin.
- A dark purple ink-blot decal recurs on the water surface near the boss's tail (tell-start-004.05, t-008.02, t-048.02) with no clear source.
- No exploration HUD leakage; fighters are not sunk/floating; camera never clips into geometry in the frames reviewed.

## C3: **FAIL**

Framing misses the 90% bar (88.9%), the tell telegraph never clears the bar's own two-part bar, and there are two clear presentation breaks (a void frame and an x-ray render) in an 18-frame sample.

## Top three defects

1. **t-032.02** — a completely empty frame mid-fight: no ally, no boss, no shore, just water. This is the loudest possible failure of "both creatures visible."
2. **t-024.02** — ally vanishes and the boss renders as a translucent ghost outline instead of its normal shaded model.
3. **Every tell-start frame** (000.60, 001.27, 002.77, 004.05) has no ground ring/arc/lane — only a text banner — so the player never gets a spatial read on where Tidecoil's attack will land before it lands.

## Bar A — reads as the Tetherbound world? **No**

The palette (cool teal water, natural sand cliff, clear sky) is consistent with the project's vibrant-but-natural identity and oxblood stays off this scene entirely. But the two creatures on screen don't belong to one visual language: Ripplet is a rounded, flat-shaded plush-toy mascot with polka dots, while Tidecoil is a painterly, scale-gradient dragon with translucent fins — closer to two different games' assets side by side than one roster (see roster board: Tidecoil's concept already reads as a serious painterly dragon, and the in-game render is a reasonable match for it, which only sharpens the mismatch with Ripplet).

## Bar B — reads as the same kind of game as Palworld? **No**

The shallows are almost entirely flat open water with no rock, reef or foam detail beyond a repeating surface texture — far emptier than Palworld's foliage-dense backgrounds. Both "hit" frames (hit-000.98, hit-001.07) show no discernible impact VFX (no flash, spark or splash burst) at the moment of contact, so the hit doesn't read as an event. Combined with the void and x-ray frames, the fight looks unfinished rather than shipping-quality.

## Fix split

**(a) Scene/camera/placement/VFX** — reproduce and fix the t-032.02 camera/void bug and the t-024.02 transparency bug; add a ground-plane telegraph (ring/arc/lane) to the tell-start state; add hit-impact VFX (splash/spark burst) on contact; add reef rock/foam detail to the shallows; fix or remove the flat cyan triangle geometry near Ripplet; fix the grey blur glitch on the staggered boss head.

**(b) New art** — reconcile Ripplet's flat plush-toy shading/proportions with Tidecoil's painterly scaled-dragon shading so companion and boss read as one roster; this is a material/shading-language mismatch, not something a scene tweak fixes.
