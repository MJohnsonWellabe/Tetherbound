# Terrain3D candidate component runtime proof

PASS for the three bounded component checks only, October 13 at 11:54-11:55 PM US Central. Root admitted and launched this run; the independent reviewer did not launch or modify the native stage. This does not close Guardian, transient interpolation, full-world rendering, art, performance, release or platform criteria.

Exact source base: `5bc0ac3ea71ad524d956751423f650432ac9de1b`, with an explicitly disclosed candidate DLL and isolated component leaf overlay. This is not a stock-source run. Candidate DLL SHA256 `5cf87b3a5dea907b788f187e7ede6347f3aaba25396610269120a3cf2a903306`; leaf SHA256 `baebfdc13f344916624ba736846730db80e54187542f729e942ba1348ba2f442`. Build, original capped failure and source/license provenance remain in `../terrain-profile-build/`.

The admitted job SHA256 is `c66166980f568eab797c9ed6e846b279a294d1782f48c2fc3a46427c49cb6113`; runner SHA256 `c280f149aa8e03f42843247becde55b7b2639c9999334d4edb7e5dbd274762d3`. Admission changes from the prepared packet are preserved in the exact raw evidence. The first administrative admission command referenced a nonexistent field and stopped before writing or launching; it is not a native failure or a second test run.

| Check | Actual result | Wall time / cap |
| --- | --- | --- |
| Component parse | exit 0, no diagnostics | 4.133 / 45 seconds |
| Unchanged resident terrain support smoke | 28 checks, zero failures, exit 0 | 14.901 / 120 seconds |
| Compatibility clipmap render | Four near/step/far/return observations; seven LOD positions each; eight PNGs; exit 0 | 20.615 / 120 seconds |

The independent review verified exact argv and source/engine/job/runner bindings, 876 canonical input snapshots totaling 44,314,860 bytes, all stdout/stderr hashes and image hashes, and resource floors. All stderr files were empty. No script errors, warnings, parse errors or deprecated RenderingServer calls appeared in stdout. The unchanged physics smoke exercises actual resident terrain, body contacts, camera movement and an in-memory hole control.

A separate pure Python pass recomputed native LOD snap positions from the bound config and source formula, validated visible-minus-hidden image pixels, and matched the supervisor's numeric result. All four visible frames were inspected: resident terrain is continuous and nonblank, with no obvious holes showing background through the ground or missing clipmap bands in these views. The return image is byte-identical to the initial view. Angular grey terrain contours are fixture output, not an art score. Settled views do not measure interpolation during movement or prove full gameplay.

Minimum observed resources: physical RAM 4,261,883,904 bytes; commit headroom 3,689,086,976; C free 15,288,582,144; D free 22,728,654,848. All exceed admitted floors. The supervisor ended `EXITED_ZERO_AWAITING_COMPONENT_VISUAL_REVIEW`; the subsequent independent verdict is `PASS_COMPONENT_SCOPE_ONLY` in `independent-review.json` (SHA256 `ea24f2d767cbe02eb53d0b13517cac12a0686c2154a1c624dcb5ea2436cba8c4`). Original receipts were not rewritten.

At this component checkpoint the original guardian warning gate remained separately required. It subsequently passed with unchanged assertions and census checks; see [candidate guardian proof](../terrain-guardian-5bc/proof.md). Prior failed evidence is retained. No runtime warning was allowlisted, no stderr was suppressed and no test was weakened.

`raw-evidence.json` embeds 16 exact UTF-8 files (1,329,584 raw bytes), each verified to round-trip with its SHA256. Eight PNGs (203,698 bytes) are preserved byte-exact in `frames/` and hashed in the bundle.
