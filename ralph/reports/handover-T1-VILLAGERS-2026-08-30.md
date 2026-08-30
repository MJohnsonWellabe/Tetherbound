# T1-VILLAGERS handover — 2026-08-30

Branch `ralph/T1-VILLAGERS` off `origin/ralph/LAND-0830I`.

**One sentence:** the twelve installed-but-generic-looking named characters and
the twelve bespoke-looking walk-ons have been swapped the right way round, at
zero new art cost, and `officer_b` is wired so Officer Dell and Warder Ness stop
being the same body.

---

## 1. The audit, verified before anything was changed

The reported inversion is real. I traced the only two resolution paths that
exist and there is no third one that could have been giving the named cast
distinct presentation.

`scripts/world/trainer_npc.gd::model_config(spec)` and
`scripts/world/village_npcs.gd::model_config(spec)` both resolve a body exactly
one of two ways:

- `spec.rank` non-empty → `npc_ranks.gd::config_for(rank, spec.base)`
- otherwise → `character_model.gd::config_for(spec.config_key)` → `art.json`

then `hair`/`accessories`/`tint`/`height` **replace** and `palette` **merges per
surface**. Nothing else can change which mesh loads.

### Confirmed: the core cast shared two meshes

Twelve named characters resolved to `villager_male_lod0.glb` or
`villager_female_lod0.glb`:

| Character | key | mesh |
|---|---|---|
| Mira | `villager_farmer` | villager_female |
| Oskar | `villager_keeper` | villager_male |
| Tam | `villager_smith` | villager_female |
| Bram | `villager_keeper` | villager_male |
| Old Bram | `villager_farmer` | villager_female |
| Sela | `villager_ranger` | villager_female |
| Quarry Foreman | `villager_quarryman` | villager_male |
| Kell | `villager_keeper` | villager_male |
| Halda | `villager_ranger` | villager_female |
| Rae | `villager_farmer` | villager_female |
| Bryn | `villager_farmer` | villager_female |
| Juno | `villager_ranger` | villager_female |

### Confirmed: twelve walk-ons each had their own mesh

Wilhelm, Nessa, Corin, Ada, Fenn, Garrick, Old Perrin, Tobin, Maren, Sorrel,
Lark, Ren.

### Corrected: `officer_b` was not unreferenced by oversight

It is in `art.json`, and it **was** wired — to `stronghold_courtyard` (Warder
Solene). `T1-HALL-3`, a commit in this branch's own history, deliberately
removed it along with `grunt_c` and `captain_a` because JUDGE-5 read the
officer_b body inside the Hall and called it "from a different game". So the
body was unplaced by a recorded decision, not by an oversight. The
`officer_a`-does-double-duty half of the finding is exactly right: Officer Dell
(band 3) and Warder Ness (band 5) were the same body.

### Corrected: `captain_accessory` is not a body

`assets/characters/captain_accessory/` contains **no mesh at all** — two
reference turnarounds behind a `.gdignore`, kept from the `captain_a`/`captain_b`
generation. It has no `art.json` key because there is nothing to key. Recorded in
`docs/ASSET_LEDGER.md` so no future pass hunts for the mesh its name implies.

### Two further defects the audit did not name

Both found while reading the dialogue to establish role reads, and both are
worse than the inversion itself because they are outright wrong rather than
merely generic:

- **Tam is male and was standing on the female rig.** Every comment in
  `data/dialogue/village.json` says "him" — "Tam stays the smith OF30 made
  him", "he has no vendor effect left to carry" — and `villager_smith` resolves
  to `villager_female_lod0.glb`.
- **Old Bram, a retired champion and an old man, was also on the female rig**,
  with white hair painted over it to say "old".

There is also a **name collision** worth knowing about but not worth changing
here: Bram the village innkeeper and Old Bram the retired champion at (195, 905)
are two different people who share a first name. Not a bug, but it will read as
one to anyone auditing this cast next.

---

## 2. What changed

Role reads come from each character's own opening line, not from the config-key
name, which had drifted (Mira's key said `villager_farmer`; she is the Meadow
Keeper and the shop).

| Character | Their own words | Was | Now | Board |
|---|---|---|---|---|
| **Mira** | "Meadow Keeper's what they call me" + runs the store | villager_female + tint | `creature_caretaker` | 13 |
| **Tam** | "Field Scout when I'm out past the fence. Smith when I'm in." | villager_female + grey hair | `craftsperson` | 12 |
| **Oskar** | "Bridgehand's my trade — I keep the old crossing in one piece" | villager_male + tint | `wandering_trainer` | 20 |
| **Bram** | "Innkeeper's the whole of it." | villager_male + tint | `innkeeper` | 9 |
| **Old Bram** | the retired champion | villager_female + white hair | `local_historian` | 15 |

Displaced walk-ons take the shared rigs, which is the right way round — each one
is the subordinate or duplicate of the character taking their body:

| Walk-on | Their own words | Now |
|---|---|---|
| Wilhelm | "Bram runs the counter, I run everything Bram doesn't have time for" | `villager_keeper` + tint |
| Ada | "The workshop's not mine" | `villager_smith` + hair |
| Fenn | "Oskar swaps them, I look after them in between" | `villager_ranger` + hair |
| Old Perrin | the square's historian | `villager_quarryman` + tint + height |

**Oskar cost nobody anything**: `wandering_trainer` was installed, rigged and
placed nowhere.

`officer_b` is wired to `stronghold_checkpoint` (Warder Ness) — a roadside
checkpoint outside the Hall, not one of the three bodies JUDGE-5 judged. Those
three are untouched.

Files: `data/config/village_npcs.json`,
`data/config/bands/band1_lower_meadows/trainers.json` (so a character does not
change body between the square, the greeting and the tournament bracket),
`data/config/bands/band5_stronghold_approach/trainers.json`,
`docs/ASSET_LEDGER.md`.

---

## 3. Evidence

`tools/_capture_t1_villagers.gd` shoots both sets in the real Meadows
(`meadows_playground.tscn`, real terrain, real grass, real light) at
conversation range — 3.8m, which is the radius `village_npcs.gd::add_prompt`
offers the "Greet <name>" prompt at, so it is the distance the player is
actually standing when they look at this person.

- `ralph/reports/T1-VILLAGERS/shots-before/` — before the reallocation
- `ralph/reports/T1-VILLAGERS/shots/` — after

Matched pairs from the same camera rules, so the only difference between a pair
is the body.

### `tools/capture_check.gd` caught two real defects in my own capture tool

Both on the first framed round, and both would have quietly invalidated the
frames:

- **Terrain3D was streaming around the gameplay camera, not the capture
  camera.** Every frame would have shown terrain LOD resolved for a camera
  standing somewhere else.
- **`WorldWeather` was still processing**, so sky and light would have drifted
  between the first shot of a pass and the last — which is precisely the failure
  that makes a before/after pair disagree for a reason that has nothing to do
  with the bodies in it.

Fixed in the tool; every committed frame reports `capture_check clean`.

### Three framing bugs I fixed by looking at the frames, not by reasoning

`capture_check` passes a frame that is technically the game and still useless.
All three were found by opening the PNGs:

1. **The tool was shooting the backs of people's heads.** These rigs are
   authored facing **+Z**, not Godot's conventional −Z. Established by render:
   the Tether lineup poses bodies at `rotation.y = 0` and shoots from +Z, and
   those frames show faces.
2. **The occlusion test was being blocked by the subject.** `npc_body.gd` builds
   its collider as a child, so excluding the body node itself was not enough —
   every candidate angle failed and the camera fell through to a fallback that
   stood it inside a wall.
3. **Mira is indoors.** OF31 moved the merchant behind her own counter inside
   `cottage_a`, so every 3.8m stand around her is on the far side of a wall. The
   tool now searches range as well as angle and steps in to 2.4m for her — which
   is also where the player stands to use the shop.

---

## 4. Team Tether: what I measured, and did not touch

*(filled in below from the rendered frames)*

---

## 5. Not fixed, deliberately

- **The Team Tether body-luminance lane.** Reported with measurements in §4 and
  left alone, per the brief — that fix has bounced three times and needs its own
  pass.
- **The three Hall bodies** (`grunt_c`, `officer_b`, `captain_a` inside the
  Hall). `T1-HALL-3` removed those overrides on JUDGE-5 evidence and that
  decision is not reopened here.
- **`young_trainer` and `rival_trainer`** stay installed and unplaced. Both are
  rigged and keyed; neither role exists in the chapter's cast, and inventing a
  character to justify a body is the wrong direction. Bryn was the one
  candidate for `rival_trainer` and is a teacher rather than a rival ("I've
  nothing left to teach you out here").
- **`campfire_traveler` and `traveling_merchant`** remain un-rigged and
  un-installed, exactly as the T1-RIG-2 handover left them.
