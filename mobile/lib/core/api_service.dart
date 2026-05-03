import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'network_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';
import 'constants.dart';
import 'storage_service.dart';

class ApiService {
  static final baseUrl = AppConstants.baseUrl;
  static const timeout = Duration(seconds: 30);

  // WebSocket
  static WebSocketChannel? _channel;
  static StreamSubscription? _subscription;
  static final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  static bool _isConnected = false;

  static Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  static bool get isWebSocketConnected => _isConnected;

  static Map<String, String> _getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Returns a valid token; refreshes if close to expiry.
  static Future<String?> getValidToken() async {
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token == null) return null;

      // Decode token expiry (simple parse, not verifying signature)
      final parts = token.split('.');
      if (parts.length != 3) return token;

      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload['exp'];
      if (exp == null) return token;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now().toUtc();
      final diff = expiry.difference(now);

      // If token has less than 5 minutes remaining, attempt refresh
      if (diff.inSeconds < 300) {
        try {
          final dio = NetworkClient().client;
          final resp = await dio.post('/api/v1/auth/refresh-token', data: {'token': token});
          if (resp.statusCode == 200) {
            final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
            final newToken = (data as Map<String, dynamic>)['token'] as String?;
            if (newToken != null) {
              await StorageService.saveString(AppConstants.tokenKey, newToken);
              return newToken;
            }
          }
        } catch (e) {
          debugPrint('Token refresh failed: $e');
        }
      }

      return token;
    } catch (e) {
      debugPrint('getValidToken error: $e');
      return await StorageService.getString(AppConstants.tokenKey);
    }
  }

  static Future<T> _handleResponse<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      int? statusCode;
      dynamic body;
      if (response == null) throw ApiException('No response', 0);

      // Dio Response
      if (response is Response) {
        statusCode = response.statusCode;
        body = response.data;
      } else {
        // Fallback: assume Map/String
        statusCode = response['statusCode'] as int?;
        body = response['body'] ?? response;
      }

      if (statusCode != null && statusCode >= 200 && statusCode < 300) {
        final data = body is String ? jsonDecode(body) as Map<String, dynamic> : body as Map<String, dynamic>;
        return fromJson(data);
      } else if (statusCode == 401) {
        throw ApiException('Unauthorized. Please login again.', 401);
      } else if (statusCode == 403) {
        throw ApiException('Access denied.', 403);
      } else if (statusCode == 404) {
        throw ApiException('Resource not found.', 404);
      } else if (statusCode == 500) {
        throw ApiException('Server error. Please try again later.', 500);
      } else {
        final parsed = body is String ? jsonDecode(body) : body;
        throw ApiException(
          parsed is Map ? (parsed['message'] ?? 'Request failed') : 'Request failed',
          statusCode ?? 0,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to parse response: $e', 0);
    }
  }

  // ============ AUTH ENDPOINTS ============

  static Future<AuthResponse> login(String phone, String password) async {
    try {
      print('🌐 Making login request to: $baseUrl/api/v1/auth/login');
      final dio = NetworkClient().client;
      final resp = await dio.post('/api/v1/auth/login', data: {'phone': phone, 'password': password});
      return _handleResponse(resp, (json) => AuthResponse.fromJson(json));
    } catch (e) {
      print('❌ Login API error: $e');
      throw ApiException('Login failed: ${e.toString()}', 0);
    }
  }

  static Future<AuthResponse> signup(String phone, String password, String fullName, String email) async {
    try {
      print('🌐 Making signup request to: $baseUrl/api/v1/auth/signup');
      final dio = NetworkClient().client;
      final resp = await dio.post('/api/v1/auth/signup', data: {
        'phone': phone,
        'password': password,
        'fullName': fullName,
        'email': email,
      });
      return _handleResponse(resp, (json) => AuthResponse.fromJson(json));
    } catch (e) {
      print('❌ Signup API error: $e');
      throw ApiException('Signup failed: ${e.toString()}', 0);
    }
  }

  static Future<AuthResponse> sendOtp(String phone) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.post('/api/v1/auth/send-otp', data: {'phone': phone});
      return _handleResponse(resp, (json) => AuthResponse.fromJson(json));
    } catch (e) {
      throw ApiException('OTP send failed: ${e.toString()}', 0);
    }
  }

  static Future<AuthResponse> verifyOtp(String phone, String otp) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.post('/api/v1/auth/verify-otp', data: {'phone': phone, 'otp': otp});
      return _handleResponse(resp, (json) => AuthResponse.fromJson(json));
    } catch (e) {
      throw ApiException('OTP verification failed: ${e.toString()}', 0);
    }
  }

  static Future<void> logout(String token) async {
    try {
      final dio = NetworkClient().client;
      await dio.post('/api/v1/auth/logout');
    } catch (e) {
      throw ApiException('Logout failed: ${e.toString()}', 0);
    }
  }

  // ============ USER ENDPOINTS ============

  static Future<UserProfile> getUserProfile(String token) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/user/profile');
      return _handleResponse(resp, (json) => UserProfile.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to fetch profile: ${e.toString()}', 0);
    }
  }

  static Future<UserProfile> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.put('/api/v1/user/profile', data: data);
      return _handleResponse(resp, (json) => UserProfile.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to update profile: ${e.toString()}', 0);
    }
  }

  static Future<void> updateLocation(
    String token,
    double latitude,
    double longitude,
    double accuracy,
  ) async {
    try {
      final dio = NetworkClient().client;
      await dio.post('/api/v1/user/location', data: {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      });
    } catch (e) {
      throw ApiException('Failed to update location: ${e.toString()}', 0);
    }
  }

  // ============ EMERGENCY/CASE ENDPOINTS ============

  /// Analyze sensor data through AI engine to get risk score
  static Future<Map<String, dynamic>?> analyzeAccident(
    String token,
    Map<String, dynamic> sensorData,
  ) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.post('/api/v1/accident/analyze', data: sensorData);
      if (resp.statusCode == 200) {
        return resp.data as Map<String, dynamic>;
      } else if (resp.statusCode == 401) {
        throw ApiException('Unauthorized', 401);
      } else {
        throw ApiException('Failed to analyze accident: ${resp.statusCode}', resp.statusCode ?? 0);
      }
    } catch (e) {
      throw ApiException('Failed to analyze accident: ${e.toString()}', 0);
    }
  }

  static Future<CaseResponse> createPanicAlert(
    String token, {
    required double latitude,
    required double longitude,
    String? description,
    Map<String, dynamic>? sensorData,
  }) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.post('/api/v1/emergency/panic', data: {
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'sensorData': sensorData,
      });

      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        return CaseResponse.fromJson(data as Map<String, dynamic>);
      } else if (resp.statusCode == 401) {
        throw ApiException('Unauthorized', 401);
      } else {
        throw ApiException('Failed to create panic alert: ${resp.statusCode}', resp.statusCode ?? 0);
      }
    } catch (e) {
      throw ApiException('Failed to create panic alert: ${e.toString()}', 0);
    }
  }

  static Future<HelpRequestResponse> requestHelp(
    String token, {
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.post('/api/v1/help/request', data: {
        'latitude': latitude,
        'longitude': longitude,
        'description': description ?? 'User needs nearby help',
      });

      final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
      return HelpRequestResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException('Failed to request help: ${e.toString()}', 0);
    }
  }

  static Future<HelpRequestResponse> acceptHelp(
    String token, {
    required String helpRequestId,
  }) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.post('/api/v1/help/accept', data: {'helpRequestId': helpRequestId});
      return _handleResponse(resp, (json) => HelpRequestResponse.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to accept help: ${e.toString()}', 0);
    }
  }

  static Future<HelpRequestResponse> rejectHelp(
    String token, {
    required String helpRequestId,
  }) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.post('/api/v1/help/reject', data: {'helpRequestId': helpRequestId});
      return _handleResponse(resp, (json) => HelpRequestResponse.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to reject help: ${e.toString()}', 0);
    }
  }

  static Future<HelpRequestResponse> completeHelp(
    String token, {
    required String helpRequestId,
  }) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.post('/api/v1/help/complete', data: {'helpRequestId': helpRequestId});
      return _handleResponse(resp, (json) => HelpRequestResponse.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to complete help: ${e.toString()}', 0);
    }
  }

  static Future<List<CaseItem>> getUserCases(String token) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/emergency/cases');
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        return (data as List).map((item) => CaseItem.fromJson(item)).toList();
      } else {
        throw ApiException('Failed to fetch cases', resp.statusCode ?? 0);
      }
    } catch (e) {
      throw ApiException('Failed to fetch cases: ${e.toString()}', 0);
    }
  }

  static Future<CaseItem> getCaseDetails(String token, String caseId) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/emergency/cases/$caseId');
      final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
      return CaseItem.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException('Failed to fetch case details: ${e.toString()}', 0);
    }
  }

  // ============ POLICE ENDPOINTS ============

  static Future<List<CaseItem>> getPoliceAlerts(String token) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/police/alerts');
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        return (data as List).map((item) => CaseItem.fromJson(item)).toList();
      } else {
        throw ApiException('Failed to fetch alerts', resp.statusCode ?? 0);
      }
    } catch (e) {
      throw ApiException('Failed to fetch alerts: ${e.toString()}', 0);
    }
  }

  static Future<void> acceptCase(String token, String caseId) async {
    try {
      final dio = NetworkClient().client;
      await dio.put('/api/v1/police/cases/$caseId/accept');
    } catch (e) {
      throw ApiException('Failed to accept case: ${e.toString()}', 0);
    }
  }

  static Future<void> updateCaseStatus(
    String token,
    String caseId,
    String status,
  ) async {
    try {
      final dio = NetworkClient().client;
      await dio.put('/api/v1/police/cases/$caseId/update', data: {'status': status});
    } catch (e) {
      throw ApiException('Failed to update case status: ${e.toString()}', 0);
    }
  }

  // ============ HOSPITAL ENDPOINTS ============

  static Future<List<CaseItem>> getHospitalAlerts(String token) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/hospital/alerts');
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        return (data as List).map((item) => CaseItem.fromJson(item)).toList();
      } else {
        final body = resp.data is String ? jsonDecode(resp.data) : resp.data;
        final message = body is Map && body['message'] != null ? body['message'] : 'Failed to fetch hospital alerts';
        throw ApiException(message, resp.statusCode ?? 0);
      }
    } on DioError catch (de) {
      final resp = de.response;
      if (resp != null) {
        final body = resp.data is String ? jsonDecode(resp.data) : resp.data;
        final message = body is Map && body['message'] != null ? body['message'] : 'Server error';
        throw ApiException(message, resp.statusCode ?? 0);
      }
      throw ApiException('Network error: ${de.message}', 0);
    } catch (e) {
      throw ApiException('Failed to fetch hospital alerts: ${e.toString()}', 0);
    }
  }

  static Future<void> acceptEmergency(String token, String caseId) async {
    try {
      final dio = NetworkClient().client;
      await dio.put('/api/v1/hospital/alerts/$caseId/accept');
    } catch (e) {
      throw ApiException('Failed to accept emergency: ${e.toString()}', 0);
    }
  }

  static Future<List<HospitalFacility>> getActiveHospitals(String token) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/hospital-admin/active');
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        final hospitals = (data is Map && data['hospitals'] is List) ? data['hospitals'] as List : <dynamic>[];
        return hospitals.map((item) => HospitalFacility.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw ApiException('Failed to fetch active hospitals', resp.statusCode ?? 0);
    } catch (e) {
      throw ApiException('Failed to fetch active hospitals: ${e.toString()}', 0);
    }
  }

  static Future<void> updateHospitalBeds(String token, int availableBeds) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.post(
        '/api/v1/hospital-admin/update-beds',
        data: {'availableBeds': availableBeds},
      );
      if (resp.statusCode == null || resp.statusCode! < 200 || resp.statusCode! >= 300) {
        throw ApiException('Failed to update bed availability', resp.statusCode ?? 0);
      }
    } catch (e) {
      throw ApiException('Failed to update bed availability: ${e.toString()}', 0);
    }
  }

  static Future<Map<String, dynamic>> updateHospitalProfile(
    String token, {
    String? hospitalName,
    String? phone,
    String? address,
    List<String>? specializations,
    String? contactPerson,
  }) async {
    try {
      final dio = NetworkClient().client;
      final data = <String, dynamic>{};
      if (hospitalName != null) data['hospitalName'] = hospitalName;
      if (phone != null) data['phone'] = phone;
      if (address != null) data['address'] = address;
      if (specializations != null) data['specializations'] = specializations;
      if (contactPerson != null) data['contactPerson'] = contactPerson;

      final resp = await dio.put(
        '/api/v1/hospital-admin/profile',
        data: data,
      );
      if (resp.statusCode == null || resp.statusCode! < 200 || resp.statusCode! >= 300) {
        throw ApiException('Failed to update hospital profile', resp.statusCode ?? 0);
      }
      final responseData = resp.data is String ? jsonDecode(resp.data) : resp.data;
      return (responseData is Map) ? responseData['hospital'] ?? responseData : {};
    } catch (e) {
      throw ApiException('Failed to update hospital profile: ${e.toString()}', 0);
    }
  }

  static Future<Map<String, dynamic>> updateAlertStatus(String token, String alertId, String status) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.put(
        '/api/v1/hospital/alerts/$alertId/status',
        data: {'status': status},
      );
      if (resp.statusCode == null || resp.statusCode! < 200 || resp.statusCode! >= 300) {
        throw ApiException('Failed to update alert status', resp.statusCode ?? 0);
      }
      final responseData = resp.data is String ? jsonDecode(resp.data) : resp.data;
      return (responseData is Map) ? responseData['alert'] ?? responseData : {};
    } catch (e) {
      throw ApiException('Failed to update alert status: ${e.toString()}', 0);
    }
  }

  // ============ AMBULANCE ENDPOINTS ============

  static Future<List<AmbulanceInfo>> getHospitalAmbulances(String token) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/ambulance');
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        final ambulances = (data is Map && data['ambulances'] is List) ? data['ambulances'] as List : <dynamic>[];
        return ambulances.map((item) => AmbulanceInfo.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw ApiException('Failed to fetch ambulances', resp.statusCode ?? 0);
    } catch (e) {
      throw ApiException('Failed to fetch ambulances: ${e.toString()}', 0);
    }
  }

  static Future<Map<String, dynamic>> getAmbulanceLocation(String token, String ambulanceId) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/ambulance/$ambulanceId/location');
      if (resp.statusCode == null || resp.statusCode! < 200 || resp.statusCode! >= 300) {
        throw ApiException('Failed to fetch ambulance location', resp.statusCode ?? 0);
      }
      final responseData = resp.data is String ? jsonDecode(resp.data) : resp.data;
      if (responseData is Map) {
        return Map<String, dynamic>.from(responseData);
      }
      return <String, dynamic>{};
    } catch (e) {
      throw ApiException('Failed to fetch ambulance location: ${e.toString()}', 0);
    }
  }

  static Future<void> updateAmbulanceLocation(String token, double latitude, double longitude, String? address) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.put(
        '/api/v1/ambulance/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        },
      );
      if (resp.statusCode == null || resp.statusCode! < 200 || resp.statusCode! >= 300) {
        throw ApiException('Failed to update ambulance location', resp.statusCode ?? 0);
      }
    } catch (e) {
      throw ApiException('Failed to update ambulance location: ${e.toString()}', 0);
    }
  }

  static Future<void> markAmbulanceArrived(String token, String ambulanceId) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.put('/api/v1/ambulance/$ambulanceId/arrived');
      if (resp.statusCode == null || resp.statusCode! < 200 || resp.statusCode! >= 300) {
        throw ApiException('Failed to mark ambulance as arrived', resp.statusCode ?? 0);
      }
    } catch (e) {
      throw ApiException('Failed to mark ambulance as arrived: ${e.toString()}', 0);
    }
  }

  // ============ ADMIN ENDPOINTS ============

  static Future<AdminStats> getAdminStats(String token) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/admin/analytics');
      return _handleResponse(resp, (json) => AdminStats.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to fetch admin stats: ${e.toString()}', 0);
    }
  }

  static Future<List<CaseItem>> getAdminCases(String token) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/admin/cases');
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        return (data as List).map((item) => CaseItem.fromJson(item)).toList();
      } else {
        throw ApiException('Failed to fetch cases', resp.statusCode ?? 0);
      }
    } catch (e) {
      throw ApiException('Failed to fetch cases: ${e.toString()}', 0);
    }
  }

  static Future<List<AdminUser>> getAdminUsers(String token) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/admin/users');
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        return (data as List).map((item) => AdminUser.fromJson(item)).toList();
      } else {
        throw ApiException('Failed to fetch users', resp.statusCode ?? 0);
      }
    } catch (e) {
      throw ApiException('Failed to fetch users: ${e.toString()}', 0);
    }
  }

  static Future<void> blockUser(String token, String userId) async {
    try {
      final dio = NetworkClient().client;
      await dio.put('/api/v1/admin/users/$userId/block');
    } catch (e) {
      throw ApiException('Failed to block user: ${e.toString()}', 0);
    }
  }

  // ============ NOTIFICATION ENDPOINTS ============

  static Future<List<Notification>> getNotifications(String token) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/notifications');
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        return (data as List).map((item) => Notification.fromJson(item)).toList();
      } else {
        throw ApiException('Failed to fetch notifications', resp.statusCode ?? 0);
      }
    } catch (e) {
      throw ApiException('Failed to fetch notifications: ${e.toString()}', 0);
    }
  }

  static Future<void> markNotificationAsRead(String token, String notificationId) async {
    try {
      final dio = NetworkClient().client;
      await dio.put('/api/v1/notifications/$notificationId/read');
    } catch (e) {
      throw ApiException('Failed to mark notification as read: ${e.toString()}', 0);
    }
  }

  static Future<void> deleteNotification(String token, String notificationId) async {
    try {
      final dio = NetworkClient().client;
      await dio.delete('/api/v1/notifications/$notificationId');
    } catch (e) {
      throw ApiException('Failed to delete notification: ${e.toString()}', 0);
    }
  }

  // ============ CONTACT ENDPOINTS ============

  static Future<List<Contact>> getContacts(String token) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/contact/list');
      if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 300) {
        final decoded = resp.data is String ? jsonDecode(resp.data) : resp.data;

        // Handle multiple possible shapes:
        // 1. Raw list: [ {..}, {..} ]
        // 2. Wrapped object: { message: "..", count: N, contacts: [ ... ] }
        List items;
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map && decoded['contacts'] is List) {
          items = decoded['contacts'];
        } else if (decoded is Map && decoded['data'] is List) {
          // fallback for APIs that return { data: [...] }
          items = decoded['data'];
        } else {
          // Unexpected shape: try to coerce single object into a list
          if (decoded is Map) {
            items = [decoded];
          } else {
            items = [];
          }
        }

        return items.map((item) => Contact.fromJson(item)).toList();
      } else {
        throw ApiException('Failed to fetch contacts', resp.statusCode ?? 0);
      }
    } catch (e) {
      throw ApiException('Failed to fetch contacts: ${e.toString()}', 0);
    }
  }

  static Future<Contact> addContact(
    String token, {
    required String name,
    required String phone,
    String? relation,
  }) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.post('/api/v1/contact/add', data: {
        'name': name,
        'phone': phone,
        'relation': relation ?? 'Friend',
      });

      return _handleResponse(resp, (json) => Contact.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to add contact: ${e.toString()}', 0);
    }
  }

  static Future<void> deleteContact(String token, String contactId) async {
    try {
      final dio = NetworkClient().client;
      await dio.delete('/api/v1/contact/remove/$contactId');
    } catch (e) {
      throw ApiException('Failed to delete contact: ${e.toString()}', 0);
    }
  }

  // ============ ROLE APPLICATION ENDPOINTS ============

  static Future<RoleApplicationResponse> submitRoleApplication(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.post('/api/v1/user/role-application', data: data);
      return _handleResponse(resp, (json) => RoleApplicationResponse.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to submit role application: ${e.toString()}', 0);
    }
  }

  static Future<RoleApplicationStatus> getRoleApplicationStatus(String token) async {
    try {
      final dio = NetworkClient().client;
      final resp = await dio.get('/api/v1/user/role-application');
      return _handleResponse(resp, (json) => RoleApplicationStatus.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to fetch role application status: ${e.toString()}', 0);
    }
  }

  // ============ WEBSOCKET METHODS ============

  static Future<void> connectWebSocket(String userId, String role) async {
    if (_isConnected) return;

    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token == null) throw Exception('No authentication token');

      final wsUrl = Uri.parse('${AppConstants.wsUrl}/ws')
          .replace(queryParameters: {
            'userId': userId,
            'role': role,
            'token': token,
          });

      _channel = WebSocketChannel.connect(wsUrl);

      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message) as Map<String, dynamic>;
            _messageController.add(data);
          } catch (e) {
            debugPrint('Failed to parse WebSocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _isConnected = false;
        },
      );

      // Wait for connection to be established
      await _channel!.ready;
      _isConnected = true;
      debugPrint('WebSocket connected');
    } catch (e) {
      debugPrint('Failed to connect WebSocket: $e');
      _isConnected = false;
      rethrow;
    }
  }

  static Future<void> disconnectWebSocket() async {
    await _subscription?.cancel();
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    _isConnected = false;
    debugPrint('WebSocket disconnected');
  }

  static void sendWebSocketMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    } else {
      debugPrint('WebSocket not connected, cannot send message');
    }
  }
}

// ============ RESPONSE MODELS ============

class ApiException implements Exception {
  final String message;
  final int code;

  ApiException(this.message, this.code);

  @override
  String toString() => message;
}

class AuthResponse {
  final String? token;
  final Map<String, dynamic>? user;
  final String? message;

  AuthResponse({this.token, this.user, this.message});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      user: json['user'],
      message: json['message'],
    );
  }
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? avatar;
  final String? address;
  final String? gender;
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? medicalConditions;
  final String? emergencyContact;
  final String? emergencyContactName;
  final String? occupation;
  final String? about;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
    this.address,
    this.gender,
    this.dateOfBirth,
    this.bloodGroup,
    this.medicalConditions,
    this.emergencyContact,
    this.emergencyContactName,
    this.occupation,
    this.about,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      avatar: json['avatar'],
      address: json['address'] ?? json['location'] ?? '',
      gender: json['gender'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? json['dob'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      medicalConditions: json['medicalConditions'] ?? json['medical_history'] ?? '',
      emergencyContact: json['emergencyContact'] ?? '',
      emergencyContactName: json['emergencyContactName'] ?? json['emergency_name'] ?? '',
      occupation: json['occupation'] ?? '',
      about: json['about'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class CaseResponse {
  final String caseId;
  final String? message;
  final String riskLevel;
  final int riskScore;

  CaseResponse({
    required this.caseId,
    this.message,
    required this.riskLevel,
    required this.riskScore,
  });

  factory CaseResponse.fromJson(Map<String, dynamic> json) {
    final alert = json['alert'] is Map<String, dynamic>
        ? json['alert'] as Map<String, dynamic>
        : null;
    final riskAssessment = alert != null && alert['riskAssessment'] is Map<String, dynamic>
        ? alert['riskAssessment'] as Map<String, dynamic>
        : null;

    return CaseResponse(
      caseId: json['caseId'] ?? alert?['id'] ?? alert?['_id'] ?? json['alertId'] ?? json['id'] ?? '',
      message: json['message'] ?? alert?['message'],
      riskLevel: riskAssessment?['riskLevel'] ?? alert?['riskLevel'] ?? json['riskLevel'] ?? 'medium',
      riskScore: riskAssessment?['riskScore'] ?? alert?['riskScore'] ?? json['riskScore'] ?? 50,
    );
  }
}

class HelpRequestResponse {
  final String requestId;
  final String message;
  final int nearbyUsersCount;
  final String status;

  HelpRequestResponse({
    required this.requestId,
    required this.message,
    required this.nearbyUsersCount,
    required this.status,
  });

  factory HelpRequestResponse.fromJson(Map<String, dynamic> json) {
    final request = json['request'] is Map<String, dynamic>
        ? json['request'] as Map<String, dynamic>
        : null;

    return HelpRequestResponse(
      requestId: request?['id'] ?? json['requestId'] ?? json['id'] ?? '',
      message: json['message'] ?? request?['message'] ?? 'Help request processed',
      nearbyUsersCount: request?['nearbyUsersCount'] ?? json['nearbyUsersCount'] ?? 0,
      status: request?['status'] ?? json['status'] ?? 'pending',
    );
  }
}

class CaseItem {
  final String id;
  final String caseId;
  final String status;
  final String type;
  final String riskLevel;
  final int riskScore;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? location;

  CaseItem({
    required this.id,
    required this.caseId,
    required this.status,
    required this.type,
    required this.riskLevel,
    required this.riskScore,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.location,
  });

  factory CaseItem.fromJson(Map<String, dynamic> json) {
    return CaseItem(
      id: json['_id'] ?? json['id'] ?? '',
      caseId: json['caseId'] ?? '',
      status: json['status'] ?? 'created',
      type: json['type'] ?? 'panic',
      riskLevel: json['riskLevel'] ?? 'medium',
      riskScore: json['riskScore'] ?? 50,
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      location: json['location'],
    );
  }
}

class HospitalFacility {
  final String id;
  final String name;
  final String phone;
  final int availableBeds;
  final List<String> specializations;
  final String? address;

  HospitalFacility({
    required this.id,
    required this.name,
    required this.phone,
    required this.availableBeds,
    required this.specializations,
    this.address,
  });

  factory HospitalFacility.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    return HospitalFacility(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      availableBeds: json['availableBeds'] is int
          ? json['availableBeds']
          : int.tryParse('${json['availableBeds'] ?? 0}') ?? 0,
      specializations: json['specializations'] is List
          ? List<String>.from(json['specializations'])
          : const [],
      address: location is Map ? location['address']?.toString() : null,
    );
  }
}

class AdminStats {
  final int totalCases;
  final int resolvedCases;
  final String resolutionRate;
  final int totalUsers;
  final int avgResponseTime;

  AdminStats({
    required this.totalCases,
    required this.resolvedCases,
    required this.resolutionRate,
    required this.totalUsers,
    required this.avgResponseTime,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalCases: json['totalCases'] ?? 0,
      resolvedCases: json['resolvedCases'] ?? 0,
      resolutionRate: json['resolutionRate']?.toString() ?? '0',
      totalUsers: json['totalUsers'] ?? 0,
      avgResponseTime: json['avgResponseTime'] ?? 0,
    );
  }
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isBlocked;
  final DateTime? createdAt;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isBlocked,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      isBlocked: json['isBlocked'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class RoleApplicationResponse {
  final String? applicationId;
  final String status;
  final String? message;

  RoleApplicationResponse({
    this.applicationId,
    required this.status,
    this.message,
  });

  factory RoleApplicationResponse.fromJson(Map<String, dynamic> json) {
    return RoleApplicationResponse(
      applicationId: json['applicationId'],
      status: json['status'] ?? 'pending',
      message: json['message'],
    );
  }
}

class RoleApplicationStatus {
  final bool hasApplication;
  final Map<String, dynamic>? application;

  RoleApplicationStatus({
    required this.hasApplication,
    this.application,
  });

  factory RoleApplicationStatus.fromJson(Map<String, dynamic> json) {
    return RoleApplicationStatus(
      hasApplication: json['hasApplication'] ?? false,
      application: json['application'],
    );
  }
}

class Notification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final int priority;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.priority,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'alert',
      isRead: json['isRead'] ?? false,
      priority: json['priority'] ?? 2,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Contact {
  final String id;
  final String name;
  final String phone;
  final String relation;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relation: json['relation'] ?? 'Friend',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relation': relation,
    };
  }
}

class AmbulanceInfo {
  final String id;
  final String licenseNumber;
  final String driverName;
  final String status;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? eta;
  final String? assignedPatient;
  final bool isOnline;

  AmbulanceInfo({
    required this.id,
    required this.licenseNumber,
    required this.driverName,
    required this.status,
    this.location,
    this.eta,
    this.assignedPatient,
    this.isOnline = false,
  });

  factory AmbulanceInfo.fromJson(Map<String, dynamic> json) {
    return AmbulanceInfo(
      id: json['id'] ?? json['_id'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      driverName: json['driverName'] ?? '',
      status: json['status'] ?? 'available',
      location: json['location'] is Map ? json['location'] as Map<String, dynamic> : null,
      eta: json['eta'] is Map ? json['eta'] as Map<String, dynamic> : null,
      assignedPatient: json['assignedPatient'],
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licenseNumber': licenseNumber,
      'driverName': driverName,
      'status': status,
      'location': location,
      'eta': eta,
      'assignedPatient': assignedPatient,
      'isOnline': isOnline,
    };
  }
}
