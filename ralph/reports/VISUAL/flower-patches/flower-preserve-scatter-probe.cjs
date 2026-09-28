'use strict';
// CPU-only scalar reproduction of the reviewed Ridgeline transition.
// This does not execute the shader, sample its noise, or establish visual quality.
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const smooth = (a, b, v) => { const t = clamp((v-a)/(b-a), 0, 1); return t*t*(3-2*t); };
const mix = (a,b,t) => a*(1-t)+b*t;
const local = {item_size:.74,size_jitter:.3,density_gain:.85,drift_scale:.04,drift_contrast:.93};
const regional = {item_size:.52,size_jitter:.45,density_gain:1.4,drift_scale:.07,drift_contrast:1};
const samples = [0,71.9,72,80,88,100].map(distance => {
  const weight=smooth(72,88,distance);
  return {distance,weight,values:Object.fromEntries(Object.keys(local).map(k=>[k,mix(local[k],regional[k],weight)])),offset:[21.7*weight,37.3*weight],threshold_mix:weight};
});
// On a radial X traversal centred on (-250,6518), Z stays 6518.
// Noise-Z = 6518*(.04+.03*weight) + 37.3*weight.
const noiseZ = distance => 6518*mix(.04,.07,smooth(72,88,distance))+37.3*smooth(72,88,distance);
const epsilon=.0001;
const result={samples,noise_z_sweep:noiseZ(88)-noiseZ(72),mid_annulus_noise_z_derivative:(noiseZ(80+epsilon)-noiseZ(80-epsilon))/(2*epsilon),camera_independent_inputs:['world cell centre','authored zone'],scope:'Scalar transition math only; prior hash probe does not validate this spatial blend'};
console.log(JSON.stringify(result,null,2));
if(samples[2].weight!==0||samples[4].weight!==1||Math.abs(result.noise_z_sweep-232.84)>1e-8)process.exitCode=1;
