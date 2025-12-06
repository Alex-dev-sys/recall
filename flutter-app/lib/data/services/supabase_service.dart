import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../models/task.dart';
import '../models/chat.dart';
import '../models/profile.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
    );
  }

  Future<List<Task>> getTasks(String userId, {String? status}) async {
    try {
      PostgrestFilterBuilder query = client
          .from('tasks')
          .select()
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      } else {
        query = query.neq('status', 'done').neq('status', 'cancelled');
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  Future<Task?> getTask(String taskId) async {
    try {
      final response = await client
          .from('tasks')
          .select()
          .eq('id', taskId)
          .single();

      return Task.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load task: $e');
    }
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      await client
          .from('tasks')
          .update({'status': status})
          .eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<List<Chat>> getMonitoredChats(String userId) async {
    try {
      final response = await client
          .from('monitored_chats')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('added_at', ascending: false);

      return (response as List).map((json) => Chat.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load chats: $e');
    }
  }

  Future<void> toggleChatMonitoring(
    String userId,
    int chatId,
    String chatTitle,
    String chatType,
    bool enable,
  ) async {
    try {
      if (enable) {
        await client.from('monitored_chats').insert({
          'user_id': userId,
          'chat_id': chatId,
          'chat_title': chatTitle,
          'chat_type': chatType,
          'is_active': true,
        });
      } else {
        await client
            .from('monitored_chats')
            .delete()
            .eq('user_id', userId)
            .eq('chat_id', chatId);
      }
    } catch (e) {
      throw Exception('Failed to toggle chat: $e');
    }
  }

  Future<Profile?> getProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await client
          .from('profiles')
          .update(data)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> updateOneSignalPlayerId(
    String userId,
    String playerId,
  ) async {
    try {
      await client
          .from('profiles')
          .update({'onesignal_player_id': playerId})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update OneSignal player ID: $e');
    }
  }

  Stream<List<Task>> watchTasks(String userId) {
    return client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          final filtered = data.where((json) => json['user_id'] == userId).toList();
          return filtered.map((json) => Task.fromJson(json)).toList();
        });
  }

  Stream<List<Chat>> watchMonitoredChats(String userId) {
    return client
        .from('monitored_chats')
        .stream(primaryKey: ['id'])
        .map((data) {
          final filtered = data.where((json) =>
            json['user_id'] == userId && json['is_active'] == true
          ).toList();
          return filtered.map((json) => Chat.fromJson(json)).toList();
        });
  }
}
