import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../data/services/supabase_service.dart';
import 'auth_provider.dart';

final taskListProvider = StateNotifierProvider<TaskListNotifier, AsyncValue<List<Task>>>((ref) {
  final auth = ref.watch(authProvider);
  return TaskListNotifier(auth.profile?.id);
});

final taskDetailProvider = FutureProvider.family<Task?, String>((ref, taskId) async {
  final supabase = SupabaseService.instance;
  return await supabase.getTask(taskId);
});

class TaskListNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  TaskListNotifier(this.userId) : super(const AsyncValue.loading()) {
    if (userId != null) {
      loadTasks();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  final String? userId;
  final _supabase = SupabaseService.instance;

  Future<void> loadTasks() async {
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      // DEMO MODE: Return mock tasks
      await Future.delayed(const Duration(milliseconds: 500));

      final mockTasks = _createMockTasks();
      state = AsyncValue.data(mockTasks);

      // Original backend call (commented out):
      // final tasks = await _supabase.getTasks(userId!);
      // state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  List<Task> _createMockTasks() {
    final now = DateTime.now();
    return [
      Task(
        id: 'task_1',
        userId: userId!,
        chatId: 123456,
        messageId: 1,
        content: 'Встретиться с командой для обсуждения проекта',
        originalQuote: 'Давай встретимся завтра в 15:00 обсудим проект',
        taskType: 'agreement',
        priority: 'high',
        deadline: now.add(const Duration(days: 1, hours: 3)),
        deadlineIsPrecise: true,
        status: 'pending',
        sourceLink: 'https://t.me/c/123456/1',
        confidence: 0.95,
        isDuplicate: false,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Task(
        id: 'task_2',
        userId: userId!,
        chatId: 123456,
        messageId: 2,
        content: 'Отправить отчет по проекту',
        originalQuote: 'Не забудь отправить отчет до конца недели',
        taskType: 'reminder',
        priority: 'medium',
        deadline: now.add(const Duration(days: 3)),
        deadlineIsPrecise: false,
        status: 'pending',
        sourceLink: 'https://t.me/c/123456/2',
        confidence: 0.88,
        isDuplicate: false,
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
      Task(
        id: 'task_3',
        userId: userId!,
        chatId: 789012,
        messageId: 3,
        content: 'Позвонить клиенту',
        originalQuote: 'Позвони мне когда будет время',
        taskType: 'request',
        priority: 'low',
        deadline: now.add(const Duration(days: 7)),
        deadlineIsPrecise: false,
        status: 'pending',
        sourceLink: 'https://t.me/c/789012/3',
        confidence: 0.75,
        isDuplicate: false,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<void> markAsDone(String taskId) async {
    try {
      // DEMO MODE: Just update local state
      await Future.delayed(const Duration(milliseconds: 300));
      final currentTasks = state.value ?? [];
      final updatedTasks = currentTasks.where((t) => t.id != taskId).toList();
      state = AsyncValue.data(updatedTasks);

      // Original backend call (commented out):
      // await _supabase.updateTaskStatus(taskId, 'done');
      // await loadTasks();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> markAsInProgress(String taskId) async {
    try {
      // DEMO MODE: Just simulate delay
      await Future.delayed(const Duration(milliseconds: 300));
      // Original backend call (commented out):
      // await _supabase.updateTaskStatus(taskId, 'in_progress');
      // await loadTasks();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> cancelTask(String taskId) async {
    try {
      // DEMO MODE: Remove from list
      await Future.delayed(const Duration(milliseconds: 300));
      final currentTasks = state.value ?? [];
      final updatedTasks = currentTasks.where((t) => t.id != taskId).toList();
      state = AsyncValue.data(updatedTasks);

      // Original backend call (commented out):
      // await _supabase.updateTaskStatus(taskId, 'cancelled');
      // await loadTasks();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      // DEMO MODE: Update local state
      await Future.delayed(const Duration(milliseconds: 300));
      if (status == 'done' || status == 'cancelled') {
        final currentTasks = state.value ?? [];
        final updatedTasks = currentTasks.where((t) => t.id != taskId).toList();
        state = AsyncValue.data(updatedTasks);
      }

      // Original backend call (commented out):
      // await _supabase.updateTaskStatus(taskId, status);
      // await loadTasks();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  List<Task> getTasksByPriority(String priority) {
    return state.value?.where((task) => task.priority == priority).toList() ?? [];
  }

  List<Task> getOverdueTasks() {
    return state.value?.where((task) => task.isOverdue).toList() ?? [];
  }

  List<Task> getTasksDueToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return state.value?.where((task) {
      if (task.deadline == null) return false;
      return task.deadline!.isAfter(today) && task.deadline!.isBefore(tomorrow);
    }).toList() ?? [];
  }

  int get totalActiveTasks => state.value?.length ?? 0;

  int get urgentTasksCount {
    return state.value?.where((task) => task.priority == 'urgent').length ?? 0;
  }

  int get overdueTasksCount {
    return state.value?.where((task) => task.isOverdue).length ?? 0;
  }
}
