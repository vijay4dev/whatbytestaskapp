// lib/widgets/filter_chips.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../utils/app_theme.dart';

class TaskFilterChips extends StatelessWidget {
  const TaskFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Status filters
          _FilterChip(
            label: 'All',
            isSelected: taskProvider.statusFilter == TaskFilter.all &&
                taskProvider.priorityFilter == null,
            onTap: () => taskProvider.clearFilters(),
            selectedColor: AppColors.primary,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Active',
            isSelected: taskProvider.statusFilter == TaskFilter.incomplete,
            onTap: () => taskProvider.setStatusFilter(TaskFilter.incomplete),
            selectedColor: AppColors.primary,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Done',
            isSelected: taskProvider.statusFilter == TaskFilter.completed,
            onTap: () => taskProvider.setStatusFilter(TaskFilter.completed),
            selectedColor: AppColors.success,
          ),
          const SizedBox(width: 8),
          const _Divider(),
          const SizedBox(width: 8),
          // Priority filters
          _FilterChip(
            label: '🔴 High',
            isSelected: taskProvider.priorityFilter == Priority.high,
            onTap: () => taskProvider.setPriorityFilter(
                taskProvider.priorityFilter == Priority.high
                    ? null
                    : Priority.high),
            selectedColor: AppColors.priorityHigh,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '🟡 Medium',
            isSelected: taskProvider.priorityFilter == Priority.medium,
            onTap: () => taskProvider.setPriorityFilter(
                taskProvider.priorityFilter == Priority.medium
                    ? null
                    : Priority.medium),
            selectedColor: AppColors.priorityMedium,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '🟢 Low',
            isSelected: taskProvider.priorityFilter == Priority.low,
            onTap: () => taskProvider.setPriorityFilter(
                taskProvider.priorityFilter == Priority.low
                    ? null
                    : Priority.low),
            selectedColor: AppColors.priorityLow,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.divider,
    );
  }
}
