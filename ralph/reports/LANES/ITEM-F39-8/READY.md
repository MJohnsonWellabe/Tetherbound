STATUS: land
BRANCH: tb/item-f39-8  HEAD: (branch tip; this file is in the last commit)

# ITEM F39#8 P2-108 Aquaryn mounted-water pose (LANE-TW)

- **Score:** GPU 4.97 live (board CPU 6.09 after VIS-TIDEWAKE). Both rounds below were CPU quick judges with three code-blind judges.
  - r1 (`qj/F39-8-d8f0118ffe47-11072231`): `rider_shadows_off` + `extra_sink_m` 1.4 scored 5.41 -> 6.75 mapped (+1.34, 3/3 up). Not shippable: at the deepest bob the rider art sits 0.29 m under the sea, which fails `test_rider_stays_above_sea_at_deepest_bob`.
  - r2 (`qj/F39-8-a298b52340f5-11072308`): `rider_shadows_off` + `extra_sink_m` 1.0 scored **4.97 -> 6.38 mapped (+1.41)**. All three judges were higher, and the defect calls went from PRESENT to PARTIAL/PRESENT. This is what ships.
- **Flags turned ON** (`data/config/water_mount_presentation.json` `mounts.water_aquaryn`, `_why_on_1107`):
  - `rider_shadows_off` true (new key; false keeps the old behaviour).
  - `extra_sink_m` 0.9 -> 1.0.
- **Code:** `scripts/world/water_mounted_swim.gd` turns the rider's (local rig's) cast shadows and blob off while a listed mount swims with the key set. The rider's shadows come back when the body is shallow, leaves the mount, fights, or the ally body changes. It reuses `water_mount_presentation.gd::set_shadows`, which restores each mesh exactly.
- **Tests:**
  - Added `tests/test_uiposes_water_mount.gd::test_f39_8_rider_shadow_and_sink_ship_on`.
  - `test_uiposes_water_mount.gd`: 5 tests, 0 failed. The rider-above-sea test passes at 1.0.
  - `tests/smoke_camera_pass_through.gd`: OK. It reads the same config.
- **Files touched:** `scripts/world/water_mounted_swim.gd`, `data/config/water_mount_presentation.json`, `tests/test_uiposes_water_mount.gd`, this report.
- **Left OFF:** nothing new.
- **Remaining judge asks:**
  - The mount still reads tall and static in the side frame. Judges ask for a swim stroke and bob animation, a bow wave and spray, and a lower waterline. The lower waterline is capped by the rider-above-sea rule unless the saddle height changes.
  - In the base capture, frame 05 showed the trainer alone on water with the mount gone. That looks like `camera_hide` (`creature_body.gd`, not this lane's file) hiding the whole body when the camera sits inside its long tail. The candidate frames didn't hit it, but the camera hide needs a guard: never hide a ridden mount. That belongs to the owner of `creature_body.gd`.
- **Next idea:** a bow-wave and spray particle at the mount's head along its velocity (`water_mount_wake.gd`), plus a saddle `mount_offset` lowered with the sink so the waterline can drop further.
