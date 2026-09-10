# CI ba11f58d1 — full job pass, HUD script error absent

GitHub Actions run 34468795897 (CI 4667) covers
`ba11f58d1513dffc7b978e484ae7979fc87f6035`. All 26 executed jobs passed on their
first attempt; three conditional jobs skipped: full known-red Gate B,
known-red continuous core, and export. No retry is used as acceptance.

The four unit shards total 3,206 tests / 490,813 assertions / zero failures.
Other executed coverage includes combat, core verbs, owner regressions,
regions, Gate A UI/build, bounded Gate B core, gate evidence, harvesting,
vegetation/scatter rules, terrain/scatter freshness, seven multiplayer shards
and the final solo-regression aggregate. These jobs do not constitute a full
fresh four-biome playthrough or Ally performance evidence.

All 26 complete job logs were retrieved and retained under
`.artifacts/broad-visual-0910/ci-ba11/job-<id>.log`. There are no actual
`SCRIPT ERROR:` emissions in those logs. In particular, the stale
`_prompt_belongs_to_combat` provider assignment seen in AD9 and the fourth
fresh prefix is absent from the replacement Gate A/core-verb jobs. The focused
production-provider lifecycle smoke supplies direct proof of the narrow guard;
this CI run supplies wider integration regression evidence.

The logs are not entirely diagnostic-free. Invalid species/conversation/JSON
and scoped-flag negative cases, off-tree fixture tree-access errors, intentional
realm-readiness/autosave rollback probes and shutdown resource/RID leaks remain.
Several headless integration jobs emit `Parameter "material" is null` from
the dummy renderer's `material_get_instance_shader_parameters`; the same class
is present in retained D6C logs, so it is not newly introduced by this HUD fix.
One multiplayer shard also records an expected child-process absence diagnostic
from its process-lifecycle exercise. Existing Node/npm notices are unchanged.
Green job statuses are reported separately from these caveats.

A later detailed comparison also identified two existing combat-fixture story
catch-up diagnostics: `adopt_starter is not a swap`, from
`sequence_director._hand_a_late_arrival_a_companion`. They are present in this
run and DBB, and are not classified as intentional negative tests. The unit
`Game.party has no add()` diagnostic is different: its stack identifies the
explicit malformed-party interface test. These distinctions matter when using
green CI as regression evidence; it is not a completely diagnostic-free run.

Bramblebun's matching-source correction is in the later `8aad9c373` revision
and has its own local variant/art/native evidence; it is not attributed to this
earlier run. That later revision's full CI and local Windows export are tracked
separately.
