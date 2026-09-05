# D87 — A shared line borrows its speaker's face, and a villager's hair colour is laid on by mask

**Date:** 2026-09-05 · **Decided by:** lane N04-DIALOGUE-PORTRAITS-0905, under the
COMMON rule that a lane makes the smallest defensible call and records it rather than
stopping to ask. Sources: `ralph/briefs/0905-followup/N04-DIALOGUE-PORTRAITS.md`,
the W08-DIALOGUE-CAMERA and W04-PORTRAITS reports, D81, owner directive 2026-09-04
item 8b (*"fix the picture during dialogue always being the main character"*).

Three calls. None is a new mechanic; two are reversible in data and one in one function.

## 1. The panel draws the line's own plate; a SHARED line takes an identity from its caller

`dialogue_panel.gd` never keyed the portrait off a constant on the tree this lane started
from: it pulls `portrait` off the runner's current line every draw, exactly as it pulls the
speaker's name. The "every NPC shows the player's face" that W08's judge saw was the data
W04 had not yet re-pointed, and W04 landed in PR #45. What was still wrong on `main`:

- **Warden Aldis** (three conversations in `data/dialogue/stronghold.json`) still named
  `trainer.png`. He now wears `warden.png`, the plate W04 rendered from the installed Warden
  body. That is the plate D81's eight-name contract reserved for him, the plate the
  unlanded finale lane (`ralph/W06-FINALE-0904`) chose for him too, and the family
  `tests/test_dialogue_portraits.gd`'s rank rule already demanded.
- **The generic trainer refusals** (`trainer_no_usable_creature`,
  `trainer_no_ally_deployed`) are one conversation said by every trainer in the chapter.
  JSON cannot know who is speaking a shared line, so `dialogue_panel.start()` now takes an
  optional identity `{"speaker": name, "portrait": path}` that the caller who knows the body
  lays over the line for as long as it is open. `trainer_npc.gd::speaker_identity(spec)`
  supplies it: the trainer's `name`, and the plate its own `challenge` conversation wears,
  so a trainer's face is written in exactly one place and the refusal cannot disagree with
  the challenge that follows it. With nothing passed, every field still comes from the line.
  The identity is dropped the moment the conversation finishes.

The identity is an overlay for shared lines only. Per-speaker conversations keep carrying
their own `speaker` and `portrait` and nothing is laid over them; the test suite refuses
any non-player speaker resolving to `trainer.png`.

## 2. The stronghold's bodiless speakers keep the player's plate, by name

`Tether Readout`, `Tether Duty Board` and `Chamber Five` are a status board, a duty
roster and second-person narration ("You pull it."). They are what the player reads and
sees, and the finale lane chose the player's own plate for them on purpose — that lane owns
the file, and D81 item 1 anticipated a faction plate instead. This lane does not overrule
the file's owner: those three speakers are exempt from the not-the-player's-face rule **by
name**, and nothing else in `stronghold.json` is. If the owner would rather they wear
`grunt.png` (D81's faction plate) or no plate at all (the panel already leaves the frame
empty for a missing one), that is three strings in one file and one list in one test.

## 3. A villager's hair colour is laid on the PAINTED hair through a baked mask

Eight villagers share the `villager_female` rig (Mira, Tam, Halda, Rae, Doss, Sela, Dara,
Nan). Its per-NPC hair colour reached only the separated `hair_ponytail` mesh at the nape,
invisible from the front (D81's finding; two code-blind judges counted the repeats
unprompted). The hair a player sees — fringe, cap, sides — is painted into the body
texture on the one fused material the rig shares with its face and clothes, so a material
multiply cannot reach it without tinting the face, which is the whole-body hue shift the
owner rejected ("looks stupid").

The colour is therefore applied **by region, not by material**: the body material's
`detail` layer mixes a solid hair-colour texture over the albedo wherever
`assets/characters/villager_female/villager_female_lod0_hair_mask.png` says there is
painted hair, and nowhere else. The mask is baked once from the rig itself by
`tools/_bake_villager_female_hair_mask.py` — UV islands skinned to the head bones,
colour-keyed to the painted hair, connected components under 1500 texels (pupils, lashes,
brows) dropped — and its value is the painted shading (`clamp(luma/28, 0, 1)^0.7`), so a
crevice stays a crevice in the new colour rather than flattening to a swatch. The same
material goes on the ponytail, which shares the texture, so nape and fringe agree. No new
geometry, no new mesh, the material slots the rig already has. A rig with no
`<model>_hair_mask.png` beside it keeps the ponytail-only behaviour; nothing is invented
for it.

The hair colours themselves (`data/config/art.json`, `data/config/village_npcs.json`,
`river_nest_clear.gd`) are unchanged. Three of them are close dark browns (farmer
`#5c3a22`, ranger `#7a3c22`, Rae `#7a4a2c`) and were chosen when the colour was invisible;
now that it lands, whoever owns those files may want to spread them. That is data.
