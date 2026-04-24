"""Audio module - Sound and crash detection"""
from typing import Dict, List
from utils.helpers import moving_average, detect_anomaly

class AudioModule:
    """Process audio signals for crash/distress detection"""
    
    AUDIO_THRESHOLD_CRASH = 85  # dB
    AUDIO_THRESHOLD_SCREAM = 90  # dB
    AUDIO_THRESHOLD_WARNING = 75  # dB
    
    def __init__(self):
        self.audio_history: List[float] = []
        self.max_history = 50
        
    def process_audio(self, sound_level: float, frequency_components: Dict = None) -> Dict:
        """Process audio input"""
        self.audio_history.append(sound_level)
        if len(self.audio_history) > self.max_history:
            self.audio_history.pop(0)
        
        avg_audio = moving_average(self.audio_history)
        is_anomalous = detect_anomaly(sound_level, avg_audio, threshold=1.5)
        
        return {
            "sound_level_db": round(sound_level, 1),
            "average_db": round(avg_audio, 1),
            "is_anomalous": is_anomalous,
            "audio_classification": self._classify_audio(sound_level),
            "potential_crash": self._detect_crash_sound(sound_level),
            "potential_distress": self._detect_distress(sound_level, frequency_components)
        }
    
    def detect_crash_sound(self) -> bool:
        """Detect potential crash/impact sound"""
        if len(self.audio_history) < 3:
            return False
        
        recent = self.audio_history[-5:]
        avg = moving_average(recent)
        max_level = max(recent)
        
        # Crash detection: sudden spike in sound
        return max_level > self.AUDIO_THRESHOLD_CRASH and max_level > avg * 1.3
    
    def detect_distress_sound(self) -> bool:
        """Detect potential distress/scream"""
        if len(self.audio_history) < 3:
            return False
        
        recent = self.audio_history[-5:]
        max_level = max(recent)
        
        # Scream detection: sustained high frequency sound
        return max_level > self.AUDIO_THRESHOLD_SCREAM
    
    def get_audio_trend(self) -> str:
        """Analyze audio trend"""
        if len(self.audio_history) < 5:
            return "unknown"
        
        first_half = moving_average(self.audio_history[:len(self.audio_history)//2])
        second_half = moving_average(self.audio_history[len(self.audio_history)//2:])
        
        if second_half > first_half * 1.2:
            return "increasing"
        elif second_half < first_half * 0.8:
            return "decreasing"
        else:
            return "stable"
    
    def _classify_audio(self, sound_level: float) -> str:
        """Classify audio level"""
        if sound_level < 50:
            return "quiet"
        elif sound_level < 75:
            return "normal"
        elif sound_level < 85:
            return "loud"
        else:
            return "very_loud"
    
    def _detect_crash_sound(self, sound_level: float) -> bool:
        """Simple crash sound detection"""
        if sound_level < self.AUDIO_THRESHOLD_CRASH:
            return False
        
        # Check for sustained high sound
        if len(self.audio_history) > 3:
            recent = self.audio_history[-3:]
            sustained = all(s > self.AUDIO_THRESHOLD_CRASH - 5 for s in recent)
            return sustained
        
        return True
    
    def _detect_distress(self, sound_level: float, frequency_components: Dict = None) -> bool:
        """Detect distress/scream"""
        if sound_level < self.AUDIO_THRESHOLD_SCREAM:
            return False
        
        # If frequency data available, check for human voice range
        if frequency_components and "peak_frequency" in frequency_components:
            # Human scream typically 500-2000 Hz
            peak_freq = frequency_components["peak_frequency"]
            if 500 < peak_freq < 2000:
                return True
        
        return sound_level > self.AUDIO_THRESHOLD_SCREAM
