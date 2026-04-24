"""Location module - GPS and geofencing logic"""
from typing import Dict, List, Tuple
from utils.helpers import haversine_distance, moving_average

class LocationModule:
    """Process location and movement data"""
    
    # Geofence definitions
    GEOFENCES = {
        "highway": {"min_speed": 60, "max_speed": 150},
        "city": {"min_speed": 20, "max_speed": 80},
        "residential": {"min_speed": 0, "max_speed": 50},
        "parking": {"min_speed": 0, "max_speed": 10}
    }
    
    def __init__(self):
        self.location_history: List[Dict] = []
        self.speed_history: List[float] = []
        self.max_history = 100
        
    def process_location(self, lat: float, lon: float, timestamp: int) -> Dict:
        """Process GPS location data"""
        location_data = {
            "lat": lat,
            "lon": lon,
            "timestamp": timestamp
        }
        self.location_history.append(location_data)
        if len(self.location_history) > self.max_history:
            self.location_history.pop(0)
        
        return {
            "latitude": round(lat, 6),
            "longitude": round(lon, 6),
            "location_type": self._detect_location_type()
        }
    
    def process_speed(self, speed: float) -> Dict:
        """Process speed data"""
        self.speed_history.append(speed)
        if len(self.speed_history) > self.max_history:
            self.speed_history.pop(0)
        
        avg_speed = moving_average(self.speed_history)
        
        return {
            "current_speed": round(speed, 2),
            "average_speed": round(avg_speed, 2),
            "movement_type": self._classify_movement_type(speed, avg_speed),
            "speed_context": self._get_speed_context(speed)
        }
    
    def calculate_distance_traveled(self, last_n_points: int = None) -> float:
        """Calculate total distance from location history"""
        if len(self.location_history) < 2:
            return 0
        
        points = self.location_history if last_n_points is None else self.location_history[-last_n_points:]
        
        total_distance = 0
        for i in range(1, len(points)):
            prev = points[i-1]
            curr = points[i]
            distance = haversine_distance(prev["lat"], prev["lon"], curr["lat"], curr["lon"])
            total_distance += distance
        
        return total_distance
    
    def detect_location_type(self, speed: float, is_stationary: bool = False) -> str:
        """Detect current location type"""
        if is_stationary or speed < 5:
            return "parking"
        elif speed < 50:
            return "residential"
        elif speed < 80:
            return "city"
        else:
            return "highway"
    
    def get_movement_pattern(self) -> Dict:
        """Analyze movement pattern"""
        if len(self.speed_history) < 5:
            return {"pattern": "unknown", "stability": 0}
        
        recent_speeds = self.speed_history[-20:]
        avg = moving_average(recent_speeds)
        
        # Calculate variance
        if avg == 0:
            variance = 0
        else:
            variance = sum((s - avg)**2 for s in recent_speeds) / len(recent_speeds)
            std_dev = variance ** 0.5
            cv = std_dev / avg  # Coefficient of variation
        
        if cv < 0.1:
            pattern = "stable"
        elif cv < 0.3:
            pattern = "normal"
        elif cv < 0.6:
            pattern = "erratic"
        else:
            pattern = "chaotic"
        
        return {
            "pattern": pattern,
            "stability": round(1 - min(cv, 1), 2),
            "coefficient_of_variation": round(cv, 3)
        }
    
    def is_stationary(self, threshold_time_ms: int = 5000) -> bool:
        """Detect if device is stationary"""
        if len(self.speed_history) < 3:
            return False
        
        recent_speeds = self.speed_history[-10:]
        avg_speed = moving_average(recent_speeds)
        
        return avg_speed < 1.0  # Less than 1 km/h
    
    def _detect_location_type(self) -> str:
        """Detect location type from history"""
        if not self.speed_history:
            return "unknown"
        
        avg_speed = moving_average(self.speed_history)
        return self.detect_location_type(avg_speed)
    
    def _classify_movement_type(self, current_speed: float, avg_speed: float) -> str:
        """Classify type of movement"""
        if current_speed < 2:
            return "walking"
        elif current_speed < 10:
            return "slow_moving"
        elif current_speed < 60:
            return "driving_normal"
        else:
            return "driving_fast"
    
    def _get_speed_context(self, speed: float) -> Dict:
        """Get contextual information about speed"""
        is_anomalous = False
        if len(self.speed_history) > 5:
            avg = moving_average(self.speed_history[-10:])
            is_anomalous = speed > avg * 1.3
        
        return {
            "is_anomalous": is_anomalous,
            "risk_level": "high" if speed > 100 else "medium" if speed > 60 else "low"
        }
