import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/services/kyc_service.dart';
import 'package:sakani/core/widgets/gradient_button.dart';

class KycScreen extends StatefulWidget {
  final bool isModal;
  const KycScreen({super.key, this.isModal = false});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  String _selectedDoc = 'national_id'; // 'national_id' or 'passport'
  final TextEditingController _idNumberCtl = TextEditingController();
  String? _frontImagePath;
  String? _backImagePath;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final existing = KycService().currentData;
    if (existing.documentNumber.isNotEmpty) {
      _idNumberCtl.text = existing.documentNumber;
      _selectedDoc = existing.documentType;
      _frontImagePath = existing.frontPhoto;
      _backImagePath = existing.backPhoto;
    }
  }

  @override
  void dispose() {
    _idNumberCtl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                  isFront ? 'صورة الوجه الأمامي' : 'صورة الوجه الخلفي',
                  style: GoogleFonts.tajawal(
                    color: context.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: context.accentColor),
                  ),
                  title: Text(
                    'التقاط صورة بالكاميرا',
                    style: GoogleFonts.tajawal(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final img = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 85,
                    );
                    if (img != null) {
                      setState(() {
                        if (isFront) {
                          _frontImagePath = img.path;
                        } else {
                          _backImagePath = img.path;
                        }
                      });
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_library_rounded, color: context.accentColor),
                  ),
                  title: Text(
                    'اختيار من ألبوم الصور',
                    style: GoogleFonts.tajawal(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final img = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (img != null) {
                      setState(() {
                        if (isFront) {
                          _frontImagePath = img.path;
                        } else {
                          _backImagePath = img.path;
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitVerification() async {
    final idNumber = _idNumberCtl.text.trim();
    if (idNumber.isEmpty) {
      _showSnackbar('يرجى كتابة رقم الهوية أو جواز السفر');
      return;
    }

    if (_frontImagePath == null) {
      _showSnackbar('يرجى التقاط أو رفع صورة الهوية الأمامية');
      return;
    }

    if (_selectedDoc == 'national_id' && _backImagePath == null) {
      _showSnackbar('يرجى التقاط أو رفع صورة ظهر بطاقة الرقم القومي');
      return;
    }

    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 700));

    await KycService().submitVerification(
      documentType: _selectedDoc,
      documentNumber: idNumber,
      frontPhoto: _frontImagePath!,
      backPhoto: _backImagePath,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              'تم توثيق الحساب بنجاح! 🎉',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تم التحقق من بياناتك الرسمية واعتماد حسابك. يمكنك الآن الحجز الفوري وإدارة العقارات بأمان تام.',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                color: context.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'تم، متابعة',
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.tajawal()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = KycService().isVerified;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'توثيق الهوية الرسمية',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isVerified
                    ? AppColors.success.withValues(alpha: 0.12)
                    : context.accentColor.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdBr,
                border: Border.all(
                  color: isVerified
                      ? AppColors.success.withValues(alpha: 0.3)
                      : context.accentColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isVerified ? Icons.verified_rounded : Icons.shield_outlined,
                    color: isVerified ? AppColors.success : context.accentColor,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVerified ? 'حسابك موثق رسمياً ✅' : 'التوثيق مطلوب لتأكيد الحجوزات',
                          style: GoogleFonts.tajawal(
                            color: isVerified ? AppColors.success : context.accentColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isVerified
                              ? 'تم التحقق من الوثائق الرسمية بنجاح'
                              : 'ارفع صورة بطاقة الرقم القومي أو الباسبور لحماية حقوقك',
                          style: GoogleFonts.tajawal(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Document Type Switcher
            Text(
              'اختر نوع وثيقة إثبات الشخصية',
              style: GoogleFonts.tajawal(
                color: context.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DocTypeTab(
                    icon: Icons.badge_outlined,
                    label: 'بطاقة الرقم القومي',
                    isSelected: _selectedDoc == 'national_id',
                    onTap: () => setState(() => _selectedDoc = 'national_id'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DocTypeTab(
                    icon: Icons.flight_takeoff_rounded,
                    label: 'جواز السفر (Passport)',
                    isSelected: _selectedDoc == 'passport',
                    onTap: () => setState(() => _selectedDoc = 'passport'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Document Number Input
            Text(
              _selectedDoc == 'national_id'
                  ? 'الرقم القومي (14 رقم)'
                  : 'رقم جواز السفر',
              style: GoogleFonts.tajawal(
                color: context.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _idNumberCtl,
              keyboardType: _selectedDoc == 'national_id'
                  ? TextInputType.number
                  : TextInputType.text,
              style: GoogleFonts.tajawal(color: context.textPrimary, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: _selectedDoc == 'national_id'
                    ? 'أدخل الـ 14 رقماً المدونة على البطاقة'
                    : 'أدخل رقم جواز السفر المعتمد',
                prefixIcon: Icon(
                  _selectedDoc == 'national_id'
                      ? Icons.credit_card_rounded
                      : Icons.card_travel_rounded,
                  color: context.accentColor,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Upload Box 1: Front
            Text(
              _selectedDoc == 'national_id'
                  ? 'صورة بطاقة الرقم القومي (الوجه الأمامي)'
                  : 'صورة صفحة البيانات في جواز السفر',
              style: GoogleFonts.tajawal(
                color: context.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _ImageUploadBox(
              imagePath: _frontImagePath,
              placeholderTitle: 'انقر لالتقاط أو اختيار الصورة الأمامية',
              onTap: () => _pickImage(true),
              onRemove: () => setState(() => _frontImagePath = null),
            ),

            if (_selectedDoc == 'national_id') ...[
              const SizedBox(height: 20),
              Text(
                'صورة بطاقة الرقم القومي (الوجه الخلفي)',
                style: GoogleFonts.tajawal(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _ImageUploadBox(
                imagePath: _backImagePath,
                placeholderTitle: 'انقر لالتقاط أو اختيار صورة ظهر البطاقة',
                onTap: () => _pickImage(false),
                onRemove: () => setState(() => _backImagePath = null),
              ),
            ],

            const SizedBox(height: 32),

            // Submit Button
            GradientButton(
              text: _isSubmitting
                  ? 'جاري التحقق والاعتماد...'
                  : (isVerified ? 'تحديث وتأكيد التوثيق' : 'إرسال وتوثيق الحساب الآن'),
              icon: Icons.shield_rounded,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitVerification,
            ),

            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: context.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'بياناتك مشفرة ومحمية وفق أعلى معايير الأمان المصرفي',
                    style: GoogleFonts.tajawal(
                      color: context.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _DocTypeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DocTypeTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? context.accentColor.withValues(alpha: 0.15)
              : (context.isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: AppRadius.mdBr,
          border: Border.all(
            color: isSelected ? context.accentColor : context.borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? context.accentColor : context.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                color: isSelected ? context.accentColor : context.textPrimary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageUploadBox extends StatelessWidget {
  final String? imagePath;
  final String placeholderTitle;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ImageUploadBox({
    required this.imagePath,
    required this.placeholderTitle,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Container(
        height: 170,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdBr,
          border: Border.all(color: context.accentColor.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imagePath!.startsWith('http')
                ? Image.network(imagePath!, fit: BoxFit.cover)
                : Image.file(File(imagePath!), fit: BoxFit.cover),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppRadius.mdBr,
          border: Border.all(
            color: context.borderColor,
            style: BorderStyle.solid,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_a_photo_outlined, color: context.accentColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              placeholderTitle,
              style: GoogleFonts.tajawal(
                color: context.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
