# b17 (24 Oct 2026, CPU): recoil hit for Aquaryn and Tidecoil (GPU F36#1: 7.49 and 7.45, just under 7.5)

What was compared:
- Candidate (`--candidate-r17`, OFF): the grounded recoil hit replaces the held shove on Aquaryn and Tidecoil and their water forms.
- Base: the shipping held shove (land b67ec65dc).

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: f36_0_npc:C1, f36_0_gap:C3, f10_2_r3_capacitor. This is a confirming batch.
- Fit: linear, slope 0.843, intercept 1.587, RMSE 0.61.

| Species | Shipping (shove) | Recoil | Decision |
|---|---|---|---|
| aquaryn | 7.29 | 6.95 | OFF (the recoil reads as idle: hit PRESENT x3) |
| tidecoil | 7.04 | 6.67 | OFF |
| water_aquaryn | 7.01 | 6.76 | OFF |
| water_tidecoil | 6.92 | 6.64 | OFF |

The shove stays.

What the judges still ask for:
- Aquaryn and Tidecoil: the shove's hind feet leave the stage at the peak; the swim still strides under the plane; the Tidecoil faint is a rigid straight log, and its coil passes through the ruler.
- Material: a glossy, saturated cyan that loses the board's white belly and navy value break.

Next candidates:
- the swim stroke (legs folded, body at the waterline);
- a curled Tidecoil faint;
- a material value break, which is likely new art.

Raw scores: raw_scores.json. Mapping: mapped.json. Codes: key.json.
