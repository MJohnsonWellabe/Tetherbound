

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

## Independent r2 visual failure and changed approach

The independent code-blind review of the retained r2 frames failed F25#2:
Fireball had no convincing extended trail, and lightning contact with the
target was not established. Several stones and one boulder were identifiable,
but their washed-out primitive surfaces and generic impacts missed the full
commercial bar. Its F25#5 finding was only a bounded size-upgrade PASS for the
four shown families at ranks 1/3/5; other families, ranks 2/4 and earned mastery
remain open. All rejected r1/r2 evidence remains retained; the feature stays off.

The next source approach replaces frame-count trail history with spatial
distance samples per body, explicitly separates volley paths, and prioritizes
primary trails when secondary layers exceed their shared budget. Fireball uses
an animated structured material, tapered volumetric plume and overlapping
three-dimensional burst lobes. Stones use irregular face-normal chunks and
weathered mineral shading. Lightning anchors to the frozen ground contact and
retains its complete branched stroke through early impact. This is geometry and
material work based on the restored Palworld combat reference, not a shutter
or global-grade adjustment. These source changes require new native captures
and independent judging; they do not establish a visual PASS.

## Native identity rework captures (r3)

Executed exact pushed source: `a90aa0c0563d29903842529c256d1f3581465437`.
Godot 4.7 official `5b4e0cb0f`, native OpenGL Compatibility, NVIDIA GTX 1060
3GB / driver 560.94; 1920×1080; isolated APPDATA `D:/tetherbound/vfx-proof-home`.
Command: `Godot_v4.7-stable_win64_console.exe --path D:/tetherbound/redesign-vfx --rendering-method gl_compatibility --resolution 1920x1080 --script tests/smoke_move_effects_library.gd -- --batch=identities --out=D:/tetherbound/vfx-identities-native-r3`.

Native exit 0, 12 cases, 0 failures, 0 ERROR/SCRIPT ERROR lines. The retained
`native-identities-r3/` contains all 36 neutral PNGs, unmodified raw results and
native log, plus SHA-256 inventory. Independently checked PNG headers are all
1920×1080; each flight shutter preceded arrival, each contact/impact shutter
followed actual arrival, every arrival frame equals its separately created
local schedule frame, and all particle leases release to zero. No shader repair
was needed during this run. Original procedural shader/geometry provenance is
recorded in `assets/vfx/procedural_provenance.csv`.

Scope remains four actual production move profiles at ranks 1/3/5 in the
synthetic arena, slowed to 0.7-second travel, with process-local library opt-in.
It is not an earned player path, multiplayer damage/contact witness, all-24
visual result, Medium four-creature fight performance result or Ally result.
The tracked flag remains off. The r1/r2 rejected evidence is preserved. A fresh
independent code-blind judge must assess these PNGs against the full visual bar;
native execution and source improvements alone do not close F25#2 or #5.

## Second blind quality rejection and replacement approach

The fresh independent r3 review failed F25#2 and the whole F25#5 criterion.
Its report is preserved in `native-identities-r3/strict-review.txt`: convincing
small stones and a single boulder still had rectangular trails and tiny rigid
impacts; the corrugated trail, solid crumpled orb, sphere burst, rigid spikes and
gray halo did not read as flame/explosion. Lightning descended from above, but
the arena contained no visible target and therefore could not prove striking
one. The sampled four families visibly scaled at ranks 1/3/5, which does not
prove all-24/ranks-1-through-5 or earned mastery. The plain arena limits coverage
and is not a judgment of unseen world content. All failed evidence is preserved.

After this second quality rejection the next implementation replaces the solid
deformed flame shell and closed corrugated tube entirely. Camera-facing soft
procedural flame layers and continuous centerline ribbons use global UVs,
animated opacity tongues and fading silhouette edges. Explosion layers and
embers use the same soft field, with no rigid spikes or enclosing gray sphere.
Stone contact uses warm dust and varied physical chip trajectories that fall
and settle at frozen ground height; the hard radial splash geometry is removed
from its profile. These change rendering only, never host HP or action timing.

The next identity harness stages the actual production Mudsnout CreatureBody
and imported model, failing if the model is absent. It aims at that body's real
height and keeps the frozen ground endpoint. The body is posed with physical
movement disabled; there is no encounter, AI or HP mutation. This can establish
visible target coverage but cannot replace the earned player path. A separate
`mastery` capture batch covers all 24 authored archetypes at every rank 1–5;
unused families resolve directly from the library and the batch makes no earned
mastery claim. These source drafts have not been rendered or independently
judged. The feature remains flag-off and every F25 criterion remains open.
