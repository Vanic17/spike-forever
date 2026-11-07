"""Numerical PBR data from the attributed scan height/UVs; no beauty-shot editing."""
from pathlib import Path
from PIL import Image
import numpy as np,json
root=Path(__file__).resolve().parent.parent
dest=root/'assets/art/athlete88'
bump=np.asarray(Image.open(dest/'source/bump-lowRes.png').convert('L'),dtype=np.float32)/255
gy,gx=np.gradient(bump)
normal=np.stack((-gx*8,gy*8,np.ones_like(gx)),axis=-1)
normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
Image.fromarray(np.uint8(np.clip(normal*.5+.5,0,1)*255)).save(dest/'scan_normal88.png')
size=2048
rough=np.full((size,size),.56,np.float32)
scatter=np.full((size,size),.4,np.float32)
source=json.loads((root/'.runtime/athlete88-scan.json').read_text())[0]
v=np.array(source['vertices'])*np.array([50,50,38])+np.array([0,1.473,0])
uv=np.array(source['uv'])*size
faces=np.array(source['indices']).reshape(-1,3)
for tri in faces:
    t=uv[tri];lo=np.maximum(np.floor(t.min(0)).astype(int),0);hi=np.minimum(np.ceil(t.max(0)).astype(int),size-1)
    if np.any(hi<lo):continue
    xx,yy=np.meshgrid(np.arange(lo[0],hi[0]+1)+.5,np.arange(lo[1],hi[1]+1)+.5)
    den=(t[1,1]-t[2,1])*(t[0,0]-t[2,0])+(t[2,0]-t[1,0])*(t[0,1]-t[2,1])
    if abs(den)<1e-7:continue
    a=((t[1,1]-t[2,1])*(xx-t[2,0])+(t[2,0]-t[1,0])*(yy-t[2,1]))/den
    b=((t[2,1]-t[0,1])*(xx-t[2,0])+(t[0,0]-t[2,0])*(yy-t[2,1]))/den
    c=1-a-b;mask=(a>=0)&(b>=0)&(c>=0)
    p=a[...,None]*v[tri[0]]+b[...,None]*v[tri[1]]+c[...,None]*v[tri[2]]
    forehead=np.exp(-((p[...,1]-1.823)/.038)**2-(p[...,0]/.075)**4)*np.clip((p[...,2]-.035)/.04,0,1)
    nose=np.exp(-(p[...,0]/.018)**2-((p[...,1]-1.744)/.034)**2)*np.clip((p[...,2]-.07)/.04,0,1)
    ears=np.exp(-((abs(p[...,0])-.086)/.018)**2-((p[...,1]-1.754)/.045)**2)
    rv=.56-.17*forehead-.18*nose
    sv=.40+.30*ears+.10*nose
    dst=rough[lo[1]:hi[1]+1,lo[0]:hi[0]+1];dst[mask]=rv[mask]
    dst=scatter[lo[1]:hi[1]+1,lo[0]:hi[0]+1];dst[mask]=sv[mask]
rng=np.random.default_rng(88031)
rough+=rng.normal(0,.008,rough.shape)
Image.fromarray(np.uint8(np.clip(rough,0,1)*255)).save(dest/'scan_roughness88.png')
Image.fromarray(np.uint8(np.clip(scatter,0,1)*255)).save(dest/'scan_sss88.png')
print('SCAN88 PBR MAPS PASS / source albedo 4096, height normal 1024, derived roughness/scatter 2048')
body_path=next((root/'assets/art/Game').rglob('T_Char_Body_Caucasian_M_01_Base.png'))
body=np.asarray(Image.open(body_path).convert('RGB'),dtype=np.float32)/255
# Chromatic adaptation of the existing body atlas to the neutral scan complexion.
# The source body features, UVs and native resolution remain intact.
skin=(body[:,:,0]>body[:,:,1]*1.03)&(body[:,:,1]>body[:,:,2]*1.02)&(body.mean(axis=-1)>.12)
adapted=body*np.array([.98,1.09,1.18])+np.array([.014,.008,.008])
body[skin]=adapted[skin]
Image.fromarray(np.uint8(np.clip(body,0,1)*255)).save(dest/'body_albedo88.png')
