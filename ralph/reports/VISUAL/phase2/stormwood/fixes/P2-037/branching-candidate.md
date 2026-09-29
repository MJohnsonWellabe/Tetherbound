# Branching crown geometry candidate

The native canopy-atlas comparison left the landmark reading as a split wooden
tower with a few small crowns. Both Stormheart boards establish connected broad
limbs, overlapping canopy tiers and inhabited construction. This candidate
addresses the branching/canopy portion using the installed nature family.

`stormheart_presentation.json.branching_crown` remains disabled. When both the
master and nested flags are enabled, eight asymmetric curved boughs with forks
and sixteen overlapping leaf masses replace the six legacy boughs/crowns.
The installed TwistedTree_2/4 leaf surfaces receive instance-only shape changes;
no new texture, external generation or asset purchase is used. Curved branch
rings share each joint and carry their local frame through vertical bends.
Their bark UVs use circumference and centreline length in metres.

The existing shell, split entrance, floors, ascent, rails and collision are
unchanged. No route, platform, harvest point or progression state is added.
This is not a complete fix for P2-037: the broad trunk surfaces, architectural
detail, material integration and focal lighting still require work and review.

Independent reviewer `stormwood_dialogue_review` found no actionable source
issues. Its independent numeric reconstruction checked positive winding against
all three vertex normals across all sixteen limbs. The focused engine run
passed 7 tests / 166 assertions without diagnostics after correcting one folded
triangle caused by the original WestTop bend. The test log is
`.tmp/stormwood-phase2/branching-crown-tests-r3.log`, SHA256
`045e2d199f50c04b6b892123cff417e13108a06dd20d138f9db1b2914bd954c3`.

The new test executes the enabled crown path, checks finite vertices and
outward winding, checks for collision nodes, and verifies the disabled master
retains the legacy crown. Its clearance check covers vertices in the 145–179 m
floor band against a 46 m cylinder; it is not a complete triangle-intersection,
traversal or sightline proof. Existing presentation, wayfinding and atlas tests
also pass. Native exterior and interior views, branch joins, seams, visibility
and code-blind Bars A/B review remain required. No activation or visual pass is
claimed.

Subsequent native comparison at `d0f5151c6` is now retained in the three
`branching-*-r1` folders and `branching-comparison-coverage.json`. Fresh blind
review confirms stronger distant tree recognition but crude branch joins and
pale fragmented canopy; the full landmark and Bars A/B remain NO/NO. Eight
matched ground-level interior pairs do not establish upper-arena visibility.
See `branching-pair-verdict.md`. The candidate stays disabled.
