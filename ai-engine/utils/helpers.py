import math
from typing import Dict, List, Tuple

def calculate_magnitude(x: float, y: float, z: float) -> float:
    """Calculate 3D vector magnitude"""
    return math.sqrt(x**2 + y**2 + z**2)

def calculate_velocity_drop(current_speed: float, previous_speed: float) -> float:
    """Calculate speed drop percentage"""
    if previous_speed == 0:
        return 0
    drop = ((previous_speed - current_speed) / previous_speed) * 100
    return max(0, drop)

def calculate_acceleration(values: List[float]) -> float:
    """Calculate acceleration from speed history"""
    if len(values) < 2:
        return 0
    return abs(values[-1] - values[-2])

def normalize_score(score: float, min_val: float = 0, max_val: float = 100) -> float:
    """Normalize score to range"""
    return min(max_val, max(min_val, score))

def classify_risk_level(score: float) -> str:
    """Classify risk level from score"""
    if score < 30:
        return "low"
    elif score < 60:
        return "medium"
    else:
        return "high"

def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two GPS points (km)"""
    R = 6371  # Earth radius in km
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = math.sin(delta_lat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c

def moving_average(values: List[float], window: int = 5) -> float:
    """Calculate moving average"""
    if not values:
        return 0
    window_data = values[-window:] if len(values) > window else values
    return sum(window_data) / len(window_data)

def detect_anomaly(current: float, historical_avg: float, threshold: float = 2.0) -> bool:
    """Detect if current value is anomalous"""
    if historical_avg == 0:
        return current > 5
    deviation = abs(current - historical_avg) / historical_avg
    return deviation > threshold

def calculate_confidence(data_points: int, sensor_quality: float = 0.9) -> float:
    """Calculate confidence based on data availability"""
    data_confidence = min(1.0, data_points / 30)  # More data = higher confidence
    return (data_confidence * 0.7 + sensor_quality * 0.3) * 100
