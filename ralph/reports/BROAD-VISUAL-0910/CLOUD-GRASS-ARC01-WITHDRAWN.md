# Cloudreach blade arc 01 — withdrawn

The successful shared Meadows/Stormwood/Water blade curvature was tested in
Cloudreach's separate stacked-surface shader. Only its green and dry Grass
materials enabled the angle; flower and bush materials retained zero. Counts,
placement, exclusions, tint, normals, existing lean and wind were unchanged.

Review caught an important coordinate difference before visual testing:
Cloudreach's mesh Y already contains `t * blade_height`. Passing that Y as the
full arc length would multiply `t` twice. The corrected vertex helper uses
`UV2.y` as full length and retains the complete original vertex when disabled.

The strengthened native GPU probe extracts the actual production hash, arc and
vertex helper. Sixteen tiles test zero preservation, root, midpoint and both
signs; wrapper outputs are checked against a full-length expectation, so the
original midpoint mistake would fail. `cloud-grass-arc-gpu-second` passed cleanly
09:31:01–09:31:09. The first invocation, 09:30:09–09:30:17, failed because a CRLF
patch preflight failed and the tool did not exist; that orchestration error is
preserved. The patch was then applied with whitespace-tolerant matching and its
two-file production delta reviewed before the valid invocation.

Candidate native capture ran 09:31:25–09:33:31 and the process-local angle-zero
control ran 09:34:06–09:36:10. Both completed cleanly with four frames: Windscar
Flight Aerie and Old Wind Observatory, day/night, using the production camera
and nearby visible grass. The control retained actual materials and all other
uniforms. Frames are under `shots/catalogue/cloudreach/broad-grass-arc01-{on,off}`.

Fresh judges preferred the original F03/F04 pair at both locations. See
`JUDGE-CLOUD-GRASS-ARC-WINDSCAR01.md` and
`JUDGE-CLOUD-GRASS-ARC-OBSERVATORY01.md`. Both answer A No, B Yes and commercial
readiness No. Nearby creatures differ between the independent Windscar runs,
so that verdict's creature preference is not evidence about this grass change;
its grass criticism and the second location still do not support retention.

The two production files were restored to HEAD. The prior committed live-crossing
cover fix remains intact. Full held patch, corrected shader and validated tools
are preserved under `.artifacts/broad-visual-0910/cloud-grass-arc01/`, with the
actual withdrawn production delta at `cloud-grass-arc01-withdrawn-production.patch`.
No further Cloudreach shape/count/radius tuning is planned in this run. Its
visible-ground-cover quality remains below the requested bar; the shared arc
retained in the other three biomes is unaffected.
