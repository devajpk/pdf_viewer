import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf_viewer/feature/pdf/data/entity/pdf_entity.dart';
import 'package:pdf_viewer/feature/pdf/data/repo/repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdfRepositoryImpl implements PdfRepository {
  final FirebaseStorage storage;

  PdfRepositoryImpl(this.storage);

  @override
  Future<List<PdfEntity>> fetchPdfs() async {
    try {
      // List all files under 'pdfs/' folder
      final result = await storage.ref('pdfs/').listAll();

      // Map each StorageReference to a PdfEntity
      final pdfs = await Future.wait(
        result.items.map((ref) async => PdfEntity(
          name: ref.name,
          url: await ref.getDownloadURL(),
          purchased: false, // initially false
        )),
      );

      return pdfs;
    } catch (e) {
      print('Error fetching PDFs: $e');
      throw Exception('Failed to fetch PDFs');
    }
  }

  Future<void> markPurchased(String pdfName) async {
    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList('purchasedPdfs') ?? [];
    if (!purchased.contains(pdfName)) {
      purchased.add(pdfName);
      await prefs.setStringList('purchasedPdfs', purchased);
    }
  }

  Future<bool> isPurchased(String pdfName) async {
    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList('purchasedPdfs') ?? [];
    return purchased.contains(pdfName);
  }
}
