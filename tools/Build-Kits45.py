"""Deterministic garment UV baker. Original PSK UVs/weights are never changed.

Inputs are unmodified photographic references or separately authored flat plates.
The raster pass projects them onto the actual garment's rest coordinates. Back
panels without a verified photograph are deliberately marked reconstructed.
Requires Pillow and NumPy. Runtime has no Python dependency.
"""
import json, math, hashlib
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/art/kits45'; REF=OUT/'reference/Maglie'
SIZE=2048

# club, original screenshot, full-shirt bounds, primary, accent, shorts, motif.
# Dedicated libero exists only when the supplied archive identifies it.
DATA=[
('allianz-milano','allianz milano .png',[
 ('home',(723,118,1095,580),'eeeeef','172239','f1f1f1','letters'),
 ('away',(187,118,562,580),'17191d','1478b4','111c30','letters')]),
('cisterna-volley','cisterna volley- viola home - bianca away- rossa libero .png',[
 ('home',None,'282051','99d5eb','24204e','angular'),('away',None,'f4f5f7','88c8e4','f2f4f5','angular'),('libero',None,'ce303b','c6e0eb','ce303b','angular')]),
('cucine-lube-civitanova','lube civitanova.png',[
 ('home',(350,132,884,862),'232225','db1a2d','232225','tribal'),('away',(887,132,1399,863),'dd152a','16171b','d31a2e','tribal'),('libero',(1428,132,1940,862),'f3c724','181c25','f2c323','tribal')]),
('acqua-santanna-cuneo','cuneo .png',[
 ('home',(121,85,431,447),'10254c','15a8c7','11254b','eagle'),('away',(992,85,1301,447),'b9e5ef','159ac3','bde6ee','eagle'),('libero',(121,714,432,1076),'e95616','575651','ec651b','eagle')]),
('gas-sales-bluenergy-piacenza','piacenza.png',[
 ('home',(201,154,488,462),'bc102c','e73245','b81530','city'),('away',(642,153,939,461),'f3f3f3','c51838','f3f3f3','city'),('libero',(1088,154,1382,461),'112735','f68b22','102432','bolt')]),
('itas-trentino','trentino.png',[
 ('home',(75,188,452,637),'f0f0ed','e8c62e','f4f4ef','contour'),('away',(696,188,1077,637),'111d32','357bc1','14233b','contour'),('libero',(1320,188,1700,637),'b7192f','dc273a','b01b31','contour')]),
('pallavolo-padova','padova - nera prima- bianca seconda - verde libero.jpg',[
 ('home',None,'151619','dddddd','151619','wing'),('away',None,'efefec','b6b8b7','151619','wing'),('libero',None,'086747','c4d630','076c4b','wing')]),
('rana-verona','verona.png',[
 ('home',(380,93,644,377),'104e8e','e5ca16','233c7c','stripes'),('away',(24,94,293,378),'e4d015','173f82','233c7c','stripes'),('libero',(732,93,998,379),'eceeec','e9cd12','233c7c','stripes')]),
('sir-susa-scai-perugia','perugia.png',[
 ('home',(143,199,522,640),'191c20','d21b38','191b20','polygon'),('away',(669,199,1051,640),'a91530','161b20','ac1732','polygon')]),
('tinet-prata-di-pordenone','pordenone.png',[
 ('home',None,'1447cf','16bfdd','1546ce','maze'),('away',None,'f0f3f5','c9e9ee','eef2f3','maze')]),
('valsa-group-modena','modena.png',[
 ('home',None,'efd127','f9e477','151e32','contour'),('away',None,'15213d','2855c5','151e32','contour'),('libero',None,'243e3e','b8d970','243e3e','leaf')]),
('vero-volley-monza','monza.png',[
 ('home',None,'1177b6','1d3e76','202435','fingerprint'),('away',None,'eeefed','1a2c48','202435','fingerprint')])]

def rgb(value): return np.array([int(value[i:i+2],16) for i in (0,2,4)],dtype=np.float32)

def panel(primary,accent,motif):
    """Code-native repeat motif for undocumented rear/side fabric, not a logo."""
    y,x=np.mgrid[0:1024,0:1024]/1024.
    a,b=rgb(primary),rgb(accent)
    if motif in ('contour','fingerprint','leaf'):
        wave=np.sin((x*15+np.sin(y*11+x*3)*.7)*5)
        mask=(wave>.97).astype(float)*.2
    elif motif in ('eagle','angular','city','tribal','maze','polygon'):
        if motif=='maze':
            mask=(((np.floor(x*15)+np.floor(y*14))%5<1)&(x>.12)&(x<.88)).astype(float)*.35
        else:
            # Faceted diagonal polygons, not circular noise. Long narrow facets
            # preserve the angular/eagle/tribal family of the reference fabric.
            gx=x*9; gy=y*14
            cell=(np.floor(gx)*13+np.floor(gy)*7)%11
            triangle=(gx%1)+(gy%1)>.95
            mask=((cell/11)*.12+triangle*.06)
            if motif=='city': mask=(((np.floor(x*11)+np.floor(y*17)*3)%7)/7)*.13
            if motif=='tribal': mask=(np.abs((x*7+y*11)%1-.5)<.07).astype(float)*.10
            if motif=='polygon': mask=((np.abs(np.sin(x*17+y*13))<.025)|(np.abs(np.sin(x*11-y*22))<.018)).astype(float)*.60
    elif motif=='wing': mask=(np.sin((np.arctan2(y-.5,x-.5)*23+np.hypot(x-.5,y-.5)*60))>.75).astype(float)*.22
    elif motif=='letters': mask=((np.sin(x*75+y*39)>.7)&((x<.23)|(x>.77))).astype(float)*.24
    elif motif=='stripes': mask=((x<.07)|(x>.93)).astype(float)*.9
    elif motif=='bolt': mask=((y>.18-x*.32)&(y<.24-x*.32)).astype(float)*.9
    else: mask=np.zeros_like(x)
    textile=(np.sin(x*1024*math.pi)*np.sin(y*1024*math.pi))[:,:,None]*.6
    return np.uint8(np.clip(a[None,None,:]*(1-mask[:,:,None])+b[None,None,:]*mask[:,:,None]+textile,0,255))

def sample(img,u,v):
    h,w=img.shape[:2]
    x=np.clip(u*(w-1),0,w-1); y=np.clip(v*(h-1),0,h-1)
    x0=x.astype(int); y0=y.astype(int); x1=np.minimum(x0+1,w-1); y1=np.minimum(y0+1,h-1)
    ax=(x-x0)[:,None]; ay=(y-y0)[:,None]
    return (img[y0,x0]*(1-ax)*(1-ay)+img[y0,x1]*ax*(1-ay)+img[y1,x0]*(1-ax)*ay+img[y1,x1]*ax*ay)

def geometry():
    import runpy
    # Inspector also writes a human-readable wireframe. It never mutates PSK.
    runpy.run_path(str(ROOT/'tools/Inspect-KitMesh45.py'))
    mesh=json.loads((ROOT/'.runtime/kits45-research/cloth-mesh.json').read_text())
    points=np.array(mesh['points']); wedges=mesh['wedges']; faces=mesh['faces']
    position=np.zeros((SIZE,SIZE,3),np.float32); covered=np.zeros((SIZE,SIZE),bool)
    # Barycentric UV rasterization using the original rest coordinates.
    for face in faces:
        uv=np.array([wedges[w][1:] for w in face])*(SIZE-1)
        xyz=np.array([points[wedges[w][0]] for w in face])
        lo=np.maximum(np.floor(uv.min(axis=0)).astype(int),0); hi=np.minimum(np.ceil(uv.max(axis=0)).astype(int),SIZE-1)
        if (hi<lo).any(): continue
        xx,yy=np.meshgrid(np.arange(lo[0],hi[0]+1),np.arange(lo[1],hi[1]+1))
        p=np.stack((xx,yy),axis=-1)
        a,b,c=uv; ab=b-a; ac=c-a; den=ab[0]*ac[1]-ab[1]*ac[0]
        if abs(den)<1e-8: continue
        w1=((p[:,:,0]-a[0])*(c[1]-a[1])-(p[:,:,1]-a[1])*(c[0]-a[0]))/den
        w2=((b[0]-a[0])*(p[:,:,1]-a[1])-(b[1]-a[1])*(p[:,:,0]-a[0]))/den
        valid=(w1>=-.002)&(w2>=-.002)&(w1+w2<=1.002)
        py=yy[valid]; px=xx[valid]
        position[py,px]=(1-w1[valid,None]-w2[valid,None])*xyz[0]+w1[valid,None]*xyz[1]+w2[valid,None]*xyz[2]
        covered[py,px]=True
    return position,covered

def bake(club,source,row,positions,covered):
    variant,bounds,primary,accent,shorts,motif=row
    key=club+'-'+variant
    clean=OUT/(key+'-front.png')
    revision={'pallavolo-padova-home':'pallavolo-padova-home-v2-front.png','pallavolo-padova-away':'pallavolo-padova-away-v3-front.png'}.get(key)
    if revision:
        clean=OUT/revision
        if not clean.exists(): raise RuntimeError('Missing approved accuracy revision '+str(clean))
    if clean.exists():
        plate=Image.open(clean).convert('RGB'); bounds=(0,0,plate.width,plate.height)
        # Measure the actual garment envelope. Generated plates can include
        # wider margins/aspect ratios than requested; never project background.
        pixels=np.asarray(plate,dtype=float)
        background=np.median(np.concatenate((pixels[:5].reshape(-1,3),pixels[-5:].reshape(-1,3))),axis=0)
        foreground=np.linalg.norm(pixels-background,axis=2)>65
        yy,xx=np.nonzero(foreground)
        bounds=(int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1)
        source_path=clean
    else:
        if bounds is None: raise RuntimeError('Missing clean plate '+key)
        source_path=REF/source; plate=Image.open(source_path).convert('RGB')
    x0,y0,x1,y1=bounds
    front=np.asarray(plate.crop(bounds),dtype=np.float32)
    background=np.asarray(plate,dtype=np.float32)[int(bounds[1]),int(bounds[0])]
    back=panel(primary,accent,motif)
    # Rear side panels, neckline, stitched hem. Leave space for live names/numbers.
    rear=Image.fromarray(back); draw=ImageDraw.Draw(rear)
    draw.polygon([(0,230),(42,230),(85,1024),(0,1024)],fill='#'+accent)
    draw.polygon([(1024,230),(982,230),(939,1024),(1024,1024)],fill='#'+accent)
    draw.line([(0,995),(1024,995)],fill='#'+accent,width=5)
    font=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',36)
    title={'allianz-milano':'MILANO','cisterna-volley':'CISTERNA VOLLEY','cucine-lube-civitanova':'LUBE','acqua-santanna-cuneo':'CUNEO VOLLEY','gas-sales-bluenergy-piacenza':'PIACENZA','itas-trentino':'TRENTINO','pallavolo-padova':'PADOVA VOLLEYBALL','rana-verona':'VERONA','sir-susa-scai-perugia':'PERUGIA','tinet-prata-di-pordenone':'PRATA','valsa-group-modena':'MODENA VOLLEY','vero-volley-monza':'VERO VOLLEY'}[club]
    text_color='#15243a' if float(rgb(primary)@np.array([.2126,.7152,.0722]))>140 else '#f4f4f4'
    draw.text((512,905),title,font=font,anchor='mm',fill=text_color)
    if club=='cisterna-volley':
        draw.text((512,65),'GRUPPO GESA',font=font,anchor='mm',fill=text_color)
        draw.text((512,860),'XGO',font=font,anchor='mm',fill=text_color)
    back=np.asarray(rear,dtype=np.float32)
    short_panel=panel(shorts,accent,motif)
    x,y,z=positions[covered].T
    shirt=y>1.045
    result=np.tile(rgb(primary),(len(x),1))
    # Front torso shrinks below the shoulders; sample body print without the background.
    v=np.clip((1.62-y)/.57,0,1)
    u=.5+x/.36*.56
    sleeve=np.abs(x)>.19
    u[sleeve]=.5+x[sleeve]/.66
    front_mask=shirt&(z>=-.015)
    result[front_mask]=sample(front,u[front_mask],v[front_mask])
    front_sleeve=front_mask&sleeve
    sleeve_u=np.clip(u[front_sleeve],.07,.93)
    sleeve_v=.30+.08*np.clip((np.abs(x[front_sleeve])-.19)/.14,0,1)
    result[front_sleeve]=sample(front,sleeve_u,sleeve_v)
    back_mask=shirt&~front_mask
    result[back_mask]=sample(back,.5-x[back_mask]/.40,v[back_mask])
    # Sleeve back uses the actual sleeve print, with no chest sponsors duplicated.
    sleeve_mask=back_mask&sleeve
    su=.5+np.sign(x[sleeve_mask])*.38
    result[sleeve_mask]=sample(front,su,np.full(len(su),.34))
    outside_sleeve=shirt&sleeve&(np.linalg.norm(result-background,axis=1)<35)
    result[outside_sleeve]=rgb(primary)
    short_mask=~shirt
    result[short_mask]=sample(short_panel,.5+x[short_mask]/.44,(1.065-y[short_mask])/.395)
    if club=='sir-susa-scai-perugia':
        badge=short_mask&(z>.04)&(x>.045)&(x<.17)&(y>.78)&(y<.875)
        result[badge]=sample(front,.25+(x[badge]-.045)/.125*.50,.35+(.875-y[badge])/.095*.20)
    # Official shorts, cropped per leg: sponsor placement/pattern, not generic colours.
    official=OUT/'reference/official'/(club+('-2.jpg' if variant=='away' else '-1.jpg'))
    if official.exists() and variant!='libero' and club!='sir-susa-scai-perugia':
        oi=Image.open(official).convert('RGB'); arr=np.asarray(oi,dtype=np.float32)
        # Known complete-uniform plate envelope. The plain top waistband stays authored.
        sm=short_mask&(z>.012)&(y<1.025)
        ou=np.clip(.50+x[sm]/.44*.68,.15,.85)
        ov=.615+(1.065-y[sm])/.395*.34
        result[sm]=sample(arr,ou,ov)
        # Remove photographed model numbers; live identity is rendered by the shader.
        photographed_number_side={'allianz-milano':1,'cisterna-volley':-1,'gas-sales-bluenergy-piacenza':-1,'itas-trentino':1,'pallavolo-padova':1,'tinet-prata-di-pordenone':-1}.get(club,0)
        if photographed_number_side:
            number_region=short_mask&(z>.012)&(x*photographed_number_side>0)
            result[number_region]=sample(short_panel,.5+x[number_region]/.44,(1.065-y[number_region])/.395)
    # Neckline, cuffs, inner facing: separate UV components have real bound locations.
    trims={
      'allianz-milano':{'home':'f4f4f1','away':'f4f4f1'},
      'acqua-santanna-cuneo':{'home':'f4f4f1','away':'f4f4f1'},
      'gas-sales-bluenergy-piacenza':{'away':'f3f3f3','libero':'f3f3f3'},
      'itas-trentino':{'away':'17223a'},
      'pallavolo-padova':{'home':'151619','away':'151619'},
      'rana-verona':{'libero':'173f82'},
      'sir-susa-scai-perugia':{'home':'191c20','away':'191c20'},
      'tinet-prata-di-pordenone':{'home':'efd531','away':'efd531'},
      'valsa-group-modena':{'home':'15213d','away':'efd531'},
      'vero-volley-monza':{'home':'eeeeef','away':'1a2c48'}
    }
    neck_color=trims.get(club,{}).get(variant,accent)
    cuff_color=neck_color if club in ('allianz-milano','sir-susa-scai-perugia','tinet-prata-di-pordenone','valsa-group-modena') else accent
    if club=='pallavolo-padova' and variant=='home':
        shoulder=back_mask&(y>1.38)&(np.abs(x)>.10)
        result[shoulder]=rgb(primary)
    neck=shirt&(y>1.585)&(np.abs(x)<.10)
    result[neck]=rgb(neck_color)
    cuff=shirt&(np.abs(x)>.295)&(y<1.40)
    result[cuff]=rgb(cuff_color)
    waistband=(y>1.045)&(y<1.068)
    result[waistband]=rgb(shorts)*.88
    hem=(y<.695)
    hem_color='efd531' if club in ('tinet-prata-di-pordenone','valsa-group-modena') and variant!='libero' else accent
    result[hem]=rgb(hem_color)*.85
    atlas=np.zeros((SIZE,SIZE,3),np.uint8); atlas[:]=rgb(primary)
    atlas[covered]=np.uint8(np.clip(result,0,255))
    # Eight-texel gutter: linear filtering / mipmaps cannot expose white seams.
    valid=covered.copy()
    for _ in range(8):
        next_valid=valid.copy()
        for dy,dx in ((0,1),(0,-1),(1,0),(-1,0)):
            neighbor=np.roll(valid,(dy,dx),(0,1)); target=~next_valid&neighbor
            atlas[target]=np.roll(atlas,(dy,dx),(0,1))[target]; next_valid[target]=True
        valid=next_valid
    dest=OUT/(key+'-uv.png'); Image.fromarray(atlas).save(dest,optimize=True)
    return {'variant':variant,'texture':'res://'+dest.relative_to(ROOT).as_posix(),'primary_hex_approx':'#'+primary,'secondary_hex_approx':'#'+accent,'shorts_hex':'#'+shorts,'ink':text_color,'front_reference':source_path.relative_to(ROOT).as_posix(),'front_bounds':list(bounds),'back_status':'reconstructed_from_supplied_palette_and_motif','shorts_reference':official.relative_to(ROOT).as_posix() if official.exists() else None,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()}

def main():
    import argparse
    parser=argparse.ArgumentParser(); parser.add_argument('--club'); args=parser.parse_args()
    positions,covered=geometry(); clubs={}
    for club,source,rows in DATA:
        if args.club and args.club!=club: continue
        variants={}
        for row in rows:
            variants[row[0]]=bake(club,source,row,positions,covered); print('BAKED',club,row[0],flush=True)
        clubs[club]={'dedicated_libero':'libero' in variants,'variants':variants}
    path=ROOT/'assets/gameplay/kits.json'
    if args.club and path.exists():
        data=json.loads(path.read_text()); data['clubs'].update(clubs)
    else: data={'schema':1,'resolution':SIZE,'archive_priority':True,'clubs':clubs}
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    print('KIT ATLAS PASS',sum(len(c['variants']) for c in data['clubs'].values()))

if __name__=='__main__': main()
