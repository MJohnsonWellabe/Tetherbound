# Owner directive — agent-generated reference art, 2026-09-07

Recorded verbatim so it survives session turnover. Under `CLAUDE.md`'s precedence this
is a **newer owner directive and outranks `CLAUDE.md`'s art rules for exactly what it
covers**. Everything it does not name is unchanged.

## Verbatim

> Will codex be able to generate its own art to put into meshy? If so tell it to
> generate 3 images to replace a creature or character it wants replaced. A visual
> judge chooses the best one. Then it runs the meshy work.

## What this changes

`CLAUDE.md` carried two rules that this directive overrides, and only these two:

1. ~~"Never spend a Meshy generation without owner-supplied reference art."~~ →
   **A Meshy generation may now be driven by reference art the agent generated
   itself, provided three candidates were produced and a code-blind visual judge
   picked the winner.** Owner-supplied boards remain preferred where one exists for
   the subject.
2. ~~"No new creature meshes or Meshy generations for the Meadows."~~ →
   **Lifted for this pilot only.** The blind judge's standing finding is that the
   creature and character art is "three incompatible languages" and that it *cannot*
   be fixed by lighting, placement, retexturing or rescaling; its worst named
   offenders (the photoreal-eagle raptor, the photo-fur deer, the trainer-versus-
   villager style split) are Meadows subjects. A directive to replace "a creature or
   character it wants replaced" would be useless if it could not touch them.

**This is a pilot of one subject, not a re-opening of the roster.** One creature or
one character. The agent chooses which, and justifies the choice from the blind
verdicts already in the repo. A second subject needs a new owner instruction.

Everything else in `CLAUDE.md` stands unchanged: the humanoid cast is still reused
by default, one nature family / one village family / one prop family, Meshy is still
otherwise reserved for Team Tether hero objects, creatures still stand taller than
the 1.80 m trainer, and the five-creature rule is untouched.

## Assumption stated for correction

This directive is read as **including Meadows subjects**, for the reason in point 2.
If the owner meant it to apply only to Cloudreach, Stormwood and Water, say so and
the pilot moves to a second-biome subject; nothing else in the plan changes.

## Can Codex actually do this? — the evidence in this repo

**Yes, on the strength of a precedent already recorded here.**
`docs/specs/ASSET_LEDGER.md`, "Warden Aila dialogue portrait cleanup (2026-09-04)",
records a shipped project asset whose source is **"OpenAI built-in image editing"**,
"generated inside the owner's OpenAI workspace for this private project", installed
at `assets/ui/portraits/cloudreach_aila_clean.png`. So image generation and editing
has already been available to an OpenAI-hosted agent on this project and has already
produced an asset that shipped.

Two further facts make the plan work regardless:

- **The Meshy pipeline does not care where an image came from.**
  `tools/art_pipeline/meshy.py::data_uri()` reads any local file off disk and sends
  it as a data URI. A generated PNG is the same input as a cropped owner board.
- **There is a no-image fallback.** The pipeline exposes both
  `/openapi/v1/multi-image-to-3d` (needs images) and `/openapi/v2/text-to-3d` (needs
  none, and the file already carries a per-species prompt for every subject). If the
  session genuinely has no image generation, it says so in its report and runs the
  text path instead — it does not stall, and it does not fake a board.

## The loop the owner asked for

1. Pick the subject and justify it from the blind verdicts.
2. Generate **three** reference images — same subject, same brief, three takes.
3. A **code-blind visual judge** picks the winner: shown the three candidates and
   `docs/reference/` only, told nothing about which is which or what the pipeline
   intends to do with them. It never judges its own output, and the lane that made
   the images never judges them.
4. Run the Meshy work from the winning image.
5. Judge the resulting mesh blind, in the world, beside the creatures it has to live
   with — the whole point is style coherence, so a candidate that looks good alone
   and still clashes has failed.

Full task contract, budget caps and stop conditions:
`docs/prompts/77-CODEX-GOAL-four-biome-push-2026-09-07.md`, lane **ART-PILOT**.
