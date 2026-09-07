# N04-DIALOGUE-PORTRAITS

**Source:** W08-DIALOGUE-CAMERA-0904, W04-PORTRAITS-0904 reports.

## Why
The most severe finding across all 24 lanes' reports: every conversation in the shipped game
shows the SAME portrait (the player's own) for every speaker, verified pixel-identical across
two different NPCs by a blind judge — because the portrait panel keys off a constant, not the
speaking character. Two smaller, related findings ride along in the same file area.

## Owns
`scripts/ui/dialogue_panel.gd`, `scripts/world/trainer_npc.gd` (the two named fixes below
only — do not touch dialogue camera framing, which is a different, already-landed lane's
work), and whichever texture/material file controls the female-rig hair tint (find it via
`grep -rn hair_ponytail scripts/ scenes/` — likely a shader parameter or material override
site, not a new texture).

## Do

**1. Portrait keys off a constant, not the speaker (W08 — the critical one).** In
`dialogue_panel.gd`, find where the portrait texture is set for a conversation and change it
to resolve from the speaking character (however the dialogue runner already identifies the
current speaker — check `scripts/dialogue/dialogue_runner.gd` for the speaker-resolution call
already used elsewhere in the same system) rather than a fixed/default value. Verify against
two different NPCs in two different conversations and confirm the portraits differ and match
each NPC's own portrait art.

**2. Generic trainer refusal shows the wrong portrait (W04).** `trainer_npc.gd`'s generic
"you're not ready" refusal line renders with `villager_male.png` because the script doesn't
pass the speaker's own portrait through to the dialogue system. Pass it through — the fix is
described as small; find the refusal's dialogue-trigger call and add the trainer's own
portrait path, matching however every other trainer conversation already supplies its
portrait.

**3. Female-rig villagers share one indistinguishable face (W04).** Mira, Tam, Halda, Rae,
Doss, Sela, Dara and Nan all share one female rig; the per-NPC tint that's supposed to
differentiate them only applies to `hair_ponytail`, which sits at the nape behind the head and
is invisible from the front (confirmed in-engine by two independent judges). Find where each
NPC's tint is applied and extend it to a front-visible surface (hair cap/fringe geometry,
face-adjacent clothing trim — whatever is both front-visible and not already carrying a
different per-NPC signal). Do not add new geometry or a new mesh; work within the existing
rig's material slots.

## Verify
- Item 1: a smoke or unit test that opens two different NPCs' conversations in sequence and
  asserts the portrait texture path differs and matches each NPC's own `portrait` field from
  `data/dialogue/*.json`. This is exactly the kind of test `docs/GATE2_GATE3_CLOSURE_PLAN.md`'s
  CL-G11 row already asks for ("a test that no non-player speaker resolves to `trainer.png`")
  — write that test if one doesn't already exist.
- Item 2: trigger the generic refusal for a named trainer and confirm the portrait shown
  matches that trainer, not `villager_male.png`.
- Item 3: render or screenshot at least three of the eight female-rig NPCs side by side and
  confirm they're now visually distinguishable from the front — a quick blind-judge round is
  worth it here since this was found by two independent judges already.
- After landing, update `docs/GATE2_GATE3_CLOSURE_PLAN.md`'s CL-G11 row (currently "proven
  failing (owner)") to reflect what's actually fixed here — note precisely that this closes
  the *wiring* defect (every speaker now resolves their own portrait) but does NOT add any
  missing per-NPC portrait art; if some NPCs still lack a portrait PNG entirely, name exactly
  which ones remain and leave the row honestly partial rather than closing it outright.

## Acceptance
Two different NPCs show two different, correct portraits in a live conversation, verified by
test and by a blind judge. The generic trainer refusal shows the challenged trainer's own
portrait. At least the front-visibility half of the female-rig tint gap is closed and judged
by a blind pass. `docs/GATE2_GATE3_CLOSURE_PLAN.md`'s CL-G11 row is updated with precise,
honest evidence of what is and isn't closed.
