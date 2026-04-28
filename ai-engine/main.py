from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, List, Optional
import uvicorn
import os
from dotenv import load_dotenv

from core.fusion_engine import FusionEngine
from services.streaming_service import StreamingService
from services.prediction_service import PredictionService
from services.filter_service import FilterService

# Load environment variables
load_dotenv()

# Initialize FastAPI
app = FastAPI(
    title="HumanSafety AI Intelligence Engine",
    description="Production-grade multi-sensor safety intelligence system",
    version="2.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
fusion_engine = FusionEngine()
streaming_service = StreamingService()
prediction_service = PredictionService()
filter_service = FilterService()

# ============== PYDANTIC MODELS ==============

class AccelerationData(BaseModel):
    x: float
    y: float
    z: float

class GyroscopeData(BaseModel):
    x: float
    y: float
    z: float

class SpeedData(BaseModel):
    current: float
    previous: Optional[float] = None

class LocationData(BaseModel):
    lat: float
    lon: float
    timestamp: int

class AudioData(BaseModel):
    level: float
    frequency_components: Optional[Dict] = None

class ContextData(BaseModel):
    screen_on: Optional[bool] = True
    battery_percent: Optional[float] = 100
    is_moving: Optional[bool] = False
    in_pocket: Optional[bool] = False
    charging: Optional[bool] = False

class FusionRequest(BaseModel):
    accel: AccelerationData
    gyro: GyroscopeData
    speed: SpeedData
    location: LocationData
    audio: Optional[AudioData] = None
    context: Optional[ContextData] = None

class StreamRequest(BaseModel):
    accel: AccelerationData
    gyro: GyroscopeData
    speed: SpeedData
    location: LocationData
    audio: Optional[AudioData] = None
    context: Optional[ContextData] = None

# ============== HEALTH & INFO ==============

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "operational",
        "service": "HumanSafety AI Engine v2.0",
        "system_health": fusion_engine.get_system_health()
    }

@app.get("/info")
async def get_info():
    """Get system information"""
    return {
        "name": "HumanSafety AI Intelligence Engine",
        "version": "2.0.0",
        "capabilities": [
            "Real-time accident detection",
            "Multi-sensor fusion",
            "Risk scoring and assessment",
            "Behavior analysis and learning",
            "False alarm filtering",
            "Emergency prediction",
            "Streaming data processing"
        ],
        "engines": ["accident", "risk", "behavior", "fusion"],
        "modules": ["sensor", "location", "audio", "context"],
        "services": ["streaming", "prediction", "filtering"]
    }

# ============== MAIN FUSION ENDPOINT ==============

@app.post("/analyze")
async def analyze_comprehensive(request: FusionRequest):
    """
    MAIN ENDPOINT: Comprehensive multi-sensor analysis
    
    Processes all sensor data through the complete AI system
    """
    try:
        result = fusion_engine.process_all_data(
            accel_data=request.accel.dict(),
            gyro_data=request.gyro.dict(),
            speed_data=request.speed.dict(),
            location_data=request.location.dict(),
            audio_data=request.audio.dict() if request.audio else None,
            context_data=request.context.dict() if request.context else None
        )
        
        # Run through filter service
        filter_result = filter_service.validate_alert(
            risk_score=result["final_assessment"]["final_risk_score"],
            sensor_data=request.accel.dict(),
            context_data=request.context.dict() if request.context else None,
            location_type=result["modules"]["location"]["location_type"]
        )
        
        # Run prediction service
        prediction = prediction_service.predict_emergency(
            final_risk_score=result["final_assessment"]["final_risk_score"],
            accident_score=result["engines"]["accident"]["accident_score"],
            behavior_score=result["engines"]["behavior"]["deviation_score"],
            speed=request.speed.current,
            location_type=result["modules"]["location"]["location_type"]
        )
        
        return {
            "status": "success",
            "timestamp": request.location.timestamp,
            "analysis": {
                "final_assessment": result["final_assessment"],
                "validation": filter_result,
                "prediction": prediction,
                "confidence": result["final_assessment"]["confidence"]
            },
            "engines": {
                "accident": {
                    "score": result["engines"]["accident"]["accident_score"],
                    "risk_level": result["engines"]["accident"]["risk_level"],
                    "factors": result["engines"]["accident"]["contributing_factors"]
                },
                "risk": {
                    "score": result["engines"]["risk"]["total_risk_score"],
                    "risk_level": result["engines"]["risk"]["risk_level"],
                    "primary_risk": result["engines"]["risk"]["primary_risk"]
                },
                "behavior": {
                    "status": result["engines"]["behavior"]["behavior_status"],
                    "anomalous": result["engines"]["behavior"]["is_anomalous"],
                    "deviation": result["engines"]["behavior"]["deviation_score"]
                }
            },
            "recommendations": result["recommendations"]
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============== STREAMING ENDPOINT ==============

@app.post("/stream-data")
async def stream_data(request: StreamRequest):
    """
    Real-time streaming endpoint
    
    Continuously process sensor data in rolling window
    """
    try:
        result = streaming_service.add_sensor_data(
            accel=request.accel.dict(),
            gyro=request.gyro.dict(),
            speed=request.speed.dict(),
            location=request.location.dict(),
            audio=request.audio.dict() if request.audio else None,
            context=request.context.dict() if request.context else None
        )
        
        # Get rolling statistics
        stats = streaming_service.get_rolling_statistics()
        trend = streaming_service.detect_trend()
        
        return {
            "status": "success",
            "streaming_active": True,
            "data_points_buffered": stats["data_points"],
            "analysis": result["final_assessment"],
            "rolling_statistics": stats,
            "trend": trend,
            "alert": result["final_assessment"]["trigger_alert"]
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============== ACCIDENT DETECTION ==============

@app.post("/analyze-accident")
async def analyze_accident(request: FusionRequest):
    """Detailed accident detection analysis"""
    try:
        speed_drop = ((request.speed.previous or request.speed.current) - request.speed.current) / (request.speed.previous or request.speed.current) * 100 if request.speed.previous else 0
        
        result = fusion_engine.accident_engine.analyze_accident(
            accel_magnitude=(request.accel.x**2 + request.accel.y**2 + request.accel.z**2) ** 0.5,
            speed_drop_pct=max(0, speed_drop),
            inactivity_ms=0,
            audio_level=request.audio.level if request.audio else 0,
            screen_off=not request.context.screen_on if request.context else False
        )
        
        return {
            "status": "success",
            "accident_analysis": result
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============== RISK ANALYSIS ==============

@app.post("/analyze-risk")
async def analyze_risk(request: FusionRequest):
    """Detailed risk scoring analysis"""
    try:
        location_analysis = fusion_engine.risk_engine.analyze_location_risk(
            location_type="unknown",
            speed=request.speed.current
        )
        
        speed_analysis = fusion_engine.risk_engine.analyze_speed_risk(
            speed=request.speed.current
        )
        
        risk_trend = fusion_engine.risk_engine.get_risk_trend()
        
        return {
            "status": "success",
            "risk_analysis": {
                "location": location_analysis,
                "speed": speed_analysis,
                "trend": risk_trend
            }
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============== BEHAVIOR ANALYSIS ==============

@app.post("/analyze-behavior")
async def analyze_behavior(request: FusionRequest):
    """Detailed behavior analysis"""
    try:
        behavior_result = fusion_engine.behavior_engine.analyze_behavior(
            current_speed=request.speed.current,
            accel_magnitude=(request.accel.x**2 + request.accel.y**2 + request.accel.z**2) ** 0.5,
            location_type="unknown"
        )
        
        aggressive_result = fusion_engine.behavior_engine.detect_aggressive_driving(
            accel_magnitude=(request.accel.x**2 + request.accel.y**2 + request.accel.z**2) ** 0.5,
            speed=request.speed.current,
            speed_changes=[]
        )
        
        summary = fusion_engine.behavior_engine.get_behavior_summary()
        
        return {
            "status": "success",
            "behavior_analysis": {
                "behavior": behavior_result,
                "aggressive_driving": aggressive_result,
                "summary": summary
            }
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============== EMERGENCY PREDICTION ==============

@app.post("/predict-emergency")
async def predict_emergency(request: FusionRequest):
    """Emergency prediction analysis"""
    try:
        # Get current fusion analysis first
        fusion_result = fusion_engine.process_all_data(
            accel_data=request.accel.dict(),
            gyro_data=request.gyro.dict(),
            speed_data=request.speed.dict(),
            location_data=request.location.dict(),
            audio_data=request.audio.dict() if request.audio else None,
            context_data=request.context.dict() if request.context else None
        )
        
        prediction = prediction_service.predict_emergency(
            final_risk_score=fusion_result["final_assessment"]["final_risk_score"],
            accident_score=fusion_result["engines"]["accident"]["accident_score"],
            behavior_score=fusion_result["engines"]["behavior"]["deviation_score"],
            speed=request.speed.current,
            location_type=fusion_result["modules"]["location"]["location_type"]
        )
        
        trend = prediction_service.analyze_prediction_trend()
        
        return {
            "status": "success",
            "prediction": {
                "emergency": prediction,
                "trend": trend
            }
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============== VALIDATION & FILTERING ==============

@app.post("/validate-alert")
async def validate_alert(request: FusionRequest):
    """Validate if alert is genuine or false alarm"""
    try:
        fusion_result = fusion_engine.process_all_data(
            accel_data=request.accel.dict(),
            gyro_data=request.gyro.dict(),
            speed_data=request.speed.dict(),
            location_data=request.location.dict(),
            audio_data=request.audio.dict() if request.audio else None,
            context_data=request.context.dict() if request.context else None
        )
        
        validation = filter_service.validate_alert(
            risk_score=fusion_result["final_assessment"]["final_risk_score"],
            sensor_data=request.accel.dict(),
            context_data=request.context.dict() if request.context else None,
            location_type=fusion_result["modules"]["location"]["location_type"]
        )
        
        stats = filter_service.get_filter_statistics()
        
        return {
            "status": "success",
            "validation": {
                "result": validation,
                "statistics": stats
            }
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============== ANALYTICS ==============

@app.get("/analytics/system-health")
async def get_system_health():
    """Get overall system health"""
    return {
        "status": "success",
        "system_health": fusion_engine.get_system_health(),
        "filter_stats": filter_service.get_filter_statistics(),
        "prediction_trend": prediction_service.analyze_prediction_trend()
    }

# ============== MAIN ==============

if __name__ == "__main__":
    PORT = int(os.getenv("PORT", 8000))
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=PORT,
        reload=False
    )
