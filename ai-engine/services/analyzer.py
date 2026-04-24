from typing import Dict, List
from models.accident_model import AccidentModel
from models.risk_model import RiskModel
from utils.helpers import normalize_score, classify_risk_level

class BehaviorAnalyzer:
    """Analyze driver/user behavior patterns"""
    
    def __init__(self):
        self.accident_model = AccidentModel()
        self.risk_model = RiskModel()
        self.behavior_history = []
        self.MAX_HISTORY = 100
        
    def analyze_behavior(self,
                        acceleration: Dict[str, float],
                        gyroscope: Dict[str, float],
                        speed: float,
                        previous_speed: float,
                        location_type: str = "unknown") -> Dict:
        """
        Comprehensive behavior analysis
        
        Args:
            acceleration: {"x": float, "y": float, "z": float}
            gyroscope: {"x": float, "y": float, "z": float}
            speed: Current speed
            previous_speed: Previous speed
            location_type: Location type
        
        Returns:
            {
                "behavior_status": str (normal/suspicious/critical),
                "anomaly_score": float,
                "indicators": {...}
            }
        """
        
        indicators = self._analyze_indicators(
            acceleration, gyroscope, speed, previous_speed
        )
        
        anomaly_score = self._calculate_anomaly_score(indicators)
        behavior_status = self._classify_behavior(anomaly_score)
        
        # Store in history
        self._update_history({
            "indicators": indicators,
            "anomaly_score": anomaly_score,
            "status": behavior_status
        })
        
        return {
            "behavior_status": behavior_status,
            "anomaly_score": round(anomaly_score, 2),
            "indicators": indicators,
            "pattern_trend": self._analyze_trend(),
            "alert_required": behavior_status == "critical"
        }
    
    def _analyze_indicators(self,
                           acceleration: Dict[str, float],
                           gyroscope: Dict[str, float],
                           speed: float,
                           previous_speed: float) -> Dict:
        """Analyze various behavior indicators"""
        
        # Acceleration analysis
        accel_x = acceleration.get("x", 0)
        accel_y = acceleration.get("y", 0)
        accel_z = acceleration.get("z", 0)
        accel_magnitude = (accel_x**2 + accel_y**2 + accel_z**2) ** 0.5
        
        # Rotation analysis
        gyro_magnitude = (
            gyroscope.get("x", 0)**2 +
            gyroscope.get("y", 0)**2 +
            gyroscope.get("z", 0)**2
        ) ** 0.5
        
        # Speed analysis
        speed_change = abs(speed - previous_speed)
        sudden_stop = speed_change > 20 and speed < 5
        rapid_acceleration = accel_magnitude > 8
        sharp_turn = gyro_magnitude > 2
        
        return {
            "acceleration_magnitude": round(accel_magnitude, 2),
            "rotation_magnitude": round(gyro_magnitude, 2),
            "speed_change": round(speed_change, 2),
            "sudden_stop": sudden_stop,
            "rapid_acceleration": rapid_acceleration,
            "sharp_turn": sharp_turn,
        }
    
    def _calculate_anomaly_score(self, indicators: Dict) -> float:
        """Calculate anomaly score from indicators"""
        score = 0
        
        if indicators["sudden_stop"]:
            score += 25
        if indicators["rapid_acceleration"]:
            score += 20
        if indicators["sharp_turn"]:
            score += 15
        
        if indicators["acceleration_magnitude"] > 10:
            score += 15
        if indicators["rotation_magnitude"] > 3:
            score += 10
        if indicators["speed_change"] > 30:
            score += 10
        
        return normalize_score(score)
    
    def _classify_behavior(self, anomaly_score: float) -> str:
        """Classify behavior based on anomaly score"""
        if anomaly_score < 25:
            return "normal"
        elif anomaly_score < 60:
            return "suspicious"
        else:
            return "critical"
    
    def _update_history(self, behavior_data: Dict) -> None:
        """Update behavior history"""
        self.behavior_history.append(behavior_data)
        if len(self.behavior_history) > self.MAX_HISTORY:
            self.behavior_history.pop(0)
    
    def _analyze_trend(self) -> str:
        """Analyze behavior trend from history"""
        if len(self.behavior_history) < 5:
            return "insufficient_data"
        
        recent = self.behavior_history[-5:]
        avg_anomaly = sum(b["anomaly_score"] for b in recent) / 5
        
        if avg_anomaly < 20:
            return "improving"
        elif avg_anomaly > 50:
            return "deteriorating"
        else:
            return "stable"
