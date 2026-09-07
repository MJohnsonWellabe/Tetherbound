# SH54 — Audit Meadows for forbidden new creature mesh / Meshy work

## Goal
Perform the chapter-end compliance audit required by the Meadows hard rule: **no new creature meshes or Meshy creature generations for Meadows** beyond the installed/approved roster assets. Confirm the rule holds across shipped code, assets, docs, prompts, backlog and planned work.

This is an audit item, not an art-generation item.

## Canonical rule
`CLAUDE.md`, `docs/AGENT_WORKFLOW.md`, D23/spec §20 explicitly prohibit new Meadows creature meshes/generations. Credits available do not lift the rule. Existing creatures may be differentiated through material, palette, modest scale, animation, VFX, habitat and behavior.

## Audit scope
Search current `main` for:
- creature model paths under assets/assets_raw and species/visual configs;
- Meshy job manifests, generation scripts/history, production reports and ledgers;
- references in `docs/CURRENT_STATE.md`, planning docs, BLOCKED/NOTES, Ralph prompts and decisions that request or imply a fresh Meadows creature generation;
- placeholder/fallback comments that still suggest "generate a new model" as a future solution;
- alpha/elder/shiny/evolution work that may have accidentally been specified as a new mesh;
- stronghold/legendary work: confirm any Meadows legendary uses its approved installed/reference-backed asset and no extra creature occupant was generated for the Tether machine.

Distinguish historical records from active requests. Do not rewrite accurate history merely because an old item records an option that was later superseded; mark it clearly superseded if it is still ambiguous.

## Compare against roster canon
Use `docs/art/REFERENCE_CANON.md`, `ROSTER_MANIFEST.md`, species config and production reports to build the authoritative current Meadows creature asset list. Every species/evolution/legendary in Meadows must resolve to an approved installed model or an explicitly permitted graft/reuse path already in canon.

Report:
- species/character id;
- model path;
- provenance/reference board;
- whether generated before the no-new-mesh lock or otherwise approved;
- any anomaly.

## Meshy credit audit
Inspect any current Meshy-related planned spend/request. Team Tether hero objects are a separate allowed category; do not falsely flag pylons/machine as creature spend. This audit is specifically about **creature generation**.

There should be no open request to spend Meshy credits on a new Meadows creature.

## Fixes allowed
If the audit finds stale active instructions that contradict the rule:
- update the active instruction/backlog/prompt to use existing asset differentiation or mark it superseded/blocked;
- do not delete historical evidence;
- do not generate anything.

If a shipped species points to an unapproved/new mesh, stop and document the exact violation; repair to the correct approved asset if canon unambiguously identifies it. Do not invent which mesh it should use when canon is ambiguous.

## Acceptance criteria
1. A complete Meadows roster-to-model audit exists.
2. Every active species/model path is accounted for against reference/production canon.
3. No open backlog/prompt requests a fresh Meadows creature mesh/generation.
4. Alpha/elder/shiny work uses existing models only.
5. Team Tether non-creature hero-object generations are correctly distinguished from creature spend.
6. Any stale contradictory instruction is marked superseded or corrected without erasing history.
7. No Meshy generation is run as part of SH54.

## Testing / verification
Run existing roster/reference/evolution/art path tests such as `smoke_art` and any asset-ledger/reference-canon checks. Verify all referenced model files exist and import. Produce a concise audit record in the appropriate docs/SH54 completion note.

## Definition of done
The Meadows chapter can close with evidence that **every creature in it comes from the approved installed roster pipeline and no active work is trying to sneak in a new generated creature mesh.**