import 'package:flutter/material.dart';
import 'package:sakani/features/settings/presentation/screens/profile_screen.dart';

/// [UserProfileScreen] now redirects to the new full [ProfileScreen]
/// to provide the complete profile experience.
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
