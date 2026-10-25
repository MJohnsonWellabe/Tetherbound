# Creature emission floor on Forward+: overlay verification (24 Oct 2026, GPU)

**Result:**
- The coordinator's renderer-aware floor (`creature_emission_floor_forward_plus_scale`, Compatibility unchanged) removes the F22#4 ghost.
- It also removes a **roster-wide daylight wash** on plain-PBR creatures.
- **Recommended scales:**
  - **base (day) ×0.0;**
  - **`times.night.environment` ×0.05**, an effective night floor of 0.011.
  - ×0 at night leaves Cindercub (black coat) barely readable.
  - **×0.1 and above whitens** pale coats again.

## 1. F22#4 Riverwatch at Medium with the overlay

- **Batch:** a fresh 3-judge batch, `yardstick/`.
  - Built with `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`; `JUDGE_PROMPT.md` verbatim.
  - Calibration: slope 1.148, intercept 0.065, r 0.93, anchor RMSE 0.44. Confirming batch, no warnings.

| Side | Mapped per judge | **Mapped mean** | Ghost (j1/j2/j3) |
|---|---|---|---|
| **Medium, overlay** (paired with Low) | 7.30 / 7.53 / 7.18 | **7.34** | FIXED ×3 |
| **Medium, overlay** (paired with shipped Medium) | 7.07 / 7.41 / 7.07 | **7.18** | FIXED ×3 |
| Medium, shipped | 5.12 / 5.00 / 5.12 | 5.08 | PRESENT ×3 |
| Low, shipped | 6.84 / 6.72 / 6.04 | 6.53 | FIXED ×3 |

- **Overlay Medium averages 7.26:** +2.18 on shipped Medium and +0.73 on Low.
- **It is now the best renderer for this fight.** The judges named its darker, better-separated grade and its larger splashes against Low's "yellow-olive over-grade".
- **Still below 7.5.** The asks left on every side:
  - the combat HUD covers about a third of the frame;
  - the player's creature is lost under the rings at combat distance;
  - i08 frames off the otter.

## 2. Day: how wide the wash was

- **Stands:** Medium, matched stands from `tools/_capture_night_legibility.gd`, run through the local copy `nl_capture.gd.txt`:
  - the copy adds a shell-ready wait, a frozen clock and an env-selected time and species list;
  - a wild Mudsnout and Bramblebun;
  - 8 fixed species on the same spot: Sparkit, Cindercub, Bramblebun, Ripplet, Mudsnout, Trailpup, Paddlenewt, Terrapup.
- **Sheet:** `_sheet_ef_day.png`, with shipped on top and the overlay below.
- **Shipped, floor 0.08:** every plain-PBR creature reads milky grey or white in daylight:
  - Cindercub grey (its coat is black);
  - Ripplet pale grey-blue;
  - Terrapup grey-white (brown);
  - Paddlenewt, Bramblebun, Trailpup and Mudsnout washed.
- **With the overlay (Forward+ ×0):** their true coat colours return. Sparkit changes least.
- **So the F22#4 ghost was this same wash,** at its most visible on a large dark-furred boss.

## 3. Night: choosing the Forward+ night scale

**Stands:** the same fixed spot at night, shipped night floor 0.22 × the Forward+ scale (`_sheet_ef_night_sweep.png`).

| Scale (effective floor) | Cindercub (black) | Bramblebun | Ripplet (blue) | Sparkit (pale) |
|---|---|---|---|---|
| ×1 (0.22, shipped) | flat white ghost | white ghost | white ghost | white ghost |
| ×0.5 (0.11) | white ghost | white ghost | white ghost | pale |
| ×0.25 (0.055) | pale grey ghost | pale | white ghost | pale |
| ×0.1 (0.022) | grey, form reads | natural | **washes pale** | natural |
| **×0.05 (0.011)** | **dark grey, form and face read** | natural | blue, slightly lifted | natural |
| ×0 | near-black; reads faintly against the moonlit grass | natural | true blue | natural |

- On Forward+ the floor acts far more strongly than its number. Even 0.055 turns a black wolf pale grey.
- **The lowest setting that keeps Cindercub readable without whitening anything is ×0.05.**
- **How it was swept:** through the base key, which the night blend inherits because `times.night.environment` does not set it. That gives the same pixels at night as the night-override form.

## Run notes

- **Source:** main 45865499d plus the overlay (`overlay_applied.diff.txt`, applied by `emission_overlay.py.txt`). The local checkout was restored after every arm; `git status` is clean for both files.
- **Hardware:** GTX 1060, Forward+ Medium, 1920x1080 (F22 at 1280x720), isolated APPDATA.
- **Queues:** `ef_queue.ps1.txt` (shipped, then overlay) and `ef_sweep.ps1.txt` (night scales).
- **Not covered here:** the F36#0 and F36#1 pose-stage captures. That stage never instantiates WorldLook, so the floor there is the static default 0.0, and those GPU numbers already had no floor.

## Files

- `_sheet_ef_f22.png`: Riverwatch at Medium (shipped / overlay / Low), i05, tell1 mid and after.
- `_sheet_ef_day.png`: day, shipped vs overlay, every stand.
- `_sheet_ef_night_sweep.png`: night, ×1 / ×0.25 / ×0.1 / ×0.05 / ×0.
- `yardstick/`:
  - `key.json`, `sets.md`, `candidates.json`, `recorded_defects.txt`, `judge_prompt_filled.txt`;
  - `j1`–`j3` (condensed), `batch.json`, `mapped.json`.
