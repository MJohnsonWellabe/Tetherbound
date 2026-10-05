# F26 item 1: packaged desktop preflight

Runtime source: `1b85fb4d985b7d622e022867055770b2f0de6b18` (includes integration 648643576).
External launcher source: `1b85fb4d985b7d622e022867055770b2f0de6b18`. This is a fresh clean-source Windows
release export with text script representation preserving the production bake
fingerprint inputs. The actual PCK accepted the fresh Stormwood bake and all
108 region files, with zero engine errors, before the native run.

Release export and actual exported headless refusal: PASS. Package integrity,
ZIP CRC and all embedded payload hashes: PASS. Four actual packaged native
routes: DESKTOP_PREFLIGHT_COMPLETE, exit 0 for every child. Receipt/raw-file hashes
and min/average/1% low independently recomputed by the author: PASS.

Hardware: desktop NVIDIA GeForce GTX 1060 3GB. Medium / Forward+ / Windows /
1920x1080, VSync disabled, max FPS 0, time scale 1, 60 Hz physics, live rendering,
no fixed FPS. Ordinary production camera far values are recorded below.
Startup/shader/world building and screenshots occur outside route timing.
These are desktop measurements; Ally acceptance remains BLOCKED_OWNER.
Meadows, Tidewake and Stormwood average below 30 FPS on this PC; only Cloudreach
meets the timing target. F26#5 remains BLOCKED_OWNER, with the requested package
and desktop native preflight subgate complete.

| Biome | Far (m) | Frames | Min FPS | Avg FPS | 1% low FPS | P95 ms | >100 ms |
|---|---:|---:|---:|---:|---:|---:|---:|
| meadows | 2000 | 212 | 6.59 | 11.03 | 6.66 | 144.24 | 19 |
| water | 6500 | 120 | 5.29 | 7.34 | 5.33 | 169.79 | 113 |
| cloudreach | 3500 | 12998 | 12.65 | 74.24 | 43.43 | 16.28 | 0 |
| stormwood | 9000 | 2595 | 6.14 | 17.11 | 9.69 | 79.09 | 13 |

Owner ZIP: `D:\tetherbound\.artifacts\f26-ally-1b85fb4d9-20261004T235918Z\Tetherbound-F26-Ally-1b85fb4d9.zip`

SHA-256: `499f29739f3797abcb21efc3fe3c4dd78586ed0b7b6856fbbd15795ee7172eda`

[One-page owner checklist](ALLY_CHECKLIST.md). Run uncapped at 15 W on the exact
declared Ally model; >=30 FPS required, 40 preferred. Return the full result folder
and visible-fault/power notes. Compatibility remains the ordinary default.

[Machine receipt](ally-desktop-preflight.json); raw proof bundle
`far-floor-packaged-native.zip` SHA-256 `8e4f4da224ba390902f69ef2234a923f039634099b4fa03bccc6537cacae4483`. All native raw logs, route JSON, exit status,
start/end PNGs, package manifest, launcher and clean-source CPU export logs are
retained. The first Meadows attempt is preserved INCOMPLETE in
`D:\tetherbound\.artifacts\f26-ally-a799297b2-20261004T225752Z\desktop-preflight-20261004T231048Z.receipt.json`; its null process status was fixed rather than converted into success.
A second attempt remains INCOMPLETE after Water shader-cache directory errors
under a long custom Output path. Its exit code was zero, but its native ERRORs
were correctly refused. The final run uses a fresh short Output and has zero
native ERRORs. The unchanged normal owner default is substantially shorter than
the failed custom path. Failed cache evidence is included in the raw bundle.

Scoped implementation and export-preflight independent review: PASS by
`/root/f26_lookbar_review`. Final independent native evidence verdict: **PASS for
bounded desktop delivery**. The reviewer independently verified all 28 raw-file
hashes, recomputed FPS and hitch counts, checked source/profile/resolution/
uncapping/far floors and inspected all eight PNGs for populated worlds. This
does not establish an Ally or full visual-bar pass.
Shared source touched: `tools/capture_lookdev_route.gd`,
`tools/owner/f26_ally.ps1`, `export_presets.cfg`,
`tools/check_exported_stormwood_scatter.gd`. No renderer default, STATE or evolution flag changed.
Full visual-bar acceptance and all later handoff items remain open.
