# Stage C6 contact-sheet manifest

**Status: PARTIAL — 20/116 required day/night destination frames assembled.**
Cloudreach, Stormwood, and Tidewake remain pending coordinator-validated rounds.

Mechanical assembly record for the full Settings-catalogue visual audit. This
document records provenance and tile identity only. It contains no visual verdict,
finding, or score.

## Assembly contract

- Compositor: `tools/contact_sheet.gd`
- Runtime: `C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe`
- Runtime version: `4.7.stable.official.5b4e0cb0f`
- Invocation mode: `--headless` image compositing only; no rendering-driver argument
- Reading order: left to right, then top to bottom; three columns
- Source-frame preservation: contact-sheet tiles are Lanczos previews at 620 px wide.
  The canonical 1280x800 PNGs remain at the absolute paths below and are the files
  to inspect for full-resolution judgments.
- Caption limitation: the compositor draws separator rules but no text into the
  pixels. The tables below are the authoritative row/column-to-frame mapping.
- Meadows source exclusion: only
  `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z` is valid.
  Every other older Meadows round is excluded from this audit.

## Meadows

Source round:
`C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z`

Generated sheet (ignored evidence output):
`C:/Projects/Tetherbound/shots/catalogue/audit-resume-sheets/meadows.png`

Verification:

- Manifest SHA-256: `772859cf46fc435723e3367bb89e0c8ea52b98cd67c5d45904fc5804dc4e7660`
- Manifest flags/counts: `complete=true`; planned `20`; captured `20`; failures `0`
- Disk count: exactly `20` PNG frames
- Identity: manifest planned-frame order equals lexically sorted PNG basename order
- Integrity: every manifest byte count equals the corresponding disk file size
- Source dimensions: all `20` frames are `1280x800`
- Sheet dimensions: `1916x3010`; `7,101,802` bytes
- Sheet SHA-256: `627a6062bdfd8ffa3e921f2472e4000a4598b09a5d611e083a0b4e5dd987239e`

| Tile | Row | Column | SHA-256 | Canonical full-resolution frame |
|---:|---:|---:|---|---|
| 1 | 1 | 1 | `1e0917ab399f74a2a93f106f0db3b49d7a9c865d8b1b6ae141c6d8e72c001b9a` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band1_lower_meadows__01__grandpas_village__day.png` |
| 2 | 1 | 2 | `4024ccf2c45c88721e647762632e8b0f0d024e032abf8176bac49bd4e3dc79d3` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band1_lower_meadows__01__grandpas_village__night.png` |
| 3 | 1 | 3 | `ff4013a6378561be1587578f8666b6f91f92e1acd510ac97cd6fcb6b135bfddd` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band1_lower_meadows__02__the_south_bridge__day.png` |
| 4 | 2 | 1 | `4b6b3f85757897a5cb941b56867f4520ef32448208c5151ed21ab1b75357585a` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band1_lower_meadows__02__the_south_bridge__night.png` |
| 5 | 2 | 2 | `fcfe19fe4dec1569c10bf1e67b90d423f68e1101aec2fd11b38974fcc006e130` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band2_stone_and_root__03__the_old_quarry__day.png` |
| 6 | 2 | 3 | `094d675d31fe5280186826debe65204358e04bf9f922274b4368981bfc3537c6` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band2_stone_and_root__03__the_old_quarry__night.png` |
| 7 | 3 | 1 | `87defa22962b7b6867f4a3fc857a2bd19a3eb9615a200b39c7d8749081b15efb` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band2_stone_and_root__04__the_burrow_warrens__day.png` |
| 8 | 3 | 2 | `65190875283024abd81a6225aa4707dad5164266cc565ca6915acd41118c0826` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band2_stone_and_root__04__the_burrow_warrens__night.png` |
| 9 | 3 | 3 | `6baf2e3ec5cf74c7b22ff09abe3b642a7195529ed9ab455b161950b1f256ff7a` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band3_the_river_lock__05__the_tether_relay__day.png` |
| 10 | 4 | 1 | `559db39e899d12ad61608aa3f6b50bf546cdb8a48f30f56d4173e435f251afbb` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band3_the_river_lock__05__the_tether_relay__night.png` |
| 11 | 4 | 2 | `274f3cca160b714008736a5d72e4bb6a884e2651edc39a8b873dc644afb4af7e` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band3_the_river_lock__06__old_mill_crossing__day.png` |
| 12 | 4 | 3 | `bf6bcfcdf25bd75396a375597e7eec576e81a8dbec910fc5989f2b933f21c8a5` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band3_the_river_lock__06__old_mill_crossing__night.png` |
| 13 | 5 | 1 | `077143b03b58921fd6b692e06006c9b1843d4097953961441cef4a2df7667ca6` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band4_upper_meadows_ironwood__07__the_ironwood_grove__day.png` |
| 14 | 5 | 2 | `11b9649f02ffb4579a0c9c768131af79b9946dd86f60d90c717707b3d22df5a0` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band4_upper_meadows_ironwood__07__the_ironwood_grove__night.png` |
| 15 | 5 | 3 | `cf89cfde2e3928f73accd6866d33c864b20d59ce55900c56bb6f2ade2ef21616` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band4_upper_meadows_ironwood__08__the_ridgeline_watch__day.png` |
| 16 | 6 | 1 | `de382d980eb089b768f747857b681c4903e0c4369ef468f1ea41984274701502` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band4_upper_meadows_ironwood__08__the_ridgeline_watch__night.png` |
| 17 | 6 | 2 | `32d9a67d496e92a9c8228ed07275e4eca17d2e0ba98412c31c5e18c371fa4ecb` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band5_stronghold_approach__09__stronghold_approach__day.png` |
| 18 | 6 | 3 | `f3c6315ab2b425a9f06c1a31070ef402723df3ff0806be936d32702dee02765f` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band5_stronghold_approach__09__stronghold_approach__night.png` |
| 19 | 7 | 1 | `128d7f5203356aecc01e88259b402f4f8b5a58a655bb34f15249a876eca8548b` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band5_stronghold_approach__10__meadows_hall__day.png` |
| 20 | 7 | 2 | `b5ad7c25214bdc6acc2564ab501934679a76598bbfb5924c79441a97991f7021` | `C:/Projects/Tetherbound/shots/catalogue/meadows/round-20260909T002752Z/meadows__band5_stronghold_approach__10__meadows_hall__night.png` |

## Pending assembly

Cloudreach, Stormwood, Tidewake, the combined sheet, and any legibility split pages
will be added only from capture rounds explicitly validated by the audit coordinator.
