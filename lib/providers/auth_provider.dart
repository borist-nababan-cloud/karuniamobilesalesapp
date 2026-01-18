import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String? role;
  final String? uid;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.role,
    this.uid,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      uid: json['uid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'uid': uid,
    };
  }
}

class AuthState {
  final User? user;
  final String? token;
  final bool isAuthenticated;
  final bool isApproved;
  final bool isLoading;

  AuthState({
    this.user,
    this.token,
    this.isAuthenticated = false,
    this.isApproved = false,
    this.isLoading = true, // Initial load
  });

  AuthState copyWith({
    User? user,
    String? token,
    bool? isAuthenticated,
    bool? isApproved,
    bool? isLoading,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isApproved: isApproved ?? this.isApproved,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userStr = prefs.getString('auth_user');
    final isApproved = prefs.getBool('auth_is_approved') ?? false;

    if (token != null && userStr != null) {
      try {
        final user = User.fromJson(jsonDecode(userStr));
        state = AuthState(
          user: user,
          token: token,
          isAuthenticated: true,
          isApproved: isApproved,
          isLoading: false,
        );
      } catch (e) {
        // Corrupt data
        await logout();
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> login(User user, String token, {bool isApproved = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_user', jsonEncode(user.toJson()));
    await prefs.setBool('auth_is_approved', isApproved);

    state = AuthState(
      user: user,
      token: token,
      isAuthenticated: true,
      isApproved: isApproved,
      isLoading: false,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    await prefs.remove('auth_is_approved');

    state = AuthState(isLoading: false);
  }

  Future<void> setApproved(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_is_approved', status);
    state = state.copyWith(isApproved: status);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
