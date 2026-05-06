import os
import sys
import subprocess
import json
import wave
import logging
import shutil
from pathlib import Path

# Use the app's logger
logger = logging.getLogger("odoo_sync")

# Attempt to import vosk. It will be in sys.path if added by backend.py
try:
    from vosk import Model, KaldiRecognizer
except ImportError:
    pass

def recognize_from_mic(verbose=True, stop_event=None, timeout=30, partial_callback=None, model_path=None):
    """
    Records audio using arecord and recognizes it using Vosk (offline).
    Returns (text, error_message).
    
    If stop_event is provided, it will stop recording when the event is set.
    """
    audio_path = None
    try:
        # Paths
        base_path = Path(__file__).parent.resolve()
        
        if model_path:
            model_path = Path(model_path)
        else:
            model_path = base_path / "model"
        
        if not model_path.exists():
            return None, f"Vosk model not found at {model_path}"

        # Load the model and initialize recognizer
        if verbose: logger.info(f"Loading Vosk model from {model_path} for live processing...")
        model = Model(str(model_path))
        rec = KaldiRecognizer(model, 16000)
        rec.SetWords(True)

        try:
            arecord_cmd = "arecord"
            use_ffmpeg = False
            
            for p in ["/usr/bin/arecord", "/bin/arecord", "/usr/local/bin/arecord"]:
                if os.path.exists(p):
                    arecord_cmd = p
                    break
            else:
                if shutil.which("ffmpeg"):
                    arecord_cmd = "ffmpeg"
                    use_ffmpeg = True
            
            logger.info(f"[VOICE] Executing live recording: {arecord_cmd}")
            
            if use_ffmpeg:
                # Output as s16le raw PCM to stdout ("-")
                cmd = [arecord_cmd, "-y", "-f", "alsa", "-i", "default", "-ac", "1", "-ar", "16000", "-f", "s16le", "-"]
            else:
                cmd = [arecord_cmd, "-f", "S16_LE", "-r", "16000", "-c", "1", "-"]
                
            import time
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
            
            start_time = time.time()
            max_duration = timeout
            
            results = []
            
            # Read from stdout in chunks
            # `read(4000)` might block until 4000 bytes are available, which is fine for live streams.
            while process.poll() is None:
                if stop_event and stop_event.is_set():
                    logger.info("[VOICE] Stop signal received, terminating record process.")
                    process.terminate()
                    break
                if (time.time() - start_time) > max_duration:
                    logger.info("[VOICE] Max duration reached, stopping.")
                    process.terminate()
                    break
                
                # We use a non-blocking-ish approach or just read. 
                # read 4000 bytes (125ms of 16kHz 16-bit mono)
                data = process.stdout.read(4000)
                if len(data) == 0:
                    break
                
                if rec.AcceptWaveform(data):
                    res = json.loads(rec.Result())
                    if res.get("text"):
                        results.append(res["text"])
                        if partial_callback:
                            combined = " ".join(results).strip()
                            partial_callback(combined)
                else:
                    res = json.loads(rec.PartialResult())
                    if res.get("partial"):
                        current_partial = res["partial"]
                        if partial_callback:
                            combined = " ".join(results + [current_partial]).strip()
                            partial_callback(combined)
            
            process.wait() # Ensure it's fully closed
                
        except (FileNotFoundError, Exception) as e:
            logger.exception(f"[VOICE] System error running {arecord_cmd}: {e}")
            return None, f"Recording tool error: {str(e)}"

        # Capture final bit of speech
        res = json.loads(rec.FinalResult())
        if res.get("text"):
            results.append(res["text"])

        text = " ".join(results).strip()
        if text:
            return text, None
        else:
            return None, "No speech detected"

    except Exception as e:
        return None, f"Deep Error: {str(e)}"

def list_microphones():
    """Returns a list of available microphone names."""
    # Since we use arecord's default, we just return a placeholder.
    return ["System Default (via arecord)"]
