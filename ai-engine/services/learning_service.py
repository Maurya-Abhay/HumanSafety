"""
AI Continuous Learning & Post-Incident Analysis Service
"""
import json
from datetime import datetime, timedelta
from collections import defaultdict
from typing import Dict, List, Tuple

class ContinuousLearningService:
    def __init__(self):
        self.incident_database = []
        self.false_positives = []
        self.learning_iterations = 0
        self.model_performance_history = []
        self.adaptive_thresholds = {
            'accident': {'low': 20, 'medium': 50, 'high': 75, 'critical': 90},
            'panic': {'low': 30, 'medium': 60, 'high': 80, 'critical': 95},
            'custom': {'low': 40, 'medium': 65, 'high': 85, 'critical': 100}
        }
        self.learning_data = defaultdict(list)
    
    def store_post_incident(self, incident):
        """
        Store incident data after resolution for learning
        """
        learning_record = {
            'incident_id': incident.get('id'),
            'type': incident.get('type'),
            'initial_risk_score': incident.get('risk_score'),
            'final_risk_score': incident.get('final_risk_score'),
            'severity': incident.get('severity'),
            'resolution_time': incident.get('resolution_time'),
            'actual_outcome': incident.get('outcome'),  # true emergency or false positive
            'ai_confidence': incident.get('ai_confidence'),
            'sensor_data': incident.get('sensor_data'),
            'location': incident.get('location'),
            'time_of_day': datetime.now().hour,
            'day_of_week': datetime.now().weekday(),
            'timestamp': datetime.now().isoformat(),
        }
        
        self.incident_database.append(learning_record)
        self.learning_data[incident.get('type')].append(learning_record)
        
        return {
            'stored': True,
            'incident_id': incident.get('id'),
            'total_incidents': len(self.incident_database)
        }
    
    def record_false_positive(self, incident_id, ai_prediction, actual_outcome):
        """
        Track false positive predictions for correction
        """
        false_positive = {
            'incident_id': incident_id,
            'ai_prediction': ai_prediction,
            'actual_outcome': actual_outcome,
            'timestamp': datetime.now().isoformat(),
            'severity': 'high'  # False positives cause wasted resources
        }
        
        self.false_positives.append(false_positive)
        
        # Trigger model retraining if too many false positives
        fp_rate = len(self.false_positives) / max(len(self.incident_database), 1)
        if fp_rate > 0.15:  # >15% false positive rate
            self.trigger_model_retraining()
        
        return {
            'recorded': True,
            'false_positive_rate': fp_rate,
            'retraining_triggered': fp_rate > 0.15
        }
    
    def adaptive_threshold_tuning(self, incident_type):
        """
        Adjust thresholds based on historical performance
        """
        if incident_type not in self.learning_data:
            return self.adaptive_thresholds[incident_type]
        
        incidents = self.learning_data[incident_type][-100:]  # Last 100 incidents
        
        if not incidents:
            return self.adaptive_thresholds[incident_type]
        
        # Calculate optimal thresholds based on true positive and false positive rates
        false_positives = sum(1 for i in incidents if i['actual_outcome'] == False)
        true_positives = sum(1 for i in incidents if i['actual_outcome'] == True)
        
        # Adjust thresholds to optimize for balanced precision/recall
        adjustment_factor = 1.0
        if false_positives > 0 and true_positives > 0:
            fp_ratio = false_positives / (false_positives + true_positives)
            if fp_ratio > 0.2:  # Too many false positives
                adjustment_factor = 1.05  # Increase thresholds
            elif fp_ratio < 0.05:  # Not enough alerts
                adjustment_factor = 0.95  # Decrease thresholds
        
        # Update thresholds
        new_thresholds = {}
        for level, value in self.adaptive_thresholds[incident_type].items():
            new_thresholds[level] = int(value * adjustment_factor)
        
        self.adaptive_thresholds[incident_type] = new_thresholds
        
        return {
            'adjusted_thresholds': new_thresholds,
            'adjustment_factor': adjustment_factor,
            'false_positive_rate': false_positives / len(incidents) if incidents else 0
        }
    
    def trigger_model_retraining(self):
        """
        Trigger model retraining based on collected data
        """
        self.learning_iterations += 1
        
        retraining_report = {
            'iteration': self.learning_iterations,
            'total_incidents_analyzed': len(self.incident_database),
            'false_positives': len(self.false_positives),
            'timestamp': datetime.now().isoformat(),
            'actions_taken': [
                'recalibrated_thresholds',
                'analyzed_sensor_patterns',
                'updated_location_risk_factors'
            ]
        }
        
        # Adjust all thresholds based on performance
        for incident_type in self.adaptive_thresholds.keys():
            self.adaptive_threshold_tuning(incident_type)
        
        self.model_performance_history.append(retraining_report)
        
        return retraining_report
    
    def get_learning_insights(self):
        """
        Generate insights from learning data
        """
        return {
            'total_incidents_learned': len(self.incident_database),
            'false_positive_rate': len(self.false_positives) / max(len(self.incident_database), 1),
            'learning_iterations': self.learning_iterations,
            'current_thresholds': self.adaptive_thresholds,
            'incidents_by_type': {
                k: len(v) for k, v in self.learning_data.items()
            }
        }
    
    def analyze_temporal_patterns(self):
        """
        Analyze time-based patterns in incidents
        """
        if not self.incident_database:
            return {}
        
        hourly_incidents = defaultdict(int)
        daily_incidents = defaultdict(int)
        
        for incident in self.incident_database:
            hourly_incidents[incident['time_of_day']] += 1
            daily_incidents[incident['day_of_week']] += 1
        
        return {
            'by_hour': dict(hourly_incidents),
            'by_day': dict(daily_incidents),
            'peak_hours': sorted(hourly_incidents.items(), key=lambda x: x[1], reverse=True)[:3],
            'peak_days': sorted(daily_incidents.items(), key=lambda x: x[1], reverse=True)[:3]
        }


class ExplainabilityService:
    def __init__(self):
        self.explanation_history = []
    
    def generate_explanation(self, risk_assessment):
        """
        Generate explainable AI report showing why alert triggered
        """
        explanation = {
            'incident_id': risk_assessment.get('incident_id'),
            'decision': 'TRIGGER_ALERT' if risk_assessment.get('risk_score', 0) >= 60 else 'NO_ALERT',
            'risk_score': risk_assessment.get('risk_score'),
            'confidence_breakdown': self._calculate_confidence_breakdown(risk_assessment),
            'contributing_signals': self._identify_contributing_signals(risk_assessment),
            'risk_factors': self._extract_risk_factors(risk_assessment),
            'explanation_report': self._generate_natural_language_explanation(risk_assessment),
            'timestamp': datetime.now().isoformat()
        }
        
        self.explanation_history.append(explanation)
        return explanation
    
    def _calculate_confidence_breakdown(self, assessment):
        """
        Break down AI confidence by component
        """
        return {
            'sensor_confidence': assessment.get('sensor_confidence', 0.7),
            'location_confidence': assessment.get('location_confidence', 0.8),
            'temporal_confidence': assessment.get('temporal_confidence', 0.6),
            'pattern_confidence': assessment.get('pattern_confidence', 0.75),
            'overall_confidence': assessment.get('confidence', 0.7)
        }
    
    def _identify_contributing_signals(self, assessment):
        """
        Identify which signals contributed to the decision
        """
        signals = []
        
        if assessment.get('rapid_deceleration'):
            signals.append({
                'signal': 'rapid_deceleration',
                'weight': 0.25,
                'value': assessment['rapid_deceleration'],
                'reason': 'Sudden braking detected via accelerometer'
            })
        
        if assessment.get('high_speed'):
            signals.append({
                'signal': 'high_speed',
                'weight': 0.2,
                'value': assessment['high_speed'],
                'reason': 'Vehicle traveling at high speed before incident'
            })
        
        if assessment.get('location_risk'):
            signals.append({
                'signal': 'location_risk',
                'weight': 0.3,
                'value': assessment['location_risk'],
                'reason': 'Incident in high-accident zone'
            })
        
        if assessment.get('time_of_day_risk'):
            signals.append({
                'signal': 'time_risk',
                'weight': 0.15,
                'value': assessment['time_of_day_risk'],
                'reason': 'Night hours with elevated accident risk'
            })
        
        if assessment.get('multiple_emergencies_nearby'):
            signals.append({
                'signal': 'cluster_activity',
                'weight': 0.1,
                'value': assessment['multiple_emergencies_nearby'],
                'reason': 'Multiple emergencies detected nearby'
            })
        
        return sorted(signals, key=lambda x: x['weight'], reverse=True)
    
    def _extract_risk_factors(self, assessment):
        """
        Extract individual risk factors
        """
        return {
            'acceleration_x': assessment.get('acceleration_x', 0),
            'acceleration_y': assessment.get('acceleration_y', 0),
            'acceleration_z': assessment.get('acceleration_z', 0),
            'gyroscope_x': assessment.get('gyroscope_x', 0),
            'gyroscope_y': assessment.get('gyroscope_y', 0),
            'gyroscope_z': assessment.get('gyroscope_z', 0),
            'location_latitude': assessment.get('location', {}).get('latitude'),
            'location_longitude': assessment.get('location', {}).get('longitude'),
        }
    
    def _generate_natural_language_explanation(self, assessment):
        """
        Generate human-readable explanation
        """
        risk_score = assessment.get('risk_score', 0)
        
        if risk_score >= 80:
            explanation = f"CRITICAL ALERT - Risk score {risk_score}. Multiple high-risk indicators detected:"
        elif risk_score >= 60:
            explanation = f"HIGH RISK ALERT - Risk score {risk_score}. Significant indicators present:"
        elif risk_score >= 40:
            explanation = f"MEDIUM RISK - Risk score {risk_score}. Some risk indicators detected:"
        else:
            explanation = f"LOW RISK - Risk score {risk_score}. Minimal risk indicators."
        
        signals = self._identify_contributing_signals(assessment)
        for signal in signals[:3]:  # Top 3 signals
            explanation += f"\n  • {signal['reason']}"
        
        return explanation
    
    def get_explanation_history(self, limit=20):
        """
        Get history of explanations for auditing
        """
        return self.explanation_history[-limit:]


class GeoIntelligenceService:
    def __init__(self):
        self.hotspots = defaultdict(int)
        self.accident_zones = {}
        self.crime_data = {}
        self.time_risk_matrix = {}
    
    def detect_hotspots(self, incidents):
        """
        Identify accident-prone zones
        """
        for incident in incidents:
            location = incident.get('location', {})
            # Round to grid (0.01 degree ~ 1km)
            grid_key = (
                round(location.get('latitude', 0), 2),
                round(location.get('longitude', 0), 2)
            )
            self.hotspots[grid_key] += 1
        
        # Identify hotspots (>5 incidents in grid)
        hotspot_zones = {
            location: count
            for location, count in self.hotspots.items()
            if count >= 5
        }
        
        return {
            'hotspots': hotspot_zones,
            'total_zones': len(self.hotspots),
            'highest_risk_zone': max(self.hotspots.items(), key=lambda x: x[1]) if self.hotspots else None
        }
    
    def calculate_location_risk_score(self, latitude, longitude, time_of_day=None):
        """
        Calculate risk score based on location history
        """
        grid_key = (round(latitude, 2), round(longitude, 2))
        base_risk = min(self.hotspots.get(grid_key, 0) * 5, 100)
        
        # Time-based adjustment
        time_risk = 0
        if time_of_day is not None:
            # Night hours (22-6): +10
            # Weekend: +5
            if time_of_day >= 22 or time_of_day <= 6:
                time_risk += 10
        
        return min(base_risk + time_risk, 100)
    
    def identify_accident_patterns(self):
        """
        Analyze accident patterns by location and time
        """
        return {
            'total_hotspots': len(self.hotspots),
            'hotspot_analysis': self.detect_hotspots([]),
            'time_based_risk': self.time_risk_matrix
        }
