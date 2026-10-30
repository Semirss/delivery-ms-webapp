"""Create the normalized Android notification sound for a new driver offer."""

import math
import shutil
import struct
import wave
from pathlib import Path


RATE = 44_100
TARGET = (
    Path(__file__).resolve().parents[1]
    / "driver_app/driver_app/android/app/src/main/res/raw/driver_offer.wav"
)
TARGET.parent.mkdir(parents=True, exist_ok=True)


def sample_at(time: float) -> float:
    # Three two-tone bursts, with short gaps so the alert cuts through traffic noise.
    bursts = ((0.00, 0.32), (0.44, 0.32), (0.88, 0.54))
    value = 0.0
    for start, length in bursts:
        local = time - start
        if 0 <= local < length:
            envelope = min(1.0, local / 0.012, (length - local) / 0.035)
            value += envelope * (
                0.48 * math.sin(2 * math.pi * 740 * local)
                + 0.32 * math.sin(2 * math.pi * 988 * local)
                + 0.12 * math.sin(2 * math.pi * 1480 * local)
            )
    return max(-0.94, min(0.94, value))


with wave.open(str(TARGET), "wb") as output:
    output.setnchannels(1)
    output.setsampwidth(2)
    output.setframerate(RATE)
    for index in range(int(1.5 * RATE)):
        output.writeframesraw(struct.pack("<h", int(sample_at(index / RATE) * 32767)))

shutil.copyfile(TARGET, TARGET.parents[6] / "ios/Runner/driver_offer.wav")
