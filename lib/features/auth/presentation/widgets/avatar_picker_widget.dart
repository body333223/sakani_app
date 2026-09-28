import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sakani/core/config/theme.dart';

class AvatarPickerWidget extends StatelessWidget {
  final XFile? imageFile;
  final ValueChanged<XFile?> onImageSelected;

  const AvatarPickerWidget({
    super.key,
    required this.imageFile,
    required this.onImageSelected,
  });

  Future<void> _pick(BuildContext context, ImageSource source) async {
    Navigator.pop(context);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        onImageSelected(picked);
      }
    } catch (_) {}
  }

  void _showModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'اختر صورة الحساب',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: context.accentColor),
                title: Text('التقاط صورة بالكاميرا', style: TextStyle(color: context.textPrimary)),
                onTap: () => _pick(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: context.accentColor),
                title: Text('اختيار من المعرض', style: TextStyle(color: context.textPrimary)),
                onTap: () => _pick(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _showModal(context),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.accentColor, width: 2),
                color: context.cardColor,
                image: imageFile != null
                    ? DecorationImage(
                        image: FileImage(File(imageFile!.path)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageFile == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 46,
                      color: context.textSecondary.withValues(alpha: 0.6),
                    )
                  : null,
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.gold,
                boxShadow: AppShadows.goldGlow,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: Color(0xFF080C14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
