const axios = require('axios');
const logger = require('../config/logger');

const AI_ENGINE_URL = process.env.AI_ENGINE_URL || 'http://localhost:8000';
const AI_TIMEOUT = parseInt(process.env.AI_TIMEOUT) || 30000; // 30 seconds (increased from 5s)
const MAX_RETRIES = parseInt(process.env.AI_MAX_RETRIES) || 3;
const INITIAL_BACKOFF = 100; // milliseconds

class AIEngineClient {
  /**
   * Retry logic with exponential backoff
   */
  static async _requestWithRetry(method, endpoint, data = null, retries = 0) {
    try {
      const config = {
        timeout: AI_TIMEOUT,
        headers: {
          'Content-Type': 'application/json',
          'X-Request-ID': `REQ-${Date.now()}-${Math.random().toString(36).slice(2)}`
        }
      };

      let response;
      if (method === 'POST') {
        response = await axios.post(`${AI_ENGINE_URL}${endpoint}`, data, config);
      } else if (method === 'GET') {
        response = await axios.get(`${AI_ENGINE_URL}${endpoint}`, config);
      }

      return response.data;
    } catch (error) {
      const isNetworkError = error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND' || error.code === 'ETIMEDOUT';
      const isServerError = error.response?.status >= 500;

      if ((isNetworkError || isServerError) && retries < MAX_RETRIES) {
        const backoffMs = INITIAL_BACKOFF * Math.pow(2, retries);
        logger.warn(`AI Engine request failed, retrying in ${backoffMs}ms (${retries + 1}/${MAX_RETRIES})`, {
          endpoint,
          error: error.message,
          retries: retries + 1
        });

        await new Promise(resolve => setTimeout(resolve, backoffMs));
        return this._requestWithRetry(method, endpoint, data, retries + 1);
      }

      throw error;
    }
  }

  /**
   * Fallback risk scoring when AI engine is unreachable
   */
  static _fallbackRiskAssessment(sensorData) {
    let riskScore = 0;

    // Speed-based risk
    const speed = sensorData.speed || 0;
    if (speed > 60) riskScore += 30;
    else if (speed > 40) riskScore += 20;
    else if (speed > 20) riskScore += 10;

    // Acceleration-based risk
    const accel = sensorData.accelerometerData || { x: 0, y: 0, z: 0 };
    const magnitude = Math.sqrt(accel.x ** 2 + accel.y ** 2 + accel.z ** 2);
    if (magnitude > 20) riskScore += 50; // High impact
    else if (magnitude > 15) riskScore += 30; // Medium impact
    else if (magnitude > 10) riskScore += 15; // Low impact

    // Audio-based risk (crash sound)
    const audioLevel = sensorData.audioLevel || 0;
    if (audioLevel > 80) riskScore += 30;
    else if (audioLevel > 70) riskScore += 15;

    // Location-based risk (highway/city roads)
    const locationRisk = sensorData.locationRisk || 0;
    riskScore += locationRisk;

    // Cap at 100
    riskScore = Math.min(riskScore, 100);

    return {
      riskScore,
      riskLevel: riskScore > 70 ? 'critical' : riskScore > 50 ? 'high' : riskScore > 30 ? 'medium' : 'low',
      confidence: 0.65, // Lower confidence for fallback
      triggerAlert: riskScore > 50 // Trigger if medium-high risk
    };
  }

  /**
   * Analyze accident data using AI engine with retry logic
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

      logger.debug('Analyzing accident data via AI engine', { endpoint: '/analyze' });
      const response = await this._requestWithRetry('POST', '/analyze', payload);

      return {
        success: true,
        data: response,
        riskScore: response.analysis?.final_assessment?.final_risk_score || 0,
        riskLevel: response.analysis?.final_assessment?.risk_level || 'low',
        triggerAlert: response.analysis?.final_assessment?.trigger_alert || false,
        confidence: response.analysis?.confidence || 0,
        source: 'ai-engine'
      };
    } catch (error) {
      logger.error('AI Engine error in analyzeAccident, using fallback', {
        error: error.message,
        endpoint: '/analyze'
      });

      // Use fallback risk assessment
      const fallback = this._fallbackRiskAssessment(sensorData);
      return {
        success: false,
        error: error.message,
        ...fallback,
        source: 'fallback'
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

      const response = await this._requestWithRetry('POST', '/predict-emergency', payload);

      return {
        success: true,
        data: response,
        emergencyProbability: response.emergency_probability || 0,
        shouldTriggerAlert: response.should_trigger_alert || false,
        source: 'ai-engine'
      };
    } catch (error) {
      logger.error('AI Engine error in predictEmergency, using fallback', {
        error: error.message,
        endpoint: '/predict-emergency'
      });

      const fallback = this._fallbackRiskAssessment(sensorData);
      return {
        success: false,
        error: error.message,
        emergencyProbability: fallback.riskScore / 100,
        shouldTriggerAlert: fallback.triggerAlert,
        source: 'fallback'
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

      const response = await this._requestWithRetry('POST', '/validate-alert', payload);

      return {
        success: true,
        data: response,
        isValid: response.is_valid_event || false,
        confidence: response.confidence || 0,
        filterReasons: response.filter_failures || [],
        source: 'ai-engine'
      };
    } catch (error) {
      logger.error('AI Engine error in validateAlert, using fallback', {
        error: error.message,
        endpoint: '/validate-alert'
      });

      return {
        success: false,
        error: error.message,
        isValid: riskScore > 50, // Conservative fallback
        confidence: 0.5,
        source: 'fallback'
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

      const response = await this._requestWithRetry('POST', '/get-risk-score', payload);

      return {
        success: true,
        data: response,
        riskScore: response.risk_score || 0,
        riskLevel: response.risk_level || 'low',
        source: 'ai-engine'
      };
    } catch (error) {
      logger.error('AI Engine error in getRiskScore, using fallback', {
        error: error.message,
        endpoint: '/get-risk-score'
      });

      // Simple fallback
      let riskScore = 0;
      if (speed > 80) riskScore = 60;
      else if (speed > 60) riskScore = 40;
      else if (speed > 40) riskScore = 20;

      return {
        success: false,
        error: error.message,
        riskScore,
        riskLevel: riskScore > 50 ? 'high' : riskScore > 30 ? 'medium' : 'low',
        source: 'fallback'
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

      const response = await this._requestWithRetry('POST', '/stream-data', payload);

      return {
        success: true,
        data: response,
        alert: response.alert || false,
        source: 'ai-engine'
      };
    } catch (error) {
      logger.error('AI Engine error in streamData', {
        error: error.message,
        endpoint: '/stream-data'
      });

      return {
        success: false,
        error: error.message,
        alert: false,
        source: 'fallback'
      };
    }
  }

  /**
   * Check AI engine health
   */
  static async checkHealth() {
    try {
      const response = await this._requestWithRetry('GET', '/health');

      logger.info('AI Engine health check successful', {
        status: response.status || 'unknown'
      });

      return {
        success: true,
        status: response.status || 'unknown',
        timestamp: Date.now()
      };
    } catch (error) {
      logger.error('AI Engine health check failed', {
        error: error.message,
        url: AI_ENGINE_URL
      });

      return {
        success: false,
        status: 'offline',
        error: error.message,
        timestamp: Date.now()
      };
    }
  }
}

module.exports = AIEngineClient;
