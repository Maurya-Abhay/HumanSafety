"""Prediction Service - Emergency prediction"""
from typing import Dict, List

class PredictionService:
    """Predict emergency situations before they occur"""
    
    def __init__(self):
        self.prediction_history = []
        
    def predict_emergency(self,
                         final_risk_score: float,
                         accident_score: float,
                         behavior_score: float,
                         speed: float,
                         location_type: str,
                         recent_trends: Dict = None) -> Dict:
        """
        Predict emergency probability
        
        Combines all factors to estimate probability
        """
        
        # Base probability from risk score
        risk_probability = final_risk_score / 100
        
        # Accident contribution
        accident_probability = (accident_score / 100) * 0.5
        
        # Behavior contribution
        behavior_probability = (behavior_score / 100) * 0.2
        
        # Speed contribution
        speed_probability = 0
        if speed > 120:
            speed_probability = 0.3
        elif speed > 80:
            speed_probability = 0.15
        
        # Location contribution
        location_probability = 0.1 if location_type == "highway" else 0.05
        
        # Combine
        total_probability = min(1.0, 
            risk_probability * 0.4 +
            accident_probability * 0.3 +
            behavior_probability * 0.15 +
            speed_probability * 0.1 +
            location_probability * 0.05
        )
        
        # Classify emergency level
        if total_probability >= 0.8:
            emergency_level = "critical"
            time_window = "immediate"  # Immediate action
        elif total_probability >= 0.6:
            emergency_level = "high"
            time_window = "2-5 minutes"
        elif total_probability >= 0.4:
            emergency_level = "medium"
            time_window = "5-10 minutes"
        else:
            emergency_level = "low"
            time_window = "not_immediate"
        
        # Determine action
        should_trigger_sos = total_probability >= 0.7
        
        prediction = {
            "emergency_probability": round(total_probability, 3),
            "emergency_level": emergency_level,
            "should_trigger_sos": should_trigger_sos,
            "estimated_time_window": time_window,
            "contributing_factors": self._extract_contributing_factors(
                risk_probability, accident_probability, behavior_probability, speed_probability
            ),
            "recommendation": self._get_emergency_recommendation(emergency_level, should_trigger_sos)
        }
        
        self.prediction_history.append(prediction)
        return prediction
    
    def analyze_prediction_trend(self) -> Dict:
        """Analyze emergency prediction trend"""
        if len(self.prediction_history) < 3:
            return {"trend": "unknown"}
        
        recent = self.prediction_history[-10:]
        probabilities = [p["emergency_probability"] for p in recent]
        
        avg_probability = sum(probabilities) / len(probabilities)
        
        if probabilities[-1] > avg_probability:
            trend = "increasing"
        elif probabilities[-1] < avg_probability:
            trend = "decreasing"
        else:
            trend = "stable"
        
        sos_count = sum(1 for p in recent if p["should_trigger_sos"])
        
        return {
            "trend": trend,
            "average_probability": round(avg_probability, 3),
            "recent_probability": round(probabilities[-1], 3),
            "sos_triggers_in_recent": sos_count,
            "recurring_emergency": sos_count > 3
        }
    
    def _extract_contributing_factors(self,
                                     risk_prob: float,
                                     accident_prob: float,
                                     behavior_prob: float,
                                     speed_prob: float) -> List[str]:
        """Extract main contributing factors"""
        factors = []
        
        if risk_prob > 0.3:
            factors.append("High overall risk score")
        if accident_prob > 0.3:
            factors.append("Accident indicators present")
        if behavior_prob > 0.2:
            factors.append("Abnormal behavior detected")
        if speed_prob > 0.2:
            factors.append("Excessive speed")
        
        return factors if factors else ["Multiple minor factors"]
    
    def _get_emergency_recommendation(self, level: str, trigger_sos: bool) -> str:
        """Get emergency recommendation"""
        if trigger_sos:
            if level == "critical":
                return "🚨 CRITICAL: Trigger SOS immediately - Emergency appears imminent"
            else:
                return "⚠️ HIGH RISK: Prepare SOS - Monitor closely"
        elif level == "high":
            return "⚠️ HIGH PROBABILITY: Emergency likely - Stay alert"
        elif level == "medium":
            return "⚡ MODERATE RISK: Monitor situation"
        else:
            return "✅ LOW RISK: Normal operation"
