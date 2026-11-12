# G-newapproach-post-setting: authored NPC posts, with and without the post camera (F40#9; GPU High)

Frames: `tb/gpu-frames-1108` 04e5b4474, High, seed 2042, `tb/newapproach` fb4ff2c0e.
- Capture: `phase2_capture_characters.gd --biome=cloudreach`, subsets keeper_maela, naturalist_sora and young_trainer_tavi.

Four sides:

| Side | Overlays | Camera spring length |
|---|---|---|
| base | tree as is | 5.2 m |
| focus | base + `NEWAPPROACH-POSTFOCUS/overlay_post_focus.json` | 3.6 m |
| focusset | focus + `NEWAPPROACH-POSTSET/overlay_post_setting.json` (fill 0.7 → 1.3, role props, round-stone dais, Sora moved) | 3.6 m |
| setonly | the setting overlay with `post_focus.enabled` false | 5.2 m |

The post camera is held for an owner decision, so **setonly is the version that can land without it.**

Sheets: Maela, Sora and Tavi, stacked at full size. Two paired sets on F40#9's brief and recorded defect:
1. focus against focusset;
2. base against setonly.

Render check (pixels changed):

| Comparison | Maela | Sora | Tavi |
|---|---|---|---|
| focus → focusset | 4.7% | 34.6% | 6.7% |
| base → setonly | 4.4% | 3.7% | 9.3% |
| base → focus (camera move) | 51% | 28% | 25% |
| setonly → focusset (camera move) | 53% | 28% | 26% |

The Sora move shows strongly only with the post camera on. Blank frames: 0 of 3 on each side.

Batch `G-ps`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.241, intercept −1.0919, r 0.888, anchor RMSE 0.637. No warnings.

## Verdict: the setting gains +1.16 at 3/3 both ways. **setonly maps 6.48 and clears 6 without the post camera.**

| Pair | Without setting | With setting | Gain | Judges preferring setting |
|---|---|---|---|---|
| (1) focus → **focusset** (post camera on both) | 5.32 | **6.48** | **+1.16** | 3/3 |
| (2) base → **setonly** (today's camera) | 5.32 | **6.48** | **+1.16** | 3/3 |

Raw Bar A (judges a, b, c):
- without the setting (focus and base): 5.3, 5.2, 5.0;
- with the setting (focusset and setonly): 6.3, 6.0, 6.0.

Recorded defect: without the setting, PRESENT 3/3; with it, PARTIAL 3/3, on both pairs.

**Absolute mapped scores:** focusset 6.48 and setonly 6.48. **Both clear 6.** The board has F40#9 at 5.72. setonly is the landing candidate, and it takes F40#9 above 6 on its own.

### The two pairs scored identically: read this as "the setting dominates"
- **Every judge gave the same numbers in both pairs** and described them as "the same two variants with the sides swapped". The camera distance does differ between the pairs: 25–53% of pixels change from the 5.2 m camera to the 3.6 m camera.
- **What the judges keyed on** was the bare grey discs against the propped, cobbled posts. In this batch the camera difference did not move their scores.
- **The post camera on its own** gained +0.71 in `G-newapproach-post-focus.md`, a separate batch. With the setting in place, this batch cannot separate any further camera gain.
- **For the owner decision on the post camera:** in this batch it adds nothing measurable on top of the setting.

## What the judges see
- **With the setting:** each NPC stands on a cobbled or stone dais in front of a workbench, stall and bookshelf, or a training-dummy rack, so "the post reads as a role" (3/3).
- **Without it:** the posts are "bare flat grey discs", "a debug pedestal" or "placeholder" (3/3). Sora is mostly hidden behind the wall corner and the trainer.
- **The warm hotspot on Maela's tree trunk (focusset):** no judge raised it.
  - Judge c notes only that "a tree trunk crowds the left of the pad" in Maela's frame.
  - Judge b says the trunks "frame it but crowd it".

## What still holds F40#9 below 7 (with the setting, 3/3)
- **NPC size:** the NPCs stay small, smaller than the 1.80 m trainer and partly overlapping him (Tavi and Maela). Costumes are visible but tiny, and no pose signals a job.
- **Mixed assets:** a saturated orange dirt path, grass carpets and big cartoony trunks around the pale Cloudreach stone (judge b).

## What would add the most (all scene)
1. **Posts and framing:** use the dais and workbench posts everywhere, and frame each NPC clear of the trainer and walls at a larger on-screen size.
2. **Role poses:** give each NPC a pose that signals its job.
