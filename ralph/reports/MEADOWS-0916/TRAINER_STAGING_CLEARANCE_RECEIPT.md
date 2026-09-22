# Trainer staging clearance focused run receipt

Date: 2026-09-16. Source checkout: `D:/tetherbound/source`; changes uncommitted at execution. This receipt transcribes tool output; no standalone raw log was saved.

Command:

```powershell
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/smoke_combat_trainer_staging_clearance.gd --quit-after 300
```

Final run: Godot 4.7 stable `5b4e0cb0f`, exit 0, six checks, no script errors. Captured output:

```text
PASS: open side preserves intended grounded placement
PASS: blocked transit selects clear opposite side
PASS: both blocked retains actual starting location
PASS: unsupported claimed floor retains actual starting location
PASS: supported gentle slope uses real grounded candidate
PASS: small arena does not stage beyond its radius
```

The fixture invokes production `_stand_the_trainer_aside` using a real CharacterBody3D capsule, floor, walls, and sloped support. It verifies actual player positions. It does not load the full Meadows or replay Bryn's encounter.

Initial attempt failed parsing `combat_manager.gd:751`: `Cannot infer the type of "candidate" variable because the value doesn't have a set type.` The dependent smoke consequently failed to instantiate the manager. That process was stopped by exact smoke command-line match. Explicit `Vector3` typing and conversion of the loop scalar fixed the parse error. A subsequent four-check run passed; the final six-check run above added slope and small-arena coverage. The initial failed attempt is not counted as validation.

Scoped `git diff --check -- scripts/combat/combat_manager.gd tests/smoke_combat_trainer_staging_clearance.gd` returned no diagnostics. No production campaign acceptance is claimed by this receipt.
