import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';

class RoleSelectorTab extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  const RoleSelectorTab({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: AppRadius.mdBr,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabItem(
              title: 'مستأجر (Tenant)',
              icon: Icons.person_outline_rounded,
              isSelected: selectedRole == 'tenant',
              onTap: () => onRoleChanged('tenant'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabItem(
              title: 'مالك عقار (Owner)',
              icon: Icons.domain_rounded,
              isSelected: selectedRole == 'owner',
              onTap: () => onRoleChanged('owner'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.gold : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: AppRadius.smBr,
          boxShadow: isSelected ? AppShadows.goldGlow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF080C14) : context.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF080C14) : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
