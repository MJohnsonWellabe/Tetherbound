# Vitals outline 01 — withdrawn

## Candidate

Fresh frames repeatedly described FOOD and health text as weak. The candidate
restored the four existing vitals labels from the local 2 px outline override
to the shared `UITokens.OUTLINE_SIZE` of 6 px. Font sizes remained 26 px;
colors, zero-shadow treatment, idle parent alpha, bars, panels and widget
bounds were unchanged. The original candidate comment said occupied pixels did
not change. More precisely, **widget bounds did not change, but the rendered
outline pixels did**.

## Matched native evidence

- `vitals-outline-on-first` captured the 6 px candidate at Gull Rest Beach day
  and night from 2026-09-10 09:40:28–09:41:06 UTC, exit 0 with `errors: []`.
- `vitals-outline-off-first` captured the matched 2 px control from
  09:42:04–09:42:42 UTC, exit 0 with `errors: []`.
- Both runs produced two complete production catalogue frames at the same
  destination and camera. The control's mounted-HUD audit verified candidate
  6 px → control 2 px as the only style mutation, recorded the same 26 px
  fonts, tints, outline color, zero shadow, label bounds and live 0.55 parent
  alpha, then restored the candidate styles before exit.
- The probe initially compared a catalogue `identity` field that is absent in
  this plan. Root corrected the guard to use the real
  `destination_index`; the validated probe completed cleanly. It is retained at
  `.artifacts/broad-visual-0910/vitals-outline01-validated/`.
- `JUDGE-VITALS-OUTLINE01.md` finds no meaningful day or night preference. It
  answers key-art A **No**, same-game B **No**, and commercial readiness
  **No** for both treatments.

## Disposition

Withdrawn. Root reversed only the vitals production hunk and preserved the
independent HUD callout fix. The original held patch remains at
`.artifacts/broad-visual-0910/vitals-text-contrast01-held.patch`; it is evidence
of the tested candidate, not an apply recommendation. No further outline
strength tuning is planned because the clean matched pair showed no visible
gain.
