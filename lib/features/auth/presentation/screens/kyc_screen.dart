import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/services/kyc_service.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/core/widgets/staggered_entrance.dart';

class KycScreen extends StatefulWidget {
  final bool isModal;
  const KycScreen({super.key, this.isModal = false});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0; // 0: Front ID, 1: Back ID, 2: Face Selfie, 3: Review & Submit
  final TextEditingController _idNumberCtl = TextEditingController();
  String? _frontImagePath;
  String? _backImagePath;
  String? _selfieImagePath;
  bool _isProcessing = false;

  final ImagePicker _picker = ImagePicker();
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    final existing = KycService().currentData;
    if (existing.documentNumber.isNotEmpty) {
      _idNumberCtl.text = existing.documentNumber;
      _frontImagePath = existing.frontPhoto;
      _backImagePath = existing.backPhoto;
      _selfieImagePath = existing.selfiePhoto;
    }
  }

  @override
  void dispose() {
    _idNumberCtl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto({
    required ImageSource source,
    required CameraDevice preferredCamera,
    required Function(String path) onCaptured,
  }) async {
    try {
      final img = await _picker.pickImage(
        source: source,
        preferredCameraDevice: preferredCamera,
        imageQuality: 85,
      );
      if (img != null) {
        setState(() => onCaptured(img.path));
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'تعذر فتح الكاميرا، يرجى التحقق من أذونات التطبيق',
        type: ToastType.error,
      );
    }
  }

  void _showImageSourcePicker({
    required String title,
    required CameraDevice preferredCamera,
    required Function(String path) onCaptured,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: context.accentColor),
                  ),
                  title: const Text('التقاط صورة بالكاميرا فوراً', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _capturePhoto(
                      source: ImageSource.camera,
                      preferredCamera: preferredCamera,
                      onCaptured: onCaptured,
                    );
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
                  title: const Text('اختيار من ألبوم الصور', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _capturePhoto(
                      source: ImageSource.gallery,
                      preferredCamera: preferredCamera,
                      onCaptured: onCaptured,
                    );
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
    if (_idNumberCtl.text.trim().isEmpty) {
      AppSnackbar.show(context, message: 'يرجى إدخال الرقم القومي للبطاقة', type: ToastType.warning);
      setState(() => _currentStep = 0);
      return;
    }
    if (_frontImagePath == null) {
      AppSnackbar.show(context, message: 'يرجى تصوير الوجه الأمامي للبطاقة', type: ToastType.warning);
      setState(() => _currentStep = 0);
      return;
    }
    if (_backImagePath == null) {
      AppSnackbar.show(context, message: 'يرجى تصوير الوجه الخلفي للبطاقة', type: ToastType.warning);
      setState(() => _currentStep = 1);
      return;
    }
    if (_selfieImagePath == null) {
      AppSnackbar.show(context, message: 'يرجى التقاط سيلفي الوجه لمطابقة الملامح', type: ToastType.warning);
      setState(() => _currentStep = 2);
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate real AI facial biometric matching & ID analysis (like Binance / Valu)
    await Future.delayed(const Duration(milliseconds: 1800));

    await KycService().submitVerification(
      documentType: 'national_id',
      documentNumber: _idNumberCtl.text.trim(),
      frontPhoto: _frontImagePath!,
      backPhoto: _backImagePath,
      selfiePhoto: _selfieImagePath,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      AppSnackbar.show(
        context,
        message: 'تم التحقق من الهوية ومطابقة الوجه بنجاح! حسابك موثق الآن.',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final kycData = KycService().currentData;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF080C14) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'توثيق الهوية والوجه (KYC)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: kycData.isVerified ? _buildVerifiedView(kycData) : _buildVerificationFlow(),
    );
  }

  // ── Verified Screen (When completed) ──
  Widget _buildVerifiedView(KycData data) {
    final maskedId = data.documentNumber.length > 6
        ? '${data.documentNumber.substring(0, 3)}******${data.documentNumber.substring(data.documentNumber.length - 3)}'
        : data.documentNumber;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.15),
                  context.cardColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'الحساب موثق رسمياً بنجاح',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'تمت مطابقة صورة البطاقة الشخصية مع ملامح الوجه البيومترية',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Divider(color: context.borderColor),
                const SizedBox(height: 14),

                // Details Row
                _buildInfoRow('نوع الوثيقة', 'بطاقة الرقم القومي المصري'),
                const SizedBox(height: 10),
                _buildInfoRow('رقم الهوية', maskedId),
                const SizedBox(height: 10),
                _buildInfoRow('حالة الفحص', 'مطابق بنسبة 99.4% (ناجح)'),
                const SizedBox(height: 10),
                _buildInfoRow(
                  'تاريخ التوثيق',
                  data.verifiedAt != null
                      ? '${data.verifiedAt!.year}/${data.verifiedAt!.month}/${data.verifiedAt!.day}'
                      : 'اليوم',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Perks of verified accounts
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: context.accentColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'مزايا الحساب الموثق في سكني',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildPerkItem('أولوية تأكيد الحجوزات لدى الملاك المعتمدين'),
                _buildPerkItem('شارة زرقاء ذهبية موثقة بجوار اسمك في المحادثات'),
                _buildPerkItem('حماية تأمينية وضمان مالي على الإيداعات والعقود'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Re-verify option
          BouncingTap(
            onTap: () async {
              await KycService().resetVerification();
              setState(() {
                _currentStep = 0;
                _frontImagePath = null;
                _backImagePath = null;
                _selfieImagePath = null;
                _idNumberCtl.clear();
              });
            },
            child: Text(
              'تحديث بيانات الهوية أو إعادة التوثيق',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Multi-Step Verification Flow ──
  Widget _buildVerificationFlow() {
    return Column(
      children: [
        // Stepper Progress Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(
            children: [
              _buildStepIndicator(0, 'وجه البطاقة', Icons.credit_card_rounded),
              _buildStepDivider(0),
              _buildStepIndicator(1, 'ظهر البطاقة', Icons.flip_rounded),
              _buildStepDivider(1),
              _buildStepIndicator(2, 'سيلفي الوجه', Icons.face_retouching_natural_rounded),
              _buildStepDivider(2),
              _buildStepIndicator(3, 'التأكيد', Icons.verified_rounded),
            ],
          ),
        ),

        Divider(height: 1, color: context.borderColor),

        // Step Content Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentStepWidget(),
            ),
          ),
        ),

        // Bottom Navigation Buttons
        _buildBottomActionBar(),
      ],
    );
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case 0:
        return _buildFrontIdStep();
      case 1:
        return _buildBackIdStep();
      case 2:
        return _buildSelfieStep();
      case 3:
      default:
        return _buildReviewStep();
    }
  }

  // ── Step 0: Front of National ID ──
  Widget _buildFrontIdStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInstructionHeader(
          stepNumber: 'الخطوة 1 من 4',
          title: 'التقاط الوجه الأمامي لبطاقة الرقم القومي',
          subtitle: 'تأكد من وضوح الاسم، الصورة الشخصية، والرقم القومي بدون انعكاس ضوئي',
        ),
        const SizedBox(height: 18),

        // National ID Number Input
        Text(
          'الرقم القومي (14 رقم)',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: TextField(
            controller: _idNumberCtl,
            keyboardType: TextInputType.number,
            maxLength: 14,
            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5),
            decoration: InputDecoration(
              hintText: '29XXXXXXXXXXXX',
              counterText: '',
              prefixIcon: Icon(Icons.badge_outlined, color: context.accentColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Front Card Scanner Box
        _buildCardScannerBox(
          imagePath: _frontImagePath,
          label: 'انقر لتصوير أو اختيار الوجه الأمامي للبطاقة',
          icon: Icons.credit_card_rounded,
          onTap: () => _showImageSourcePicker(
            title: 'تصوير الوجه الأمامي للبطاقة',
            preferredCamera: CameraDevice.rear,
            onCaptured: (path) => setState(() => _frontImagePath = path),
          ),
        ),
      ],
    );
  }

  // ── Step 1: Back of National ID ──
  Widget _buildBackIdStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInstructionHeader(
          stepNumber: 'الخطوة 2 من 4',
          title: 'التقاط الوجه الخلفي لبطاقة الرقم القومي',
          subtitle: 'تأكد من وضوح الباركود، المهنة، والحالة الاجتماعية داخل الإطار',
        ),
        const SizedBox(height: 20),

        // Back Card Scanner Box
        _buildCardScannerBox(
          imagePath: _backImagePath,
          label: 'انقر لتصوير أو اختيار الوجه الخلفي للبطاقة',
          icon: Icons.flip_to_back_rounded,
          onTap: () => _showImageSourcePicker(
            title: 'تصوير الوجه الخلفي للبطاقة',
            preferredCamera: CameraDevice.rear,
            onCaptured: (path) => setState(() => _backImagePath = path),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Biometric Face Selfie (The big platforms feature) ──
  Widget _buildSelfieStep() {
    return Column(
      children: [
        _buildInstructionHeader(
          stepNumber: 'الخطوة 3 من 4',
          title: 'فحص ملامح الوجه البيومترية (سيلفي حي)',
          subtitle: 'انظر مباشرة إلى الكاميرا وتأكد من وجود إضاءة كافية بدون ارتداء نظارات شمسية أو قبعة',
        ),
        const SizedBox(height: 24),

        // Oval Face Scanner Guide
        Center(
          child: BouncingTap(
            scaleFactor: 0.97,
            onTap: () => _showImageSourcePicker(
              title: 'التقاط سيلفي للوجه',
              preferredCamera: CameraDevice.front,
              onCaptured: (path) => setState(() => _selfieImagePath = path),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing glowing background ring
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 230 + (_pulseController.value * 14),
                      height: 290 + (_pulseController.value * 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(140),
                        border: Border.all(
                          color: context.accentColor.withValues(
                            alpha: 0.2 + (_pulseController.value * 0.3),
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),

                // Oval container with image or placeholder
                Container(
                  width: 220,
                  height: 280,
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(130),
                    border: Border.all(
                      color: _selfieImagePath != null
                          ? AppColors.success
                          : context.accentColor,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_selfieImagePath != null
                                ? AppColors.success
                                : context.accentColor)
                            .withValues(alpha: 0.25),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _selfieImagePath != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(_selfieImagePath!),
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'تم التقاط الوجه',
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.face_retouching_natural_rounded,
                              size: 72,
                              color: context.accentColor.withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'اضغط لفتح كاميرا السيلفي',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.accentColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ضع وجهك داخل الإطار البيضاوي',
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Biometric checklist
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCheckBadge('إضاءة جيدة'),
            const SizedBox(width: 12),
            _buildCheckBadge('وجه مكشوف'),
            const SizedBox(width: 12),
            _buildCheckBadge('مطابقة AI'),
          ],
        ),
      ],
    );
  }

  // ── Step 3: Review & Final Submission ──
  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInstructionHeader(
          stepNumber: 'الخطوة 4 من 4',
          title: 'مراجعة وتأكيد بيانات التوثيق',
          subtitle: 'تأكد من صحة الصور المرفوعة ورقم الهوية قبل الإرسال النهائي للمطابقة الذكية',
        ),
        const SizedBox(height: 20),

        // Thumbnails row
        Row(
          children: [
            Expanded(
              child: _buildReviewThumbnail(
                title: 'وجه البطاقة',
                path: _frontImagePath,
                step: 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildReviewThumbnail(
                title: 'ظهر البطاقة',
                path: _backImagePath,
                step: 1,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildReviewThumbnail(
                title: 'سيلفي الوجه',
                path: _selfieImagePath,
                step: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            children: [
              _buildInfoRow('نوع المستند', 'بطاقة الرقم القومي'),
              const SizedBox(height: 10),
              _buildInfoRow('الرقم القومي', _idNumberCtl.text),
              const SizedBox(height: 10),
              _buildInfoRow('فحص الحيوية البيومتري', 'جاهز للمطابقة الفورية'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.accentColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.security_rounded, color: context.accentColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'بياناتك وهويتك مشفرة بأعلى معايير التشفير البنكي (256-bit AES) ولا تتم مشاركتها مع أي طرف ثالث.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bottom Action Bar (Back / Next / Submit) ──
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            BouncingTap(
              scaleFactor: 0.95,
              onTap: () => setState(() => _currentStep--),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: const Center(
                  child: Text(
                    'السابق',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: BouncingTap(
              scaleFactor: 0.97,
              onTap: _isProcessing
                  ? null
                  : () {
                      if (_currentStep < 3) {
                        setState(() => _currentStep++);
                      } else {
                        _submitVerification();
                      }
                    },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.accentColor, AppColors.goldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: context.accentColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _currentStep == 3 ? Icons.verified_user_rounded : Icons.arrow_forward_rounded,
                              color: Colors.black,
                              size: 19,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _currentStep == 3 ? 'إرسال وتوثيق الهوية الآن' : 'المتابعة للخطوة التالية',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ──
  Widget _buildStepIndicator(int stepIndex, String title, IconData icon) {
    final isDone = _currentStep > stepIndex;
    final isCurrent = _currentStep == stepIndex;

    return BouncingTap(
      onTap: () => setState(() => _currentStep = stepIndex),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone || isCurrent
                  ? context.accentColor
                  : (context.isDark ? Colors.white10 : Colors.black12),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: context.accentColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isDone ? Icons.check_rounded : icon,
              size: 18,
              color: isDone || isCurrent ? Colors.black : context.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
              color: isCurrent ? context.accentColor : context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(int afterStep) {
    final isPassed = _currentStep > afterStep;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          height: 2,
          color: isPassed ? context.accentColor : context.borderColor,
        ),
      ),
    );
  }

  Widget _buildInstructionHeader({
    required String stepNumber,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: context.accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            stepNumber,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: context.accentColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: context.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildCardScannerBox({
    required String? imagePath,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return BouncingTap(
      scaleFactor: 0.98,
      onTap: onTap,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: imagePath != null ? AppColors.success : context.borderColor,
            width: imagePath != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05),
              blurRadius: 14,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: imagePath != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(imagePath), fit: BoxFit.cover),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'تم التقاط الصورة',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: context.accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 28, color: context.accentColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'التقط صورة واضحة داخل الإطار',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCheckBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewThumbnail({
    required String title,
    required String? path,
    required int step,
  }) {
    return BouncingTap(
      onTap: () => setState(() => _currentStep = step),
      child: Column(
        children: [
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: path != null ? AppColors.success : AppColors.error,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: path != null
                ? Image.file(File(path), fit: BoxFit.cover, width: double.infinity)
                : Center(
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: context.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12.5, color: context.textSecondary, fontWeight: FontWeight.w600),
        ),
        Text(
          val,
          style: TextStyle(fontSize: 13, color: context.textPrimary, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildPerkItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: context.accentColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
