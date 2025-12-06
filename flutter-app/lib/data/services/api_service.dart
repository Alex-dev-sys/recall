import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  static ApiService? _instance;
  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  late final Dio _dio;

  Future<Map<String, dynamic>> requestTelegramCode(String phoneNumber) async {
    try {
      final response = await _dio.post(
        '/auth/request-code',
        data: {'phone_number': phoneNumber},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyTelegramCode({
    required String phoneNumber,
    required String code,
    required String phoneCodeHash,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-code',
        data: {
          'phone_number': phoneNumber,
          'code': code,
          'phone_code_hash': phoneCodeHash,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getAvailableChats(String userId) async {
    try {
      final response = await _dio.get('/chats/list/$userId');
      return response.data['chats'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> toggleChatMonitoring({
    required String userId,
    required int chatId,
    required String chatTitle,
    required String chatType,
    required bool enable,
  }) async {
    try {
      await _dio.post(
        '/chats/toggle/$userId',
        data: {
          'chat_id': chatId,
          'chat_title': chatTitle,
          'chat_type': chatType,
          'action': enable ? 'add' : 'remove',
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getActiveTasks(String userId) async {
    try {
      final response = await _dio.get('/tasks/active/$userId');
      return response.data['tasks'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTaskDetails(String taskId) async {
    try {
      final response = await _dio.get('/tasks/$taskId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    try {
      await _dio.put(
        '/tasks/$taskId/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await _dio.get('/profile/$userId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateFCMToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      await _dio.post(
        '/profile/fcm-token/$userId',
        data: {'fcm_token': fcmToken},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('detail')) {
        return data['detail'].toString();
      }
      return 'Server error: ${error.response!.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. Please check your internet connection.';
    } else {
      return 'Network error: ${error.message}';
    }
  }
}
