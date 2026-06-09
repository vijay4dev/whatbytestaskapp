import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';

enum TaskFilter { all, completed, incomplete }

class TaskProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  TaskFilter _statusFilter = TaskFilter.all;
  Priority? _priorityFilter;

  List<Task> get tasks => _filteredAndSortedTasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TaskFilter get statusFilter => _statusFilter;
  Priority? get priorityFilter => _priorityFilter;

  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((t) => t.isCompleted).length;
  int get incompleteTasks => _tasks.where((t) => !t.isCompleted).length;
  double get completionRate =>
      _tasks.isEmpty ? 0 : completedTasks / _tasks.length;

  int get highPriorityCount =>
      _tasks.where((t) => t.priority == Priority.high).length;
  int get mediumPriorityCount =>
      _tasks.where((t) => t.priority == Priority.medium).length;
  int get lowPriorityCount =>
      _tasks.where((t) => t.priority == Priority.low).length;

  int get overdueCount {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return _tasks
        .where((t) => !t.isCompleted && t.dueDate.isBefore(today))
        .length;
  }

  int get dueTodayCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks
        .where(
          (t) =>
              !t.isCompleted &&
              DateTime(
                t.dueDate.year,
                t.dueDate.month,
                t.dueDate.day,
              ).isAtSameMomentAs(today),
        )
        .length;
  }

  List<Task> get _filteredAndSortedTasks {
    List<Task> result = List.from(_tasks);

    // Status filter
    if (_statusFilter == TaskFilter.completed) {
      result = result.where((t) => t.isCompleted).toList();
    } else if (_statusFilter == TaskFilter.incomplete) {
      result = result.where((t) => !t.isCompleted).toList();
    }

    // Priority filter
    if (_priorityFilter != null) {
      result = result.where((t) => t.priority == _priorityFilter).toList();
    }

    // Sort by due date earliest first
    result.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return result;
  }

  // Grouped tasks by date section (Today / Tomorrow / This Week / Later)
  Map<String, List<Task>> get groupedTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    final Map<String, List<Task>> grouped = {
      'Today': [],
      'Tomorrow': [],
      'This Week': [],
      'Later': [],
    };

    for (final task in tasks) {
      final due = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      if (due.isAtSameMomentAs(today)) {
        grouped['Today']!.add(task);
      } else if (due.isAtSameMomentAs(tomorrow)) {
        grouped['Tomorrow']!.add(task);
      } else if (due.isAfter(today) && due.isBefore(weekEnd)) {
        grouped['This Week']!.add(task);
      } else {
        grouped['Later']!.add(task);
      }
    }

    // Remove empty sections
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  List<Map<String, dynamic>> get last7DaysActivity {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i));
      final count = _tasks.where((t) {
        final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
        return t.isCompleted && due.isAtSameMomentAs(day);
      }).length;
      return {'date': day, 'count': count};
    });
  }

  void setStatusFilter(TaskFilter filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setPriorityFilter(Priority? priority) {
    _priorityFilter = priority;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = TaskFilter.all;
    _priorityFilter = null;
    notifyListeners();
  }

  Future<void> loadTasks(String userId) async {
    try {
      _setLoading(true);
      // Load from SharedPrefs cache first (optimistic UI)
      await _loadFromCache(userId);

      // Then fetch from Firestore
      final snapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      _tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
      await _saveToCache(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load tasks. Showing cached data.');
    } finally {
      _setLoading(false);
    }
  }

  // Real-time listener
  Stream<List<Task>> tasksStream(String userId) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          _tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
          _saveToCache(userId);
          notifyListeners();
          return _tasks;
        });
  }

  Future<bool> addTask({
    required String userId,
    required String title,
    required String description,
    required DateTime dueDate,
    required Priority priority,
  }) async {
    try {
      final task = Task(
        id: _uuid.v4(),
        userId: userId,
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('tasks').doc(task.id).set(task.toFirestore());
      _tasks.add(task);
      await _saveToCache(userId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add task. Please try again.');
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      await _firestore
          .collection('tasks')
          .doc(task.id)
          .update(task.toFirestore());
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = task;
        await _saveToCache(task.userId);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update task.');
      return false;
    }
  }

  Future<bool> toggleComplete(Task task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    return updateTask(updated);
  }

  Future<bool> deleteTask(Task task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).delete();
      _tasks.removeWhere((t) => t.id == task.id);
      await _saveToCache(task.userId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete task.');
      return false;
    }
  }

  // SharedPrefs cache
  Future<void> _saveToCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = _tasks
          .map((t) => t.toFirestore()..['id'] = t.id)
          .toList();
      await prefs.setString('tasks_$userId', jsonEncode(tasksJson));
    } catch (_) {}
  }

  Future<void> _loadFromCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('tasks_$userId');
      if (cached != null) {
        final List decoded = jsonDecode(cached);
        _tasks = decoded.map((item) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id'] as String;
          return Task(
            id: id,
            userId: map['userId'] ?? userId,
            title: map['title'] ?? '',
            description: map['description'] ?? '',
            dueDate: DateTime.parse(
              (map['dueDate'] as Map)['_seconds'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      ((map['dueDate'] as Map)['_seconds'] as int) * 1000,
                    ).toIso8601String()
                  : map['dueDate'].toString(),
            ),
            priority: Priority.values.firstWhere(
              (p) => p.name == map['priority'],
              orElse: () => Priority.low,
            ),
            isCompleted: map['isCompleted'] ?? false,
            createdAt: DateTime.now(),
          );
        }).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> clearCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tasks_$userId');
    _tasks = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
