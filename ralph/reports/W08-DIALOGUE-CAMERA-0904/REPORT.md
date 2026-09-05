# W08-DIALOGUE-CAMERA-0904 — the conversation push-in

Branch `ralph/W08-DIALOGUE-CAMERA-0904`. Final commit **`a05a0c9d`**.
Finisher session: the feature commit `c5a381bd` was already on the branch; this
session verified it, found it inert in the running game, fixed that and three
further defects, and gathered the evidence.

---

## What the player gets

Walk up to a villager, press the button, and the camera stops orbiting behind
you and pushes in over the dialogue fade to a two-shot: the person talking near
the middle of frame at about 3.5m with the lens narrowed from 70° to 40°, your
own near shoulder on the opposite third. The stick and the mouse are ignored
while you read, and the pose you had is blended back exactly when the box
closes. Indoors, where Mira's cottage and Bram's inn have no 3.5m of floor
behind you, the shot gives way to a closer over-the-shoulder; backed into a
corner it swings round to whichever side of you the room is actually on. It
never stands inside the person talking, never inside your own head, and never
takes a position it could not have travelled to.

Nobody's scale changed. D73 §6 / CL-G10, owner #8: villagers reading small in
dialogue is a camera-depth problem, and villager scale has already been cut and
re-cut.

**The claim, as a number.** Measured through the game's own camera, by pressing
the real interaction button in the built village:

| stand | speaker's share of frame height, box shut → mid-conversation | arm | fov | fallback |
|---|---|---|---|---|
| Halda, village square, open air | **33.8% → 58.6%** | 3.50m | 40.0 | no |
| Bram, inn, across the bar | 115.8% (off-centre, half out of frame) → **59.0%** | 3.50m | 40.0 | no |
| Bram, inn, backed into the corner | 0.0% (behind the camera) → **77.5%** | 2.10m | 46.0 | yes |

---

## Files changed

| file | what |
|---|---|
| `scripts/player/conversation_camera.gd` | new. Resolves who is speaking; solves the framing as pure static geometry so it can be asserted rather than looked at. |
| `scripts/player/camera_rig.gd` | the blend, the arm, the occlusion probe, the swing search and the restore. |
| `scripts/ui/dialogue_panel.gd` | **the hook, one call each way**: `start()` → `_push_the_camera_in()`, `_on_runner_finished()` → `_pull_the_camera_out()`. No layout touched. |
| `data/config/camera.json` | new. Every tunable: distance, blend time, fov, bias, swing, elevation, anchors, the four clearance guards, the fallback block and its swing search. |
| `tests/test_conversation_camera.gd` | new. 23 tests, 100 assertions. |
| `tools/_capture_dialogue_camera.gd` | new. Drives the real walk and the real button press and photographs what the game's own camera sees. |
| `docs/CURRENT_STATE.md` | the P2 "villagers read too small in dialogue" row, rewritten to fixed. |

`scripts/ui/dialogue_panel.gd` is the file the brief asked to be named: it is
the one place that knows a conversation is on screen, so it is the one place
that says so. `dialogue_runner.gd::close()` emits `finished` whether the
conversation ended by advancing off the last line or by somebody calling
`close()`, so there is a single path out.

---

## The four defects this session found

The branch arrived with the push-in written, wired and unit-tested — **and doing
nothing at all in the running game.** Every one of these was found by driving
the real village, not by reading the code, and each is now covered by a test
that was watched fail against the old behaviour before it was kept.

**1. The push-in framed the wrong person, or nobody.**
`interaction_arbiter.gd::activate()` calls the provider's `interaction_activate`
FIRST and emits its `activated` signal afterwards — and `interaction_activate`
on a villager opens the dialogue panel synchronously, which is what asks for the
push-in. The remembered provider was therefore always one conversation stale,
and null for the first of the session. The capture reported it plainly: *"the
conversation opened but the camera never pushed in."* The speaker is now read
from the arbiter's live `winning_provider()`, with the remembered one kept as
the fallback for a conversation opened by a story beat rather than a press.

**2. The blend advanced one frame and froze.**
`story/sequence_director.gd` ends its per-frame gate with
`_camera_rig.set_process(not panel)`: the rig has never had a suspend of its
own, so the director switches its whole idle tick off for the length of every
conversation, deliberately, to stop the stick look and the follow. The blend
lived on `_process`. Measured in the real village, sampled every twelve frames:
`in_conv yes  blend 0.056  arm 5.18  fov 69.7` — unchanged from t+0 to t+48. It
now runs on the physics tick, which is also where `dialogue_panel.gd` reads its
own input and where the arbiter recomputes, so the shot ticks on the same clock
as the box it exists for. Nothing in the unit suite could have seen this: a
detached rig stepped by hand is never suspended by a director that is not there.

**3. The cramped fallback put the lens inside the trainer's head.**
Found by the blind judge on the first captured sheet: *"the entire left third of
the frame is the player's own hair mesh at point-blank range... the player's
collar and shoulder are sliced flat by the near plane."* Measured from the same
capture, the lens sat 0.36m off the trainer's centre line. Two causes: the room
measured behind a shot was not the room the camera got (`SpringArm3D` holds its
`margin`, 0.6m on this rig, back from whatever it hits, so an arm set to the raw
hit distance is placed that much shorter, forward of everything the framing
solved for); and `min_speaker_clearance` kept the lens out of the person talking
while nothing at all guarded the person holding the camera — who is the one
standing between the pivot and the lens. New `min_trainer_clearance`, solved
exactly rather than estimated along the axis.

**4. Clearing the trainer, on its own, blocked the shot.**
With no room behind the player the only way to clear them was to put the pivot
on their own chest, and the next capture came back with the trainer's hair
filling the middle of frame and Bram hidden entirely behind it. Standing behind
somebody is not a shot when there is a wall a metre back. The cramped shot now
searches `fallback.swing_search_deg` for the room instead of assuming where it
is — each candidate solved and then swept against real geometry, nearest-first
and both ways — and additionally requires the lens to be somewhere the camera
could have travelled to from behind the player, so a wide swing cannot find
clear air on the far side of a bar and stand there.

---

## Tests

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_conversation_camera.gd
→ 23 tests, 100 assertions, 0 failed
```

Every test drives the rig's own `enter_conversation`, blend and restore. The one
thing that genuinely needs a world — how much space is behind the camera — is
injected through `set_occlusion_probe_for_tests`, because `tests/run_tests.gd`
runs entirely inside `_init` with `Engine.get_main_loop()` null throughout, so
there is no physics space to build a room in.

**Seen red, for the right reason, before being kept** (the brief names the first
two; the rest are this session's):

| test | broken how | what went red |
|---|---|---|
| `..._closing_a_conversation_restores_the_rig_it_borrowed` | exit blend written as `yaw = shot_yaw` | `expected 0.900000 +/- 0.001000, got 0.314159 (the exploration yaw is player-authored; it must come back exactly)` |
| `..._a_cramped_room_falls_back_to_a_closer_over_the_shoulder` | `is_blocked` forced false | `expected true, got false (1.8m of room must not be filled with a 3.5m two-shot)` + 3 more, and `..._a_wall_pressed_against_the_lens...` with it |
| `..._the_push_in_frames_the_person_being_activated_not_the_one_before` | speaker read from the stale signal again | `expected <Villager#...>, got <Villager#...>` — the previous speaker |
| `..._the_push_in_survives_the_idle_tick_being_switched_off` | blend moved back to `_process` | red, and it took 7 others with it — the suite drives the real path, so restoring the shipped design breaks all of it |
| `..._a_cramped_room_still_keeps_the_lens_out_of_the_trainers_head` / `..._a_room_ceiling_never_pushes_the_lens_through_the_trainer` | bias cap removed | `a 1.2m room left the lens 0.31m from the trainer, wanted 1.00m` |
| `..._a_corner_swings_the_camera_to_the_side_the_room_is_on` | swing search reduced to `[0.0]` | `expected true, got false (the shot must swing off the blocked axis, not stand in the wall)` |
| `..._the_camera_never_takes_a_position_it_could_not_reach` | reachability forced true | `expected true, got false (the shot must stay on the side of the bar the player is actually on)` |

The last one was **vacuous on its first writing** — the fixture never actually
offered the across-the-bar option, so it passed with the guard removed. It was
rewritten until it failed for the right reason and only then kept. Recorded
because a test that cannot fail is worse than no test.

## Smokes

All six the brief names, **green on the first attempt**, run on the final code
(`2d8de7e6`), each exactly as CI runs it:

```
godot --headless --path . --script tests/smoke_dialogue_clears_the_world_hud.gd   rc=0
godot --headless --path . --script tests/smoke_post_modal_control.gd              rc=0
godot --headless --path . --script tests/smoke_menu.gd                            rc=0
godot --headless --path . --script tests/smoke_opening.gd                         rc=0
godot --headless --path . --script tests/smoke_gate_b_continuous.gd               rc=0   (CORE, +403.70s)
godot --headless --path . --script tests/smoke_tournament_bracket.gd              rc=0
```

`verify-gate-b-core` runs `smoke_gate_b_continuous.gd` with no flag, which is
the core prefix; that is what was run here.

`SCRIPT ERROR`: **0 across all six.** `^ERROR:`: six occurrences of one line,
`Parameter "material" is null` from `creature_body.gd::_build_model` under the
headless dummy renderer — present on `main`, unrelated to this change, and the
known-benign set did not grow.

## Runtime validation

`tools/_capture_dialogue_camera.gd` walks the player to each stand in the built
playground, presses `interaction_arbiter.gd::activate()` for real, and shoots
through `CameraRig/Camera3D` — **not** a free camera posed by hand, because what
is being judged here IS the camera and a second one would only prove the tool
can do arithmetic. It fails loudly if the press does not land, if the box does
not open, or if the rig does not push in.

```
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver opengl3 \
  --resolution 1280x800 --script tools/_capture_dialogue_camera.gd
→ 6 frames, 0 failures
```

It also grew a `--dry-run` mode (identical walk, press and numbers; no renderer,
no PNGs) so the wiring could be checked in one headless world build instead of a
software-GL capture. That is what made defects 1 and 2 findable at all, and it
is the reason the blend is now sampled across the window rather than reported
once at the end — a shot that engages and then never moves reads identically to
a finished one in a single end-of-window line, and that is exactly how the
push-in shipped frozen at five per cent.

## Frames and the blind verdict

`ralph/reports/W08-DIALOGUE-CAMERA-0904/_sheet.png` — three frames at 1280×800,
the handheld resolution. Per-frame PNGs deliberately not committed.

Judged by a fresh code-blind sub-agent given only the sheet, `docs/reference/`
and `.claude/skills/visual-judge/SKILL.md`, told nothing about what changed. Two
rounds; the first round's FAIL is defect 3 above, and it was fixed rather than
argued with. Round two, verbatim on the two acceptance questions:

> **Acceptance A — PASS.** All three speakers are large enough (head 13–15% of
> frame height, ≈12–14mm on a 7-inch panel), well placed vertically above the
> dialogue panel, and none is blocked by geometry. The camera delivers the
> speaker in every frame.

> **Acceptance B — FAIL, on frame 1 only.** Frames 2 and 3 are clean of
> intersections; I looked specifically at the arms/counter, the bedroll/counter,
> the beam/wall corner and the near plane in both, and found none.

**Not one of frame 1's three intersections is the camera's**, and none is in
this lane's ownership. They are listed under "outside this lane" below, with
what to do about each. The judge's own summary of the speaker question:
*"None of the three speakers is too small, too far, or blocked."*

The reachability guard (defect 4's second half) landed after this capture. A
dry run on the same three stands afterwards returned identical shot parameters —
arm 3.50/3.50/2.10m, fov 40/40/46, the same fallback decisions, the speaker
filling 58.6/59.0/77.5% — so the swings those stands were already choosing were
reachable, the judged frames still describe the shipped behaviour, and no third
capture round was spent to re-photograph an unchanged picture.

---

## Outside this lane — exact patches, not fixed here

Per FINISHER.md rule 4. Each was found by the blind judge on real frames.

1. **The dialogue portrait is the same image for every speaker, and it is the
   player's.** Verified pixel-identical by the judge across Halda's panel and
   Bram's: *"Halda is a brown-bobbed young woman on screen; her portrait is a
   spiky-haired boy."* The panel names the right person and shows the wrong
   face, in every conversation in the game. **This is the single largest defect
   on the sheet and it is squarely in the area this lane was forbidden to touch**
   (`dialogue_panel.gd` layout). Owner: whoever holds the dialogue panel. The
   fix is to key the portrait off the speaking character rather than off a
   constant.
2. **`village_npcs.gd` / village fence geometry.** In the Halda frame, a post of
   one fence run passes bodily through the rails of another at a different angle
   and into the boulder behind it (frame coords ≈ x 900–980, y 255–310); a
   second post floats clear of the terrain with visible ground beneath it
   (≈ x 865, y 265–315) and a rail ends in mid-air (≈ x 985, y 275).
3. **Trainer clothing collision.** A cream cloth flap on Halda hangs past her
   right leg and its tip is drawn through the toe of her boot (≈ x 575–610,
   y 748–790). It is inside the conversation the shot exists to frame, so it is
   the most visible of the three.
4. **Controller glyph in the dialogue prompt.** The continue prompt renders
   `assets/ui/input_prompts/keyboard_e.png` — a keyboard `E` — on a
   controller-first handheld target.
5. **Inn interior is undressed.** Both judge rounds independently called it a
   greybox: *"There is not one bottle, shelf, stool, tankard, barrel, sign or
   lamp in either frame"*, in a room whose own dialogue says "beds are through
   the back, and I keep stock too." Not a camera defect — but the push-in is
   what now puts a player's eye on that wall for the length of a conversation,
   so it is newly worth someone's time.

## Known limitations

- **In a genuinely cramped corner the shot stops being a two-shot.** With a wall
  a metre behind the player, the swing that has room puts the trainer out of
  frame entirely and delivers a clean single on the speaker. That is the
  deliberate call: the alternative, measured and photographed, is the trainer's
  head filling the middle of the frame with the speaker hidden behind it. A
  legible single beats a blocked two-shot. Recorded in `camera.json`'s own
  comment beside the tunable that decides it.
- **Mounted is reasoned, not photographed.** `riding_controller.gd` hands the
  rig the mount as its target and the push-in frames from `_target` with a
  configured anchor height, so it works by construction, and `set_target` drops
  the push-in cleanly if a mount or a fight takes the camera mid-blend (covered
  by `test_a_fight_taking_the_camera_beats_a_conversation_still_blending`). No
  frame was captured of a conversation opened from the saddle.
- **Blend time and lens are one setting for every conversation.** A shop or a
  gate that opens the panel with nobody to frame correctly gets no push-in at
  all (`resolve_speaker` accepts only characters), but a long story beat gets
  the same 0.45s push as a one-line greeting.
- The `--dry-run` capture and the headless smokes ran on software GL in a
  container. Frame times from any of it are not a performance measurement.

---

Branch `ralph/W08-DIALOGUE-CAMERA-0904`, final commit `a05a0c9d`.
No pull request opened; the landing lane does that.
