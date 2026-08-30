# HANDOVER — T1-HALL-ART, 2026-08-30

**Branch:** `ralph/T1-HALL-ART`, off `origin/ralph/T1-HALL-ART` (which already
carried the consolidation and the owner's asset pack). `origin/ralph/T1-HALL-4`
merged forward at the start of the lane and again before the final render.

**Brief:** the owner's own
`docs/art/reference/hall-asset-pack-2026-08-30/HALL_ASSET_IMPLEMENTATION.md`,
treated as the contract, with its five art boards as the generation reference.

---

## 0. The four numbers the lane was asked for

| | |
|---|---|
| **Money spent** | **$0.00.** Budget was "target $0, hard cap $10". Nothing was purchased and no payment method was ever used. |
| **Meshy generations** | **Zero.** No credit spent. See §1 — this is the one place the lane did not follow the pack, and the reason is environmental. |
| **Assets downloaded** | **Zero.** The pack's own first-named free source turned out to be already vendored in this repository. |
| **Draw calls added** | **+208** (3365 → ~3573 against a 4000 ceiling). Measured on the shipped build by `tools/_probe_hall_art_fast.gd`, not estimated. Full breakdown in §4.4. |

---

## 1. Read this first: Meshy was not available, and nothing was bought

The pack's build path for all five props reads **"BUILD PATH = NEW MESHY PROP"**,
on every board. That did not happen, and the reason is not a judgement call:

```
$ echo "MESHY_API_KEY=[${MESHY_API_KEY:-UNSET}]"
MESHY_API_KEY=[UNSET]
```

`tools/art_pipeline/meshy.py` reads the key "from the environment and from
nowhere else" (its own header, line 19). With no key there is no Meshy. **No key
was hunted for, no credential store was searched, and no purchase was
attempted** — including the ~$5 itch.io fallback the pack names, which stayed
unbought because the free layer never failed.

So the five props are **authored procedurally in Blender** by a committed script,
`tools/art_pipeline/blender/build_hall_props.py`, against the boards' own
human-scale bars. That script's header carries the full reasoning and, more
importantly, the honest list of what it costs:

- **Genuinely lost:** surface micro-detail — rivet heads, oxidation mottling, the
  boards' painterly texture. These props carry flat PBR values.
- **Arguably gained:** the pack asks three times for "low-to-medium detail",
  "large forms, strong shapes", and "separate logical pieces". Assembled
  primitives are exactly that, and Meshy's track record on this project is the
  opposite — `docs/ASSET_LEDGER.md`'s camp-set row records a tent that took eight
  candidates across six rounds before the owner chose round one.

**If a Meshy budget is ever authorised, boards 02 (boiler) and 04 (siphon) are
the two worth spending it on.** They are the boards whose detail this cannot
reproduce. The other three are shape-dominated and lose little.

---

## 2. What was built

### 2.1 The five props — nine GLBs, 9,558 triangles, `$0`

`assets/environment/team_tether/hall/`

| Prop | Board | Height | Surfaces |
|---|---|---|---|
| `team_tether_scaffold_tower` | 01 | 4.5 m | 5 |
| `team_tether_boiler_chimney` | 02 | 3.5 m | 4 |
| `tt_pipe_straight` / `_elbow` / `_tee` / `_valve` / `_bracket` | 03 | 2.5 m envelope | 1–3 each |
| `rift_siphon_wall_machine` | 04 | 3.0 m | 4 |
| `team_tether_banner_rig` | 05 | 2.8 m | 3 |

The **Rift Siphon got the most attention**, as the pack asks. It is a caged
central chamber with eight bars and two binding hoops, a heavy iron frame
standing proud of a bolted backplate, two flanking tanks with conduits into the
chamber base, thick pipes arcing over the top, a control cluster with a red wheel
and brass dials, and a cable junction. **The core is a separate object with its
own material**, because the pack is explicit that the particle effect must not be
baked in — Godot supplies the emission and the light.

The pipe kit is **five separate GLBs**, because board 03 asks for a kit rather
than a sculpture.

### 2.2 The ruin layer — 631 instances, 20 draw calls, `$0`

`stronghold.gd::_build_ruin_reclaim()`, driven by
`stronghold.json`'s new `hall_occupation.reclaim` block: **515 ivy** and **116
rubble** instances across 14 + 6 `MultiMeshInstance3D` bands, clustered rather
than evenly spaced. (Both counts were revised by the render rounds in §4.2 --
ivy up so it reads at flank range, rubble down and bigger so it reads as fallen
masonry rather than gravel.)

**The pack's first-named free source was already in the repository.** It names
"Quaternius Medieval Village MegaKit" as a starting point for ivy, moss, vines,
broken wall tops and rubble; `assets/buildings/quaternius_medieval/` has shipped
since the village work and contains `Prop_Vine1`, `Prop_Vine2`, `Prop_Brick1`,
`Prop_Brick2` and 60 other modules. Nothing needed downloading. That single fact
is what made the $0 target comfortable rather than tight.

### 2.3 The retrofit layer — 17 props, 64 draw calls

`stronghold.gd::_build_tether_retrofit()` and `_build_tether_pipe_runs()`.
Placement is a system, not a scatter, per the pack's "coherent retrofit layer,
not randomly scattered props":

- **3 siphons escalating along the player's route** — courtyard, tether approach,
  and the hero one on the Warden arena wall, each with a higher core energy than
  the last.
- **2 boilers** where work happens, with **4 pipe runs going from a boiler to a
  siphon**, so the machinery reads as one installed system.
- **4 scaffolds** — two on the south elevation the causeway reads, two inside
  the courtyard. (Two exterior-flank scaffolds were authored and then removed:
  they hung 18 m in the air on top of the skirt. See §4.2.)
- **8 banner rigs**, gate face to arena.

**No colliders anywhere in either layer.** None of these meshes is named `-col`,
so Godot's glTF importer builds no collision. A player can walk through a siphon.
That is the correct trade: a machine bolted to the inside of the Warden's arena
wall must not be able to snag a boss fight.

---

## 3. Four mistakes this lane made and caught, worth knowing

1. **The first cut would have blown the draw-call budget by ~450.** Exporting
   each primitive as its own object — which is what "prefer separate logical
   pieces" reads like — gave a 63-object scaffold and a 49-object siphon, and the
   placement list came to **~1087 draw calls against 635 of headroom**. Joined by
   material it is **208**. A prop costs its *material* count, not its part count.
   `join_by_material()` in the build script.

2. **An interior-only ruin layer would not have moved one judged pixel.** Every
   stand in `tools/_judge_capture_hall.gd` is *outside* the complex. The first
   config dressed interior walls only. Eight exterior ivy bands and four exterior
   props were added once that was noticed.

3. **Two props were authored facing into the stone.** The south-elevation
   scaffolds and gate banners were placed at z −12.3 with yaw 180 — inside the
   wall's own 1.2 m thickness *and* turned to face the masonry. The exterior face
   is at −12.63. Fixed, and then the orientation was **verified in glTF space by
   reading the exported accessors' min/max**, not by reasoning about Blender's
   axis convention — which is how the fourth mistake was found:

4. **The banner rig was authored with its wall on the opposite axis from the
   other four props.** Correcting board 05's bracket put the stone at +Y while
   every other prop has it at −Y; the glTF Y-up export maps those to opposite
   sides, so one Godot yaw convention could not have placed all five. Caught by
   the accessor probe, not by eye.

---

## 4. Evidence

### 4.1 `smoke_stronghold` — a FAILURE that is NOT this lane's, isolated and proved

`tests/smoke_stronghold.gd` fails on this branch:

```
warden_arena -> legendary_chamber: ended 21.5m from its centre (allowed 16.0)
FAIL: walking from 'warden_arena' toward 'legendary_chamber' never got there (21.5m short)
```

**It is not mine, and that is established by measurement rather than by
argument.** The test was re-run with this lane's three layers switched off at
the config (`reclaim`, `retrofit` and `pipe_runs` emptied, which is all three
builders' no-op condition) and everything else identical:

| Run | Result |
|---|---|
| This lane's layers **on** | `ended 21.5m from its centre` — FAIL |
| This lane's layers **off** | `ended 21.5m from its centre` — FAIL |

**The identical number to one decimal place.** The Hall's route is bit-for-bit
unaffected by everything this lane adds, which is the expected result for a
change that introduces no colliders — none of the nine GLBs is named `-col`, so
Godot's importer builds no collision for any of them, and `MultiMeshInstance3D`
has none either.

**What the failure actually is**, for whoever picks it up: the player is stopped
at x ≈ −10.5 walking west out of the Warden's arena, whose west wall is at
x = −12. The `warden_arena → legendary_chamber` passage is 5.0 m wide and the
walk is a straight push along z = 90.2 for 600 frames — at ~4 m/s that is ~40 m
of budget against a 32 m journey, so this is a **blocked walk, not an exhausted
frame budget**. The three earlier legs all pass. That points at the passage
opening or its door, not at the walker. The brief mentioned a separate lane is
fixing a real placement bug under the finale; this may well be the same bug seen
from the other side.

**One thing this lane did change as a result**, even though it could not have
caused the failure: the hero siphon was authored at z 88.0 on the arena's west
wall, and that passage opening spans z 87.7–92.7. The machine was standing *in
the doorway to the Legendary Chamber*. It has no collider so it blocked nothing,
but it was wrong to look at, and it now sits at z 82.5, clear of the opening.

### 4.2 Renders — and the rendering trap that cost this lane most of its time

**Frames:** `ralph/reports/T1-HALL-ART/shots/F-01..F-05`, from
`tools/_probe_hall_art_fast.gd` (new).

**The trap, because it is written down in this repo and I still walked into it.**
`ralph/conventions.md` line 246 says, in bold, that `--headless` **hangs forever**
with a real rendering driver and calls it "the single most expensive trap in this
repo", listing four abandoned capture attempts on 2026-08-22 alone. I spent
several rounds re-running `_judge_capture_hall.gd` with `--headless`, watched it
print `[playground] spawned` and go silent every time, and misdiagnosed it twice
— first as CPU contention, then as processes being restarted by something — before
reading the convention that names the exact symptom. The correct invocation drops
`--headless` and keeps `xvfb-run`. **Read `ralph/conventions.md` before your first
capture, not after your fourth.** The zombie processes that file also warns about
were real and were mine.

**The fast rig.** `tools/_judge_capture_hall.gd` boots the entire Meadows
playground — Terrain3D, ~130k scattered props, the village, the NPC cast — which
is 5–8 minutes before a shutter opens, plus two 60-frame settle passes per stand
waiting for grass and terrain streaming. That cost is correct for the judge's
stands, because what is judged there is the fortress *against its landscape*.
It is entirely wasted when the question is "is the asset layer right". So
`_probe_hall_art_fast.gd` builds **only** `stronghold.gd` under `art.json`'s own
sun, sky and tonemap and shoots five stands in **seconds**. It turned a
multi-round guessing loop into four render-and-look iterations.

**Its frames are deliberately NOT evidence for the JUDGE-6 silhouette
measurement**, and the script header says so: there is no hill, no ground and no
scatter in them, so `_t1hall4_measure.py`'s fortress/hill boxes have nothing to
compare against and any luminance number off them would be meaningless. **That
measurement is therefore NOT closed by this lane** — see §6.

**What the frames do show, and what four rounds of them fixed:**

| Round | Defect found in the frame | Fix |
|---|---|---|
| 1 | ~260 rubble bricks read as **bright white polystyrene cubes** | `MI_RockTrim` imports at `metallic=1.0` — a defect `building_prefabs.json` already records for this exact material. Forced to 0.0, tinted to the Hall's own `site.stone`, and scaled up 1.5–3.4× (fallen blocks off a 9 m wall are head-sized) |
| 1 | Two flank scaffolds **hanging 18 m in the air** | `site.skirt` is 18.0, so the complex floor is 18 m above the ground outside the flank walls. Scaffolds need ground; they were removed rather than dropped to the skirt foot. Banners stay — a bracketed banner needs no ground |
| 2 | **No exterior ivy at all** | Bands sat at ±11.68 against a face at ±11.63, so half of every band was inside the wall and the rest behind buttresses that stand 0.8 m proud. Moved clear of the *buttress* line, not the wall line |
| 3 | Exterior ivy read as **specks** at flank range | The kit's vine is 2.6 m and the flank stand is ~45 m out. Scaled 1.9–3.4× and count raised 1.9×. Free: a band is one MultiMesh whatever `count` says |
| 4 | A courtyard scaffold **standing in front of the yard's emblem banner** | Moved south, clear of it |

**Measured on the final build, by the rig itself rather than estimated:**

```
reclaim: 631 instances / 20 batches
retrofit: 17 props, 64 surfaces, 3 siphon cores, 3 lights
pipes:   68 pieces, 124 surfaces
DRAW CALLS ADDED: 208
```

208 against 635 of headroom (3365 measured by T1-HALL-4, 4000 ceiling) → **~3573**.
All three siphon cores resolve, so all three glow.

### 4.3 A pre-existing artifact this lane found but did not cause

Thin **bright cyan-white vertical bars** hang beside several wall banners on the
exterior flanks (visible in `F-02` and `F-05`). I suspected my own brass and spent
a round dropping metallic to chase them. They are **not mine**: re-rendered with
`retrofit` and `pipe_runs` emptied, the bars are still there. They are almost
certainly the existing `_live_material()` teal conduits — `tether_teal` (#3fe8c4)
emissive at energy 1.4 blowing out to white under ACES. Flagged, not fixed;
it is outside this lane's asset scope and belongs to whoever owns the conduits.

*(The metallic drop was kept anyway — iron 0.65 → 0.05, brass 0.8 → 0.12. It was
the right change for a different reason: `gl_compatibility` has no reflection
probes, which is the same finding `building_prefabs.json` records for
`MI_RockTrim`, and high-metallic surfaces render flat rather than metallic.)*

---

## 4.4 PLACED IN THE WORLD vs merely present in the repo

An asset that is committed but not placed is not an improvement, so this table
separates the two honestly.

**Placed, and therefore actually visible to a player:**

| Asset | Placements | Where |
|---|---|---|
| `rift_siphon_wall_machine` | **3** | courtyard west wall, tether approach east wall, Warden arena west wall — escalating core energy along the route |
| `team_tether_banner_rig` | **8** | gate face ×2 (on the causeway), exterior flanks ×3, courtyard ×2, Warden arena ×1 |
| `team_tether_scaffold_tower` | **4** | south elevation ×2 (on the causeway), courtyard ×2 |
| `team_tether_boiler_chimney` | **2** | courtyard east, outer works west |
| `tt_pipe_straight` / `_valve` / `_bracket` / `_elbow` | **68 pieces** across 4 runs | boiler → siphon, along ancient walls |
| `Prop_Vine1` / `Prop_Vine2` (ivy) | **515 instances**, 14 MultiMesh bands | courtyard/outer-works/Warden interiors + south elevation and both exterior flanks |
| `Prop_Brick1` / `Prop_Brick2` (rubble) | **116 instances**, 6 MultiMesh bands | interior wall feet |

**In the repo but NOT placed anywhere:**

- **`tt_pipe_tee.glb`.** Board 03 asks for a T-junction and one was built, but
  `_build_tether_pipe_runs()` lays a run as a straight line and emits only
  straights, a valve, brackets and end elbows. **Nothing in the Hall uses it
  today.** It is 604 triangles of dead weight until a run branches. Either give
  the run builder a branch, or delete the asset — do not leave it looking like
  shipped content.

**Corrected cost numbers.** An earlier note in this lane quoted *574 instances /
20 batches / 218 draw calls*. Those were superseded twice, and the **final
measured figures** (printed by `_probe_hall_art_fast.gd` on the shipped build,
not estimated) are:

```
reclaim: 631 instances / 20 batches
retrofit: 17 props, 64 surfaces, 3 siphon cores, 3 lights
pipes:   68 pieces, 124 surfaces
DRAW CALLS ADDED: 208
```

The instance count went **up** (574 → 631) because the exterior ivy was scaled
and multiplied to read at flank range; the draw calls went **down** (218 → 208)
because two floating flank scaffolds were removed. That divergence is the lane's
central budget lesson in one line: **instances are nearly free, distinct props
are not.** 208 against 635 of headroom (3365 measured by T1-HALL-4, 4000
ceiling) → **~3573**.

**3 new OmniLights** (one per siphon, short-range interior fills). Note
`stronghold.json`'s `_comment_braziers` states the §7 *exterior* light budget is
spent to its ceiling of 18 exactly; these are interior and are declared here
rather than smuggled in, but a lane that re-counts that budget should know they
exist. They are opt-out per entry via `core_light: false`.

---

## 5. The reserved-colour conflict, flagged for the owner

**This is the one thing in the lane that is genuinely the owner's call, and it is
not blocking.**

`data/config/palette.json` reserves `tether_teal` (#3fe8c4) as "Team Tether's
ENERGY colour … pylon crystals, conduits, **rift energy**". Board 04 and the
pack's integration instructions call for **purple**, twice: "Purple Rift-energy
core", "Keep purple Rift glow selective".

Read as one system those conflict. Read as two they do not, and the boards
themselves say which: the siphon exists to *"siphon, stabilize, or redirect Rift
energy"* — so the purple is **the Rift's**, and the teal stays **Team Tether's
own**. The lane implemented that reading:

- purple (#a24bd8) appears on **the siphon cores and nothing else** in the Hall;
- no teal appears on any of the five new props;
- so `palette.json`'s reservation is not broken by anything shipped here.

If the owner would rather the siphons ran teal, it is one constant
(`SIPHON_CORE_NODE`'s sibling `SIPHON_RIFT` in `stronghold.gd`) plus the
`RIFT` value in the build script.

---

## 6. What is NOT done, honestly

- **The JUDGE-6 silhouette number is NOT re-measured, and this lane does not
  claim it.** That measurement needs the full-world capture
  (`_judge_capture_hall.gd`) because it compares the fortress against the hill
  and ground beside it, and the fast rig has no landscape in it. Every
  full-world attempt this session was lost to the `--headless` trap in §4.2, and
  by the time that was diagnosed the remaining budget went into the four
  render-and-fix rounds that the fast rig made possible — which I judged the
  better trade, because they fixed four real defects and the measurement would
  have confirmed a number T1-HALL-4 had already moved. **The one command that
  closes it** is:

      xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
        --rendering-driver opengl3 --resolution 1280x800 \
        --script tools/_judge_capture_hall.gd -- --only=H-02b
      python3 tools/_t1hall4_measure.py shots/hall0830

- **No Meshy generation happened**, so §1's micro-detail gap is real and open.
- **Broken wall tops and collapsed parapets were not built.** The pack asks for
  them ("use broken masonry pieces to destroy the 'perfect finished castle'
  silhouette") and the Quaternius kit ships no ruined modules. Rubble at the wall
  feet implies collapse; the parapets themselves are still intact. Cutting them
  procedurally out of the castle kit is the obvious next move and is a real piece
  of work, not a tweak.
- **No moss-in-mortar-joint treatment.** That is a material/decal job on the
  stone, not a prop job, and it is the highest-value remaining item in the pack's
  Layer 1 list.
- **The arched gate / keystone / portcullis upgrade was not attempted.** The kit
  has `Wall_Arch`, and `stronghold.gd::_build_gate_frame()` already owns that
  read; changing it risked colliding with T1-HALL-4's gate work for a gain the
  lane could not measure in time.
- **`assets/buildings/` has no ledger coverage beyond the four modules this lane
  ships.** Pre-existing gap, named in `docs/ASSET_LEDGER.md` rather than glossed.

---

## 7. What the next lane should do first

The owner's pack now lives permanently at
`docs/art/reference/hall-asset-pack-2026-08-30/`. It is the contract; read
`HALL_ASSET_IMPLEMENTATION.md` and **look at the five boards as images** before
touching anything.

In priority order:

1. **Close the JUDGE-6 silhouette measurement.** It is the one number the brief
   asked for that this lane did not deliver (§6). Two commands, both in §6.
   Do this before any new art, because it tells you whether the asset layer
   moved the number the owner and the judge actually care about.

2. **Read `ralph/conventions.md` line 246 before your first capture.** `--headless`
   plus a real rendering driver hangs forever. It cost this lane most of its
   session and it has now cost at least two lanes. Use
   `tools/_probe_hall_art_fast.gd` for iteration (seconds) and
   `tools/_judge_capture_hall.gd` only for judged evidence (5–8 min boot).

3. **Resolve `tt_pipe_tee`** — branch a pipe run through it or delete it (§4.4).
   Small, but it is the one place this lane left something that looks shipped
   and is not.

4. **Broken wall tops and collapsed parapets.** The pack asks for them
   explicitly ("use broken masonry pieces to destroy the 'perfect finished
   castle' silhouette") and the Quaternius kit ships no ruined modules. Rubble
   at the wall feet currently *implies* collapse the parapets don't show.
   Cutting ruined variants procedurally out of the installed castle kit in
   Blender is free, cohesive by construction, and is the highest-value remaining
   Layer 1 item. This is real work, not a tweak.

5. **Moss in the mortar joints.** A material/decal job on the stone, not a prop
   job. Second-highest Layer 1 value.

6. **The pre-existing cyan-white bars on the exterior flanks** (§4.3) — almost
   certainly `_live_material()`'s teal conduits blowing out under ACES. Not an
   asset problem; belongs to whoever owns the conduits.

7. **Do not re-litigate the free-asset layer.** The pack's named sources were
   already in the tree. If you need ruin pieces the kit lacks, author them from
   the installed kit before spending anything — the $0 result here was not luck,
   it was that `assets/buildings/quaternius_medieval/` already had 64 modules.

**If a Meshy budget is authorised:** boards **02 (boiler)** and **04 (rift
siphon)** are the two worth it. The other three are shape-dominated and the
authored versions lose little. Never spend a generation without the owner's
reference art — the boards are that art, and they are now permanent in the repo.
