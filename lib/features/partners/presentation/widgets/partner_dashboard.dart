import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/confirm_dialog.dart';
import '../../domain/partner_model.dart';
import '../providers/partner_analytics_provider.dart';
import '../providers/partners_provider.dart';
import 'genre_radar_chart.dart';

class PartnerDashboard extends ConsumerWidget {
  final PartnerModel partner;

  const PartnerDashboard({super.key, required this.partner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Partner header
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                partner.partnerUsername[0].toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(partner.partnerUsername, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Chip(
              avatar: const Icon(Icons.favorite, size: 14),
              label: const Text('Partner'),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'unlink') {
                  showConfirmDialog(
                    context: context,
                    title: 'Unlink Partner',
                    message: 'Are you sure you want to unlink from ${partner.partnerUsername}? This will remove all shared data.',
                    confirmLabel: 'Unlink',
                    confirmColor: Colors.red,
                  ).then((confirmed) {
                    if (confirmed && context.mounted) {
                      ref.read(partnersNotifierProvider.notifier).remove(partner.partnerId);
                    }
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'unlink', child: Text('Unlink Partner')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Analytics section
        Text('Shared Analytics', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),

        // Together History count + Time Spent
        _AnalyticsRow(partnerLinkId: partner.id),
        const SizedBox(height: 16),

        // Genre Harmony Map
        Text('Genre Harmony', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _GenreHarmonySection(partnerLinkId: partner.id, partnerId: partner.partnerId),
        const SizedBox(height: 24),

        // Together History list
        Text('Together History', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _TogetherHistoryList(partnerLinkId: partner.id),
      ],
    );
  }
}

class _AnalyticsRow extends ConsumerWidget {
  final String partnerLinkId;
  const _AnalyticsRow({required this.partnerLinkId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(togetherHistoryProvider(partnerLinkId));
    final timeAsync = ref.watch(timeSpentProvider(partnerLinkId));

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: countAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const Text('--'),
                data: (movies) => Column(
                  children: [
                    Text('${movies.length}', style: Theme.of(context).textTheme.headlineMedium),
                    Text('Together', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: timeAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const Text('--'),
                data: (duration) {
                  final hours = duration.inHours;
                  final minutes = duration.inMinutes.remainder(60);
                  return Column(
                    children: [
                      Text('${hours}h ${minutes}m', style: Theme.of(context).textTheme.headlineMedium),
                      Text('Time Spent', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenreHarmonySection extends ConsumerWidget {
  final String partnerLinkId;
  final String partnerId;
  const _GenreHarmonySection({required this.partnerLinkId, required this.partnerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final harmonyAsync = ref.watch(genreHarmonyProvider(partnerLinkId, partnerId: partnerId));

    return harmonyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Could not load genre data',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
      data: (data) {
        if (data.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Swipe and watch movies together to see genre insights',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          );
        }
        return Column(
          children: [
            Center(child: GenreRadarChart(data: data)),
            const SizedBox(height: 8),
            RadarChartLegend(data: data),
          ],
        );
      },
    );
  }
}

class _TogetherHistoryList extends ConsumerWidget {
  final String partnerLinkId;
  const _TogetherHistoryList({required this.partnerLinkId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(togetherHistoryProvider(partnerLinkId));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Could not load history',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
      data: (movies) {
        if (movies.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No movies watched together yet',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: movies.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final movie = movies[index];
              return ListTile(
                dense: true,
                leading: movie.posterUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          movie.posterUrl!,
                          width: 36,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.movie, size: 36),
                        ),
                      )
                    : const Icon(Icons.movie, size: 36),
                title: Text(movie.title, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  '${movie.year ?? '--'}  •  ${movie.genres.take(2).join(', ')}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: movie.runtime != null
                    ? Text('${movie.runtime! ~/ 60}h ${movie.runtime! % 60}m',
                        style: const TextStyle(fontSize: 11))
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}