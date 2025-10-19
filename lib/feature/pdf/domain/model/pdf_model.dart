import 'package:pdf_viewer/feature/pdf/data/entity/pdf_entity.dart';
class PdfModel extends PdfEntity {
  PdfModel({required String name, required String url, bool purchased = false})
      : super(name: name, url: url, purchased: purchased);

  factory PdfModel.fromMap(Map<String, dynamic> map) {
    return PdfModel(
      name: map['name'],
      url: map['url'],
      purchased: map['purchased'] ?? false,
    );
  }
}
