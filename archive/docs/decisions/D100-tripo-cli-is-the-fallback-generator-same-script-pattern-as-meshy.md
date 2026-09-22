# D100 — Tripo CLI is the fallback/comparison generator, on the same script pattern as Meshy

**Status:** accepted
**Found during:** wiring up the Tripo comparison candidate that
`TETHERBOUND_3D_ART_PIPELINE.md` §2 has always named ("Tripo comparison
candidate if Meshy results are inadequate") but that nothing in the repo had
ever implemented.

## The decision

Tripo3D's official CLI, [`tripo-cli`](https://www.npmjs.com/package/tripo-cli),
is installed the same way Blender and Godot are — fetched idempotently by
`tools/art_pipeline/setup.sh tripo` (a thin `npm install -g tripo-cli`, since
unlike Blender/Godot it is a small npm package, not a multi-hundred-megabyte
binary) — and driven through a new committed wrapper,
`tools/art_pipeline/tripo.py`, that mirrors `meshy.py`'s command surface
(`check`, `balance`, `generate`, `status`, `fetch`) and output layout
(`assets_raw/<species>/<candidate>/`, a `provenance.json` per candidate).

It is not a replacement for Meshy. The pipeline's preferred order stays
multi-image-to-3D (Meshy) > image-to-3D (Meshy) > text-to-3D (Meshy) first;
Tripo is reached for only when Meshy's candidates are inadequate, or for a
deliberate side-by-side comparison.

## Why a script, not the CLI's own MCP mode

`tripo-cli` ships an `mcp` subcommand (an MCP server over stdio). It is not
used, for exactly D11's reasoning: an MCP server configuration is session-local
and dies with the session; this project's containers are ephemeral and
reclaimed between sessions, so a committed script is the thing that survives.
`tripo.py` is that script, the same way `meshy.py` already is.

## Why a thin wrapper, not a second REST client

`meshy.py` hand-rolls Meshy's REST API — submit, poll, download — because
Meshy's own MCP server is nothing more than a wrapper over those same
endpoints, and calling them directly buys exact control over polling and cost
accounting (D11's point 3).

Tripo is different: `tripo make` is a single **synchronous, blocking** command
that already submits, polls, downloads, and writes a `preview.png`, and the
CLI's own bundled agent docs (`tripo docs`) are explicit that an agent must not
re-implement that polling loop. So `tripo.py` does not either. It is narrower
than `meshy.py` on purpose: resolve Tetherbound's reference crops the same way
(`meshy.reference_views()`, imported rather than duplicated), enforce this
project's own candidate-count budget guard, and normalize the CLI's output
into the same `assets_raw/` layout Meshy candidates already use, so a Tripo
candidate looks identical on disk regardless of which service produced it.

## Why the budget guard is candidate-count, not an estimated credit cost

`meshy.py`'s guard estimates cost from a measured `COSTS` table (its own
comment is explicit that the numbers came from watching the balance endpoint
before and after real batches, "NOT taken from the pricing page"). No such
table exists yet for Tripo — models, tiers and regions all vary the real
cost, and fabricating a number would violate the same "never invent
parameters" rule the CLI's own docs state for API parameters. `tripo.py`
guards on **candidate count** instead (default budget 3, matching §25's
"cheap tier, three candidates" rule), and reports each candidate's own
`credits_consumed` from the CLI's result JSON — measured, not estimated —
before and after every run.

## Why login is never automated

`tripo login` is genuinely interactive: it prints a verification URL and a
one-time code and blocks for up to ~15 minutes for a human to approve in a
browser. `tripo.py` never calls it. This is the same credential boundary
`TETHERBOUND_3D_ART_PIPELINE.md` §0.5 already draws for Meshy's own API key —
an agent session stops at the boundary and hands the exact command back to a
human, rather than attempting it blind.

## Same hard rules as Meshy

CLAUDE.md's asset rules ("Never spend a Meshy generation without
owner-supplied reference art", "Meshy is reserved for Team Tether hero
objects", "No new creature meshes or Meshy generations for the Meadows")
govern any AI 3D generation service, not the literal word "Meshy". A Tripo
candidate is subject to the identical rules, and still needs a row in
`docs/specs/ASSET_LEDGER.md` before it ships.
