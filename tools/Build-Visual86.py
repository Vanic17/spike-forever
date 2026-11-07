"""Author tileable maple surface maps; no external artwork or runtime dependency."""
from pathlib import Path
import numpy as np
from PIL import Image

out=Path('assets/art/visual86');out.mkdir(parents=True,exist_ok=True)
n=2048
rng=np.random.default_rng(86017)
y,x=np.mgrid[0:n,0:n].astype(np.float32)/n
board=np.floor(x*10)
longitudinal=y*3+np.mod(board,3)/3
unit_x=np.mod(x*10,1);unit_y=np.mod(longitudinal,1)
seam_x=np.exp(-np.minimum(unit_x,1-unit_x)*220)
seam_y=np.exp(-np.minimum(unit_y,1-unit_y)*350)
tone=np.sin(board*41.71+np.floor(longitudinal)*37.19)*.014
grain=np.zeros_like(x)
for frequency,amplitude in [(87,.010),(183,.006),(383,.003)]:
    grain+=np.sin((x*frequency+np.sin(y*np.pi*4+board)*.16)*np.pi*2)*amplitude
fine=rng.normal(0,.0015,(n,n)).astype(np.float32)
value=np.clip(.975+tone+grain+fine-seam_x*.032-seam_y*.02,0,1)
color=np.stack((value,np.clip(value*.998,0,1),np.clip(value*.987,0,1)),axis=-1)
Image.fromarray(np.uint8(color*255)).save(out/'maple_albedo86.png',optimize=True)
Image.fromarray(np.uint8(np.clip(.64+tone*.8+grain+fine,0,1)*255)).save(out/'maple_roughness86.png',optimize=True)
height=grain*.00002-seam_x*.000004-seam_y*.000003
dy,dx=np.gradient(height,n**-1)
normal=np.stack((-dx*.18,-dy*.18,np.ones_like(x)),axis=-1)
normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
Image.fromarray(np.uint8((normal*.5+.5)*255)).save(out/'maple_normal86.png',optimize=True)
print('VISUAL86 MAPS BUILT: 3 x 2048, seed 86017')
