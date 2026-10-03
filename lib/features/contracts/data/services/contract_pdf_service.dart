import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sakani/features/contracts/domain/models/contract_model.dart';

/// خدمة توليد وثيقة عقد الإيجار الرسمي بصيغة PDF حقيقية معتمدة
class ContractPdfService {
  static Future<Uint8List> generateContractPdf(ContractModel contract) async {
    final pdf = pw.Document(
      title: 'عقد إيجار إلكتروني موثق - ${contract.id}',
      author: 'منصة سكني للوساطة العقارية والضمان المالي',
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.amber800, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('SAKANI ESCROW PLATFORM',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700)),
                    pw.Text('جمهورية مصر العربية - عقود إلكترونية موثقة',
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.amber900)),
                  ],
                ),
                pw.Divider(color: PdfColors.amber800, thickness: 1),
                pw.SizedBox(height: 8),

                pw.Text(
                  'وثيقة عقد إيجار رسمي موثق ومسجل',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'رقم الوثيقة: ${contract.id}',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                ),
                pw.Text(
                  'تاريخ الإصدار: ${contract.createdAt.day}/${contract.createdAt.month}/${contract.createdAt.year} م',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 14),

                // Table: Parties
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('الطرف الأول (المؤجر): ${contract.ownerName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('الرقم القومي: ${contract.ownerNationalId}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey900)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('الطرف الثاني (المستأجر): ${contract.tenantName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('الرقم القومي: ${contract.tenantNationalId}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey900)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Lease Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('العين المؤجرة: ${contract.apartmentTitle}', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('المدينة والموقع: ${contract.apartmentCity} - ${contract.apartmentAddress}', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('مدة التعاقد: من ${contract.startDate.day}/${contract.startDate.month}/${contract.startDate.year} إلى ${contract.endDate.day}/${contract.endDate.month}/${contract.endDate.year}', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('نوع الإيجار: ${contract.periodType}', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('القيمة الإيجارية الإجمالية: ${contract.totalRent.round()} ج.م', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                          pw.Text('مبلغ التأمين المحتجز بحساب الضمان: ${contract.securityDeposit.round()} ج.م', style: const pw.TextStyle(fontSize: 10, color: PdfColors.amber900)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Clauses
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('البنود والشروط القانونية الملزمة:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black)),
                      pw.SizedBox(height: 4),
                      pw.Text('1. أقر الطرفان بأهليتهما القانونية المعتبرة للتعاقد وتم التراضي إلكترونياً عبر منصة سكني.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      pw.Text('2. يلتزم المستأجر بالمحافظة التامة على العين ومحتوياتها وردها بالحالة التي استلمها عليها.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      pw.Text('3. يتم حجز مبلغ التأمين في حساب الضمان البنكي للمنصة ولا يصرف إلا بعد إخلاء الطرفين بالتراضي.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      pw.Text('4. يخضع هذا العقد لأحكام القانون رقم 4 لسنة 1996 وتعديلاته وتعد المنصة حكماً عدلاً في المنازعات.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    ],
                  ),
                ),
                pw.Spacer(),

                // Cryptographic seal and QR
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.amber600),
                  ),
                  child: pw.Row(
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: contract.qrData,
                        width: 50,
                        height: 50,
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('البصمة الرقمية المعتمدة (SHA-256 Seal):', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                            pw.Text(contract.digitalHash, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                            pw.SizedBox(height: 2),
                            pw.Text('تم التوثيق إلكترونياً ببصمة رقمية غير قابلة للتلاعب أو التعديل', style: const pw.TextStyle(fontSize: 8, color: PdfColors.green700)),
                          ],
                        ),
                      ),
                      pw.Column(
                        children: [
                          pw.Text('خاتم التوثيق الرسمي', style: const pw.TextStyle(fontSize: 8, color: PdfColors.amber800)),
                          pw.Text('★ معتمد ★', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.amber800)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
