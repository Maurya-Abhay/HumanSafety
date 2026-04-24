import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiService {
  static const baseUrl = AppConstants.baseUrl;
  static const timeout = Duration(seconds: 30);

  static Map<String, String> _getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return fromJson(data);
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized. Please login again.', 401);
      } else if (response.statusCode == 403) {
        throw ApiException('Access denied.', 403);
      } else if (response.statusCode == 404) {
        throw ApiException('Resource not found.', 404);
      } else if (response.statusCode == 500) {
        throw ApiException('Server error. Please try again later.', 500);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Request failed',
          response.statusCode,
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
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/login'),
            headers: _getHeaders(),
            body: jsonEncode({'phone': phone, 'password': password}),
          )
          .timeout(timeout);

      return _handleResponse(response, (json) => AuthResponse.fromJson(json));
    } catch (e) {
      throw ApiException('Login failed: ${e.toString()}', 0);
    }
  }

  static Future<AuthResponse> sendOtp(String phone) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/send-otp'),
            headers: _getHeaders(),
            body: jsonEncode({'phone': phone}),
          )
          .timeout(timeout);

      return _handleResponse(response, (json) => AuthResponse.fromJson(json));
    } catch (e) {
      throw ApiException('OTP send failed: ${e.toString()}', 0);
    }
  }

  static Future<AuthResponse> verifyOtp(String phone, String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/verify-otp'),
            headers: _getHeaders(),
            body: jsonEncode({'phone': phone, 'otp': otp}),
          )
          .timeout(timeout);

      return _handleResponse(response, (json) => AuthResponse.fromJson(json));
    } catch (e) {
      throw ApiException('OTP verification failed: ${e.toString()}', 0);
    }
  }

  static Future<void> logout(String token) async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/logout'),
            headers: _getHeaders(token: token),
          )
          .timeout(timeout);
    } catch (e) {
      throw ApiException('Logout failed: ${e.toString()}', 0);
    }
  }

  // ============ USER ENDPOINTS ============

  static Future<UserProfile> getUserProfile(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/user/profile'),
            headers: _getHeaders(token: token),
          )
          .timeout(timeout);

      return _handleResponse(response, (json) => UserProfile.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to fetch profile: ${e.toString()}', 0);
    }
  }

  static Future<UserProfile> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/v1/user/profile'),
            headers: _getHeaders(token: token),
            body: jsonEncode(data),
          )
          .timeout(timeout);

      return _handleResponse(response, (json) => UserProfile.fromJson(json));
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
      await http
          .post(
            Uri.parse('$baseUrl/api/v1/user/location'),
            headers: _getHeaders(token: token),
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'accuracy': accuracy,
            }),
          )
          .timeout(timeout);
    } catch (e) {
      throw ApiException('Failed to update location: ${e.toString()}', 0);
    }
  }

  // ============ EMERGENCY/CASE ENDPOINTS ============

  static Future<CaseResponse> createPanicAlert(
    String token, {
    required double latitude,
    required double longitude,
    String? description,
    Map<String, dynamic>? sensorData,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/emergency/panic'),
            headers: _getHeaders(token: token),
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'description': description,
              'sensorData': sensorData,
            }),
          )
          .timeout(timeout);

      return _handleResponse(response, (json) => CaseResponse.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to create panic alert: ${e.toString()}', 0);
    }
  }

  static Future<List<CaseItem>> getUserCases(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/emergency/cases'),
            headers: _getHeaders(token: token),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List data = jsonDecode(response.body);
        return data.map((item) => CaseItem.fromJson(item)).toList();
      } else {
        throw ApiException('Failed to fetch cases', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Failed to fetch cases: ${e.toString()}', 0);
    }
  }

  static Future<CaseItem> getCaseDetails(String token, String caseId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/emergency/cases/$caseId'),
            headers: _getHeaders(token: token),
          )
          .timeout(timeout);

      return _handleResponse(response, (json) => CaseItem.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to fetch case details: ${e.toString()}', 0);
    }
  }

  // ============ POLICE ENDPOINTS ============

  static Future<List<CaseItem>> getPoliceAlerts(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/police/alerts'),
            headers: _getHeaders(token: token),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List data = jsonDecode(response.body);
        return data.map((item) => CaseItem.fromJson(item)).toList();
      } else {
        throw ApiException('Failed to fetch alerts', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Failed to fetch alerts: ${e.toString()}', 0);
    }
  }

  static Future<void> acceptCase(String token, String caseId) async {
    try {
      await http
          .put(
            Uri.parse('$baseUrl/api/v1/police/cases/$caseId/accept'),
            headers: _getHeaders(token: token),
          )
          .timeout(timeout);
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
      await http
          .put(
            Uri.parse('$baseUrl/api/v1/police/cases/$caseId/update'),
            headers: _getHeaders(token: token),
            body: jsonEncode({'status': status}),
          )
          .timeout(timeout);
    } catch (e) {
      throw ApiException('Failed to update case status: ${e.toString()}', 0);
    }
  }

  // ============ HOSPITAL ENDPOINTS ============

  static Future<List<CaseItem>> getHospitalAlerts(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/hospital/alerts'),
            headers: _getHeaders(token: token),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List data = jsonDecode(response.body);
        return data.map((item) => CaseItem.fromJson(item)).toList();
      } else {
        throw ApiException('Failed to fetch hospital alerts', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Failed to fetch hospital alerts: ${e.toString()}', 0);
    }
  }

  static Future<void> acceptEmergency(String token, String caseId) async {
    try {
      await http
          .put(
            Uri.parse('$baseUrl/api/v1/hospital/alerts/$caseId/accept'),
            headers: _getHeaders(token: token),
          )
          .timeout(timeout);
    } catch (e) {
      throw ApiException('Failed to accept emergency: ${e.toString()}', 0);
    }
  }

  // ============ ADMIN ENDPOINTS ============

  static Future<AdminStats> getAdminStats(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/admin/analytics'),
            headers: _getHeaders(token: token),
          )
          .timeout(timeout);

      return _handleResponse(response, (json) => AdminStats.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to fetch admin stats: ${e.toString()}', 0);
    }
  }

  static Future<List<CaseItem>> getAdminCases(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/admin/cases'),
            headers: _getHeaders(token: token),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List data = jsonDecode(response.body);
        return data.map((item) => CaseItem.fromJson(item)).toList();
      } else {
        throw ApiException('Failed to fetch cases', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Failed to fetch cases: ${e.toString()}', 0);
    }
  }

  static Future<List<AdminUser>> getAdminUsers(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/admin/users'),
            headers: _getHeaders(token: token),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List data = jsonDecode(response.body);
        return data.map((item) => AdminUser.fromJson(item)).toList();
      } else {
        throw ApiException('Failed to fetch users', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Failed to fetch users: ${e.toString()}', 0);
    }
  }

  static Future<void> blockUser(String token, String userId) async {
    try {
      await http
          .put(
            Uri.parse('$baseUrl/api/v1/admin/users/$userId/block'),
            headers: _getHeaders(token: token),
          )
          .timeout(timeout);
    } catch (e) {
      throw ApiException('Failed to block user: ${e.toString()}', 0);
    }
  }

  // ============ ROLE APPLICATION ENDPOINTS ============

  static Future<RoleApplicationResponse> submitRoleApplication(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/user/role-application'),
            headers: _getHeaders(token: token),
            body: jsonEncode(data),
          )
          .timeout(timeout);

      return _handleResponse(
          response, (json) => RoleApplicationResponse.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to submit role application: ${e.toString()}', 0);
    }
  }

  static Future<RoleApplicationStatus> getRoleApplicationStatus(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/user/role-application'),
            headers: _getHeaders(token: token),
          )
          .timeout(timeout);

      return _handleResponse(
          response, (json) => RoleApplicationStatus.fromJson(json));
    } catch (e) {
      throw ApiException('Failed to fetch role application status: ${e.toString()}', 0);
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
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
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
    return CaseResponse(
      caseId: json['caseId'] ?? '',
      message: json['message'],
      riskLevel: json['riskLevel'] ?? 'medium',
      riskScore: json['riskScore'] ?? 50,
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
