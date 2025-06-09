#!/bin/bash
curl -X POST http://127.0.0.1:5000/transcribe \
  -F "audio=@../data/audio_samples/sample.wav"
