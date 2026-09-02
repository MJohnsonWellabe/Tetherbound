# FIX — three village-presentation complaints (owner playtest 2026-09-02, findings 4/8/9)

No Godot binary was available in this session (`~/.cache/tetherbound-art/godot`
does not exist here, and none was found anywhere else on the machine), so
nothing below is render-verified the way `FIX-OWNER-0901-KNIFE-VISIBILITY`
was. Every claim is checked by hand against the actual shipped code/data on
`main` — reading the exact constants the game builds from and computing the
resulting world-space geometry — the same standard several `village_npcs.json`
entries in this same file already hold themselves to when a lane had no
engine to render with. This needs a real render or an owner playthrough to
confirm before it can be called done; it is not.

## 1. "Characters in the village look too small now."

**Verdict: not a regression in the villagers. This is the expected
side-effect of the creature-scale growth the owner asked for on 2026-09-01,
landing the day before this playtest.**

Checked and ruled out first:

- **No villager height changed.** `data/config/art.json`'s villager
  `height` values (farmer 1.75, keeper 1.78, smith 1.73, quarryman 1.8,
  ranger 1.77 — all close to the 1.80m trainer) have no commit touching them
  since 2026-08-30 (`git log --since=2026-09-01 -- data/config/art.json`
  returns nothing). `character_model.gd::_fit()` scales every human rig to
  exactly this `height` field in render space, so there is no second,
  hidden scale multiplier anywhere in the NPC pipeline that could have
  shrunk them silently.
- **No global camera/FOV change** that would shrink everyone equally —
  the complaint names characters specifically, not the whole scene.

What did change, the day before this playtest, both directly per owner
instruction (`ralph/OWNER_DIRECTIVES_2026-09-01.md`, "almost all creatures
should stand taller than the character... that's part of the allure"):

- `ralph/VISUAL-STARTER-BADGER-SCALE-REVERT` (`190a415c`): Terrapup
  1.62m → 2.30m, Ripplet 1.55m → 2.15m — both now roughly a head-and-a-half
  taller than the 1.7-1.8m villagers standing near them.
- `ralph/VISUAL-VERIDIAN-GROWTH` (`9d4870fe`): Veridian Stag 2.60m → 3.60m,
  alpha Galecrest multipliers raised across bands 3-5.

A player's own team creatures (now dramatically taller, by direct owner
design) standing next to unchanged 1.7-1.8m villagers in the same frame is
almost certainly what reads as "villagers got small" — nothing about the
villagers moved, the frame's other bodies grew around them. Shrinking the
creatures back is off the table (it is the exact regression
`OD-0901-1`/`OD-0901-2` already corrected once, twice); growing the
villagers past real adult human height to compensate would be a new,
unrequested design decision this task has no authorization to make.

**Separately, and not new to this playtest:** `ralph/BLOCKED.md` (deleted
2026-09-01, recovered here from `git show a6bc8609^:ralph/BLOCKED.md`)
already carried an *unresolved, owner-blocked* question with the same
surface symptom — VIS-CAST measured both villager rigs at ~4.9 heads with
~36cm heads on 1.75-1.78m bodies, which reads as either "an adult with an
oversized head" or "correctly-proportioned youths stretched to adult
height," and named it a story decision ("who lives in this village") that
CLAUDE.md says not to invent. That question was never carried into the new
`BACKLOG.md` when the old backlog files were deleted, and is reopened here
rather than re-decided. It may be compounding this complaint (proportion,
not just relative height, can read as "small"), but it is a second,
independent, still-owner-blocked issue, not something this branch can
close.

**No code or data changed for this finding.** It needs an owner call
(shrink the creature/human height *gap* on purpose, if the new gap itself
is unwanted — separate from the already-settled "creatures should loom"
call) and/or the still-open adult-vs-youth ruling, neither of which this
task is authorized to decide.

## 2. "Village shape still makes no sense, especially with Grandpa's house."

**Verdict: found a concrete defect. Fixed.**

The "Grandpa's House" dirt road (`data/config/terrain_playground.json`
`paths.routes`) ran from the square `[10,-10]` through `[-4,-13]` and
terminated at `[-18,-15]`. Computed the house's actual world footprint from
the code that builds it:

- `playground_world.gd`'s `HOUSE_AT = Vector2(-22.0, -16.0)`, and the house
  node is placed with **no yaw** (`house.position = Vector3(HOUSE_AT.x,
  ground, HOUSE_AT.y)` — nothing rotates the node itself, only its child
  `KitShell` mesh gets `rotation.y = 90°`).
- `grandpa_house.gd`'s `EXT_HALF_W = 5.0`, `EXT_HALF_D = 3.0` (the "10m x
  6m outside" the file's own header describes) put the exterior wall lines,
  in world space, at **x: [-27, -17], z: [-19, -13]**.
- The route's own endpoint, `[-18, -15]`, falls at x=-18 (1m inside the
  x=-17 east wall) and z=-15 (inside the z:[-19,-13] range) — **the road's
  authored endpoint is a metre inside the house's own exterior wall**, not
  a stand-off short of the door the way every other village route's
  endpoint is (compare `The Inn`'s route, which the file's own comment says
  ends "2.0m short of the inn's own centre").
- The actual door sits at local `(INNER_W*0.5 + WALL_T + 1.2, 0, 0)` =
  world **(-15.7, -16)**, 1.3m *outside* that same east wall — on the
  opposite side of the wall from where the road stops.

So the painted dirt path runs into the side of the house rather than up to
its door. This is very likely why the complaint reads as "now": the file's
own header records that the EV6 kit rebuild widened the house's exterior
from the old hand-built ~9m shell to the kit's 10m `farmhouse_shell` —
which moves the east wall line 0.5m *toward* the square, making an
already-tight-or-borderline road endpoint clip the wall for the first time
(or clip it harder than before).

**Fix:** moved the route's final waypoint from `[-18.0, -15.0]` to
`[-16.5, -16.0]` — 0.5m clear of the actual wall line, aligned with the
door's own z, so the path visually reaches the doorway instead of
disappearing into the wall. Full reasoning is recorded inline in the
route's own `_why` field (this file's established convention).

**Checked for side effects:**
- `signpost.gd`'s junction sign reads each route's bearing from
  `points[0]`→`points[1]` only (unaffected — I only changed the third
  point).
- `tools/_probe_village_gate_roads_v2.gd` and `map_landmarks.json`'s
  `starting_reveal` (the fog-of-war seed) both exist independently: the
  reveal circle at `[-18.0,-15.0]` has a 75m radius, so a 1.8m shift is
  immaterial to it and it was left alone rather than touched for no
  functional gain.
- `tests/test_scatter_rules.gd::_route_probes()` and `tests/test_map_fog.gd`
  both hardcode their own copies of the old endpoint rather than reading
  `terrain_playground.json` at all, so neither is affected by this edit
  either way.

I did not find, and did not go looking to invent, a second "shape" defect
beyond this one road/wall clip — the fence, workshop and cottage placements
around it check out under the same coordinate math (door bearing to the
square is ~10° off dead-centre, fences don't cross the route or the direct
sightline). If the owner's complaint is about something this coordinate
read cannot see (a visual proportion, a texture seam, an approach that
looks wrong only from eye height), it needs an actual render or playthrough
to find, which this session could not produce.

## 3. "Mira shouldn't be hidden in a house."

**Verdict: confirmed. Fixed with an exterior sign, not by moving her back
outside.**

`data/config/village_npcs.json`'s own comment confirms this directly: "OF31
moved her indoors: she is the merchant... she stands behind her own counter
inside cottage_a." `scripts/world/shop_interior.gd` builds a real one-room
shop behind a real door, and nothing anywhere — no sign, no lit window
callout, no difference from cottage_b's exterior — tells a player standing
in the square that a merchant is behind that specific door. Moving her back
outside would undo a deliberate, owner-requested decision (OF31: "he has a
store in his house"), which CLAUDE.md's canon precedence says stands unless
a newer owner directive overrides it — this playtest complaint reads as
"she isn't findable," not "put her back in the square."

**Fix:** `scripts/world/shop_interior.gd` now builds a small hanging sign
over the doorway (`_build_sign()`) reading "Mira's Store" — a flat board
plus a billboarded `Label3D`, the exact same primitive-plus-text mechanism
`signpost.gd` already uses at the village junction sign (CLAUDE.md: a
placeholder is fine to prove a mechanic; this spends no new asset and no
Meshy generation, and adds no new prop family). Mounted at the recipe's own
documented doorway coordinates (`DOOR_X = 1.0`, front wall at local z≈3,
per this file's own `INNER_HALF_W`/`_D` comment), just above the 2.3m kit
door height so it reads from outside without blocking the doorway.

Billboarded rather than face-painted like the junction signpost's arms:
those need to point a specific bearing on each face, which is why that file
paints both sides to avoid a mirrored-text bug; this is one static sign
read from whatever direction a player approaches from, so there is no
bearing to get backwards and a billboard is the simpler correct choice.

**Not addressed, flagged instead of guessed at:** whether she should also
be reachable/findable at *every* hour (there is no day/night gating on her
placement — she is always in the shop, unlike Sela or Kell who have
`place_when` gates), so hours-of-operation are not the issue here; the gap
was purely "nothing outside says this is a shop," which the sign now
answers.

## What this branch does not touch

Per the dispatch: no merge was performed. All three findings above are
independently commit-able; findings 2 and 3 have real (if unrendered) code
fixes, finding 1 has an investigation and an explicit call for an owner
decision rather than a guess.
