# Ralph Prompt Compatibility / Deduplication Map

**Purpose:** Preserve every existing prompt while preventing Ralph from executing overlapping owner-play briefs as duplicate implementation work.

`docs/prompts/` contains the original numbered review prompts, the newer detailed Phase -1.7 prompts, and seven earlier `OP-*` owner-play prompts that overlap them. Nothing is deleted. The active execution contract is `docs/ROADMAP.md`; use this map when two prompt files describe the same owner finding.

## Rule

When an older `OP-*` prompt and a newer canonical prompt/package overlap:

1. inspect current `main`;
2. read both for any unique acceptance detail;
3. implement the work **once** under the canonical owner named below;
4. do not create a second branch/system merely to “complete” the duplicate prompt;
5. when bookkeeping is updated, record both old references as satisfied by the same evidence/implementation where appropriate.

The newer owner decision always wins where wording conflicts.

## Legacy overlap mapping

| Legacy existing prompt | Canonical current owner |
|---|---|
| `39-OP-BUILD-valheim-repeat-snap-and-dismantle.md` | Gate A through `40-BUILD-valheim-repeat-placement.md`, `41-BUILD-dismantle-full-refund.md`, `42-BUILD-modular-snap-contract.md`; assembled/verified by `56-OPENING-first-session-to-tournament.md` |
| `40-OP-BED-gradual-overnight-creature-recovery.md` | `43-CREATURE-BED-gradual-overnight-rest.md` + `61-EXPEDITION-rest-rhythm.md` |
| `41-OP-HARVEST-equipped-tool-swing-and-resource-feedback.md` | `44-GATHER-equipped-tool-swing-and-pickup-feedback.md` + Gate A/B evidence |
| `42-OP-CATCH-palworld-like-aim-and-throw.md` | `45-CATCH-over-shoulder-aim-and-throw.md` + Gate A/B evidence |
| `43-OP-CREATURE-UX-release-levelup-and-exploration-cycling.md` | `46-CREATURE-release-ceremony.md`, `47-CREATURE-level-up-feedback.md`, `48-PARTY-cycle-pals-in-world.md`, plus `67-FIVE-creature-pressure-and-bond.md` |
| `44-OP-WORLD-pond-water-doors-map-trails-and-density.md` | `49-POND-real-water.md`, `50-WORLD-usable-building-doors.md`, `52-MAP-all-authored-trails-visible.md`, plus regional packages 62–66 and `55-MEADOWS-gameplay-assembly-master.md` |
| `45-OP-MEADOWS-core-loop-purpose-and-encounter-density.md` | `53-MEADOWS-pokemon-first-core-loop-density.md` as legacy integration brief; current master ownership is `55-MEADOWS-gameplay-assembly-master.md` + `57`–`70` gameplay packages |

## Additional numbering ambiguity

There are duplicate numeric prefixes (`39`–`45`) because these prompt generations were authored in separate passes. **Never identify a prompt by number alone. Use the full filename.**

The active plan’s table of “existing 54 prompts” refers to the canonical review/Phase -1.7 sequence represented in its mapping; the seven `OP-*` files above are preserved compatibility briefs and are consumed through this map rather than becoming seven additional implementation projects.

## Definition of done

No existing owner instruction is lost, but overlapping descriptions converge on one implementation and one player-facing acceptance result.