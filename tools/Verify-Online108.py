from pathlib import Path
import json,hashlib,zipfile
root=Path(__file__).resolve().parent.parent
with zipfile.ZipFile(root/'dist/v0.101.0-reactivity107/SpikeForever-Windows.zip') as z:
    for name in ['assets/gameplay/league.json','controls.cfg','src/timing.gd','src/player_stats_gameplay.gd','src/ball_flight.gd','src/rally_ai.gd','src/attack_delivery104.gd','src/defense_read107.gd','src/approach105.gd','assets/active/native_motion107.res']:
        assert (root/name).read_bytes()==z.read(name),name
profile=root/'.runtime/roaming/Godot/app_userdata/Spike Forever'
rows=json.loads((root/'.runtime/personal98-before.json').read_text(encoding='utf-8-sig'))
for entry in rows:
    file=profile/entry['path'].lstrip('\\/').replace('\\','/')
    assert hashlib.sha256(file.read_bytes()).hexdigest().upper()==entry['sha256'],str(file)
reports={}
for name in ['online108-host.json','online108-guest.json','online108-catalog-history.json']:
    report=json.loads((root/'docs'/name).read_text(encoding='utf-8-sig'));assert report['pass'],name;reports[name]=report
assert reports['online108-host.json']['catalog_hash']==reports['online108-guest.json']['catalog_hash']
assert len(reports['online108-guest.json']['stages'])==6
result={'pass':True,'personal_files_preserved':len(rows),'host_guest_database_hash_matches':True,'local_databases_unchanged':True,'balance_curves_physics_rotations_animations_unchanged':True,'network_attack_cases':6}
(root/'docs/online108-preservation.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps(result))
