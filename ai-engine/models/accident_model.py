from typing import Dict, List
from utils.helpers import (
    calculate_magnitude, calculate_velocity_drop, 
    normalize_score, classify_risk_level, detect_pattern
)

class AccidentModel:
    """Rule-based accident detection model"""
    
    def __init__(self):
        self.IMPACT_THRESHOLD = 15.0  # m/s² (1.5G)
        self.SPEED_DROP_THRESHOLD = 50  # percentage
        self.INACTIVITY_THRESHOLD = 30000  # milliseconds
        self.SOUND_THRESHOLD = 80  # dB
        
    def calculate_impact_score(self, acceleration_magnitude: float) -> float:
        """Calculate impact score from acceleration"""
        if acceleration_magnitude < self.IMPACT_THRESHOLD:
            return 0
        
        # Score increases with acceleration above threshold
        # Max score of 30 at 20+ m/s²
        excess = acceleration_magnitude - self.IMPACT_THRESHOLD
        score = (excess / 5) * 30
        
        return min(30, score)
    
    def calculate_speed_drop_score(self, current_speed: float, previous_speed: float) -> float:
        """Calculate score from sudden speed drop"""
        if previous_speed == 0:
            return 0
        
        drop_percentage = ((previous_speed - current_speed) / previous_speed) * 100
        
        if drop_percentage < self.SPEED_DROP_THRESHOLD:
            return 0
        
        # Score increases with drop percentage
        # Max score of 25 at 100% drop
        score = (drop_percentage / 100) * 25
        
        return min(25, score)
    
    def calculate_inactivity_score(self, inactivity_ms: float) -> float:
        """Calculate score from user inactivity"""
        if inactivity_ms < self.INACTIVITY_THRESHOLD:
            return 0
        
        # Score increases with inactivity time
        # Max score of 20 at 60+ seconds
        excess = (inactivity_ms - self.INACTIVITY_THRESHOLD) / 1000  # Convert to seconds
        score = (excess / 30) * 20
        
        return min(20, score)
    
    def calculate_sound_score(self, sound_level: float) -> float:
        """Calculate score from high sound levels"""
        if sound_level < self.SOUND_THRESHOLD:
            return 0
        
        # Score increases with sound level
        # Max score of 15 at 130+ dB
        excess = sound_level - self.SOUND_THRESHOLD
        score = (excess / 50) * 15
        
        return min(15, score)
    
    def analyze_accident(self, 
                        acceleration: Dict[str, float],
                        current_speed: float,
                        previous_speed: float,
                        inactivity_ms: float,
                        sound_level: float = 0) -> Dict:
        """
        Main accident detection function
        
        Args:
            acceleration: {"x": float, "y": float, "z": float}
            current_speed: Current vehicle speed (km/h)
            previous_speed: Previous vehicle speed (km/h)
            inactivity_ms: Time without movement (milliseconds)
            sound_level: Detected sound level (dB)
        
        Returns:
            {
                "score": float (0-100),
                "risk_level": str (low/medium/high),
                "trigger_alert": bool,
                "components": {...},
                "confidence": float
            }
        """
        
        # Calculate individual component scores
        accel_magnitude = calculate_magnitude(
            acceleration.get("x", 0),
            acceleration.get("y", 0),
            acceleration.get("z", 0)
        )
        
        impact_score = self.calculate_impact_score(accel_magnitude)
        speed_drop_score = self.calculate_speed_drop_score(current_speed, previous_speed)
        inactivity_score = self.calculate_inactivity_score(inactivity_ms)
        sound_score = self.calculate_sound_score(sound_level)
        
        # Calculate total score
        total_score = impact_score + speed_drop_score + inactivity_score + sound_score
        normalized_score = normalize_score(total_score)
        
        # Determine risk level
        risk_level = classify_risk_level(normalized_score)
        
        # Trigger alert if score > 60
        trigger_alert = normalized_score >= 60
        
        return {
            "score": round(normalized_score, 2),
            "risk_level": risk_level,
            "trigger_alert": trigger_alert,
            "components": {
                "impact_score": round(impact_score, 2),
                "speed_drop_score": round(speed_drop_score, 2),
                "inactivity_score": round(inactivity_score, 2),
                "sound_score": round(sound_score, 2),
            },
            "confidence": 0.85,
            "recommendation": self._get_recommendation(risk_level, trigger_alert)
        }
    
    def _get_recommendation(self, risk_level: str, trigger_alert: bool) -> str:
        """Get safety recommendation based on analysis"""
        if trigger_alert:
            return "🚨 EMERGENCY: Trigger SOS immediately"
        elif risk_level == "high":
            return "⚠️ HIGH RISK: Monitor closely"
        elif risk_level == "medium":
            return "⚡ MEDIUM RISK: Caution advised"
        else:
            return "✅ LOW RISK: All clear"
