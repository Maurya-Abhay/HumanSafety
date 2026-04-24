"""Sensor module - Accelerometer and Gyroscope processing"""
from typing import Dict, List, Tuple
from utils.helpers import calculate_magnitude, moving_average, detect_anomaly

class SensorModule:
    """Process real-time sensor data"""
    
    def __init__(self):
        self.accel_history: List[float] = []
        self.gyro_history: List[float] = []
        self.max_history = 100
        
    def process_acceleration(self, x: float, y: float, z: float) -> Dict:
        """Process accelerometer data"""
        magnitude = calculate_magnitude(x, y, z)
        self.accel_history.append(magnitude)
        if len(self.accel_history) > self.max_history:
            self.accel_history.pop(0)
        
        avg_accel = moving_average(self.accel_history)
        is_anomalous = detect_anomaly(magnitude, avg_accel, threshold=1.5)
        
        return {
            "magnitude": round(magnitude, 3),
            "x": round(x, 3),
            "y": round(y, 3),
            "z": round(z, 3),
            "average": round(avg_accel, 3),
            "is_anomalous": is_anomalous,
            "impact_level": self._classify_impact(magnitude)
        }
    
    def process_gyroscope(self, x: float, y: float, z: float) -> Dict:
        """Process gyroscope data"""
        magnitude = calculate_magnitude(x, y, z)
        self.gyro_history.append(magnitude)
        if len(self.gyro_history) > self.max_history:
            self.gyro_history.pop(0)
        
        avg_gyro = moving_average(self.gyro_history)
        is_anomalous = detect_anomaly(magnitude, avg_gyro, threshold=2.0)
        
        return {
            "magnitude": round(magnitude, 3),
            "x": round(x, 3),
            "y": round(y, 3),
            "z": round(z, 3),
            "average": round(avg_gyro, 3),
            "is_anomalous": is_anomalous,
            "rotation_intensity": self._classify_rotation(magnitude)
        }
    
    def detect_sudden_movement(self) -> bool:
        """Detect sudden acceleration"""
        if len(self.accel_history) < 2:
            return False
        
        recent_avg = moving_average(self.accel_history[-10:])
        prev_avg = moving_average(self.accel_history[-20:-10]) if len(self.accel_history) >= 20 else moving_average(self.accel_history[:5])
        
        return recent_avg > prev_avg * 1.5
    
    def detect_sharp_turn(self) -> bool:
        """Detect sharp rotation"""
        if len(self.gyro_history) < 5:
            return False
        
        recent_gyro = max(self.gyro_history[-5:])
        return recent_gyro > 2.0  # High rotation threshold
    
    def get_motion_intensity(self) -> str:
        """Overall motion intensity"""
        if not self.accel_history:
            return "idle"
        
        avg = moving_average(self.accel_history)
        
        if avg < 1.0:
            return "idle"
        elif avg < 3.0:
            return "low"
        elif avg < 6.0:
            return "medium"
        else:
            return "high"
    
    @staticmethod
    def _classify_impact(magnitude: float) -> str:
        """Classify acceleration impact level"""
        if magnitude < 5:
            return "none"
        elif magnitude < 10:
            return "light"
        elif magnitude < 15:
            return "moderate"
        elif magnitude < 20:
            return "severe"
        else:
            return "critical"
    
    @staticmethod
    def _classify_rotation(magnitude: float) -> str:
        """Classify rotation intensity"""
        if magnitude < 0.5:
            return "none"
        elif magnitude < 1.0:
            return "slight"
        elif magnitude < 2.0:
            return "moderate"
        else:
            return "severe"
