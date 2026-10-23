"""Build the v39 long-form arena bank from the user's recordings and authored DSP.

No packages/downloads: Python stdlib and the project's ffmpeg are sufficient.
The new rhythms are individual arrangements with humanized claps, pitched skin
drums, source call/response passages and deliberate rests, not renamed loops.
Raw source videos stay outside the distributed game. Arena reverb is runtime.
"""
from __future__ import annotations

import argparse
import array
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import math
import os
from pathlib import Path
import random
import re
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
FFMPEG = ROOT / "tools/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe"
OUTPUT = ROOT / "assets/audio/arena39"
WORK = ROOT / ".runtime/audio39-source"
RATE = 24000
SOURCES = ["applause 2", "applause 3", "crowd", "crowd 2", "drums", "in between", "whislte"]


def run(args: list) -> str:
    proc = subprocess.run([str(x) for x in args], capture_output=True, text=True, encoding="utf-8", errors="replace")
    if proc.returncode:
        raise RuntimeError(proc.stderr)
    return proc.stdout + proc.stderr


def read_wav(path: Path) -> array.array:
    with wave.open(str(path), "rb") as stream:
        assert stream.getframerate() == RATE and stream.getnchannels() == 1
        value = array.array("h", stream.readframes(stream.getnframes()))
    return array.array("f", (x / 32768 for x in value))


def write_wav(path: Path, left: array.array, right: array.array) -> None:
    peak = max(max(map(abs, left)), max(map(abs, right)), .001)
    scale = min(1.0, .82 / peak)
    pcm = array.array("h")
    for l, r in zip(left, right):
        pcm.extend((int(l * scale * 32767), int(r * scale * 32767)))
    with wave.open(str(path), "wb") as stream:
        stream.setnchannels(2); stream.setsampwidth(2); stream.setframerate(RATE)
        stream.writeframes(pcm.tobytes())


def sample(source: array.array, offset: float, duration: float, target_rms: float = .1) -> array.array:
    result = array.array("f", source[int(offset * RATE):int((offset + duration) * RATE)])
    energy = math.sqrt(sum(x * x for x in result) / max(1, len(result)))
    gain = min(12.0, target_rms / max(.00001, energy))
    return array.array("f", (x * gain for x in result))


def place(left: array.array, right: array.array, clip: array.array, at: float, gain: float = 1, pan: float = 0,
          fade: float = .05, rate: float = 1.0) -> None:
    start = int(at * RATE)
    count = int(len(clip) / rate)
    fade_frames = max(1, int(min(fade, count / RATE * .48) * RATE))
    gl = math.sqrt((1 - pan) * .5) * gain
    gr = math.sqrt((1 + pan) * .5) * gain
    for i in range(count):
        destination = start + i
        if destination < 0 or destination >= len(left):
            continue
        pos = i * rate
        a = int(pos)
        b = min(len(clip) - 1, a + 1)
        v = clip[a] + (clip[b] - clip[a]) * (pos - a)
        # Equal-power source splice envelopes. Wide passages overlap in time.
        envelope = min(1, i / fade_frames, (count - 1 - i) / fade_frames)
        envelope = math.sin(max(0, envelope) * math.pi / 2)
        left[destination] += v * gl * envelope
        right[destination] += v * gr * envelope


def clap(rng: random.Random, strength: float) -> array.array:
    duration = rng.uniform(.115, .18)
    result = array.array("f")
    low = 0.0
    taps = [0.0, rng.uniform(.008, .013), rng.uniform(.018, .027)]
    for n in range(int(duration * RATE)):
        t = n / RATE
        noise = rng.uniform(-1, 1)
        low += .31 * (noise - low)
        body = noise - low
        envelope = sum(math.exp(-(t - tap) * 65) for tap in taps if t >= tap)
        tail = math.exp(-t * 25) * .12
        attack = min(1, t / .0015)
        result.append((body * envelope * .36 + low * tail) * strength * attack)
    return result


def drum(rng: random.Random, strength: float, high: bool = False) -> array.array:
    duration = .24 if high else .43
    pitch = rng.uniform(133, 174) if high else rng.uniform(70, 105)
    phase = 0.0
    low = 0.0
    result = array.array("f")
    for n in range(int(duration * RATE)):
        t = n / RATE
        phase += math.tau * (pitch + 75 * math.exp(-t * 55)) / RATE
        noise = rng.uniform(-1, 1)
        low += .18 * (noise - low)
        skin = (noise - low) * math.exp(-t * 29) * (.23 if high else .11)
        tone = (math.sin(phase) + .25 * math.sin(phase * 1.47)) * math.exp(-t * (15 if high else 9))
        result.append((tone * .34 + skin) * strength * min(1, t / .003))
    return result


def murmur(rng: random.Random, duration: float, gain: float) -> array.array:
    """Diffuse voiced air, without intelligible speech or synthetic crowd cheers."""
    result = array.array("f")
    a = b = 0.0
    for n in range(int(duration * RATE)):
        t = n / RATE
        noise = rng.uniform(-1, 1)
        a += .075 * (noise - a)
        b += .011 * (noise - b)
        breath = .62 + .16 * math.sin(t * .71) + .12 * math.sin(t * 1.47 + 2.2)
        result.append((a - b) * gain * breath)
    return result


def silence(duration: float) -> tuple[array.array, array.array]:
    frames = int(duration * RATE)
    return array.array("f", [0]) * frames, array.array("f", [0]) * frames


def fades(left: array.array, right: array.array, fade_in: float, fade_out: float) -> None:
    count = len(left)
    front, back = int(fade_in * RATE), int(fade_out * RATE)
    for n in range(count):
        envelope = min(1, n / max(1, front), (count - n - 1) / max(1, back))
        envelope = math.sin(max(0, envelope) * math.pi / 2) ** 2
        left[n] *= envelope; right[n] *= envelope


def loudness(text: str) -> dict:
    result = re.search(r'\{\s*"input_i"[\s\S]+?\}', text)
    if not result:
        raise RuntimeError("ffmpeg loudness measurement missing")
    return json.loads(result.group())


def render(job: dict) -> dict:
    raw, name, group, target = job["raw"], job["name"], job["group"], job["target"]
    before = "highpass=f=100,lowpass=f=9500"
    if group == "ambient_bed":
        before = "highpass=f=110,lowpass=f=1450"
    elif group == "whistle_real":
        before = "highpass=f=370,lowpass=f=9000"
    measured = loudness(run([FFMPEG, "-hide_banner", "-i", raw, "-af", before + f",loudnorm=I={target}:TP=-4:LRA=12:print_format=json", "-f", "null", "-"]))
    norm = (f"loudnorm=I={target}:TP=-4:LRA=12:measured_I={measured['input_i']}:"
            f"measured_TP={measured['input_tp']}:measured_LRA={measured['input_lra']}:"
            f"measured_thresh={measured['input_thresh']}:offset={measured['target_offset']}:linear=true")
    path = OUTPUT / (name + ".ogg")
    run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-i", raw, "-af", before + "," + norm + ",alimiter=limit=0.74:level=false", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "4", path])
    decoded = WORK / (name + "-check.wav")
    run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-i", path, "-ar", str(RATE), "-ac", "1", decoded])
    values = read_wav(decoded)
    stat = loudness(run([FFMPEG, "-hide_banner", "-i", path, "-af", "loudnorm=I=-24:TP=-3:print_format=json", "-f", "null", "-"]))
    def rms_db(seq):
        return round(20 * math.log10(max(1e-9, math.sqrt(sum(x * x for x in seq) / max(1, len(seq))))), 2)
    result = {key: value for key, value in job.items() if key not in ("raw", "name", "target")}
    result.update({"file": path.name, "duration": round(len(values) / RATE, 3), "normalization_target_lufs": target,
                   "integrated_lufs": float(stat["input_i"]), "true_peak_dbtp": float(stat["input_tp"]),
                   "rms_dbfs": rms_db(values), "last_50ms_rms_dbfs": rms_db(values[-1200:]),
                   "first_50ms_rms_dbfs": rms_db(values[:1200]), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                   "prefer_loop": False})
    print(json.dumps({k: result[k] for k in ("file", "duration", "integrated_lufs", "true_peak_dbtp", "last_50ms_rms_dbfs")}), flush=True)
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-directory", type=Path, default=Path(os.environ["USERPROFILE"]) / "Videos/Captures")
    parser.add_argument("--crowd-only", action="store_true", help="Add/rebuild the four long reaction tails in an existing bank")
    args = parser.parse_args()
    OUTPUT.mkdir(parents=True, exist_ok=True); WORK.mkdir(parents=True, exist_ok=True)
    bank, source_info = {}, {}
    for name in SOURCES:
        path = args.source_directory / (name + ".mp4")
        decoded = WORK / (name + "-source.wav")
        run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-i", path, "-vn", "-ar", str(RATE), "-ac", "1", decoded])
        bank[name] = read_wav(decoded)
        source_info[name] = {"source": path.name, "source_sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "duration": len(bank[name]) / RATE}
    jobs = []
    def job(name, group, left, right, target, sources, synthesis, fi=1.1, fo=2.5):
        fades(left, right, fi, fo)
        path = WORK / (name + ".wav")
        write_wav(path, left, right)
        jobs.append({"name": name, "group": group, "raw": path, "target": target, "sources": sources,
                     "authored_synthesis": synthesis, "fade_in_seconds": fi, "fade_out_seconds": fo})
        print("arranged", name, flush=True)

    for index in range(0 if args.crowd_only else 8):
        rng = random.Random(39000 + index)
        duration = [26, 29, 32, 24, 28, 31, 27, 30][index]
        left, right = silence(duration)
        # Independent, wide, overlapping source tails. Avoid the loud cheer onset.
        events = []
        for passage in range(7):
            source_name = "crowd 2" if (passage + index) % 3 else "crowd"
            offset = rng.uniform(9.3, 12.2) if source_name == "crowd 2" else rng.uniform(5.9, 6.3)
            length = rng.uniform(2.7, 3.3) if source_name == "crowd 2" else 1.35
            at = passage * duration / 7 - .3
            place(left, right, sample(bank[source_name], offset, length, .04), at, .52, rng.uniform(-.7, .7), .7, rng.uniform(.92, 1.06))
            events.append({"file": source_name + ".mp4", "offset_seconds": round(offset, 3), "length_seconds": round(length, 3), "at_seconds": round(at, 3)})
        place(left, right, murmur(rng, duration, .13), 0, 1, -.3, .9)
        place(left, right, murmur(random.Random(39300 + index), duration, .13), 0, 1, .4, 1.2)
        job(f"ambient_bed_{index:02d}", "ambient_bed", left, right, -29, events,
            {"algorithm": "two independent low-passed voiced-noise air layers, asynchronous overlapping quiet crowd tails", "seed": 39000 + index}, fi=1.8, fo=3.2)

    # Explicit patterns: audience pulse, syncopated response, sparse slow claps,
    # drum calls, alternate accents, three-and-two, and last-bar fills.
    patterns = [[0, 1, 2, 3], [0, 1.5, 2, 3.5], [.5, 1.5, 2.5, 3.5], [0, .5, 2, 3],
                [0, .75, 1.5, 3], [0, 2], [0, 1, 2.5, 3], [.5, 2, 3.5],
                [0, .5, 1, 2, 3], [0, 1.5, 3], [1, 2, 3.5], [0, 1, 2, 2.75, 3.5]]
    for index in range(0 if args.crowd_only else 12):
        rng = random.Random(39400 + index)
        bpm = [96, 108, 116, 88, 104, 112, 100, 120, 92, 110, 102, 118][index]
        beat = 60 / bpm
        bars = [10, 11, 12][index % 3]
        duration = bars * 4 * beat + 2.3
        left, right = silence(duration)
        for bar in range(bars):
            # Supporters breathe and answer. Some bars omit percussion entirely.
            if bar % 5 == 3:
                continue
            attenuation = .55 if bar % 5 == 4 else .85
            for pulse in patterns[index]:
                at = .7 + (bar * 4 + pulse) * beat
                for person in range(4 + index % 4):
                    timing = at + rng.uniform(-.045, .065) + person * .003
                    place(left, right, clap(rng, rng.uniform(.48, .95)), timing, attenuation * .24,
                          rng.uniform(-.85, .85), .002)
            if index % 4 != 2:
                for pulse in ([0, 2] if index % 3 else [0, 1.5, 3]):
                    place(left, right, drum(rng, rng.uniform(.55, .9)), .7 + (bar * 4 + pulse) * beat + rng.uniform(-.022, .028),
                          .45 * attenuation, rng.uniform(-.3, .3), .003)
            if bar % 4 == 2:
                for pulse in [2.5, 3, 3.5]:
                    place(left, right, drum(rng, .55, True), .7 + (bar * 4 + pulse) * beat, .22, .15, .003)
        events = []
        # Three distinct recorded phrases provide the source texture; synthesized
        # patterns remain in the foreground, passages overlap with soft splices.
        for section in range(3):
            source_name = ["applause 2", "applause 3", "drums"][(index + section) % 3]
            offset = {"applause 2": [4.8, 10.2, 22.2, 29.5], "applause 3": [6.3, 10.0, 18.2, 22.3], "drums": [4.2, 8.4, 13, 17.2]}[source_name][(index + section) % 4]
            length = 4.1
            at = .3 + section * (duration - 5) / 3
            place(left, right, sample(bank[source_name], offset, length, .065), at, .34, rng.uniform(-.6, .6), .8)
            events.append({"file": source_name + ".mp4", "offset_seconds": offset, "length_seconds": length, "at_seconds": round(at, 3)})
        place(left, right, murmur(rng, duration, .025), 0, .7, 0, .8)
        job(f"rhythm_long_{index:02d}", "rhythm_long", left, right, -24, events,
            {"algorithm": "authored humanized multi-person noise claps, two resonant skin-drum voices, unique accent/rest/call-response arrangement", "seed": 39400 + index, "bpm": bpm, "bars": bars, "clap_pattern_beats": patterns[index]}, fi=1.0, fo=2.7)

    for index in range(0 if args.crowd_only else 6):
        rng = random.Random(39700 + index)
        duration = [11, 12.5, 14, 10.5, 13.5, 15][index]
        left, right = silence(duration)
        events = []
        for section in range(2):
            offset = 4.45 + ((index * 2 + section) % 5) * .72
            length = 3.6
            at = .4 + section * (duration - 4.3) * .65
            place(left, right, sample(bank["in between"], offset, length, .09), at, .55, -.22 if section == 0 else .22, .8)
            events.append({"file": "in between.mp4", "offset_seconds": round(offset, 3), "length_seconds": length, "at_seconds": round(at, 3)})
        beat = 60 / [108, 114, 104, 120, 110, 116][index]
        for pulse in range(int((duration - 2) / beat)):
            if pulse % 8 in (5, 6):
                continue
            at = .5 + pulse * beat
            place(left, right, drum(rng, .65, pulse % 3 == 2), at, .3, -.1, .003)
            if pulse % 2:
                for person in range(3):
                    place(left, right, clap(rng, .7), at + rng.uniform(-.04, .04), .16, rng.uniform(-.7, .7), .002)
        job(f"interlude_long_{index:02d}", "interlude_long", left, right, -24, events,
            {"algorithm": "source motif call and delayed response plus independently arranged clap/skin-drum rests", "seed": 39700 + index}, fi=.6, fo=2.2)

    for index in range(4):
        rng = random.Random(39900 + index)
        duration = [7.5, 8, 6.5, 7][index]
        left, right = silence(duration)
        source_name = "crowd 2" if index % 2 == 0 else "crowd"
        offset = [4.45, 4.78, 4.7, 4.9][index]
        length = 3.25 if source_name == "crowd 2" else 2.7
        place(left, right, sample(bank[source_name], offset, length, .12), .08, 1.0, -.1, .15)
        # The falling real cheer overlaps a diffuse real tail, then blends back
        # into the continuous hall bed instead of falling into digital silence.
        place(left, right, sample(bank["crowd 2"], 9.0 + index * .2, 4.3, .055), 2.0, .7, .25, 1.0)
        place(left, right, murmur(rng, duration, .1), 0, .6, -.35, .7)
        for clap_index in range(10):
            at = .3 + clap_index * .37 + rng.uniform(-.06, .09)
            place(left, right, clap(rng, rng.uniform(.4, .75)), at, .13 * (1 - at / duration), rng.uniform(-.8, .8), .002)
        job(f"crowd_long_{index:02d}", "crowd_long", left, right, -23,
            [{"file": source_name + ".mp4", "offset_seconds": offset, "length_seconds": length},
             {"file": "crowd 2.mp4", "offset_seconds": 9.0 + index * .2, "length_seconds": 4.3, "at_seconds": 2.0}],
            {"algorithm": "recorded home cheer overlapping quieter hall tail with declining authored applause and low air texture", "seed": 39900 + index}, fi=.12, fo=2.6)

    # The file includes silence and a click near6.65s. Retain the actual blow,
    # never the unrelated lead-in or recording controls. Four variants of ONE
    # recorded gesture are declared honestly; the source is not four recordings.
    for index, (offset, length, speed) in enumerate([] if args.crowd_only else [(6.97, 1.52, 1), (7.04, 1.2, 1.025), (6.98, 1.48, .98), (7.1, 1.27, 1.01)]):
        duration = length / speed + .18
        left, right = silence(duration)
        place(left, right, sample(bank["whislte"], offset, length, .11), .02, 1, 0, .035, speed)
        job(f"whistle_real_{index:02d}", "whistle_real", left, right, -23,
            [{"file": "whislte.mp4", "offset_seconds": offset, "length_seconds": length, "speed": speed}],
            {"type": "recorded_gesture_edit", "note": "four natural trim/speed edits of one real blow; no synthesized whistle"}, fi=.018, fo=.2)

    with ThreadPoolExecutor(max_workers=4) as executor:
        variants = list(executor.map(render, jobs))
    if args.crowd_only:
        previous = json.loads((OUTPUT / "manifest.json").read_text(encoding="utf-8"))
        variants = [item for item in previous["variants"] if item["group"] != "crowd_long"] + variants
    groups = {group: sum(item["group"] == group for item in variants) for group in sorted({x["group"] for x in variants})}
    manifest = {"schema": 1, "description": "Long-form dry stereo arena phrases: user recordings plus authored rhythmic/air synthesis, wide fades. Runtime Arena bus adds the room response.",
                "source_analysis": source_info, "variants": variants, "count": len(variants), "groups": groups,
                "whistle_analysis": {"unrelated_leadin_seconds": [0, 3.2], "silence_seconds": [3.2, 6.25], "excluded_click_seconds": [6.55, 6.85], "usable_blow_seconds": [6.97, 8.49], "independent_recorded_gestures": 1}}
    (OUTPUT / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({"count": len(variants), "groups": groups, "bytes": sum(p.stat().st_size for p in OUTPUT.glob("*.ogg")), "total_seconds": round(sum(x["duration"] for x in variants), 1), "maximum_true_peak_dbtp": max(x["true_peak_dbtp"] for x in variants)}), flush=True)


if __name__ == "__main__":
    main()
