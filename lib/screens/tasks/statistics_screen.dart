// lib/screens/tasks/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../utils/app_theme.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Statistics',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 22),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Completion ring + top numbers ──
                _CompletionCard(tp: tp),
                const SizedBox(height: 16),

                // ── 4 stat tiles ──
                _StatGrid(tp: tp),
                const SizedBox(height: 20),

                // ── Priority breakdown ──
                _SectionTitle('Tasks by priority'),
                const SizedBox(height: 10),
                _PriorityBreakdown(tp: tp),
                const SizedBox(height: 20),

                // ── 7-day activity bar chart ──
                _SectionTitle('Activity — last 7 days'),
                const SizedBox(height: 10),
                _ActivityChart(data: tp.last7DaysActivity),
                const SizedBox(height: 20),

                // ── Recent completed tasks ──
                _SectionTitle('Recently completed'),
                const SizedBox(height: 10),
                _RecentCompleted(tp: tp),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completion ring card ─────────────────────────────────────────────────────

class _CompletionCard extends StatelessWidget {
  final TaskProvider tp;
  const _CompletionCard({required this.tp});

  @override
  Widget build(BuildContext context) {
    final pct = (tp.completionRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: tp.completionRate,
                    strokeWidth: 9,
                    backgroundColor: AppColors.cardBg,
                    color: AppColors.primary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$pct%',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const Text('done',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Breakdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall progress',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _MiniRow(
                    color: AppColors.success,
                    label: 'Completed',
                    value: '${tp.completedTasks}'),
                const SizedBox(height: 6),
                _MiniRow(
                    color: AppColors.primary,
                    label: 'Remaining',
                    value: '${tp.incompleteTasks}'),
                const SizedBox(height: 6),
                _MiniRow(
                    color: AppColors.accent,
                    label: 'Total',
                    value: '${tp.totalTasks}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _MiniRow(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary))),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── 4 stat tiles ─────────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  final TaskProvider tp;
  const _StatGrid({required this.tp});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatTile(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.priorityHigh,
          bgColor: AppColors.priorityHigh.withOpacity(0.1),
          label: 'Overdue',
          value: '${tp.overdueCount}',
        ),
        _StatTile(
          icon: Icons.today_rounded,
          iconColor: AppColors.priorityMedium,
          bgColor: AppColors.priorityMedium.withOpacity(0.1),
          label: 'Due today',
          value: '${tp.dueTodayCount}',
        ),
        _StatTile(
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.success,
          bgColor: AppColors.success.withOpacity(0.1),
          label: 'Completed',
          value: '${tp.completedTasks}',
        ),
        _StatTile(
          icon: Icons.pending_actions_rounded,
          iconColor: AppColors.primary,
          bgColor: AppColors.primary.withOpacity(0.1),
          label: 'Pending',
          value: '${tp.incompleteTasks}',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Priority breakdown bars ───────────────────────────────────────────────────

class _PriorityBreakdown extends StatelessWidget {
  final TaskProvider tp;
  const _PriorityBreakdown({required this.tp});

  @override
  Widget build(BuildContext context) {
    final total = tp.totalTasks;
    final items = [
      _PrioItem('High', tp.highPriorityCount, total, AppColors.priorityHigh,
          Icons.keyboard_double_arrow_up_rounded),
      _PrioItem('Medium', tp.mediumPriorityCount, total,
          AppColors.priorityMedium, Icons.remove_rounded),
      _PrioItem('Low', tp.lowPriorityCount, total, AppColors.priorityLow,
          Icons.keyboard_double_arrow_down_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PriorityBar(item: item),
                ))
            .toList(),
      ),
    );
  }
}

class _PrioItem {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;
  _PrioItem(this.label, this.count, this.total, this.color, this.icon);
  double get fraction => total == 0 ? 0 : count / total;
}

class _PriorityBar extends StatelessWidget {
  final _PrioItem item;
  const _PriorityBar({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(item.icon, color: item.color, size: 16),
            const SizedBox(width: 6),
            Text(item.label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text('${item.count} tasks',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: item.fraction,
            minHeight: 8,
            backgroundColor: AppColors.cardBg,
            color: item.color,
          ),
        ),
      ],
    );
  }
}

// ── 7-day activity bar chart ──────────────────────────────────────────────────

class _ActivityChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _ActivityChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxCount =
        data.fold<int>(0, (m, d) => d['count'] > m ? d['count'] : m);
    final effectiveMax = maxCount < 1 ? 1 : maxCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Bars
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final count = d['count'] as int;
                final frac = count / effectiveMax;
                final isToday = DateFormat('EEE')
                        .format(d['date'] as DateTime) ==
                    DateFormat('EEE').format(DateTime.now());
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (count > 0)
                          Text('$count',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isToday
                                      ? AppColors.primary
                                      : AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: frac * 60,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.primaryLight.withOpacity(0.5),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Day labels
          Row(
            children: data.map((d) {
              final isToday = DateFormat('EEE')
                      .format(d['date'] as DateTime) ==
                  DateFormat('EEE').format(DateTime.now());
              return Expanded(
                child: Text(
                  DateFormat('EEE').format(d['date'] as DateTime),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.normal,
                    color: isToday
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Recent completed ─────────────────────────────────────────────────────────

class _RecentCompleted extends StatelessWidget {
  final TaskProvider tp;
  const _RecentCompleted({required this.tp});

  @override
  Widget build(BuildContext context) {
    // Pull last 5 completed tasks sorted by dueDate desc
    final completed = tp.tasks
        .where((t) => t.isCompleted)
        .toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
    final recent = completed.take(5).toList();

    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No completed tasks yet',
              style: TextStyle(color: AppColors.textHint)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: recent.asMap().entries.map((e) {
          final task = e.value;
          final isLast = e.key == recent.length - 1;
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(
                          color: AppColors.divider, width: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(
                          DateFormat('MMM d').format(task.dueDate),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint)),
                    ],
                  ),
                ),
                _PriorityDot(priority: task.priority),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final Priority priority;
  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      Priority.high => AppColors.priorityHigh,
      Priority.medium => AppColors.priorityMedium,
      Priority.low => AppColors.priorityLow,
    };
    return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

// ── Shared section title ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700));
  }
}
