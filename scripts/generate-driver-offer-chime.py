"""Write the admin dashboard's three-tone chime as mobile notification WAVs."""

import io
import math
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1] / "driver_app" / "driver_app"
SAMPLE_RATE = 44100
TONES = ((650, 0.00, 0.24), (820, 0.27, 0.24), (980, 0.54, 0.40))
DURATION = 0.98


def sample_at(time: float) -> float:
    for frequency, start, duration in TONES:
        elapsed = time - start
        if not 0 <= elapsed < duration:
            continue
        phase = (frequency * elapsed) % 1.0
        triangle = 4.0 * abs(phase - 0.5) - 1.0
        if elapsed < 0.01:
            envelope = 0.85 * elapsed / 0.01
        else:
            envelope = 0.85 * math.exp(
                math.log(0.001 / 0.85) * (elapsed - 0.01) / (duration - 0.01)
            )
        return triangle * envelope
    return 0.0


buffer = io.BytesIO()
with wave.open(buffer, "wb") as wav:
    wav.setnchannels(1)
    wav.setsampwidth(2)
    wav.setframerate(SAMPLE_RATE)
    wav.writeframes(
        b"".join(
            struct.pack("<h", round(32767 * sample_at(index / SAMPLE_RATE)))
            for index in range(round(DURATION * SAMPLE_RATE))
        )
    )

for path in (
    ROOT / "android" / "app" / "src" / "main" / "res" / "raw" / "driver_offer.wav",
    ROOT / "ios" / "Runner" / "driver_offer.wav",
):
    path.write_bytes(buffer.getvalue())
