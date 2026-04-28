import 'package:flutter/material.dart';
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

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isVerified = false,
    this.createdAt,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      avatar: json['avatar'],
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
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
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
    this.isRead = false,
    required this.createdAt,
    this.userId,
  });

  bool get read => isRead;
  DateTime get timestamp => createdAt;

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
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
}

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _token;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;
  String? get token => _token;

  AuthProvider() {
    loadSavedLogin();
  }

  Future<void> loadSavedLogin() async {
    _token = await StorageService.getString(AppConstants.tokenKey);
    final data = await StorageService.getJson(AppConstants.userKey);
    if (data != null) {
      _user = User.fromJson(data);
    }
    notifyListeners();
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔐 Attempting login for phone: $phone');
      final result = await ApiService.login(phone, password);
      _token = result.token;
      
      if (result.token != null && result.user != null) {
        _user = User.fromJson(result.user!);
        await StorageService.saveString(AppConstants.tokenKey, _token!);
        await StorageService.saveJson(AppConstants.userKey, _user!.toJson());
        print('✅ Login successful for user: ${_user!.name}');
        return true;
      }
      _error = 'Login failed - no token received';
      print('❌ Login failed - no token received');
      return false;
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

  Future<bool> signup(String phone, String password, String name, String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.signup(phone, password, name, email);
      _token = result.token;
      
      if (result.token != null && result.user != null) {
        _user = User.fromJson(result.user!);
        await StorageService.saveString(AppConstants.tokenKey, _token!);
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
      _user = null;
      _token = null;
      _error = null;
      notifyListeners();
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
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

  Future<void> reportIncident(double latitude, double longitude, String details) async {
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
      // TODO: Implement API call
      await Future.delayed(const Duration(seconds: 1));
      _stats = {
        'totalUsers': 150,
        'totalCases': 45,
        'resolvedCases': 32,
        'avgResponseTime': 8.5,
      };
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStats([String? token]) async {
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
        Contact(id: '1', name: 'Police Emergency', phone: '100', relation: 'Emergency Service'),
        Contact(id: '2', name: 'Ambulance', phone: '108', relation: 'Medical Emergency'),
        Contact(id: '3', name: 'Fire Service', phone: '101', relation: 'Fire Emergency'),
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
