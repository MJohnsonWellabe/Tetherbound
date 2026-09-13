# Independent evidence verdict — `final-companion-15`

**Overall: MIXED — T0 #2 PASS; T0 #13 FAIL.**

I inspected all eight 1280×800 PNGs at native resolution and reconciled them
against `manifest.json`. The package is structurally clean: 8/8 planned frames are
present and unique, every recorded byte count matches its file, `complete` is true,
and the manifest has no failures or warnings. The disclosure is appropriately
bounded: formation uses the production gameplay camera and real movement input;
rest uses the production Party/bed assignment/recall/`RestingCreature`/`play_rest`
path with a disclosed audit camera and no animation seek or pose injection.

## Strict 09/12 row verdicts

| Owner row | Verdict | Evidence |
|---|---|---|
| T0 #2 — companion walks beside the player rather than behind/blocking the camera | **PASS** | The active brown Terrapup holds the camera-right flank in settled day/night (`01`, `02`) and during both diagonal movement samples (`03`, `04`). The player, route centre, and forward country remain readable in every frame; Terrapup never occupies the camera axis or sits behind the trainer. The receipt agrees: `companion_behind_camera: false`, centre in frustum, 5.90–6.06 m camera-axis surface clearance, and only 0.11–0.26 m station error. The large grey Trailpups at the frame edges are nearby world creatures, not the active companion, and do not invalidate the formation result. |
| T0 #13 — Terrapup lays down correctly when resting | **FAIL** | The rest subject is finally visible and the production state transition is proved, but the visible endpoint is not a lay. In `05`–`08`, Terrapup keeps its head/neck erect, eyes open, chest high, and both forelegs nearly vertical with planted paws; it reads as an alert crouch or sit on the bed. The measured posed height is 3.600 m against the declared 3.85 m body height (about 94%), consistent with the upright read, and the lowest skinned point is 0.172 m below the bed anchor plane. The two promised viewing angles also resolve as near-frontal images rather than a useful side and three-quarter silhouette. Zero anchor error, the completed 1.5417 s `faint` clip, 15,616 skinned vertices, and no surface failures prove that the shipped path ran; they do not make its resulting pose correct. |

## Capture/readability gate

- **PASS for formation:** ordinary production-camera framing, day/night settled
  coverage, opposing movement samples, and visible player/companion/world context.
- **FAIL for rest acceptance:** subject and bed are now readable, so this is no
  longer a HOLD, but the pixels directly reproduce the pose defect. A fresh pass
  needs a clearly lowered/horizontal torso with relaxed limb contact, plus genuinely
  distinct side and three-quarter day/night views.

This package supports closing T0 #2 only. T0 #13 remains open.
