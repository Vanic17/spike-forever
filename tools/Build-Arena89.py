from pathlib import Path
from PIL import Image,ImageFilter
import numpy as np
dest=Path('assets/art/arena89');dest.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(89013);size=2048
noise=rng.normal(0,1,(size,size)).astype(np.float32)
soft=np.array(Image.fromarray(np.uint8(np.clip(noise*28+128,0,255))).filter(ImageFilter.GaussianBlur(10)),dtype=np.float32)/255-.5
y,x=np.mgrid[:size,:size]
grain=.5+.11*noise+.2*soft
# Sealed maple boards at a known scale: ten 18 cm boards in a 1.8 m tile.
# Low-contrast longitudinal fibres stay readable without baked lighting.
board=np.minimum(9,(x*10//size));within=(x*10/size)%1
shade=rng.uniform(.91,1.0,10)[board]
fibres=np.sin(x*.043+np.sin(y*.004+board*.7)*2+soft*6)
fine=np.sin(x*.91+np.sin(y*.014)*.8)
wood=np.clip(shade+fibres*.008+fine*.001+soft*.020+noise*.002,0,1)
side_seam=np.minimum(within,1-within)<.0045
stagger=rng.integers(0,size//2,10)[board]
joint=((y+stagger)%(size//2))<2
wood-=side_seam*.09+joint*.045
rgb=np.stack((wood,wood*.978,wood*.935),axis=-1)
Image.fromarray(np.uint8(rgb*255)).save(dest/'sport_floor89.png')
rough=.67+noise*.012+soft*.12+side_seam*.05+joint*.025
for k in range(55):
 cx,cy=rng.uniform(0,size,2);angle=rng.uniform(-np.pi,np.pi)
 dx=(x-cx)*np.cos(angle)+(y-cy)*np.sin(angle);dy=-(x-cx)*np.sin(angle)+(y-cy)*np.cos(angle)
 scuff=np.exp(-(dx/rng.uniform(25,75))**2-(dy/rng.uniform(1.5,3.2))**2)
 rough+=scuff*.10
Image.fromarray(np.uint8(np.clip(rough,0,1)*255)).save(dest/'sport_rough89.png')
height=fibres*.006+fine*.001-side_seam*.045-joint*.025
gy,gx=np.gradient(height);n=np.stack((-gx*.65,gy*.65,np.ones_like(gx)),axis=-1);n/=np.linalg.norm(n,axis=-1,keepdims=True)
Image.fromarray(np.uint8((n*.5+.5)*255)).save(dest/'sport_normal89.png')
print('ARENA89 MATERIAL MAPS PASS')
