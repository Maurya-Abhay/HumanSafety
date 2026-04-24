"""Risk Scoring Engine - Comprehensive risk assessment"""
from typing import Dict, List
from utils.scoring import ScoringSystem

class RiskEngine:
    """Calculate comprehensive risk scores"""
    
    def __init__(self):
        self.risk_history = []
        
    def calculate_total_risk(self,
                            location_type: str,
                            speed: float,
                            movement_type: str,
                            is_anomalous_movement: bool,
                            behavior_score: float = 0,
                            audio_risk: float = 0) -> Dict:
        """
        Calculate total risk from all factors
        
        Returns:
            {
                "total_risk_score": float,
                "risk_level": str,
                "components": dict,
                "recommendations": list
            }
        """
        
        # Calculate component risks
        location_risk = ScoringSystem.calculate_location_risk_factor(location_type, speed)
        movement_risk = ScoringSystem.calculate_movement_risk(movement_type, is_anomalous_movement)
        behavior_risk = ScoringSystem.calculate_behavior_risk(behavior_score, 0)
        
        # Combine risks
        total_risk = ScoringSystem.calculate_combined_risk_score(
            accident_score=0,  # Will be 0 here, added in fusion
            location_risk=location_risk,
            movement_risk=movement_risk,
            behavior_risk=behavior_risk,
            audio_risk=audio_risk
        )
        
        risk_level = self._determine_risk_level(total_risk)
        
        result = {
            "total_risk_score": round(total_risk, 2),
            "risk_level": risk_level,
            "components": {
                "location_risk": round(location_risk, 2),
                "movement_risk": round(movement_risk, 2),
                "behavior_risk": round(behavior_risk, 2),
                "audio_risk": round(audio_risk, 2)
            },
            "primary_risk": self._identify_primary_risk(location_risk, movement_risk, behavior_risk),
            "recommendations": self._get_recommendations(risk_level, location_type, speed)
        }
        
        self.risk_history.append(result)
        return result
    
    def analyze_location_risk(self, location_type: str, speed: float, time_of_day: str = "day") -> Dict:
        """Analyze risk specific to location"""
        base_risk = ScoringSystem.calculate_location_risk_factor(location_type, speed)
        
        # Increase risk at night
        if time_of_day.lower() == "night":
            base_risk *= 1.2
        
        return {
            "location_type": location_type,
            "location_risk_score": round(min(100, base_risk), 2),
            "time_of_day": time_of_day,
            "risk_factors": self._get_location_factors(location_type, speed)
        }
    
    def analyze_speed_risk(self, speed: float, location_type: str = "unknown") -> Dict:
        """Analyze risk specific to speed"""
        # Define safe speeds per location
        safe_speeds = {
            "residential": 40,
            "city": 60,
            "highway": 100,
            "parking": 10,
            "unknown": 50
        }
        
        safe_speed = safe_speeds.get(location_type, 50)
        
        if speed <= safe_speed * 0.8:
            speed_risk = 10
            status = "safe"
        elif speed <= safe_speed:
            speed_risk = 20
            status = "normal"
        elif speed <= safe_speed * 1.2:
            speed_risk = 35
            status = "above_normal"
        else:
            speed_risk = 70
            status = "excessive"
        
        return {
            "current_speed": round(speed, 2),
            "safe_speed": safe_speed,
            "speed_risk_score": speed_risk,
            "status": status,
            "overspeed_percentage": round((speed - safe_speed) / safe_speed * 100, 1) if speed > safe_speed else 0
        }
    
    def get_risk_trend(self) -> Dict:
        """Analyze risk trend over time"""
        if len(self.risk_history) < 3:
            return {"trend": "unknown", "direction": "stable"}
        
        recent = self.risk_history[-10:]
        scores = [r["total_risk_score"] for r in recent]
        
        avg_score = sum(scores) / len(scores)
        first_avg = sum(scores[:5]) / 5
        last_avg = sum(scores[-5:]) / 5
        
        if last_avg > first_avg * 1.2:
            direction = "increasing"
        elif last_avg < first_avg * 0.8:
            direction = "decreasing"
        else:
            direction = "stable"
        
        return {
            "current_risk": round(scores[-1], 2),
            "average_risk": round(avg_score, 2),
            "direction": direction,
            "trend": f"Risk is {direction}"
        }
    
    def _determine_risk_level(self, score: float) -> str:
        """Map score to risk level"""
        if score < 25:
            return "minimal"
        elif score < 40:
            return "low"
        elif score < 60:
            return "medium"
        elif score < 80:
            return "high"
        else:
            return "critical"
    
    def _identify_primary_risk(self, location_risk: float, movement_risk: float, behavior_risk: float) -> str:
        """Identify primary risk factor"""
        risks = {
            "location": location_risk,
            "movement": movement_risk,
            "behavior": behavior_risk
        }
        return max(risks, key=risks.get)
    
    def _get_location_factors(self, location_type: str, speed: float) -> List[str]:
        """Get risk factors for location"""
        factors = []
        
        if location_type == "highway" and speed > 100:
            factors.append("High-speed highway driving")
        if location_type == "residential" and speed > 40:
            factors.append("Speeding in residential area")
        if location_type == "city" and speed > 60:
            factors.append("High speed in urban area")
        
        return factors if factors else ["Normal driving"]
    
    def _get_recommendations(self, risk_level: str, location_type: str, speed: float) -> List[str]:
        """Get safety recommendations"""
        recommendations = []
        
        if risk_level == "critical":
            recommendations.append("🚨 CRITICAL: Reduce speed immediately")
            recommendations.append("Consider pulling over")
        elif risk_level == "high":
            recommendations.append("⚠️ High risk: Drive carefully")
            recommendations.append("Increase following distance")
        elif risk_level == "medium":
            recommendations.append("⚡ Moderate risk: Stay alert")
        
        if location_type == "highway" and speed > 120:
            recommendations.append("Reduce speed on highway")
        
        if risk_level in ["low", "minimal"]:
            recommendations.append("✅ Safe driving conditions")
        
        return recommendations
