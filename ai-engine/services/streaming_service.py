"""Streaming Service - Real-time data processing"""
from typing import Dict, List
from collections import deque
from core.fusion_engine import FusionEngine

class StreamingService:
    """Real-time sensor data streaming and processing"""
    
    def __init__(self, window_size: int = 30):
        self.window_size = window_size  # 30 seconds default
        self.data_buffer = deque(maxlen=window_size)
        self.fusion_engine = FusionEngine()
        
    def add_sensor_data(self,
                       accel: Dict,
                       gyro: Dict,
                       speed: Dict,
                       location: Dict,
                       audio: Dict = None,
                       context: Dict = None) -> Dict:
        """
        Add new sensor data to stream
        
        Process in real-time and return analysis
        """
        
        # Add to buffer
        data_point = {
            "accel": accel,
            "gyro": gyro,
            "speed": speed,
            "location": location,
            "audio": audio,
            "context": context,
            "timestamp": location.get("timestamp", 0)
        }
        self.data_buffer.append(data_point)
        
        # Process through fusion engine
        result = self.fusion_engine.process_all_data(
            accel_data=accel,
            gyro_data=gyro,
            speed_data=speed,
            location_data=location,
            audio_data=audio,
            context_data=context
        )
        
        return result
    
    def get_rolling_statistics(self) -> Dict:
        """Get statistics from rolling window"""
        if not self.data_buffer:
            return {"status": "no_data"}
        
        speeds = [d["speed"].get("current", 0) for d in self.data_buffer]
        accels = [d["accel"].get("x", 0) for d in self.data_buffer]
        
        avg_speed = sum(speeds) / len(speeds) if speeds else 0
        max_speed = max(speeds) if speeds else 0
        min_speed = min(speeds) if speeds else 0
        
        avg_accel = sum(accels) / len(accels) if accels else 0
        max_accel = max(accels) if accels else 0
        
        return {
            "window_size_seconds": self.window_size,
            "data_points": len(self.data_buffer),
            "speed": {
                "average": round(avg_speed, 2),
                "max": round(max_speed, 2),
                "min": round(min_speed, 2)
            },
            "acceleration": {
                "average": round(avg_accel, 2),
                "max": round(max_accel, 2)
            }
        }
    
    def detect_trend(self) -> Dict:
        """Detect trends in streaming data"""
        if len(self.data_buffer) < 5:
            return {"trend": "insufficient_data"}
        
        recent = list(self.data_buffer)[-10:]
        speeds = [d["speed"].get("current", 0) for d in recent]
        
        first_half_avg = sum(speeds[:len(speeds)//2]) / (len(speeds)//2)
        second_half_avg = sum(speeds[len(speeds)//2:]) / (len(speeds) - len(speeds)//2)
        
        if second_half_avg > first_half_avg * 1.2:
            trend = "accelerating"
        elif second_half_avg < first_half_avg * 0.8:
            trend = "decelerating"
        else:
            trend = "stable"
        
        return {
            "trend": trend,
            "speed_change": round(second_half_avg - first_half_avg, 2)
        }
