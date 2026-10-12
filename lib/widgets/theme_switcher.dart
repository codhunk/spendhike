import 'package:flutter/material.dart';
import '../services/app_settings.dart';
import '../config/app_theme.dart';

/// App Bar or Header Theme Switcher Icon Button
class ThemeSwitcherButton extends StatelessWidget {
  final bool showDialogOnTap;
  final VoidCallback? onThemeChanged;

  const ThemeSwitcherButton({
    super.key,
    this.showDialogOnTap = true,
    this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final mode = AppSettings.instance.themeMode;
        final icon = switch (mode) {
          ThemeMode.light => Icons.light_mode_rounded,
          ThemeMode.dark => Icons.dark_mode_rounded,
          ThemeMode.system => Icons.brightness_auto_rounded,
        };

        final tooltip = switch (mode) {
          ThemeMode.light => 'Light Mode'.tr,
          ThemeMode.dark => 'Dark Mode'.tr,
          ThemeMode.system => 'System Default'.tr,
        };

        return IconButton(
          icon: Icon(icon, size: 22),
          tooltip: tooltip,
          splashRadius: 22,
          onPressed: () {
            if (showDialogOnTap) {
              showThemeSelectionDialog(context);
            } else {
              AppSettings.instance.cycleThemeMode();
              onThemeChanged?.call();
            }
          },
        );
      },
    );
  }
}

/// Modal dialog for selecting theme (Light, Dark, System Default)
Future<void> showThemeSelectionDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (ctx) => const _ThemeSelectionDialog(),
  );
}

class _ThemeSelectionDialog extends StatelessWidget {
  const _ThemeSelectionDialog();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final currentMode = AppSettings.instance.themeMode;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.palette_outlined, color: colors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select Theme'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOptionTile(
                title: 'Light Mode'.tr,
                subtitle: 'Always use light theme'.tr,
                icon: Icons.light_mode_rounded,
                iconColor: const Color(0xFFF59E0B),
                isSelected: currentMode == ThemeMode.light,
                onTap: () {
                  AppSettings.instance.setThemeMode(ThemeMode.light);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              _ThemeOptionTile(
                title: 'Dark Mode'.tr,
                subtitle: 'Always use dark theme'.tr,
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFF818CF8),
                isSelected: currentMode == ThemeMode.dark,
                onTap: () {
                  AppSettings.instance.setThemeMode(ThemeMode.dark);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              _ThemeOptionTile(
                title: 'System Default'.tr,
                subtitle: 'Follow system appearance'.tr,
                icon: Icons.brightness_auto_rounded,
                iconColor: const Color(0xFF10B981),
                isSelected: currentMode == ThemeMode.system,
                onTap: () {
                  AppSettings.instance.setThemeMode(ThemeMode.system);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close'.tr,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.1)
              : colors.surfaceSubtle.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 15,
                      color: isSelected ? colors.primary : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: colors.primary, size: 20)
            else
              Icon(Icons.radio_button_unchecked_rounded,
                  color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// An embedded selector widget for Settings / Profile screen
class ThemeSelectorSettingTile extends StatelessWidget {
  const ThemeSelectorSettingTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final mode = AppSettings.instance.themeMode;
        final (title, icon, iconColor) = switch (mode) {
          ThemeMode.light => ('Light Mode'.tr, Icons.light_mode_rounded, const Color(0xFFF59E0B)),
          ThemeMode.dark => ('Dark Mode'.tr, Icons.dark_mode_rounded, const Color(0xFF818CF8)),
          ThemeMode.system => ('System Default'.tr, Icons.brightness_auto_rounded, const Color(0xFF10B981)),
        };

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(
            'Theme Mode'.tr,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: colors.textMuted,
          ),
          onTap: () => showThemeSelectionDialog(context),
        );
      },
    );
  }
}
