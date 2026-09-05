# N12-REPO-HYGIENE-0905

Lane: repository hygiene — commit the missing Godot import sidecars. Branch
`ralph/N12-REPO-HYGIENE-0905` off `origin/main` @ `f8a47ee4` (the #51 landing). No PR
opened, per the brief.

## 0. What this covers, and a note on the brief

The session was started with the instruction to read `ralph/briefs/0905-followup/COMMON.md`
and `ralph/briefs/0905-followup/N12-REPO-HYGIENE.md`. **Neither file exists on any branch
of `origin`** (`git ls-remote --heads` lists 23 branches; `ralph/briefs/` on `main` holds
only `0904/LANES.md`). The brief was presumably written in the coordinator's container and
not pushed. Rather than stall, this lane took its scope from the session title — *"commit
the missing import sidecars"* — and from the three lane reports that routed this gap to the
coordinator (W12-COMPANION §7, W18-DENSITY-B4-B5 "pre-existing repo gap", W24-LANDING
cycle-2 ledger). The report format below follows `docs/AGENT_WORKFLOW.md` §4, since
COMMON.md's own format was not available. If the brief asked for more than this, the
remainder is not done and is not claimed.

## 1. Method

Godot 4.7-stable (the same `Godot_v4.7-stable_linux.x86_64` binary
`.github/actions/setup-godot` installs) was downloaded into a fresh clone of `main` and run
exactly as CI runs it:

```
godot --headless --path . --import      # cold pass, exit 0, 5,567 log lines
godot --headless --path . --import      # warm pass, exit 0, 27 log lines, 0 ERROR lines
git status --porcelain
```

The cold pass populated `.godot/imported/` with 1,910 cache files, so the whole asset tree
was processed, not a subset. This is the procedure the repo's own convention defines for
"what should be tracked": every sidecar Godot writes beside a tracked source belongs in the
tree (953 `.import` and 1,046 `.uid` files are tracked after this change).

The inverse check was a script over `git ls-files`: every tracked `*.import` / `*.uid`
whose source path is not itself tracked is an orphan.

## 2. Findings

### 2.1 Missing sidecars — twelve `.gd.uid` files, nothing else

After two import passes on a clean checkout of `main`, `git status` lists exactly twelve
untracked files, all `.gd.uid` sidecars, all for scripts added by the Cloudreach commits
`04d844d0`, `3f9e1a14` and `47ca2e12` (2026-09-04, `codex/cloudreach-cliffs`):

| Script | uid |
|---|---|
| `autoload/realm_heart_state.gd` | `uid://b5q6ep45wyfev` |
| `scripts/world/cloudreach_world.gd` | `uid://cliocwkukov75` |
| `scripts/world/realm_gate.gd` | `uid://ivxi8f1jino4` |
| `scripts/world/realm_heart_shrine.gd` | `uid://brt5aopmv18mx` |
| `tests/smoke_cloudreach_foundation.gd` | `uid://bre2n6gq0corq` |
| `tests/smoke_cloudreach_transition.gd` | `uid://cwtltcx6r60ry` |
| `tests/test_cloudreach_chapter_data.gd` | `uid://xt5fo4b3jpdd` |
| `tests/test_cloudreach_world_data.gd` | `uid://ccugths8vvmx7` |
| `tests/test_meadows_cloudreach_handoff.gd` | `uid://df4l2dsb474je` |
| `tests/test_realm_heart_state.gd` | `uid://cngjpoojtx6kq` |
| `tests/test_realm_world_components.gd` | `uid://duo3rpew27015` |
| `tools/capture_cloudreach_foundation.gd` | `uid://cyunfl42b64i8` |

**No `.import` sidecar and no extracted texture was missing on `main`.** The 34 `.import`
files and 7 extracted textures W12 and W18 reported were committed by `e46b9524` (the
W23 lane, 02:31 UTC) and landed in #45; the eight `.uid` files the landing lane added closed
the rest of that list. What remained was the Cloudreach set above, which no 0904 lane owned.

Independent cross-check by script, before running Godot: of 943 importable assets outside
`.gdignore` directories, the only ones without a tracked sidecar were the 20 `site/img/*.jpg`
download-page images — and those are excluded on purpose (`.gitignore` line
`site/img/*.import`, `site/README.md` §"Do not commit"). Godot's own pass agreed: it wrote
no untracked `.import` at all.

### 2.2 Orphaned sidecars — 28 removed

Tracked sidecars whose source file is no longer in the tree:

| Set | Count | Why the source is gone |
|---|---|---|
| `assets/creatures/plumberry/{homer-the-wolf,kiki-the-rabbit,orson-the-penguin,zinnia-the-fox}_{0..4}.png.import` | 20 | placeholder sprites deleted; sidecars survived the deletion |
| `assets/characters/{captain_a,captain_b,grunt_a,grunt_b,grunt_c,officer_a,officer_b}/*_lod0_texture_0.orig.png.import` | 7 | the `.orig.png` regrade backups are banned by `.gitignore` (T1-CAST rule), so the sources were never tracked but Godot's sidecars for them were |
| `scripts/combat/combat_camera.gd.uid` | 1 | `combat_camera.gd` was deleted in M2 (`data/config/catching.json` records why); `docs/CLEANUP_MANIFEST.md` names this exact file for removal |

All 28 date from `a470c981` (the Gate F capstone commit that added the tree wholesale).
Removed with the one-liner `docs/CLEANUP_MANIFEST.md` prescribes, generalised to
`*.import`. Godot regenerates a sidecar the moment a source reappears, so nothing is lost.

### 2.3 The `.orig.png` sidecar can no longer come back

`.gitignore` ignored `*_lod0_texture_0.orig.png` but not the `.import` Godot writes beside
it, so anyone running `tools/regrade_tether_textures.py` locally and then opening the editor
would get seven fresh untracked sidecars. One line added under the existing rule:
`*_lod0_texture_0.orig.png.import`.

## 3. Files changed

- **Added (12):** the `.gd.uid` files in §2.1.
- **Deleted (28):** the sidecars in §2.2.
- **Modified (1):** `.gitignore` (+3 lines, comment and one pattern).
- **Added:** this report.

No script, scene, data or config file changed. 41 files, 15 insertions, 1,081 deletions
in the code commit.

## 4. Functionality implemented

None player-visible, by design. The player-facing effect is nil; the developer-facing
effect is that a fresh clone plus `godot --import` now leaves `git status` empty, so no lane
has to explain or dodge twelve untracked files, and the CI import-cache key
(`hashFiles('**/*.import')`) stops carrying 27 dead entries.

## 5. Tests run

| Command | Result |
|---|---|
| `godot --headless --path . --import` ×2 on clean `main` | exit 0 / exit 0; second pass 0 `ERROR`, 0 `SCRIPT ERROR`, 0 `Parse Error`; 12 untracked files, all listed above |
| `godot --headless --path . --import` ×1 on this branch after the change | exit 0; 0 `SCRIPT ERROR` / `Parse Error` / `Failed to load` / `Cannot open`; **`git status` clean** (nothing regenerated, nothing modified) |
| `godot --headless --path . --script tests/run_tests.gd -- --only=cloudreach,realm_heart_state,realm_world_components` | exit 0; **43 tests, 1,175 assertions, 0 failed** — every script that received a uid, loaded and exercised |

The unit set is the real check that a uid sidecar does not break loading: Godot resolves a
script's `uid://` through the sidecar from the moment it exists, and every one of the eight
test/smoke scripts that got one ran under it.

## 6. Runtime validation

The import pass *is* the runtime for this change (it is what generates and consumes
sidecars). No smoke was run because no world, spawn, creature or encounter code changed
(`docs/AGENT_WORKFLOW.md` §6). CI has not run on this branch at the time of writing — the
brief said no PR, and a push to `ralph/*` will run it; the change is docs-and-sidecars so
`ci.yml` may legitimately skip the code jobs.

## 7. Screenshots

Not a visual change; none.

## 8. Known limitations and what was deliberately not done

- **30 tracked `.import` files sit inside `.gdignore`'d `reference/` directories**
  (`assets/creatures/tetherbound/{camp_bed,camp_fire_pit,camp_firewood,camp_flame,camp_tent,
  relay_apparatus,tether_machine,tether_pylon,tm_orb,warden_body,warden_head}/reference/`).
  Godot never reads them, so they are dead weight, but their sources exist and they are
  harmless. Left alone as outside "missing or orphaned"; a one-line follow-up if wanted.
- **`site/img/*.jpg` stay without sidecars on purpose** (see §2.1).
- **`docs/CURRENT_STATE.md` was not touched.** Its §1 table is maintained by the landing
  lane per PR, and this change has no system-status row to add; this report is the record.
- **The Cloudreach scripts themselves were not reviewed.** `CLAUDE.md` bars Biome 2
  implementation before the Meadows exit gate and the W24 ledger has already raised that the
  Cloudreach commits are on `main`; giving their scripts the sidecars Godot demands neither
  endorses nor extends them. The owner's call on that work is unchanged.
- **The brief was reconstructed, not read** (§0). Anything it asked beyond sidecar hygiene
  is not done.

## 9. Commit and branch

Code commit: `54ab11d1badffcd0987e41876361ee9f0dfd5879` on `ralph/N12-REPO-HYGIENE-0905`
(this report is committed as its immediate child). Base: `origin/main` @ `f8a47ee4`.
