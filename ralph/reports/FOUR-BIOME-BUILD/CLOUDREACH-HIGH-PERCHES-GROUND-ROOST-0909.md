# Cloudreach High Perches ground roost — 2026-09-09

Status: one candidate rendered; independent verdict pending. No second tuning round.

## Defect and attribution

The held first High Perches pass added footings, collars, elevated rest arms and rigging, but its independent image-only verdict remained A No / B No. In the fixed ordinary day view, `70.26%` of the lower 470 rows falls in a broad green-like HSV band. That number only attributes the uninterrupted floor area; it is not an acceptance target. The player-height composition still presents an empty lawn between monumental shafts, and the capture manifest reports no creatures within 160 m.

This pass does not revisit exhausted cloud, ground-material, deck, lighting, creature-spawn or camera work. It targets one distinct composition defect: the landing lacks a maintained, human-scale roost use at visible height.

## Installed-asset candidate

Three low roost racks form an outer crescent between the retained needles. Each uses the already-vendored CC0 Kenney `tree-log-small.glb` as a 3.2 m crossbar, seated on two small existing Cloudreach masonry sockets. The source asset is 9,216 bytes, 148 vertices / 88 triangles, one material and no collision node; SHA-256 `5B416ADDC4CB01D9D6AD30EC282606A8FEFB018043D3253D5E42C1E353AAB3C8`.

Construction samples the production `ground_height_at()` surface beneath every rack and offsets the measured imported AABB so its bottom meets the socket tops. The complete addition is three imported meshes (264 triangles) and six small CylinderMesh sockets. It uses a 480 m visibility range.

## Traversal and proof contract

All additions remain non-colliding, and their measured top is approximately 0.311 m above the floor, below the controller's 0.35 m step height. They behave as traversable low ground dressing rather than walk-through furniture. Their conservative crossbar bounds leave the exact 4.5 m survey/teleport/landing disc around `(900, 1020, 2700)` clear and retain at least 0.5 m from every shaft after including shaft radius. The existing fly route, survey trigger, six needles/caps, terrain and prior keeper construction remain unchanged.

`tools/_probe_cloudreach_high_perches_ground_roost.gd` calls the actual production `_build_high_perches()` method on a tiny root with the real installed asset and a registered production crown seam. It checks asset/log/socket counts, zero added collision, floor grounding, below-step visual height, landing clearance and shaft clearance without booting a second full world. Visual proof will reuse the exact production catalogue High Perches day camera transform and `1280x800` viewport from `round-high-perches-20260909T113828Z`; no creature spawn or camera reframe is permitted to improve the result. One ordinary orbit may be retained only as supplemental context. Independent image review decides whether the three racks read as a maintained roost rather than scattered logs.

## Runtime evidence

The first tiny probe stopped at parse time because its fixture-local `landmark` identifier was declared twice. That failed exit-1 receipt and raw error remain in `.artifacts/cloudreach-ground-roost-0909/probe/`; it is not counted as a construction check. After the single identifier correction, the separate corrected probe exited 0 with:

`CLOUDREACH GROUND ROOST PASS racks=3 logs=3 sockets=6 collisions=0 landing_clearance=5.778 shaft_gap=0.556 visual_height=0.311 failures=[]`

The one matched production catalogue run then captured day and night at the retained coordinate, camera transform and `1280x800` viewport. It completed 2/2 frames, exit 0, zero manifest failures and peak 74.13% system committed memory. Raw error scan was clean; stderr contains only the pre-existing `cr_candy_broken_route_good_07` no-surface warning. Godot count was zero after exit.

- day: `shots/catalogue/cloudreach/round-ground-roost-20260909T1412Z/cloudreach__high_roost_sky_shrine__08__the_high_perches__day.png`, SHA-256 `8CDDF8D6BAB66D4470B19886EB5393D51E0C27C40784A5A899B37D0F01D27854`
- night: `shots/catalogue/cloudreach/round-ground-roost-20260909T1412Z/cloudreach__high_roost_sky_shrine__08__the_high_perches__night.png`, SHA-256 `C6C2F295997544DC1ACE54A0D3E47F6F8057A208024B1A76D112E81391A587C9`
- matched sheet (before left, candidate right; day then night): `shots/catalogue/cloudreach/round-ground-roost-20260909T1412Z/ground-roost-before-after.png`, SHA-256 `23B38C0F3DAEDB16FE41E71FB6F686229D868193390544FB758376CF9527BDF3`
- manifest SHA-256 `7A599602AB17E36FC732053F4EADC1B2EE04FF57C828BF5DE0162ABF8BE612E3`
- guard receipt SHA-256 `CAD2353DBA7F0B10FC94EB54B3C3062FA2B23D35496E77D51E5EE8741E709BE1`
- corrected probe stdout SHA-256 `621B7ABF92A00F52DBFCB90449EE7A8ADED003D995A08A613BCCA7ADF6CD276D`
- corrected probe receipt SHA-256 `8169E5EAE01473A8F76A0A82379D9C39213FCFB1510D646CE94B6B62122D5667`

Visible evidence limit: the canonical frames clearly expose only one thin rail; the other two are occluded by the retained shafts and grass from this unchanged camera. Independent review in `VISUAL-WAVE6-IMAGE-REVIEW-0909.md` is A No/B No: the loose strip does not improve the empty floor or repetitive monumental pillars, and night values remain poor. Root holds this candidate from shipping. No second placement or camera round is authorized for this small-prop approach; a future High Perches proposal must address the larger composition.
