from pathlib import Path
from PIL import Image,ImageFilter
import numpy as np
dest=Path('assets/art/arena89');dest.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(89013);size=2048
noise=rng.normal(0,1,(size,size)).astype(np.float32)
soft=np.array(Image.fromarray(np.uint8(np.clip(noise*28+128,0,255))).filter(ImageFilter.GaussianBlur(10)),dtype=np.float32)/255-.5
y,x=np.mgrid[:size,:size]
grain=.5+.11*noise+.2*soft
rubber=np.clip(.97+noise*.009+soft*.04,0,1)
rgb=np.repeat(rubber[:,:,None],3,axis=2)
Image.fromarray(np.uint8(rgb*255)).save(dest/'sport_floor89.png')
rough=.58+noise*.025+soft*.30
for k in range(55):
 cx,cy=rng.uniform(0,size,2);angle=rng.uniform(-np.pi,np.pi)
 dx=(x-cx)*np.cos(angle)+(y-cy)*np.sin(angle);dy=-(x-cx)*np.sin(angle)+(y-cy)*np.cos(angle)
 scuff=np.exp(-(dx/rng.uniform(25,75))**2-(dy/rng.uniform(1.5,3.2))**2)
 rough+=scuff*.10
Image.fromarray(np.uint8(np.clip(rough,0,1)*255)).save(dest/'sport_rough89.png')
gy,gx=np.gradient(grain);n=np.stack((-gx*.18,gy*.18,np.ones_like(gx)),axis=-1);n/=np.linalg.norm(n,axis=-1,keepdims=True)
Image.fromarray(np.uint8((n*.5+.5)*255)).save(dest/'sport_normal89.png')
print('ARENA89 MATERIAL MAPS PASS')
