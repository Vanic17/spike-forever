import struct,json,re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
pak=Path(r'C:\Program Files (x86)\Steam\steamapps\common\Spike Volleyball\ProVolley\Content\Paks\ProVolley-WindowsNoEditor.pak')
def i32(f): return struct.unpack('<i',f.read(4))[0]
def text(f):
    n=i32(f); return f.read(abs(n)*(2 if n<0 else 1)).decode('utf-16-le' if n<0 else 'utf-8').rstrip('\0')
matches=[]
with pak.open('rb') as f:
    f.seek(-44,2); magic,version,offset,size=struct.unpack('<IIQQ',f.read(24)); assert magic==0x5A6F12E1 and version==4
    f.seek(offset); mount=text(f); count=i32(f)
    for _ in range(count):
        name=text(f); entry=f.read(48); compression=struct.unpack_from('<I',entry,24)[0]
        if compression: f.seek(i32(f)*16,1)
        f.read(5)
        if re.search(r'referee|ref_|umpire|arbitr',name,re.I): matches.append(name)
out=root/'.runtime/officials46'; out.mkdir(parents=True,exist_ok=True)
(out/'pak-index.json').write_text(json.dumps(matches,indent=2))
for name in matches:
    if not '/Animations/' in name: print(name)
