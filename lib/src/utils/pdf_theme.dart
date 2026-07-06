import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Loads a Unicode-capable font (supports ₹ and other symbols the built-in
/// PDF core fonts don't) so amounts render correctly across all PDFs.
Future<pw.ThemeData> buildPdfTheme() async {
  final regular = await PdfGoogleFonts.notoSansRegular();
  final bold = await PdfGoogleFonts.notoSansBold();
  return pw.ThemeData.withFont(base: regular, bold: bold);
}
