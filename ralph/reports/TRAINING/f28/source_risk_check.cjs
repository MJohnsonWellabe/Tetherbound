const fs=require('fs'),path=require('path'),crypto=require('crypto'); const root=process.cwd();const read=p=>JSON.parse(fs.readFileSync(p,'utf8'));const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');const out='ralph/reports/TRAINING/f28';fs.mkdirSync(out,{recursive:true});
// Before integration, pass the reviewed F32 checkout as argv[2]. After integration,
// omit it to inspect canonical files in this checkout. Never infer runtime stock.
const f32Root=path.resolve(process.argv[2]||root);
const dependency=read(out+'/attuned-source-contract.json');
const nodeFile='data/config/essence_nodes.json',farmFile='data/config/farm.json';
const nodes=read(path.join(f32Root,nodeFile)).nodes,farm=read(path.join(f32Root,farmFile));
const m=read('data/config/masters.json'), f=read('data/recipes/feasts.json'), core=read('data/items/items.json').items, water=read('data/config/water_crafting.json').item_registration_proposals;
const known={...core,...water,...f.items};const failures=[];let checks=0;function check(ok,msg){checks++;if(!ok)failures.push(msg)}
check(m.masters.length===5,'five masters');check(JSON.stringify(m.masters.map(x=>x.cap_level))==='[10,20,30,40,50]','live cap order');check(m.ceiling===60&&JSON.stringify(m.reserved_caps)==='[70,80,90,100]','ceiling and reserved data');check(new Set(m.masters.map(x=>x.humanoid_key)).size===5,'five installed cast identities');check(new Set(m.masters.map(x=>x.combat.pattern_id)).size===5,'distinct combat questions');const a=read('data/config/art.json');for(const r of m.masters){check(!!a[r.humanoid_key],'cast config '+r.id);check(fs.existsSync(r.scene.replace('res://','')),'scene '+r.id);check(r.participants===1&&r.combat.no_switch&&r.combat.no_flee&&!r.combat.trainer_damage&&!r.combat.catchable,'one-creature duel rules '+r.id)}
const sourceFiles=['data/config/bands/band1_lower_meadows/harvest.json','data/config/bands/band2_stone_and_root/harvest.json','data/config/bands/band4_upper_meadows_ironwood/harvest.json','data/config/water_pickups.json','data/config/cloudreach_chapter.json','data/config/stormwood_harvests.json','data/config/burrow_warrens.json','data/recipes/feasts.json'];const sources={};
function scan(o,p,file,biome){if(!o||typeof o!=='object')return;if(!Array.isArray(o)){const item=o.item||o.item_id||o.resource_id;if(typeof item==='string'&&(o.at||o.position||o.offset||o.chamber)) (sources[item]??=[]).push({file,json_path:p,biome,stable_id:o.id||o.order||o.flag||'',position:o.at||o.position||o.offset||[],amount:o.amount||o.yield||1,status:file.endsWith('feasts.json')?'owned_source_requires_typed_host_mount':'existing_authored_source_no_runtime_reproof'});}for(const [k,v]of Object.entries(o)){if(k.startsWith('_'))continue;scan(v,p+'.'+k,file,biome)}}
for(const file of sourceFiles){const biome=file.includes('water')?'tidewake':file.includes('cloudreach')?'cloudreach':file.includes('stormwood')?'stormwood':'meadows';scan(read(file),'$',file,biome)}
for(const file of [nodeFile,farmFile]) {
 const actual=fs.readFileSync(path.join(f32Root,file),'utf8').replace(/\r\n/g,'\n');
 check(crypto.createHash('sha256').update(actual).digest('hex')===dependency.files[file].git_content_sha256,'reviewed F32 source hash '+file);
}
const types=['ground','water','air','electric','fire','dark','ice','psychic'];
check(f.attuned_sources.enabled===false&&f.attuned_sources.nodes.length===0,'provisional finite garden retired');
check(nodes.length===32&&new Set(nodes.map(n=>n.id)).size===32,'32 unique canonical F32 nodes');
for(const realm of ['meadows','water','cloudreach','stormwood']) for(const type of types) {
 const rows=nodes.filter(n=>n.realm===realm&&n.type===type);
 check(rows.length===1,'one authored F32 node '+realm+'/'+type);
}
nodes.forEach((n,index)=>{
 const type=n.type,item='attuned_'+type,biome=n.realm==='water'?'tidewake':n.realm;
 check(types.includes(type)&&n.outputs[item]===1&&n.respawn_days===3,'typed renewable output '+n.id);
 check(n.seed_drop.item==='seed_'+type&&n.seed_drop.amount===1&&n.seed_drop.chance===0.25,'canonical seed chance '+n.id);
 (sources[item]??=[]).push({file:nodeFile,json_path:'$.nodes.'+index,biome,runtime_realm:n.realm,stable_id:n.id,position:n.at,amount:n.outputs[item],scope:'world_stock; character_outputs',respawn_host_days:n.respawn_days,seed_drop:n.seed_drop,status:'F32_REVIEWED_AUTHORED_SOURCE_NO_ACCEPTED_STOCK_OR_PATH_PROOF'});
});
for(const type of types) {
 const crop=farm.crops[type];
 check(crop.seed_item==='seed_'+type&&crop.grow_days===2&&crop.outputs['attuned_'+type]===2,'canonical crop '+type);
 const early=nodes.find(n=>n.realm==='meadows'&&n.type===type);
 check(!!early&&['band1_lower_meadows','band2_stone_and_root'].includes(early.region_id),'early Meadows candidate '+type);
}
sources.sunstone=[{file:'scripts/world/playground_world.gd',symbol:'SUNSTONE_AT / _spawn_sunstone',position:[121,7336],biome:'meadows',status:'existing_optional_stone_pickup_no_runtime_reproof'}];
const order=read('data/config/biome_order.json').live;const ledger=[];for(const [id,r]of Object.entries(f.recipes)){check(r.station_id==='kitchen'&&r.homestead_only&&r.station_tier===Math.max(1,r.tier-1),'Kitchen tier '+id);check(r.output[id]===1&&Object.keys(r.output).length===1,'one typed output '+id);check(f.items[id].attuned_type===r.attuned_type&&f.items[id].catalyst===r.catalyst,'immutable type/catalyst '+id);check(r.cost['attuned_'+r.attuned_type]===1,'exactly one matching ingredient '+id);const entries=[];for(const [item,n]of Object.entries(r.cost)){check(!!known[item]&&Number.isInteger(n)&&n>0,'catalogue ingredient '+id+'/'+item);const eligible=(sources[item]||[]).filter(x=>order.indexOf(x.biome)>=0&&order.indexOf(x.biome)<=order.indexOf(r.biome));check(eligible.length>0,'authored ingredient at or before biome '+id+'/'+item);const entry={item,count:n,catalogue:core[item]?'data/items/items.json':water[item]?'data/config/water_crafting.json':'data/recipes/feasts.json',source:eligible.find(x=>x.biome===r.biome)||eligible[0]||null};if(item.startsWith('attuned_')){const type=item.slice(8);entry.supplemental_crop={file:farmFile,json_path:'$.crops.'+type,biome:'meadows',seed_item:farm.crops[type].seed_item,seed_source_id:'essence_meadows_'+type+'_01',seed_chance:0.25,seed_guaranteed:false,grow_host_days:2,amount:2,growth_gate:farm.native_types.includes(type)?'native outdoor crop':'actual paid world Greenhouse',status:'NO_ACCEPTED_SEED_PLANT_OR_HARVEST_STOCK_PROOF'};}entries.push(entry);}ledger.push({recipe_id:id,biome:r.biome,breaks_level:r.tier*10,catalyst_optional:!!r.catalyst,ingredients:entries})}
if(failures.length){console.log(JSON.stringify({checks,failures}));process.exit(1);}
fs.writeFileSync(out+'/ingredient-ledger.json',JSON.stringify({status:'REVIEWED_SOURCE_REFERENCES_ONLY; RUNTIME_STOCK_UNPROVEN',claim:'All recipe inputs have authored sources in or before recipe biome. F32 canonical renewable nodes/crops exclusively provide attuned ingredients; actual mounted stock, terrain, seeds, supply and Kitchen integration remain unproven.',external_source:dependency,biome_order:order,recipes:ledger},null,2)+'\n');
fs.writeFileSync(out+'/source-risk-check.json',JSON.stringify({checks,failures,scope:'Authored JSON identity/catalogue/source/order checks only; no GDScript parse, engine, persistence or acceptance proof.'},null,2)+'\n');console.log(JSON.stringify({checks,failures}));if(failures.length)process.exitCode=1;
