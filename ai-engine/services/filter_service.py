"""Filter Service - False alarm filtering and validation"""
from typing import Dict, List

class FilterService:
    """Filter false alarms and validate true emergencies"""
    
    def __init__(self):
        self.false_alarm_history = []
        self.validation_history = []
        
    def validate_alert(self,
                      risk_score: float,
                      sensor_data: Dict,
                      context_data: Dict = None,
                      location_type: str = "unknown") -> Dict:
        """
        Validate if alert is genuine or false alarm
        
        Returns:
            {
                "is_valid_event": bool,
                "confidence": float,
                "filter_reasons": list,
                "recommendation": str
            }
        """
        
        filters = self._run_filters(risk_score, sensor_data, context_data, location_type)
        
        # Count passed filters
        passed = sum(1 for f in filters.values() if f is True)
        total = len(filters)
        
        # Determine validity
        is_valid = passed >= (total * 0.7)  # 70% filters must pass
        
        # Calculate confidence
        confidence = (passed / total) * 100 if total > 0 else 0
        
        result = {
            "is_valid_event": is_valid,
            "confidence": round(confidence, 1),
            "filter_results": filters,
            "filter_failures": [k for k, v in filters.items() if not v],
            "recommendation": self._get_filter_recommendation(is_valid, filters, risk_score)
        }
        
        self.validation_history.append(result)
        return result
    
    def _run_filters(self,
                    risk_score: float,
                    sensor_data: Dict,
                    context_data: Dict,
                    location_type: str) -> Dict:
        """Run all validation filters"""
        
        filters = {}
        
        # FILTER 1: Not a phone drop
        filters["not_phone_drop"] = self._filter_phone_drop(sensor_data, risk_score)
        
        # FILTER 2: Not vibration only
        filters["not_vibration_only"] = self._filter_vibration(sensor_data)
        
        # FILTER 3: Not pocket placement
        filters["not_pocket_placement"] = self._filter_pocket(context_data, sensor_data)
        
        # FILTER 4: Sustained impact (not momentary)
        filters["sustained_impact"] = self._filter_sustained_impact(sensor_data)
        
        # FILTER 5: Reasonable location
        filters["reasonable_location"] = self._filter_location(location_type, risk_score)
        
        # FILTER 6: Not just speed variation
        filters["not_speed_variation"] = self._filter_speed_only(sensor_data)
        
        # FILTER 7: Contextual validity
        filters["contextual_valid"] = self._filter_context(context_data)
        
        return filters
    
    def _filter_phone_drop(self, sensor_data: Dict, risk_score: float) -> bool:
        """
        Filter out phone drops
        
        Phone drop characteristics:
        - Very high initial impact
        - Immediate settling
        - No sustained motion
        """
        
        accel = sensor_data.get("accel", {})
        magnitude = (accel.get("x", 0)**2 + accel.get("y", 0)**2 + accel.get("z", 0)**2) ** 0.5
        
        # Very high magnitude but low risk score = likely drop
        if magnitude > 20 and risk_score < 30:
            return False  # FAIL - likely phone drop
        
        return True  # PASS
    
    def _filter_vibration(self, sensor_data: Dict) -> bool:
        """
        Filter pure vibration (not accident)
        
        Vibration characteristics:
        - Multiple rapid small movements
        - No speed change
        - No sustained acceleration
        """
        
        accel = sensor_data.get("accel", {})
        magnitude = (accel.get("x", 0)**2 + accel.get("y", 0)**2 + accel.get("z", 0)**2) ** 0.5
        
        # Low magnitude sustained = vibration
        if magnitude < 3 and magnitude > 0.5:
            return False  # FAIL - pure vibration
        
        return True  # PASS
    
    def _filter_pocket(self, context_data: Dict, sensor_data: Dict) -> bool:
        """
        Filter pocket placement movements
        
        Pocket characteristics:
        - Screen off
        - Limited motion
        - Stable acceleration pattern
        """
        
        if not context_data:
            return True
        
        screen_on = context_data.get("screen_on", True)
        
        accel = sensor_data.get("accel", {})
        magnitude = (accel.get("x", 0)**2 + accel.get("y", 0)**2 + accel.get("z", 0)**2) ** 0.5
        
        # Screen off + low motion = likely in pocket
        if not screen_on and magnitude < 2:
            return False  # FAIL - likely in pocket
        
        return True  # PASS
    
    def _filter_sustained_impact(self, sensor_data: Dict) -> bool:
        """
        Filter momentary impacts
        
        Must have sustained high acceleration, not just spike
        """
        
        # In real system, would check accel history
        # For now, require substantial data
        accel = sensor_data.get("accel", {})
        if accel:
            magnitude = (accel.get("x", 0)**2 + accel.get("y", 0)**2 + accel.get("z", 0)**2) ** 0.5
            # Need minimum impact level
            if magnitude > 10:
                return True
        
        return False  # FAIL - insufficient impact
    
    def _filter_location(self, location_type: str, risk_score: float) -> bool:
        """Filter by location context"""
        
        # Parking lot high risk = likely false alarm
        if location_type == "parking" and risk_score > 50:
            return False
        
        return True
    
    def _filter_speed_only(self, sensor_data: Dict) -> bool:
        """Filter pure speed variations without impact"""
        
        accel = sensor_data.get("accel", {})
        magnitude = (accel.get("x", 0)**2 + accel.get("y", 0)**2 + accel.get("z", 0)**2) ** 0.5
        
        # Minimal acceleration with speed change = just speed variation
        if magnitude < 5:
            return False
        
        return True
    
    def _filter_context(self, context_data: Dict) -> bool:
        """Validate contextual factors"""
        
        if not context_data:
            return True
        
        # Battery critically low = unreliable sensors
        if context_data.get("battery_percent", 100) < 5:
            return False
        
        # Device charging = electrical noise
        if context_data.get("charging", False):
            return False
        
        return True
    
    def get_filter_statistics(self) -> Dict:
        """Get statistics on filtering"""
        if not self.validation_history:
            return {"total_validations": 0}
        
        valid_count = sum(1 for v in self.validation_history if v["is_valid_event"])
        total = len(self.validation_history)
        
        return {
            "total_validations": total,
            "valid_events": valid_count,
            "false_alarms": total - valid_count,
            "validation_accuracy": round((valid_count / total) * 100, 1) if total > 0 else 0,
            "most_common_filter": self._find_most_common_filter()
        }
    
    def _find_most_common_filter(self) -> str:
        """Find most commonly triggered filter"""
        if not self.validation_history:
            return "none"
        
        filter_counts = {}
        for validation in self.validation_history:
            for failure in validation.get("filter_failures", []):
                filter_counts[failure] = filter_counts.get(failure, 0) + 1
        
        if filter_counts:
            return max(filter_counts, key=filter_counts.get)
        return "none"
    
    def _get_filter_recommendation(self, is_valid: bool, filters: Dict, risk_score: float) -> str:
        """Get recommendation based on filters"""
        if is_valid:
            if risk_score > 70:
                return "✅ VALIDATED: Legitimate high-risk event"
            else:
                return "✅ VALIDATED: Event appears genuine"
        else:
            failures = [k for k, v in filters.items() if not v]
            if "not_phone_drop" not in failures:
                return "🔍 LIKELY FALSE ALARM: Phone drop detected"
            elif "not_vibration_only" not in failures:
                return "🔍 LIKELY FALSE ALARM: Vibration only"
            else:
                return "🔍 LOW CONFIDENCE: Requires manual verification"
