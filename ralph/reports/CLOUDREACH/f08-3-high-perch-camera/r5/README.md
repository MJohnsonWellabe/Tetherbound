# F08#3 r5 — the High Perches through the live production camera

- **Tool:** `tools/capture_cloudreach_high_perch_live.gd` (run: xvfb, `--rendering-driver opengl3 --resolution 1920x1080 --fixed-fps 60`). 12/12 frames, 0 failures (`manifest.json`, `complete: true`).
- **Verdict:** `verdict.md`, CAMERA READ: PASS from a code-blind judge (`judge-prompt.md` is its prompt verbatim). Independent strict re-check: MET under the Phase 1 rule.
- **Bars A/B → Phase 2 catalog** (aerie dome/towers/banners, rock, cloud floor; the c3 judge failed both bars).

What it shows: one continuous sequence per time of day through the scene's own `CameraRig` (never frozen, never replaced; Fly's 7.5 m arm while flying, 5.2 m on foot): a Jump in the air launches the glide, held move-forward flies it onto the crown, the trainer walks to the south-east rim and looks over the drop, walks back across the court, jumps twice to launch north and glides away with the camera turned back.

Disclosed shortcuts:
- Fixture start: `reset_for_new_game`, the frame matrix's BOOT_FLAGS (Act I-II, including `fly_traversal_unlocked`), a four-creature party with no flier.
- Every flight uses Maela's loaner; owned-carrier Fly remains open debt.
- The trainer is teleported into the air 80 m south of the crown, 14 m above it, once per time of day.
- Camera yaw is written each physics frame (instant, not the stick's 190°/s turn); pitch is written to -32° for the rim-out frames only, then back to -12° (rest).
- Clock pinned (10:00 / 23:00); HUD hidden; render loop off between captures.
- The tool writes PNG; frames were converted to JPG (quality 0.9) and the manifest paths rewritten.
- Stills from one continuous run, not video.
- Non-blocking defects the judge recorded: landed frame boxed between two needle trunks with a wild ram near the trainer; at 20 m the gate wall hides the landing ring; the court view's only height cue is a far cloud horizon.
