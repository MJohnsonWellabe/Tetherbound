import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {sourceReport} from './economy_ledger.mjs';

const STARTERS=['terrapup','ripplet','galewisp'];
const median=values=>{const v=[...values].sort((a,b)=>a-b),m=Math.floor(v.length/2);return v.length%2?v[m]:(v[m-1]+v[m])/2;};
const fraction=n=>typeof n==='number'&&Number.isFinite(n)&&n>=0&&n<=1;

// Consumes actual F22 pilot fields; never substitutes a damage simulation.
export function scoreC2(runs,{minimumSeeds=24,topTrainer=false,tutorialWild=false}={}) {
  const reasons=[],byPolicy={READER:[],MASHER:[]};
  for(const row of runs) {
    if(!(row.pilot in byPolicy)) continue;
    if(!Number.isSafeInteger(row.seed)||typeof row.won!=='boolean'||typeof row.lead_fainted!=='boolean'
      || !fraction(row.lead_lost_frac)||!fraction(row.party_lost_frac)||row.fixture_error||row.stalled) {
      reasons.push('invalid or stalled production pilot sample');continue;
    }
    byPolicy[row.pilot].push(row);
  }
  const stats={};
  for(const [policy,rows]of Object.entries(byPolicy)) {
    const seeds=new Set(rows.map(r=>r.seed));
    if(rows.length<minimumSeeds||rows.length!==seeds.size) reasons.push(`${policy}: missing or duplicated seeds`);
    stats[policy]=rows.length?{seeds:[...seeds].sort((a,b)=>a-b),runs:rows.length,
      win_rate:rows.filter(r=>r.won).length/rows.length,
      lead_faint_rate:rows.filter(r=>r.lead_fainted).length/rows.length,
      median_lead_cost:median(rows.map(r=>r.lead_lost_frac)),median_party_cost:median(rows.map(r=>r.party_lost_frac))}:null;
  }
  const reader=stats.READER,masher=stats.MASHER;
  if(reader&&masher) {
    if(JSON.stringify(reader.seeds)!==JSON.stringify(masher.seeds)) reasons.push('reader/masher seeds differ');
    if(reader.win_rate<(topTrainer?0.75:0.9)) reasons.push('reader win floor');
    const metric=topTrainer?'median_party_cost':'median_lead_cost';
    if(reader[metric]>masher[metric]*0.55) reasons.push('reader HP cost exceeds 55% of masher');
    if(topTrainer&&masher.lead_faint_rate!==1) reasons.push('top trainer must faint masher lead every run');
    if(!topTrainer&&!tutorialWild&&(masher.win_rate<0.9||masher.median_lead_cost<0.15||masher.median_lead_cost>0.30)) reasons.push('ordinary wild masher win/cost floor');
  }
  return {arithmetic_pass:reasons.length===0,reasons,stats,acceptance_verified:false};
}

export function bandCoverage(report,expectedBands) {
  const cells=[];
  for(const band of expectedBands) for(const starter of STARTERS) {
    const id=`${band.biome}/${band.band}`;
    // Meadows F22 ids are the raw region ids; other chapters prefix the biome.
    const matching=(report.runs??[]).filter(r=>(r.band===id||r.band===band.band)&&r.starter===starter);
    const score=scoreC2(matching,{tutorialWild:band.band==='band1_lower_meadows'});
    cells.push({biome:band.biome,band:band.band,starter,...score});
  }
  return {cells,arithmetic_all_bands:cells.every(c=>c.arithmetic_pass),
    acceptance_verified:false,
    producer_acceptance:report.acceptance===true,
    policy_scope:report.policy_scope??'unavailable',
    status:'C2 arithmetic only. F22 flat-fixture diagnostics disclose incomplete F23/F24 policy; ordinary-world footage/authority and gear pairs remain required.'};
}

export function chapterMasherLoss(fights) {
  if(!Array.isArray(fights)||!fights.length||fights.some(f=>!fraction(f.win_rate))) throw Error('Missing fight win rates');
  // Exact owning COMBAT contract: 1-product(rate), independent-fight estimate.
  const loss=1-fights.reduce((p,f)=>p*f.win_rate,1);
  return {loss_probability:loss,arithmetic_pass:loss>=0.25,
    scope:'per-starter independent-fight estimate; not an observed continuous playthrough',acceptance_verified:false};
}

if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  const args=process.argv.slice(2),input=args[args.indexOf('--input')+1],out=args[args.indexOf('--out')+1];
  if(!args.includes('--input')||!args.includes('--out')||!input||!out) throw Error('--input and --out required');
  const bytes=fs.readFileSync(input),source=sourceReport();
  const result=bandCoverage(JSON.parse(bytes),source.bands);
  result.input_sha256=crypto.createHash('sha256').update(bytes).digest('hex');
  result.source_manifest=source.manifest;
  fs.writeFileSync(out,JSON.stringify(result,null,2)+'\n');
  if(!result.arithmetic_all_bands) process.exitCode=1;
}
