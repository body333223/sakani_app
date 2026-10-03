import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/api_config.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/notifications_bottom_sheet.dart';

/// خدمة الإشعارات اللحظية Push Notifications مع التنبيه الصوتي الحقيقي
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal() {
    _initAudio();
  }

  AudioPlayer? _audioPlayer;

  void _initAudio() {
    try {
      _audioPlayer = AudioPlayer();
    } catch (_) {}
  }

  // ── Tone Synthesis (Pure Dart In-Memory Audio Generation) ──
  /// توليد نغمة WAV ثنائية أو ثلاثية نقية للإنذار الصوتي
  static Uint8List _generateChimeWav({
    required List<double> frequencies,
    required List<int> durationsMs,
  }) {
    const sampleRate = 44100;
    final pcmBytes = BytesBuilder();
    for (int t = 0; t < frequencies.length; t++) {
      final freq = frequencies[t];
      final noteSamples = (sampleRate * (durationsMs[t] / 1000.0)).round();

      for (int i = 0; i < noteSamples; i++) {
        final timeSec = i / sampleRate.toDouble();
        // Envelope: smooth attack & exponential decay
        final progress = i / noteSamples.toDouble();
        final envelope = math.sin(progress * math.pi) * math.exp(-progress * 2.0);

        final sampleVal = (math.sin(2 * math.pi * freq * timeSec) * 30000 * envelope).round().clamp(-32767, 32767);
        pcmBytes.addByte(sampleVal & 0xFF);
        pcmBytes.addByte((sampleVal >> 8) & 0xFF);
      }
    }

    final rawPcm = pcmBytes.toBytes();
    final wav = BytesBuilder();

    // RIFF chunk
    wav.add(ascii.encode('RIFF'));
    final int fileSize = 36 + rawPcm.length;
    wav.addByte(fileSize & 0xFF);
    wav.addByte((fileSize >> 8) & 0xFF);
    wav.addByte((fileSize >> 16) & 0xFF);
    wav.addByte((fileSize >> 24) & 0xFF);
    wav.add(ascii.encode('WAVE'));

    // fmt subchunk
    wav.add(ascii.encode('fmt '));
    wav.addByte(16); // Subchunk1Size
    wav.addByte(0);
    wav.addByte(0);
    wav.addByte(0);
    wav.addByte(1); // AudioFormat = 1 (PCM)
    wav.addByte(0);
    wav.addByte(1); // NumChannels = 1 (Mono)
    wav.addByte(0);
    // SampleRate = 44100
    wav.addByte(sampleRate & 0xFF);
    wav.addByte((sampleRate >> 8) & 0xFF);
    wav.addByte((sampleRate >> 16) & 0xFF);
    wav.addByte((sampleRate >> 24) & 0xFF);
    // ByteRate = SampleRate * 2
    final byteRate = sampleRate * 2;
    wav.addByte(byteRate & 0xFF);
    wav.addByte((byteRate >> 8) & 0xFF);
    wav.addByte((byteRate >> 16) & 0xFF);
    wav.addByte((byteRate >> 24) & 0xFF);
    // BlockAlign = 2
    wav.addByte(2);
    wav.addByte(0);
    // BitsPerSample = 16
    wav.addByte(16);
    wav.addByte(0);

    // data subchunk
    wav.add(ascii.encode('data'));
    final dataSize = rawPcm.length;
    wav.addByte(dataSize & 0xFF);
    wav.addByte((dataSize >> 8) & 0xFF);
    wav.addByte((dataSize >> 16) & 0xFF);
    wav.addByte((dataSize >> 24) & 0xFF);
    wav.add(rawPcm);

    return wav.toBytes();
  }

  /// نغمة إنذار عاجلة لهاتف المالك عند وصول طلب حجز جديد
  Future<void> playOwnerBookingAlertTone() async {
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      final wav = _generateChimeWav(
        frequencies: [880.0, 1174.66], // A5 -> D6 luxury chime
        durationsMs: [160, 280],
      );
      if (_audioPlayer != null) {
        await _audioPlayer!.play(BytesSource(wav));
      }
    } catch (_) {}
  }

  /// نغمة احتفالية سعيدة لهاتف المستأجر عند قبول الحجز وتوثيق العقد
  Future<void> playTenantAcceptedAlertTone() async {
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      final wav = _generateChimeWav(
        frequencies: [523.25, 659.25, 783.99, 1046.50], // C5 -> E5 -> G5 -> C6 joy chord
        durationsMs: [120, 120, 140, 320],
      );
      if (_audioPlayer != null) {
        await _audioPlayer!.play(BytesSource(wav));
      }
    } catch (_) {}
  }

  /// نغمة إشعار اعتيادية
  Future<void> playGenericAlertTone() async {
    try {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.alert);
      final wav = _generateChimeWav(
        frequencies: [587.33, 880.0],
        durationsMs: [140, 220],
      );
      if (_audioPlayer != null) {
        await _audioPlayer!.play(BytesSource(wav));
      }
    } catch (_) {}
  }

  // ── Dispatch Methods ──

  /// إرسال تنبيه عاجل لهاتف المالك بوجود طلب حجز جديد
  Future<void> notifyOwnerNewBooking({
    required BuildContext? context,
    required String ownerId,
    required String tenantName,
    required String apartmentTitle,
    required double totalAmount,
    required String bookingId,
  }) async {
    // 1. تشغيل التنبيه الصوتي والاهتزاز فوراً
    await playOwnerBookingAlertTone();

    // 2. إضافة إشعار داخل التطبيق
    await NotificationsBottomSheet.addNotification(
      title: 'طلب حجز جديد عاجل! 🔔',
      body: 'المستأجر $tenantName طلب حجز $apartmentTitle بقيمة ${totalAmount.round()} ج.م',
      icon: Icons.event_available_rounded,
      color: AppColors.gold,
    );

    // 3. إرسال Push Notification حقيقي إلى السيرفر
    _sendPushToServer(
      recipientId: ownerId,
      title: 'طلب حجز جديد عاجل 🔔',
      body: 'المستأجر $tenantName طلب حجز $apartmentTitle. يرجى المراجعة والقبول.',
      payload: {
        'type': 'new_booking_request',
        'bookingId': bookingId,
        'sound': 'urgent_chime.wav',
        'priority': 'high',
      },
    );

    // 4. إظهار بانر فاخر أعلى الشاشة إذا كان context متاحاً
    if (context != null && context.mounted) {
      showFloatingNotificationBanner(
        context: context,
        title: 'تم إرسال طلب الحجز وتنبيه المالك 🔔',
        message: 'تم إصدار إشعار صوتي فوري على هاتف مالك العقار لمراجعة طلبك.',
        isSuccess: true,
      );
    }
  }

  /// إرسال تنبيه فوري لهاتف المستأجر فور قبول المالك للحجز
  Future<void> notifyTenantBookingAccepted({
    required BuildContext? context,
    required String tenantId,
    required String apartmentTitle,
    required String contractId,
  }) async {
    // 1. تشغيل التنبيه الصوتي
    await playTenantAcceptedAlertTone();

    // 2. إضافة إشعار داخل التطبيق
    await NotificationsBottomSheet.addNotification(
      title: 'تم قبول حجزك وتوثيق العقد! 📄🎉',
      body: 'وافق المالك على حجز $apartmentTitle وتم توليد وثيقة عقد الإيجار الإلكتروني الموثق رقم $contractId',
      icon: Icons.verified_rounded,
      color: AppColors.success,
    );

    // 3. إرسال Push Notification إلى السيرفر
    _sendPushToServer(
      recipientId: tenantId,
      title: 'تم قبول حجزك رسمياً! 📄🎉',
      body: 'تهانينا! وافق المالك على طلبك لشقة $apartmentTitle وتم إصدار عقد الإيجار الموثق بالرقم القومي.',
      payload: {
        'type': 'booking_accepted_contract_issued',
        'contractId': contractId,
        'sound': 'success_fanfare.wav',
        'priority': 'high',
      },
    );

    // 4. إظهار بانر فوري
    if (context != null && context.mounted) {
      showFloatingNotificationBanner(
        context: context,
        title: 'تم قبول الحجز وتوليد العقد الموثق! 📄✨',
        message: 'تم تفعيل وثيقة الإيجار الرسمية برقم قومي وبصمة مشفرة SHA-256.',
        isSuccess: true,
      );
    }
  }

  /// إرسال تنبيه للمستأجر في حال رفض الحجز
  Future<void> notifyTenantBookingRejected({
    required BuildContext? context,
    required String tenantId,
    required String apartmentTitle,
  }) async {
    await playGenericAlertTone();

    await NotificationsBottomSheet.addNotification(
      title: 'تم الاعتذار عن الحجز ⚠️',
      body: 'نأسف، اعتذر المالك عن حجز $apartmentTitle في هذه الفترة.',
      icon: Icons.cancel_outlined,
      color: AppColors.error,
    );

    _sendPushToServer(
      recipientId: tenantId,
      title: 'اعتذار عن الحجز ⚠️',
      body: 'نأسف، اعتذر المالك عن قبول حجز $apartmentTitle.',
      payload: {'type': 'booking_rejected'},
    );
  }

  /// إرسال إشعار الدفع عبر الـ API للخادم
  Future<void> _sendPushToServer({
    required String recipientId,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/send'),
        headers: ApiConfig.authHeaders,
        body: jsonEncode({
          'recipientId': recipientId,
          'title': title,
          'body': body,
          'data': payload,
          'sound': 'default',
          'vibrate': true,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  /// إظهار بانر عائم فاخر أعلى الشاشة (Floating HUD Banner)
  static void showFloatingNotificationBanner({
    required BuildContext context,
    required String title,
    required String message,
    bool isSuccess = true,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -50.0, end: 0.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (context, yOffset, child) {
              return Transform.translate(
                offset: Offset(0, yOffset),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSuccess
                      ? [const Color(0xFF0F251E), const Color(0xFF081410)]
                      : [const Color(0xFF2A1515), const Color(0xFF140A0A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.lgBr,
                border: Border.all(
                  color: isSuccess ? AppColors.success.withValues(alpha: 0.6) : AppColors.error.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSuccess ? AppColors.success : AppColors.error).withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isSuccess ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess ? Icons.notifications_active_rounded : Icons.warning_amber_rounded,
                      color: isSuccess ? AppColors.success : AppColors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.tajawal(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: GoogleFonts.tajawal(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 3800), () {
      try {
        entry.remove();
      } catch (_) {}
    });
  }
}
