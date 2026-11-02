# HALL-1: F17#6 Crossing Hall GPU swing, High (31 Oct – 1 Nov 2026)

**Verdict: the HALL-1 candidate improves the Hall by about +0.7 at High on every set. It does not close F17#6.**
- **Best arm, r2b:** main 5.40 → **6.18 (+0.78)** in its batch. Every set clears +0.5: approach-nave +0.60, nave-sides +0.80, shrine +0.94.
- The candidate is ready to land OFF and then flip, or to build on. It is on a local branch exported here as patches (`patches/`), like the POSE-1 handoff. Not pushed anywhere else.
- **MET: no.** High maps about 6.2–6.5 against a 7.5 bar, so no Medium run was made (owner rule: High first).

## Baseline: current main has moved since 24 Oct

Main ade041d97 has changed since the 24 Oct F17-6 GPU pass:
- the Forward+ shafts are off;
- the arch facades are on;
- the nave furnishing is in.

So I judged main first, one-sided: **6.18 at High** (approach-nave 6.43, nave-sides 6.19, shrine 5.92; fit r 0.94). On 24 Oct it was 5.83. The judges still named three defects:
- near-field posts: PRESENT 3;
- bare hall: PARTIAL 3 (the grade is warm now; the shrine cobbles read as a courtyard);
- no warm shrine focal: PARTIAL 3 (only a small cool-blue font).

## Arms (each judged against main's frames in its own batch, three code-blind judges, high anchors)

| Arm | What it adds | Main → arm (batch mean) | approach-nave | nave-sides | shrine | Fit |
|---|---|---|---|---|---|---|
| r1 | z ±6 posts out, two lit hearths, warm altar halo, shrine rug, aisle table | 5.70 → 6.33 (+0.63) | +0.63 | +0.52 | +0.74 | r 0.96 |
| r2a | r1 + z 12 posts out, altar's own emissive mask lit warm gold, candle stands at the altar | 5.78 → 6.46 (+0.68) | +0.45 | +0.64 | +0.94 | r 0.98 |
| **r2b** | r2a + darker night: ambient 0.35 → 0.22, lantern night scale 1.5 → 1.8 | **5.40 → 6.18 (+0.78)** | **+0.60** | **+0.80** | **+0.94** | r 0.90 |

- Absolute levels drift between batches: main maps 5.40–5.78. Compare the gains within a batch, not the levels across batches.
- Sides were balanced in every batch. r2a was redrawn once, with anchor seed 1, because its first draw put all three candidates on side A.

**Defect calls, r2b vs main:**
- **Shrine focal:**
  - shrine set: PARTIAL 2 / FIXED 1, against main PRESENT/PARTIAL;
  - nave sets: still PRESENT, because those views end at purple doors or the tether gate.
- **Posts:** still PRESENT in nave-sides on both arms. Those are the **stone arch piers** (the arch facades, judged +1.1 at High, kept). The timber posts are gone from approach-nave (PARTIAL).
- **Bare hall:** PARTIAL on both.

**What it looks like** (`_sheet_hall1.jpg`, main left, r2b right):
- the nave opens up with the middle timber posts gone;
- a lit hearth sits in a west bay and another on the Shrine Room's north wall;
- a woven rug covers the shrine cobbles;
- the altar glows warm gold, with candle stands either side.

The altar's glow blooms toward white at night, and the plaster around it runs hot.

## Path to 7.5 (gap about 1.0–1.3, from the judges' notes, all scene work)

1. **Near field:** the stone arch piers frame the nave-arches and nave-forward views. The F17-6 cameras are fixed, so this means slimmer pier facades, or a camera-set revision that the owner signs off.
2. **Grouped furnishing:**
   - tables, benches, crates and sacks in clusters, not an even scatter;
   - villagers at the tables;
   - hanging cloth lower down.
3. **Light:**
   - pull the plaster exposure down, since the walls blow out in the shrine;
   - warm window shafts with a little haze (Forward+-safe, unlike the old additive quads);
   - a night that is clearly darker, with warm pools. r2b moves this, but the shrine at night still reads close to day.
4. **The altar glow:** cap it so it reads as gold, not white (the mask energy is 1.6 now).

## Candidate code (local branch tb/hall-1, 5 commits on main ade041d97, all OFF)

- **`data/config/crossing_hall.json`:** a new `hall_1` section, `enabled: false`, with three lists:
  - `merge`: nested overrides — the rugs, and the night ambient and lantern scale;
  - `append`: extra list rows — the hearths and flames, the warm altar, the candle stands, the aisle table, stools and logs;
  - `remove`: rows dropped by name — the z ±6 and z 12 posts, braces, ties and lanterns; WallBenchL3; ShrineGlow, re-added at 1.5; the old altar row.
- **`scripts/world/crossing_hall.gd`:** `apply_hall_1()` layers the section onto the config before anything is built. With the flag off, the config is byte-for-byte as shipped.
- **`scripts/world/crossing_hall_great_hall.gd`:**
  - a `rugs` list reuses the runner shader, with an optional yaw;
  - pieces take an optional `ignite_energy`, so the camp flame burns.
- **`tests/test_crossing_hall_hall_1.gd`:**
  - OFF leaves the config unchanged;
  - merge, append and remove behave as described;
  - remove matches unnamed rows by model;
  - every named row and section exists, and every appended model is installed.
- **Tests:** run headless on the imported tree with `--only=crossing_hall,f17_companion_interior`: **20 tests, 99 / 107 assertions (r1 / r2), 0 failed** (`yardstick/HALL1-*tests.log`). r2b adds only two `merge` keys inside the OFF section.
- Everything uses installed assets: `meshy-1024/ranger_hearth`, `generated_camp/camp_flame`, `quaternius_fantasy`, and the altar's own `hall_shrine_altar_emissive_mask.png`. No import changes.

## Capture

- **Main:** local import of ade041d97, `capture_camera_set.gd --set=F17-6.json --preset=High`, 15 views, first try.
- **Arms:** tb/hall-1 imported once. Each arm byte-copies `crossing_hall.json` from a local flag-on commit: r1 bbe84f4d2, r2a b65e387bd, r2b 2b53ce465. Same command, all first try.
- **Judging:** the three five-view groups of every earlier F17-6 round (approach-nave, nave-sides, shrine), with the 24 Oct brief and recorded defects (`build_yard_hall1.ps1.txt`).
- **Files:** yardsticks are in `yardstick/HALL1M` (main one-sided), `HALL1C` (r1), `HALL1R2A` and `HALL1R2B`.
