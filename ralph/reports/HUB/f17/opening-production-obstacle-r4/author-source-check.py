from pathlib import Path
import subprocess, hashlib, re, json
root=Path('D:/tetherbound/redesign-hub')
parent='8189ef734addce12d446c6c9a0f9d4016a0d657d'
name='tests/helpers/opening_geometry_navigator.gd'
old=subprocess.check_output(['git','show',parent+':'+name],cwd=root).decode().replace('\r\n','\n')
new=(root/name).read_text()
def functions(source):
    matches=list(re.finditer(r'^func (\w+)\(',source,re.M))
    result={}
    for m in matches:
        lines=source[m.start():].splitlines(True)
        end=1
        while end<len(lines) and (not lines[end].strip() or lines[end][0].isspace() or lines[end].startswith('#')): end+=1
        result[m.group(1)]=''.join(lines[:end]).rstrip()
    return result
a,b=functions(old),functions(new)
changed=[n for n in a if a[n]!=b[n]]
assert set(changed)=={'reset','_native_tick_impl','_native_tick','_production_observe','_production_record'},changed
assert b['_production_observe'].replace('\t\t\t"provisional_steering_us": _production_steering_us,\n','')==a['_production_observe']
addition='\tif _production_steering:\n\t\tvar steering_began: int = Time.get_ticks_usec()\n\t\tdirection = _production_heading(direction)\n\t\t_production_steering_us = Time.get_ticks_usec() - steering_began\n\t\tif refused():\n\t\t\treturn\n'
assert b['_native_tick_impl'].replace(addition,'')==a['_native_tick_impl']
assert b['reset'].replace('\t_avoid_tangent = Vector3.ZERO\n\t_avoid_retry = 0\n','')==a['reset']
for guard in ['MAX_QUERIES_FRAME := 96','MAX_QUERIES_LIFETIME := 250000','MAX_REQUESTS := 24000','FRAME_QUERY_US := 10000','CONTACTS := 8']:
    assert guard in new
heading=b['_production_heading']
assert heading.count('_motion(')==1
assert '_observed_frames' not in heading and '_observed_distance' not in heading and '_stalled =' not in heading and '_retry_at =' not in heading
assert 'global_position =' not in heading and 'velocity =' not in heading and '_supported_step(' not in heading
print(json.dumps({'unchanged_existing_functions':len(a)-len(changed),'changed':changed,'new_functions':sorted(set(b)-set(a)),'aggregate_observer_unchanged_except_timing':True,'default_native_tick_impl_restores_byte_exact_after_production_only_insertion':True,'new_queries_at_most_one':True,'navigator_sha256':hashlib.sha256((root/name).read_bytes()).hexdigest()}))
