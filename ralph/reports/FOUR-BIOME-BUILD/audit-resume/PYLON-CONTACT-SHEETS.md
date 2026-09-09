# Final post-pylon catalogue sheet manifest

Status: **assembly complete for 116/116 canonical frames.** This is a mechanical
provenance and tile-mapping record. It contains no visual verdict.

## Assembly contract

- Compositor: `tools/contact_sheet.gd` under Godot 4.7 headless image-compositing
  mode.
- Output root: `C:/Projects/Tetherbound/shots/catalogue/audit-pylon-sheets/`.
- Three columns; reading order is left to right, then top to bottom.
- Tiles are 620 px-wide Lanczos previews. Canonical source PNGs remain untouched.
- No captions, change descriptions, verdicts, or annotations are burned into pixels.
- `_sheet.png`, manifests, logs, validation mosaics, and other noncanonical PNGs were
  excluded. Staging was populated only from each source manifest's frame records.

## Exact source rounds

| Biome | Frames | Day/night | Source round | Manifest SHA-256 | Planned-ID match | Copy mismatches |
|---|---:|---:|---|---|---|---:|
| Cloudreach | 24 | 12/12 | `shots/catalogue/cloudreach/round-pylon-20260909T015726Z` | `117de398d54f6fd3b358012b7d02c3913261d0a85e540bdfc9f59a1c73cfa33f` | yes | 0 |
| Meadows | 20 | 10/10 | `shots/catalogue/meadows/round-camera-20260909T011407Z` | `e49392094f53918f6fadf0e2e4663c19c525ed9ef5f1720849431ca71acb945c` | yes | 0 |
| Stormwood | 24 | 12/12 | `shots/catalogue/stormwood/round-pylon-20260909T020124Z` | `be54b57e9c31225e59362647a8cf00b72d2c1fe08158a51e52e09001479ede4b` | yes | 0 |
| Water | 48 | 24/24 | `shots/catalogue/water/round-camera-20260909T013251Z` | `e889ff467e0fcc9eae8cbfc00f5872c0d54e810d7205f349a7a64af78fdd778c` | yes | 0 |

Every source manifest reports complete, its planned and captured counts agree, and its
captured frame-ID set exactly matches its planned frame-ID set. All 116 frame names and
SHA-256 hashes are unique. The four biome staging directories contain exactly 24, 20,
24, and 48 PNGs; combined staging contains 116. A second post-copy SHA pass found zero
source, biome-staging, combined-staging, or CSV mismatches.

Cloudreach and Stormwood are the post-material `round-pylon` sources. Meadows and Water
are the established corrected-production-camera sources requested for the final set.
The earlier baseline and `audit-camera-sheets` outputs remain untouched.

## Generated sheets

| Sheet | Tiles | Dimensions | Bytes | SHA-256 |
|---|---:|---:|---:|---|
| `cloudreach.png` | 24 | `1916x3438` | 9,208,510 | `37856b567f2cf5702d843c3a5be44288c61fa54bcd110488b94f99114ebe19a0` |
| `meadows.png` | 20 | `1916x3010` | 7,259,126 | `2eafa4797243908bbeb2488cdfc1dca09f18c5c831499af88c88bfd84d35222c` |
| `stormwood.png` | 24 | `1916x3438` | 9,084,252 | `a71e2cc91cdca086389c2049ebedbe83ea6a716c339ecd5d29771f9f52d3bbdc` |
| `water.png` | 48 | `1916x6862` | 18,029,947 | `5f0d02ebb25601c72120c32eaa8a76cbba0dc6a793d7085843dab7d90fda4a0b` |
| `combined-116.png` | 116 | `1916x16706` | 43,606,265 | `36282823ddb5dec27a0dfb98089fc4356a84fecd9ce7b75ec148328e69887399` |
| `combined-page-01.png` | 30 | `1916x4294` | 11,528,841 | `e6de25632d1d1332a2ca5115302b3c4c6b5a0b5b0a956de96406e312767cd4f7` |
| `combined-page-02.png` | 30 | `1916x4294` | 10,921,188 | `b30183e5f6f1cdd7d5ae6a0dd74b378d4b454186ff63ca6473b4256e7ad5c1a2` |
| `combined-page-03.png` | 30 | `1916x4294` | 11,470,383 | `a155a9ead99a50ffd74c73b38fb78458e32062a0dff6fea4e6f2c7209994f166` |
| `combined-page-04.png` | 26 | `1916x3866` | 9,685,900 | `30ec392aab9cd632fad8e432311bdade170bf23a0d9621a244e80d4b3ef15832` |

## Tile mapping

The authoritative mapping is
`shots/catalogue/audit-pylon-sheets/frame-map.csv`: **116 rows**, SHA-256
`bb5b80f2f966654c75ac87dfc478bc42735592930a488d20b088b7334bcf07c6`.
Each row records global tile/row/column, split page and page-local tile/row/column,
biome tile, exact filename, absolute canonical source path, and source SHA-256.

Combined order is exact lexical filename order:

| Global tiles | Exact source mapping | Global tile for biome tile `b` |
|---:|---|---:|
| 1–24 | Cloudreach lexical tiles 1–24 | `b` |
| 25–44 | Meadows lexical tiles 1–20 | `24 + b` |
| 45–68 | Stormwood lexical tiles 1–24 | `44 + b` |
| 69–116 | Water lexical tiles 1–48 | `68 + b` |

For global tile `g`, global row is `floor((g - 1) / 3) + 1` and column is
`((g - 1) mod 3) + 1`. Split pages preserve that order: page 1 is tiles 1–30,
page 2 is 31–60, page 3 is 61–90, and page 4 is 91–116. Page-local tile is
`((g - 1) mod 30) + 1`. The CSV resolves every tile without relying on pixel text.

No visual judgment was performed during assembly.
