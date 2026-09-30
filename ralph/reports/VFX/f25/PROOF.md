

## Native identity captures (Compatibility)

Executed source: `d8e0c240c` (Godot 4.7 official `5b4e0cb0f`). Native display,
OpenGL Compatibility, NVIDIA GTX 1060 3GB / driver 560.94; 1920×1080.
Command: `Godot_v4.7-stable_win64_console.exe --path D:/tetherbound/redesign-vfx --rendering-method gl_compatibility --resolution 1920x1080 --script tests/smoke_move_effects_library.gd -- --batch=identities --out=D:/tetherbound/vfx-identities-native-r2`.
Isolated process APPDATA: `D:/tetherbound/vfx-proof-home`.

`native-identities-r2/` retains 36 neutral-named PNGs, the private move/rank
mapping and actual phase timestamps in `results.json`, and both native logs.
Final result: exit 0, 12 cases, 0 failures, 0 native ERROR/SCRIPT ERROR lines.
PNG headers all report 1920×1080. Every arrival process frame equals its
separately created local schedule frame; every particle lease releases to zero.

The rejected first run had exit 1/native errors 0: three contact shutters ran
before actual arrival because PNG I/O advanced wall time without advancing
presentation by the same amount. `rejected-initial.json` and
`native-initial.txt` preserve that result. The repair changed shutters to
presentation-domain timers and actual arrival signals. Guard checks still
reject flight after contact and contact/impact before arrival; nothing was
skipped or weakened. All raw wall timestamps, including capture stalls, remain.

Scope: actual authored production effect nodes/data for Pebble Toss, Rock Throw,
Fireball and Thunder Break at ranks 1/3/5, in a synthetic lit arena. Process-local
library opt-in; tracked configuration remains flag-off. Travel is slowed to
0.7 seconds for identification frames. These are not an earned acquire/equip
path, player-camera fight, host/guest timing witness, four-creature Medium
performance result or Ally result. Native captures are not a visual PASS:
F25#2/#5 require an independent code-blind judge. The public host-impact drawing
reconciliation API is present but not invoked by this synthetic batch; the
hosted witness must prove that path separately. No F25 criterion is closed here.
