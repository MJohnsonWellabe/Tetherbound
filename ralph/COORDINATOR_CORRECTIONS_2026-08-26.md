# Coordinator corrections — 2026-08-26, ~00:50Z

Two things in `ralph/HANDOVER_2026-08-26_COORDINATOR.md` are no longer true, and
one new pipeline defect is recorded here. Cited to file and line, per that
handover's own §6 rule.

## 1. The release does NOT serve a branch build. It serves `main`.

Handover §5 says the download site and the `latest` release serve a build made
from `ralph/WORLD-GRASS`. That was true at 20:15Z and was overwritten at 23:48Z.

Measured from the Actions API, `release.yml` runs:

| run | ref | head_sha | event | created |
|---|---|---|---|---|
| 633 | `main` | `7c47b893` | workflow_dispatch | 2026-08-25T23:37:58Z |
| 632 | `ralph/WORLD-GRASS` | `54e2cd26` | workflow_dispatch | 2026-08-25T20:05:14Z |

Run 633 replaced run 632's asset. Current `latest` asset state:

- `Tetherbound-windows.zip`, uploaded **2026-08-25T23:45:24Z**
- `sha256:41612bb8fef5670a2dcbd0b29f6b3e868fa2c2c041e35b5f62d65f14c7c397a9`
- release body: "Automatic build of `main`, commit `7c47b893…`"

Note the body's word "main" is hardcoded prose (`.github/workflows/release.yml:150`)
and is NOT evidence of the ref — `${{ github.sha }}` on that same line is. Do not
read the body's "main" as proof; read the sha.

**Owner directive, 2026-08-26:** *"I don't care about playing grass. just keep the
deploy running main."* The deploy tracks `main`. Do not dispatch `release.yml`
against a `ralph/**` ref again; let `main` pushes drive it.

## 2. `verify-owner-regressions-shard` is intermittently red, and it gates every branch

Not a known-red. Unlike `verify-continuous-core-known-red`
(`ci.yml:1786`, `continue-on-error: true`, so it never affects a run conclusion),
this job has no such flag and IS in `export`'s `needs:` list
(`ci.yml:1814`). `tools/ci/ship_branch.sh:118` ships only a run whose
`conclusion == "success"`, so one red here strands a branch.

The failing assertion, CI run 2463 job 98017562064:

```
arena containment FAIL: burrow warrens / mouth: the fight's own centre
((-363.5901, 4.1484, 2619.013)) is not recognised as inside any chamber
```

That is `tests/smoke_arena_contain.gd:174`, reached when
`combat_arena_bounds_at()` returns `<= 0.0`. That function
(`scripts/world/burrow_warrens.gd:1181-1193`) returns `-1.0` when the point
falls outside every rect in `_footprint`.

**Why it is nondeterministic.** Spawn placement itself is deterministic — a fan,
not a scatter (`burrow_warrens.gd:940-947`, and its own comment says the world is
deterministic by contract). But `_approach_and_engage_wild()`
(`tests/smoke_arena_contain.gd:295-305`) teleports the player to
`wild.global_position + back * 2.0`, i.e. to wherever the wild creature is *at
the moment the test runs*, and `Warrens_mudsnout_1` is a live wild body that has
been simulating since world load. Frame timing on a CI runner therefore decides
whether the fight opens inside the mouth chamber's footprint or outside it.

**The decisive evidence it is not the branch's fault:** this same job PASSED at
2026-08-25T23:38Z on `ralph/OPENING-STARTER-FOCUS`, which is 0 commits behind
`main` and whose diff is additive tooling only. Same gameplay code, opposite
outcome, 65 minutes apart.

`ralph/UNITTEST-VEG-CORRIDOR-SPLIT` cannot cause it either way: the job invokes
`godot --headless --script tests/smoke_*.gd` directly (`ci.yml:1720-1729`) and
never goes through `run_tests.gd`, which is the only script that branch changes
besides adding a job and a `--skip=` flag used solely by `verify-unit-tests`.

**Open question for whoever takes this.** Do not "fix" it by loosening the
assertion. There are two readings and they need deciding on evidence:
its own header says the test exists to prove OP21-25's shrink happens, so a
fight opening in a spot the building does not recognise may be the real defect
rather than test noise. The safe test-side fix is to make the engage
deterministic (place the fight at a known point inside the mouth chamber, or
settle/relocate the resident first) — not to accept a `-1.0` bound.

## 3. What the veg-corridor split actually proved

CI run 2463 on `ralph/UNITTEST-VEG-CORRIDOR-SPLIT`:

- `verify-veg-corridor`: **success**, 7m19s against its new 25-minute ceiling.
- all six `verify-unit-tests` shards: **success**. Shard 1 was the slowest at
  9m50s; shard 2, the one that was killed twice, finished well inside budget.

The split works. The only thing standing between it and `main` is §2 above.
