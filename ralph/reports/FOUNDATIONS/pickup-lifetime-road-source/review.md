# Allocated pickup lifetime repair and road source diagnosis

Integration source: `12a2ede365be2bf0a65b30c9bfb5ab1221b3d670`.
Pinned main: `30fcc38fc591d5df3a7cfb122b9da58445467021`.

The coordinator's incomplete, timed-out historical regression batch reported
132 native errors from deliberately detached pickup fixtures. The existing
`test_band_pickups.gd` builds item cache nodes without mounting them, calls setup,
dresses their rarity geometry, and restores a real saved progression store.
`item_cache_pickup.gd` called absolute Game lookups in setup and `_item_colour`
without checking membership in the scene tree. `pickup_glow.gd::_field_for`
called `get_tree()` before its null-tree guard; that API reports the native error
before returning null.

The repair adds membership checks before those three API sites. Detached setup
retains its null Game and existing colour fallback. Detached glow attach/detach
retains its no-field result, including invalid/freed owner nodes. Mounted paths
perform the same Game lookups and shared-field current_scene/walk-up host lookup.
Ledger ownership, progression identities, claim behavior, visuals, rarity dressing,
spin, presentation-anchor lifecycle, and all test fixtures remain unchanged.
The actual integration proposal preserves the coordinator's existing presentation
anchor implementation, which predates this allocation but is absent locally.

Source comparison and read-only `git apply --check` passed. No engine, parser,
import, rendering, bake, CI, agent, manifest, or region writes occurred here.
Existing pickup regression cases and actual mounted behavior still require the
coordinator's runtime validation. The timed-out batch is not passing evidence.

The road dependency audit independently reproduces the existing baker's exact
hash algorithm from pinned Git bytes. All six inputs are identical to pinned
main; five are identical to the last manifest commit. The sole changed input
is `terrain_playground.json` (see the per-file blob and SHA256 audit). Current
integration and main produce fingerprint `2236840266`; the last manifest commit
produces `601121851`, exactly the installed manifest. The mismatch is inherited
main staleness. The baker consumes the ordered texture names from this file,
while its declared freshness contract hashes its complete text. Consequently
unrelated Meadows changes and formatting also stale this fingerprint.

Preserve the current manifest/test contract. The coordinator owns a real full
108-region bake at its final source cut and the isolated surface regression.
The existing baker explicitly invalidates the manifest for partial region sets.
Hand-editing the fingerprint does not establish a fresh bake.
