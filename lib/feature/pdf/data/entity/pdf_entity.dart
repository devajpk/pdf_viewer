class PdfEntity {
  final String name;
  final String url;
  final bool purchased;

  PdfEntity({required this.name, required this.url, this.purchased = false});
}
