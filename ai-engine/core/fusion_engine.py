"""Fusion Engine - The main intelligence brain combining all systems"""
from typing import Dict, List
from core.accident_engine import AccidentEngine
from core.risk_engine import RiskEngine
from core.behavior_engine import BehaviorEngine
from modules.sensor_module import SensorModule
from modules.location_module import LocationModule
from modules.audio_module import AudioModule
from modules.context_module import ContextModule
from utils.scoring import ScoringSystem

class FusionEngine:
    """Multi-brain safety intelligence system"""
    
    def __init__(self):
        self.accident_engine = AccidentEngine()
        self.risk_engine = RiskEngine()
        self.behavior_engine = BehaviorEngine()
        
        self.sensor_module = SensorModule()
        self.location_module = LocationModule()
        self.audio_module = AudioModule()
        self.context_module = ContextModule()
        
        self.fusion_history = []
        
    def process_all_data(self,
                        accel_data: Dict,
                        gyro_data: Dict,
                        speed_data: Dict,
                        location_data: Dict,
                        audio_data: Dict = None,
                        context_data: Dict = None) -> Dict:
        """
        Process all sensor data through fusion engine
        
        Main intelligence hub combining all inputs
        """
        
        # Process each module
        sensor_info = self.sensor_module.process_acceleration(
            accel_data.get("x", 0),
            accel_data.get("y", 0),
            accel_data.get("z", 0)
        )
        
        gyro_info = self.sensor_module.process_gyroscope(
            gyro_data.get("x", 0),
            gyro_data.get("y", 0),
            gyro_data.get("z", 0)
        )
        
        speed_info = self.location_module.process_speed(speed_data.get("current", 0))
        
        location_info = self.location_module.process_location(
            location_data.get("lat", 0),
            location_data.get("lon", 0),
            location_data.get("timestamp", 0)
        )
        
        # Audio processing (optional)
        audio_info = {}
        audio_risk = 0
        if audio_data:
            audio_info = self.audio_module.process_audio(audio_data.get("level", 0))
            audio_risk = audio_data.get("level", 0)
        
        # Context processing (optional)
        context_info = {}
        if context_data:
            self.context_module.update_device_state(**context_data)
            context_info = self.context_module.analyze_context()
        
        # FUSION CORE: Analyze through all engines
        
        # 1. Accident Detection
        accident_result = self.accident_engine.analyze_accident(
            accel_magnitude=sensor_info["magnitude"],
            speed_drop_pct=self._calculate_speed_drop(speed_data),
            inactivity_ms=self._estimate_inactivity(),
            audio_level=audio_risk,
            screen_off=not context_data.get("screen_on", True) if context_data else False
        )
        
        # 2. Risk Assessment
        risk_result = self.risk_engine.calculate_total_risk(
            location_type=location_info["location_type"],
            speed=speed_data.get("current", 0),
            movement_type=speed_info["movement_type"],
            is_anomalous_movement=sensor_info["is_anomalous"],
            behavior_score=0,
            audio_risk=audio_risk / 100 if audio_risk else 0
        )
        
        # 3. Behavior Analysis
        behavior_result = self.behavior_engine.analyze_behavior(
            current_speed=speed_data.get("current", 0),
            accel_magnitude=sensor_info["magnitude"],
            location_type=location_info["location_type"]
        )
        
        # UPDATE user profile
        self.behavior_engine.update_user_profile(
            speed_data.get("current", 0),
            sensor_info["magnitude"]
        )
        
        # 4. FINAL FUSION DECISION
        final_assessment = self._fuse_all_signals(
            accident_result,
            risk_result,
            behavior_result,
            sensor_info,
            context_info
        )
        
        # Store for history
        self.fusion_history.append({
            "accident": accident_result["accident_score"],
            "risk": risk_result["total_risk_score"],
            "behavior": behavior_result["deviation_score"],
            "final": final_assessment["final_risk_score"]
        })
        
        return {
            "status": "success",
            "timestamp": location_data.get("timestamp", 0),
            "final_assessment": final_assessment,
            "modules": {
                "sensor": sensor_info,
                "location": location_info,
                "speed": speed_info,
                "audio": audio_info,
                "context": context_info
            },
            "engines": {
                "accident": accident_result,
                "risk": risk_result,
                "behavior": behavior_result
            },
            "recommendations": self._generate_recommendations(final_assessment)
        }
    
    def _fuse_all_signals(self,
                         accident_result: Dict,
                         risk_result: Dict,
                         behavior_result: Dict,
                         sensor_info: Dict,
                         context_info: Dict) -> Dict:
        """
        FUSION CORE: Combine all signals into final decision
        """
        
        # Weighted combination
        final_score = (
            accident_result["accident_score"] * 0.45 +
            risk_result["total_risk_score"] * 0.35 +
            behavior_result["deviation_score"] * 0.15 +
            (sensor_info.get("magnitude", 0) / 20 * 100) * 0.05
        )
        
        final_score = min(100, final_score)
        
        # Determine alert trigger
        trigger_alert = (
            accident_result["trigger_alert"] or
            final_score >= 70 or
            behavior_result["is_anomalous"]
        )
        
        # Determine risk level
        if final_score < 30:
            risk_level = "low"
        elif final_score < 50:
            risk_level = "medium"
        elif final_score < 75:
            risk_level = "high"
        else:
            risk_level = "critical"
        
        # Check alertability
        alertability = 1.0
        if context_info:
            alertability = self.context_module.calculate_alertability_score()
        
        # Adjust alert threshold based on alertability
        if trigger_alert and alertability < 0.3:
            trigger_alert = True  # Always alert if critical, even if user not aware
        
        return {
            "final_risk_score": round(final_score, 2),
            "final_risk_level": risk_level,
            "trigger_alert": trigger_alert,
            "confidence": round(min(100, 
                (accident_result["confidence"] + 
                 risk_result["components"].get("location_risk", 50) / 100) / 2 * 100), 2),
            "alertability_score": round(alertability, 2),
            "reason": self._generate_reason(accident_result, risk_result, behavior_result, final_score)
        }
    
    def _generate_reason(self,
                        accident_result: Dict,
                        risk_result: Dict,
                        behavior_result: Dict,
                        final_score: float) -> List[str]:
        """Generate human-readable reason for alert"""
        reasons = []
        
        if accident_result["accident_score"] > 40:
            reasons.extend(accident_result["contributing_factors"])
        
        if risk_result["total_risk_score"] > 50:
            reasons.append(risk_result["primary_risk"].title())
        
        if behavior_result["is_anomalous"]:
            reasons.append("Anomalous behavior detected")
        
        if final_score >= 70:
            reasons.append("High combined risk score")
        
        return reasons if reasons else ["Multiple factors detected"]
    
    def _generate_recommendations(self, final_assessment: Dict) -> List[str]:
        """Generate actionable recommendations"""
        recommendations = []
        
        if final_assessment["trigger_alert"]:
            if final_assessment["final_risk_level"] == "critical":
                recommendations.append("🚨 EMERGENCY: Trigger SOS immediately")
                recommendations.append("Alert all emergency contacts now")
            else:
                recommendations.append("⚠️ High risk detected: Prepare for emergency")
                recommendations.append("Stay alert and ready to respond")
        
        elif final_assessment["final_risk_level"] == "high":
            recommendations.append("⚡ Monitor situation closely")
            recommendations.append("Reduce speed and increase caution")
        
        elif final_assessment["final_risk_level"] == "medium":
            recommendations.append("Stay aware of surroundings")
        
        if final_assessment["alertability_score"] < 0.4:
            recommendations.append("⚡ Note: Screen is off - user may not see alert")
        
        return recommendations
    
    def _calculate_speed_drop(self, speed_data: Dict) -> float:
        """Calculate speed drop percentage"""
        current = speed_data.get("current", 0)
        previous = speed_data.get("previous", current)
        
        if previous == 0:
            return 0
        
        drop = ((previous - current) / previous) * 100
        return max(0, drop)
    
    def _estimate_inactivity(self) -> float:
        """Estimate device inactivity time"""
        # Get from sensor module
        if len(self.sensor_module.accel_history) > 0:
            if all(v < 1 for v in self.sensor_module.accel_history[-10:]):
                return 30000  # 30 seconds
        return 0
    
    def get_system_health(self) -> Dict:
        """Get overall system health"""
        return {
            "modules_active": {
                "accident": len(self.accident_engine.accident_history) > 0,
                "risk": len(self.risk_engine.risk_history) > 0,
                "behavior": len(self.behavior_engine.behavior_history) > 0,
                "sensor": len(self.sensor_module.accel_history) > 0,
                "location": len(self.location_module.location_history) > 0,
                "audio": len(self.audio_module.audio_history) > 0
            },
            "fusion_events": len(self.fusion_history),
            "system_status": "operational"
        }
