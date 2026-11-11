# G-things-t4-rescore: 18 more F36 (1) pose rows re-scored on main (GPU High)

## Frames and method
- **Frames:** `tb/gpu-frames-1108`.
  - Section a: 32de092b2 (sparkit, riftfrill, shadelet, pebbik, mirejaw, thundertunnel, paddlenewt, mosshock, brooktail).
  - Section b: 35bd6ae29 (trailpup, solmane, cliffspike, voltwig, stormtrail, duskhush, breezetail, stormraven, ashtusk).
  - Both are one-sided on main 3a514ef5c, High, with no overlay.
- **Crop and brief:** the same as the earlier pose re-scores. Crop 560,200 1000×640. Tiles: standing (hit 000), hit 050, faint 050, faint 100. Brief: F36 (1). Recorded defects: the 24 Oct roster causes where the roster lists one.
- **Render check:** blank frames 0 of 90 per section. An eye check of all 18 standing frames showed every creature inside the crop.
- **Batches:** G-t4a and G-t4b, three fresh code-blind judges each, standard prompt. Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. Both are confirming batches.

| Batch | Slope | Intercept | r | RMSE | Warnings |
|---|---|---|---|---|---|
| G-t4a | 1.1329 | −0.196 | 0.930 | 0.366 | none |
| G-t4b | 1.2228 | −0.8051 | 0.952 | 0.305 | solmane meets the bar only above the top anchor (7.53); this is the confirming batch |

Read changes against the board as indicative (about ±0.3). The board scores come from other judge pools.

## Per-row mapped scores, sorted

| Row | Board | Main now | Change | Raw a, b, c |
|---|---|---|---|---|
| **F36#69 Solmane** | 6.68 | **7.63** ↑top | +0.95 | 7.0, 6.6, 7.1 |
| **F36#58 Pebbik** | 6.07 (CPU) | **7.47** | +1.40 | 7.0, 6.7, 6.6 |
| F36#35 Breezetail | 6.89 | 7.31 | +0.42 | 6.8, 6.5, 6.6 |
| F36#75 Stormtrail | 6.82 | 7.22 | +0.40 | 6.8, 6.3, 6.6 |
| F36#40 Cliffspike | 6.72 | 7.02 | +0.30 | 6.3, 6.4, 6.5 |
| F36#36 Brooktail | 6.63 | 6.90 | +0.27 | 6.2, 6.2, 6.4 |
| F36#33 Ashtusk | 6.96 | 6.90 | −0.06 | 6.4, 6.2, 6.3 |
| F36#87 Voltwig | 6.79 | 6.78 | −0.01 | 6.2, 6.2, 6.2 |
| F36#54 Mosshock | 6.55 (CPU) | 6.68 | +0.13 | 6.2, 6.1, 5.9 |
| F36#70 Sparkit | 6.03 (CPU) | 6.60 | +0.57 | 6.4, 5.8, 5.8 |
| F36#44 Duskhush | 6.85 | 6.53 | −0.32 | 5.8, 6.0, 6.2 |
| F36#83 Trailpup | 6.64 | 6.53 | −0.11 | 6.0, 5.8, 6.2 |
| F36#74 Stormraven | 6.94 (CPU) | 6.37 | −0.57 | 5.8, 5.6, 6.2 |
| F36#57 Paddlenewt | 6.49 | 6.34 | −0.15 | 5.9, 5.9, 5.5 |
| F36#62 Riftfrill | 6.04 | 6.30 | +0.26 | 6.2, 5.5, 5.5 |
| F36#66 Shadelet | 6.06 | 6.15 | +0.09 | 6.0, 5.4, 5.4 |
| **F36#80 Thundertunnel** | 6.47 | **5.92** | −0.55 | 5.6, 5.4, 5.2 |
| **F36#52 Mirejaw** | 6.23 | **5.28** | −0.95 | 5.2, 4.7, 4.6 |

- **Summary:** 10 rows up, 3 level and 5 down. The mean change is +0.11.
- **Solmane (7.63, meets the bar at High):** capture Medium next.
- **Close-out candidates at 7.0 or above:** pebbik 7.47, breezetail 7.31, stormtrail 7.22, cliffspike 7.02.

## For LANE-BELOW6 (below 6)
- **Mirejaw 5.28.** Its tail passes through the trainer in every frame (PRESENT 3/3). In the hit frame the head becomes "a pale translucent jaw shape" (2/3). It sits low, at about the trainer's head. There is a stretched dark bar on the tail.
- **Thundertunnel 5.92.** It has a flat pinkish-tan "flesh" material. Its white cracks read as mud fissures or decals, not lightning. It has a single cartoon disc eye, and the faint end is a "faceless ball" (3/3). Two judges ask for new art.

## For LANE-THINGS: faints the judges say do not read or ground
| Species | Faint problem named | Judges |
|---|---|---|
| duskhush | crumpled feather heap, no head; head turned away in standing and hit | 3/3 |
| cliffspike | "quill pile", head and legs gone | 3/3 |
| solmane | wings swallow the body and head | 3/3 |
| stormraven | wing or tail stands up as a "rigid flat slab" or "blade" (hit and faint) | 3/3 |
| shadelet | tail rises into a rigid hook in the air (faint), reaching the trainer | 3/3 |
| thundertunnel | faceless ball | 3/3 |
| trailpup | belly-up, legs in the air, "reads as dead"; faint mid a featureless tube | 3/3 |
| stormtrail | flat pelt or sheet; faint mid a featureless tube | 3/3 |
| voltwig | belly-up "lumpy green log" | 3/3 |
| mosshock | headless spike lump | 3/3 |
| pebbik | belly-up with a stiff upright tail | 3/3 |
| breezetail | belly-up, head twisted, or a fluffy blob | 3/3 |
| sparkit | legs-up sprawl; S-bent spine in the hit frame | 2/3 |
| paddlenewt, riftfrill | stray spikes stick up off the back in the faint end | 3/3 |

**Other shared causes:**
- **Tail at or through the trainer:** mirejaw (every frame), brooktail, shadelet, riftfrill, sparkit, ashtusk (trainer overlaps the hind legs). Staging or pose spacing.
- **Floating stray hair cards or specks** above the back: stormtrail, ashtusk, riftfrill (3/3).
- **Missing elemental trait or rim light:**
  - trailpup: no amber paws or eyes, so the recorded "stock animal" defect is still PRESENT 3/3;
  - stormraven: the streaks read as specular, not lightning;
  - sparkit: no electric trait;
  - duskhush;
  - ashtusk: embers only show in the faint.
- **Mesh shared by riftfrill and paddlenewt** (3/3 in G-t4a): an identity problem, new_art.
- **Brooktail:** oversized glowing spots read as a decal pattern (3/3).
- **Ashtusk:** tusks clip the floor in the hit frame (3/3).

**Owner rules:**
- **Red:** no red or oxblood leak on any creature. Mirejaw's orange frill (1/3) and ashtusk's tusk bases (1/3) are borderline and read as ember or rust.
- **Height:** every creature is taller than the trainer. Sparkit's back is still below the trainer's head (1/3).

**Pose re-score across all 37 rows:**
- **Up:** 16 rows moved up by 0.25 or more.
- **Closed:** stormbrush.
- **Meeting the bar at High:** solmane.
