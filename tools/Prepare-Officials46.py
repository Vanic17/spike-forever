"""Copy only the referee's required mesh, source gestures and diffuse maps."""
import struct,json,shutil
from pathlib import Path
root=Path(__file__).resolve().parents[1]; source=root/'assets/officials46_source'
out=root/'assets/art/officials46'; out.mkdir(exist_ok=True,parents=True)
mesh=next(source.rglob('SK_Char_Referee_M_01.psk'))
raw=mesh.read_bytes(); offset=0; mats=[]
while offset+32<=len(raw):
    tag,_,size,count=struct.unpack_from('<20s3i',raw,offset); offset+=32
    if tag.startswith(b'MATT'): mats=[raw[offset+i*size:offset+i*size+64].split(b'\0')[0].decode() for i in range(count)]
    offset+=size*count
shutil.copy2(mesh,out/'referee.psk')
materials={}
for name in mats:
    path=next(source.rglob(name+'.mat'),None)
    fields=dict(line.split('=',1) for line in path.read_text().splitlines() if '=' in line) if path else {}
    if name=='M_Char_M_Coach02_LOD01': fields['Diffuse']='T_Char_Head_M_Coach02_Base'
    if name=='M_Char_Body_Caucasian_LOD01': fields['Diffuse']='T_Char_Body_Caucasian_M_01_Base'
    textures={}
    for kind in ['Diffuse','Normal']:
        texture=next(source.rglob(fields.get(kind,'?')+'.png'),None)
        if texture:
            shutil.copy2(texture,out/texture.name); textures[kind]=texture.name
    materials[name]=textures
gestures={'idle':'Cine_REF_Center_Idle_Watch1','serve_left':'Cine_REF_Center_Sign_AuthServe_L','serve_right':'Cine_REF_Center_Sign_AuthServe_R','point_left':'Cine_REF_Center_Sign_TeamServe_L','point_right':'Cine_REF_Center_Sign_TeamServe_R','end_set':'Cine_REF_Center_Sign_EndSet'}
for key,clip in gestures.items():
    path=root/'assets/spike/Game/CharactersV1/Animations/_Cinematic/Referee'/(clip+'.psa')
    assert path.exists(),path
    shutil.copy2(path,out/(key+'.psa'))
(out/'materials.json').write_text(json.dumps(materials,indent=2))
print(json.dumps(materials,indent=2))
