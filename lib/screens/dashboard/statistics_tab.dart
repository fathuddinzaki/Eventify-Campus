import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';

class StatisticsTab extends StatelessWidget {
  const StatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Calculate statistics by category
        Map<String, int> categoryCounts = {};
        for (var event in appState.events) {
          categoryCounts[event.category] = (categoryCounts[event.category] ?? 0) + 1;
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistik Event',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ringkasan data seluruh kegiatan',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Main Stats
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          children: [
                            StatCard(
                              title: 'Total Event',
                              value: '${appState.totalEventsCount}',
                              icon: Icons.event_note_rounded,
                              gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            ),
                            StatCard(
                              title: 'Event Aktif',
                              value: '${appState.activeEventsCount}',
                              icon: Icons.check_circle_rounded,
                              gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            StatCard(
                              title: 'Selesai',
                              value: '${appState.completedEventsCount}',
                              icon: Icons.assignment_turned_in_rounded,
                              gradientColors: const [Color(0xFF64748B), Color(0xFF475569)],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        if (categoryCounts.isNotEmpty) ...[
                          Text(
                            'Berdasarkan Kategori',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Category Stats
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: categoryCounts.length,
                            itemBuilder: (context, index) {
                              String category = categoryCounts.keys.elementAt(index);
                              int count = categoryCounts[category]!;
                              double percentage = appState.events.isEmpty ? 0 : (count / appState.events.length);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          category,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                          ),
                                        ),
                                        Text(
                                          '$count Event',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percentage,
                                        minHeight: 8,
                                        backgroundColor: isDark ? AppTheme.darkCard : Colors.grey.withValues(alpha: 0.2),
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryIndigo),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ] else ...[
                           Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'Belum ada data event',
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
