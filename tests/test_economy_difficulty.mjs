import test from 'node:test';
import assert from 'node:assert/strict';
import {scoreC2,bandCoverage,chapterMasherLoss} from '../tools/economy_difficulty.mjs';

const samples=()=>Array.from({length:24},(_,seed)=>[
  {pilot:'READER',seed,won:true,lead_fainted:false,lead_lost_frac:0.1,party_lost_frac:0.1},
  {pilot:'MASHER',seed,won:true,lead_fainted:false,lead_lost_frac:0.2,party_lost_frac:0.2}]).flat();
test('C2 compares paired seeds and real distributions, never promotes proof',()=>{
  assert.equal(scoreC2(samples()).arithmetic_pass,true);
  assert.equal(scoreC2(samples()).acceptance_verified,false);
  assert.equal(scoreC2(samples().slice(2)).arithmetic_pass,false);
  assert.equal(scoreC2([...samples(),samples()[0]]).arithmetic_pass,false);
  const unpaired=samples();unpaired[0].seed=99;
  assert.equal(scoreC2(unpaired).arithmetic_pass,false);
  const bad=samples();bad[0].fixture_error='missing actual producer';
  assert.equal(scoreC2(bad).arithmetic_pass,false);
});
test('top trainers require lead faint every masher seed and party ratio',()=>{
  assert.equal(scoreC2(samples(),{topTrainer:true}).arithmetic_pass,false);
  const top=samples().map(r=>r.pilot==='MASHER'?{...r,lead_fainted:true,party_lost_frac:0.6}:r);
  assert.equal(scoreC2(top,{topTrainer:true}).arithmetic_pass,true);
});
test('one starter cannot fill all three coverage cells',()=>{
  const result=bandCoverage({runs:samples().map(r=>({...r,band:'meadows/b1',starter:'terrapup'}))},[{biome:'meadows',band:'b1'}]);
  assert.equal(result.cells.length,3);
  assert.equal(result.arithmetic_all_bands,false);
});
test('chapter independent-fight loss uses the owning contract',()=>{
  assert.ok(Math.abs(chapterMasherLoss([{win_rate:0.8},{win_rate:0.8}]).loss_probability-0.36)<1e-10);
  assert.equal(chapterMasherLoss([{win_rate:1}]).arithmetic_pass,false);
});
