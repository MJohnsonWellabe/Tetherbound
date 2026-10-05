# F26 Low verification batch (labels, lure smoke, stands)

After frames: source `fca48154` (Low, Compatibility, llvmpipe; all runs exit 0 with zero native ERROR lines; see `exits.txt`).
Before frames: the original Low census and route stills (`4d75308a`/`445098af`). The lure-smoke before frames
are pre-tune band data (`b1d76e75~1`) rendered at the same explicit stands with `tools/capture_f26_low_stands.gd`.
Eighteen blinded X/Y pairs went to a fresh code-blind judge (`judge-verdict-blinded.md`); `blind-key.json`
records `after_is`. Decoded:

- **After better 16, before better 1, same 1.** The before-better pair is 13, meadows route_02 night: the
  new Hall doorway is slightly muddier at night. That comes from the integration Hall, not these fixes.
- **Lure smoke (b1d76e75, 5390b5b6):** all four dark pole-like columns (Bram, Doss, Burrow stand,
  Burrow census) are on the before side. After: soft translucent smoke.
- **Labels (ced438ee):** all three mirrored labels (Hall pedestal day and night, Cloudreach Master
  sign) are on the before side. After: readable.
- **Stands (fca48154):** the trunk at Ridgeline, the sandstone at the Veilfall crown, and the pickup
  inside the legs at Lantern Hollow, Glass Field and Stormheart are all on the before side.
- **Hall roof:** the roofless interior is before-only. It is resolved through the integration merge.

Still open:
- Pair 17: the Veilfall crown has a grey horizon band after the stand fix as well.
- Cloudreach High Perches: a white Master site pillar stands through the player on both sides (tb/visual-cloudreach).
- Pair 06: a far fogged landmark now reads as a pale translucent pillar (minor).
- Veilfall spray: the fix was ineffective and is reverted (85c4574f).
