import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/genre_filter_provider.dart';

class GenreFilterSheet extends ConsumerStatefulWidget {
  const GenreFilterSheet({super.key});

  @override
  ConsumerState<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends ConsumerState<GenreFilterSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(genreFilterNotifierProvider.notifier).loadGenres();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(genreFilterNotifierProvider);
    final selectedGenres = filterState['selectedGenres'] as List<int>;
    final availableGenres = filterState['availableGenres'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Filter by Genre',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (selectedGenres.isNotEmpty)
                TextButton(
                  onPressed: () {
                    ref.read(genreFilterNotifierProvider.notifier).clearGenres();
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: AppColors.primaryPink),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (availableGenres.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: availableGenres.map((genre) {
                final id = genre['id'] as int;
                final name = genre['name'] as String;
                final isSelected = selectedGenres.contains(id);

                return GestureDetector(
                  onTap: () {
                    ref.read(genreFilterNotifierProvider.notifier).toggleGenre(id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: isSelected ? null : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppColors.textMuted.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                selectedGenres.isEmpty
                    ? 'Show All Movies'
                    : 'Show ${selectedGenres.length} Genre${selectedGenres.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

void showGenreFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const GenreFilterSheet(),
  );
}
