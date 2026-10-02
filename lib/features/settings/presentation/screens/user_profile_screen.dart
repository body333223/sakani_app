import 'package:flutter/material.dart';
import 'package:sakani/features/settings/presentation/screens/settings_screen.dart';

/// [UserProfileScreen] is unified with [SettingsScreen] to eliminate
/// redundant nested profile screens while keeping backward compatibility.
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen(isEmbedded: false);
  }
}
