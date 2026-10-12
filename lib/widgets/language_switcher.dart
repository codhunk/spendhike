import 'package:flutter/material.dart';
import '../services/app_settings.dart';
import '../services/api_service.dart';

/// Shows a dialog allowing the user to switch between English and Hindi
void showLanguageSelectionDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (ctx) => ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0453CD).withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.translate, color: Color(0xFF0453CD), size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              AppSettings.instance.tr('Select Language'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOptionTile(
              title: 'English',
              subtitle: 'English (Default)',
              isSelected: !AppSettings.instance.isHindi,
              onTap: () async {
                Navigator.pop(ctx);
                await AppSettings.instance.setLanguage(AppLanguage.english);
                if (ApiService.isLoggedIn) {
                  ApiService.updateProfile({'language': 'English'});
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppSettings.instance.tr('Language set to English')),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            _LanguageOptionTile(
              title: 'हिंदी',
              subtitle: 'Hindi',
              isSelected: AppSettings.instance.isHindi,
              onTap: () async {
                Navigator.pop(ctx);
                await AppSettings.instance.setLanguage(AppLanguage.hindi);
                if (ApiService.isLoggedIn) {
                  ApiService.updateProfile({'language': 'Hindi'});
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppSettings.instance.tr('Language set to Hindi')),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppSettings.instance.tr('Close'),
              style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF44474C)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LanguageOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0453CD).withAlpha(25)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0453CD)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isSelected ? const Color(0xFF0453CD) : Colors.grey.withAlpha(50),
              child: Text(
                title.substring(0, 1),
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF0453CD) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF0453CD), size: 22),
          ],
        ),
      ),
    );
  }
}

/// A compact or standard button that can be embedded in AppBars, Menus, or Screens
class LanguageSwitcherButton extends StatelessWidget {
  final bool isCompact;
  final Color? color;

  const LanguageSwitcherButton({
    super.key,
    this.isCompact = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final currentText = AppSettings.instance.isHindi ? 'हिन्दी' : 'English';
        final themeColor = color ?? const Color(0xFF0453CD);

        if (isCompact) {
          return IconButton(
            tooltip: AppSettings.instance.tr('Select Language'),
            icon: Icon(Icons.translate, color: themeColor, size: 20),
            onPressed: () => showLanguageSelectionDialog(context),
          );
        }

        return TextButton.icon(
          onPressed: () => showLanguageSelectionDialog(context),
          icon: Icon(Icons.translate, size: 16, color: themeColor),
          label: Text(
            currentText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: themeColor,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: themeColor.withAlpha(80)),
            ),
          ),
        );
      },
    );
  }
}
