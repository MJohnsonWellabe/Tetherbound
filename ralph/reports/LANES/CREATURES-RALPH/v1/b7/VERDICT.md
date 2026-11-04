# Visual lane v1/b7: stage poses for Terrapup (F38#2 stage) and Nightburrow (F36#56), ground-clip and amplify recipe (3 Nov 2026, ~16:00 UTC)

**Arm:** pose recipe on the live remake GLBs (`ground_clip.py rest --percentile=3 --settle`, `ground_clip.py hit --hop=0.3`, `amplify_clip.py hit 1.8 --bones=spine,spine_2,root`) vs the shipped GLBs. Frames: the f36n neutral stage (hit react mid and end, faint mid and end, beside a 1.80 m ruler), base and candidate in the same CPU run. CPU llvmpipe, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs (f36_0_gap:C4, f36_0_npc:C6, craft; a confirming batch), three fresh code-blind judges, `calibrate.py`: linear, slope 0.64, intercept 2.36, r 0.42. **Warning:** anchor RMSE 0.80 is above 0.75, so these mapped scores carry a weak-fit caveat.

| Row | Item | CPU base (mapped) | Pose arm (mapped) | Decision |
|---|---|---|---|---|
| F38#2 (stage) | Terrapup hurt and faint | 6.50 | 6.47 (-0.03) | GLBs not kept |
| F36#56 | Nightburrow hurt and faint | 6.11 | 6.11 (0.00) | GLBs not kept; as shipped maps 6.11 (was 5.66) |

**Judges:** all three call both pairs ties. On both sides:
- **Hurt pose:** hit react mid reads as hurt, but hit react end returns to the idle silhouette.
- **Faint pose:** the faint frames are grounded.
- **Recorded defect:** PARTIAL on both rows, 3/3.

The amplify and ground-clip recipe does not change what the judges see at stage size. Real gains need:
- A distinct hurt-end keyframe and a side-collapse faint.
- Lighter plating on Nightburrow: all three judges call its yellow and purple plates "full-body overgrowth" that hides the face in faint.
- Rim light on the dark coats.

**Nightburrow F36#56:** the shipped model maps 6.11 in this batch. This crosses 6.0 as shipped, with the RMSE caveat. Its earlier 5.66 came from a different batch.
