import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network_client.dart';
import 'dart:convert';
import '../core/api_service.dart';
import '../core/storage_service.dart';
import '../core/constants.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isVerified;
  final DateTime? createdAt;
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

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isVerified = false,
    this.createdAt,
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
  });

  int get profileCompletion {
    final fields = [
      name,
      email,
      phone,
      address,
      gender,
      dateOfBirth,
      bloodGroup,
      medicalConditions,
      emergencyContact,
      avatar,
    ];
    final filled =
        fields.where((value) => value != null && value.isNotEmpty).length;
    return ((filled / fields.length) * 100).round();
  }

  bool get isProfileComplete => profileCompletion >= 80;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      avatar: json['avatar'],
      address: json['address'] ?? json['location'] ?? '',
      gender: json['gender'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? json['dob'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      medicalConditions:
          json['medicalConditions'] ?? json['medical_history'] ?? '',
      emergencyContact: json['emergencyContact'] ?? '',
      emergencyContactName:
          json['emergencyContactName'] ?? json['emergency_name'] ?? '',
      occupation: json['occupation'] ?? '',
      about: json['about'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isVerified': isVerified,
      'createdAt': createdAt?.toIso8601String(),
      'avatar': avatar,
      'address': address,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'bloodGroup': bloodGroup,
      'medicalConditions': medicalConditions,
      'emergencyContact': emergencyContact,
      'emergencyContactName': emergencyContactName,
      'occupation': occupation,
      'about': about,
    };
  }
}

class Case {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime createdAt;
  final String? location;
  final String? userId;

  Case({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.location,
    this.userId,
  });

  factory Case.fromJson(Map<String, dynamic> json) {
    return Case(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      location: json['location'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'location': location,
      'userId': userId,
    };
  }
}

class Notification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? userId;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    bool? isRead,
    bool? read,
    DateTime? createdAt,
    DateTime? timestamp,
    this.userId,
  })  : isRead = isRead ?? read ?? false,
        createdAt = createdAt ?? timestamp ?? DateTime.now();

  bool get read => isRead;
  DateTime get timestamp => createdAt;

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  Notification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    bool? read,
    DateTime? createdAt,
    String? userId,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? read ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;
  String? _token;
  DateTime? _lastLoginTime;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isSessionExpired =>
      _lastLoginTime != null &&
      DateTime.now().difference(_lastLoginTime!).inDays >= 30;
  bool get isAuthenticated =>
      _token != null && _user != null && !isSessionExpired;
  String? get token => _token;

  AuthProvider() {
    loadSavedLogin();
  }

  Future<void> loadSavedLogin() async {
    _isInitializing = true;
    notifyListeners();

    _token = await StorageService.getString(AppConstants.tokenKey);
    final loginTime = await StorageService.getString(AppConstants.loginTimeKey);
    if (loginTime != null) {
      _lastLoginTime = DateTime.tryParse(loginTime);
    }

    if (_lastLoginTime != null && isSessionExpired) {
      await logout();
      _isInitializing = false;
      notifyListeners();
      return;
    }

    final data = await StorageService.getJson(AppConstants.userKey);
    if (data != null) {
      _user = User.fromJson(data);
    }

    _isInitializing = false;
    notifyListeners();
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔐 Attempting login for phone: $phone');
      final result = await ApiService.login(phone, password);

      if (result.token == null) {
        _error = 'Login failed - no token received';
        print('❌ Login failed - no token received');
        return false;
      }

      _token = result.token;

      final loginUser =
          result.user != null ? User.fromJson(result.user!) : null;
      User resolvedUser = loginUser ??
          User(
            id: '',
            name: '',
            email: '',
            phone: phone,
            role: 'user',
          );

      if (resolvedUser.role == 'user' || resolvedUser.name.isEmpty) {
        try {
          final profile = await ApiService.getUserProfile(_token!);
          resolvedUser = User(
            id: profile.id.isNotEmpty ? profile.id : resolvedUser.id,
            name: profile.name.isNotEmpty ? profile.name : resolvedUser.name,
            email:
                profile.email.isNotEmpty ? profile.email : resolvedUser.email,
            phone:
                profile.phone.isNotEmpty ? profile.phone : resolvedUser.phone,
            role: profile.role.isNotEmpty ? profile.role : resolvedUser.role,
            avatar: profile.avatar ?? resolvedUser.avatar,
            createdAt: profile.createdAt ?? resolvedUser.createdAt,
          );
        } catch (e) {
          debugPrint('⚠️ Profile refresh skipped after login: $e');
        }
      }

      _user = resolvedUser;
      _lastLoginTime = DateTime.now();
      await StorageService.saveString(AppConstants.tokenKey, _token!);
      await StorageService.saveString(
          AppConstants.loginTimeKey, _lastLoginTime!.toIso8601String());
      await StorageService.saveJson(AppConstants.userKey, _user!.toJson());
      print('✅ Login successful for user: ${_user!.name} (${_user!.role})');
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    if (_token == null) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await ApiService.getUserProfile(_token!);
      _user = User(
        id: profile.id,
        name: profile.name,
        email: profile.email,
        phone: profile.phone,
        role: profile.role,
        avatar: profile.avatar,
        createdAt: profile.createdAt,
      );
      await StorageService.saveJson(AppConstants.userKey, _user!.toJson());
      notifyListeners();

      return {
        '_id': profile.id,
        'id': profile.id,
        'name': profile.name,
        'email': profile.email,
        'phone': profile.phone,
        'role': profile.role,
      };
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.sendOtp(phone);
      return true;
    } catch (e) {
      _error = e.toString();
      print('Send OTP error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.verifyOtp(phone, otp);
      _token = result.token;

      if (result.token != null && result.user != null) {
        _user = User.fromJson(result.user!);
        await StorageService.saveString(AppConstants.tokenKey, _token!);
        await StorageService.saveJson(AppConstants.userKey, _user!.toJson());
        return true;
      }
      _error = 'OTP verification failed';
      return false;
    } catch (e) {
      _error = e.toString();
      print('OTP verification error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(
      String phone, String password, String name, String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.signup(phone, password, name, email);
      _token = result.token;

      if (result.token != null && result.user != null) {
        _user = User.fromJson(result.user!);
        _lastLoginTime = DateTime.now();
        await StorageService.saveString(AppConstants.tokenKey, _token!);
        await StorageService.saveString(
            AppConstants.loginTimeKey, _lastLoginTime!.toIso8601String());
        await StorageService.saveJson(AppConstants.userKey, _user!.toJson());
        return true;
      }
      _error = 'Signup failed';
      return false;
    } catch (e) {
      _error = e.toString();
      print('Signup error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await ApiService.logout(_token!);
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await StorageService.delete(AppConstants.tokenKey);
      await StorageService.delete(AppConstants.userKey);
      await StorageService.delete(AppConstants.loginTimeKey);
      _user = null;
      _token = null;
      _error = null;
      _lastLoginTime = null;
      notifyListeners();
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    loadSavedTheme();
  }

  Future<void> loadSavedTheme() async {
    _isDarkMode = await StorageService.getBool('theme_dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await StorageService.saveBool('theme_dark_mode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    await StorageService.saveBool('theme_dark_mode', _isDarkMode);
    notifyListeners();
  }
}

class RoleProvider extends ChangeNotifier {
  String _currentRole = 'user';
  String get currentRole => _currentRole;

  void setRole(String role) {
    _currentRole = role;
    notifyListeners();
  }
}

class CasesProvider extends ChangeNotifier {
  List<Case> _cases = [];
  bool _isLoading = false;
  String? _error;

  List<Case> get cases => _cases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement API call
      await Future.delayed(const Duration(seconds: 1));
      _cases = [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCases([String? userId]) async {
    await loadCases();
  }

  Future<void> reportIncident(
      double latitude, double longitude, String details) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _cases.insert(
        0,
        Case(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Incident Report',
          description: details,
          status: 'active',
          priority: 'high',
          createdAt: DateTime.now(),
          location: '$latitude,$longitude',
          userId: _cases.isNotEmpty ? _cases.first.userId : null,
        ),
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class NotificationsProvider extends ChangeNotifier {
  List<Notification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement API call
      await Future.delayed(const Duration(seconds: 1));
      _notifications = [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> load([String? userId]) async {
    await loadNotifications();
  }

  Future<void> markAsRead(String notificationId, [String? token]) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    final existing = _notifications[index];
    _notifications[index] = Notification(
      id: existing.id,
      title: existing.title,
      message: existing.message,
      type: existing.type,
      isRead: true,
      createdAt: existing.createdAt,
      userId: existing.userId,
    );
    notifyListeners();
  }

  Future<void> delete(String notificationId, [String? token]) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }
}

class StatsProvider extends ChangeNotifier {
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _error;
  String? _token;

  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed properties for easy access
  int get totalUsers => _stats['totalUsers'] ?? 0;
  int get totalCases => _stats['totalCases'] ?? 0;
  int get resolvedCases => _stats['resolvedCases'] ?? 0;
  double get avgResponseTime => (_stats['avgResponseTime'] ?? 0.0).toDouble();

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_token == null) {
        _error = 'No token available';
        _isLoading = false;
        notifyListeners();
        return;
      }

      try {
        final dio = NetworkClient().client;
        final resp = await dio.get('/api/v1/admin/dashboard',
            options: Options(headers: _token != null ? {'Authorization': 'Bearer $_token'} : null));
        if (resp.statusCode == 200) {
          final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
          _stats = (data as Map<String, dynamic>)['stats'] ?? {};
        } else {
          _error = 'Failed to fetch stats: ${resp.statusCode}';
        }
      } catch (e) {
        _error = 'Failed to fetch stats: $e';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStats([String? token]) async {
    if (token != null) {
      _token = token;
    }
    await loadStats();
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
      relation: json['relation'] ?? '',
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

class ContactsProvider extends ChangeNotifier {
  List<Contact> _contacts = [];
  bool _isLoading = false;
  String? _error;

  List<Contact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ContactsProvider() {
    loadContacts();
  }

  Future<void> loadContacts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement storage loading
      _contacts = [
        Contact(
            id: '1',
            name: 'Police Emergency',
            phone: '100',
            relation: 'Emergency Service'),
        Contact(
            id: '2',
            name: 'Ambulance',
            phone: '108',
            relation: 'Medical Emergency'),
        Contact(
            id: '3',
            name: 'Fire Service',
            phone: '101',
            relation: 'Fire Emergency'),
      ];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addContact(String name, String phone, String relation) async {
    try {
      final newContact = Contact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phone: phone,
        relation: relation,
      );
      _contacts.add(newContact);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      _contacts.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
