# G-meshy-f41-8-distinct-bodies: distinct bodies for the Stormwood named trio (F41#8; GPU High)

**Frames:** `tb/gpu-frames-1108` 9faf56418, High.
- **base:** `tb/item-f41-8-bodies` c1733ce49 with `distinct_bodies_1111` OFF. All three characters are on `local_historian`, one caned and cloaked elder body in different robe colours.
- **arm:** base plus `MESHY-F41-8-BODIES/overlay.json`:
  - Elder Maud unchanged;
  - Rodkeeper Hesk on the installed `alpha_tracker` body;
  - Warden-elect Bryn on `lost_traveler`.
- **Frames:** inventory character frames of elder_maud, rodkeeper_hesk and warden_elect_bryn, stacked top to bottom at 1280×720 per side.
  - A first build put the three side by side at 853×480. It was rebuilt before judging because the villagers were too small to compare.

**Render check:** 0.9% (Maud), 1.1% (Hesk) and 1.1% (Bryn) of pixels changed. Blank frames: 0 of 3 per side. The villagers are small in these inventory frames, so the change is a small patch of each frame.

**Batch `G-f418`:**
- Three code-blind judges, standard prompt.
- F41#8's brief: "named character silhouettes", with the recorded defect "Many distinct named roles in Tidewake and Stormwood repeat the same face body and outfit silhouettes".
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. This is a confirming batch.

**Fit:** linear, slope 1.2508, intercept −0.9057, r 0.944, RMSE 0.329. No warnings.

## Verdict: +0.29, 2 of 3 judges prefer the arm, no frame loses. It passes the ship rule but is below 0.5 and far from the bar, so it should ride inside a larger change, not land alone

| Side | Raw a, b, c | Mapped | Recorded defect (a / b / c) |
|---|---|---|---|
| base | 5.0, 4.6, 5.6 | **5.43** | PRESENT / PRESENT / PARTIAL |
| arm | 5.6, 5.0, 5.3 | **5.72** | PARTIAL / PARTIAL / PARTIAL |
| gain | | **+0.29** | prefer arm: a, b (2/3); c prefers base |

- **Scores:** base 5.43 is in line with the board's 5.31. The arm reaches 5.72, so the row stays below 6.
- **Defect:** the repetition defect improves on every judge, from PRESENT 2/3 on base to PARTIAL 3/3 on the arm.
- **Owner rule:** a change gaining under 0.5 does not land alone, and the close-out exception does not apply at 5.7.

## What the judges say
- **Arm (judges a and b):** "three distinct silhouettes: a purple-robed elder, a stocky bearded man in brown leather [goggles and pack], a young brown-haired villager".
- **Base (judges a and b):** the second villager is "another white-haired elder with a staff ... too close to row 1's head and hair read".
- **Judge c, the dissent:** on the arm, Hesk and Bryn "share a tan-and-brown palette and a similar silhouette at this size". Judge c read base's purple, tan and blue robes as more distinct by colour.
  - **Cheap follow-up:** give Hesk or Bryn a contrasting outfit colour. That addresses judge c's dissent at small size.
- **Background repeats (judge a):** "repeated armoured figures" appear in the background of rows 1 and 2, so the defect stays PARTIAL on the arm.

**What holds F41#8 down (top change, 3/3, scene): the Stormwood frame, not the bodies.**
- crushed black pools covering about half of each frame, with aliased edges;
- posterised, noisy moss;
- a flat lilac sky card with no lightning;
- small, over-bright, near-white villagers with no rim light, which "glow against the scene" (2/3);
- salmon-pink bears in row 1 (3/3).

This overlaps the Stormwood storm-light pass (#5 in `LOW-HANGING-6TO7.md`).

## Recommendation
1. **Keep the arm flag-off for now, and land it inside the Stormwood grade/storm-light swing.**
   - It passes the ship rule (+0.29, 2/3, no loss), but it is under 0.5 on a 5.4 row.
   - The judges place the row's real ceiling in the scene grade and the villager lighting.
2. **When it rides, recolour one of Hesk and Bryn** so their tan-brown palettes differ.
