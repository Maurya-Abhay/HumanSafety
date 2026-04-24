"""Scoring system for various risk calculations"""
from typing import Dict

class ScoringSystem:
    """Comprehensive scoring algorithms"""
    
    # Accident Detection Weights
    IMPACT_THRESHOLD = 15.0  # m/s²
    IMPACT_WEIGHT = 30
    
    SPEED_DROP_THRESHOLD = 50  # %
    SPEED_DROP_WEIGHT = 25
    
    INACTIVITY_THRESHOLD = 30000  # ms
    INACTIVITY_WEIGHT = 20
    
    AUDIO_THRESHOLD = 80  # dB
    AUDIO_WEIGHT = 15
    
    SCREEN_STATE_WEIGHT = 10
    
    # Risk Level Thresholds
    LOW_RISK_THRESHOLD = 30
    MEDIUM_RISK_THRESHOLD = 60
    HIGH_RISK_THRESHOLD = 85
    
    @staticmethod
    def calculate_impact_score(accel_magnitude: float) -> float:
        """Score from acceleration impact"""
        if accel_magnitude < ScoringSystem.IMPACT_THRESHOLD:
            return 0
        
        excess = accel_magnitude - ScoringSystem.IMPACT_THRESHOLD
        score = (excess / 5) * ScoringSystem.IMPACT_WEIGHT
        
        return min(ScoringSystem.IMPACT_WEIGHT, score)
    
    @staticmethod
    def calculate_speed_drop_score(speed_drop_pct: float) -> float:
        """Score from speed drop"""
        if speed_drop_pct < ScoringSystem.SPEED_DROP_THRESHOLD:
            return 0
        
        excess = speed_drop_pct - ScoringSystem.SPEED_DROP_THRESHOLD
        score = (excess / 50) * ScoringSystem.SPEED_DROP_WEIGHT
        
        return min(ScoringSystem.SPEED_DROP_WEIGHT, score)
    
    @staticmethod
    def calculate_inactivity_score(inactivity_ms: float) -> float:
        """Score from inactivity"""
        if inactivity_ms < ScoringSystem.INACTIVITY_THRESHOLD:
            return (inactivity_ms / ScoringSystem.INACTIVITY_THRESHOLD) * ScoringSystem.INACTIVITY_WEIGHT
        
        excess = (inactivity_ms - ScoringSystem.INACTIVITY_THRESHOLD) / 1000
        score = ScoringSystem.INACTIVITY_WEIGHT + (min(excess, 30) / 30) * 10
        
        return min(ScoringSystem.INACTIVITY_WEIGHT + 10, score)
    
    @staticmethod
    def calculate_audio_score(sound_level: float) -> float:
        """Score from sound level"""
        if sound_level < ScoringSystem.AUDIO_THRESHOLD:
            return 0
        
        excess = sound_level - ScoringSystem.AUDIO_THRESHOLD
        score = (excess / 50) * ScoringSystem.AUDIO_WEIGHT
        
        return min(ScoringSystem.AUDIO_WEIGHT, score)
    
    @staticmethod
    def calculate_screen_score(is_screen_off: bool) -> float:
        """Score if screen is inactive"""
        return ScoringSystem.SCREEN_STATE_WEIGHT if is_screen_off else 0
    
    @staticmethod
    def calculate_combined_accident_score(components: Dict[str, float]) -> float:
        """Combine all accident detection components"""
        total = sum(components.values())
        return min(100, total)
    
    @staticmethod
    def calculate_location_risk_factor(location_type: str, speed: float) -> float:
        """Risk factor based on location and speed"""
        base_risk = {
            "highway": 0.8,
            "city": 0.5,
            "residential": 0.3,
            "parking": 0.1,
            "unknown": 0.5
        }.get(location_type.lower(), 0.5)
        
        # Higher speed increases risk
        speed_multiplier = 1 + (min(speed, 150) / 150) * 0.5
        
        return min(100, base_risk * speed_multiplier * 100)
    
    @staticmethod
    def calculate_movement_risk(movement_type: str, is_anomalous: bool) -> float:
        """Risk from movement type and anomalies"""
        base_risk = {
            "walking": 10,
            "stationary": 5,
            "driving_normal": 15,
            "driving_aggressive": 40,
            "unknown": 20
        }.get(movement_type, 20)
        
        if is_anomalous:
            base_risk += 20
        
        return min(100, base_risk)
    
    @staticmethod
    def calculate_behavior_risk(behavior_deviation: float, time_since_incident: int) -> float:
        """Risk from abnormal behavior"""
        base_risk = min(100, behavior_deviation * 100)
        
        # Risk decreases over time
        time_factor = max(0.3, 1.0 - (time_since_incident / 60000))  # 1 minute decay
        
        return base_risk * time_factor
    
    @staticmethod
    def calculate_combined_risk_score(
        accident_score: float,
        location_risk: float,
        movement_risk: float,
        behavior_risk: float,
        audio_risk: float = 0
    ) -> float:
        """Combine all risk factors with weighted average"""
        weights = {
            "accident": 0.4,
            "location": 0.2,
            "movement": 0.15,
            "behavior": 0.15,
            "audio": 0.1
        }
        
        combined = (
            accident_score * weights["accident"] +
            location_risk * weights["location"] +
            movement_risk * weights["movement"] +
            behavior_risk * weights["behavior"] +
            audio_risk * weights["audio"]
        )
        
        return min(100, combined)
