import 'package:dio/dio.dart';
import '../core/cached_http_client.dart';
import '../core/storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  final _client = CachedHttpClient();
  String _baseUrl = 'https://humansafety.onrender.com/api/v1';
  String? _authToken;

  void setBaseUrl(String url) => _baseUrl = url;

  void setAuthToken(String token) => _authToken = token;

  Map<String, dynamic> _getHeaders() {
    return {
      'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    };
  }

  // ============== AUTH ==============
  Future<Map<String, dynamic>> loginWithPassword(String phone, String password) async {
    try {
      final response = await _client.post(
        '$_baseUrl/auth/login',
        data: {'phone': phone, 'password': password},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signup(String phone, String name, String password) async {
    try {
      final response = await _client.post(
        '$_baseUrl/auth/signup',
        data: {'phone': phone, 'name': name, 'password': password},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ============== EMERGENCY ==============
  Future<Map<String, dynamic>> triggerPanic(
    double latitude,
    double longitude, {
    Map<String, dynamic>? sensorData,
  }) async {
    try {
      final response = await _client.post(
        '$_baseUrl/emergency/panic',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (sensorData != null) 'sensorData': sensorData,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestHospital(
    double latitude,
    double longitude, {
    bool emergency = true,
    String? patientName,
    String? medicalCondition,
  }) async {
    try {
      final response = await _client.post(
        '$_baseUrl/hospital/request',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'emergency': emergency,
          if (patientName != null) 'patientName': patientName,
          if (medicalCondition != null) 'medicalCondition': medicalCondition,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ============== HOSPITAL ==============
  Future<Map<String, dynamic>> searchHospitals(
    double latitude,
    double longitude, {
    double radius = 15,
    String? specialization,
  }) async {
    try {
      final response = await _client.getWithCache(
        '$_baseUrl/hospital/search?latitude=$latitude&longitude=$longitude&radius=$radius${specialization != null ? '&specialization=$specialization' : ''}',
        cacheDuration: const Duration(hours: 2),
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getHospitalDetails(String hospitalId) async {
    try {
      final response = await _client.getWithCache(
        '$_baseUrl/hospital/$hospitalId',
        cacheDuration: const Duration(hours: 4),
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ============== POLICE CASES ==============
  Future<Map<String, dynamic>> searchCases({
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String query = '$_baseUrl/case/search?';
      if (status != null) query += 'status=$status&';
      if (type != null) query += 'type=$type&';
      if (startDate != null) query += 'startDate=${startDate.toIso8601String()}&';
      if (endDate != null) query += 'endDate=${endDate.toIso8601String()}&';

      // Remove trailing & if present
      final cleanQuery = query.endsWith('&') ? query.substring(0, query.length - 1) : query;
      final response = await _client.getWithCache(cleanQuery);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCaseDetails(String caseId) async {
    try {
      final response = await _client.getWithCache('$_baseUrl/case/$caseId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> acceptCase(String caseId, {int? eta}) async {
    try {
      final response = await _client.post(
        '$_baseUrl/case/$caseId/accept',
        data: {'eta': eta ?? 10},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCaseStatus(String caseId, String status) async {
    try {
      final response = await _client.put(
        '$_baseUrl/case/$caseId/status',
        data: {'status': status},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateFIR(
    String caseId, {
    required String firDetails,
    List<String>? witnesses,
    List<String>? vehicles,
  }) async {
    try {
      final response = await _client.post(
        '$_baseUrl/case/$caseId/fir',
        data: {
          'firstInformationReport': firDetails,
          if (witnesses != null) 'witnessNames': witnesses,
          if (vehicles != null) 'vehicleNumbers': vehicles,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ============== AMBULANCE ==============
  Future<Map<String, dynamic>> updateAmbulanceLocation(
    double latitude,
    double longitude, {
    String? address,
  }) async {
    try {
      final response = await _client.post(
        '$_baseUrl/ambulance/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (address != null) 'address': address,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> acceptEmergency(String emergencyId, {int? eta}) async {
    try {
      final response = await _client.post(
        '$_baseUrl/ambulance/$emergencyId/accept',
        data: {'eta': eta ?? 15},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markAmbulanceArrived(String emergencyId) async {
    try {
      final response = await _client.post(
        '$_baseUrl/ambulance/$emergencyId/arrived',
        data: {},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeEmergency(
    String emergencyId, {
    String? patientCondition,
    String? treatmentGiven,
  }) async {
    try {
      final response = await _client.post(
        '$_baseUrl/ambulance/$emergencyId/complete',
        data: {
          if (patientCondition != null) 'patientCondition': patientCondition,
          if (treatmentGiven != null) 'treatmentGiven': treatmentGiven,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAmbulanceStatus() async {
    try {
      final response = await _client.getWithCache('$_baseUrl/ambulance/status');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ============== USER PROFILE ==============
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _client.getWithCache('$_baseUrl/user/profile');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final response = await _client.put(
        '$_baseUrl/user/profile',
        data: data,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ============== UTILITY ==============
  void clearCache() {
    _client.clearCache();
  }
}
