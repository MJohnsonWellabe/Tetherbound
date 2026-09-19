# Owner directive — Stage C6 pulled forward

Recorded from the owner conversation, 2026-09-08. This supersedes the current
bounded terrain/cloud/performance work; the separate earned-content lane continues.

> GOAL: Hard visual pass, all four biomes — general audit, not a fix list.
> This supersedes whatever visual/content-adjacent work is in front of you
> right now, EXCEPT the parallel content lane in §5, which keeps running
> unblocked on a separate agent.
>
> This is Stage C6 of docs/DEVELOPMENT_ROADMAP.md (the four-biome visual bar)
> pulled forward and run now instead of waiting for the full audit gate.
>
> Owner's trigger complaints — creature color/size reading as random-bright
> instead of matching their reference art (glow is fine, wanted even; the
> color/scale relationship to reference is not), terrain reading badly, and
> some end-of-chapter locations reading as half-built — are EXAMPLES that
> prompted this, not the scope. Do not treat them as the checklist. Find
> everything a full pass finds.

## 1. Method — survey every area, not one route

Extend tools/survey.sh (or write an equivalent) to walk EVERY location
reachable through the Settings debug-teleport catalogue: all regions/bands in
the Meadows, Cloudreach Cliffs, Stormwood, and Water/Tidewake, day and night.
Do not sample one biome's route and extrapolate to the rest.

Frame creatures and structures with the 1.80 m trainer in shot as a scale
reference where possible (the visual-judge skill's scale-agreement rubric
needs this). Generate one contact sheet per biome plus one combined sheet
(godot --headless --path . --script tools/contact_sheet.gd).

## 2. Judge — use the existing blind-judge workflow across the FULL rubric

Run .claude/skills/visual-judge against every sheet, unmodified rubric,
critic sees only frames + docs/reference — never told what changed or that
this is a hard pass. Its rubric already covers silhouette/readability, color
and value structure, intentionality (authored vs. procedural-looking),
lighting, horizon/depth, interface, artefacts, and scale agreement — run all
of it, everywhere, not just the categories the owner happened to notice.

Turn every accepted finding into a Stage-C-style item: observed problem,
exact frame/location, likely owning system/file, proposed fix, and whether
it's fixable by scene/material/config change or needs art not in the build.
No numeric score — the project's own audit rule forbids reducing this to one.

## 3. Root-cause discipline — universal fix, not per-instance patching

For every finding, before fixing it, check whether it's local (one asset,
one location) or systemic (a shared material/shader/config/derivation that
many things read from). If the same class of defect shows up in more than
one place, the fix belongs in the shared system, not in repeated per-instance
patches. Say explicitly, per finding, which kind it is.

Growing is allowed to correct undersized elements; shrinking anything to fix
a scale mismatch is not (CLAUDE.md hard rule, owner directive 2026-09-01).

## 4. Hard rules that still apply

No new creature meshes or Meshy generations without owner-supplied reference
art — the 2026-09-07 pilot-subject carve-out is a single already-scoped
exception, don't assume a second. Reuse the installed creature/humanoid/
nature/prop families. Keep the red/oxblood family reserved for Team Tether.
Don't invent a new gameplay/story decision to explain away a visual gap —
ask if genuinely blocked on one.

## 5. Parallel content lane — do not pause it

Keep a separate agent advancing the current earned-continuous-path/content
work (the wave PRs already in flight). The two lanes must not edit the same
files concurrently; if a visual fix and a content fix would touch the same
script, sequence them — don't block either lane on the other's full scope.

## 6. Evidence

Report in docs/CURRENT_STATE.md / a ralph/reports/ entry: prioritized
findings across all four biomes, before/after contact sheets for every
claimed fix, and an explicit split of what's fixable in-engine vs. what needs
new art or reference. No "looks better" claim without a re-run sheet proving
it, on every biome's sheet the fix should touch, not just the one it was
found on.
