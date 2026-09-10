# Stormwood palette 01 — retained

## Outcome

Retain the vegetation material-policy change. Two fresh blind comparisons preferred the candidate’s biome coherence: Glass Crown preferred F03/F04 overall, and Lantern Hollow preferred F01, specifically noting that the repeated red-bush distraction was removed. Both judgments still answered key-art world **No**, same-kind-of-game **Yes**, and commercial quality **Not yet**. This is a useful systemic palette gain, not a full-bar visual result.

## Owned files

- `data/config/stormwood_vegetation.json`
- `tests/test_stormwood_vegetation_palette.gd`
- canonical generated Stormwood scatter manifest fingerprint, staged by root after final combined bake disposition

The config applies warm dark bark to `Bark_TwistedTree` and `Bark_NormalTree`, cools the crown leaf tint, swaps `storm_bush` from the crimson TwistedTree sheet to the existing desaturated normal-tree sheet, and retints fern `Leaves` into the same cool understory family. Mushroom material remains unchanged as a limited warm accent. Placement, counts, model selection, scale, LOD, collision, and harvest behavior are unchanged.

## Validation

- Production material-binding tests: **3 tests, 12 assertions, clean**, 04:21:23–04:21:26. Tests instantiate the real Stormwood tree, bush, and fern models and run `vegetation.gd::_retint`; they verify the bark subset retains its installed texture, the bush resolves to the existing desaturated leaf texture, and fern/mushroom policy remains separated.
- Canonical palette bake: 04:21:03–04:21:11, **108 regions, 33,773 kept placements**, all **108 binary region hashes unchanged**; only presentation fingerprint metadata changed.
- First native palette capture was non-clean because a concurrent tree-config edit changed the fingerprint after the bake. That failure is preserved and is not acceptance evidence.
- Combined art bake: 04:28:13–04:28:21, all **108 binary hashes unchanged**.
- Native palette 02 capture: **10/10 frames clean**, 71 seconds, 04:29:44–04:30:55.

## Visual evidence and limits

- `JUDGE-GLASS-PALETTE01.md`: preferred candidate coherence and darker trunks, with a caveat that night trunk detail can become subdued.
- `JUDGE-LANTERN-PALETTE01.md`: preferred candidate coherence and removal of distracting repeated red bushes.
- Glass baseline `broad-foliage-backlight01` and candidate both include the same foliage-backlight work, isolating the palette comparison there.
- Lantern baseline `workshop-dressing01` predates foliage backlight, so that comparison is directionally useful but does not isolate palette alone.
- Native palette 02 also contains the concurrent tree candidate and foliage-backlight work. The retained claim is therefore limited to the directly supported palette/coherence improvement; no full-bar or commercial-quality claim is made.

Night bark detail is the known follow-up risk. Do not blanket-brighten the biome; assess trunk separation in representative night gameplay if that policy moves again.

Final retained-state bake: `stormwood-retained-palette-scatter-first`,
04:54:03–04:54:12 UTC, clean. The rejected Stormheart material candidate and
unsupported Stormwood detiling setters were withdrawn before this bake.
All 108 region binaries remain byte-identical to the pre-palette hash record;
the generated manifest now fingerprints only the retained production config.
