# CREATURES-F36 r7: coat value lift batch 2 (CPU, three judges)

**Verdict: GPU READY.** Arm `tb/co-f36-5-on` c2b5851b4, built on `tb/co-f36-4-on` 529829e88 (control: main a41e1b30). All three species gain at least 0.5.

| Species | Live coat (probed) | Median value | Mapped main | Mapped arm | Gain | Dark-body defect (main / arm) |
|---|---|---|---|---|---|---|
| **Stormtrail** | `creature_trailpup_nat1024_Image_0_stormtrail.png` | 0.31 -> 0.44 | 5.63 | **6.88** | **+1.25** | PRESENT x3 / PARTIAL x3 |
| **Shadelet** | `creature_shadelet_lod0_base_color.jpg` | 0.21 -> 0.34 | 5.59 | **6.63** | **+1.04** | PRESENT x3 / PARTIAL x3 |
| **Nightburrow** | `creature_burrowback_nat1024_Image_0_nightburrow.png` | 0.25 -> 0.30 | 5.72 | **6.30** | **+0.58** | PARTIAL x3 / PARTIAL x3 |

**Fit:** linear, slope 1.25, intercept −1.25, r 0.98, RMSE 0.18. Confirming batch (craft, f36_0_npc:C1). No warnings.

**Targets:**
- GPU roster 24 Oct: shadelet 6.29, "near-black, no rim light; silhouette dissolves".
- GPU roster 24 Oct: stormtrail 5.98, "flat black placeholder dog".
- CO12 (31 Oct): nightburrow 6.67, "coat noisy and speckled".

**Screened out:** Riftfrill, Mangrove Monitor and Mirejaw. Their coat textures are mid-value (median 0.45–0.63); they read dark on screen from lighting or gloss, so a value lift is not their fix.

**Arm shape:**
- Same grade and hook as CO-F36-4.
- New flag `creatures_f36_coat_lift_2` (`enabled` false) in `data/config/creature_coat_flags.json`.
- Three new textures need one import.
- The night and storm variants take a gentler lift, so they stay darker than Burrowback and Trailpup.

**What the judges still see:**
- **Stormtrail:** blue glow patches on the fur, which the owner rule rules out as glowing seams on fur. They are main's variant glow map, not this change. It stands at about trainer height.
- **Shadelet:** its hit react leaps off the floor, and its faint-end tail passes through the trainer ruler.
- **Nightburrow:** a noisy mottled plate pattern ("generator noise"), and a blob faint.

Sheet `_sheet_r7.jpg`: main on the left, arm on the right; rows are Stormtrail, Shadelet, Nightburrow.
