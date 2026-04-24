from typing import Dict, List
from models.accident_model import AccidentModel
from models.risk_model import RiskModel
from utils.helpers import normalize_score

class EmergencyPredictor:
    """Predict emergency situations before they occur"""
    
    def __init__(self):
        self.accident_model = AccidentModel()
        self.risk_model = RiskModel()
        self.prediction_history = []
        
    def predict_emergency(self,
                         sensor_data: Dict,
                         speed_history: List[float],
                         location_type: str = "unknown",
                         inactivity_ms: float = 0) -> Dict:
        """
        Predict emergency probability using multiple signals
        
        Args:
            sensor_data: {
                "acceleration": {"x", "y", "z"},
                "gyroscope": {"x", "y", "z"},
                "speed": float,
                "previous_speed": float,
                "sound_level": float (optional)
            }
            speed_history: List of previous speeds
            location_type: Current location type
            inactivity_ms: Time without movement
        
        Returns:
            {
                "emergency_probability": float (0-1),
                "emergency_risk_level": str,
                "should_trigger_alert": bool,
                "contributing_factors": [...],
                "time_to_impact": float (seconds, estimated)
            }
        """
        
        # Get accident detection score
        accident_data = self.accident_model.analyze_accident(
            acceleration=sensor_data.get("acceleration", {"x": 0, "y": 0, "z": 0}),
            current_speed=sensor_data.get("speed", 0),
            previous_speed=sensor_data.get("previous_speed", 0),
            inactivity_ms=inactivity_ms,
            sound_level=sensor_data.get("sound_level", 0)
        )
        
        # Get risk score
        risk_data = self.risk_model.calculate_total_risk(
            speed=sensor_data.get("speed", 0),
            movement_data=speed_history,
            location_type=location_type,
            inactivity_ms=inactivity_ms
        )
        
        # Calculate emergency probability
        # Weight accident detection heavily
        accident_probability = (accident_data["score"] / 100) * 0.6
        risk_probability = (risk_data["risk_score"] / 100) * 0.4
        
        total_probability = accident_probability + risk_probability
        emergency_probability = min(1.0, total_probability)
        
        # Determine emergency risk level
        if emergency_probability >= 0.8:
            emergency_risk_level = "critical"
        elif emergency_probability >= 0.6:
            emergency_risk_level = "high"
        elif emergency_probability >= 0.4:
            emergency_risk_level = "medium"
        else:
            emergency_risk_level = "low"
        
        # Determine if alert should be triggered
        should_trigger = emergency_probability >= 0.7 or accident_data["trigger_alert"]
        
        # Extract contributing factors
        contributing_factors = self._extract_factors(accident_data, risk_data)
        
        # Estimate time to impact
        time_to_impact = self._estimate_time_to_impact(sensor_data, contributing_factors)
        
        prediction_result = {
            "emergency_probability": round(emergency_probability, 3),
            "emergency_risk_level": emergency_risk_level,
            "should_trigger_alert": should_trigger,
            "contributing_factors": contributing_factors,
            "time_to_impact_seconds": round(time_to_impact, 2),
            "accident_score": accident_data["score"],
            "risk_score": risk_data["risk_score"],
            "confidence": round((accident_data["confidence"] + risk_data["confidence"]) / 2, 2),
            "recommendation": self._get_prediction_recommendation(
                emergency_probability, emergency_risk_level, contributing_factors
            )
        }
        
        self.prediction_history.append(prediction_result)
        return prediction_result
    
    def _extract_factors(self, accident_data: Dict, risk_data: Dict) -> List[str]:
        """Extract main contributing factors"""
        factors = []
        
        # From accident detection
        if accident_data["components"]["impact_score"] > 15:
            factors.append("High impact detected")
        if accident_data["components"]["speed_drop_score"] > 15:
            factors.append("Sudden speed drop")
        if accident_data["components"]["inactivity_score"] > 10:
            factors.append("Extended inactivity")
        if accident_data["components"]["sound_score"] > 5:
            factors.append("Loud impact sound")
        
        # From risk analysis
        if risk_data["components"]["speed_risk"] > 30:
            factors.append("High speed detected")
        if risk_data["movement_pattern"] in ["chaotic", "erratic"]:
            factors.append(f"Erratic movement pattern ({risk_data['movement_pattern']})")
        
        return factors if factors else ["No critical factors detected"]
    
    def _estimate_time_to_impact(self, sensor_data: Dict, factors: List[str]) -> float:
        """Estimate time to potential impact"""
        speed = sensor_data.get("speed", 0)
        accel_magnitude = (
            sensor_data.get("acceleration", {}).get("x", 0)**2 +
            sensor_data.get("acceleration", {}).get("y", 0)**2 +
            sensor_data.get("acceleration", {}).get("z", 0)**2
        ) ** 0.5
        
        # If high acceleration/deceleration, estimate braking time
        if accel_magnitude > 10:
            # Assume emergency braking
            # time = speed / deceleration
            deceleration = accel_magnitude  # Approximate
            if deceleration > 0:
                # Convert speed from km/h to m/s
                speed_ms = speed / 3.6
                time_to_stop = speed_ms / deceleration
                return max(0.1, min(5, time_to_stop))
        
        # If moving at high speed with suspicious factors
        if speed > 80 and len(factors) > 2:
            return 2.5
        
        return 5.0  # Default estimate
    
    def _get_prediction_recommendation(self, probability: float, risk_level: str, factors: List[str]) -> str:
        """Get recommendation based on prediction"""
        if probability >= 0.8:
            return "🚨 EMERGENCY IMMINENT: Trigger SOS and alert all contacts NOW"
        elif probability >= 0.6:
            return f"⚠️ HIGH EMERGENCY RISK: {risk_level} - Prepare for emergency response"
        elif probability >= 0.4:
            return f"⚡ EMERGENCY POSSIBLE: {risk_level} risk - Monitor situation closely"
        else:
            return "✅ SAFE: No emergency predicted at this time"
    
    def get_prediction_trend(self) -> Dict:
        """Analyze trend of emergency predictions"""
        if len(self.prediction_history) < 3:
            return {"trend": "insufficient_data", "avg_probability": 0}
        
        recent = self.prediction_history[-10:]
        avg_probability = sum(p["emergency_probability"] for p in recent) / len(recent)
        
        # Check if trend is improving or deteriorating
        first_half_avg = sum(p["emergency_probability"] for p in recent[:5]) / 5
        second_half_avg = sum(p["emergency_probability"] for p in recent[5:]) / 5
        
        if second_half_avg < first_half_avg:
            trend = "improving"
        elif second_half_avg > first_half_avg:
            trend = "deteriorating"
        else:
            trend = "stable"
        
        return {
            "trend": trend,
            "avg_probability": round(avg_probability, 3),
            "recent_count": len(recent)
        }
