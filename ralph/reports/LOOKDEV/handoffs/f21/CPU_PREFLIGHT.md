# F21 native hit overlay CPU evidence

Requested runtime source: `61a6b5e4c92457e836e60f342a31af9187998329`
on `tb/f21`, in a clean detached checkout. The external overlay lives on
`tb/lookdev`; it does not modify the pinned game's source. Its hash, dependency
hashes, actual parent hashes, commands and log hashes are in
[cpu-preflight.json](cpu-preflight.json).

Both the pinned parent and the older lookdev parent loaded the overlay and
deliberately refused headless rendering: exit 2, zero errors. This proves
parsing and the refusal path only. It does not execute the native preset,
world, timing, image validation or final publication paths. No F21 criterion
is accepted by this receipt.

The overlay requires Medium/Forward+, a fresh output directory, ordinary
continuously drawn time and the updated parent's full sequence. It selects
the production Medium preset before mounting the world, seeds the global RNG,
records the supplied runtime source identity and checks the four seven-image
sequences at 1920x1080. The external launcher must verify clean HEAD against
the supplied source SHA; the engine checks SHA syntax, not Git identity.
The global RNG seed alone does not establish deterministic world generation
or matching damage: production nodes randomize private generators. The receipt
discloses this. Cross-run contact/outcome matching remains unproved; capture
completeness does not certify a matched A/B pair. The overlay verifies each
role against its confirmed impact slot/direction/critical state, so a normal
contact labeled `crit` fails. Duplicate roles and image paths also fail.

The parent samples 300 live drawn process-frame intervals **before** the
scripted contact sequences. This is a fight timing interval, not GPU-only
timing or a measurement of the hit sequences. PNG I/O occurs outside that
interval. Baseline mode disables the impact layer in memory as disclosed by
the parent fixture; inherited campaign/crit shortcuts remain disclosed there.
Independent image review and full feature acceptance remain separate.

Native invocation shape, with the caller providing fresh isolated device
preferences, verifying the pinned checkout and retaining the engine log:

```text
Godot_v4.7-stable_win64_console.exe
  --path D:/tetherbound/f21-native-61a6b5e4
  --rendering-method forward_plus --resolution 1920x1080
  --script D:/tetherbound/redesign-lookdev/tools/capture_f21_native_hit.gd
  -- --preset=Medium
  --source-commit=61a6b5e4c92457e836e60f342a31af9187998329
  --out=<fresh-directory> --sequence
```

The comparison baseline uses another fresh profile/output and adds `--baseline`.
The actual sequence offsets are 0,2,4,6,10,16,24 after confirmed contact;
the parent's comment about a pre-contact frame does not describe its code.
Do not use `--fast`, `--fixed-fps` or headless rendering for native evidence.
The F21 live camera matrix uses the pinned production smoke instead:
`--script tests/smoke_combat_camera.gd -- --matrix-live
--matrix-dir=<fresh-directory> --matrix-preset=Medium --source-commit=<pin>`.
It requires the same native renderer/1080p setup and retains the ordinary
camera/control checks after the nine pairs. These commands have not run
natively while Valheim occupies the GPU.

Evidence belongs under this authorized LOOKDEV handoff directory. A pointer
under `ralph/reports/COMBAT/f21/native/` lets the combat lane find it without
duplicating image sets.
