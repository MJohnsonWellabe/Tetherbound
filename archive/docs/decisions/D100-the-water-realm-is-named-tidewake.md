# D100 — The water realm is named Tidewake

**Date:** 2026-09-08
**Status:** accepted (owner decision)
**Scope:** player-facing naming only. No code, id, flag or filename changes.

## Decision

The fourth realm's player-facing name is **Tidewake**.

`data/config/realm_hearts.json` → `realms.water.display_name` is now `"Tidewake"`,
replacing `"Water Archipelago"`.

## Why it needed a name

It was the only realm named like a directory. Its siblings all carry proper names:

| Realm | Display name |
|---|---|
| meadows | The Meadows |
| cloudreach | Cloudreach Cliffs |
| stormwood | The Stormwood |
| water | ~~Water Archipelago~~ → **Tidewake** |

The gap was visible in the relic names too. Meadows and Cloudreach name their region
in the reward — "Heart of Meadows", "Wings of Cloudreach" — while the water relic is
the "Tideglass Compass", which names the object and never the place. The region had no
proper noun anywhere in the game.

## Why Tidewake

**It is built like its siblings.** Cloudreach and Stormwood are both
[element] + [landform] compounds, one word, two syllables. Tidewake is the same
construction. "Water Archipelago" was a category label, not a name.

**It fits the region's existing lexicon.** The realm already speaks in tide, salt,
brine and drift: First Shore, Reedhaven, Brine Steps, Shellwatch, Tidal Cradle, Salt
Crown, Sluice Isle, The Veilfall, Lantern Cove, Gull Rest, Drowned Garden, Deep Watch —
and a sub-region literally named Tether Current.

**"Wake" carries the chapter's arc without explaining it.** It is both the trail a
hull leaves in water — the realm is crossed by swimming and mounted swimming — and
waking. Team Tether's machine stopped the currents; the chapter ends when the Guardian
is released and `water_currents_restored` fires. The region waking up *is* the ending.
The name states that and stays quiet about it.

Alternates considered and set aside: **Slackwater** (the real nautical term for the
dead moment between tides when the current stops — the most precise word in English
for what the tether machine did, but soft as a realm name); **Saltwrack** (darker,
closest to Stormwood's tone); **Brinehold** (leans on the bound Guardian, but generic).

## What deliberately did not change

The internal realm id stays `water`. It is load-bearing across ~105 files — the entry
key `realm_key_water`, the flag chain from `water_chapter_started` to
`water_currents_restored`, `realm_relic_water_earned`, every `water_*.json` config, the
`from_stormwood` entry anchor, and the scene path `water_archipelago.tscn`. Renaming the
id would be an enormous diff for zero player-visible gain, and would collide with the
four-biome build in flight. Cloudreach already works this way: the id is `cloudreach`,
the player reads "Cloudreach Cliffs".

Scene filenames, test names and report paths keep `water` for the same reason. This is
a display-layer decision, not a refactor.

## Where the name should now appear

The name is new content, so it is written where the player meets the realm, not
retrofitted everywhere:

- **The Waterward reveal** is where the player first hears it. That dialogue is
  authored as part of the missing Stormwood→Water gate, so the name should land in the
  same change rather than as a later pass.
- The realm-entry title card and map header read from `realms.water.display_name` and
  pick it up automatically.
- Existing location names inside the realm are unaffected — Veilfall, Reedhaven and the
  rest were already proper names and stay exactly as authored.

Prose in `docs/biomes/water/BUILD_WATER_ARCHIPELAGO_TO_COMPLETION.md` and the other
water docs may keep saying "Water" as the realm id; the filename does not need to move.
