from pathlib import Path
import json,hashlib,zipfile
root=Path(__file__).resolve().parent.parent
with zipfile.ZipFile(root/'dist/v0.99.0-approach105/SpikeForever-Windows.zip') as z:
    for name in ['assets/gameplay/league.json','controls.cfg','src/timing.gd','src/ball_flight.gd','src/block_response.gd','src/rally_ai.gd','src/approach105.gd','assets/active/native_motion105.res']:
        assert (root/name).read_bytes()==z.read(name),name
    # Keep historical test reports intact; attach the rerun to this patch.
    name='docs/attack105-tests.json'
    (root/'docs/serve106-attack-regression.json').write_bytes((root/name).read_bytes())
    (root/name).write_bytes(z.read(name))
profile=root/'.runtime/roaming/Godot/app_userdata/Spike Forever'
rows=json.loads((root/'.runtime/personal98-before.json').read_text(encoding='utf-8-sig'))
for entry in rows:
    file=profile/entry['path'].lstrip('\\/').replace('\\','/')
    assert hashlib.sha256(file.read_bytes()).hexdigest().upper()==entry['sha256'],str(file)
for name in ['serve106-tests.json','serve106-online-host.json','serve106-online-guest.json','serve106-attack-regression.json']:
    assert json.loads((root/'docs'/name).read_text(encoding='utf-8-sig'))['pass'],name
result={'pass':True,'personal_files_preserved':len(rows),'database_controls_timing_integrator_rotations_native_animations_unchanged':True,'tests_isolated_from_personal_profile':True}
(root/'docs/serve106-preservation.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps(result))
