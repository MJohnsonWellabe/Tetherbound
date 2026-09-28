# F13#5 independent strict re-check: MET

A fresh read-only subagent scored the evidence in this folder against ACCEPTANCE
§6.1 F13 ("Currents, inhabited docks and Veilfall distance read pass T2's visual
matrix"), ART_DIRECTION's Tidewake row, the Phase 1 function rule (STATE §1 ruling 4,
CLAUDE_START_HERE §3.5 and §4) and the relaxed-proof rule. It opened the frames
itself and checked that VERDICTS.md summarises them faithfully.

**RESULT: MET** (Phase 1 function and readability)

- **Veilfall distance read:** r2/frame_01-03. A small grey cone with white falls from
  First Shore, larger with distinct falls from Tidal Cradle, sea stacks and structures
  from Sluice Isle: visible from First Shore and gaining detail over the journey.
- **Inhabited docks:** r2/frame_04-10. Every mandatory dock has two or three people by
  its cargo (r1: six of seven empty). The residents are built from data on every peer,
  independent of flags, and add no state.
- **Currents:** r3_currents pairs. Aligned foam streaks mark each lane and shift between
  frames at the normal CameraRig, in the live (unrestored) state; the judge read the
  direction correctly from motion.

## Shortcuts to disclose on the board
- Teleport stands and mid-chapter upstream world flags (tool header).
- Local xvfb + llvmpipe (opengl3) at 1280x720; no ROG Ally or Windows capture.
- Day only, clock frozen; no night or weather coverage.
- Motion judged from still pairs 0.5 s apart, not video.
- Dock and Veilfall frames at 811c3244 plus residents; not re-shot after the comet
  change (8d7e3ddf), which also halved the live chop.
- The current verdict is WEAK 3/3 for still-frame direction: the board says "reads as
  current, direction from motion", not YES.

## Gaps recorded for the Phase 2 catalog
- Still-frame direction of the comets is ambiguous.
- Veilfall is small from the First Shore stand.
- Dock coves share one template; figures are small and static.
- At the Sluice Isle dock the grey sluice-control block hides the player from the
  approach stand (a camera/occlusion note).
- "Cliffs explain gated approaches" (ART_DIRECTION) was not tested; it is not in the
  ACCEPTANCE text.

Housekeeping the re-check raised (a stale evidence path in `water_dock_residents.json`
and the machines block's old off-note in `water_veilfall.json`) is fixed on the same
branch.
