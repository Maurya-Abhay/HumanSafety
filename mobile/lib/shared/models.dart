import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../core/constants.dart';
import '../core/storage_service.dart';
import '../core/api_service.dart';

/// =======================
/// MODELS
/// =======================

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? avatar;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final roleText = (json['role'] ?? 'user').toString();
    return User(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == roleText,
        orElse: () => UserRole.user,
      ),
      avatar: json['avatar'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SafetyCase {
  final String id;
  final String title;
  final String description;
  final String status;
  final String location;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  SafetyCase({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.location,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory SafetyCase.fromJson(Map<String, dynamic> json) {
    return SafetyCase(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      location: json['location'] ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class AppNotification {
    AppNotification copyWith({
      String? id,
      String? title,
      String? message,
      bool? read,
      DateTime? time,
    }) {
      return AppNotification(
        id: id ?? this.id,
        title: title ?? this.title,
        message: message ?? this.message,
        read: read ?? this.read,
        time: time ?? this.time,
      );
    }

    DateTime get timestamp => time;
  final String id;
  final String title;
  final String message;
  final bool read;
  final DateTime time;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    required this.time,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      time: DateTime.tryParse(json['timestamp'] ?? '') ??
          DateTime.now(),
    );
  }
}

/// =======================
/// AUTH PROVIDER
/// =======================

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _loading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _loading;
  bool get isAuthenticated => _token != null && _user != null;

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
    _loading = true;
    notifyListeners();
    try {
      final result = await ApiService.login(phone, password);
      _token = result.token;
      if (result.token != null && result.user != null) {
        _user = User.fromJson(result.user!);
        await StorageService.saveString(AppConstants.tokenKey, _token!);
        await StorageService.saveJson(AppConstants.userKey, _user!.toJson());
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(String phone, String password, String name) async {
    _loading = true;
    notifyListeners();
    try {
      // For signup, we'll use sendOtp first
      final result = await ApiService.sendOtp(phone);
      _token = result.token;
      if (result.token != null) {
        await StorageService.saveString(AppConstants.tokenKey, _token!);
        return true;
      }
      return false;
    } catch (e) {
      print('Signup error: $e');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> sendOtp(String phone) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await ApiService.sendOtp(phone);
      return result.token != null;
    } catch (e) {
      print('Send OTP error: $e');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _loading = true;
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
      return false;
    } catch (e) {
      print('Verify OTP error: $e');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    await StorageService.delete(AppConstants.tokenKey);
    await StorageService.delete(AppConstants.userKey);
    _user = null;
    _token = null;
    _loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      if (_token == null) return null;
      
      final profile = await ApiService.getUserProfile(_token!);
      // Update local user data
      _user = User(
        id: profile.id,
        name: profile.name,
        email: profile.email,
        phone: profile.phone,
        role: UserRole.values.firstWhere(
          (e) => e.name == profile.role,
          orElse: () => UserRole.user,
        ),
        avatar: profile.avatar,
        createdAt: profile.createdAt ?? DateTime.now(),
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
        'avatar': profile.avatar,
        'createdAt': profile.createdAt?.toIso8601String(),
      };
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }
}

/// =======================
/// ROLE PROVIDER
/// =======================

class RoleProvider extends ChangeNotifier {
  UserRole? _userRole;
  UserRole? get userRole => _userRole;

  RoleProvider() {
    loadRole();
  }

  Future<void> loadRole() async {
    final saved = await StorageService.getString(AppConstants.roleKey);
    if (saved != null) {
      _userRole = UserRole.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => UserRole.user,
      );
    }
    notifyListeners();
  }

  Future<void> setRole(UserRole value) async {
    _userRole = value;
    await StorageService.saveString(AppConstants.roleKey, value.name);
    notifyListeners();
  }
}

/// =======================
/// THEME PROVIDER
/// =======================

class ThemeProvider extends ChangeNotifier {
  bool _dark = false;
  bool get isDarkMode => _dark;

  ThemeProvider() {
    loadTheme();
  }

  Future<void> loadTheme() async {
    _dark = await StorageService.getBool(AppConstants.themeKey) ?? false;
    notifyListeners();
  }

  Future<void> setTheme(bool dark) async {
    _dark = dark;
    await StorageService.saveBool(AppConstants.themeKey, _dark);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _dark = !_dark;
    await StorageService.saveBool(AppConstants.themeKey, _dark);
    notifyListeners();
  }
}

/// =======================
/// CASES PROVIDER
/// =======================

class CasesProvider extends ChangeNotifier {
  List<SafetyCase> _cases = [];
  bool _loading = false;
  String? _error;

  List<SafetyCase> get cases => _cases;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> fetchCases(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final authProvider = await StorageService.getString(AppConstants.tokenKey);
      if (authProvider == null) {
        _error = 'Not authenticated';
        _loading = false;
        notifyListeners();
        return;
      }

      final caseItems = await ApiService.getUserCases(authProvider);
      _cases = caseItems
          .map<SafetyCase>((e) => SafetyCase(
                id: e.id,
                title: e.type,
                description: e.description ?? '',
                status: e.status,
                location: e.location?.toString() ?? 'Unknown',
                createdAt: e.createdAt ?? DateTime.now(),
                latitude: (e.location?['latitude'] as num?)?.toDouble(),
                longitude: (e.location?['longitude'] as num?)?.toDouble(),
              ))
          .toList();
    } catch (e) {
      _error = e.toString();
      _cases = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reportSOS(
    double latitude,
    double longitude,
    String? description,
  ) async {
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token != null) {
        await ApiService.createPanicAlert(
          token,
          latitude: latitude,
          longitude: longitude,
          description: description,
        );
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> reportIncident(
    double latitude,
    double longitude,
    String? description,
  ) async {
    await reportSOS(latitude, longitude, description);
  }
}

/// =======================
/// NOTIFICATION PROVIDER
/// =======================

class NotificationsProvider extends ChangeNotifier {
  List<AppNotification> _items = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // For now, notifications will be empty
      // In a production app, you'd call: 
      // final data = await ApiService.getNotifications(userId);
      _items = [];
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAsRead(String id) {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(read: true);
      notifyListeners();
    }
  }
}

/// =======================
/// STATS PROVIDER
/// =======================

class StatsProvider extends ChangeNotifier {
  AdminStats? _stats;
  bool _isLoading = false;
  String? _error;

  AdminStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStats(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _stats = await ApiService.getAdminStats(token);
    } catch (e) {
      _error = e.toString();
      _stats = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}c l a s s   C o n t a c t   { 
     f i n a l   S t r i n g   i d ; 
     f i n a l   S t r i n g   n a m e ; 
     f i n a l   S t r i n g   p h o n e ; 
     f i n a l   S t r i n g   r e l a t i o n ; 
 
     C o n t a c t ( { 
         r e q u i r e d   t h i s . i d , 
         r e q u i r e d   t h i s . n a m e , 
         r e q u i r e d   t h i s . p h o n e , 
         r e q u i r e d   t h i s . r e l a t i o n , 
     } ) ; 
 
     f a c t o r y   C o n t a c t . f r o m J s o n ( M a p < S t r i n g ,   d y n a m i c >   j s o n )   { 
         r e t u r n   C o n t a c t ( 
             i d :   j s o n [ 
 
 _ i d ]   ? ?   j s o n [ i d ]   ? ?   ' , 
             n a m e :   j s o n [ n a m e ]   ? ?   ' , 
             p h o n e :   j s o n [ p h o n e ]   ? ?   ' , 
             r e l a t i o n :   j s o n [ r e l a t i o n ]   ? ?   ' , 
         ) ; 
     } 
 
     M a p < S t r i n g ,   d y n a m i c >   t o J s o n ( )   { 
         r e t u r n   { 
             i d :   i d , 
             n a m e :   n a m e , 
             p h o n e :   p h o n e , 
             r e l a t i o n :   r e l a t i o n , 
         } ; 
     } 
 } 
 
 / / /   = = = = = = = = = = = = = = = = = = = = = = = 
 / / /   C O N T A C T S   P R O V I D E R 
 / / /   = = = = = = = = = = = = = = = = = = = = = = = 
 
 c l a s s   C o n t a c t s P r o v i d e r   e x t e n d s   C h a n g e N o t i f i e r   { 
     L i s t < C o n t a c t >   _ c o n t a c t s   =   [ ] ; 
     b o o l   _ i s L o a d i n g   =   f a l s e ; 
     S t r i n g ?   _ e r r o r ; 
 
     L i s t < C o n t a c t >   g e t   c o n t a c t s   = >   _ c o n t a c t s ; 
     b o o l   g e t   i s L o a d i n g   = >   _ i s L o a d i n g ; 
     S t r i n g ?   g e t   e r r o r   = >   _ e r r o r ; 
 
     C o n t a c t s P r o v i d e r ( )   { 
         l o a d C o n t a c t s ( ) ; 
     } 
 
     F u t u r e < v o i d >   l o a d C o n t a c t s ( )   a s y n c   { 
         _ i s L o a d i n g   =   t r u e ; 
         _ e r r o r   =   n u l l ; 
         n o t i f y L i s t e n e r s ( ) ; 
 
         t r y   { 
             / /   F o r   n o w ,   l o a d   f r o m   l o c a l   s t o r a g e 
             / /   T O D O :   L o a d   f r o m   s e r v e r   A P I 
             f i n a l   s t o r e d   =   a w a i t   S t o r a g e S e r v i c e . g e t J s o n ( e m e r g e n c y _ c o n t a c t s ) ; 
             i f   ( s t o r e d   ! =   n u l l   ;   s t o r e d   i s   L i s t )   { 
                 _ c o n t a c t s   =   s t o r e d . m a p ( ( c )   = >   C o n t a c t . f r o m J s o n ( c ) ) . t o L i s t ( ) ; 
             }   e l s e   { 
                 / /   D e f a u l t   e m e r g e n c y   c o n t a c t s 
                 _ c o n t a c t s   =   [ 
                     C o n t a c t ( i d :   1 ,   n a m e :   P o l i c e 
 
 E m e r g e n c y ,   p h o n e :   1 0 0 ,   r e l a t i o n :   E m e r g e n c y 
 
 S e r v i c e ) , 
                     C o n t a c t ( i d :   2 ,   n a m e :   A m b u l a n c e ,   p h o n e :   1 0 8 ,   r e l a t i o n :   M e d i c a l 
 
 E m e r g e n c y ) , 
                     C o n t a c t ( i d :   3 ,   n a m e :   F i r e 
 
 S e r v i c e ,   p h o n e :   1 0 1 ,   r e l a t i o n :   F i r e 
 
 E m e r g e n c y ) , 
                 ] ; 
                 a w a i t   S t o r a g e S e r v i c e . s a v e J s o n ( e m e r g e n c y _ c o n t a c t s ,   _ c o n t a c t s . m a p ( ( c )   = >   c . t o J s o n ( ) ) . t o L i s t ( ) ) ; 
             } 
         }   c a t c h   ( e )   { 
             _ e r r o r   =   e . t o S t r i n g ( ) ; 
         }   f i n a l l y   { 
             _ i s L o a d i n g   =   f a l s e ; 
             n o t i f y L i s t e n e r s ( ) ; 
         } 
     } 
 
     F u t u r e < v o i d >   a d d C o n t a c t ( S t r i n g   n a m e ,   S t r i n g   p h o n e ,   S t r i n g   r e l a t i o n )   a s y n c   { 
         t r y   { 
             f i n a l   n e w C o n t a c t   =   C o n t a c t ( 
                 i d :   D a t e T i m e . n o w ( ) . m i l l i s e c o n d s S i n c e E p o c h . t o S t r i n g ( ) , 
                 n a m e :   n a m e , 
                 p h o n e :   p h o n e , 
                 r e l a t i o n :   r e l a t i o n , 
             ) ; 
             _ c o n t a c t s . a d d ( n e w C o n t a c t ) ; 
             a w a i t   S t o r a g e S e r v i c e . s a v e J s o n ( e m e r g e n c y _ c o n t a c t s ,   _ c o n t a c t s . m a p ( ( c )   = >   c . t o J s o n ( ) ) . t o L i s t ( ) ) ; 
             n o t i f y L i s t e n e r s ( ) ; 
         }   c a t c h   ( e )   { 
             _ e r r o r   =   e . t o S t r i n g ( ) ; 
             n o t i f y L i s t e n e r s ( ) ; 
         } 
     } 
 
     F u t u r e < v o i d >   u p d a t e C o n t a c t ( S t r i n g   i d ,   S t r i n g   n a m e ,   S t r i n g   p h o n e ,   S t r i n g   r e l a t i o n )   a s y n c   { 
         t r y   { 
             f i n a l   i n d e x   =   _ c o n t a c t s . i n d e x W h e r e ( ( c )   = >   c . i d   = =   i d ) ; 
             i f   ( i n d e x   ! =   - 1 )   { 
                 _ c o n t a c t s [ i n d e x ]   =   C o n t a c t ( 
                     i d :   i d , 
                     n a m e :   n a m e , 
                     p h o n e :   p h o n e , 
                     r e l a t i o n :   r e l a t i o n , 
                 ) ; 
                 a w a i t   S t o r a g e S e r v i c e . s a v e J s o n ( e m e r g e n c y _ c o n t a c t s ,   _ c o n t a c t s . m a p ( ( c )   = >   c . t o J s o n ( ) ) . t o L i s t ( ) ) ; 
                 n o t i f y L i s t e n e r s ( ) ; 
             } 
         }   c a t c h   ( e )   { 
             _ e r r o r   =   e . t o S t r i n g ( ) ; 
             n o t i f y L i s t e n e r s ( ) ; 
         } 
     } 
 
     F u t u r e < v o i d >   d e l e t e C o n t a c t ( S t r i n g   i d )   a s y n c   { 
         t r y   { 
             _ c o n t a c t s . r e m o v e W h e r e ( ( c )   = >   c . i d   = =   i d ) ; 
             a w a i t   S t o r a g e S e r v i c e . s a v e J s o n ( e m e r g e n c y _ c o n t a c t s ,   _ c o n t a c t s . m a p ( ( c )   = >   c . t o J s o n ( ) ) . t o L i s t ( ) ) ; 
             n o t i f y L i s t e n e r s ( ) ; 
         }   c a t c h   ( e )   { 
             _ e r r o r   =   e . t o S t r i n g ( ) ; 
             n o t i f y L i s t e n e r s ( ) ; 
         } 
     } 
 } 
 
 c l a s s   C o n t a c t   { 
     f i n a l   S t r i n g   i d ; 
     f i n a l   S t r i n g   n a m e ; 
     f i n a l   S t r i n g   p h o n e ; 
     f i n a l   S t r i n g   r e l a t i o n ; 
 
     C o n t a c t ( { 
         r e q u i r e d   t h i s . i d , 
         r e q u i r e d   t h i s . n a m e , 
         r e q u i r e d   t h i s . p h o n e , 
         r e q u i r e d   t h i s . r e l a t i o n , 
     } ) ; 
 
     f a c t o r y   C o n t a c t . f r o m J s o n ( M a p < S t r i n g ,   d y n a m i c >   j s o n )   { 
         r e t u r n   C o n t a c t ( 
             i d :   j s o n [ " _ i d " ]   ? ?   j s o n [ " i d " ]   ? ?   " " , 
             n a m e :   j s o n [ " n a m e " ]   ? ?   " " , 
             p h o n e :   j s o n [ " p h o n e " ]   ? ?   " " , 
             r e l a t i o n :   j s o n [ " r e l a t i o n " ]   ? ?   " " , 
         ) ; 
     } 
 
     M a p < S t r i n g ,   d y n a m i c >   t o J s o n ( )   { 
         r e t u r n   { 
             " i d " :   i d , 
             " n a m e " :   n a m e , 
             " p h o n e " :   p h o n e , 
             " r e l a t i o n " :   r e l a t i o n , 
         } ; 
     } 
 } 
 
 / / /   = = = = = = = = = = = = = = = = = = = = = = = 
 / / /   C O N T A C T S   P R O V I D E R 
 / / /   = = = = = = = = = = = = = = = = = = = = = = = 
 
 c l a s s   C o n t a c t s P r o v i d e r   e x t e n d s   C h a n g e N o t i f i e r   { 
     L i s t < C o n t a c t >   _ c o n t a c t s   =   [ ] ; 
     b o o l   _ i s L o a d i n g   =   f a l s e ; 
     S t r i n g ?   _ e r r o r ; 
 
     L i s t < C o n t a c t >   g e t   c o n t a c t s   = >   _ c o n t a c t s ; 
     b o o l   g e t   i s L o a d i n g   = >   _ i s L o a d i n g ; 
     S t r i n g ?   g e t   e r r o r   = >   _ e r r o r ; 
 
     C o n t a c t s P r o v i d e r ( )   { 
         l o a d C o n t a c t s ( ) ; 
     } 
 
     F u t u r e < v o i d >   l o a d C o n t a c t s ( )   a s y n c   { 
         _ i s L o a d i n g   =   t r u e ; 
         _ e r r o r   =   n u l l ; 
         n o t i f y L i s t e n e r s ( ) ; 
 
         t r y   { 
             / /   F o r   n o w ,   l o a d   f r o m   l o c a l   s t o r a g e 
             / /   T O D O :   L o a d   f r o m   s e r v e r   A P I 
             f i n a l   s t o r e d   =   a w a i t   S t o r a g e S e r v i c e . g e t J s o n ( " e m e r g e n c y _ c o n t a c t s " ) ; 
             i f   ( s t o r e d   ! =   n u l l   & &   s t o r e d   i s   L i s t )   { 
                 _ c o n t a c t s   =   s t o r e d . m a p ( ( c )   = >   C o n t a c t . f r o m J s o n ( c ) ) . t o L i s t ( ) ; 
             }   e l s e   { 
                 / /   D e f a u l t   e m e r g e n c y   c o n t a c t s 
                 _ c o n t a c t s   =   [ 
                     C o n t a c t ( i d :   " 1 " ,   n a m e :   " P o l i c e   E m e r g e n c y " ,   p h o n e :   " 1 0 0 " ,   r e l a t i o n :   " E m e r g e n c y   S e r v i c e " ) , 
                     C o n t a c t ( i d :   " 2 " ,   n a m e :   " A m b u l a n c e " ,   p h o n e :   " 1 0 8 " ,   r e l a t i o n :   " M e d i c a l   E m e r g e n c y " ) , 
                     C o n t a c t ( i d :   " 3 " ,   n a m e :   " F i r e   S e r v i c e " ,   p h o n e :   " 1 0 1 " ,   r e l a t i o n :   " F i r e   E m e r g e n c y " ) , 
                 ] ; 
                 a w a i t   S t o r a g e S e r v i c e . s a v e J s o n ( " e m e r g e n c y _ c o n t a c t s " ,   _ c o n t a c t s . m a p ( ( c )   = >   c . t o J s o n ( ) ) . t o L i s t ( ) ) ; 
             } 
         }   c a t c h   ( e )   { 
             _ e r r o r   =   e . t o S t r i n g ( ) ; 
         }   f i n a l l y   { 
             _ i s L o a d i n g   =   f a l s e ; 
             n o t i f y L i s t e n e r s ( ) ; 
         } 
     } 
 
     F u t u r e < v o i d >   a d d C o n t a c t ( S t r i n g   n a m e ,   S t r i n g   p h o n e ,   S t r i n g   r e l a t i o n )   a s y n c   { 
         t r y   { 
             f i n a l   n e w C o n t a c t   =   C o n t a c t ( 
                 i d :   D a t e T i m e . n o w ( ) . m i l l i s e c o n d s S i n c e E p o c h . t o S t r i n g ( ) , 
                 n a m e :   n a m e , 
                 p h o n e :   p h o n e , 
                 r e l a t i o n :   r e l a t i o n , 
             ) ; 
             _ c o n t a c t s . a d d ( n e w C o n t a c t ) ; 
             a w a i t   S t o r a g e S e r v i c e . s a v e J s o n ( " e m e r g e n c y _ c o n t a c t s " ,   _ c o n t a c t s . m a p ( ( c )   = >   c . t o J s o n ( ) ) . t o L i s t ( ) ) ; 
             n o t i f y L i s t e n e r s ( ) ; 
         }   c a t c h   ( e )   { 
             _ e r r o r   =   e . t o S t r i n g ( ) ; 
             n o t i f y L i s t e n e r s ( ) ; 
         } 
     } 
 
     F u t u r e < v o i d >   u p d a t e C o n t a c t ( S t r i n g   i d ,   S t r i n g   n a m e ,   S t r i n g   p h o n e ,   S t r i n g   r e l a t i o n )   a s y n c   { 
         t r y   { 
             f i n a l   i n d e x   =   _ c o n t a c t s . i n d e x W h e r e ( ( c )   = >   c . i d   = =   i d ) ; 
             i f   ( i n d e x   ! =   - 1 )   { 
                 _ c o n t a c t s [ i n d e x ]   =   C o n t a c t ( 
                     i d :   i d , 
                     n a m e :   n a m e , 
                     p h o n e :   p h o n e , 
                     r e l a t i o n :   r e l a t i o n , 
                 ) ; 
                 a w a i t   S t o r a g e S e r v i c e . s a v e J s o n ( " e m e r g e n c y _ c o n t a c t s " ,   _ c o n t a c t s . m a p ( ( c )   = >   c . t o J s o n ( ) ) . t o L i s t ( ) ) ; 
                 n o t i f y L i s t e n e r s ( ) ; 
             } 
         }   c a t c h   ( e )   { 
             _ e r r o r   =   e . t o S t r i n g ( ) ; 
             n o t i f y L i s t e n e r s ( ) ; 
         } 
     } 
 
     F u t u r e < v o i d >   d e l e t e C o n t a c t ( S t r i n g   i d )   a s y n c   { 
         t r y   { 
             _ c o n t a c t s . r e m o v e W h e r e ( ( c )   = >   c . i d   = =   i d ) ; 
             a w a i t   S t o r a g e S e r v i c e . s a v e J s o n ( " e m e r g e n c y _ c o n t a c t s " ,   _ c o n t a c t s . m a p ( ( c )   = >   c . t o J s o n ( ) ) . t o L i s t ( ) ) ; 
             n o t i f y L i s t e n e r s ( ) ; 
         }   c a t c h   ( e )   { 
             _ e r r o r   =   e . t o S t r i n g ( ) ; 
             n o t i f y L i s t e n e r s ( ) ; 
         } 
     } 
 } 
 
 } 
 
 
 
 / / /   = = = = = = = = = = = = = = = = = = = = = = = 
 
 / / /   T R A C K I N G   P R O V I D E R 
 
 / / /   = = = = = = = = = = = = = = = = = = = = = = = 
 
 
 
 c l a s s   R e s p o n d e r   { 
 
     f i n a l   S t r i n g   i d ; 
 
     f i n a l   S t r i n g   t y p e ; 
 
     f i n a l   S t r i n g   n a m e ; 
 
     f i n a l   d o u b l e   l a t i t u d e ; 
 
     f i n a l   d o u b l e   l o n g i t u d e ; 
 
     f i n a l   d o u b l e   d i s t a n c e ; 
 
     f i n a l   i n t   e t a M i n u t e s ; 
 
 
 
     R e s p o n d e r ( { 
 
         r e q u i r e d   t h i s . i d , 
 
         r e q u i r e d   t h i s . t y p e , 
 
         r e q u i r e d   t h i s . n a m e , 
 
         r e q u i r e d   t h i s . l a t i t u d e , 
 
         r e q u i r e d   t h i s . l o n g i t u d e , 
 
         r e q u i r e d   t h i s . d i s t a n c e , 
 
         r e q u i r e d   t h i s . e t a M i n u t e s , 
 
     } ) ; 
 
 
 
     f a c t o r y   R e s p o n d e r . f r o m J s o n ( M a p < S t r i n g ,   d y n a m i c >   j s o n )   { 
 
         r e t u r n   R e s p o n d e r ( 
 
             i d :   j s o n [ ' i d ' ]   ? ?   ' ' , 
 
             t y p e :   j s o n [ ' t y p e ' ]   ? ?   ' p o l i c e ' , 
 
             n a m e :   j s o n [ ' n a m e ' ]   ? ?   ' ' , 
 
             l a t i t u d e :   j s o n [ ' l a t i t u d e ' ]   ? ?   0 . 0 , 
 
             l o n g i t u d e :   j s o n [ ' l o n g i t u d e ' ]   ? ?   0 . 0 , 
 
             d i s t a n c e :   j s o n [ ' d i s t a n c e ' ]   ? ?   0 . 0 , 
 
             e t a M i n u t e s :   j s o n [ ' e t a M i n u t e s ' ]   ? ?   0 , 
 
         ) ; 
 
     } 
 
 
 
     M a p < S t r i n g ,   d y n a m i c >   t o J s o n ( )   { 
 
         r e t u r n   { 
 
             ' i d ' :   i d , 
 
             ' t y p e ' :   t y p e , 
 
             ' n a m e ' :   n a m e , 
 
             ' l a t i t u d e ' :   l a t i t u d e , 
 
             ' l o n g i t u d e ' :   l o n g i t u d e , 
 
             ' d i s t a n c e ' :   d i s t a n c e , 
 
             ' e t a M i n u t e s ' :   e t a M i n u t e s , 
 
         } ; 
 
     } 
 
 } 
 
 
 
 c l a s s   T r a c k i n g P r o v i d e r   e x t e n d s   C h a n g e N o t i f i e r   { 
 
     L i s t < R e s p o n d e r >   _ n e a r b y R e s p o n d e r s   =   [ ] ; 
 
     b o o l   _ i s L o a d i n g   =   f a l s e ; 
 
     S t r i n g ?   _ e r r o r ; 
 
     d o u b l e ?   _ c u r r e n t L a t ; 
 
     d o u b l e ?   _ c u r r e n t L n g ; 
 
     D a t e T i m e ?   _ t r a c k i n g S t a r t e d ; 
 
 
 
     L i s t < R e s p o n d e r >   g e t   n e a r b y R e s p o n d e r s   = >   _ n e a r b y R e s p o n d e r s ; 
 
     b o o l   g e t   i s L o a d i n g   = >   _ i s L o a d i n g ; 
 
     S t r i n g ?   g e t   e r r o r   = >   _ e r r o r ; 
 
     d o u b l e ?   g e t   c u r r e n t L a t   = >   _ c u r r e n t L a t ; 
 
     d o u b l e ?   g e t   c u r r e n t L n g   = >   _ c u r r e n t L n g ; 
 
     D a t e T i m e ?   g e t   t r a c k i n g S t a r t e d   = >   _ t r a c k i n g S t a r t e d ; 
 
 
 
     T r a c k i n g P r o v i d e r ( )   { 
 
         l o a d N e a r b y R e s p o n d e r s ( ) ; 
 
     } 
 
 
 
     F u t u r e < v o i d >   l o a d N e a r b y R e s p o n d e r s ( )   a s y n c   { 
 
         _ i s L o a d i n g   =   t r u e ; 
 
         _ e r r o r   =   n u l l ; 
 
         n o t i f y L i s t e n e r s ( ) ; 
 
 
 
         t r y   { 
 
             / /   T O D O :   L o a d   f r o m   s e r v e r   A P I 
 
             / /   F o r   n o w ,   u s e   m o c k   d a t a 
 
             a w a i t   F u t u r e . d e l a y e d ( c o n s t   D u r a t i o n ( s e c o n d s :   1 ) ) ; 
 
             _ n e a r b y R e s p o n d e r s   =   [ 
 
                 R e s p o n d e r ( 
 
                     i d :   ' 1 ' , 
 
                     t y p e :   ' p o l i c e ' , 
 
                     n a m e :   ' P o l i c e   U n i t ' , 
 
                     l a t i t u d e :   2 8 . 6 1 3 9 , 
 
                     l o n g i t u d e :   7 7 . 2 0 9 0 , 
 
                     d i s t a n c e :   2 . 5 , 
 
                     e t a M i n u t e s :   5 , 
 
                 ) , 
 
                 R e s p o n d e r ( 
 
                     i d :   ' 2 ' , 
 
                     t y p e :   ' a m b u l a n c e ' , 
 
                     n a m e :   ' A m b u l a n c e ' , 
 
                     l a t i t u d e :   2 8 . 6 1 4 0 , 
 
                     l o n g i t u d e :   7 7 . 2 0 9 1 , 
 
                     d i s t a n c e :   3 . 2 , 
 
                     e t a M i n u t e s :   7 , 
 
                 ) , 
 
                 R e s p o n d e r ( 
 
                     i d :   ' 3 ' , 
 
                     t y p e :   ' f i r e ' , 
 
                     n a m e :   ' F i r e   S e r v i c e ' , 
 
                     l a t i t u d e :   2 8 . 6 1 4 1 , 
 
                     l o n g i t u d e :   7 7 . 2 0 9 2 , 
 
                     d i s t a n c e :   4 . 1 , 
 
                     e t a M i n u t e s :   1 0 , 
 
                 ) , 
 
             ] ; 
 
         }   c a t c h   ( e )   { 
 
             _ e r r o r   =   e . t o S t r i n g ( ) ; 
 
         }   f i n a l l y   { 
 
             _ i s L o a d i n g   =   f a l s e ; 
 
             n o t i f y L i s t e n e r s ( ) ; 
 
         } 
 
     } 
 
 
 
     v o i d   s t a r t T r a c k i n g ( d o u b l e   l a t ,   d o u b l e   l n g )   { 
 
         _ c u r r e n t L a t   =   l a t ; 
 
         _ c u r r e n t L n g   =   l n g ; 
 
         _ t r a c k i n g S t a r t e d   =   D a t e T i m e . n o w ( ) ; 
 
         n o t i f y L i s t e n e r s ( ) ; 
 
     } 
 
 
 
     v o i d   s t o p T r a c k i n g ( )   { 
 
         _ c u r r e n t L a t   =   n u l l ; 
 
         _ c u r r e n t L n g   =   n u l l ; 
 
         _ t r a c k i n g S t a r t e d   =   n u l l ; 
 
         n o t i f y L i s t e n e r s ( ) ; 
 
     } 
 
 } 
 
 
} 
 
 
 
 / / /   = = = = = = = = = = = = = = = = = = = = = = = 
 
 / / /   T R A C K I N G   P R O V I D E R 
 
 / / /   = = = = = = = = = = = = = = = = = = = = = = = 
 
 
 
 c l a s s   R e s p o n d e r   { 
 
     f i n a l   S t r i n g   i d ; 
 
     f i n a l   S t r i n g   t y p e ; 
 
     f i n a l   S t r i n g   n a m e ; 
 
     f i n a l   d o u b l e   l a t i t u d e ; 
 
     f i n a l   d o u b l e   l o n g i t u d e ; 
 
     f i n a l   d o u b l e   d i s t a n c e ; 
 
     f i n a l   i n t   e t a M i n u t e s ; 
 
 
 
     R e s p o n d e r ( { 
 
         r e q u i r e d   t h i s . i d , 
 
         r e q u i r e d   t h i s . t y p e , 
 
         r e q u i r e d   t h i s . n a m e , 
 
         r e q u i r e d   t h i s . l a t i t u d e , 
 
         r e q u i r e d   t h i s . l o n g i t u d e , 
 
         r e q u i r e d   t h i s . d i s t a n c e , 
 
         r e q u i r e d   t h i s . e t a M i n u t e s , 
 
     } ) ; 
 
 
 
     f a c t o r y   R e s p o n d e r . f r o m J s o n ( M a p < S t r i n g ,   d y n a m i c >   j s o n )   { 
 
         r e t u r n   R e s p o n d e r ( 
 
             i d :   j s o n [ ' i d ' ]   ? ?   ' ' , 
 
             t y p e :   j s o n [ ' t y p e ' ]   ? ?   ' p o l i c e ' , 
 
             n a m e :   j s o n [ ' n a m e ' ]   ? ?   ' ' , 
 
             l a t i t u d e :   j s o n [ ' l a t i t u d e ' ]   ? ?   0 . 0 , 
 
             l o n g i t u d e :   j s o n [ ' l o n g i t u d e ' ]   ? ?   0 . 0 , 
 
             d i s t a n c e :   j s o n [ ' d i s t a n c e ' ]   ? ?   0 . 0 , 
 
             e t a M i n u t e s :   j s o n [ ' e t a M i n u t e s ' ]   ? ?   0 , 
 
         ) ; 
 
     } 
 
 
 
     M a p < S t r i n g ,   d y n a m i c >   t o J s o n ( )   { 
 
         r e t u r n   { 
 
             ' i d ' :   i d , 
 
             ' t y p e ' :   t y p e , 
 
             ' n a m e ' :   n a m e , 
 
             ' l a t i t u d e ' :   l a t i t u d e , 
 
             ' l o n g i t u d e ' :   l o n g i t u d e , 
 
             ' d i s t a n c e ' :   d i s t a n c e , 
 
             ' e t a M i n u t e s ' :   e t a M i n u t e s , 
 
         } ; 
 
     } 
 
 } 
 
 
 
 c l a s s   T r a c k i n g P r o v i d e r   e x t e n d s   C h a n g e N o t i f i e r   { 
 
     L i s t < R e s p o n d e r >   _ n e a r b y R e s p o n d e r s   =   [ ] ; 
 
     b o o l   _ i s L o a d i n g   =   f a l s e ; 
 
     S t r i n g ?   _ e r r o r ; 
 
     d o u b l e ?   _ c u r r e n t L a t ; 
 
     d o u b l e ?   _ c u r r e n t L n g ; 
 
     D a t e T i m e ?   _ t r a c k i n g S t a r t e d ; 
 
 
 
     L i s t < R e s p o n d e r >   g e t   n e a r b y R e s p o n d e r s   = >   _ n e a r b y R e s p o n d e r s ; 
 
     b o o l   g e t   i s L o a d i n g   = >   _ i s L o a d i n g ; 
 
     S t r i n g ?   g e t   e r r o r   = >   _ e r r o r ; 
 
     d o u b l e ?   g e t   c u r r e n t L a t   = >   _ c u r r e n t L a t ; 
 
     d o u b l e ?   g e t   c u r r e n t L n g   = >   _ c u r r e n t L n g ; 
 
     D a t e T i m e ?   g e t   t r a c k i n g S t a r t e d   = >   _ t r a c k i n g S t a r t e d ; 
 
 
 
     T r a c k i n g P r o v i d e r ( )   { 
 
         l o a d N e a r b y R e s p o n d e r s ( ) ; 
 
     } 
 
 
 
     F u t u r e < v o i d >   l o a d N e a r b y R e s p o n d e r s ( )   a s y n c   { 
 
         _ i s L o a d i n g   =   t r u e ; 
 
         _ e r r o r   =   n u l l ; 
 
         n o t i f y L i s t e n e r s ( ) ; 
 
 
 
         t r y   { 
 
             / /   T O D O :   L o a d   f r o m   s e r v e r   A P I 
 
             / /   F o r   n o w ,   u s e   m o c k   d a t a 
 
             a w a i t   F u t u r e . d e l a y e d ( c o n s t   D u r a t i o n ( s e c o n d s :   1 ) ) ; 
 
             _ n e a r b y R e s p o n d e r s   =   [ 
 
                 R e s p o n d e r ( 
 
                     i d :   ' 1 ' , 
 
                     t y p e :   ' p o l i c e ' , 
 
                     n a m e :   ' P o l i c e   U n i t ' , 
 
                     l a t i t u d e :   2 8 . 6 1 3 9 , 
 
                     l o n g i t u d e :   7 7 . 2 0 9 0 , 
 
                     d i s t a n c e :   2 . 5 , 
 
                     e t a M i n u t e s :   5 , 
 
                 ) , 
 
                 R e s p o n d e r ( 
 
                     i d :   ' 2 ' , 
 
                     t y p e :   ' a m b u l a n c e ' , 
 
                     n a m e :   ' A m b u l a n c e ' , 
 
                     l a t i t u d e :   2 8 . 6 1 4 0 , 
 
                     l o n g i t u d e :   7 7 . 2 0 9 1 , 
 
                     d i s t a n c e :   3 . 2 , 
 
                     e t a M i n u t e s :   7 , 
 
                 ) , 
 
                 R e s p o n d e r ( 
 
                     i d :   ' 3 ' , 
 
                     t y p e :   ' f i r e ' , 
 
                     n a m e :   ' F i r e   S e r v i c e ' , 
 
                     l a t i t u d e :   2 8 . 6 1 4 1 , 
 
                     l o n g i t u d e :   7 7 . 2 0 9 2 , 
 
                     d i s t a n c e :   4 . 1 , 
 
                     e t a M i n u t e s :   1 0 , 
 
                 ) , 
 
             ] ; 
 
         }   c a t c h   ( e )   { 
 
             _ e r r o r   =   e . t o S t r i n g ( ) ; 
 
         }   f i n a l l y   { 
 
             _ i s L o a d i n g   =   f a l s e ; 
 
             n o t i f y L i s t e n e r s ( ) ; 
 
         } 
 
     } 
 
 
 
     v o i d   s t a r t T r a c k i n g ( d o u b l e   l a t ,   d o u b l e   l n g )   { 
 
         _ c u r r e n t L a t   =   l a t ; 
 
         _ c u r r e n t L n g   =   l n g ; 
 
         _ t r a c k i n g S t a r t e d   =   D a t e T i m e . n o w ( ) ; 
 
         n o t i f y L i s t e n e r s ( ) ; 
 
     } 
 
 
 
     v o i d   s t o p T r a c k i n g ( )   { 
 
         _ c u r r e n t L a t   =   n u l l ; 
 
         _ c u r r e n t L n g   =   n u l l ; 
 
         _ t r a c k i n g S t a r t e d   =   n u l l ; 
 
         n o t i f y L i s t e n e r s ( ) ; 
 
     } 
 
 } 
 
 