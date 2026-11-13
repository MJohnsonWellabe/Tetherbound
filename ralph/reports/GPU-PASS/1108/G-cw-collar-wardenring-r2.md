# G-cw: Fulgocobra slate collar (F36#46, F41#13) and Warden ring r2 at High (F38#28) (GPU High)

## Verdicts
- **Fulgocobra slate collar: SHIP.** Both sets gain, 3/3 prefer the arm, and no set loses.
- **No red or oxblood is left on the arm's Fulgocobra.** All three judges name the base's copper-red neck plates as "close to oxblood" on both sets. None see red on the arm. My render check agrees: 0 red pixels on every arm pose frame (base 0.002–0.019 %). In the world frames the only red left is the cottage door and timbers, a crate and the orange trail, the same on both sides (shiny_idle, which has no copper, reads the same 0.87 %).
- **Warden ring r2 at High: DO NOT SHIP as a gain.** It is level against r1 (−0.04, 0/3 prefer r2, 1/3 prefer r1), and the other Warden frames are identical. **F38#28 does not close:** r2 High reads 6.87. Medium is held for the re-run, and a High under 7.5 already rules out a close in this round.

| Row | Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|---|
| **F36#46** | Fulgocobra pose stage (hit, faint) | 5.29 | **5.70** | **+0.41** | 3/3 | 5.84, 5.42, 5.84 |
| **F41#13** (cobra half) | Fulgocobra world states (Stormwood) | 6.12 | **6.54** | **+0.42** | 3/3 | 6.40, 6.40, 6.82 |
| **F38#28** | Warden ring row frames, High (r1 → r2) | 6.91 | 6.87 | −0.04 | 0/3 (1/3 prefer r1) | 7.10, 6.82, 6.68 |
| no-loss | Other Warden frames, High (r1 → r2) | 6.77 | 6.77 | 0.00 | identical per judge | 6.96, 6.54, 6.82 |

## Fulgocobra collar
- **Why it gains.** The copper-red plates read as "bolted-on armour", "visually unrelated to the gold-banded body" and "close to oxblood" (3/3, both sets). The slate version is not flagged by any judge.
- **What still holds the row (3/3, both sides):**
  - Pose stage: "the faint does not reach the ground" and "hood stays up in the faint" are PRESENT; "dark body on the stage" is PARTIAL. The neck stays arched at about trainer height in faint mid and faint end.
  - World: the charge defect is PARTIAL. Eyes and the hood-rim cyan line read; the body has no lightning veins at this distance.
  - The world fainted frame shows the hood as a large flat disc facing the camera (2/3). The hurt frame shows the hood as a dark flat disc (1/3).
- **Next (3/3, new art):** a grounded faint with the hood folded and the neck and head on the floor, plus lightning veins along the body.

## Warden ring r2 (F38#28)
- The teal boundary is PARTIAL on both sides (3/3): "a thin curved line", no longer thick or straight, but still read as guide geometry and still crossing the Burrowback in frame 3.
- The other holds are shared: one orange-brown value band in the hall flattens creatures into the floor (3/3), and the win frame's flat heart and key icons float over a dark floor (3/3).
- Lowering warden_aldis's boundary alpha 0.12 → 0.05 does not register. The judges' asks are a grounded in-world edge (stones, scorch or a dust ring) and a cool fill to separate creatures from the floor.
- **Pooled F38#28 High:** 7.05 (G-co) and 6.91 (this r1 base), ≈ 6.98. Medium stays at 7.52 (G-co, r1) until the held Medium re-run is judged.

## Frames
- **Collar poses:** `tb/gpu-frames-1108` section `G-below6-fulgocobra-collar-poses` (f919d655e), High, `tb/below6` fa88105d8. Base: no flag. Arm: `creature_coat_flags below6_fulgocobra_slate_collar`. `capture_f36_poses.gd --game-clips --clear-ruler`, hit and faint 000–100. Render diff 0.08–0.11, all in the collar.
- **Collar world:** section `G-below6-fulgocobra-collar-world` (29e40f773), Stormwood creature states, `--fixed-fps 20`, High. Render diff 0.18–0.55. shiny_idle was left out because it is identical on both sides.
- **Warden ring:** section `G-things-wardenring-r2-high` (94da43aeb), `tb/things` a85dde69b, Meadows fight, `--fixed-fps 20`, High. Base: `overlay_warden_ring.json` (r1). Arm: `overlay_warden_ring_r2.json`. Render diff 0.6–0.73 on the row frames, 0.2–0.79 on r04, r16 and a03. Cameras match on every frame.
- **Health:** 0 script errors on every manifest frame.
- **Sets:**
  - F36#46: the pose-stage 2×2 of hit-000, hit-050, faint-050 and faint-100, cropped (560, 200, 1560, 840), with G-fb's recorded defects.
  - Fulgocobra world: idle, moving, attacking, hurt, resting and fainted in a 2×3 grid, with F41#13's recorded defect.
  - F38#28: warden_aldis-03, 05 and 08 stacked, with its recorded defect.
  - No-loss: r04, r16 and a03, with no defect.

## Batch `G-cw`
- Three code-blind judges, standard prompt, four candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch, and no candidate is above the top anchor.
- **Fit:** linear, slope 1.396, intercept −1.971, r 0.964, anchor RMSE 0.27. No warnings.
- Yardstick: `yardstick_g_cw_collar_wardenring_r2/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F36#46 | 5.3, 4.9, 5.4 | 5.6, 5.3, 5.6 |
| Fulgocobra world | 5.8, 5.6, 6.0 | 6.0, 6.0, 6.3 |
| F38#28 High (r1 / r2) | 6.6, 6.3, 6.2 | 6.5, 6.3, 6.2 |
| Other Warden frames (r1 / r2) | 6.4, 6.1, 6.3 | 6.4, 6.1, 6.3 |

Bar B: no on every candidate set (3/3).
