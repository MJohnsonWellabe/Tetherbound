# D17 — An evolution is always larger than what it came from

> Vocabulary note: written when the game called its creatures "pals"; R1.1 (2026-08-14) renamed the term to "creature" throughout the codebase without rewriting this historical record.
**Status:** accepted, by the owner
**Decided:** this session, on a direct instruction

## The decision

The owner: *"whatever pal is an evolution of another needs to be larger in
size."*

Every species that names another as its `evolves_into` must have a **strictly
smaller** `placeholder.height` than that target. Not "usually", not "unless the
sheet says otherwise" — strictly, and enforced.

## Why it needed writing down at all

The rule is already true in the game. The Meadows has exactly one evolution
(D13), and it reads 1.40 m Mudsnout → 2.00 m Tuskroot.

But it is true **by accident**. Those two numbers were set independently, from
the sheets' relative ordering, by someone who was not thinking about the
evolution link at all — and heights in this project are explicitly TUNABLE.
`species.json` says so, D12 moved every one of them once already, and nine more
wild species are being produced right now, each arriving with a height chosen
against the band rather than against a line.

The failure this prevents is small, cheap and completely silent: a height tune
that leaves the evolved form the same size or smaller than the runt it grew out
of. Nothing in the game would complain. There is no evolution system yet
(HANDOFF §4), so nothing reads these fields — the first person to notice would
be the owner, seeing an evolution that looks like a downgrade, months after the
commit that caused it.

A rule that only lives in prose is a rule the next height tune breaks. So it
lives in `tests/test_evolution_links.gd`, which fails naming both species and
both heights.

## What the test actually asserts

`tests/test_evolution_links.gd`, run by the normal unit suite:

- every `evolves_into` names a species that is in the table
- every `evolves_from` names a species that is in the table
- the target's `placeholder.height` is **strictly greater** than the source's —
  equal is a failure, because an evolution you cannot see is not one
- every species in a line declares a height at all, so the comparison above is
  never two defaults quietly agreeing
- the two ends of each link agree: if A evolves into B, B evolves from A
- at least one link exists, so deleting the last one cannot turn the file green
  while proving nothing

## What this does NOT change

**It does not reopen the scale band.** D12 set pals as peers to the 1.8 m
trainer and D13 confirmed it against the owner's own pack, which asked for
smaller creatures; the answer was that D12 stands. The shipped band is
1.20–2.60 m and this decision does not touch it. D17 constrains the **relative**
size of two forms of one creature. It says nothing about absolute size, and the
test deliberately asserts nothing about the band — that is D12/D13's territory
and duplicating it here would mean two places to argue with.

**It does not add an evolution system.** `evolves_into` and `evolves_from` are
still data nothing reads. This makes that data trustworthy for whoever
eventually does.

**It does not decide how much larger.** The owner said larger, not "by 30%", so
that is what is enforced. Mudsnout → Tuskroot happens to be a 43% jump; nothing
below claims that is the standard.

## The honest trade-off

This constrains future design. A creature line that evolves into something
*smaller* — a bulky larva that becomes a lean flier, a fat grub that becomes a
dragonfly — is now forbidden by a test rather than by a discussion. That is a
real cost, and it is a shape some creature rosters use deliberately.

It is accepted because the owner asked for it plainly and because the biome has
one evolution, not because the general case was reasoned about. If a later biome
wants the shrinking line, that is a decision to bring back to the owner and this
file to amend — not a test to quietly delete.

## Where it is recorded

- this file
- `tests/test_evolution_links.gd` — the enforcement
- `data/pals/species.json`, in the comment header beside `_comment_wild_heights`
