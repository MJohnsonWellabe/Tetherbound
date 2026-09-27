# archive/

Historical material kept for reference, not for routing current work.

**Nothing in this directory is authoritative as a work list.** Start from
`AGENTS.md` and the live set it names (seven documents in `docs/` plus the ten
`docs/design/` specs). Unsuperseded archived owner directives keep authority for
their scope (AGENTS precedence). Do not cold-read this tree and do not take work
from it.

## What is here

- `docs/decisions/` — the 125 numbered decision records (D01–D112 plus named
  Water/Stormwood records), with `INDEX.md` listing all of them and
  disambiguating the six reused numbers. Binding decisions were recovered into the
  live set and `ralph/reports/PLAN-REWRITE/FINDINGS.md`, but the compressed Bible
  does not hold every one. Open a record when a task or code comment needs its
  exact constraint; decision numbers were reused, so cite the full slug.
- `docs/owner/` — the 33 verbatim owner directives and playtests, 2026-08-15
  through 2026-09-19. The requirements they established are in the Bible and
  `ACCEPTANCE.md`; the live record of current owner rulings is
  `docs/STATE.md`.
- `docs/specs/`, `docs/acceptance/`, `docs/biomes/`, `docs/prompts/` — the
  design, acceptance and per-biome build contracts, superseded by
  `docs/GAME_BIBLE.md`, `docs/ACCEPTANCE.md` and the `docs/design/` specs.
- `docs/*.md` — the superseded top-level documents: `00_START_HERE`,
  `GAME_VISION`, `CURRENT_STATE`, `ROADMAP`, `DEVELOPMENT_ROADMAP`,
  `AGENT_WORKFLOW`, `GAMEPLAY_SYSTEMS`, `WORLD_AND_CONTENT`, `CREATURE_DESIGN`,
  `TECHNICAL_ARCHITECTURE`, `VISUAL_BIBLE`, `SECOND_PASS_BACKLOG`, the dated
  handoffs and the dated Codex goal documents.
- `docs/art/` — art pipeline and roster prose. The one art document that is
  still used is `docs/art/HUMANOID_ASSET_INVENTORY.md`, which stayed in `docs/`
  because configs and tools cite it.
- `docs/handoffs/`, `owner/`, `ralph/` — earlier archive passes.
- `reports/` — markdown summaries and verdicts from past evidence runs (Gate F
  runs, visual-judge rounds, audits). The image and telemetry payloads that
  accompanied them are not kept in the tree; they remain retrievable from git
  history at commit `cf535cce` under `ralph/reports/`.

## Why

On 2026-09-19 the repository held 279 markdown documents under `docs/` — roughly
500 KB and ~125k tokens to orient in — including three competing roadmaps, three
visual bibles, two Gate F protocols, the vision split four ways, and six
duplicate decision numbers. An agent could not tell which was current, and
several routing documents were provably stale. The set was consolidated into
five live documents plus `AGENTS.md`/`CLAUDE.md`; the later plan rewrite settled
the current live set named in `AGENTS.md`. Everything else moved here. Nothing
was deleted.
