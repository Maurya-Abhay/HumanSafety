#!/usr/bin/env python3
"""
AI Engine Service Initialization Test
Verifies all layers load correctly
"""

import sys
import os

sys.path.insert(0, os.path.dirname(__file__))

colors = {
    'reset': '\033[0m',
    'green': '\033[92m',
    'red': '\033[91m',
    'yellow': '\033[93m',
    'blue': '\033[94m',
    'cyan': '\033[96m',
}

def log(message, color='reset'):
    print(f"{colors[color]}{message}{colors['reset']}")

log('\n╔════════════════════════════════════════════════════════════════╗', 'cyan')
log('║     AI Engine Service Verification                             ║', 'cyan')
log('║     Testing Layers 4, 5, 9                                     ║', 'cyan')
log('╚════════════════════════════════════════════════════════════════╝', 'cyan')

tests = []

# Layer 4: Continuous Learning
def test_layer_4():
    from services.learning_service import ContinuousLearningService
    service = ContinuousLearningService()
    assert hasattr(service, 'store_post_incident'), 'store_post_incident not found'
    assert hasattr(service, 'adaptive_threshold_tuning'), 'adaptive_threshold_tuning not found'
    return 'OK'

tests.append({
    'name': 'Layer 4: Continuous Learning Service',
    'test': test_layer_4,
})

# Layer 5: Geo-Intelligence
def test_layer_5():
    from services.learning_service import GeoIntelligenceService
    service = GeoIntelligenceService()
    assert hasattr(service, 'detect_hotspots'), 'detect_hotspots not found'
    assert hasattr(service, 'calculate_location_risk_score'), 'calculate_location_risk_score not found'
    return 'OK'

tests.append({
    'name': 'Layer 5: Geo-Intelligence Service',
    'test': test_layer_5,
})

# Layer 9: Explainability
def test_layer_9():
    from services.learning_service import ExplainabilityService
    service = ExplainabilityService()
    assert hasattr(service, 'generate_explanation'), 'generate_explanation not found'
    assert hasattr(service, '_identify_contributing_signals'), '_identify_contributing_signals not found'
    return 'OK'

tests.append({
    'name': 'Layer 9: Explainability Service',
    'test': test_layer_9,
})

# Main API
def test_api():
    from fastapi import FastAPI
    assert FastAPI, 'FastAPI import failed'
    return 'OK'

tests.append({
    'name': 'FastAPI Framework',
    'test': test_api,
})

passed = 0
failed = 0

log('\n📋 Running Service Tests:\n', 'blue')

for test in tests:
    try:
        result = test['test']()
        log(f"  ✅ {test['name']}", 'green')
        passed += 1
    except Exception as error:
        log(f"  ❌ {test['name']}: {str(error)}", 'red')
        failed += 1

log('\n📊 Test Results:', 'blue')
log(f"  Passed: {passed}/{len(tests)}", 'green')
log(f"  Failed: {failed}/{len(tests)}", 'red' if failed > 0 else 'green')

if failed == 0:
    log('\n✅ All AI services initialized successfully!\n', 'green')
    sys.exit(0)
else:
    log('\n❌ Some AI services failed to initialize.\n', 'red')
    sys.exit(1)
