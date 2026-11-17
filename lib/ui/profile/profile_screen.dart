import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/session_view_model.dart';
import 'settings_view_model.dart';

/// The logged-in member, app settings and sign-out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    // Read before the await: the screen may be gone afterwards.
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<SessionViewModel>().signOut();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not log out. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.watch<SessionViewModel>();
    final settings = context.watch<SettingsViewModel>();
    final member = session.member;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (member != null)
            ListTile(
              leading: CircleAvatar(
                child: Text(
                  member.displayName.isEmpty
                      ? '?'
                      : member.displayName[0].toUpperCase(),
                ),
              ),
              title: Text(
                member.displayName,
                style: theme.textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                member.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const Divider(),
          _SectionTitle('Theme'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) =>
                  context.read<SettingsViewModel>().setThemeMode(s.single),
            ),
          ),
          _SectionTitle('Language'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<AppLanguage>(
              segments: const [
                ButtonSegment(
                  value: AppLanguage.english,
                  label: Text('English'),
                ),
                ButtonSegment(value: AppLanguage.polish, label: Text('Polski')),
              ],
              selected: {settings.language},
              onSelectionChanged: (s) =>
                  context.read<SettingsViewModel>().setLanguage(s.single),
            ),
          ),
          if (settings.language == AppLanguage.polish)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'The Polish translation is not ready yet.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Log out',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            trailing: session.isSigningOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            enabled: !session.isSigningOut,
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
