# D54 — Content configs are cut per band, and merged by an authored `order`

**2026-08-17. `BAND-SPLIT`.**

## The problem this solves, which is not a data problem

The owner wants several agents authoring the Meadows corridor at once, one per
band. That could not be done, for a reason with nothing to do with agents: every
piece of Meadows content lived in one top-level array in one file —
`spawns.json`'s `spawns`, `props.json`'s `clusters`, `harvest.json`'s `nodes`,
`trainers.json`'s `trainers`. Five band authors would all edit all four files
and collide on every one of them, continuously.

File exclusion is the mechanism that actually keeps this project's lanes off
each other, and it could not help: the unit of exclusion is a file and the unit
of work is a band. So make them the same unit.

## The layout

```
data/config/spawns.json                              ← globals only
data/config/bands/band1_lower_meadows/spawns.json    ← Band 1's spawns
data/config/bands/band2_stone_and_root/spawns.json
...
```

**Directory per band, not per config.** `data/config/bands/<band>/props.json`
rather than `data/config/props/<band>.json`. The whole point is that a band's
ownership is expressible as one path: a lane brief says "you own
`data/config/bands/band3_the_river_lock/`" and that is the entire exclusion. The
per-config shape would have made it four paths per lane, each a sibling of four
other bands' files, which is the same collision surface in a new place. It also
means a band author sees their whole content set in one `ls`.

**Globals stay in the head file, unsharded.** `spawns.json` keeps
`respawn_seconds` and `roles`; `trainers.json` keeps `flow` and `prompts`. These
are not positional and there is exactly one right value for each, so five copies
would be five things to drift. Only the positional array is cut.

**No `shared` or `unbanded` bucket.** Band assignment clamps to the trail table:
content below Band 1's start (the village sits at z −46, the trail starts at
z −16) belongs to Band 1, content past Band 5's end (the Warden at z 7569.4)
belongs to Band 5. Every entry lands in exactly one band and nothing is left
over. A `shared` file would be a sixth thing with no owner, and the entries that
would have gone in it are not shared — the village is unambiguously Band 1's,
and the Warden is unambiguously Band 5's.

## The merge is by `order`, and `order` is authored

Every entry carries an `order` integer. The merge sorts by it; band order and
file order are only tie-breakers, so a mistake still produces the same array on
every boot rather than an engine-dependent one.

**The merged array must be identical to the pre-split file** — same entries,
same order, same values — because array position is identity here. The obvious
alternative, concatenating in band order, does not produce it: the existing
arrays are not band-sorted. `spawns[4]` is Band 4 and `spawns[5]` is Band 2;
`trainers` interleaves Bands 3, 4 and 5. Concatenating by band would silently
reorder both.

`tests/test_band_content.gd` pins this against frozen copies of the pre-split
files in `tests/fixtures/band_split_baseline/`. Its assertions are scoped to the
first `baseline.size()` entries, so content authored later appends past them and
the test stays green — while the entries that existed at the split, and the
indices they occupy, are pinned forever.

## `encounter_director.gd` now seeds from `order`, not from the array index

This is the part that is a behaviour change and needs saying plainly.

`_spawn_creatures()` seeded each cluster with `hash("wild_spawn_%d" % index)` —
the array index. That one number decides the cluster's scatter positions, its
level roll, its IVs, its trait pair and its shiny draw. It now reads the entry's
`order` instead, falling back to the index if absent.

For every entry that existed at the split, `order` equals the old index, so the
meadow is unchanged and the test above proves it.

The reason to change it at all is that the index stopped being a safe identity
the moment five agents could author five bands at once. With the index, a Band 1
author appending one spawn shifts every entry after it — and silently moves,
relevels and rerolls Band 3's creatures, with no edit to Band 3 anywhere in the
diff, no error, and nothing failing. That is precisely the class of bug the
split exists to prevent, so leaving it in place would have made the split
cosmetic for the one config where order actually matters.

New entries take an unused `order` in their band's reserved range (Band N uses
`N000`–`N999`), which no other band can collide with. Existing numbers are never
renumbered.

`props.json`, `harvest.json` and `trainers.json` do not use the index as
identity — they place by coordinates and by id — but they get the same `order`
field anyway. One rule for four files is worth more than three files saving a
key, and the merged order still decides scene-tree order, which decides Godot's
silent auto-renaming of same-named siblings.

## The band list is a literal, not a directory scan

`band_content.gd`'s `BANDS` is five ids in a `const`. A `DirAccess` listing of
`bands/` reads as more flexible and is worse in both directions: it silently
picks up a stray or half-finished directory as canon, and it silently loads
nothing if `res://` listing behaves differently in an export than in the editor.
A test asserts the list still matches `terrain_playground.json`'s
`trail.bands[]`, because a band added to the trail and not here would load as a
region with no content and no error anywhere.

## Vegetation is deliberately not split

`data/config/vegetation.json` is scatter *rules*, not placements — the
placements are generated. There is nothing per-band in it to own. Splitting it
would mean splitting a rule set, which is the drift problem, not the collision
problem. If per-band scatter density is ever wanted, the right shape is a
per-band override block inside the rules, not five rule files. `VEG-CORRIDOR`
(the scatter still being bounded to a 512 m square at the origin) is a separate
and unrelated item.
