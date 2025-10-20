import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_viewer/feature/pdf/presentation/view_model/pdf_bloc.dart';
import 'package:pdf_viewer/feature/pdf/presentation/view_model/pdf_event.dart';
import 'package:pdf_viewer/feature/pdf/presentation/view_model/pdf_state.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfListPage extends StatefulWidget {
  @override
  State<PdfListPage> createState() => _PdfListPageState();
}

class _PdfListPageState extends State<PdfListPage> {
  late Razorpay _razorpay;
  dynamic _pendingPdfToOpen;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadInitialPdfs();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _loadInitialPdfs() {
    context.read<PdfBloc>().add(LoadPdfsEvent());
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("Payment successful: ${response.paymentId}");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Payment successful! Opening PDF...'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    context.read<PdfBloc>().add(LoadPdfsEvent());
    
    if (_pendingPdfToOpen != null) {
      Future.delayed(Duration(milliseconds: 500), () {
        _viewPdf(_pendingPdfToOpen);
        _pendingPdfToOpen = null;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _pendingPdfToOpen = null;
    
    if (response.code != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Payment failed: ${response.message ?? 'Unknown error'}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment cancelled'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External wallet selected: ${response.walletName}");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redirecting to ${response.walletName}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _initiatePdfPurchase(dynamic pdf) {
    _pendingPdfToOpen = pdf;
    
    final options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',
      'amount': 10000,
      'name': 'PDF Viewer Pro',
      'description': 'Purchase: ${pdf.name}',
      'prefill': {
        'contact': '',
        'email': '',
      },
      'theme': {'color': '#007ACC'},
    };
    
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay error: $e");
      _pendingPdfToOpen = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize payment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handlePdfTap(dynamic pdf) async {
    final isPurchased = pdf.purchased;
    
    if (isPurchased) {
      await _viewPdf(pdf);
    } else {
      _showPurchasePrompt(pdf);
    }
  }

  void _showPurchasePrompt(dynamic pdf) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.blue),
            SizedBox(width: 8),
            Text('Premium Content'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This PDF requires purchase to view.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pdf.name ?? 'Untitled PDF',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Price: ₹100.00',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _initiatePdfPurchase(pdf);
            },
            icon: Icon(Icons.shopping_cart, size: 18),
            label: Text('Purchase'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: View PDF inline without downloading - using URL directly
  Future<void> _viewPdf(dynamic pdf) async {
    // Navigate directly to PDF viewer using the URL
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          pdfUrl: pdf.url,
          pdfName: pdf.name ?? 'Document',
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildPdfList(),
      floatingActionButton: _buildRefreshButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'PDF Library',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
      shadowColor: Colors.black12,
      actions: [
        IconButton(
          icon: Icon(Icons.search, size: 24),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Search feature coming soon!')),
            );
          },
          tooltip: 'Search PDFs',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.filter_list, size: 24),
          onSelected: (value) {
            context.read<PdfBloc>().add(LoadPdfsEvent());
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'all', child: Text('All PDFs')),
            PopupMenuItem(value: 'purchased', child: Text('Purchased')),
            PopupMenuItem(value: 'free', child: Text('Free')),
          ],
        ),
      ],
    );
  }

  Widget _buildPdfList() {
    return BlocBuilder<PdfBloc, PdfState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: _buildStateContent(state),
        );
      },
    );
  }

  Widget _buildStateContent(PdfState state) {
    if (state is PdfLoading) {
      return _buildLoadingState();
    } else if (state is PdfError) {
      return _buildErrorState(state);
    } else if (state is PdfLoaded) {
      return _buildPdfListView(state.pdfs);
    } else {
      return _buildInitialState();
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => _buildPdfSkeletonItem(),
    );
  }

  Widget _buildErrorState(PdfError state) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.7),
            ),
            SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.read<PdfBloc>().add(LoadPdfsEvent()),
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No PDFs available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfListView(List<dynamic> pdfs) {
    if (pdfs.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: pdfs.length,
      itemBuilder: (context, index) {
        final pdf = pdfs[index];
        return _buildPdfListItem(pdf);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.grey.withOpacity(0.4),
            ),
            SizedBox(height: 24),
            Text(
              'No PDFs Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Check back later for new content',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfListItem(dynamic pdf) {
    final isPurchased = pdf.purchased;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handlePdfTap(pdf),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildPdfIcon(isPurchased),
                SizedBox(width: 16),
                Expanded(
                  child: _buildPdfInfo(pdf, isPurchased),
                ),
                _buildActionButtons(pdf, isPurchased),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfIcon(bool isPurchased) {
    Color iconColor = isPurchased ? Colors.green : Colors.blue;
    Widget iconWidget = isPurchased
        ? Icon(Icons.verified, size: 16, color: Colors.white)
        : Icon(Icons.description, size: 20, color: Colors.white);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor,
            shape: BoxShape.circle,
          ),
          child: Center(child: iconWidget),
        ),
      ),
    );
  }

  Widget _buildPdfInfo(dynamic pdf, bool isPurchased) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pdf.name ?? 'Untitled PDF',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
        Text(
          isPurchased ? 'Purchased • Ready to view' : 'Premium Content • ₹100.00',
          style: TextStyle(
            fontSize: 14,
            color: isPurchased ? Colors.green : Colors.grey[600],
            fontWeight: isPurchased ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(dynamic pdf, bool isPurchased) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildViewButton(pdf, isPurchased),
        SizedBox(width: 8),
        if (!isPurchased) _buildBuyButton(pdf),
        if (isPurchased) _buildPurchasedBadge(),
      ],
    );
  }

  Widget _buildViewButton(dynamic pdf, bool isPurchased) {
    return Tooltip(
      message: isPurchased ? 'View PDF' : 'Purchase required',
      child: Container(
        decoration: BoxDecoration(
          color: isPurchased 
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(
            isPurchased ? Icons.visibility : Icons.lock,
            size: 20,
          ),
          color: isPurchased ? Colors.blue : Colors.grey,
          onPressed: () => _handlePdfTap(pdf),
          padding: EdgeInsets.all(8),
          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ),
    );
  }

  Widget _buildBuyButton(dynamic pdf) {
    return Tooltip(
      message: 'Purchase PDF',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.shopping_cart, size: 18),
          color: Colors.white,
          onPressed: () => _initiatePdfPurchase(pdf),
          padding: EdgeInsets.all(8),
          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ),
    );
  }

  Widget _buildPurchasedBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 14, color: Colors.green),
          SizedBox(width: 4),
          Text(
            'Owned',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfSkeletonItem() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return FloatingActionButton(
      onPressed: () {
        context.read<PdfBloc>().add(LoadPdfsEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refreshing PDF library...'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Icon(Icons.refresh, size: 24),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 4,
      tooltip: 'Refresh PDFs',
    );
  }
}

// NEW: PDF Viewer Page with pinch-to-zoom and mobile optimization
class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String pdfName;

  const PdfViewerPage({
    Key? key,
    required this.pdfUrl,
    required this.pdfName,
  }) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int currentPage = 1;
  int totalPages = 0;
  bool isLoading = true;

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pdfName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            if (totalPages > 0)
              Text(
                'Page $currentPage of $totalPages',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
            },
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
            },
            tooltip: 'Zoom Out',
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _pdfViewerController.searchText('search');
            },
            tooltip: 'Search',
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.pdfUrl,
            controller: _pdfViewerController,
            enableDoubleTapZooming: true,
            enableTextSelection: true,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                totalPages = details.document.pages.count;
                isLoading = false;
              });
            },
            onPageChanged: (PdfPageChangedDetails details) {
              setState(() {
                currentPage = details.newPageNumber;
              });
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              setState(() {
                isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load PDF: ${details.error}'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
            },
          ),
          if (isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading PDF...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: !isLoading && totalPages > 1
          ? Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, size: 28),
                      onPressed: currentPage > 1
                          ? () {
                              _pdfViewerController.previousPage();
                            }
                          : null,
                      tooltip: 'Previous Page',
                      color: Colors.blue,
                    ),
                    GestureDetector(
                      onTap: () => _showPageNavigator(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Text(
                          '$currentPage / $totalPages',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, size: 28),
                      onPressed: currentPage < totalPages
                          ? () {
                              _pdfViewerController.nextPage();
                            }
                          : null,
                      tooltip: 'Next Page',
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  void _showPageNavigator(BuildContext context) {
    final TextEditingController pageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Go to Page'),
        content: TextField(
          controller: pageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter page number (1-$totalPages)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(pageController.text);
              if (page != null && page >= 1 && page <= totalPages) {
                _pdfViewerController.jumpToPage(page);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid page number'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Go'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}