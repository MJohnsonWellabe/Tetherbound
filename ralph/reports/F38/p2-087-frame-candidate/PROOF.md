# P2-087 camera candidate — pending native review

Source: `tb/codex-visual-meadows` based on `1f6d7e210888244d544ea4290770cb844ca21a66`. Crosswalk status remains open/needs_capture; the current survey has no exact High/Medium matches. Earlier direct-start dialogue fixtures do not prove an earned-path speaker defect.

Candidate: `camera_rig.gd` can optionally test whether the aftermath speaker anchor projects inside an 82% safe frame, then search reachable shoulder swings that preserve configured sightlines. `camera.json` exposes `speaker_frame_candidate_enabled`, false by default. No body scale, character art, dialogue content, combat logic or capture fixture changed.

Capture the same named Warden aftermath in the native checkout, at 1920×1080, with High and Medium separately. Use `tools/capture_f38_fight.gd`, trainer `warden_aldis`, seed 2042, `--resolve=won --after-frames=24 --frames=8 --interval=0.5`; set unique `--out=res://shots/f38/p2-087/<before-or-candidate>-<preset>` for each run and include `--preset=<high-or-medium>`. For candidate runs, temporarily set `camera.json` `profiles.aftermath.speaker_frame_candidate_enabled` to true and add `--f38-candidate`; restore false after capture. Keep the same scene, player/ally, renderer, timing and resolution in every pair. `--resolve=won` shortcuts the battle result but exercises the production victory-dialogue and aftermath-camera path; disclose this in the manifest/review.

Review the `-aNN` aftermath frames for speaker visibility while retaining the player, ally and arena. Not READY: candidate remains OFF pending root's serialized native captures and code-blind verdict. P2-087 stays open until all listed sightings are assessed.
