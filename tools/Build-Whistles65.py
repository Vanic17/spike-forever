"""Derive short/long referee breaths from the user's actual whistle recording."""
from pathlib import Path
import subprocess, json, hashlib
root = Path(__file__).resolve().parents[1]
ffmpeg = root/'tools/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe'
source = root/'assets/audio/referee62.ogg'
folder = root/'assets/audio/referee65'
folder.mkdir(exist_ok=True)
rows=[]
for group, durations in [('serve', [.48,.59,.68,.78]), ('point', [.61,.74,.9,1.04])]:
    for index, duration in enumerate(durations):
        pitch = [.985,1.018,.996,1.028][index]
        filters = f'aresample=48000,atrim=start=0.04:duration={duration},asetpts=PTS-STARTPTS,asetrate={round(48000*pitch)},aresample=48000,highpass=f=1200,lowpass=f=10500,afade=t=in:d=0.012,afade=t=out:st={duration/pitch-.09}:d=0.09,alimiter=limit=0.88'
        name=f'{group}-{index}.ogg'
        subprocess.run([str(ffmpeg),'-v','error','-y','-i',str(source),'-ar','48000','-af',filters,'-c:a','libvorbis','-q:a','6',str(folder/name)],check=True)
        rows.append({'group':group,'file':name,'duration':round(duration/pitch,3),'pitch':pitch})
(folder/'manifest.json').write_text(json.dumps({'source':'referee62.ogg','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'variants':rows},indent=2),encoding='utf-8')
print('WHISTLES65: 4 service breaths + 4 end-of-rally breaths, softened tails')
