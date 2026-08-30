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
| **Draw calls added** | **+220** (3365 → ~3585 against a 4000 ceiling). Counted per surface off the exported GLBs, not estimated. |

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

### 2.2 The ruin layer — 574 instances, 20 draw calls, `$0`

`stronghold.gd::_build_ruin_reclaim()`, driven by
`stronghold.json`'s new `hall_occupation.reclaim` block: **312 ivy** and **262
rubble** instances across 14 + 6 `MultiMeshInstance3D` bands, clustered rather
than evenly spaced.

**The pack's first-named free source was already in the repository.** It names
"Quaternius Medieval Village MegaKit" as a starting point for ivy, moss, vines,
broken wall tops and rubble; `assets/buildings/quaternius_medieval/` has shipped
since the village work and contains `Prop_Vine1`, `Prop_Vine2`, `Prop_Brick1`,
`Prop_Brick2` and 60 other modules. Nothing needed downloading. That single fact
is what made the $0 target comfortable rather than tight.

### 2.3 The retrofit layer — 19 props, 74 draw calls

`stronghold.gd::_build_tether_retrofit()` and `_build_tether_pipe_runs()`.
Placement is a system, not a scatter, per the pack's "coherent retrofit layer,
not randomly scattered props":

- **3 siphons escalating along the player's route** — courtyard, tether approach,
  and the hero one on the Warden arena wall, each with a higher core energy than
  the last.
- **2 boilers** where work happens, with **4 pipe runs going from a boiler to a
  siphon**, so the machinery reads as one installed system.
- **6 scaffolds** — two on the south elevation the causeway reads, two on the
  exterior flanks, two inside the courtyard.
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
   material it is **220**. A prop costs its *material* count, not its part count.
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

*(filled in below — renders, measurement, and test results)*

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
