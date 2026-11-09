"""Offline range/payload/install tests against the production PowerShell worker."""
from pathlib import Path
import hashlib, json, subprocess, zipfile, random, uuid, importlib.util

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('update_index76',ROOT/'tools/Build-UpdateIndex76.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);build=module.build
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def run_ps(script,*args):
    r=subprocess.run(['powershell','-NoProfile','-ExecutionPolicy','Bypass','-File',str(ROOT/'tools'/script),*map(str,args)],capture_output=True,text=True,timeout=90)
    return r
def main():
    # Import filename contains a hyphen, so the tiny loader below supplies it.
    folder=ROOT/'.runtime'/('selective76-'+uuid.uuid4().hex);folder.mkdir(parents=True)
    project=b'config_version=5\n[application]\nconfig/name="Spike Forever"\n'
    files={'project.godot':project,'src/main.gd':b'extends Node3D\n# new\n','version.json':b'{"version":"0.76.0"}',
           'Avvia Spike Forever.cmd':b'@echo off','controls.cfg':b'default controls','assets/gameplay/league.json':b'default DB',
           'assets/unchanged.bin':random.Random(76).randbytes(2*1024*1024),'assets/new.bin':b'new defense'*4096}
    archive=folder/'SpikeForever-Windows.zip';index_path=folder/'SpikeForever-UpdateIndex.json'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p,b in files.items():z.writestr(p,b)
        z.writestr('release-manifest.json',json.dumps({'version':'0.76.0','files':{p:hashlib.sha256(b).hexdigest() for p,b in files.items()}}))
    build(archive,index_path)
    def fixture(label):
        game=folder/label;game.mkdir()
        for p,b in files.items():
            if p=='assets/new.bin':continue
            target=game/p;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(b)
        (game/'src/main.gd').write_bytes(b'extends Node3D\n# old\n');(game/'version.json').write_bytes(b'{"version":"0.20.0"}')
        (game/'controls.cfg').write_bytes(b'personal bindings')
        (game/'assets/gameplay/league.json').write_bytes(b'personal DB')
        for p in ['careers/slot.json','legend72/legend-01.json','roster-overrides.json']:
            t=game/p;t.parent.mkdir(parents=True,exist_ok=True);t.write_bytes(b'personal data')
        return game
    def scan(game,label,index=index_path):
        job=folder/label
        result=run_ps('Download-SelectiveUpdate.ps1','-Destination',game,'-StateFolder',job,'-LocalIndex',index,'-LocalArchive',archive,'-IndexHash',sha(index),'-ArchiveHash',sha(archive))
        state=json.loads((job/'state.json').read_text(encoding='utf-8-sig'))
        return state,result
    results=[];game=fixture('game')
    untouched={p:sha(game/p) for p in ['controls.cfg','careers/slot.json','legend72/legend-01.json','roster-overrides.json','assets/gameplay/league.json','assets/unchanged.bin']}
    stamp=(game/'assets/unchanged.bin').stat().st_mtime_ns
    state,process=scan(game,'job')
    assert state['status']=='ready',(state,process.stderr)
    assert state['changed_files']==3 and state['received']<archive.stat().st_size*.01,state
    assert (game/'src/main.gd').read_bytes().endswith(b'# old\n'),'worker modified installed files'
    with zipfile.ZipFile(state['package']) as z:assert set(z.namelist())=={'src/main.gd','version.json','assets/new.bin','release-manifest.json'}
    result=run_ps('Install-Update.ps1','-Archive',state['package'],'-Destination',game,'-ExpectedHash',state['sha256'],'-NoRestart')
    assert result.returncode==0,result.stderr
    for p,b in files.items():
        if p not in ['controls.cfg','assets/gameplay/league.json']:assert (game/p).read_bytes()==b,p
    for p,h in untouched.items():assert sha(game/p)==h,p
    assert (game/'assets/unchanged.bin').stat().st_mtime_ns==stamp,'unchanged asset rewritten'
    results.append({'case':'changed-missing-only-and-personal-preservation','pass':True,'downloaded_bytes':state['received'],'full_bytes':archive.stat().st_size})
    state,_=scan(game,'job-current');assert state['status']=='current',state
    results.append({'case':'up-to-date-no-download','pass':True})
    race=fixture('race');state,_=scan(race,'job-race');assert state['status']=='ready',state
    (race/'assets/unchanged.bin').write_bytes(b'changed after scan')
    result=run_ps('Install-Update.ps1','-Archive',state['package'],'-Destination',race,'-ExpectedHash',state['sha256'],'-NoRestart')
    assert result.returncode!=0 and (race/'version.json').read_bytes()==b'{"version":"0.20.0"}' and (race/'src/main.gd').read_bytes().endswith(b'# old\n'),result.stdout
    results.append({'case':'unchanged-file-race-refused-before-install','pass':True})
    bad=json.loads(index_path.read_text());bad['files']['../escape'] = next(iter(bad['files'].values()))
    bad_index=folder/'bad-index.json';bad_index.write_text(json.dumps(bad))
    state,_=scan(fixture('unsafe'),'job-unsafe',bad_index);assert state['status']=='error',state
    assert not (folder/'escape').exists()
    results.append({'case':'unsafe-index-path-refused','pass':True})
    bad=json.loads(index_path.read_text());bad['files']['src/main.gd']['sha256']='0'*64
    bad_index=folder/'inconsistent-index.json';bad_index.write_text(json.dumps(bad))
    corrupt=fixture('corrupt');state,_=scan(corrupt,'job-corrupt',bad_index)
    assert state['status']=='fallback' and 'checksum' in state['message'],state
    assert (corrupt/'src/main.gd').read_bytes().endswith(b'# old\n')
    results.append({'case':'bad-file-hash-never-installed-full-fallback','pass':True})
    bad=json.loads(index_path.read_text());bad['files']['roster-overrides.json']=next(iter(bad['files'].values()))
    personal_index=folder/'personal-index.json';personal_index.write_text(json.dumps(bad))
    state,_=scan(fixture('personal'),'job-personal',personal_index);assert state['status']=='error',state
    results.append({'case':'personal-database-cannot-enter-index','pass':True})
    empty=folder/'empty';empty.mkdir();job=folder/'job-full'
    result=run_ps('Download-SelectiveUpdate.ps1','-Destination',empty,'-StateFolder',job,'-LocalIndex',index_path,'-IndexHash',sha(index_path),'-ArchiveHash',sha(archive),'-ArchiveUrl','https://github.com/Vanic17/spike-forever/releases/download/v0.76.0/SpikeForever-Windows.zip')
    state=json.loads((job/'state.json').read_text(encoding='utf-8-sig'));assert state['status']=='fallback' and state['received']==0,state
    results.append({'case':'new-install-falls-back-before-any-range-transfer','pass':True})
    report={'pass':True,'cases':results,'fixture':str(folder)}
    (ROOT/'docs/selective76-offline.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report))
if __name__=='__main__':main()
