import 'package:equatable/equatable.dart';
import 'package:pdf_viewer/feature/pdf/data/entity/pdf_entity.dart';

abstract class PdfState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PdfInitial extends PdfState {}
class PdfLoading extends PdfState {}
class PdfLoaded extends PdfState {
  final List<PdfEntity> pdfs;
  PdfLoaded(this.pdfs);
  @override
  List<Object?> get props => [pdfs];
}
class PdfError extends PdfState {
  final String message;
  PdfError(this.message);
  @override
  List<Object?> get props => [message];
}

