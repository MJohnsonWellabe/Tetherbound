# Corrected-camera catalogue sheet manifest

Status: **assembly complete for 116/116 canonical corrected-camera frames.** This is a
mechanical provenance and tile-mapping record. It contains no visual verdict. The
Stormwood source is the explicitly preserved pre-pylon-material-repair round and must
not be mistaken for a later post-repair survey.

## Assembly contract

- Compositor: `tools/contact_sheet.gd` under Godot 4.7 headless image-compositing mode.
- Output root: `C:/Projects/Tetherbound/shots/catalogue/audit-camera-sheets/`.
- Three columns; reading order is left to right, then top to bottom.
- Tiles are 620 px-wide Lanczos previews. Canonical source PNGs remain untouched at
  their source-round paths.
- No captions, change descriptions, verdicts, or annotations are burned into pixels.
- `_sheet.png`, validation mosaics, manifests, logs, and other noncanonical PNGs were
  excluded. Staging was populated only from each source manifest's captured frames.

## Exact source rounds

| Biome | Canonical frames | Source round | Manifest SHA-256 | Staging hash mismatches |
|---|---:|---|---|---:|
| Cloudreach | 24 | `shots/catalogue/cloudreach/round-camera-20260909T012134Z` | `ea2c5b332045a5504be380590cefb09c99b5d28eaefd80c073221724bc52c03c` | 0 |
| Meadows | 20 | `shots/catalogue/meadows/round-camera-20260909T011407Z` | `e49392094f53918f6fadf0e2e4663c19c525ed9ef5f1720849431ca71acb945c` | 0 |
| Stormwood | 24 | `shots/catalogue/stormwood/round-camera-20260909T013019Z` | `489b1a9fb731381d36675d14b3b2dcc51d4d186c7134c12967bd1080fea22f69` | 0 |
| Water | 48 | `shots/catalogue/water/round-camera-20260909T013251Z` | `e889ff467e0fcc9eae8cbfc00f5872c0d54e810d7205f349a7a64af78fdd778c` | 0 |

The four per-biome staging counts are exactly 24, 20, 24, and 48. The combined staging
directory contains exactly 116 PNGs and has zero source-to-copy SHA mismatches.

## Generated sheets

| Sheet | Tiles | Dimensions | Bytes | SHA-256 |
|---|---:|---:|---:|---|
| `cloudreach.png` | 24 | `1916x3438` | 9,191,775 | `dad0339142d0340897e1b488803185e65d6f2f9d6ef240051d4425c2dbf4f98e` |
| `meadows.png` | 20 | `1916x3010` | 7,259,126 | `2eafa4797243908bbeb2488cdfc1dca09f18c5c831499af88c88bfd84d35222c` |
| `stormwood.png` | 24 | `1916x3438` | 8,968,610 | `88ad8e673758a7eec8917f20754c45644bc74fc361709c670e7ad5e0cd4f5474` |
| `water.png` | 48 | `1916x6862` | 18,029,947 | `5f0d02ebb25601c72120c32eaa8a76cbba0dc6a793d7085843dab7d90fda4a0b` |
| `combined-116.png` | 116 | `1916x16706` | 43,475,286 | `9c274bd1337a20ab86ad8b71b8dbc4510ce6d03fb33194407e5b827154e0dc37` |
| `combined-page-01.png` | 30 | `1916x4294` | 11,512,009 | `ea0cc26cb56a8b0b02d4ff30290ce3eed4bf69f49176f0756c428cc2c16072c6` |
| `combined-page-02.png` | 30 | `1916x4294` | 10,804,928 | `7b9a346af8109f8e16be6902dd646ed5be417f913a654988eb9176188f859752` |
| `combined-page-03.png` | 30 | `1916x4294` | 11,473,135 | `0b3b6ea825fbaadc31c0cbdb1fd2cf1ac4121130de0d6b5180a26d6d43767845` |
| `combined-page-04.png` | 26 | `1916x3866` | 9,685,900 | `30ec392aab9cd632fad8e432311bdade170bf23a0d9621a244e80d4b3ef15832` |

## Tile mapping

The authoritative explicit mapping is
`shots/catalogue/audit-camera-sheets/frame-map.csv`: **116 rows**, SHA-256
`0926f79adac6ff28e7af5a064e1eebbcfab762092c9c56d5103eac537d7d3763`.
Each row records global tile/row/column, split page and page-local tile/row/column,
biome tile, exact filename, absolute canonical source path, and source SHA-256.

Combined order is the actual lexical filename order requested by the audit:

| Global tiles | Exact source mapping | Global tile for biome tile `b` |
|---:|---|---:|
| 1–24 | Cloudreach lexical tiles 1–24 | `b` |
| 25–44 | Meadows lexical tiles 1–20 | `24 + b` |
| 45–68 | Stormwood lexical tiles 1–24 | `44 + b` |
| 69–116 | Water lexical tiles 1–48 | `68 + b` |

For any global tile `g`, global row is `floor((g - 1) / 3) + 1` and column is
`((g - 1) mod 3) + 1`. Split pages preserve the same order: page 1 is global tiles
1–30, page 2 is 31–60, page 3 is 61–90, and page 4 is 91–116. Page-local tile is
`((g - 1) mod 30) + 1`; the CSV resolves every tile directly without relying on pixel
captions.

All earlier baseline sheets remain untouched. No visual judgment was performed during
assembly.
