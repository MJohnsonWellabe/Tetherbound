# Judge — round11-sentries (Team Tether Hall gate)

Comparing PREVIOUS (`round10/locations/`, 960x540) vs NEW (`round11-sentries/`, 1280x720) on the four named gate frames, plus a regression sweep on approach/courtyard day+night. Judged blind against `docs/reference/tetherbound-meadows-keyart.png` and `site/img/page-board.jpg` only.

## 1. gate-face-day — PASS

Two guards are now present and legible, one flanking each side of the arch, standing recessed against the red door drapes. Both read clearly as Team Tether grunts, back to camera: dark mauve/grey body armor, a crossed chest-strap harness, a belt with pouches, gloved hands, boots, and a covered/dark head (helmet or balaclava — no face detail, silhouette only). Stance and gear are legible enough to identify "guard," not just "NPC blob."

Measured height: cropping and 4x-upscaling each guard, head-top to boot-bottom is ~105–110px in the 720px-tall frame (~15% of frame height) — plausible for a person standing at that recessed distance behind the player, and the two guards measure within ~3px of each other, so left/right are scaled consistently.

Composition: the wooden crate the player is pushing sits low-center-foreground and does not occlude either guard — both are outside the crate's silhouette, one each side of the doorway. No prop clipping onto the guards was found. One pre-existing (non-regression) oddity: the pale heart/leaf-shaped cutout panels on the far left and right walls are an unrelated, slightly distracting shape — present unchanged in PREVIOUS too, so not new, but still worth a future look.

## 2. gate-face-night — PARTIAL

The guards are present at the same positions as day, but at normal viewing size they are close to unreadable — they read as near-black shapes barely differentiated from the dark stone/gate structure around them. Only after 3x crop+zoom does the silhouette (head, strap line, boot break) become legible.

Luminance check: sampling the guard body vs. the lit doorway/backdrop directly behind them gives average pixel luminance ≈3.2 (guard) vs ≈15.6 (doorway) — the guards are roughly 5x darker than what's behind them, i.e. true silhouettes with no rim/fill light picking them out from the surrounding blackness. That's consistent with "present but not really seen" rather than a rendering bug — nothing pops or z-fights — but it means a player glancing at this frame at night would very plausibly miss that guards are there at all.

## 3. gate-day (42m) — PASS

Cropping and 4x-zooming the gate structure in `10-stronghold-gate-day.png` shows two small humanoid silhouettes still standing flanking the arch opening, distinguishable from the stonework behind them (visible head/shoulder breaks against the red door color). Confirms the sentries read even from the ~42m approach framing, not just at the close gate-face shot.

## 4. Regression sweep — none found

- `approach-day` / `approach-night`: composition, tree placement, castle silhouette, sky, moon, and lighting are unchanged between rounds; only the render resolution changed (960x540 → 1280x720), which sharpens detail rather than hurting it.
- `courtyard-day` / `courtyard-night`: identical composition and prop layout in both rounds; the single guard already standing near the brazier/anvil on the right side of the courtyard is unchanged and unaffected. No new clipping, popping, or lighting shift spotted.

No frame in the NEW set looks worse than its PREVIOUS counterpart. The only cross-round difference is the resolution bump, which is a clarity improvement, not a regression.

## Verdict

**NEXT ROUND** — day-side sentries are a clear win (gate-face-day and gate-day both PASS), but gate-face-night is only PARTIAL: the guards exist and are geometrically correct, yet at night they are near-invisible silhouettes (~5x darker than the doorway behind them) with no light picking them out, so the "two guards flank the gate" read that works by day effectively disappears after dark. Next round should add or check for a night-side light source (torch glow, rim light, or lantern prop) on/near the sentries so they don't vanish into the wall at night.
