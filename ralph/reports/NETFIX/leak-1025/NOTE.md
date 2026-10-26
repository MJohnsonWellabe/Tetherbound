# NETFIX leak-1025: hp-fixture child leaks at exit

`tests/test_director_join_snapshot.gd :: test_native_trainer_hp_fixture_survives_projectile_snapshot` failed now and then in CI `verify-suite`. It failed on PR #745 (24a31ba06), where a re-run passed, and on PR #749 (322ff9582). The child completed every time. It then printed `WARNING: 2 ObjectDB instances were leaked at exit` and `ERROR: 1 resources still in use at exit`, and the unchanged leak assertion failed.

## Cause

The leak is a one-shot sound still playing when the child quits.

- `AudioManager.play_file_at` plays the move-effect launch/impact cues on pooled `AudioStreamPlayer3D`s. The pool sits under `root` by design, so it outlives the fixture.
- The fight ends a few milliseconds before `quit()`. A 0.16 s `stone_throw_launch.wav` is often still playing then; an instrumented run caught it at 0.099 s.
- SceneTree finalize frees the pool. In Godot 4.7, freeing a playing player only flags its playback node (`stop_playback_stream` sets `FADE_OUT_TO_DELETION`).
- Only the audio thread's next `_mix_step` erases that node. The dummy driver mixes every ~93 ms here.
- `AudioServer::finish()` joins the audio thread without draining the list. I checked this against the 4.7-stable source of `audio_server.cpp` and `audio_driver_dummy.cpp`.
- On a loaded runner (CI runs two suite lanes at once), no mix runs between teardown and `finish()`. The playback and its stream then leak.

`--verbose` names the leaked objects: `AudioStreamPlaybackWAV` and `AudioStreamWAV`, plus `Resource still in use: res://assets/vfx/audio/stone_throw_launch.wav`.

This explains both facts:
- **Why only sometimes:** it needs a sound still playing at quit and an audio thread that misses one mix.
- **Why the PR doesn't matter:** nothing in either PR touched this path.

## Fix

The fix is in fixture code only: `_native_drain_audio()`, called at the end of `_native_cleanup()`. Every native child runner calls that right before `quit`.

- It stops every playing `AudioStreamPlayer`, `AudioStreamPlayer2D` and `AudioStreamPlayer3D`.
- Then it waits for two completed mixes, watching `AudioServer.get_time_since_last_mix()` reset. The wait is capped at 1 s.
- If nothing is playing, it returns at once. With a sound playing it took about 120 ms.

The leak assertion is unchanged. No game code changed.

## Proof

**Before the fix**
- Natural failure rate: 0 in 50 local runs and 0 in 40 on a CI runner.
  - Local: 20 direct `--verbose`, 10 single-core contended, 10 full-file suite runs, plus 10 earlier ones.
  - CI: render.yml headless probe run 40225117660, 3 CPU burners.
  - The CI suite has failed twice that we know of, so the natural rate is low. That is why the deterministic repro below matters.
- **Deterministic repro**, 3 of 3 runs: play the same WAV and quit while it is still playing, under movie mode:
  `xvfb-run -a godot --path . --rendering-driver opengl3 --rendering-method gl_compatibility --write-movie <scratch>/m.png --fixed-fps 30 --script <play_then_quit.gd>`
  Movie mode mixes audio only on frames, so no mix runs after teardown. Every run printed the exact CI pair, "2 ObjectDB instances leaked" and "1 resources still in use". `--verbose` named `AudioStreamPlaybackWAV`, `AudioStreamWAV` and `stone_throw_launch.wav`.
- Same repro with stop plus two mixing frames before quit: no leak.

**After the fix**
- `_native_drain_audio` with a sound playing (threaded dummy driver): it waited 119.7–120.0 ms for two mixes and left nothing playing.
- Hp-fixture child, 20 runs (`godot --headless --verbose --path . --script <runner from the test>`): 20 of 20 exited 0 and completed, with 0 leak or still-in-use lines.
- Whole file, 3 runs (`godot --headless --path . --script tests/run_tests.gd -- --only=test_director_join_snapshot.gd`): 3 of 3 passed, 6 tests ok and 0 failed each time, including `test_native_guest_killing_strike…` and `test_native_realm_rpc…`, which use the same `_native_cleanup`.
- No other file changed. `_native_cleanup` is used only by this test file.

## Harness lesson

This was added to TECHNICAL §8.1. A pooled sound playing at quit can trip exit-leak checks. To reproduce it every time, use `--write-movie` under xvfb. Drain audio before `quit`; never loosen the assertion.

The temporary probe (`tools/ci/probe_hp_fixture_*.gd`, commits aeca94bf0 and d669d2994) was removed in the fix commit.
