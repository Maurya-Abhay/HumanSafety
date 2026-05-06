"""Persistence Service - Save/load AI models and user behavior profiles"""
import requests
import json
import os
from datetime import datetime
from typing import Dict, Optional

class PersistenceService:
    """Handle persistence of AI models and user behavior profiles"""
    
    def __init__(self):
        self.server_url = os.getenv('SERVER_URL', 'http://localhost:5000')
        self.api_base = f"{self.server_url}/api/v1"
        self.cache = {}
        
    def save_user_profile(self, user_id: str, profile_data: Dict) -> bool:
        """Save user behavior profile to server"""
        try:
            # Add timestamp
            profile_data['updatedAt'] = datetime.utcnow().isoformat()
            profile_data['userId'] = user_id
            
            endpoint = f"{self.api_base}/ai/profile"
            response = requests.post(
                endpoint,
                json=profile_data,
                timeout=5,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code in [200, 201]:
                print(f"✅ User profile saved: {user_id}")
                return True
            else:
                print(f"⚠️ Failed to save profile: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Profile save error: {e}")
            return False
    
    def load_user_profile(self, user_id: str) -> Optional[Dict]:
        """Load user behavior profile from server"""
        try:
            # Check cache first
            if user_id in self.cache:
                return self.cache[user_id]
                
            endpoint = f"{self.api_base}/ai/profile/{user_id}"
            response = requests.get(endpoint, timeout=5)
            
            if response.status_code == 200:
                profile = response.json().get('data', {})
                self.cache[user_id] = profile
                print(f"✅ User profile loaded: {user_id}")
                return profile
            else:
                print(f"⚠️ Profile not found: {user_id}")
                return None
                
        except Exception as e:
            print(f"❌ Profile load error: {e}")
            return None
    
    def save_behavior_history(self, user_id: str, history: list) -> bool:
        """Save behavior history for learning"""
        try:
            endpoint = f"{self.api_base}/ai/behavior-history"
            response = requests.post(
                endpoint,
                json={
                    'userId': user_id,
                    'records': history,
                    'timestamp': datetime.utcnow().isoformat()
                },
                timeout=5,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code in [200, 201]:
                print(f"✅ Behavior history saved: {len(history)} records")
                return True
            else:
                return False
                
        except Exception as e:
            print(f"❌ History save error: {e}")
            return False
    
    def save_model_state(self, model_name: str, state_data: Dict) -> bool:
        """Save AI model state"""
        try:
            endpoint = f"{self.api_base}/ai/model-state"
            response = requests.post(
                endpoint,
                json={
                    'modelName': model_name,
                    'state': state_data,
                    'timestamp': datetime.utcnow().isoformat()
                },
                timeout=5,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code in [200, 201]:
                print(f"✅ Model state saved: {model_name}")
                return True
            else:
                return False
                
        except Exception as e:
            print(f"❌ Model save error: {e}")
            return False
    
    def load_model_state(self, model_name: str) -> Optional[Dict]:
        """Load AI model state"""
        try:
            endpoint = f"{self.api_base}/ai/model-state/{model_name}"
            response = requests.get(endpoint, timeout=5)
            
            if response.status_code == 200:
                state = response.json().get('data', {})
                print(f"✅ Model state loaded: {model_name}")
                return state
            else:
                return None
                
        except Exception as e:
            print(f"❌ Model load error: {e}")
            return None
    
    def clear_cache(self, user_id: Optional[str] = None):
        """Clear profile cache"""
        if user_id:
            if user_id in self.cache:
                del self.cache[user_id]
        else:
            self.cache.clear()

# Initialize persistence service
persistence = PersistenceService()
