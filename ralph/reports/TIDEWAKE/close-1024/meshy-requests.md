# Tidewake Meshy requests, 23 Oct 2026 (lane tb/tidewake)

Concept step as in `assets/props/meshy-1022/*/provenance.jsonl`: image-to-image from the refs below, then image-to-3D. Shared refs for every item:
`docs/reference/boards-2026-09-06/water-veilfall-stronghold-board.png` (palette: pale stone, weathered wood, teal water, aged brass, navy cloth) and the installed family's look, `assets/props/meshy-1020/tidewake_fisher_hut/` and `tidewake_rowboat/`. Common suffix for each concept prompt: "Stylised realism in the Palworld / Tetherbound key-art style, chunky readable silhouette, hand-painted materials with wear. ONE isolated object, whole object in frame, three-quarter view, plain light-grey background, even studio light, no text, people or creatures. No red or oxblood anywhere."

Scale check: every size is against the 1.80 m trainer and the installed dock (deck about 0.6 m above water, 3 m wide planks). Every result lands flag-OFF in `data/config/tidewake_look.json` until judged.

| # | Name | Size (L x W x H) | Purpose | Brief |
|---|---|---|---|---|
| 1 | tidewake_driftwood_log | 3.0 x 0.5 x 0.6 m | F13#5 / P2-066: natural drift markers in the currents (the installed log.glb reads as a grey box) | Sun-bleached silver-grey driftwood log, two snapped branch stubs, twisted grain, a little green weed at the waterline; flat underside so it sits low on water. |
| 2 | tidewake_moored_sailboat | 6.5 x 2.0 x 6.5 m (mast) | F13#5 docks: boats at the jetties; 3.6x the trainer, hull top about 1.0 m above water | Single-mast wooden fishing sloop, weathered pale planks with teal trim band, sand-coloured furled sail on the boom, coiled ropes and a net heap in the stern, small brass lantern at the bow. Waterline flat. |
| 3 | tidewake_boathouse | 8.0 x 5.0 x 5.5 m | F13#5 docks: the inhabited harbour silhouette from the water (a building that sits half over the water on stilts) | Open-fronted stilt boathouse: pale timber piles, reed-thatch gable roof with a deep overhang, net loft under the eaves, wide water-level slip opening on the front, ladder to the deck. Underside of piles extend 1.5 m below the deck line. |
| 4 | tidewake_smokehouse | 4.0 x 4.0 x 4.5 m | F13#5 / P2-011: a second building type so Reedhaven is not all one hut | Small stone-and-timber fish smokehouse: pale fieldstone base, weathered plank walls, reed roof with a squat stone chimney, fish hanging on a rack under a side awning. |
| 5 | tidewake_channel_spar_buoy | 0.9 x 0.9 x 2.6 m | F13#5 / P2-066: tall current-channel marker readable at 40 m (the installed buoy marker reads small) | Tall wooden spar buoy, alternating weathered white and teal bands, a small aged-brass bell cage and a navy pennant on top, barnacled float collar at the base. |
| 6 | tidewake_dock_work_cluster | 2.0 x 1.4 x 1.2 m | F13#5 inhabited docks: deck props showing daily work | Cluster: two coopered bait barrels, a coiled rope, an open fish basket of silver fish, a gutting stool with a knife-less wooden board, a mending net draped over a barrel. |

Water materials are a scene/shader change (water depth bands, foam), not a Meshy asset; this lane does them.

## Second batch, 24 Oct 2026 (judge-driven)

All three w1 judges call the Veilfall close-up the weakest frame in the batch and mark it `new_art`: "near-black faceted slabs with untextured facets", "an opaque white quad whose bottom edge stops dead in mid-air", no mist, no plunge pool, no scale cue. The board (`water-veilfall-stronghold-board.png`) asks for pale stratified limestone, layered cascades and turquoise pools.

| # | Name | Size (W x D x H) | Purpose | Brief |
|---|---|---|---|---|
| 7 | veilfall_cascade_tier | 18 x 10 x 12 m | F39#4 / P2-010: one modular tier of the hero falls, three or four stacked and offset make the cascade | Pale stratified limestone cliff tier: horizontal bedding courses with a weathered lip, a wide notch where the water pours, wet darker stone in the pour line, moss and sea-grass on the dry shoulders, a shallow turquoise catch basin cut into the top. Flat base and top so tiers stack. |
| 8 | veilfall_plunge_rocks | 9 x 7 x 3 m | The base of the falls: the frame currently ends in mid-air with no pool | Cluster of water-worn pale limestone boulders around a shallow basin, polished and darker where the water strikes, white mineral crust at the waterline, a few ferns in the crevices. |
