import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';

// Read-only F47 arithmetic. Source quantities are candidates, never earned receipts.
export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const integer = n => Number.isSafeInteger(n) && n >= 0;
// Validate the materialized F19 values or the retained original authoring input.
// Repeat application is idempotent; this arithmetic never mutates game state.
export function authoredCurve(base, policy) {
  const object = v => v !== null && typeof v === 'object' && !Array.isArray(v);
  const level = v => Number.isInteger(v) && v >= 1 && v <= 100;
  const slot = (root, tokens) => {
    if (!Array.isArray(tokens) || !tokens.length || tokens.length > 16) throw Error('Invalid overlay path');
    let parent = root;
    for (let i=0;i<tokens.length;i++) {
      const key = tokens[i];
      if (!(object(parent) && typeof key === 'string') &&
          !(Array.isArray(parent) && integer(key) && key < parent.length)) throw Error('Invalid overlay slot');
      const exists = Object.hasOwn(parent,key);
      if (i === tokens.length-1) return {parent,key,exists,value:exists?parent[key]:null};
      if (!exists) throw Error('Missing overlay parent');
      parent = parent[key];
    }
  };
  if (!object(base) || !object(policy) || policy.schema_version !== 1 ||
      typeof policy.runtime_enabled !== 'boolean' || !object(policy.biomes)) throw Error('Invalid authored curve');
  const rows=policy.overlays?.['data/config/chapter_curve.json'];
  if (!Array.isArray(rows)) throw Error('Missing authored curve overlay');
  const seen=new Set();
  for (const row of rows) {
    if (!object(row) || !Array.isArray(row.at) || !Array.isArray(row.anchors) ||
        !Object.hasOwn(row,'legacy') || !level(row.value)) throw Error('Invalid level overlay');
    const words=row.at.filter(t=>typeof t==='string');
    const last=words.at(-1);
    if (row.at.some(t=>typeof t!=='string'&&!integer(t)) ||
        !(['level','ace_level','level_ceiling','warden_level','wild_band','trainer_levels','level_range','level_band'].includes(last) ||
          (['enter','exit'].includes(last)&&words.at(-2)==='team'))) throw Error('Not a level overlay');
    const key=JSON.stringify(row.at);
    if (seen.has(key)) throw Error('Duplicate level overlay');
    seen.add(key);
    for (const anchor of row.anchors) {
      if (!object(anchor)||!Object.hasOwn(anchor,'value')) throw Error('Invalid overlay anchor');
      const found=slot(base,anchor.at);
      if (!found.exists || JSON.stringify(found.value)!==JSON.stringify(anchor.value)) throw Error('Stale overlay identity');
    }
    const old=slot(base,row.at);
    if (row.legacy===null ? !object(old.parent) || (old.exists && old.value!==row.value) :
        !level(row.legacy)||!old.exists||!level(old.value)||(old.value!==row.legacy&&old.value!==row.value)) throw Error('Stale overlay level');
  }
  const next=structuredClone(base);
  for (const row of rows) {const target=slot(next,row.at);target.parent[target.key]=row.value;}
  next.biomes=structuredClone(policy.biomes);
  return next;
}
export function stock(raw) {
  const out = {};
  const rows = Array.isArray(raw) ? raw : Object.entries(raw).map(([id,n]) => ({id,n}));
  for (const row of rows) {
    if (!row || typeof row.id !== 'string' || !row.id || !integer(row.n)) throw Error('Invalid stock');
    out[row.id] = (out[row.id] ?? 0) + row.n;
    if (!integer(out[row.id])) throw Error('Stock overflow');
  }
  return out;
}
export function add(to, from, count = 1) {
  if (!integer(count)) throw Error('Invalid multiplier');
  for (const [id,n] of Object.entries(stock(from))) {
    to[id] = (to[id] ?? 0) + n * count;
    if (!integer(to[id])) throw Error('Stock overflow');
  }
  return to;
}
export function contention(personal, shared, characters) {
  if (!Number.isInteger(characters) || characters < 1 || characters > 4) throw Error('1–4 characters required');
  return add(add({}, personal, characters), shared);
}
// Deterministic stock equation for an explicitly supplied route scenario.
// Producer provenance/reachability is an independent runtime obligation.
export function routeBudget({starting,guaranteed,purchases,required,consumption,coins,vendorGoods}) {
  const available=add(add({},starting),guaranteed);
  if(!integer(coins)) throw Error('Invalid coins');
  let remainingCoins=coins;
  for(const [id,n] of Object.entries(stock(purchases))) {
    const row=vendorGoods[id];
    if(!row || !integer(row.buy) || row.buy<1 || !integer(row.stock) || n>row.stock) throw Error(`Unavailable vendor stock ${id}`);
    const cost=row.buy*n;
    if(!integer(cost)||cost>remainingCoins) throw Error(`Unaffordable purchase ${id}`);
    remainingCoins-=cost;add(available,{[id]:n});
  }
  const spending=add(add({},required),consumption),ending={},deficits={};
  for(const id of new Set([...Object.keys(available),...Object.keys(spending)])) {
    ending[id]=(available[id]??0)-(spending[id]??0);
    if(ending[id]<0) deficits[id]=-ending[id];
  }
  return {available,spending,ending,deficits,remaining_coins:remainingCoins,
    arithmetic_solvent:Object.keys(deficits).length===0,acceptance_verified:false};
}

export function recipeAudit(recipes,vendors) {
  const prices={};
  for(const row of Object.values(vendors)) for(const [id,g] of Object.entries(row.goods??{})) {
    const p=prices[id]??={buy:Infinity,sell:0};
    if(g.buy>0&&g.stock>0) p.buy=Math.min(p.buy,g.buy);
    p.sell=Math.max(p.sell,g.sell);
  }
  const profitable=[];
  for(const [id,r] of Object.entries(recipes)) {
    const cost=stock(r.cost);
    if(!r.output || !integer(r.output.n) || r.output.n<1) throw Error(`Invalid recipe output ${id}`);
    const purchaseCost=Object.entries(cost).reduce((sum,[item,n])=>sum+(prices[item]?.buy??Infinity)*n,0);
    const sellReturn=(prices[r.output.id]?.sell??0)*r.output.n;
    if(Number.isFinite(purchaseCost)&&sellReturn>purchaseCost) profitable.push({recipe:id,purchase_cost:purchaseCost,sell_return:sellReturn});
  }
  return {scope:'single craft edges using stocked vendor inputs; conditional availability and multi-recipe cycles still need runtime proof',profitable};
}
export function observedRate(before,after,elapsedMs) {
  if(!Number.isSafeInteger(elapsedMs)||elapsedMs<=0) throw Error('Positive measured interval required');
  const a=stock(before),b=stock(after),rate={};
  for(const id of new Set([...Object.keys(a),...Object.keys(b)])) rate[id]=((b[id]??0)-(a[id]??0))*3600000/elapsedMs;
  return {net_stock_per_hour:rate,elapsed_ms:elapsedMs,
    scope:'observed net stock, including spending/loss; no guessed gross producer yield or catch success',acceptance_verified:false};
}
export function expandRefining(required, recipes, active = []) {
  const result = {};
  for (const [id,n] of Object.entries(stock(required))) {
    const recipe = recipes[id];
    if (!recipe || n === 0) { add(result, {[id]:n}); continue; }
    if (active.includes(id)) throw Error(`Refining cycle: ${[...active,id].join(' -> ')}`);
    if (recipe.output.id !== id || !integer(recipe.output.n) || recipe.output.n < 1) throw Error(`Invalid output: ${id}`);
    add(result, expandRefining(add({},recipe.cost,Math.ceil(n/recipe.output.n)),recipes,[...active,id]));
  }
  return result;
}
export function levelCost(level, essence, progression) {
  const bands = essence.level_cost_bands.filter(b => level >= b.minimum_level && level <= b.maximum_level);
  if (bands.length !== 1 || !Number.isInteger(level) || level < 1 || level > 59) throw Error('Invalid level band');
  const {xp_to_next_base:base,xp_to_next_exponent:exponent} = progression.level;
  if (![base,exponent,essence.essence_xp_value,bands[0].multiplier].every(v=>Number.isFinite(v)&&v>0)) throw Error('Invalid XP curve');
  return Math.ceil(Math.floor(base * Math.max(level,1) ** exponent) / essence.essence_xp_value * bands[0].multiplier);
}
export function tradeAudit(vendors) {
  const prices = {};
  const forbidden = [];
  for (const [vendor,row] of Object.entries(vendors)) for (const [item,goods] of Object.entries(row.goods ?? {})) {
    if (![goods.buy,goods.sell,goods.stock].every(integer)) throw Error(`Invalid trade row ${vendor}/${item}`);
    const price = prices[item] ??= {buys:[],sells:[]};
    if (goods.buy > 0 && goods.stock > 0) price.buys.push({vendor,price:goods.buy});
    price.sells.push({vendor,price:goods.sell});
    if (goods.stock > 0 && (item.startsWith('essence_') || item==='tether_candy' || item.includes('elixir'))) forbidden.push({vendor,item});
  }
  const profitable = [];
  for (const [item,row] of Object.entries(prices)) for (const buy of row.buys) for (const sell of row.sells)
    if (sell.price > buy.price) profitable.push({item,buy,sell,profit:sell.price-buy.price});
  return {scope:'authored vendor prices; restock/runtime receipt semantics unverified',profitable,forbidden};
}

export function sourceReport(root = ROOT) {
  const manifest = [];
  const source = p => {
    const bytes = fs.readFileSync(path.join(root,p));
    manifest.push({path:p,sha256:digest(bytes)});
    return bytes.toString();
  };
  const read = p => {
    return JSON.parse(source(p));
  };
  const order = read('data/config/biome_order.json');
  const liveCurve = read('data/config/chapter_curve.json');
  const curvePolicy = read('data/config/redesign_level_curve.json');
  source('scripts/creatures/level_curve_policy.gd');
  const curve = authoredCurve(liveCurve,curvePolicy);
  const essence = read('data/config/essence.json');
  const progression = read('data/config/progression.json');
  const types = read('data/config/type_chart.json').types;
  const gear = read('data/config/gear.json');
  const feasts = read('data/recipes/feasts.json');
  const forge = read('data/recipes/recipes_forge.json');
  const stations = read('data/config/stations.json');
  const camp = read('data/config/forward_camps.json');
  const masters = read('data/config/masters.json');
  const nodes = read('data/config/essence_nodes.json');
  const bounties = read('data/config/bounties.json');
  const rematches = read('data/config/rematches.json');
  const alphas = read('data/config/alpha_respawns.json');
  const trade = read('data/config/trade.json');
  const buildables = read('data/items/buildables.json');
  const basicRecipes = read('data/recipes/recipes.json');
  const rematchSource=source('scripts/repeatables/rematch_rules.gd');
  source('scripts/creatures/essence.gd');
  source('scripts/creatures/progression.gd');
  source('scripts/world/bounty_board.gd');
  source('autoload/inventory.gd');
  source('autoload/party.gd');
  source('scripts/net/session.gd');
  const findings=[];
  if(rematchSource.includes('context.world_namespace + ":" + intent.trainer_id + ":" + intent.tier') &&
    rematchSource.includes('cooldowns.get(key, {})') && rematchSource.includes('last.get("next_eligible_seconds", 0)')) {
    // These are source markers, not an executed two-world payout proof.
    const foreignClockGuard=rematchSource.includes('foreign_paid_clock = true') &&
      rematchSource.includes('not foreign_paid_clock and int(context.world_seconds)');
    findings.push({kind:foreignClockGuard?'rematch_world_hop_clock_unverified':'rematch_world_hop_cooldown_bypass',
      path:'scripts/repeatables/rematch_rules.gd',
      source_fact:foreignClockGuard?'existing stage retains foreign paid clocks and forbids a repeat payout from the destination clock':
        'cooldown key includes world namespace; absent destination cooldown defaults eligibility time to zero',
      dependency:foreignClockGuard?'F44/F47 actual two-world original outcome, owner-save ACK and return-to-owning-clock proof':
        'F44/ROOT must supply a portable cycle entitlement/reanchor policy and same-record owner-save ACK; no comparable global clock currently supplied',
      status:foreignClockGuard?'OPEN: source guard present; source markers alone do not verify production behavior':
        'OPEN: source branch reachable; actual two-world production proof deferred; receipt budget bounds total retained history, not the intended cycle'});
  }
  const lastMeadows=curve.regions.at(-1).team.exit;
  if(lastMeadows!==curve.biomes.meadows.team[1]) findings.push({kind:'meadows_exit_target_disagreement',
    path:'data/config/chapter_curve.json',regional_exit:lastMeadows,biome_exit:curve.biomes.meadows.team[1],
    status:'F19 owns curve consistency; no speculative reward tuning'});
  const errors = [];
  for (let level=1;level<60;level++) levelCost(level,essence,progression);
  const bands = [];
  for (const biome of order.live) {
    const regions = biome==='meadows' ? curve.regions.map(r=>({region_id:r.id,team:[r.team.enter,r.team.exit]})) : curve.biomes[biome].regional_targets;
    for (const region of regions) {
      const [entry,exit] = region.team;
      let perCreature = 0;
      for (let level=entry;level<exit;level++) perCreature += levelCost(level,essence,progression);
      bands.push({biome,band:region.region_id,optional:region.optional===true,entry,exit,
        essence_only_upper_cost_per_creature:perCreature,
        homogeneous_five_by_type:Object.fromEntries(types.map(t=>[t,perCreature*5])),
        guaranteed_main_path_supply:null,auto_xp_credit:null,candy_credit:null,
        status:'UNAVAILABLE: earned route, type allocation, actual caps and committed awards required'});
    }
  }
  // A homogeneous five for each type discloses contention without assuming a team.
  const materials = [];
  for (const biome of order.live) for (const type of types) for (let upgrade=0;upgrade<=gear.max_upgrade;upgrade++) {
    const tier = gear.tiers.find(t=>t.biome===biome&&t.status==='live');
    if (!tier) throw Error(`Missing gear tier ${biome}`);
    const personal = {}, shared = {};
    const components = [];
    const charge = (id,cost,count,scope) => {add(scope==='personal'?personal:shared,cost,count);components.push({id,count,scope,cost:stock(cost)});};
    for (const master of masters.masters.filter(m=>m.biome===biome)) {
      const id = `${master.feast_id}_${type}`;
      const recipe = feasts.recipes[id];
      if (!recipe) throw Error(`Missing feast ${id}`);
      charge(id,recipe.cost,5,'personal');
    }
    for (const slot of ['harness','charm']) {
      const id = Object.keys(gear.items).find(id=>gear.items[id].gear_tier===tier.tier&&gear.items[id].gear_slot===slot&&gear.items[id].gear_upgrade===0);
      const recipe = Object.values(gear.recipes).find(r=>r.output.id===id);
      if (!recipe) throw Error(`Missing ${biome} ${slot}`);
      charge(id,recipe.cost,5,'personal');
      let current=id;
      for(let step=1;step<=upgrade;step++) {
        const next = gear.upgrades[current];
        if (!next) throw Error(`Missing upgrade ${current}`);
        charge(next.output,next.inputs,5,'personal');current=next.output;
      }
    }
    for (const attachment of stations.attachments.filter(a=>a.biome===biome&&a.status==='live')) charge(attachment.id,attachment.cost,1,'shared');
    if(biome===order.live[0]) {
      // Structures are one world allocation even with four visiting characters.
      for(const station of stations.stations) {
        const row=[...buildables.buildables,...buildables.homestead_buildables].find(b=>b.id===station.id);
        if(!row) throw Error(`Missing station buildable ${station.id}`);
        charge(row.id,row.cost,1,'shared');
      }
      // Preserves the authored tutorial camp and tournament's two creature beds.
      for(const [id,count] of [['tent',1],['campfire',1],['bedroll',1],['creature_bed',2]]) {
        const row=buildables.buildables.find(b=>b.id===id);
        if(!row) throw Error(`Missing opening buildable ${id}`);
        charge(id,row.cost,count,'shared');
      }
    }
    // A separately carried camp kit per character, not four copies of a shared attachment.
    charge('forward_camp_kit',camp.recipes.forward_camp_kit.cost,1,'personal');
    const solo = expandRefining(contention(personal,shared,1),forge.recipes);
    const four = expandRefining(contention(personal,shared,4),forge.recipes);
    materials.push({biome,type,upgrade,components,personal,shared,solo_raw:solo,
      solo_supply_margin_150_percent:Object.fromEntries(Object.entries(solo).map(([id,n])=>[id,Math.ceil(n*1.5)])),
      four_character_raw:four,reachable_supply:null,observed_two_loss_consumption:null,
      status:'UNAVAILABLE: on-route harvest claims and loss/recovery consumption not measured'});
  }
  const authoredNodes = nodes.nodes.map(n=>({id:n.id,biome:n.realm,band:n.region_id,type:n.type,outputs:n.outputs,
    respawn_days:n.respawn_days,placement_proven:n.placement?.terrain_and_player_path_proven===true,
    guaranteed_on_route:false}));
  for(const n of authoredNodes) if(!Number.isInteger(n.respawn_days)||n.respawn_days<1) errors.push(`Invalid node cycle ${n.id}`);
  const tradeResult = tradeAudit(trade.vendors);
  const craftResult = recipeAudit({...basicRecipes.recipes,...forge.recipes,...gear.recipes,...camp.recipes},trade.vendors);
  if(tradeResult.profitable.length) errors.push('Profitable authored buy/resell edges');
  if(tradeResult.forbidden.length) errors.push('Forbidden progression goods for sale');
  if(craftResult.profitable.length) errors.push('Profitable vendor/craft/resell edges');
  if(!Number.isInteger(rematches.repeat_days)||rematches.repeat_days<1||!Number.isFinite(rematches.day_seconds)||rematches.day_seconds<=0) errors.push('Invalid rematch cycle');
  if(!Number.isInteger(alphas.respawn_days)||alphas.respawn_days<1||!Number.isFinite(alphas.day_seconds)||alphas.day_seconds<=0) errors.push('Invalid alpha cycle');
  if(bounties.board_count!==3||bounties.world_hop_policy!=='reanchor_without_rotation') errors.push('Invalid bounty rotation/world-hop contract');
  if(!integer(essence.care_daily_character_cap)) errors.push('Invalid care cap');
  const missing = ['scripts/creatures/research_log.gd','data/config/research.json'].filter(p=>!fs.existsSync(path.join(root,p)));
  const flags = {essence:{xp_mode:essence.wild_victory_xp_mode,altar:essence.altar_runtime_enabled,wild:essence.wild_victory_runtime_enabled},
    gear:gear.feature_flags,stations:stations.runtime_enabled,camp:camp.runtime_enabled,bounties:bounties.runtime_enabled,
    rematches:rematches.runtime_enabled,alphas:alphas.runtime_enabled,level_curve:curvePolicy.runtime_enabled};
  return {schema_version:1,evidence_scope:'source-generated arithmetic; not an earned clear or acceptance verdict',
    manifest,errors,findings,bands,materials,authoredNodes,flags,missing_producers:missing,
    level_curve:{basis:'validated materialized F19 production data; earned-route solvency remains unproved',
      live_meadows_exit:liveCurve.regions.at(-1).team.exit,authored_meadows_exit:curve.regions.at(-1).team.exit},
    economy_exploits:{trade:tradeResult,craft:craftResult,
      rest:'UNAVAILABLE: earned-day receipt and reload/world-hop witness required',
      release:{once_per:'creature uid',base:essence.release_essence_base,per_level:essence.release_essence_per_level,
        optional_rate_per_hour:null,orb_cost:trade.vendors.mira.goods.orb_basic.buy,status:'UNAVAILABLE: catch success, elapsed time and immutable owner receipt required'},
      bounties:{count:bounties.board_count,morning_policy:bounties.morning_policy,world_hop_policy:bounties.world_hop_policy,status:'UNAVAILABLE: same-day/reload/world-hop real path proof'},
      rematches:{repeat_days:rematches.repeat_days,day_seconds:rematches.day_seconds,status:'UNAVAILABLE: elapsed-cycle/replay proof'},
      alphas:{config:alphas,status:'UNAVAILABLE: host respawn clock/reconnect proof'}},
    duration:{target_hours:[15,25],measured_hours:null,agent_piloted:false,owner_confirmed:false},
    difficulty:{bands:bands.map(({biome,band,entry,optional})=>({biome,band,entry,optional})),
      starters:['terrapup','ripplet','galewisp'],seeds_per_starter:24,status:'UNRUN: production C2 samples required'},
    limitations:['No guaranteed supply inferred from node coordinates or stock declarations.',
      'Level costs are an essence-only upper bound, without invented auto-XP or candy credits.',
      'Material costs include station base builds, tutorial camp and two creature beds once in Meadows; opening gifts, tools, greenhouse and unmeasured recovery require route observations.',
      'All upgrade scenarios shown; boss-required upgrade has not been measured.']};
}

// Observations are live serializer snapshots, never substitutes for owner-save ACK proof.
export function analyzeTrace(rows) {
  const sessions = new Map();
  for (const row of rows) {
    if(row.schema_version!==1 || typeof row.run_id!=='string' || !row.run_id || !integer(row.elapsed_ms)) throw Error('Invalid observation');
    const run = sessions.get(row.run_id) ?? {last_ms:0,characters:new Map(),events:[],finished:false,starts:new Map(),rates:[]};
    sessions.set(row.run_id,run);
    if(row.elapsed_ms<run.last_ms || run.finished) throw Error('Out-of-order or post-close observation');
    run.last_ms=row.elapsed_ms;
    if(row.kind==='snapshot') {
      if(typeof row.character_id!=='string'||!row.character_id) throw Error('Missing character identity');
      const current = stock(row.stock);
      const previous = run.characters.get(row.character_id);
      const delta={};
      if(previous) for(const id of new Set([...Object.keys(previous.stock),...Object.keys(current)])) {
        const n=(current[id]??0)-(previous.stock[id]??0);if(n) delta[id]=n;
      }
      run.events.push({elapsed_ms:row.elapsed_ms,character_id:row.character_id,biome:row.biome,band:row.band,
        stock:current,delta,party:row.party,receipts_sha256:row.receipts_sha256,
        scope:'observed net state; neither gross reward/consumption nor durable ACK attribution'});
      run.characters.set(row.character_id,{stock:current});
    } else if(row.kind==='stop') run.finished=true;
    else {
      // Capture operators bracket loops after explicit sample() calls; annotations
      // do not establish ordinary-route eligibility, durable awards or ownership.
      if(row.kind==='annotation'&&['optional_begin','optional_end'].includes(row.label)) {
        const character=row.detail;
        const current=run.characters.get(character);
        if(!current) throw Error('Optional marker has no character observation');
        if(row.label==='optional_begin') {
          if(run.starts.has(character)) throw Error('Overlapping optional interval');
          run.starts.set(character,{stock:current.stock,elapsed_ms:row.elapsed_ms});
        } else {
          const begin=run.starts.get(character);
          if(!begin) throw Error('Optional interval not started');
          run.rates.push({character_id:character,...observedRate(begin.stock,current.stock,row.elapsed_ms-begin.elapsed_ms)});
          run.starts.delete(character);
        }
      }
      run.events.push(row);
    }
  }
  return [...sessions].map(([run_id,run])=>({run_id,elapsed_hours:run.last_ms/3600000,closed:run.finished,
    observed_characters:run.characters.size,events:run.events,
    normal_clear_verified:false,owner_confirmed:false,durable_transactions_verified:false,
    optional_observed_rates:run.rates,incomplete_optional_intervals:[...run.starts.keys()],
    status:'Observations only; route coverage, shortcuts, losses and gross producers require review'}));
}

if(process.argv[1] && path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  const args=process.argv.slice(2);
  const value=name=>{const i=args.indexOf(name);if(i<0)return null;if(!args[i+1]||args[i+1].startsWith('--'))throw Error(`Missing ${name}`);return args[i+1];};
  const report=sourceReport(value('--root')??ROOT);
  const trace=value('--trace');
  if(trace) {const bytes=fs.readFileSync(trace);report.trace_sha256=digest(bytes);report.observations=analyzeTrace(bytes.toString().split(/\r?\n/).filter(Boolean).map(JSON.parse));}
  const out=value('--out');
  const json=JSON.stringify(report,null,2)+'\n';
  if(out) fs.writeFileSync(out,json);else process.stdout.write(json);
  if(report.errors.length) process.exitCode=1;
}
