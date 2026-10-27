# Meshy batch 2 (Creatures lane, 24 Oct 2026): naturalistic remakes for F36#0 and F29#3

Same route as batch 1 (`../meshy-batch1/REQUEST.md`): image-to-image concept with the identity reference + `style_wolf.png` + `style_bear.png`, then multi-image-to-3D textured. Batch 1 gave Mudsnout 7.40, Trailpup 7.49, Paddlenewt 6.88, Mosshell 7.08, Burrowback 7.23 (b6, CPU); its misses drive the redrafts here:
- Staticub (F29#3): b6 judges docked the remake for losing its violet lightning veins and drifting red-maroon. The prompt now demands the veins and warm brown.
- Sparkit: the remake lost the oversized fennec ears and read as a flat yellow toy.
- Pipwing: bone-heat weighting found no solution on the remake mesh (all vertices unweighted, even welded and decimated); asks for one closed shell, wings clear of the body.
- Galewisp (starter, Fly carrier): the nat-v1 GLB has its wings folded, so the glider rig cannot find wing extremes; asks for a spread-wing T-shape.
- New: Mosshock, Skyrill, Stormbrush, Cindercub, Torrentoad, Cannonback (b2-b4 judges: toy, chrome or off-identity materials). Mosshock's board has red spikes; the prompt keeps it green/yellow (red is reserved).

Scale: target heights are the installed heights, all above the 1.80 m trainer. No red or oxblood. Each result stays flag-off until a judged round passes.

| Species | Target height | Identity reference | Prompt |
|---|---|---|---|
| staticub | 3.25 m (trainer 1.80, ratio 1.81) | `assets/creatures/tetherbound/staticub/reference/native-standing-v1.png` | `ralph/reports/CREATURES/close-1024/meshy-batch2/staticub.prompt.txt` |
| sparkit | 1.95 m (trainer 1.80, ratio 1.08) | `assets/creatures/tetherbound/sparkit/reference/side.png` | `ralph/reports/CREATURES/close-1024/meshy-batch2/sparkit.prompt.txt` |
| pipwing | 1.90 m (trainer 1.80, ratio 1.06) | `assets/creatures/tetherbound/pipwing/reference/three_quarter.png` | `ralph/reports/CREATURES/close-1024/meshy-batch2/pipwing.prompt.txt` |
| galewisp | 1.90 m (trainer 1.80, ratio 1.06) | `assets/creatures/tetherbound/galewisp/reference/native-standing-v1.png` | `ralph/reports/CREATURES/close-1024/meshy-batch2/galewisp.prompt.txt` |
| mosshock | 2.95 m (trainer 1.80, ratio 1.64) | `assets/creatures/tetherbound/mosshock/reference/front.png` | `ralph/reports/CREATURES/close-1024/meshy-batch2/mosshock.prompt.txt` |
| skyrill | 3.25 m (trainer 1.80, ratio 1.81) | `assets/creatures/tetherbound/skyrill/reference/three_quarter.png` | `ralph/reports/CREATURES/close-1024/meshy-batch2/skyrill.prompt.txt` |
| stormbrush | 3.25 m (trainer 1.80, ratio 1.81) | `assets/creatures/tetherbound/stormbrush/reference/side.png` | `ralph/reports/CREATURES/close-1024/meshy-batch2/stormbrush.prompt.txt` |
| cindercub | 2.50 m (trainer 1.80, ratio 1.39) | `assets/creatures/tetherbound/cindercub/reference/side.png` | `ralph/reports/CREATURES/close-1024/meshy-batch2/cindercub.prompt.txt` |
| torrentoad | 3.25 m (trainer 1.80, ratio 1.81) | `assets/creatures/tetherbound/torrentoad/reference/front.png` | `ralph/reports/CREATURES/close-1024/meshy-batch2/torrentoad.prompt.txt` |
| cannonback | 3.70 m (trainer 1.80, ratio 2.06) | `assets/creatures/tetherbound/cannonback/reference/native-standing-v1.png` | `ralph/reports/CREATURES/close-1024/meshy-batch2/cannonback.prompt.txt` |
