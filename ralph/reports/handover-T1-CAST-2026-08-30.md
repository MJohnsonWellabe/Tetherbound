# T1-CAST — the human cast as a set

Branch `ralph/T1-CAST` off `origin/ralph/LAND-0830I`. Owner directive mid-task:
*"ensure that the game is using all of the characters we generated in meshy
somewhere in the game where it's appropriate. not just reusing the same 3 NPCs
when we generated 25."* That directive redirects this lane away from the
bench-the-body fix T1-HALL-3 applied and toward using every installed rig.

## 1. What is installed vs what actually stands in the world

28 humanoid rigs are installed under `assets/characters/` and 31 keys in
`data/config/art.json` point at them. Counting real placements in shipped data
(`config_key` / `base` in `data/config/**`, not tests, not comments):

| Rig | Placements | Where |
|---|---|---|
| trainer | player | player body |
| grandpa | scene | Grandpa Elias |
| warden | boss | `stronghold_climax.gd` |
| villager_male / villager_female | 20 | every villager AND every non-Tether trainer |
| grunt | 3 | rank default for grunt/officer/captain |
| grunt_a / grunt_b / grunt_c | 3 / 3 / 2 | Tether rank-and-file, bands 1-5 |
| officer_a | 2 | Officer Dell, Warder Ness |
| captain_a / captain_b | 2 / 2 | Vance, Oreth, Halder, Vess |
| innkeeper, inn_helper, trader, craftsperson, creature_caretaker, farmer, local_historian, field_researcher, lost_traveler, alpha_tracker, courier, former_tether_member | 1 each | the twelve civilians placed this week |
| **officer_b** | **0** | **stranded** |
| **young_trainer** | **0** | **stranded** |
| **rival_trainer** | **0** | **stranded** |
| **wandering_trainer** | **0** | **stranded** |

**Four generated bodies stand nowhere in the game.** They are installed, baked,
wired into `art.json`, and never referenced by any placement.

## 2. Why they are stranded, and the second half of the defect

`officer_b` was the Warden's courtyard figure. JUDGE-5 D2 condemned it blind;
T1-HALL-3 fixed that by deleting the `base` override, which returned the
courtyard to the rank's shared `grunt` rig and left `officer_b` with no home.

The other three were never placed at all — and the reason is visible in the
data. **Every non-Tether trainer in the chapter is wearing a villager body:**

| Trainer | Role | Currently |
|---|---|---|
| `practice_trainer` Bryn | the chapter's first trainer fight | `villager_farmer` (villager_female) |
| `trainer_mira` / `trainer_oskar` / `trainer_tam` | the three village trainers | villager rigs |
| `tournament_quarter/semi/final` | the tournament ladder | the same three villager rigs again |
| `old_champion_bram` Old Bram | the retired champion | `villager_farmer` — the **female** villager rig |
| `pasture_drover_juno` Juno | the band-4 roadside trainer | `villager_ranger` |

Nine trainer fights, two bodies between them, while three purpose-built trainer
rigs sit unused. `old_champion_bram` on `villager_farmer` is also a straight
mismatch: the same character is `villager_keeper` (male rig) as a villager in
`village_npcs.json` and a female rig as a trainer.

## 3. The idiom split (JUDGE-5 D2, measured)

Measured over the alpha-masked, non-empty region of each atlas
(`docs`-free repro in this report's own commit):

| Group | median luma | mean lit RGB |
|---|---|---|
| production rigs (trainer/grandpa/warden/villagers) | 0.169 - 0.258 | warm, browns/olives/creams |
| `grunt` (Tether production rig) | 0.140 | (0.198, 0.143, 0.141) mauve-maroon |
| Meshy Tether cast (grunt_a/b/c, officer_a/b, captain_a/b) | **0.086 - 0.114** | purple-black, no oxblood |

The seven Meshy Tether bodies are a different rendering language: crushed
near-black grounds, saturated purple-magenta accents, blown-out flat faces with
painted eye/mouth, and hair as a solid magenta mass. That is what the blind
judge read as "from a different game" — and it is a property of the seven
atlases, not of the one figure that happened to be standing in the courtyard.

## 4. The regression in the Warden's courtyard — what put her there, and what stands there now

**What put her there.** `data/config/bands/band5_stronghold_approach/trainers.json`,
entry `stronghold_courtyard` (Warder Solene). T3-INSTALL gave that entry a
`base: "officer_b"` override, which `trainer_npc.gd::model_config()` passes to
`npc_ranks.gd::config_for()` as `base_override`, replacing the rank's own default
body for that one trainer. The rank's default *is* `grunt` for grunt, officer and
captain alike, so before T3-INSTALL the courtyard fielded the oxblood grunt
silhouette JUDGE-5 preferred.

**It was already fixed on this branch before this lane started, and this lane
verified rather than assumed it.** T1-HALL-3 deleted the override for the three
bodies standing inside the Hall (`stronghold_courtyard`, `stronghold_patrol`,
`stronghold_elite`) after reading JUDGE-5 D2. The courtyard therefore returns to
the rank's shared `grunt` production rig. See §7 for the rendered frame.

**But the fix stranded the asset, and the defect was never cast-wide fixed.**
Deleting the override took `officer_b` out of the game entirely (§1) and left the
other six generated Tether bodies — all carrying the same idiom — standing in
fourteen fights across bands 1-5. JUDGE-5 read one figure; the property it
condemned belongs to seven.

## 5. The black-NPC defect did NOT hold. It reopened on the captains.

`ralph/MEADOWS_EXIT_CRITERION.md` C1 records the defect as "closed 2026-08-30
with measurements — grunts 13→31.5/255 day, 15→51.7 night". Those numbers are
real and this lane reproduces them. They cover two ranks of three.

`character_model.gd`'s additive emission floor is gated on **tint luminance
< 0.95**. The captain's palette multiply is `#ffffff` *by design* — it is the
identity step of the value ladder, "the brightest of the three grunt-rig ranks IS
the texture as painted". So the gate reads the captain as a bright character
needing no help. T1-LIGHT's own comment says as much, and treats it as correct:
the floor "still skips the trainer/Grandpa/villagers/captain/Warden, unchanged".

That is right for four of those five. They have their own bright textures. It is
wrong for the captain, who is on the **same near-black grunt-family texture the
floor exists to rescue** (`captain_a`/`captain_b` median 0.093 — the darkest
character atlases in the game).

Measured through the real build path, `tools/_probe_rank_ladder.gd` (new, this lane):

| rank | individual | texMedian | albedoMul | emissAdd | **effective** |
|---|---|---|---|---|---|
| grunt | Dorn / Pell / Kest | 0.101-0.113 | 0.863 | 0.155 | 0.242-0.253 |
| officer | Dell / Ness | 0.102 | 0.933 | 0.168 | 0.263 |
| captain | **Vance / Oreth / Halder / Vess** | 0.093 | 1.000 | **0.000** | **0.093** |

**The ladder ran backwards.** The four captains the player actually fights
rendered at roughly a third of the officers below them, and were the darkest
humans in the game — the exact defect C1 claims closed, on the rank carrying the
most story weight.

**Fix.** The floor is now declared by the rank (`npc_ranks.json`'s own
`emission_floor`, 0.18 — T1-LIGHT's own render-verified constant) instead of
inferred from how bright the albedo multiply happens to be. `npc_ranks.gd`
carries it into the config; `character_model.gd` applies it to body surfaces when
the config declares one. A character with no rank has no key, gets 0.0, and takes
the untouched branch — so nothing outside the three Tether ranks moves.

After, same probe:

| rank | individual | **effective** |
|---|---|---|
| grunt | Dorn / Pell / Kest | 0.242-0.253 |
| officer | Dell / Ness | 0.263 |
| captain | Vance / Oreth / Halder / Vess | **0.273** |
| grunt / officer / captain | rank defaults | 0.273 / 0.296 / **0.317** |

Grunt and officer are unchanged to the third decimal — their adds are still
0.155/0.168 — so T1-LIGHT's measured result is preserved exactly. The captains
lift 0.093 → 0.273, and the ladder ascends by rank.

## 6. The idiom split, fixed in the atlas rather than by benching the bodies

Purple/magenta share of saturated pixels, before → after
(`tools/regrade_tether_textures.py --check`):

| rig | before | after |
|---|---|---|
| production rigs (trainer, villagers, grandpa, grunt) | 0.0-0.1% | *(reference, untouched)* |
| grunt_a | 2.7% | 0.0% |
| grunt_b | 24.5% | 0.0% |
| grunt_c | 4.7% | 0.2% |
| officer_a | 24.3% | 0.3% |
| officer_b | **34.8%** | 0.2% |
| captain_a | 20.9% | 0.0% |
| captain_b | 19.6% | 0.4% |

The tool rotates only that hue band, toward the hue the hand-built `grunt` rig
already sits at (median 354.7°, measured off the faction's own shipped body, not
picked), weighted by depth-into-band and by saturation so nothing near-neutral
steps and no banding appears at the selection edges. Skin, leather, metal, cream
and the reserved tether teal are untouched. No Meshy spend, no new mesh, no
re-rig — `CLAUDE.md` names materials and textures as the sanctioned lever, and
`npc_ranks.json` had already used it once when it moved the faction colour "into
the texture".

`data/config/palette.json` reserves `tether_oxblood` (#332228) and says why:
"it appears only on Team Tether banners, equipment and uniforms, never on
friendly or neutral elements. A reserved colour is what lets a player read threat
at distance without a marker." Seven bodies rendering magenta were not spending
that reservation. JUDGE-5 said the courtyard swap "cost the Team Tether colour
identity"; this is that cost measured and paid back.

## 7. What was standing in the Warden's courtyard, and what stands there now

**Was:** Warder Solene on `officer_b` — a generated Meshy body carrying an anime
idiom and a purple-magenta palette with no oxblood in it, put there by
T3-INSTALL's per-trainer `base` override.

**Now:** Warder Solene on the rank's shared `grunt` production rig — masked and
capped, in the faction's dusty oxblood with a sigil cap badge, crossed straps and
a belt rig. Rendered on this branch, `ralph/reports/T1-CAST/shots/hall/H-07-courtyard.png`,
`capture_check` passing ("grass field bound to this camera and drawing").

Measured off that frame, so the "blown-out flat white face" claim is answered with
numbers rather than a look:

| region | mean luma | clipped (>0.95) |
|---|---|---|
| face/mask | 0.498 | **0.0%** |
| torso uniform | 0.339 | 0.0% |
| legs | 0.269 | 0.0% |
| stone wall behind | 0.375 | 0.0% |
| cobble floor | 0.259 | 0.0% |

Nothing is clipped anywhere on the figure. The face is a pale cloth mask, lit, not
blown. The torso sits between the wall (0.375) and the floor (0.259) — a person in
clothing against the architecture, which is C1. The uniform reads against the
oxblood banners above the doorway as the same faction.

## 8. What did NOT get fixed, and why it is an owner question

The regrade fixes colour. It cannot fix a face.

The lineup render (`shots/rank_variety/12-lineup-all.png`, all eleven named
grunt/officer/captain fights, post-regrade) shows the rank silhouette ladder
working — grunts in short jackets, officers with chest chevrons, captains in full
long coats with shoulder mantles, readable at lineup distance without a nameplate,
which is C2. It also shows that **two of the seven generated bodies still do not
belong in this world, and no material pass will change that**:

- **`grunt_c` (Pell, the Warrens watch)** is a chibi-proportioned figure in cargo
  shorts and ankle socks with oversized stylised eyes. Its cyan hair is fixed
  (1.9% → 0.00% teal); its build and face are geometry.
- **`grunt_b` (Dorn, the quarry picket)** has the same oversized-eye face and a
  hair mass that regrades from magenta to rose but stays a bright hair mass.

Both stand in Band 2, early, where the player is forming their first read of who
Team Tether is. The colour identity is now right on both. The drawing idiom is not,
and it is baked into the mesh and its face texture.

**This is where I stop rather than invent.** `CLAUDE.md`: a new humanoid mesh is
exceptional, must solve a real unmet player-facing need, and *still requires
owner-supplied reference art* — and **never spend a Meshy generation without
owner-supplied reference art.** I have none for these two. So, as an owner
question rather than a spend:

> `grunt_b` and `grunt_c` read as anime characters in a painted stylised-realism
> world, in the mesh rather than the material. Three options: (a) leave them —
> they are now in the faction's colour and only two of fourteen Tether fights are
> affected; (b) bench both and let those two fights take the shared `grunt` rig,
> which costs the per-individual identity T3-INSTALL added and puts two bodies
> back on the shelf; (c) re-generate the two heads against owner-supplied
> reference art, which is the only option that both keeps the bodies and fixes
> the idiom, and which needs reference art I do not have.

`rival_trainer`, `young_trainer` and `wandering_trainer` carry no such problem —
they were drawn in the world's own idiom and are placed (§9).

## 9. What this lane changed

**Placement — every installed humanoid rig is now used somewhere.**

| Body | Was | Now |
|---|---|---|
| `young_trainer` | nowhere | Bryn, the chapter's first trainer fight |
| `wandering_trainer` | nowhere | Old Bram, the retired champion off the Band 1 road |
| `rival_trainer` | nowhere | Juno, the Band 4 trainer road |
| `officer_b` | nowhere | Warder Ness, the Sigil-gate checkpoint |

No new trainer fight was added. T3-LADDER removed three fights that existed only
to house meshes, and it was right to — the chapter's 24-opponent ceiling is
enforced by `test_chapter_content_map.gd` and Band 1 was already the "monotonous
trainer hallway" Prompt 59 warns about. Every placement here **reassigns an
existing fight**, so the census is unchanged and the bodies are spent on
characters the player already meets.

It also fixes two things nobody had caught:
- **Old Bram was wearing the female villager rig.** `villager_farmer` resolves to
  `villager_female_lod0.glb`; the same character's `village_npcs.json` entry uses
  the male one.
- **Warder Ness had `base` declared twice** in one JSON object. The later key
  wins, so T3-INSTALL's override was silently dead. Found by
  `test_trainers_data.gd` after this lane's own edit collided with it; a scan of
  every trainer table found no others.

**Code and data.**
- `data/config/npc_ranks.json` — new per-rank `emission_floor` (§5).
- `scripts/characters/npc_ranks.gd` — carries it into the built config.
- `scripts/characters/character_model.gd` — body-surface floor now reads the
  rank's declared value instead of inferring one from tint luminance.
- `tools/regrade_tether_textures.py` — new; the atlas regrade (§6), idempotent,
  no Meshy spend.
- `tools/_probe_rank_ladder.gd` — new; the ladder measurement (§5).
- `tools/_capture_t1_cast_world.gd` — new; player-distance world frames of the
  four reassignments, `capture_check` at every shutter.

## 10. The regrade took three rounds; here is what each one actually bought

Convergence, not a round count (`ralph/conventions.md`). Each round was judged
against a re-rendered `shots/rank_variety` set, not against the atlas thumbnails.

**Round 1** — hue band `[258,342]` with a triangular falloff from the band centre,
chroma ramp `0.12 → 0.30`. Measured the purple share down to 0.0-0.4% at the
`s>0.30` threshold and the render confirmed the uniform FIELDS had moved. Two
things it did not fix, both visible in the lineup: `grunt_c` (Pell) still had
bright cyan hair, and the officers' and captains' chest chevrons and coat panels
were still pale lilac.

*Note on the falloff:* a triangular weight from the band centre was the first
attempt and it barely moved anything — `grunt_b` went 24.5% → 23.7% — because its
purple sits out near the band edges where a triangle has no weight left. Replaced
with a plateau plus soft shoulders before round 1 was judged.

**Round 2** — added a second pass for the cyan/blue band, chroma ramp lowered to
`0.06 → 0.20`. Marginal. Pell's hair rotated *partway* and parked at green, which
is not an improvement over cyan, just a different wrong colour; the pale lilac
panels moved barely at all.

**Round 3** — one root cause explained both leftovers. The chroma ramp was gating
out exactly the pixel class that was failing: **high value, low chroma** — the pale
panels, and the mint highlight speckles scattered through Pell's hair once its
brown base had rotated. Those sat at the bottom of the ramp and rotated a fraction
of the way. A pale pixel with a real hue should rotate fully — pale lilac and pale
rose differ in nothing but hue, and a pixel with no hue at all is already excluded
by `rgb_to_hsv`'s own `d < 1e-6` guard. Ramp dropped to `0.02 → 0.06`; the cyan band
widened to `[132,232]` so a partial rotation cannot park inside it.

Result, measured at the low-chroma threshold `s>0.04` where the residue actually
lives:

| rig | purple/magenta | cyan/blue |
|---|---|---|
| grunt_b | 0.05% | 0.00% |
| grunt_c | 1.26% | 0.63% |
| officer_a | 0.19% | 0.00% |
| officer_b | 0.20% | 0.00% |
| captain_a | 0.11% | 0.00% |
| captain_b | 0.40% | 0.00% |
| *`grunt`, the production reference* | *17.16%* | *0.12%* |
| *`trainer`, not a subject* | *0.27%* | *8.90%* |

The production `grunt` rig reads 17% "purple" at this threshold because oxblood at
low chroma sits right on the red/purple boundary — which is the point: the
generated cast is now well inside the range of the body the project built by hand.
The trainer's own teal jacket (8.90%) is untouched, because the pass is scoped to
the seven Tether subjects and never sees him.

**Stopped here.** Pell's hair is plain brown at 5× magnification, cyan and speckles
both gone. What is left in the lineup is a mauve cast on the chevrons and coat
panels — and that is **lighting, not texture**: the atlases measure 0.11-0.20%
purple, so a desaturated maroon under the bare stage's cool fill is what is
reading lilac. Another regrade round cannot touch it, and the stage's lighting is
not the game's.

## 11. Evidence

All frames on this branch under `ralph/reports/T1-CAST/shots/`, plus
`shots/rank_variety/` for the controlled ladder set.

| Frame | What it shows | capture_check |
|---|---|---|
| `shots/hall/H-07-courtyard.png` | the Warden's courtyard as it now ships | pass |
| `shots/world/01-bryn-practice-field.png` | Bryn on `young_trainer`, village practice field | pass |
| `shots/world/02-bram-off-road.png` | Old Bram on `wandering_trainer`, Band 1 clearing | pass |
| `shots/world/03-juno-trainer-road.png` | Juno on `rival_trainer`, Band 4 road | pass |
| `shots/world/04-ness-sigil-checkpoint.png` | Warder Ness on regraded `officer_b`, Hall visible behind | pass |
| `shots/rank_variety/12-lineup-all.png` | all eleven named grunt/officer/captain fights together | n/a (bare stage) |

**`capture_check` earned its keep twice on this lane, on my own tool.** Round 1 of
`_capture_t1_cast_world.gd` did not hand Terrain3D the capture camera and did not
pin the weather, and the check refused the frames for exactly that. Round 2 tripped
"the capture camera's own position is inside 'Player'" — that one is the tool's own
doing (it parks the hidden player at the camera so the grass ring and terrain
bubble stream to the stand, the same trick `_judge_capture_hall.gd` uses), so the
player is now passed in `ignore_bodies` the way that tool passes it, and the check
still applies to every other body.

The tool also carries `_judge_capture_hall.gd`'s hard-won settle lesson: **two
settle passes with a real drawn frame between them, not one long one.** Frame count
was never the lever — that tool measured the same stand at 5.5% and 54.6% green
cover seconds apart in one run, because what a stand waits on is Terrain3D
streaming the region in, and `grass_field` places its tufts in a shader off the
live height and region maps.

At player distance (8-9m, where the challenge prompt comes up) all four
reassignments read as people who live in this world, and the grass field is dense
and present in every frame.

## 12. Acceptance — section C

- **C1, NPCs read as people in clothing, never silhouette cutouts.** Was **not**
  met on this branch despite being recorded as closed: captains rendered at 0.093
  against grunts' 0.242-0.273. Now met, measured — captains lift to 0.273, and the
  courtyard officer measures 0.339 torso against a 0.375 wall with 0.0% clipping
  anywhere on the figure.
- **C2, rank readable on sight.** Met, and now monotonic: rank defaults ascend
  0.273 / 0.296 / 0.317. The lineup shows the silhouette ladder doing the primary
  work as designed — grunts in short jackets, officers with chest chevrons,
  captains in full long coats with shoulder mantles.
- **C3, the cast is varied enough that the Meadows feels populated.** Improved:
  four bodies that stood nowhere now stand somewhere, and the nine non-Tether
  trainer fights no longer share two villager rigs between them.
- **C4, named characters visually individual.** Improved: Bryn, Old Bram, Juno and
  Warder Ness each have their own body instead of a repaint, and Old Bram is no
  longer on the female villager rig.

## 13. Open — for the owner

1. **`grunt_b` and `grunt_c` are anime in the mesh** (§8). Three options laid out
   there; the only one that both keeps the bodies and fixes the idiom needs
   owner-supplied reference art, and `CLAUDE.md` forbids spending a Meshy
   generation without it. **No generation was spent on this lane.**
2. **`captain_accessory` is installed but is not a rig** and was not audited here;
   it appears to be a prop rather than a body.
3. The chapter is at its **24-opponent ceiling** (`test_chapter_content_map.gd`).
   Every placement here reassigned an existing fight for that reason. If a rival
   rung is ever authored — T3-LADDER flagged it as a real story-structure decision
   and deliberately left it to whoever shapes the escalation — the census has to be
   spent deliberately, not inherited because a mesh existed.
