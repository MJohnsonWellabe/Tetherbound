# First camp: village gathering route

Owner direction on 2026-09-08 shifted the next batch to playable game content.
Main's own run 34264602920 passed on
043cd1061ba8e1423d1681c7479d9ad36f6d4317 before this work continues.

Tam now directs the player along the path to Practice Meadow, explains the
knife's use for binding fiber, and reminds them to collect fallen materials.
The foreman describes the tent, outdoor fire, sheltered bedroll and one
Creature Bed, then connects that camp to caring for the team and visiting Halda.
The corresponding quest guidance names the same location and pieces.

Two existing resources support this walk: deadwood order 1020 moves from
Garrick's exact standing position to the path shoulder at [7,-24]; grass order
1027 moves to the Practice Meadow clearing edge at [31,-32]. Their models,
yields, tools and identifiers are unchanged. No resources were added.

The fresh playthrough previously demanded five beds even though the authored
home quest requires one. Its existing helpers now have an explicit lesson mode
derived from home.required_pieces. That mode pays for one bed, assigns each
unrested retained entrant in turn, and requires an actual sleep and condition
receipt for each. The default five-bed mode and its three-night bound remain
unchanged. Tournament eligibility still checks all five actual creatures.

Existing content checks: 29 tests / 22,302 assertions passed. Existing dialogue
and quest checks: 110 tests / 1,998 assertions passed (the suite includes an
expected unknown-dialogue negative control). Existing helper and home/quest
checks: 60 tests / 896 assertions passed with clean engine logs.

Four actual-world day/night frames were captured successfully with the existing
location survey, using a thin viewpoint-only artifact script. Owner save hashes
were unchanged. Frames are under shots/locations/wave4-camp-loop-1925-*.png;
the capture is staged visual evidence, not fresh progression evidence.

A fresh, code-blind judge answered key-art belonging **no**, and same kind of
game as Palworld **yes**, explicitly without claiming shipping-quality parity.
It identified fragmented creature textures, sparse needle-like grass and an
unclear path, plus crushed night foregrounds and weak distance separation.
The bounded review is complete; these frames do not establish a visual pass.

The genuine fresh run wave4-fresh-camp-lesson ended at 595.393 seconds in
scratch four_biome_fresh_35664_2471. It completed the ordinary opening and new
village dialogue, earned five creatures and ten training wins, gathered the
actual camp bill (18 wood, 18 fiber, 8 stone), and paid for the camp. Two
unrested entrants used the real bed and completed actual nights on days 2 and
3, each becoming ready and freeing the bed. The next assignment failed because
the controller walk stopped 5.2 m short at [31,0,-38]. The result is a failure,
not a completed care lesson or tournament. Owner saves were unchanged and
the engine log contains no ERROR or SCRIPT ERROR lines.

Read-only travel observation recorded 123 samples over 1,364.57 m; 92 samples
had fewer than two visible creatures, and one interval was undersampled.
These are observations of this path, not full-road acceptance. Opening-to-ending
and full forward-view coverage remain unproven.

After that run, two Tidewake text corrections were added: Salt Crown now names
the mandatory charting interaction by its actual visible label, and Nerissa
describes defeating her team before releasing the Guardian rather than directing
the player to timed conduits her encounter does not implement. No completion
conditions, encounter mechanics or costs changed. These texts were not loaded
by the completed fresh run.
Existing Tidewake dialogue/dock and general dialogue/quest checks passed
113 tests / 2,053 assertions. The expected unknown-dialogue negative control
is present; there are no script errors.
