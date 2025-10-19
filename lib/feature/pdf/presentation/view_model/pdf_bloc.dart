import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf_viewer/feature/pdf/data/entity/pdf_entity.dart';
import 'package:pdf_viewer/feature/pdf/data/repo/repo.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'pdf_event.dart';
import 'pdf_state.dart';

/// PDF Business Logic Component (BLoC)
/// 
/// Manages all PDF-related business logic including:
/// - Fetching PDF lists from repository
/// - Handling PDF loading states
/// - Managing PDF data state
/// - Coordinating with Razorpay for payments (future implementation)
/// 
/// This BLoC follows the BLoC pattern for state management and
/// integrates with the data layer through the PdfRepository.
class PdfBloc extends Bloc<PdfEvent, PdfState> {
  
  /// Repository for PDF data operations
  /// 
  /// Handles all data fetching and persistence operations.
  /// Abstracted through repository pattern for testability and
  /// separation of concerns.
  final PdfRepository repository;

  /// Razorpay payment gateway instance
  /// 
  /// Note: Currently declared but not initialized in constructor.
  /// For production, initialize with proper configuration.
  /// TODO: Initialize Razorpay with proper event handlers
  late Razorpay razorpay;

  /// Constructor initializes the BLoC with repository dependency
  /// 
  /// @param repository - The PDF repository implementation
  /// @initialState - PdfInitial() represents the starting state
  /// 
  /// Event handlers are registered in the constructor to handle
  /// different PDF-related events.
  PdfBloc(this.repository) : super(PdfInitial()) {
    
    /// Register event handlers for different PDF operations
    
    // Handler for loading PDFs event
    on<LoadPdfsEvent>((event, emit) async {
      // Emit loading state to update UI with progress indicator
      emit(PdfLoading());
      
      try {
        // Fetch PDF list from repository (local or remote)
        final pdfs = await repository.fetchPdfs();
        
        // Log successful PDF fetch (debug purposes)
        print("✓ PDFs loaded successfully: ${pdfs.length} items");
        
        // Emit loaded state with PDF data
        emit(PdfLoaded(pdfs));
      } catch (e) {
        // Log the error for debugging
        print("✗ Failed to load PDFs: ${e.toString()}");
        
        // Emit error state with error message
        emit(PdfError(e.toString()));
      }
    });
    
    // TODO: Add event handlers for:
    // - PurchasePdfEvent
    // - DownloadPdfEvent  
    // - OpenPdfEvent
    // - SearchPdfsEvent
    // - FilterPdfsEvent
  }
}