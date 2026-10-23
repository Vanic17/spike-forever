"""Check shipped v39 audio bytes, decoded tails, headroom and source provenance."""
import array
import hashlib
import json
import math
from pathlib import Path
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / "assets/audio/arena39"
FFMPEG = ROOT / "tools/ffmpeg/ffmpeg-9.0.2-essentials_build/bin/ffmpeg.exe"
WORK = ROOT / ".runtime/audio39-validation"


def check() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((FOLDER / "manifest.json").read_text(encoding="utf-8"))
    variants = manifest["variants"]
    assert len(variants) == manifest["count"] >= 30
    expected = {"ambient_bed": 8, "rhythm_long": 12, "interlude_long": 6, "whistle_real": 4, "crowd_long": 4}
    assert all(manifest["groups"].get(k) == v for k, v in expected.items())
    hashes = set()
    pcm_hashes = set()
    for item in variants:
        name = item["file"]
        path = FOLDER / name
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        assert digest == item["sha256"], name + " hash mismatch"
        assert digest not in hashes, name + " duplicate encoded audio"
        hashes.add(digest)
        assert item["sources"] and item["authored_synthesis"], name + " missing provenance"
        assert item["true_peak_dbtp"] <= -2.9, name + " insufficient true-peak headroom"
        decoded = WORK / (path.stem + ".wav")
        subprocess.run([str(FFMPEG), "-hide_banner", "-loglevel", "error", "-y", "-i", str(path), "-ac", "1", "-ar", "24000", str(decoded)], check=True)
        with wave.open(str(decoded), "rb") as reader:
            assert reader.getframerate() == 24000
            pcm = array.array("h", reader.readframes(reader.getnframes()))
        pcm_digest = hashlib.sha256(pcm.tobytes()).hexdigest()
        assert pcm_digest not in pcm_hashes, name + " duplicate decoded content"
        pcm_hashes.add(pcm_digest)
        duration = len(pcm) / 24000
        assert abs(duration - item["duration"]) < .02, name + " incorrect duration"
        rms = lambda values: math.sqrt(sum(x*x for x in values) / len(values))
        tail = rms(pcm[-1200:])
        body = rms(pcm[len(pcm)//4:len(pcm)*3//4])
        assert tail < body * .08 + 1, name + " audible hard tail"
        if item["group"] != "whistle_real":
            assert item["fade_out_seconds"] >= 2.0, name + " fade too short"
        ranges = {"ambient_bed": (20, 40), "rhythm_long": (18, 35), "interlude_long": (8, 16), "whistle_real": (.5, 2.5)}
        low, high = ranges.get(item["group"], (3, 20))
        assert low <= duration <= high, name + " unsuitable duration"
    assert manifest["whistle_analysis"]["independent_recorded_gestures"] == 1
    print("PASS ARENA39 ASSETS", json.dumps({"count": len(variants), "groups": manifest["groups"], "total_seconds": round(sum(x["duration"] for x in variants), 1), "maximum_true_peak_dbtp": max(x["true_peak_dbtp"] for x in variants), "encoded_hashes_distinct": len(hashes), "decoded_pcm_hashes_distinct": len(pcm_hashes)}))


if __name__ == "__main__":
    check()
