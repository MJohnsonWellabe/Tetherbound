# Authored biome slot contract assertion

Consolidated CI at runtime source `a795173a3c82058e0bef9558a5ab83487dbe0e1a`
failed the final assertion of
`test_schema_redesign.gd::test_eight_slots_have_exactly_four_live_and_four_sealed`.
Its eight IDs, four-live catalogue counts, malformed-reservation refusal checks,
sealed display names, and runtime aliases were not the failing assertion.

The final assertion called `BiomeOrder.legacy_physical_crossings()` without a
replacement runtime fixture. Integrated commit `b0064c98c8084974394b062fcf6d6bde9a4558ca`
correctly preserves legacy crossings until the actual portal replacement is
enabled. Thus that helper returns true while the portal runtime is off, even
though the authored retirement flag is false. The schema test conflated the
authored contract with the separately gated runtime behavior.

The correction changes only that assertion. It reads the canonical JSON flag
directly and requires an actual boolean false. Missing, numeric, string, and
true values cannot pass. Every other byte of the schema test remains unchanged;
all three catalogues retain four live and four reserved rows. No runtime code,
schema, defaults, flags, or fixtures are altered.

Existing `test_portal_admission_mode.gd` cases independently exercise replacement
off/on behavior, strict readiness, runtime aliases, and rejection of reserved
and unknown biomes. All five passed in this exact CI log, and their source and
runtime dependencies are pinned unchanged. No runtime assertion was discarded
or rewritten to accept a failing behavior. The authored assertion now checks
its intended field; runtime admission retains its existing coverage.

Source comparison and read-only patch application checks passed. The named
affected selector is the original eight-slot test above. Actual execution and
independent review belong to the coordinator; no engine/import/native/render,
new agents/sessions, or coordinator worktree writes occurred here. The separate
autosave failure still has no captured rejecting snapshot and remains unproven.
This packet contains no autosave change or criterion completion claim.
