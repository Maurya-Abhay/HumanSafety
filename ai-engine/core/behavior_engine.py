"""Behavior Learning Engine - User pattern analysis"""
from typing import Dict, List
from utils.helpers import moving_average, detect_anomaly

class BehaviorEngine:
    """Analyze and learn user behavior patterns"""
    
    def __init__(self):
        self.behavior_history = []
        self.user_profile = {
            "avg_speed": 50,
            "avg_accel": 3.0,
            "common_locations": [],
            "night_driving": False
        }
        
    def analyze_behavior(self,
                        current_speed: float,
                        accel_magnitude: float,
                        location_type: str,
                        hour_of_day: int = 12) -> Dict:
        """
        Analyze current behavior against user profile
        
        Returns:
            {
                "behavior_status": str,
                "deviation_score": float,
                "is_anomalous": bool,
                "behavior_insights": dict
            }
        """
        
        # Calculate deviation from normal
        speed_deviation = self._calculate_deviation(current_speed, self.user_profile["avg_speed"])
        accel_deviation = self._calculate_deviation(accel_magnitude, self.user_profile["avg_accel"])
        
        # Combine deviations
        total_deviation = (speed_deviation + accel_deviation) / 2
        
        # Detect anomaly
        is_anomalous = total_deviation > 1.5
        
        # Classify behavior status
        behavior_status = self._classify_behavior(total_deviation, is_anomalous)
        
        # Store in history
        behavior_record = {
            "speed": current_speed,
            "accel": accel_magnitude,
            "location": location_type,
            "hour": hour_of_day,
            "deviation": total_deviation,
            "status": behavior_status,
            "anomalous": is_anomalous
        }
        self.behavior_history.append(behavior_record)
        
        return {
            "behavior_status": behavior_status,
            "deviation_score": round(total_deviation, 2),
            "is_anomalous": is_anomalous,
            "deviations": {
                "speed_deviation": round(speed_deviation, 2),
                "accel_deviation": round(accel_deviation, 2)
            },
            "behavior_insights": self._get_insights(behavior_status, total_deviation)
        }
    
    def detect_aggressive_driving(self,
                                 accel_magnitude: float,
                                 speed: float,
                                 speed_changes: List[float]) -> Dict:
        """Detect aggressive driving patterns"""
        
        aggressive_score = 0
        indicators = []
        
        # High acceleration
        if accel_magnitude > 8:
            aggressive_score += 20
            indicators.append("Rapid acceleration")
        
        # Speed variations
        if len(speed_changes) > 2:
            avg_change = moving_average(speed_changes[-5:]) if len(speed_changes) >= 5 else moving_average(speed_changes)
            if avg_change > 15:
                aggressive_score += 20
                indicators.append("Frequent speed changes")
        
        # Excessive speed
        if speed > 100:
            aggressive_score += 20
            indicators.append("High speed")
        
        # Normalize
        aggressive_score = min(100, aggressive_score)
        
        return {
            "aggressive_driving_score": aggressive_score,
            "is_aggressive": aggressive_score > 50,
            "indicators": indicators,
            "recommendation": self._aggressive_driving_recommendation(aggressive_score)
        }
    
    def update_user_profile(self, speed: float, accel: float) -> None:
        """Update user profile with new data"""
        # Exponential moving average (EMA)
        alpha = 0.1  # Smoothing factor
        self.user_profile["avg_speed"] = (1 - alpha) * self.user_profile["avg_speed"] + alpha * speed
        self.user_profile["avg_accel"] = (1 - alpha) * self.user_profile["avg_accel"] + alpha * accel
    
    def get_behavior_summary(self) -> Dict:
        """Get summary of user behavior"""
        if not self.behavior_history:
            return {"summary": "No data"}
        
        recent = self.behavior_history[-50:]
        statuses = [b["status"] for b in recent]
        anomalies = sum(1 for b in recent if b["anomalous"])
        
        normal_pct = (statuses.count("normal") / len(statuses)) * 100 if statuses else 0
        suspicious_pct = (statuses.count("suspicious") / len(statuses)) * 100 if statuses else 0
        
        return {
            "total_sessions": len(self.behavior_history),
            "normal_behavior_pct": round(normal_pct, 1),
            "suspicious_behavior_pct": round(suspicious_pct, 1),
            "anomaly_count": anomalies,
            "anomaly_frequency": round((anomalies / len(recent)) * 100, 1) if recent else 0,
            "user_profile": {
                "avg_speed": round(self.user_profile["avg_speed"], 2),
                "avg_acceleration": round(self.user_profile["avg_accel"], 2)
            }
        }
    
    def _calculate_deviation(self, current: float, expected: float) -> float:
        """Calculate deviation from expected value"""
        if expected == 0:
            return current / 10  # Arbitrary scaling
        return abs(current - expected) / expected
    
    def _classify_behavior(self, deviation: float, is_anomalous: bool) -> str:
        """Classify behavior status"""
        if is_anomalous:
            return "critical"
        elif deviation < 0.5:
            return "normal"
        elif deviation < 1.0:
            return "unusual"
        else:
            return "suspicious"
    
    def _get_insights(self, behavior_status: str, deviation: float) -> Dict:
        """Get insights about behavior"""
        insights = {
            "assessment": behavior_status.upper(),
            "deviation_level": deviation
        }
        
        if behavior_status == "normal":
            insights["message"] = "Driving pattern is normal and safe"
        elif behavior_status == "unusual":
            insights["message"] = "Some deviation from normal pattern detected"
        elif behavior_status == "suspicious":
            insights["message"] = "Behavior significantly deviates from user pattern"
        else:
            insights["message"] = "Critical behavioral anomaly detected"
        
        return insights
    
    def _aggressive_driving_recommendation(self, score: float) -> str:
        """Get recommendation for aggressive driving"""
        if score < 30:
            return "✅ Safe driving"
        elif score < 60:
            return "⚠️ Avoid aggressive maneuvers"
        else:
            return "🚨 CRITICAL: Reduce aggressiveness immediately"
