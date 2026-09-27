# Veilfall Interior — Visual Verdict (r1)

## 1. Per-frame defects

- **intake_gallery.png** — Corridor walls are one repeating stone-block texture with no variation (moss, wear, carving), reading as a tiled material rather than authored stonework. The waterfall at the end of the hall is a flat static-noise texture inside a plain triangle cutout, not a cascading surface. Named a "gallery" but holds no props — no nets, baskets, crates — that support that function. Lighting is flat ambient; lit lanterns cast no visible glow/contact shadow.
- **pump_hall.png** — The two "pools" are hard-edged, solid-blue rectangles with no ripple, reflection, or foam — reads as a placeholder plane, not water. The banners are flat colour rectangles with a blank pale square, no heraldry. A distant NPC reads as a featureless black silhouette. The room is named "pump hall" but contains no pump, pipe, gear, or wet-machinery prop anywhere in frame.
- **sluice_crossing.png** — The entire foreground is one flat blue plane; nothing about it reads as a *sluice* (channel, flow direction, current). No rails, planks, splash, or moisture streak where the stone walkway meets the water.
- **heart_chamber_entry.png** — Same static-noise waterfall plane behind the crystal, more visible here at wider framing — it reads like a paused screen. The room is a flat-ceilinged box; nothing suggests the multi-level Gothic hall the board specifies. NPC "Pell" stands in flat, unlit silhouette against dark stone with no rim light to separate them from the wall.
- **heart_chamber_crystal.png** — The "Heart Chamber" centrepiece — the single most important asset in this location — is a flat-shaded, untextured cone with no facets, internal glow falloff, or light shaft. Two plain grey cubes sit at its base, unmistakably blockout primitives, not dressed pedestals or rockwork. No wet-floor reflection of the crystal's light despite "wet rock" being a named board material.
- **heart_chamber_banner.png** — The banner "icon" is a blank light-grey square, not the Tetherbound diamond sigil the board shows on every banner in this room. The wall behind it is bare stone with lanterns only — no arch, moulding, or carved threshold marking this as the chamber's climax.

## 2. Three biggest gaps from the references, ranked

1. **The crystal/waterfall centrepiece is unfinished geometry, not a hero prop.** The board's Heart Chamber is built around a faceted, luminous crystal and a real cascading waterfall; these frames substitute a flat cone and a static noise-texture plane, with visible grey placeholder cubes at its feet (`heart_chamber_crystal.png`).
2. **No verticality or architecture.** The board's chamber is a multi-level Gothic hall — arches, railings, balconies, a bridge crossing in front of the falls. Every frame here is a single flat-ceilinged stone box (`heart_chamber_entry.png`, `pump_hall.png`).
3. **Water and function props are absent.** Pools and the sluice are flat solid colour with no shader behaviour, and rooms named for their function (pump hall, sluice, gallery) carry none of the machinery or dressing that would justify those names (`pump_hall.png`, `sluice_crossing.png`).

## 3. Bar A (the board's Veilfall / Heart Chamber) — **No.**
The cool blue/stone palette and banner placement gesture at the right location, but the flat unfaceted crystal, static-texture waterfall, exposed blockout cubes, and blank banner icon sink it — none of the board's defining Heart Chamber elements (luminous crystal, real falls, verticality) are actually present.

## 4. Bar B (beside the Palworld shots) — **No.**
Even allowing that these are interior versus Palworld's outdoor shots, Palworld's own base-building interior (`palworld-05`) still shows varied crates, plants, and working stations at shipping polish. These halls are comparatively bare, with flat-colour water and exposed placeholder geometry that would not pass as finished in any comparable game.

## 5. Specific read: **No.**
The two grey untextured cubes flanking the crystal and the static-noise waterfall plane are unambiguous blockout signals, not a stylistic choice.

## 6. Fix split

**(a) Fixable by scene changes (existing asset kinds):**
- Replace flat blue pool/sluice planes with a water material carrying reflection, ripple, and foam.
- Dress named rooms to match function: crates/nets/baskets in the gallery, pipes/valves/gears in the pump hall, rails/planks/splash decals at the sluice crossing.
- Remove or re-skin the two grey placeholder cubes at the crystal's base into dressed pedestals or rockwork.
- Add banner texture with the existing Tetherbound diamond emblem in place of the blank square.
- Add warm lantern glow/bounce and a rim light on Pell and other NPCs so they read against dark stone.
- Break up wall texture repetition with moss/wear decals and tile rotation/offset.
- Add mist/spray VFX and light shafts near the waterfall for atmosphere.

**(b) Needs new art not in the build:**
- A proper faceted, internally-lit crystal mesh/shader to replace the flat cone.
- An actual animated, layered waterfall mesh+shader to replace the static noise plane.
- Multi-level chamber architecture — arches, balconies, railings, a bridge — since the current kit only offers a flat single-level box.
- Distinct pump/machinery asset set for the pump hall.
