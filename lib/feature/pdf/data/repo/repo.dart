import 'package:pdf_viewer/feature/pdf/data/entity/pdf_entity.dart';
abstract class PdfRepository {
  Future<List<PdfEntity>> fetchPdfs();
  Future<void> markPurchased(String pdfName);
}
