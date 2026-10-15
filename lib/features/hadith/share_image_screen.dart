import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../domain/models/models.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings/settings_provider.dart';
import '../books/book_provider.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class ShareImageScreen extends ConsumerStatefulWidget {
  final Hadith hadith;
  final String? chapterTitle;

  const ShareImageScreen({super.key, required this.hadith, this.chapterTitle});

  @override
  ConsumerState<ShareImageScreen> createState() => _ShareImageScreenState();
}

class _ShareImageScreenState extends ConsumerState<ShareImageScreen> {
  final _screenshotController = ScreenshotController();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Hadith'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildScreenshotWidget(
                child: _buildImageCard(isDark),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _shareImage,
                  icon: _isExporting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.share, color: Colors.white),
                  label: Text(_isExporting ? 'Generating...' : 'Share Image', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotWidget({required Widget child}) {
    return Screenshot(
      controller: _screenshotController,
      child: child,
    );
  }

  Widget _buildImageCard(bool isDark) {
    final settings = ref.watch(settingsProvider);
    final booksAsync = ref.watch(allBooksProvider);
    final currentBook = ref.watch(currentBookProvider);
    final book = booksAsync.value?.firstWhere(
      (b) => b.id == widget.hadith.bookId,
      orElse: () => currentBook,
    ) ?? currentBook;
    final bookName = settings.titleLanguage == 'English'
        ? book.nameEnglish
        : (settings.titleLanguage == 'Arabic' ? book.nameArabic : book.nameUrdu);
    final primaryColor = AppTheme.getBookPrimaryColor(widget.hadith.bookId);

    // We force a specific background color for the screenshot to ensure it looks good when shared
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9);
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.grey.shade300 : Colors.grey.shade800;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(bookName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Text('Hadith #${widget.hadith.hadithNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),

          // Content
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.chapterTitle != null && widget.chapterTitle!.isNotEmpty) ...[
                  Text(
                    widget.chapterTitle!,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                ],

                if (settings.showArabic && widget.hadith.arabicText.isNotEmpty) ...[
                  Text(
                    widget.hadith.arabicText,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: AppTheme.safeGetFont(
                      settings.arabicFontFamily,
                      color: isDark ? Colors.greenAccent.shade100 : primaryColor,
                      fontSize: settings.arabicFontSize,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (settings.showUrdu && widget.hadith.urduText.isNotEmpty) ...[
                  Text(
                    widget.hadith.urduText,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: AppTheme.safeGetFont(
                      settings.urduFontFamily,
                      color: textColor,
                      fontSize: settings.urduFontSize,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (settings.showEnglish && widget.hadith.englishText.isNotEmpty) ...[
                  Text(
                    widget.hadith.englishText,
                    textAlign: TextAlign.left,
                    textDirection: TextDirection.ltr,
                    style: AppTheme.safeGetFont(
                      settings.englishFontFamily,
                      fontSize: settings.englishFontSize,
                      height: 1.6,
                      color: textColor,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Footer Branding
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: primaryColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Shared via All Hadith (سب احادیث) App',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareImage() async {
    setState(() => _isExporting = true);

    try {
      final image = await _screenshotController.capture(pixelRatio: 3.0);
      if (image == null) throw Exception('Failed to capture image');

      final books = ref.read(allBooksProvider).valueOrNull ?? [];
      final book = books.where((b) => b.id == widget.hadith.bookId).firstOrNull ?? ref.read(currentBookProvider);
      final bookName = book?.nameEnglish ?? 'Hadith';

      if (kIsWeb) {
        // For web, use Share.shareXFiles with memory bytes
        final xFile = XFile.fromData(image, mimeType: 'image/png', name: 'hadith_${widget.hadith.hadithNumber}.png');
        await Share.shareXFiles([xFile], text: 'Hadith #${widget.hadith.hadithNumber} from $bookName');
      } else {
        // For mobile/desktop, save to temp dir first
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/hadith_${widget.hadith.hadithNumber}.png').create();
        await imagePath.writeAsBytes(image);

        final xFile = XFile(imagePath.path);
        await Share.shareXFiles([xFile], text: 'Hadith #${widget.hadith.hadithNumber} from $bookName');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
