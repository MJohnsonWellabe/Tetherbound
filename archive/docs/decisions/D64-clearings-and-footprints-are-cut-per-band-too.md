# D64 — `clearings` and `footprints` are cut per band too, and dialogue gets one container per band

**2026-08-18. `BAND-SPLIT-2`.**

## The problem this solves

`BAND-SPLIT` (D54) cut `spawns`, `props`, `harvest` and `trainers` into
`data/config/bands/<band>/`, so five agents could each own one band's file set
with no shared file between them. It answered its own closing question --
"will this actually let five agents author five bands?" -- honestly: *"for the
four configs I split: yes. For 'combine into a finished world': not yet."* A
band author who can add a creature, a prop, a harvest node and a trainer but
cannot add a clearing or a footprint can only populate terrain that already
exists — a structure with no footprint has grass growing through its floor.

`data/config/vegetation.json`'s `clearings` (9 entries) and `footprints` (7
entries) were exactly the shape `BAND-SPLIT` had already fixed for the other
four files: positional arrays, monolithic, and (this item's own finding) all
but one clearing sitting in Band 1. This is not hypothetical — the Band 2
content lane (`MQ2B`) has a ranger camp shipping right now with nowhere of its
own to clear ground for it.

## The layout — same shape as D54, one file instead of two

```
data/config/vegetation.json                                    ← scatter rules only
data/config/bands/band1_lower_meadows/vegetation.json          ← Band 1's clearings + footprints
data/config/bands/band2_stone_and_root/vegetation.json         ← Band 2's (one clearing today)
...
```

Both split arrays live in **one file per band**, not two. `band_content.gd`'s
`load_config(head_path, array_key)` already takes the array key as a parameter
independent of the file name, so `scripts/world/scatter_rules.gd::config()`
calls it twice against the same head path — once for `"clearings"`, once for
`"footprints"` — and merges the two results into one dictionary. A band author
touches exactly one file for both.

**`order` is authored, same convention.** Every entry that existed before the
split kept `order` equal to the array index it held — `clearings[8]` (the Old
Quarry floor) is `order: 8` in `band2_stone_and_root/vegetation.json` — so the
merge reproduces the pre-split file exactly. `tests/test_band_vegetation.gd`
pins this against `tests/fixtures/band_split_baseline/vegetation.json`, the
same pattern `test_band_content.gd` uses, verified failable twice (one entry
deleted, two entries' `order` swapped) before shipping.

**Vegetation's scatter *rules* — `layers`, `corridor_bands`, `retint`, `seed`
— are untouched**, and deliberately not band-split; D54 already covered why
(a rule set splitting into five drifting copies is the opposite of the
point). This item only moves the two positional placement arrays that D54's
own "vegetation is deliberately not split" note was never actually about.

## Dialogue gets one container per band too

`data/dialogue/` was already multi-file and already merged the same way — an
explicit const list of paths, unioned by `scripts/story/dialogue_runner.gd::
table()` — but split by chapter beat (opening/village/trainers/relay/
stronghold/meadows_freed), not by band. Every new trainer's conversation had
to land in the one shared `trainers.json`, and Band 2 had no file at all.

Added `data/dialogue/bands/<band>.json`, one per band, each starting as
`{"conversations": {}}`, and appended all five to
`EXTRA_DIALOGUE_PATHS`. Unlike the positional splits above, this merge is a
Dictionary keyed by conversation id — lookup is always by id, never by
position — so there is no `order` and no reordering risk; the failure mode
`tests/test_band_dialogue.gd` actually guards is a band file silently not
being wired in, or silently shadowing an id that already resolved.

## `terrain_playground.json` — measured, not cut

The lane's own fix order flagged this file as "the real gate" and its guess
about which arrays might be band-local as exactly that, a guess. Measured
instead of assumed (see `ralph/NOTES.md` for the full per-array breakdown):
`flats`, `building_aprons.footprints`, `rises.peaks`, `drains.stations`,
`crossings` and `trail.loops` (which already carries an authored `band`
integer) are genuinely band-local per entry, with no code indexing any of
them by position. But `spokes.routes` has one entry (`storm_road`) that
physically crosses the Band 4/5 seam, `trail.shortcuts` are cross-band by
design (a shortcut connects two distant points, so it cannot be owned by one
band), and `paths.trailheads` pairs with `trail.loops`/`spokes.routes` by
coordinate rather than by an explicit key, which is a synchronization
problem the array-level split does not solve by itself. **Not cut in this
pass** — a wrong cut here is worse than no cut, and this file's own
complications (two genuinely cross-band cases, one implicit pairing) need a
scoped item of their own rather than a rushed mechanical copy at the end of
this one. `ralph/NOTES.md` carries the full finding for whoever picks it up.

## What this does not change

- No content authored — not one clearing, footprint or conversation line.
  That is `MQ2B`/`MQ3`'s work and this item is the container it uses.
- `vegetation.json`'s `layers` and `corridor_bands` keys, and `data/config/
  bands/**`'s existing spawns/props/harvest/trainers content, are untouched —
  both were other lanes' declared territory (`HARVEST-ALL`, `MQ2B`) at the
  time this shipped.
