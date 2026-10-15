import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../data/repositories/hadith_repository.dart';
import '../../domain/models/models.dart';

final collectionsProvider = FutureProvider<List<HadithCollection>>((ref) async {
  final repo = ref.watch(hadithRepositoryProvider);
  return repo.getCollections();
});

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: collectionsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (collections) {
          if (collections.isEmpty) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.create_new_folder_outlined,
                            size: 64,
                            color: Theme.of(context).primaryColor,
                          ),
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                         .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1500.ms, curve: Curves.easeInOut),
                        const SizedBox(height: 24),
                        Text(
                          'No Collections',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + icon to create your first\nhadith collection.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOut),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              return _CollectionCard(
                collection: collection,
                index: index,
                isDark: isDark,
                onDelete: () async {
                  final repo = ref.read(hadithRepositoryProvider);
                  await repo.deleteCollection(collection.id);
                  ref.invalidate(collectionsProvider);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Collection', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Collection name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final repo = ref.read(hadithRepositoryProvider);
                await repo.createCollection(controller.text);
                ref.invalidate(collectionsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends ConsumerWidget {
  final HadithCollection collection;
  final int index;
  final bool isDark;
  final VoidCallback onDelete;

  const _CollectionCard({
    required this.collection,
    required this.index,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(FutureProvider((ref) async {
      return ref.watch(hadithRepositoryProvider).getCollectionHadithCount(collection.id);
    }));

    return Dismissible(
      key: Key('collection_${collection.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Collection?'),
            content: Text('Are you sure you want to delete "${collection.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.folder, color: Theme.of(context).primaryColor),
          ),
          title: Text(
            collection.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textDark,
            ),
          ),
          subtitle: countAsync.when(
            data: (count) => Text('$count hadiths', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade500)),
            loading: () => Text('...', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade500)),
            error: (_, st) => Text('0 hadiths', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade500)),
          ),
          trailing: Icon(Icons.chevron_right, color: Theme.of(context).primaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          // FIX Bug 1: Navigate to CollectionDetailScreen instead of showing a SnackBar
          onTap: () => context.push('/home/collections/${collection.id}'),
        ),
      ),
    ).animate().fadeIn(delay: (80 * index).ms).slideX(begin: 0.05, end: 0);
  }
}
