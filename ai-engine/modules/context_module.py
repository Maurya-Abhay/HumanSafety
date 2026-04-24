"""Context module - Device state awareness"""
from typing import Dict

class ContextModule:
    """Monitor device context and state"""
    
    def __init__(self):
        self.device_state = {
            "screen_on": False,
            "battery_percent": 100,
            "is_moving": False,
            "in_pocket": False,
            "charging": False
        }
        self.state_history = []
        
    def update_device_state(self, **kwargs) -> Dict:
        """Update device state"""
        for key, value in kwargs.items():
            if key in self.device_state:
                self.device_state[key] = value
        
        self.state_history.append(dict(self.device_state))
        if len(self.state_history) > 100:
            self.state_history.pop(0)
        
        return self.device_state
    
    def analyze_context(self) -> Dict:
        """Analyze current device context"""
        return {
            "screen_state": "on" if self.device_state["screen_on"] else "off",
            "battery_level": self.device_state["battery_percent"],
            "battery_status": self._classify_battery_status(self.device_state["battery_percent"]),
            "is_moving": self.device_state["is_moving"],
            "likely_location": self._infer_location(),
            "device_stability": self._estimate_device_stability(),
            "activity_state": self._determine_activity_state()
        }
    
    def detect_pocket_placement(self, motion_intensity: str, screen_off: bool) -> bool:
        """Detect if device is in pocket"""
        # Device in pocket typically has: screen off + low motion + stable
        if screen_off and motion_intensity in ["idle", "low"]:
            return True
        return False
    
    def get_context_risk_factors(self) -> Dict:
        """Get risk factors from context"""
        risks = {}
        
        # Low battery = can't call for help
        if self.device_state["battery_percent"] < 20:
            risks["low_battery"] = True
        
        # Screen off = user not aware of alerts
        if not self.device_state["screen_on"]:
            risks["screen_off"] = True
        
        # Pocket placement = delayed user response
        if self.device_state["in_pocket"]:
            risks["in_pocket"] = True
        
        return risks
    
    def calculate_alertability_score(self) -> float:
        """Calculate how likely user will notice alert (0-1)"""
        score = 1.0
        
        # Screen on = higher alertability
        if not self.device_state["screen_on"]:
            score -= 0.4
        
        # In pocket = lower alertability
        if self.device_state["in_pocket"]:
            score -= 0.3
        
        # Low battery might affect volume
        if self.device_state["battery_percent"] < 10:
            score -= 0.1
        
        return max(0, score)
    
    def _classify_battery_status(self, battery_percent: float) -> str:
        """Classify battery status"""
        if battery_percent > 50:
            return "good"
        elif battery_percent > 20:
            return "fair"
        elif battery_percent > 10:
            return "low"
        else:
            return "critical"
    
    def _infer_location(self) -> str:
        """Infer device location based on state"""
        if self.device_state["in_pocket"]:
            return "pocket"
        elif not self.device_state["screen_on"] and not self.device_state["is_moving"]:
            return "on_surface"
        elif self.device_state["screen_on"]:
            return "in_hand"
        else:
            return "unknown"
    
    def _estimate_device_stability(self) -> str:
        """Estimate device stability"""
        if len(self.state_history) < 5:
            return "unknown"
        
        # Check consistency of state
        recent_states = self.state_history[-5:]
        moving_states = [s["is_moving"] for s in recent_states]
        
        if all(moving_states):
            return "unstable"
        elif not any(moving_states):
            return "stable"
        else:
            return "variable"
    
    def _determine_activity_state(self) -> str:
        """Determine user activity state"""
        if self.device_state["is_moving"]:
            return "active"
        elif self.device_state["screen_on"]:
            return "engaged"
        else:
            return "inactive"
