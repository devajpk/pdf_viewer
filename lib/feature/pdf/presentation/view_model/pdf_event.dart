import 'package:equatable/equatable.dart';
import 'package:pdf_viewer/feature/pdf/data/entity/pdf_entity.dart';

abstract class PdfEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPdfsEvent extends PdfEvent {}

