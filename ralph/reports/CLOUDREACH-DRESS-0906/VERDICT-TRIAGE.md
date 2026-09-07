# The before-verdict, triaged by lane

`JUDGE-before.md` is a blind read of `shots/dress_before/` — the six stands as
they stood on `claude/second-biome-art-plan-470zru` before this round. It is
much wider than this lane. This is which of its findings this lane owns, which
belong to other lanes, and which are open owner decisions, so the next session
does not read the verdict as one undifferentiated backlog.

## Owned by this lane, and addressed this round

| Judge item | What it said | Done |
|---|---|---|
| I4 | `09` — "a perfect oval of dirt with a razor-sharp edge against grass and absolutely nothing on it ... this is the climax space of the region" | The deck is banded (swept circle / mid court / outer court) with an inlaid ring at each authored hazard radius, a worn centre, an edge skirt that runs the wear out past the rim instead of ending on a drawn circle, and cages, chains, braziers with fire, stores, weapon stands, dummies, banners and pylons around it |
| I5, A2 | `02`, `08`, `12` — "the same bare leaning pole prop appears repeatedly with nothing on it"; "a bare pale pole runs ground-to-sky ... it carries nothing"; fix list says "remove or load" | It cannot be removed (`smoke_cloudreach_look` asserts a non-zero guy-rope count) so it is *loaded*: three ridge lashings now run over each roof and stake both sides, and the guy rope was set to the identical gauge (0.038) and stake reach (1.5 m) so eight matching tails converge on stakes around one roof instead of one lone line at its own angle |
| I3 (part) | "the cottages are one model at one scale ... no hero building, no height variation" | Per-building balconies, diagonal braces, brick footings, vines and shutters, chosen per building and placed on each prefab's own windward wall cells. The building *positions and models* are authored elsewhere and shared with the Meadows village, so footprint and roof-pitch variation is not this lane's to change |
| A8 (part) | `09` — "the arena wall is one crenellated stone module repeated left to right" | Not re-modelled, but broken up: braziers, cages, stalls, weapon stands, dummies, banners and pylons now stand in front of the repeat |
| — | (from the earlier verdict) rocks in three unrelated materials | Both rock defects fixed — see `REPORT.md` §2 and `MEASUREMENTS.md` |

## Not this lane

* **A1** (`11` mesa stretched texture), **H2/H3** (`06` terrain seam, sky under
  the plateau lip), **H1** (`08` "the world ends"), **L1** (one time of day),
  **L4** (no mid-tone at `06`), aerial perspective, cloud sea — the atmosphere
  and terrain lane owns `cloudreach_atmosphere.json`, the `sky_profile`/
  `landmass` blocks, `cloudreach_cliff.gdshader`, `_dress_fog`/`_dress_moorings`
  and the `_mesa` geometry.
* **H4** (`11` floating cliff chunk and loose boulders) — C5 in the gap table,
  islands and moorings, same lane.
* **A4** (path decal outlines on grass) and **S4/S5** (flat rock decals,
  distant tree dots) — the ground-cover pass that landed on this branch's base.
* **A6** (no edge smoothing anywhere) — a project render setting, not a scene.

## Owner decisions, unchanged by this round

* **C1, C2, C3, Sc1** — the creature cast: a photoreal snow leopard beside a
  stylised trainer, and every creature in the survey shorter than the 1.80 m
  human. This is X2 in the gap table and it is explicitly an owner call: one
  material/shader decision for the whole roster, then `creature_visual.gd`.
  `CLAUDE.md` also fixes the direction of any scale fix — grow the smaller
  side, never shrink — so it cannot be done piecemeal in one region's dressing.
* **C4** — the trainer's A-pose in all six frames. An idle set, not scene work.
* **C6** — the boss at `09` reads at ~45 px with no framing or VFX. Encounter
  presentation, not dressing.

## Found by this lane, not this lane's to fix

* **A3** — `12`'s chimney "floats through the roof" at an offset, and `02`'s
  left cottage has the same offset. This is `Prop_Chimney2` at `[0.6, 4.2,
  -1.8]` in `cottage_a`'s recipe in `data/config/building_prefabs.json`, which
  the Meadows village shares. Fixing it there changes the Meadows too, so it is
  logged rather than touched.
* **A7** — the summit dome's white finial "shades differently from every other
  object in frame". It is `tether_pylon.glb` scaled to 18 m at the oculus. The
  same asset reads acceptably at the four corner pylons, so this is about scale
  and context rather than the material; it is left alone rather than retinted
  on a guess, because the pylon is Team Tether's own hero object.
