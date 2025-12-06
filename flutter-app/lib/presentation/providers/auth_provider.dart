import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/profile.dart';
import '../../data/services/supabase_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final Profile? profile;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.profile,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    Profile? profile,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _checkAuthStatus();
  }

  final _supabase = SupabaseService.instance;
  // final _api = ApiService.instance; // Unused in demo mode

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null) {
        // DEMO MODE: Create mock profile from stored data
        final phoneNumber = prefs.getString('phone_number') ?? '+7 000 000 00 00';

        final mockProfile = Profile(
          id: userId,
          phoneNumber: phoneNumber,
          firstName: 'Demo',
          lastName: 'User',
          username: null,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        state = state.copyWith(
          profile: mockProfile,
          isAuthenticated: true,
        );

        // Original backend call (commented out):
        // final profile = await _supabase.getProfile(userId);
        // if (profile != null) {
        //   state = state.copyWith(
        //     profile: profile,
        //     isAuthenticated: true,
        //   );
        // } else {
        //   await logout();
        // }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<Map<String, dynamic>?> requestCode(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // DEMO MODE: Skip backend call, use mock response
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

      // Mock response with fake phone_code_hash
      final response = {
        'phone_code_hash': 'demo_hash_${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Code sent successfully (DEMO MODE)'
      };

      state = state.copyWith(isLoading: false);
      return response;

      // Original backend call (commented out):
      // final response = await _api.requestTelegramCode(phoneNumber);
      // state = state.copyWith(isLoading: false);
      // return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  Future<bool> verifyCode({
    required String phoneNumber,
    required String code,
    required String phoneCodeHash,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // DEMO MODE: Accept any code, create mock user
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

      // Generate mock user ID
      final userId = 'demo_user_${DateTime.now().millisecondsSinceEpoch}';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await prefs.setString('phone_number', phoneNumber);

      // Create mock profile
      final mockProfile = Profile(
        id: userId,
        phoneNumber: phoneNumber,
        firstName: 'Demo',
        lastName: 'User',
        username: null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        profile: mockProfile,
        isAuthenticated: true,
        isLoading: false,
      );

      return true;

      // Original backend call (commented out):
      // final response = await _api.verifyTelegramCode(
      //   phoneNumber: phoneNumber,
      //   code: code,
      //   phoneCodeHash: phoneCodeHash,
      // );
      // final userId = response['user_id'] as String;
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setString('user_id', userId);
      // final profile = await _supabase.getProfile(userId);
      // state = state.copyWith(
      //   profile: profile,
      //   isAuthenticated: true,
      //   isLoading: false,
      // );
      // return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    state = AuthState();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (state.profile == null) return;

    try {
      await _supabase.updateProfile(state.profile!.id, data);
      final updatedProfile = await _supabase.getProfile(state.profile!.id);
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
