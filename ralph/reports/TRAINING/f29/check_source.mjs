import {readFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';

// Cheap source/relation/risk check only. Never invokes Godot or asset imports.
const read = p => readFileSync(p, 'utf8');
const json = p => JSON.parse(read(p));
let checks = 0;
const check = (condition, name) => {checks++; if (!condition) throw Error(name);};
const config = json('data/config/evolution_lines.json');
const schemaDefaults = json('data/schema/evolution_lines.json');
check(JSON.stringify(config) === JSON.stringify(schemaDefaults), 'F16 exact authored line identities and enable flags');
const species = json('data/creatures/species.json').species;
const items = json('data/items/items.json').items;
for (const row of config) {
  check(!!species[row.source], `source exists: ${row.source}`);
  check(!!species[row.target] || (row.target === 'stormursa' && row.enabled === false), `target exists or authorized disabled bear: ${row.target}`);
  check(row.extra_ingredient === '' || !!items[row.extra_ingredient], `ingredient exists: ${row.id}`);
}
check(new Set(config.map(r => r.source)).size === 4, 'four source lines');
const evolution = read('scripts/creatures/evolution.gd');
const component = evolution.slice(evolution.indexOf('static func prepare_feast_choice'), evolution.indexOf('static func variant_branches'));
check(!/inventory\.call|\.remove\(|\.add_member\(|\.save_|mint_uid\(/.test(component), 'planner has no independent debit, save, roster creation or identity mint');
check(component.includes('"debit": {}'), 'cooked feast catalyst never paid twice');
check(component.includes('evolution_choice_permanent'), 'per-tier choice lock source');
check(evolution.includes('cfg.get("evolution_mode", "legacy") == "breakthrough"'), 'legacy held-stone mode activation refusal exists');
const proof = json('assets/creatures/tetherbound/stormursa/source/provenance.json');
check(proof.default_enabled === false && proof.full_art_bar_pass === false && proof.meshy_task_id === '', 'no invented asset acceptance');
check(config.find(r => r.target === 'stormursa').enabled === false, 'bear acquisition flag off');
const before = path => JSON.parse(execFileSync('git', ['show', 'b7cb96de89:' + path], {encoding:'utf8',maxBuffer:16*1024*1024}));
const bandPaths = execFileSync('git', ['ls-files', 'data/config/bands/*/spawns.json'], {encoding:'utf8'}).trim().split(/\r?\n/);
for (const path of ['data/config/water_encounters.json', 'data/config/cloudreach_encounters.json', 'data/config/cloudreach_chapter.json', 'data/config/stormwood_encounters.json', ...bandPaths]) {
  check(JSON.stringify(json(path)) === JSON.stringify(before(path)), `existing wild encounter catalogue preserved: ${path}`);
}
const water = json('data/config/water_encounters.json');
const cloud = json('data/config/cloudreach_encounters.json');
const storm = json('data/config/stormwood_encounters.json');
const chapter = json('data/config/cloudreach_chapter.json');
const wildText = JSON.stringify([water.tables, cloud.wild_sites, chapter.encounter_tables.filter(t => t.catchable), storm.tables, ...bandPaths.map(p => json(p).spawns)]);
check(wildText.includes('cannonback'), 'Cannonback remains authored wild');
check(wildText.includes('stormcapra'), 'Stormcapra remains authored wild');
for (const id of ['tuskroot','ashtusk','stormursa']) check(!wildText.includes('"'+id+'"'), `not regional wild: ${id}`);
const delta = json('ralph/reports/TRAINING/f29/species-delta.json');
check(delta.path === 'data/creatures/species.json' && delta.owner === 'F23', 'sole species metadata writer retained');
const paths = ['scripts/creatures/evolution.gd','data/config/evolution_lines.json','assets/creatures/tetherbound/stormursa/source/provenance.json','assets/creatures/tetherbound/stormursa/source/reference_brief.json','ralph/reports/TRAINING/f29/species-delta.json','ralph/reports/TRAINING/f29/feast_choice_proof.gd'];
const hashes = Object.fromEntries(paths.map(path => [path,createHash('sha256').update(readFileSync(path)).digest('hex')]));
console.log(JSON.stringify({checks,result:'SOURCE_RELATION_PASS',hashes,engine_runs:0,acceptance_credit:0},null,2));
