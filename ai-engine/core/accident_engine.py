"""Accident Detection Engine - Core intelligence for crash detection"""
from typing import Dict, List
from utils.scoring import ScoringSystem

class AccidentEngine:
    """Real-time accident detection"""
    
    def __init__(self):
        self.accident_history = []
        
    def analyze_accident(self,
                        accel_magnitude: float,
                        speed_drop_pct: float,
                        inactivity_ms: float,
                        audio_level: float = 0,
                        screen_off: bool = False) -> Dict:
        """
        Analyze potential accident
        
        Returns:
            {
                "accident_score": float,
                "risk_level": str,
                "trigger_alert": bool,
                "components": dict,
                "recommendation": str
            }
        """
        
        # Calculate component scores
        components = {
            "impact": ScoringSystem.calculate_impact_score(accel_magnitude),
            "speed_drop": ScoringSystem.calculate_speed_drop_score(speed_drop_pct),
            "inactivity": ScoringSystem.calculate_inactivity_score(inactivity_ms),
            "audio": ScoringSystem.calculate_audio_score(audio_level),
            "screen": ScoringSystem.calculate_screen_score(screen_off)
        }
        
        # Calculate total score
        accident_score = ScoringSystem.calculate_combined_accident_score(components)
        
        # Determine risk level and alert status
        risk_level = self._determine_risk_level(accident_score)
        trigger_alert = accident_score >= 60
        
        # Get recommendation
        recommendation = self._get_recommendation(risk_level, trigger_alert, components)
        
        result = {
            "accident_score": round(accident_score, 2),
            "risk_level": risk_level,
            "trigger_alert": trigger_alert,
            "components": {k: round(v, 2) for k, v in components.items()},
            "confidence": self._calculate_confidence(components),
            "recommendation": recommendation,
            "contributing_factors": self._extract_factors(components)
        }
        
        self.accident_history.append(result)
        return result
    
    def detect_patterns(self) -> Dict:
        """Detect patterns from accident history"""
        if len(self.accident_history) < 3:
            return {"pattern": "insufficient_data"}
        
        recent = self.accident_history[-10:]
        scores = [a["accident_score"] for a in recent]
        alerts = [a["trigger_alert"] for a in recent]
        
        avg_score = sum(scores) / len(scores)
        alert_frequency = sum(alerts) / len(alerts)
        
        return {
            "average_score": round(avg_score, 2),
            "alert_frequency": round(alert_frequency, 2),
            "trend": "increasing" if scores[-1] > avg_score else "decreasing",
            "recurrence": "high" if alert_frequency > 0.5 else "low"
        }
    
    def _determine_risk_level(self, score: float) -> str:
        """Map score to risk level"""
        if score < 30:
            return "low"
        elif score < 60:
            return "medium"
        elif score < 85:
            return "high"
        else:
            return "critical"
    
    def _calculate_confidence(self, components: Dict) -> float:
        """Calculate confidence in detection"""
        # More components with significant values = higher confidence
        significant = sum(1 for v in components.values() if v > 5)
        confidence = min(100, (significant / len(components)) * 100)
        return round(confidence, 2)
    
    def _extract_factors(self, components: Dict) -> List[str]:
        """Extract main contributing factors"""
        factors = []
        
        if components["impact"] > 15:
            factors.append("High Impact Detected")
        if components["speed_drop"] > 15:
            factors.append("Sudden Speed Drop")
        if components["inactivity"] > 10:
            factors.append("Extended Inactivity")
        if components["audio"] > 10:
            factors.append("Impact Sound Detected")
        if components["screen"] > 0:
            factors.append("Screen Inactive")
        
        return factors if factors else ["Minor Movement"]
    
    def _get_recommendation(self, risk_level: str, trigger_alert: bool, components: Dict) -> str:
        """Get recommendation based on analysis"""
        if trigger_alert:
            if components["impact"] > 25:
                return "🚨 CRITICAL: High impact detected - Trigger emergency SOS immediately"
            else:
                return "⚠️ HIGH RISK: Potential accident - Prepare to alert contacts"
        elif risk_level == "high":
            return "⚡ MEDIUM-HIGH RISK: Monitor carefully"
        elif risk_level == "medium":
            return "⚠️ MODERATE RISK: Stay alert"
        else:
            return "✅ LOW RISK: Safe"
