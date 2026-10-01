import test from 'node:test';
import assert from 'node:assert/strict';
import {stock,contention,expandRefining,levelCost,tradeAudit,recipeAudit,routeBudget,observedRate,sourceReport,analyzeTrace,authoredCurve} from '../tools/economy_ledger.mjs';

test('candidate costs use F19 overlay while preserving live legacy levels and gates',()=>{
  const report=sourceReport();
  assert.equal(report.level_curve.legacy_meadows_exit,21);
  assert.equal(report.level_curve.authored_meadows_exit,22);
  assert.equal(report.flags.level_curve,false);
  assert.equal(report.bands.filter(b=>b.biome==='meadows').at(-1).exit,22);
  assert.ok(!report.findings.some(f=>f.kind==='meadows_exit_target_disagreement'));
});

test('stale original identity or level refuses candidate arithmetic without mutation',()=>{
  const base={regions:[{id:'one',team:{exit:21}}]};
  const row={at:['regions',0,'team','exit'],anchors:[{at:['regions',0,'id'],value:'one'}],legacy:21,value:22};
  const policy={schema_version:1,runtime_enabled:false,biomes:{},overlays:{'data/config/chapter_curve.json':[row]}};
  assert.equal(authoredCurve(base,policy).regions[0].team.exit,22);
  assert.equal(base.regions[0].team.exit,21);
  assert.equal(policy.runtime_enabled,false);
  assert.throws(()=>authoredCurve({...base,regions:[{id:'two',team:{exit:21}}]},policy),/identity/);
  assert.throws(()=>authoredCurve({...base,regions:[{id:'one',team:{exit:20}}]},policy),/level/);
  assert.throws(()=>authoredCurve(base,{...policy,overlays:{'data/config/chapter_curve.json':[row,row]}}),/Duplicate/);
});

test('four personal kits consume four allocations, shared buildings one',()=>{
  assert.deepEqual(contention({ingot:5,feast:5},{ingot:2},4),{ingot:22,feast:20});
  assert.throws(()=>contention({}, {},5));
  assert.throws(()=>stock([{id:'wood',n:-1}]));
  assert.throws(()=>stock({wood:Number.MAX_SAFE_INTEGER+1}));
});
test('refining rounds whole batches and rejects circular minting dependencies',()=>{
  const recipes={ingot:{output:{id:'ingot',n:2},cost:{ore:3,fuel:1}}};
  assert.deepEqual(expandRefining({ingot:5},recipes),{ore:9,fuel:3});
  assert.throws(()=>expandRefining({a:1},{a:{output:{id:'a',n:1},cost:{b:1}},b:{output:{id:'b',n:1},cost:{a:1}}}),/cycle/);
});
test('cost floors XP before ceiling essence, refusing ambiguous bands',()=>{
  const e={essence_xp_value:25,level_cost_bands:[{minimum_level:1,maximum_level:60,multiplier:1}]};
  const p={level:{xp_to_next_base:40,xp_to_next_exponent:1.15}};
  assert.equal(levelCost(3,e,p),6);
  assert.throws(()=>levelCost(3,{...e,level_cost_bands:[...e.level_cost_bands,...e.level_cost_bands]},p));
});
test('buy/resell checks cross-vendor prices and forbidden stocked power items',()=>{
  const result=tradeAudit({a:{goods:{wood:{buy:2,sell:1,stock:1},essence_fire:{buy:5,sell:1,stock:1}}},b:{goods:{wood:{buy:9,sell:4,stock:0}}}});
  assert.equal(result.profitable[0].profit,2);
  assert.equal(result.forbidden[0].item,'essence_fire');
});
test('route stock subtracts recovery, spends real coins and refuses unavailable purchases',()=>{
  const scenario={starting:{wood:2},guaranteed:{wood:8},purchases:{potion:2},required:{wood:6},consumption:{wood:5,potion:2},coins:20,vendorGoods:{potion:{buy:5,stock:2}}};
  const result=routeBudget(scenario);
  assert.deepEqual(result.deficits,{wood:1});
  assert.equal(result.remaining_coins,10);
  assert.equal(result.arithmetic_solvent,false);
  assert.equal(result.acceptance_verified,false);
  assert.throws(()=>routeBudget({...scenario,coins:9}),/Unaffordable/);
  assert.throws(()=>routeBudget({...scenario,purchases:{potion:3}}),/stock/);
});
test('craft profit checks output batch quantity, refusing unpriced inputs as proof',()=>{
  const recipes={boards:{cost:{wood:1},output:{id:'board',n:3}}};
  assert.equal(recipeAudit(recipes,{a:{goods:{wood:{buy:2,sell:1,stock:1},board:{buy:9,sell:1,stock:0}}}}).profitable.length,1);
  assert.equal(recipeAudit(recipes,{a:{goods:{board:{buy:9,sell:1,stock:0}}}}).profitable.length,0);
});
test('observed reconnect duplicates mint no additional stock; runs stay separate',()=>{
  const row={schema_version:1,run_id:'a',kind:'snapshot',character_id:'one',elapsed_ms:1,stock:{wood:2}};
  const result=analyzeTrace([row,{...row,elapsed_ms:2},{...row,character_id:'two',elapsed_ms:3},
    {...row,run_id:'b',elapsed_ms:1},{schema_version:1,run_id:'a',kind:'stop',elapsed_ms:3600000}]);
  assert.deepEqual(result[0].events[1].delta,{});
  assert.equal(result[0].observed_characters,2);
  assert.equal(result[0].elapsed_hours,1);
  assert.equal(result[0].normal_clear_verified,false);
  assert.equal(result[0].durable_transactions_verified,false);
  assert.equal(result.length,2);
  assert.throws(()=>analyzeTrace([row,{...row,elapsed_ms:0}]),/order/);
});
test('optional rates preserve negative spending and require a measured positive interval',()=>{
  assert.deepEqual(observedRate({orb_basic:5,essence_ground:2},{orb_basic:3,essence_ground:7},1800000).net_stock_per_hour,{orb_basic:-4,essence_ground:10});
  assert.throws(()=>observedRate({}, {},0));
  const base={schema_version:1,run_id:'a'};
  const result=analyzeTrace([
    {...base,kind:'snapshot',elapsed_ms:0,character_id:'one',stock:{essence_ground:2}},
    {...base,kind:'annotation',elapsed_ms:0,label:'optional_begin',detail:'one'},
    {...base,kind:'snapshot',elapsed_ms:1800000,character_id:'one',stock:{essence_ground:7}},
    {...base,kind:'annotation',elapsed_ms:1800000,label:'optional_end',detail:'one'}]);
  assert.equal(result[0].optional_observed_rates[0].net_stock_per_hour.essence_ground,10);
});
test('authored five + two Meadows breakthroughs and one shared attachment set',()=>{
  const report=sourceReport();
  assert.deepEqual(report.errors,[]);
  assert.equal(report.bands.length,23);
  const ground=report.materials.find(r=>r.biome==='meadows'&&r.type==='ground'&&r.upgrade===0);
  assert.equal(ground.personal.attuned_ground,10);
  assert.equal(ground.personal.berries,50);
  assert.equal(ground.components.filter(c=>c.scope==='shared'&&c.id.startsWith('forge_')).length,1);
  assert.equal(ground.components.find(c=>c.id==='creature_bed').count,2);
  assert.equal(ground.four_character_raw.attuned_ground,40);
  assert.equal(ground.reachable_supply,null);
  assert.equal(report.duration.measured_hours,null);
  assert.equal(report.economy_exploits.release.optional_rate_per_hour,null);
});
