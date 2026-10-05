# F08#3 — Correct high-perch production camera (Cloudreach visual lane)

- **Commit under test:** `d7c8618e` (tb/visual-cloudreach)
- **Renderer:** Compatibility (Low preset), Xvfb + llvmpipe, opengl3, 1920x1080; committed and judged as 1280x720 JPG copies. Medium/High (Forward+) requested from the Codex GPU render service as `RENDER REQUEST cloudreach-1` (PR #525); not judged here.
- **Command:** `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --fixed-fps 60 --rendering-driver opengl3 --audio-driver Dummy --resolution 1920x1080 --script tools/capture_cloudreach_high_perch_live.gd -- --output=<dir>`
- **Tool result:** `HIGH PERCH LIVE OK: 12/12 frames, 0 failures` (run_lines.txt, frames/manifest.json). Before (re-proof at 826d273c3): 11/12, night departure never launched.
- **Judge:** fresh code-blind agent; inputs were only these frames, the criterion and bar text, the Sky Aviary and roster boards, palworld-04 and the Meadows key art. Verdict in `JUDGE.md`.

## Before → after

| Re-proof defect (826d273c3) | At d7c8618e |
|---|---|
| Night departure: second Jump never launched, no frame | Fixed. Cause: the first press was a grounded no-op (the trainer stepped onto a low rack on the jump frame); the tool now repeats a grounded first press. 12/12 frames. |
| arrival-lip: solid arch between camera and landing | Arch replaced by open gate pylons; judge still flags a rail prop in the bottom-left corner and the carrier's wings over the trainer. |
| arrival-landed: camera wedged between two needles, bench and rail at the lens | Needles re-spaced off the landing lane; no needle or bench at the lens. Judge: the frame faces away from the perches and reads as a meadow; at night two companions crowd the edges. |
| rim-out: rock mass and pillar base in the corners | A dark object is still clipped by the near plane in the bottom-left corner; no visible drop. |
| White disc platform on white cylinder legs | Was the F28 Master pad; now a turfed rock islet. Judge now reads the mesas as flat-topped cylinders and the worn arena top as an orange disc. |
| No cloud sea (grey/navy plane) | Cloud sea renders (far-plane floor). Judge: the cloud layer sits level with the lawn in rim-out; horizons still go to grey/navy voids. |

## Verdict: FAIL (Low). Camera correct NO, Bar A NO, Bar B NO.

Top blocking defects (judge): rim-out near-plane clip and no drop; arrival-landed framing and night companion crowding; crown-court does not read as high; arrival-lip corner prop and wings over the trainer; placeholder cylinder shelves, sky voids, floating world-text labels, weak night window light.

## High Perches day-departure note

At 52b269ce one run's **day** departure glide touched down before 35 m. It did not reproduce at d7c8618e (both departures reach 36.1 m, 1.47 m below crown height). The glide is marginal by construction; the tool now logs the landing collider if it recurs (302d27e8).
