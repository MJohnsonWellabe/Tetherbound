# G-closeout-stormtrail-stormbrush: Stormtrail at High, Stormbrush Medium margin check (slate stage; GPU)

## Verdict
- **Stormtrail does NOT close.** High is **7.36** (per judge 7.50, 7.02, 7.56). Medium was 7.72 (G-reverify-f36-medium).
- **F36#72 Stormbrush stays closed.** Medium on the corrected slate stage is **7.56** ↑top (7.56, 7.44, 7.68). That repeats the black-stage 7.55, and this time the lowest judge is 7.44 rather than 7.20.

| Row | Preset | Mapped | Per judge | Bar |
|---|---|---|---|---|
| Stormtrail | High | **7.36** | 7.50, 7.02, 7.56 | no (Medium 7.72) |
| F36#72 Stormbrush | Medium | **7.56** ↑top (confirming) | 7.56, 7.44, 7.68 | holds (High 7.68) |

## What holds Stormtrail (High)
- **Faint flattens:** "faint flattens to a sheet" is PARTIAL 3/3.
  - Faint mid is "squashed flat with the head twisted" (1/3).
  - Faint end lies on its side "a little sheet-like" or "pancaked" (2/3).
- **Detached particles:** the floating pale orbs and yellow sparks "look detached from the body, like generic particles" or "read as noise, not a lightning trait" (3/3).
  - One judge asks for "glow markings that follow the fur" in their place.
- **Placeholder look:** "flat black placeholder look" is FIXED 3/3. All three call it a naturalistic coyote close to the style bar.
- **Close-out fixes** (both sub-0.5; it sits at 7.36 High):
  - give the faint end volume: head visible, body rounded on its side;
  - replace the loose orbs with markings attached to the body.

## Stormbrush notes
- Both recorded defects (plastic-blue fur, hidden ruler) are FIXED 3/3.
- The faint end is still "an unreadable fur mound with the face hidden" (3/3), and "dark value without rim light" (1/3). That is the margin item if the row ever reopens.

## Frames
- **Source:** `tb/gpu-frames-1108`.
  - G-closeout-stormtrail-high (0277db694), High.
  - G-closeout-stormbrush-medium (9bc958900), Medium.
- **Build:** main 90ffeb663, which carries #925 (preset reaches the stage) and #926 (slate backdrop restored, corner (43,50,56)). One side.
- **Capture:** `capture_f36_poses.gd --whole-body --context --roles=hit,faint`.
- **Health:** the logs confirm the preset applied. 0 script errors.
- **Sets:** the standard pose crop and tiles, F36 (1) brief, one-sided.
- **Recorded defects:**
  - Stormtrail: "flat black placeholder look with emissive bands", "faint flattens to a sheet".
  - Stormbrush: "oversaturated plastic-blue fur", "bulk hides the trainer ruler".

## Batch `G-csb`
- Three code-blind judges, standard prompt, two candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.1876, intercept −0.7563, r 0.923, anchor RMSE 0.38.
- **Warning:** Stormbrush meets the bar only above the top anchor (7.53). This batch is its confirming batch.
- **Raw:** each judge scored the two identical sides 0–0.1 apart; the means are used.

| Row | Raw (judges a, b, c) |
|---|---|
| Stormtrail | 6.95, 6.55, 7.0 |
| Stormbrush | 7.0, 6.9, 7.1 |
