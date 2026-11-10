from pathlib import Path
import json,hashlib,zipfile
root=Path(__file__).resolve().parent.parent
with zipfile.ZipFile(root/'dist/v0.100.0-serve106/SpikeForever-Windows.zip') as z:
    for name in ['assets/gameplay/league.json','controls.cfg','src/timing.gd','src/ball_flight.gd','src/block_response.gd','src/rally_ai.gd','src/attack_delivery104.gd','assets/active/native_motion105.res']:
        assert (root/name).read_bytes()==z.read(name),name
    for name,dest in [('docs/attack105-tests.json','docs/reactivity107-attack-tests.json'),('docs/serve106-tests.json','docs/reactivity107-serve-tests.json'),('docs/serve106-online-host.json','docs/reactivity107-online-host.json'),('docs/serve106-online-guest.json','docs/reactivity107-online-guest.json')]:
        (root/dest).write_bytes((root/name).read_bytes())
        (root/name).write_bytes(z.read(name))
profile=root/'.runtime/roaming/Godot/app_userdata/Spike Forever'
rows=json.loads((root/'.runtime/personal98-before.json').read_text(encoding='utf-8-sig'))
for entry in rows:
    file=profile/entry['path'].lstrip('\\/').replace('\\','/')
    assert hashlib.sha256(file.read_bytes()).hexdigest().upper()==entry['sha256'],str(file)
for name in ['reactivity107-tests.json','reactivity107-attack-tests.json','reactivity107-serve-tests.json','reactivity107-online-host.json','reactivity107-online-guest.json']:
    assert json.loads((root/'docs'/name).read_text(encoding='utf-8-sig'))['pass'],name
result={'pass':True,'personal_files_preserved':len(rows),'database_controls_timing_integrator_rotations_ballistics_unchanged':True,'old_native_library_preserved':True}
(root/'docs/reactivity107-preservation.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps(result))
