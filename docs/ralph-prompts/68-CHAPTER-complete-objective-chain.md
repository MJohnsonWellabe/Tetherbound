# CHAPTER-OBJECTIVES — Make the existing simple objective system represent the whole Meadows chapter

## Goal
Populate and wire the existing progression/objective architecture so the player always understands the current major goal from opening through the post-Warden outcome.

Do **not** build a giant quest engine. Preserve the repo’s small flag-driven objective philosophy.

## Current gap
The canonical Meadows story has many clear progression beats, while the current objective data represents only a small fraction of them. The chapter can therefore exist in code/world data while still feeling directionless.

## Design rule
At most one concise tracked major objective should dominate the HUD.

NPC dialogue explains **why**.
The objective line explains **what now**.
The world/map provides **where** without turning into a GPS beam.

## Required main-chain coverage
Use current exact flags/IDs/names where they exist. A representative sequence is:

### Opening
- Complete Grandpa opening / choose starter as handled by opening state.
- Build a team for the village tournament.
- Train with your creatures.
- Gather materials for a home.
- Build a functional home.
- Build a creature bed.
- Build/use your bed and sleep.
- Enter the village tournament.
- Win the village tournament.

### Lower Meadows
- Head toward / reach South Bridge.
- Earn/open access to deeper Meadows.

### Quarry / Warrens
- Investigate the Old Quarry / Rootstone lead.
- Enter the Burrow Warrens.
- Clear the guardian / recover meaningful progression reward.
- Follow the Team Tether evidence toward the river.

### River / Relay
- Find a way across the river / understand the Mill Crossing problem.
- Find/rescue the captured crossing keeper/person.
- Break the Tether Relay control.
- Defeat Captain Vance.
- Restore/open the crossing.

### Upper Meadows
- Prepare/explore Upper Meadows as required by current story.
- Defeat the three regional captains. `n/3` using current count-flags support.
- Bring/use the three Sigils to open Meadows Hall approach.

### Finale
- Enter Meadows Hall.
- Defeat stronghold opposition / elite as current progression requires.
- Defeat the Meadows Warden.
- Disable/free the tethered legendary.
- Resolve join/release if roster is full.
- Surface the post-Warden world-state acknowledgment / next-world hint without entering Biome 2.

Exact decomposition should follow existing state and avoid redundant booleans where real game state can answer completion.

## Local requests
Populate the existing local objective/request list only for meaningful optional content that deserves tracking. Do not track every cache, trainer or resource node.

Good candidates are existing CONTENT-ACTIVITIES with a clear start/completion and worthwhile reward.

## Persistence / out-of-order play
Objectives must derive from authoritative state where possible and survive save/load.

If the player completes a future action early:
- recognize it when its beat becomes current;
- do not force repetition;
- do not regress state.

Older saves should resolve to the most appropriate current objective from existing flags/world state.

## Map integration
Use current map landmarks/regions for meaningful destinations. Do not reveal the whole map or every creature. Objectives should identify places the player has reason to know about.

## Completion feedback
A completed major objective should receive brief readable acknowledgment and advance without requiring menu archaeology.

## Audit for stale wording
Some route directions may have drifted from old cardinal descriptions after macro-layout relocation. Use current geography and established world fiction; do not tell the player “east” when current authored route obviously goes another way unless the world’s naming convention supports it.

## Verification
Fresh-play and save/load tests at multiple beats:
- correct objective appears;
- current action completes it;
- next objective appears;
- already-completed future state is recognized;
- count objective works at 0/3, 1/3, 2/3, 3/3;
- map destination is sensible;
- no objective points into inaccessible/stale coordinates;
- post-Warden chain terminates correctly.

## Acceptance
- a first-time player rarely asks “what am I supposed to do now?”;
- the main chain is represented from tournament through Warden;
- HUD remains concise;
- no giant quest engine is created;
- optional requests remain selective;
- objectives persist honestly;
- world navigation still matters.

## Definition of done
The rich chapter already designed in the repository becomes legible to the player through one clear next objective at a time.