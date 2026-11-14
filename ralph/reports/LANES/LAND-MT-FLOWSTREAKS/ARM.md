# LAND-MT-FLOWSTREAKS round 2 (lesson-gated): drop the crescents on the swim-lesson lanes only

**Round 1 (G-land-mt-flowstreaks): DO NOT SHIP.** F13#5 +0.52 (3/3), but F39#16 / F39#17 current states -0.42 (0/3), because the re-enabled streaks drew guide lanes everywhere.

**Round 2 change (coordinator / LANE-JUDGE ask: gate it to the lesson).**
- New flag-off `current_flow.lesson_cue` in `water_veilfall.json`.
- The flow ribbon's vertex alpha is 0 on four lesson lanes, the ones the T2 views look across: First Shore to Reedhaven and Reedhaven to Brine Steps, sheltered and direct.
- The shader scales only those lanes' chop caps by `lesson_chop_scale` (0 when ON).
- Streaks stay at their shipped 0 everywhere.
- The current-state stands S1 and S2 use other lanes (`tidal_cradle_to_salt_crown`, `salt_crown_to_sluice_isle`), so their frames cannot change.

**Overlay.** `{"water_veilfall.json": {"current_flow": {"lesson_cue": {"enabled": true}}}}`

**CPU.** `_sheet_flowstreaks_off_vs_on_cpu.jpg` (left base, right chop caps off): the T2 crescents are gone. This sheet is the global chop-off probe; on the T2 views it is the same picture as the gated version, because all four views look across lesson lanes. Pin test `tests/test_current_lesson_cue.gd`: 1 test, 10 assertions, 0 failed (OFF marks no lane; ON marks the lesson lanes only and sets the scale to 0).

**By-eye.** T2 views: no crescents. Current-state S1 / S2: identical to base.

**Not in this arm.** A wake anchored to the swimmer (3/3 ask), and the wide bright band in swim-brine-day.

---

Earlier notes follow.

# LAND-MT-FLOWSTREAKS round 2: chop caps off only

**Round 1 verdict (G-land-mt-flowstreaks, LANE-JUDGE): DO NOT SHIP.**
- F13#5 swim views 5.52 -> 6.04 (+0.52, 3/3); the crescents read PARTIAL.
- F39#16 / F39#17 current states 6.08 -> 5.66 (-0.42, 0/3): the re-enabled foam groups drew long parallel guide lanes, which is F39#16's own defect.

**Round 2 change.** Overlay only: `current_flow.state_shader.live.chop_cap_opacity` 0.45 to 0. The streaks stay at their shipped 0, so no lanes are added. The F13#5 gain should come from the crescents going, and those are the chop caps.

**CPU.** `_sheet_flowstreaks_off_vs_on_cpu.jpg` (left base, right round 2; the four T2 views): every crescent is gone and nothing replaces it. This is the earlier probe run with this exact value.

**By-eye.** T2 views: no crescents. Current-state frames: no new streaks or lanes, only the chop caps gone.

**Risk.** The current-state frames lose the chop caps too. They are the no-loss check. If they lose, the next step is gating the change to the swim lesson only (a per-region value), as LANE-JUDGE suggested.

---

Round 1 notes follow.

# LAND-MT-FLOWSTREAKS: F13#5 swim current cue without the crescents

**Row.** F13#5 swimmer-relative current cue (T2), 5.38 on main (G-rescore-1113-f13-5, tb/places 2c119be7c), the worst row in this lane's scope.

**Defect (3/3).** "The scattered white crescent arcs read as decals or a debug overlay, not authored water flow." Ask: "one aligned flow field of soft, elongated, animated foam streaks running downstream past the swimmer".

**Cause, and how I know.** The crescents are the current-flow shader's chop caps (`tidewake_look.json` `current_flow.state_shader.live.chop_cap_opacity` 0.45). CPU probe on all four T2 views (`T2-current.json`): with only that value at 0, every crescent disappears.

**Change (overlay only, no code).**
- `chop_cap_opacity` 0.45 to 0: the crescents go.
- The shader's existing "foam groups" (soft, tapered, eroded streaks aligned with the flow and drifting downstream; `water_current_flow.gdshader` `foam_group`) come back at low strength: `streak_density` 0.35, `dash_fill` 0.3, live `opacity` 0.45, and cells 2.2 m by 7 m with breakup 0.8.
- Two stronger tunings drew long straight bright lanes at this grazing camera (the old "guide lanes" defect), so they were dropped.

**CPU before / after.** `_sheet_flowstreaks_off_vs_on_cpu.jpg`: left base, right arm; swim-away day, swim-across day, swim-away night, swim-brine day. The crescents are gone in all four; the flow groups are faint and short. 0 script errors.

**Honest read.** In stills this is mostly "the crescents are gone". The current's direction then reads mainly from the water's own wave motion, which is the owner's 10 Nov direction ("The in world cue should just be which way the waves move"). The risk is a judge saying there is no current cue at all; the faint groups are there to soften that.

**By-eye line for the GPU lane.** All four T2 views: no white crescent arcs on the water. If crescents remain, the overlay did not apply: hold.

**No-loss frames.** F39#16 and F39#17 current-state frames (`phase2_capture_current_states.gd`): this changes the live current look everywhere, not only at the lesson.
