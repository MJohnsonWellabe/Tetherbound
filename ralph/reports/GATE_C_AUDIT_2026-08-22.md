# Gate C audit — the seven owning prompts against current `main`

**2026-08-22.** Gate C is not a play gate; it is seven cross-chapter system
prompts that every regional package inherits. Nothing in this session had looked
at whether any of them were actually done, and the branch was being reported as
"Gates A/B/C verified" on the strength of Gate A's evidence run. This closes that
gap.

Audited by three independent readers, each given the prompts and the repo and
told explicitly **not to trust `DONE.md`, `BACKLOG.md`, or any doc claiming
something shipped** — only actual data files and code. That instruction earned
itself twice over; see "What the prose got wrong" below.

## Verdicts

| Prompt | Verdict |
| --- | --- |
| 57 TEAM-progression-curve | **IMPLEMENTED** |
| 58 REWARD-resource-economy | **PARTIAL** |
| 59 TRAINER-journey | **IMPLEMENTED** |
| 60 WILD-ecology-journey | **PARTIAL** |
| 61 EXPEDITION-rest-rhythm | **PARTIAL** |
| 67 FIVE-creature-pressure-and-bond | **PARTIAL** |
| 68 CHAPTER-complete-objective-chain | **IMPLEMENTED** (main chain) |

Three implemented, four partial, none absent. Gate C is in materially better
shape than "not audited" implied — but "partial" here is not cosmetic, and the
gaps are named below rather than rounded off.

## What is genuinely done

**57** — `data/config/chapter_curve.json` is the real progression table: five
region rows with `team {enter, exit, expected_members}`, `wild_band`,
`trainer_levels`, `tools`, `xp_sources`, `temptations`, `tuning`. Wired, not
prose: `chapter_curve.gd::wild_band_at()` resolves wild level from world **z**
and `encounter_director.gd:407` consumes it, so a stronghold-approach creature
is not level 4. Crucially **nothing scales to player level** — `wild_band_at`
takes only `z`. 18 tests, including that the team band never regresses and every
trainer fights inside its own region's band.

**59** — 21 trainers across all five bands, the full escalation ladder from
Bryn at level 2/3 to Warden Aldis at 16/17/17/18/20, rank recognition
data-driven through `npc_ranks.json` plus per-captain palette accents. 47 tests.
Band 2's old "no human opposition" gap is genuinely closed by
`quarry_picket_dorn` and `warrens_watch_pell`.

**68** — all 20 objectives traced individually to a real flag writer, by grep,
one at a time. No orphans, no dead ends, no duplicate flags. The full chain runs
opening catch → road gate → tournament ladder (9 steps) → South Bridge → Warrens
→ relay → mill crossing → captains → hall → Warden → `legendary_freed`. Two
tests already pin it, including one that cross-checks every `flag_id` against
real trainer defeat flags.

**67's hard rule holds.** `autoload/party.gd:19 MAX_CREATURES := 5`, `add()` is
the only insertion path and refuses a sixth, `members()` hands out a duplicate so
the list cannot be grown from outside, and no box/bank/reserve field exists in
the class. `storage_state.gd` is item chests only. The CLAUDE.md rule is enforced
in code, not just documented.

## The gaps that are real content work

**No alpha/elder tier exists at all** (58 and 60 both). No `alpha`, `elder`,
`special`, `nest` or `rare` field appears in any of the five band spawn files —
the fields are exactly `order, species, count, centre, radius, time, weather`.
`grep -rn "PW2"` returns nothing. The only hand-placed strong wild in the chapter
is the Burrow Warrens guardian, which is one creature, not "a handful across the
chapter". This is the largest single gap in Gate C.

**58's audit table omits the tournament entirely.** `grep tournament
data/config/chapter_rewards.json` returns nothing, though the rewards themselves
exist in band1's trainers. "Ordinary wild fights" has no row either.

**61: camps are buildable but not sited.** `band3`, `band4` and `band5` each
carry a `props.json` with `clusters: []` and a `harvest.json` with `nodes: []` —
comment-only stubs — and no `vegetation.json` at all. Across the back ~4.4 km of
corridor there are no authored clearings and no local harvest nodes. Corridor
scatter still yields materials, so a player *can* camp; nowhere is *worth*
camping. No attrition tuning artefact exists anywhere.

**67: no per-creature history.** No battles-fought, no caught-on-day, no
days-together counter — so the prompt's "battle history / time together surfaced
in the release ceremony" cannot be surfaced. Feeding grants no bond (only
`nourishment` and `happiness`); the canon bond list includes it. No
favourite-food concept exists.

**60: species-specific shiny rates are not implemented** — one global
`shiny_chance: 0.0078`, and `shiny_chance()` takes no species argument.

## What the prose got wrong, in both directions

The distrust instruction paid off twice, and the two failures point opposite ways:

- `data/progression/objectives.json`'s own `_comment_gateb_flags` claims the
  nine tournament-ladder flags are unwritten "CONTRACT" flags that "nothing sets
  yet". **All nine are live** — `tournament.gd`, `home_progress.gd`,
  `creature_bed.gd`, `camp.gd` and the Halda signup dialogue have since landed.
  The prose *understates* the implementation.
- `chapter_curve.json:35` still says band 2 "has no trainers of its own, which
  is prompt 59's gap". The trainer file sitting next to it has two.

Both are stale in the direction of describing a repo that no longer exists. This
is the same failure mode the reconciliation report was written for, and it is
worth stating plainly: **in this repository, a comment asserting the state of
another file is evidence of nothing.**

## One defect found, deliberately not fixed

`fight_through_the_hall` can never display `3/3`. Its `flag_id` is
`defeated_stronghold_elite`, which is also the third entry in its own
`count_flags` — so the moment the counter would read 3/3 the objective is done
and the line has moved on. The player sees 0/3, 1/3, 2/3, then it vanishes.
`defeat_the_captains` deliberately avoids this by completing on the Sigil gate,
and `tests/test_quest_log.gd` pins that pattern.

Left alone because it is an **inconsistency, not a clear bug**: the entry carries
a `_why` field explicitly reasoning that "the elite is the last of the three and
the one the Warden stands behind, so the elite's flag is the completion", and
`stronghold.json:112` gates the Warden Arena shutter on that same flag, so there
is no separate flag to complete on. Changing it is a design call for the owner,
not a repair.

## What this means for the gate

Gate C's own plan says it "does not need to be a single long serial block" and
that these can run in parallel with regional authoring "once Gate B proves the
base game". On that wording the backbone exists: the curve, the trainer ladder
and the objective chain — the three things every regional package inherits — are
implemented and tested.

What is missing is the *texture*: special encounters, sited camps, per-creature
history, and two reward-map sections. None of it blocks a regional package from
starting. All of it is real work, and none of it should be reported as done.

## Corrections to this audit, checked after it was written

Two of the reported gaps do not survive contact with the code. Recorded here
rather than quietly deleted, because both would have been "fixed" into
regressions by someone trusting the table above.

### 59's "rank is missing on 6 rows" is a false positive

`trainer_npc.gd::model_config()` treats `rank` and `config_key` as **mutually
exclusive branches**, not as two required fields:

```gdscript
var cfg := NPC_RANKS.config_for(rank) if rank != "" \
    else CHARACTER_MODEL.config_for(str(spec.get("config_key", "")))
```

`rank` builds a body from `data/config/npc_ranks.json`, whose four entries are
**grunt, officer, captain, warden** — every one a Team Tether rank. The six rows
reported as missing it are the four villager trainers and the three tournament
rounds (the same villagers again), and every one of them carries `config_key`
instead: `villager_farmer` for Bryn and Mira, `villager_keeper` for Oskar,
`villager_smith` for Tam. Checked across all five bands: **no trainer row has
neither field.**

So the absent `rank` is correct by design. Adding `rank: "villager"` would send
those seven NPCs down the Team Tether branch to a rank that does not exist,
`config_for()` would return empty, and `model_config()` returns that empty
dictionary before the per-part variants are ever applied — the villagers would
lose their bodies. The prompt's "faction/rank" requirement is satisfied by the
faction being *villager* and expressed through the branch the code actually
reads.

### 68's "3/3 never displays" is a design decision, not a defect

Left as reported above, but with the reason it stays: `stronghold.json:112`
gates the Warden Arena shutter on `defeated_stronghold_elite`, the same flag the
objective completes on, so there is no separate flag to complete on instead. The
entry's own `_why` field reasons the choice explicitly. Changing it is the
owner's call about presentation, not a repair.

### The method note

Both of these came from asking "what reads this field?" rather than "is this
field present?". An audit that checks shape finds gaps that are not there; an
audit that checks consumers finds the ones that are. The seven verdicts above
were reached by reading consumers — these two rows are where the shape-checking
crept back in, and they are the two that were wrong.

---

## What this session closed after the audit

The audit above is the state as **found**. Four of its gaps were closed in the
same session; this records which, so the table is not read later as still-open
work.

| Gap | Prompt | Now |
| --- | --- | --- |
| No alpha/elder tier anywhere | 60 | **Built.** Four alphas, one per band from 2 on |
| Reward audit omits the tournament | 58 | **Closed.** Four rows, pinned against trainer data |
| No per-creature history | 67 | **Built.** Three counters, save VERSION 14 |
| Camps buildable but not sited | 61 | **Built.** 21 harvest nodes across bands 3–5 |
| Two rest semantics "coexist" | 61 | **Resolved** — one was dead; filed as DEAD-REST |

Still open and genuinely unbuilt: species-specific shiny rates (60), the
spawn-siting audit artefact in the prompt's requested shape (60), favourite-food
and feeding-bond (67), and the attrition tuning artefact (61).

### The two bugs this work introduced and caught

Both were mine, both were caught by checking rather than by a passing test, and
both are the same mistake.

**The alpha scaled its art and not its body.** `_make_alpha` set `wild.scale`,
which grows the model and nothing else — `creature_body.gd` builds the capsule,
the collider, the hit cone and `body_radius()` from `_height` and `_radius`. A
1.35× alpha would have looked bigger while resolving throws against an ordinary
body, so a throw that visually struck it returns an edge hit or a miss. That is
`reticle_outside_body`, which this branch had already spent four rounds on.
Fixed with `apply_size_multiplier()`, which scales gameplay size and rebuilds
from it.

**Two invented data values in the camp siting.** `Grass_Large.gltf` does not
exist — the shipped fiber model is `Plant_7_Big` — and a stone scale of `0.30`
against the shipped `1.0`. The first would have stood a harvest node in the
world with no mesh, which a player reads as "nothing is there" rather than as an
error.

### The pattern worth carrying forward

`test_wild_alphas.gd` passed while the alpha fought at ordinary size, because
every check in it read **data or source text**. `test_level_up_announcement.gd`
passed a hand-rolled runner while asserting the singular `trait` against a
config that spells it `traits`.

That is the same flaw this audit names in its own corrections section — asking
*"is this field present?"* instead of *"what reads this field?"* — committed
twice more, by the person who wrote the correction. Shape-checking is easy to
write and it is how a test ends up green over broken code.

The three checks that actually caught things tonight all asked about consumers:
what does `model_config()` do with `rank`; what reads `_radius`; does this model
path resolve.
