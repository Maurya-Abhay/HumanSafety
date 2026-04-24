"""
AI Engine - Production-Grade Emergency Response Analysis
Features:
- Accident/panic detection with sensor fusion
- Continuous learning from resolved cases
- Geo-intelligence with hotspot detection
- Explainable AI with decision transparency
- Real-time risk scoring
"""

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
import numpy as np
from pydantic import BaseModel
from typing import Dict, List, Optional
import json
from datetime import datetime, timedelta
from collections import defaultdict
import math

# Import learning services
from services.learning_service import (
    ContinuousLearningService,
    ExplainabilityService,
    GeoIntelligenceService,
)

app = FastAPI(title="HumanSafety AI Engine", version="2.0")

# Initialize services
learning_service = ContinuousLearningService()
explainability_service = ExplainabilityService()
geo_intelligence = GeoIntelligenceService()

# ============= REQUEST MODELS =============


class SensorData(BaseModel):
    acceleration_x: float
    acceleration_y: float
    acceleration_z: float
    gyroscope_x: float
    gyroscope_y: float
    gyroscope_z: float
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    speed: Optional[float] = None
    timestamp: Optional[int] = None
    userId: Optional[str] = None


class AnalysisRequest(BaseModel):
    sensorData: SensorData
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    userId: Optional[str] = None


class LearningFeedback(BaseModel):
    caseId: str
    feedback: str  # "true_positive" or "false_positive"
    actualRiskLevel: Optional[str] = None
    respondedTime: Optional[int] = None
    aiPredictedRisk: float


class IncidentAnalysis(BaseModel):
    incident_id: str
    type: str
    initial_risk_score: float
    final_risk_score: float
    severity: str
    resolution_time: int
    outcome: bool
    ai_confidence: float
    location: Dict
    sensor_data: Dict


# ============= ACCIDENT DETECTION =============


def detect_accident_from_sensors(sensor_data: SensorData) -> Dict:
    """
    Detect accident from accelerometer and gyroscope data
    Returns: {is_accident, confidence, risk_score}
    """
    # Calculate acceleration magnitude
    accel_magnitude = math.sqrt(
        sensor_data.acceleration_x**2
        + sensor_data.acceleration_y**2
        + sensor_data.acceleration_z**2
    )

    # Calculate gyroscope magnitude
    gyro_magnitude = math.sqrt(
        sensor_data.gyroscope_x**2
        + sensor_data.gyroscope_y**2
        + sensor_data.gyroscope_z**2
    )

    # Thresholds
    high_accel_threshold = 30  # m/s² (3G)
    extreme_accel_threshold = 50  # m/s² (5G)
    gyro_threshold = 2.0  # rad/s

    risk_score = 0
    confidence = 0

    # Extreme acceleration (crash-like)
    if accel_magnitude > extreme_accel_threshold:
        risk_score += 40
        confidence += 0.4

    # High acceleration
    elif accel_magnitude > high_accel_threshold:
        risk_score += 25
        confidence += 0.3

    # High gyroscope (rotation/tumble)
    if gyro_magnitude > gyro_threshold:
        risk_score += 20
        confidence += 0.2

    # Speed check (if available)
    if sensor_data.speed and sensor_data.speed > 100:  # >100 km/h
        risk_score += 15
        confidence += 0.15

    return {
        "is_accident": risk_score > 40,
        "confidence": min(confidence, 1.0),
        "risk_score": min(risk_score, 100),
        "acceleration_magnitude": accel_magnitude,
        "gyro_magnitude": gyro_magnitude,
    }


def calculate_location_risk(latitude: float, longitude: float) -> Dict:
    """
    Calculate risk based on location history (hotspots)
    """
    location_risk = geo_intelligence.calculate_location_risk_score(
        latitude, longitude, datetime.now().hour
    )

    time_of_day = datetime.now().hour
    time_risk = 0
    if time_of_day >= 22 or time_of_day <= 6:
        time_risk = 10  # Night hours: higher risk

    total_location_risk = min(location_risk + time_risk, 100)

    return {
        "location_risk": location_risk,
        "time_risk": time_risk,
        "total_location_risk": total_location_risk,
        "is_hotspot": location_risk > 40,
        "time_of_day": time_of_day,
    }


def calculate_panic_risk(
    rapid_presses: int, time_between_presses: float
) -> Dict:
    """
    Calculate panic button risk
    """
    risk_score = 0
    confidence = 0

    if rapid_presses >= 3 and time_between_presses < 60:
        risk_score = 95
        confidence = 0.95

    elif rapid_presses >= 2 and time_between_presses < 120:
        risk_score = 80
        confidence = 0.85

    elif rapid_presses >= 1:
        risk_score = 60
        confidence = 0.7

    return {
        "panic_risk_score": risk_score,
        "confidence": confidence,
        "rapid_presses": rapid_presses,
    }


# ============= API ENDPOINTS =============


@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {
        "status": "AI Engine running",
        "timestamp": datetime.now().isoformat(),
        "services": {
            "accident_detection": "active",
            "learning_service": "active",
            "geo_intelligence": "active",
            "explainability": "active",
        },
    }


@app.post("/analyze-accident")
def analyze_accident(request: AnalysisRequest):
    """
    Analyze sensor data for accident
    Returns: riskScore, riskLevel, confidence, explanation
    """
    try:
        sensor_data = request.sensorData
        latitude = request.latitude or sensor_data.latitude
        longitude = request.longitude or sensor_data.longitude

        # Accident detection from sensors
        accident_analysis = detect_accident_from_sensors(sensor_data)

        # Location risk analysis
        location_analysis = (
            calculate_location_risk(latitude, longitude)
            if latitude and longitude
            else {"location_risk": 30, "time_risk": 0, "total_location_risk": 30}
        )

        # Combine risks (weighted)
        base_risk = accident_analysis["risk_score"]
        location_risk = location_analysis.get("total_location_risk", 30)
        combined_risk = (base_risk * 0.6) + (location_risk * 0.4)

        # Determine risk level
        if combined_risk >= 85:
            risk_level = "critical"
        elif combined_risk >= 65:
            risk_level = "high"
        elif combined_risk >= 40:
            risk_level = "medium"
        else:
            risk_level = "low"

        # Generate explanation
        assessment = {
            "incident_id": f"INC-{datetime.now().timestamp()}",
            "risk_score": round(combined_risk, 2),
            "sensor_confidence": accident_analysis["confidence"],
            "location_confidence": 0.7,
            "confidence": min(
                accident_analysis["confidence"] * 0.8, 1.0
            ),  # Overall confidence
            "acceleration_x": sensor_data.acceleration_x,
            "acceleration_y": sensor_data.acceleration_y,
            "acceleration_z": sensor_data.acceleration_z,
            "gyroscope_x": sensor_data.gyroscope_x,
            "gyroscope_y": sensor_data.gyroscope_y,
            "gyroscope_z": sensor_data.gyroscope_z,
            "location": {"latitude": latitude, "longitude": longitude},
        }

        explanation = explainability_service.generate_explanation(assessment)

        return {
            "success": True,
            "data": {
                "riskScore": round(combined_risk, 2),
                "riskLevel": risk_level,
                "confidence": round(assessment["confidence"], 3),
                "explanation": explanation["explanation_report"],
                "signals": explanation["contributing_signals"],
                "requiresImmediate": combined_risk >= 65,
                "confidenceBreakdown": explanation["confidence_breakdown"],
            },
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "riskScore": 50,  # Default to medium risk on error
            "riskLevel": "medium",
        }


@app.post("/analyze-panic")
def analyze_panic(
    rapid_presses: int = 3, time_between_presses: float = 30
):
    """
    Analyze panic button presses
    """
    try:
        panic_analysis = calculate_panic_risk(
            rapid_presses, time_between_presses
        )
        risk_score = panic_analysis["panic_risk_score"]

        if risk_score >= 80:
            risk_level = "critical"
        elif risk_score >= 60:
            risk_level = "high"
        else:
            risk_level = "medium"

        return {
            "success": True,
            "data": {
                "riskScore": risk_score,
                "riskLevel": risk_level,
                "confidence": panic_analysis["confidence"],
                "message": f"Panic button pressed {rapid_presses} times in {time_between_presses}s",
                "requiresImmediate": True,
            },
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
        }


# ============= LEARNING ENDPOINTS =============


@app.post("/api/learning")
def record_learning_feedback(feedback: LearningFeedback):
    """
    Record post-incident feedback for continuous learning
    """
    try:
        # Store incident data
        learning_data = {
            "id": feedback.caseId,
            "type": "accident",  # Could be determined from context
            "risk_score": feedback.aiPredictedRisk,
            "final_risk_score": (
                100 if feedback.feedback == "true_positive" else 20
            ),
            "outcome": feedback.feedback == "true_positive",
            "ai_confidence": feedback.aiPredictedRisk / 100,
            "resolution_time": feedback.respondedTime or 0,
            "severity": feedback.actualRiskLevel or "medium",
        }

        result = learning_service.store_post_incident(learning_data)

        # Check for false positives and trigger retraining if needed
        if feedback.feedback == "false_positive":
            fp_record = learning_service.record_false_positive(
                feedback.caseId,
                feedback.aiPredictedRisk,
                False,
            )

            if fp_record.get("retraining_triggered"):
                return {
                    "success": True,
                    "message": "Feedback recorded, model retraining triggered",
                    "retraining": True,
                    "data": result,
                }

        # Adjust thresholds based on learning
        threshold_adjustment = (
            learning_service.adaptive_threshold_tuning(
                "accident"
            )
        )

        return {
            "success": True,
            "message": "Learning feedback recorded",
            "incidents_learned": result["total_incidents"],
            "threshold_adjustment": threshold_adjustment,
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
        }


@app.get("/api/learning/insights")
def get_learning_insights():
    """
    Get insights from learning service
    """
    try:
        insights = learning_service.get_learning_insights()
        temporal_patterns = (
            learning_service.analyze_temporal_patterns()
        )

        return {
            "success": True,
            "data": {
                **insights,
                "temporal_patterns": temporal_patterns,
            },
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
        }


# ============= GEO-INTELLIGENCE ENDPOINTS =============


@app.get("/api/geo-hotspots")
def get_hotspots():
    """
    Get accident hotspot analysis
    """
    try:
        hotspot_data = geo_intelligence.identify_accident_patterns()

        return {
            "success": True,
            "data": hotspot_data,
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
        }


@app.post("/api/geo-risk-score")
def calculate_geo_risk(latitude: float, longitude: float, time_of_day: Optional[int] = None):
    """
    Calculate risk score for a specific location
    """
    try:
        if time_of_day is None:
            time_of_day = datetime.now().hour

        risk_score = geo_intelligence.calculate_location_risk_score(
            latitude, longitude, time_of_day
        )

        return {
            "success": True,
            "data": {
                "location_latitude": latitude,
                "location_longitude": longitude,
                "risk_score": risk_score,
                "time_of_day": time_of_day,
                "is_hotspot": risk_score > 40,
            },
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
        }


# ============= EXPLAINABILITY ENDPOINTS =============


@app.post("/api/explain-decision")
def explain_decision(assessment: Dict):
    """
    Get explainable AI breakdown for a decision
    """
    try:
        explanation = explainability_service.generate_explanation(
            assessment
        )

        return {
            "success": True,
            "data": {
                "decision": explanation["decision"],
                "risk_score": explanation["risk_score"],
                "contributing_signals": explanation["contributing_signals"],
                "confidence_breakdown": explanation["confidence_breakdown"],
                "explanation": explanation["explanation_report"],
            },
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
        }


@app.get("/api/explain-history")
def get_explanation_history(limit: int = 20):
    """
    Get history of AI explanations
    """
    try:
        history = explainability_service.get_explanation_history(limit)

        return {
            "success": True,
            "data": history,
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
        }


# ============= SYSTEM ENDPOINTS =============


@app.get("/api/system/stats")
def get_system_stats():
    """
    Get AI engine statistics
    """
    try:
        return {
            "success": True,
            "data": {
                "learning_service": learning_service.get_learning_insights(),
                "total_explanations": len(
                    explainability_service.explanation_history
                ),
                "total_hotspots": len(geo_intelligence.hotspots),
                "timestamp": datetime.now().isoformat(),
            },
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
        }


if __name__ == "__main__":
    import uvicorn

    print("🚀 Starting HumanSafety AI Engine v2.0")
    print("📊 Features:")
    print("  ✓ Accident/Panic Detection")
    print("  ✓ Continuous Learning Loop")
    print("  ✓ Geo-Intelligence (Hotspot Detection)")
    print("  ✓ Explainable AI (Decision Transparency)")
    print(
        "\n📍 Available at http://localhost:8000"
    )
    print("📖 API Docs at http://localhost:8000/docs")
    uvicorn.run(app, host="0.0.0.0", port=8000)
