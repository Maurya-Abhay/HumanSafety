const axios = require('axios');

const AI_ENGINE_URL = process.env.AI_ENGINE_URL || 'http://localhost:8000';
const AI_TIMEOUT = 5000; // 5 seconds timeout

class AIEngineClient {
  /**
   * Analyze accident data using AI engine
   */
  static async analyzeAccident(sensorData) {
    try {
      const payload = {
        accel: sensorData.accelerometerData || { x: 0, y: 0, z: 0 },
        gyro: sensorData.gyroscopeData || { x: 0, y: 0, z: 0 },
        speed: {
          current: sensorData.speed || 0,
          previous: sensorData.previousSpeed || null
        },
        location: {
          lat: sensorData.latitude || 0,
          lon: sensorData.longitude || 0,
          timestamp: sensorData.timestamp || Date.now()
        },
        audio: sensorData.audioLevel ? { level: sensorData.audioLevel } : null,
        context: sensorData.context || {
          screen_on: true,
          battery_percent: 100,
          is_moving: true
        }
      };

      const response = await axios.post(
        `${AI_ENGINE_URL}/analyze`,
        payload,
        { timeout: AI_TIMEOUT }
      );

      return {
        success: true,
        data: response.data,
        riskScore: response.data.analysis?.final_assessment?.final_risk_score || 0,
        riskLevel: response.data.analysis?.final_assessment?.risk_level || 'low',
        triggerAlert: response.data.analysis?.final_assessment?.trigger_alert || false,
        confidence: response.data.analysis?.confidence || 0
      };
    } catch (error) {
      console.error('❌ AI Engine Error (analyze):', error.message);
      return {
        success: false,
        error: error.message,
        riskScore: 0,
        riskLevel: 'unknown',
        triggerAlert: false
      };
    }
  }

  /**
   * Predict emergency probability
   */
  static async predictEmergency(sensorData) {
    try {
      const payload = {
        accel: sensorData.accelerometerData || { x: 0, y: 0, z: 0 },
        gyro: sensorData.gyroscopeData || { x: 0, y: 0, z: 0 },
        speed: {
          current: sensorData.speed || 0,
          previous: sensorData.previousSpeed || null
        },
        location: {
          lat: sensorData.latitude || 0,
          lon: sensorData.longitude || 0,
          timestamp: sensorData.timestamp || Date.now()
        },
        audio: sensorData.audioLevel ? { level: sensorData.audioLevel } : null
      };

      const response = await axios.post(
        `${AI_ENGINE_URL}/predict-emergency`,
        payload,
        { timeout: AI_TIMEOUT }
      );

      return {
        success: true,
        data: response.data,
        emergencyProbability: response.data.emergency_probability || 0,
        shouldTriggerAlert: response.data.should_trigger_alert || false
      };
    } catch (error) {
      console.error('❌ AI Engine Error (predict):', error.message);
      return {
        success: false,
        error: error.message,
        emergencyProbability: 0,
        shouldTriggerAlert: false
      };
    }
  }

  /**
   * Validate if an alert is genuine
   */
  static async validateAlert(sensorData, riskScore) {
    try {
      const payload = {
        accel: sensorData.accelerometerData || { x: 0, y: 0, z: 0 },
        gyro: sensorData.gyroscopeData || { x: 0, y: 0, z: 0 },
        speed: {
          current: sensorData.speed || 0,
          previous: sensorData.previousSpeed || null
        },
        location: {
          lat: sensorData.latitude || 0,
          lon: sensorData.longitude || 0,
          timestamp: sensorData.timestamp || Date.now()
        },
        risk_score: riskScore
      };

      const response = await axios.post(
        `${AI_ENGINE_URL}/validate-alert`,
        payload,
        { timeout: AI_TIMEOUT }
      );

      return {
        success: true,
        data: response.data,
        isValid: response.data.is_valid_event || false,
        confidence: response.data.confidence || 0,
        filterReasons: response.data.filter_failures || []
      };
    } catch (error) {
      console.error('❌ AI Engine Error (validate):', error.message);
      return {
        success: false,
        error: error.message,
        isValid: false,
        confidence: 0
      };
    }
  }

  /**
   * Get risk score for location and speed
   */
  static async getRiskScore(latitude, longitude, speed) {
    try {
      const payload = {
        location: {
          lat: latitude || 0,
          lon: longitude || 0,
          timestamp: Date.now()
        },
        speed: {
          current: speed || 0,
          previous: null
        },
        accel: { x: 0, y: 0, z: 0 },
        gyro: { x: 0, y: 0, z: 0 }
      };

      const response = await axios.post(
        `${AI_ENGINE_URL}/get-risk-score`,
        payload,
        { timeout: AI_TIMEOUT }
      );

      return {
        success: true,
        data: response.data,
        riskScore: response.data.risk_score || 0,
        riskLevel: response.data.risk_level || 'low'
      };
    } catch (error) {
      console.error('❌ AI Engine Error (risk):', error.message);
      return {
        success: false,
        error: error.message,
        riskScore: 0,
        riskLevel: 'unknown'
      };
    }
  }

  /**
   * Stream real-time data
   */
  static async streamData(sensorData) {
    try {
      const payload = {
        accel: sensorData.accelerometerData || { x: 0, y: 0, z: 0 },
        gyro: sensorData.gyroscopeData || { x: 0, y: 0, z: 0 },
        speed: {
          current: sensorData.speed || 0,
          previous: sensorData.previousSpeed || null
        },
        location: {
          lat: sensorData.latitude || 0,
          lon: sensorData.longitude || 0,
          timestamp: sensorData.timestamp || Date.now()
        },
        audio: sensorData.audioLevel ? { level: sensorData.audioLevel } : null
      };

      const response = await axios.post(
        `${AI_ENGINE_URL}/stream-data`,
        payload,
        { timeout: AI_TIMEOUT }
      );

      return {
        success: true,
        data: response.data,
        alert: response.data.alert || false
      };
    } catch (error) {
      console.error('❌ AI Engine Error (stream):', error.message);
      return {
        success: false,
        error: error.message,
        alert: false
      };
    }
  }

  /**
   * Check AI engine health
   */
  static async checkHealth() {
    try {
      const response = await axios.get(
        `${AI_ENGINE_URL}/health`,
        { timeout: AI_TIMEOUT }
      );

      return {
        success: true,
        status: response.data.status || 'unknown'
      };
    } catch (error) {
      console.error('❌ AI Engine Health Check Failed:', error.message);
      return {
        success: false,
        status: 'offline',
        error: error.message
      };
    }
  }
}

module.exports = AIEngineClient;
