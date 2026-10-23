# Arena audio bank 39

The new bank complements the 54 v38 assets. The original assets are retained as
fallback. The files contain dry audio with soft edits; the Godot Arena bus adds
the hall reverb and runtime crossfades. Menu music remains outside that bus.

| Group | Files | Actual lengths | Measured integrated LUFS | Authorship |
| --- | ---: | --- | --- | --- |
| `ambient_bed` | 8 | 24–32 s | −29.23 to −29.18 | Quiet recorded crowd tails, independent low air textures and overlapping passages |
| `rhythm_long` | 12 | 24.118–33.604 s | −24.34 to −24.10 | Individually arranged supporter claps and skin drums, with humanized offsets, changing accents, call/response and rests; recorded source textures |
| `interlude_long` | 6 | 10.5–15 s | −24.47 to −24.23 | Recorded motif fragments developed into different call/response arrangements with authored percussion |
| `crowd_long` | 4 | 6.5–8 s | −24.87 to −23.73 | Real cheer onset blended into a quieter real hall tail, declining authored applause and air texture |
| `whistle_real` | 4 | 1.351–1.700 s | −23.09 to −23.05 | Four trim/speed edits of **one** supplied real referee blow; no synthesized whistle |

Total: **34 Ogg Vorbis files, 668.3 seconds, 6,629,334 bytes**. All files use
44.1 kHz stereo. The loudest measured true peak is **−4.32 dBTP**. These are
34 distinct edited/arranged assets, not 34 independent source recordings.

## Edits and continuity

Long phrase fade-outs are 3.2 seconds for beds, 2.7 seconds for rhythms, 2.2
seconds for interludes and 2.6 seconds for cheers. Source passages overlap with
equal-power splice envelopes. Every synthesized clap or drum has its own attack
and decay envelope. Rhythm patterns deliberately omit bars and vary emphasis;
they do not repeat a full recording at fixed boundaries. The real cheer falls
back toward hall ambience rather than ending on its transient peak.

The whistle video `whislte.mp4` includes an unrelated/noisy opening around
0–3.2 seconds and a silent recording pause around 3.2–6.25 seconds. A recording
click near 6.65 seconds is excluded. The selected real blow is approximately
6.97–8.49 seconds. The source waveform and log-frequency spectrogram were
checked before trimming. Its provenance and the exact offsets for all clips
are recorded in `assets/audio/arena39/manifest.json`, along with source SHA-256,
authored synthesis seeds/patterns, measured levels, fades and output hashes.

Crowd reactions and interludes are intended for home-team points only. Referee
whistles are neutral match events. Quiet ambient beds and occasional rhythmic
support can continue during rallies. The runtime director controls these phase
rules and gain envelopes; they are not baked into the files as a fixed match
soundtrack. Global L3/LS mute still acts on Master.

## Reproduction and validation

From the repository root on Windows:

```powershell
& tools/python311/python.exe tools/Build-ArenaAudio39.py --source-directory 'C:\Users\kravi\Videos\Captures'
& tools/python311/python.exe tools/Test-ArenaAudioAssets39.py
```

The builder needs only Python's standard library and the project's ffmpeg. It
does not download anything. Source videos are not distributed in the game ZIP.
`--crowd-only` rebuilds just the four long cheer tails in an existing bank.

The asset test decodes every shipped Ogg, verifies source metadata, expected
group counts and length ranges, SHA-256, distinct decoded PCM, real headroom,
and that the final 50 ms are at least about 22 dB below the body. The test
completed with `PASS ARENA39 ASSETS` for all 34 files. This verifies technical
continuity and integrity; it does not replace listening to the final in-game mix.

Logs: `docs/audio39-build.log`, `docs/audio39-crowd-build.log`,
`docs/audio39-assets-validation.log`. The runtime render maintained alongside
the audio director records the actual Godot buses for mix review.
