from pathlib import Path, PurePosixPath
import hashlib,json,sys,zipfile,zlib
archive=Path(sys.argv[1]).resolve()
index=json.loads(archive.with_name('SpikeForever-UpdateIndex.json').read_text(encoding='utf-8-sig'))
assert index['version']==json.loads((Path(__file__).resolve().parent.parent/'version.json').read_text(encoding='utf-8-sig'))['version']
assert index['archive']['size']==archive.stat().st_size
assert index['archive']['sha256']==hashlib.file_digest(archive.open('rb'),'sha256').hexdigest()
with zipfile.ZipFile(archive) as z, archive.open('rb') as raw:
    manifest=json.loads(z.read('release-manifest.json').decode('utf-8-sig'))
    assert manifest['version']==index['version']
    assert set(manifest['files'])==set(index['files'])
    assert set(z.namelist())==set(manifest['files'])|{'release-manifest.json'}
    assert len(z.namelist())==len(set(z.namelist()))
    for name,expected in manifest['files'].items():
        path=PurePosixPath(name)
        assert not path.is_absolute() and '..' not in path.parts and ':' not in name
        assert path.parts[0] not in ['.runtime','.updates','.git','user','saves','careers']
        assert path.name not in ['roster-overrides.json','hosts.yml','settings.cfg']
        assert not name.startswith(('tools/github/','tools/git/','assets/art/blender91/','assets/art/athlete92/','assets/art/player93/'))
        assert path.suffix not in ['.blend','.blend1']
        info=z.getinfo(name); entry=index['files'][name]
        data=z.read(name);actual=hashlib.sha256(data).hexdigest()
        assert actual==expected==entry['sha256'],name
        assert entry['size']==len(data)==info.file_size
        raw.seek(entry['offset']);packed=raw.read(entry['compressed_size'])
        decoded=zlib.decompress(packed,-15) if entry['compression']==8 else packed
        assert decoded==data,name
    for required in ['src/setter_second96.gd','src/stroke_motion96.gd','src/player_pose95.gd','src/net_spec94.gd','assets/active/native_motion96.res','docs/strokes96-tests.json','docs/strokes96-online-host.json','docs/strokes96-online-guest.json','tools/godot/Godot_v4.5.1-stable_win64.exe']:
        assert required in manifest['files'],required
    assert b'SF098-ATTACK104' in z.read('src/online_session.gd')
    assert b'banks["tip"]' in z.read('src/match_audio.gd')
report={'pass':True,'version':index['version'],'files':len(index['files']),'archive_bytes':archive.stat().st_size,'every_hash_and_selective_range_verified':True,'personal_files_included':False,'unapproved_prototypes_included':False}
Path('docs/strokes96-package-verification.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps(report))
