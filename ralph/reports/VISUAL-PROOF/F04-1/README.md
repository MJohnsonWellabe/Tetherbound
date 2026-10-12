# F04#1 Captain Vance at routes-west `68262126`

Captured Mon 12 Oct 2026, finished about 7:38 PM CT, by the captures lane, in a local detached worktree at `68262126`. Its own `tools/capture_f04_strike_beats.gd`; Low/Compatibility (llvmpipe), 1280x720, real time. This lane captures; it does not judge.

- **Three runs at this SHA:**
  - Run 1, lead, `--policies=stand,stand,dodge,dodge`: Galecrest fell after 2 strikes, so there was no dodge sample. The witness logged FAIL for that reason only (0/0 dodges).
  - Run 2, lead, `--policies=dodge,dodge,stand,stand`: strike 1 is the leap, dodged, and missed. The process hit its 1 h cap after strike 4 (it shared the CPU with another capture), so it has frames but no witness line.
  - Run 3, ace (Tuskroot), `--live-member=relay_captain:4`: witness PASS, 2/4 dodges avoided.
  - Rows from runs 1 and 3 are in `witness_rows.log`.
- **Sheet:** leap tell, mid-tell, hit when held still (run 1); leap mid-tell while stepping out, then the miss (run 2); Tuskroot lane tell, mid-tell, hit, then a mid-tell step-off and the miss (run 3).
- **Observed:** the leap's wide disc at the target still does not read in these frames. Only magenta slivers show around the crates on the deck by the Terrapup's feet; the ring around the Galecrest is clear. Tuskroot's lane reads on the deck.
- **Check at f1ded80d (routes-west: marker/field discs at the target's foot height, pattern cues drawn without a depth test). Finished about 9:40 PM CT Sun 11 Oct.**
  - Source: `tb/ev-meadows-fights` at `f1ded80d`, detached worktree. Tool: `tools/capture_f04_strike_beats.gd --trainer=relay_captain --policies=stand,dodge,dodge,stand`.
  - The run hit this lane's 2-hour background limit after strike 3, so beat 4 was not captured. `f1ded80d/manifest.json` lists every frame with its game frame and gap.
  - `sheet-f1ded80d.jpg`, one row per strike (tell start, mid-tell, strike, outcome +3 frames):
    - storm strike, held still: hit;
    - talon dive (the leap), dodged: miss;
    - storm strike, dodged: miss.
  - Observed: in both talon dive rows, a magenta wedge runs from the Galecrest to the Terrapup's feet, drawn over the deck and crates. The Terrapup steps off it by mid-tell and the outcome reads "it missed you".
