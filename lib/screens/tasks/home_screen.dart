import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/task_card.dart';
import '../../widgets/filter_chips.dart';
import '../auth/splash_screen.dart';
import 'add_edit_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<TaskProvider>().loadTasks(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final user = auth.user;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // App icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        // Search bar
                        Expanded(
                          child: GestureDetector(
                            onTap: _showSearch,
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(width: 12),
                                  Icon(Icons.search,
                                      color: Colors.white70, size: 18),
                                  SizedBox(width: 8),
                                  Text('Search tasks...',
                                      style: TextStyle(
                                          color: Colors.white54, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Profile/logout
                        GestureDetector(
                          onTap: _showProfileMenu,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              (user?.email?.substring(0, 1).toUpperCase() ??
                                  'U'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      DateFormat('EEEE, d MMM').format(now),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'My tasks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),

          // Filters
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TaskFilterChips(),
          ),

          // Task list
          Expanded(
            child: taskProvider.isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : taskProvider.tasks.isEmpty
                    ? _EmptyState(
                        hasFilters: taskProvider.statusFilter !=
                                TaskFilter.all ||
                            taskProvider.priorityFilter != null)
                    : _TaskList(
                        grouped: taskProvider.groupedTasks,
                        userId: user?.uid ?? '',
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTask(),
        elevation: 6,
        child: const Icon(Icons.add_rounded, size: 28),
      ).animate().scale(delay: 300.ms, duration: 500.ms, curve: Curves.elasticOut),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _BottomBar(onAdd: _openAddTask),
    );
  }

  void _openAddTask() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const AddEditTaskScreen()),
    );
  }

  void _showSearch() {
    showSearch(context: context, delegate: _TaskSearchDelegate(
      tasks: context.read<TaskProvider>().tasks,
    ));
  }

  void _showProfileMenu() {
    final user = context.read<AuthProvider>().user;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                (user?.email?.substring(0, 1).toUpperCase() ?? 'U'),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            Text(user?.email ?? '', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Log out',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: AppColors.error.withOpacity(0.07),
              onTap: () async {
                Navigator.pop(ctx);
                final taskProvider = context.read<TaskProvider>();
                final uid = user?.uid;
                await context.read<AuthProvider>().logout();
                if (uid != null) await taskProvider.clearCache(uid);
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OnboardingScreen()),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final Map<String, List<Task>> grouped;
  final String userId;

  const _TaskList({required this.grouped, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: grouped.length,
      itemBuilder: (ctx, sectionIdx) {
        final section = grouped.keys.elementAt(sectionIdx);
        final tasks = grouped[section]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                section,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            ...tasks.asMap().entries.map((entry) {
              return TaskCard(task: entry.value)
                  .animate(delay: (entry.key * 60).ms)
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.1);
            }),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              hasFilters ? Icons.filter_list_off : Icons.task_alt,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasFilters ? 'No tasks match your filter' : 'No tasks yet!',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try clearing the filters'
                : 'Tap + to add your first task',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onAdd;
  const _BottomBar({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            color: AppColors.primary,
            onPressed: () {},
          ),
          const SizedBox(width: 60), // FAB space
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            color: AppColors.textHint,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// Search delegate
class _TaskSearchDelegate extends SearchDelegate<Task?> {
  final List<Task> tasks;
  _TaskSearchDelegate({required this.tasks});

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      );

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final filtered = tasks
        .where((t) =>
            t.title.toLowerCase().contains(query.toLowerCase()) ||
            t.description.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No tasks found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => TaskCard(task: filtered[i]),
    );
  }
}
