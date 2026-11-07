"""Authored seamless surface maps. No external images, models or dependencies at runtime."""
from pathlib import Path
import json
import numpy as np
from PIL import Image

OUT=Path('assets/art/visual85')
OUT.mkdir(parents=True,exist_ok=True)
N=1024
rng=np.random.default_rng(85017)
y,x=np.mgrid[0:N,0:N]/N
grain=np.zeros((N,N),np.float32)
for frequency,amplitude in [(13,.35),(31,.20),(67,.13),(139,.07),(277,.035)]:
    grain+=np.sin(2*np.pi*(x*frequency+.2*np.sin(y*2*np.pi)+.06*np.sin(y*10*np.pi)))*amplitude
board=np.floor(x*6)
board_tone=np.sin(board*15.73)*.008
edge=np.minimum(np.mod(x*6,1),1-np.mod(x*6,1))
seam=np.exp(-edge*180)*.025
fleck=rng.normal(0,1,(N,N))
albedo=np.clip(.965+grain*.018+board_tone-seam+fleck*.001,0,1)
height=grain*.00010-seam*.0004
dy,dx=np.gradient(height,N**-1)
normal=np.dstack((-dx*.09,-dy*.09,np.ones_like(x)))
normal/=np.linalg.norm(normal,axis=2,keepdims=True)
def gray(name,value):
    Image.fromarray(np.uint8(np.clip(value,0,1)*255),'L').save(OUT/name,optimize=True)
gray('court_detail_albedo.png',albedo)
gray('court_detail_roughness.png',.52+grain*.045+fleck*.006)
gray('vinyl_roughness.png',.62+.03*np.sin(2*np.pi*x*19)*np.sin(2*np.pi*y*13)+fleck*.015)
Image.fromarray(np.uint8((normal*.5+.5)*255),'RGB').save(OUT/'court_detail_normal.png',optimize=True)
u=x*2*np.pi*128;v=y*2*np.pi*128
fabric=np.dstack((.10*np.cos(u)*np.sin(v),.10*np.sin(u)*np.cos(v),np.ones_like(x)))
fabric/=np.linalg.norm(fabric,axis=2,keepdims=True)
Image.fromarray(np.uint8((fabric*.5+.5)*255),'RGB').save(OUT/'fabric_micro_normal.png',optimize=True)
(OUT/'README.md').write_text('# Visual surface maps\n\nProcedurally authored for Spike Forever by tools/Build-Visual85.py, seed 85017. No external image sources. Maps may be distributed with the project. Original licensed assets remain separate and unchanged.\n',encoding='utf-8')
print(json.dumps({'maps':5,'resolution':N,'seed':85017}))
