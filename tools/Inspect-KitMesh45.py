"""Inspect original cloth geometry and draw its native UV islands."""
import json, struct
from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parents[1]
raw=(root/'assets/active/cloth.psk').read_bytes(); chunks={}; offset=0
while offset+32<=len(raw):
    tag,_,size,count=struct.unpack_from('<20s3i',raw,offset); offset+=32
    chunks[tag.rstrip(b'\0').decode()]=(size,count,raw[offset:offset+size*count]); offset+=size*count
_,count,data=chunks['PNTS0000']
points=[(x*.01,z*.01,-y*.01) for x,y,z in struct.iter_unpack('<3f',data)]
size,count,data=chunks['VTXW0000']
wedges=[struct.unpack_from('<I2f',data,i*size) for i in range(count)]
size,count,data=chunks['FACE0000']
faces=[struct.unpack_from('<3H',data,i*size) for i in range(count)]
parents=list(range(len(points)))
def find(x):
    while parents[x]!=x:
        parents[x]=parents[parents[x]]; x=parents[x]
    return x
for face in faces:
    a,b,c=[wedges[w][0] for w in face]; parents[find(b)]=find(a); parents[find(c)]=find(a)
groups={}
for face in faces:
    key=find(wedges[face[0]][0]); groups.setdefault(key,[]).append(face)
canvas=Image.new('RGB',(2048,2048),'#101c2c'); draw=ImageDraw.Draw(canvas)
report=[]
colors=['#75d5ff','#f5bd55','#94ed92','#e28ee8','#ff8479','#e5e8f2']
for n,(key,triangles) in enumerate(sorted(groups.items(),key=lambda p:-len(p[1]))):
    coords=[points[wedges[w][0]] for face in triangles for w in face]
    uv=[wedges[w][1:] for face in triangles for w in face]
    bounds=[[round(min(p[a] for p in coords),4),round(max(p[a] for p in coords),4)] for a in range(3)]
    uv_bounds=[[round(min(p[a] for p in uv),4),round(max(p[a] for p in uv),4)] for a in range(2)]
    report.append({'component':n,'triangles':len(triangles),'bounds':bounds,'uv_bounds':uv_bounds})
    for face in triangles:
        polygon=[(wedges[w][1]*2048,wedges[w][2]*2048) for w in face]
        draw.polygon(polygon,outline=colors[n%len(colors)])
    if len(triangles)>20:
        centre=((uv_bounds[0][0]+uv_bounds[0][1])*1024,(uv_bounds[1][0]+uv_bounds[1][1])*1024)
        draw.text(centre,str(n),fill='white',stroke_width=2,stroke_fill='black')
out=root/'.runtime/kits45-research'; out.mkdir(exist_ok=True,parents=True)
canvas.save(out/'cloth-uv.png')
(out/'cloth-mesh.json').write_text(json.dumps({'components':report,'points':points,'wedges':wedges,'faces':faces}),encoding='utf-8')
print(json.dumps(report,indent=2))
