# D42. The CC0-only rule is waived; the manifest is a provenance log

Kind: conflict

`ASSETS.md` says CC0 assets only. The owner waived that at M5: the game is
personal and non-commercial, and the instruction was to take the best assets
available rather than the best CC0 assets available.

This overrides the CC0 constraint in `ASSETS.md` and nothing else. In
particular it does not relax the quality bar, the triangle budget, or the
requirement that every shipped file is accounted for.

`ASSET_MANIFEST.md` therefore changes job. It was a licence gate; it is now a
provenance log, recording for every file in `public/` where it came from, who
made it, and what licence it carried when it was fetched. `tests/assets.test.ts`
still checks coverage in both directions, so a file cannot ship without a row
and a row cannot survive its file. No test gates on the licence string.

Keeping provenance rather than dropping it costs one table column and makes
attribution a lookup instead of an archaeology project, which matters if the
game ever does go anywhere.

The practical unlock is Quaternius' rigged, skeletal-animated creatures and
characters on poly.pizza, which are CC-BY. Those are a full quality tier above
anything the CC0-only rule allowed, and they are the reason the pals are
distinct animated creatures instead of tinted capsules (D45).
