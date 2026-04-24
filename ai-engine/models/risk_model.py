from typing import Dict, List
from utils.helpers import (
    normalize_score, classify_risk_level, 
    determine_location_risk, detect_pattern, calculate_confidence
)

class RiskModel:
    """Risk scoring and analysis system"""
    
    def __init__(self):
        self.SPEED_MULTIPLIER = 1.2  # Higher speed = higher risk
        self.INACTIVITY_RISK_THRESHOLD = 20000  # ms
        self.UNUSUAL_PATTERN_THRESHOLD = 0.7
        
    def calculate_speed_risk(self, speed: float, speed_limit: float = 120) -> float:
        """Calculate risk from speed"""
        if speed <= 0:
            return 0
        
        # Risk increases with speed above typical safe speeds
        if speed <= 50:
            risk = (speed / 50) * 10
        elif speed <= 100:
            risk = 10 + ((speed - 50) / 50) * 15
        else:
            # Risk increases significantly above 100
            risk = 25 + ((speed - 100) / speed_limit) * 25
        
        return min(50, risk)
    
    def calculate_movement_risk(self, movement_pattern: str, cv: float) -> float:
        """Calculate risk from movement pattern"""
        pattern_risk_map = {
            "stationary": 0,
            "stable": 5,
            "normal": 10,
            "erratic": 30,
            "chaotic": 50,
            "insufficient_data": 15,
        }
        
        base_risk = pattern_risk_map.get(movement_pattern, 15)
        
        # Increase risk if coefficient of variation is high
        if cv > self.UNUSUAL_PATTERN_THRESHOLD:
            base_risk += 10
        
        return min(50, base_risk)
    
    def calculate_location_risk(self, location_type: str, time_of_day: str = "day") -> float:
        """Calculate risk based on location and time"""
        base_risk = determine_location_risk(location_type) * 30
        
        # Increase risk at night
        if time_of_day.lower() == "night":
            base_risk *= 1.3
        
        return min(50, base_risk)
    
    def calculate_temporal_risk(self, inactivity_ms: float) -> float:
        """Calculate risk from inactivity patterns"""
        if inactivity_ms < self.INACTIVITY_RISK_THRESHOLD:
            return (inactivity_ms / self.INACTIVITY_RISK_THRESHOLD) * 15
        else:
            # High inactivity risk
            return 15 + (min(inactivity_ms - self.INACTIVITY_RISK_THRESHOLD, 30000) / 30000) * 20
    
    def calculate_total_risk(self,
                           speed: float,
                           movement_data: List[float],
                           location_type: str = "unknown",
                           inactivity_ms: float = 0,
                           time_of_day: str = "day") -> Dict:
        """
        Calculate comprehensive risk score
        
        Args:
            speed: Current speed (km/h)
            movement_data: List of recent acceleration values
            location_type: Type of location (highway/city/residential/rural)
            inactivity_ms: Time without movement
            time_of_day: "day" or "night"
        
        Returns:
            {
                "risk_score": float (0-100),
                "risk_level": str,
                "components": {...},
                "recommendations": [...]
            }
        """
        
        # Calculate component risks
        speed_risk = self.calculate_speed_risk(speed)
        
        # Analyze movement pattern
        movement_pattern, cv = detect_pattern(movement_data) if movement_data else ("insufficient_data", 0)
        movement_risk = self.calculate_movement_risk(movement_pattern, cv)
        
        location_risk = self.calculate_location_risk(location_type, time_of_day)
        temporal_risk = self.calculate_temporal_risk(inactivity_ms)
        
        # Weighted average
        weights = [0.35, 0.25, 0.25, 0.15]  # speed, movement, location, temporal
        total_risk = (
            speed_risk * weights[0] +
            movement_risk * weights[1] +
            location_risk * weights[2] +
            temporal_risk * weights[3]
        )
        
        normalized_score = normalize_score(total_risk)
        risk_level = classify_risk_level(normalized_score)
        
        # Calculate confidence
        confidence = calculate_confidence(len(movement_data) if movement_data else 0)
        
        return {
            "risk_score": round(normalized_score, 2),
            "risk_level": risk_level,
            "components": {
                "speed_risk": round(speed_risk, 2),
                "movement_risk": round(movement_risk, 2),
                "location_risk": round(location_risk, 2),
                "temporal_risk": round(temporal_risk, 2),
            },
            "movement_pattern": movement_pattern,
            "confidence": round(confidence, 2),
            "recommendations": self._get_safety_recommendations(
                normalized_score, movement_pattern, location_type
            )
        }
    
    def _get_safety_recommendations(self, risk_score: float, movement_pattern: str, location_type: str) -> List[str]:
        """Generate safety recommendations"""
        recommendations = []
        
        if risk_score >= 75:
            recommendations.append("CRITICAL: Reduce speed immediately")
            recommendations.append("Consider pulling over if safe to do so")
        elif risk_score >= 60:
            recommendations.append("High risk detected: Drive carefully")
            recommendations.append("Avoid sudden maneuvers")
        elif risk_score >= 40:
            recommendations.append("Moderate risk: Maintain alertness")
        
        if movement_pattern == "chaotic":
            recommendations.append("Unusual movement detected: Check vehicle status")
        
        if location_type == "highway" and risk_score >= 50:
            recommendations.append("Highway driving: Maintain safe distance")
        
        return recommendations if recommendations else ["✅ Safe driving conditions"]
