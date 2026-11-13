STATUS: superseded by BELOW6-STORMDRESS (same flag, sent with the banners as one arm)
ROW: F41#1 Stormheart (6.81 on the new approach stand). A game defect beside the entrance, not in the row's fixed camera set.
BRANCH: tb/below6 (code and config only, no import)
OVERLAY: ralph/reports/LANES/BELOW6-SPLITWOOD/overlay.json (`stormheart_presentation.json split_bark_finish.aged_heartwood_1112`)
FRAMES: CAPTURE.json (one ad-hoc stand facing the split, base and arm)

# ARM: the Stormheart split's exposed wood, aged (LANE-BELOW6, 12 Nov 2026)

## The defect
From beside the south split, the split's exposed inner wood fills the view as a saturated orange wood-grain slab. On the old approach stand all three judges read it as "an orange untextured placeholder" (G-below6-thundertunnel-heartwood, G-below6-stormheart-approach base: approach frames 2.80). The new approach stand no longer faces it, but a player walking round the trunk to the entrance still does.

## Cause and fix (flag OFF)
`stormheart_split_wood.gdshader` multiplies an orange trim atlas by a tint; no tint takes it off orange. `aged_heartwood_1112` adds a `weathering` parameter (0 = unchanged) and sets it to 0.75 under a pale heartwood tint (#b3a892). Shader parameter only; no geometry, collider or stand change.

## The stand
The old approach stand, reproduced as an ad-hoc spot so both sides see the split: `--spot=split@-101.56,5466.87@26.6 --views=approach` (the catalogue position and heading of "The Stormheart Tree"; the stand search seats the player about 48 m back at (-123, 5424), beside the split, as the 11 Nov frames did). `--subset=zz_no_match` keeps the catalogue rows out.

## CPU check (`_sheet_cpu.jpg`: base left, arm right, that same stand)
The slab goes from saturated orange to a muted grey-brown that sits with the lavender-grey bark. Nothing else in the frame changes.

## Second set: Marrow's dialogue frames
G-below6-marrow, all three judges on the arm side: "trunk colours: saturated orange on the left (one judge says it's near oxblood)". That trunk face is this same exposed wood, seen from the DynamoCore deck (`BELOW6-MARROW/_sheet_cpu_probes.jpg` shows it at the left of every probe). CAPTURE.json `second_capture` adds his two dialogue frames, base and arm. Not captured on CPU with this flag.

## Expected
On this one frame, more than 0.5 (it was the named defect, 3/3). It earns nothing on the F41#1 row's fixed set, which does not show the split; it lands as a game fix if the judges prefer it.

## Checks
`--only=capture_approach_overrides,stormheart_ramp_body,stormheart_split_bark`: 7 tests, 0 failed (before the merge with main; the Stormheart set is re-running after the merge).
